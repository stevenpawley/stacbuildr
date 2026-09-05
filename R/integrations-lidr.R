# LAS point record formats, in the naming and whole-byte sizing convention that
# PDAL uses and that the Point Cloud extension's own example follows. Several of
# these dimensions are bit-packed in the file (ReturnNumber, NumberOfReturns,
# ScanDirectionFlag, EdgeOfFlightLine and the class flags all share bytes), but
# pc:schemas can only express whole bytes, so each is reported as the unpacked
# dimension a reader materialises.
las_dimension_sizes <- list(
  X = c(8, "floating"),
  Y = c(8, "floating"),
  Z = c(8, "floating"),
  Intensity = c(2, "unsigned"),
  ReturnNumber = c(1, "unsigned"),
  NumberOfReturns = c(1, "unsigned"),
  ScanDirectionFlag = c(1, "unsigned"),
  EdgeOfFlightLine = c(1, "unsigned"),
  Classification = c(1, "unsigned"),
  ScanAngleRank = c(4, "floating"),
  UserData = c(1, "unsigned"),
  PointSourceId = c(2, "unsigned"),
  GpsTime = c(8, "floating"),
  ScanChannel = c(1, "unsigned"),
  ClassFlags = c(1, "unsigned"),
  Red = c(2, "unsigned"),
  Green = c(2, "unsigned"),
  Blue = c(2, "unsigned"),
  Infrared = c(2, "unsigned"),
  WavePacketDescriptorIndex = c(1, "unsigned"),
  WaveformDataOffset = c(8, "unsigned"),
  WaveformPacketSize = c(4, "unsigned"),
  WaveformLocation = c(4, "floating"),
  WaveformXt = c(4, "floating"),
  WaveformYt = c(4, "floating"),
  WaveformZt = c(4, "floating")
)

las_base_dimensions <- c(
  "X", "Y", "Z", "Intensity", "ReturnNumber", "NumberOfReturns",
  "ScanDirectionFlag", "EdgeOfFlightLine", "Classification", "ScanAngleRank",
  "UserData", "PointSourceId"
)

las_rgb_dimensions <- c("Red", "Green", "Blue")

las_wave_dimensions <- c(
  "WavePacketDescriptorIndex", "WaveformDataOffset", "WaveformPacketSize",
  "WaveformLocation", "WaveformXt", "WaveformYt", "WaveformZt"
)

# Which dimensions each LAS point data record format carries. Formats 6-10 are
# the LAS 1.4 "extended" records, which always carry GPS time and add the scan
# channel and class flag bytes.
las_point_formats <- local({
  base <- las_base_dimensions
  ext <- c(base, "GpsTime", "ScanChannel", "ClassFlags")
  list(
    `0` = base,
    `1` = c(base, "GpsTime"),
    `2` = c(base, las_rgb_dimensions),
    `3` = c(base, "GpsTime", las_rgb_dimensions),
    `4` = c(base, "GpsTime", las_wave_dimensions),
    `5` = c(base, "GpsTime", las_rgb_dimensions, las_wave_dimensions),
    `6` = ext,
    `7` = c(ext, las_rgb_dimensions),
    `8` = c(ext, las_rgb_dimensions, "Infrared"),
    `9` = c(ext, las_wave_dimensions),
    `10` = c(ext, las_rgb_dimensions, "Infrared", las_wave_dimensions)
  )
})

# Extra Bytes VLR data type codes, from the LAS 1.4 specification. Codes 11-30
# described arrays and were deprecated, so they are not mapped.
las_extra_byte_types <- list(
  `1` = c(1, "unsigned"),
  `2` = c(1, "signed"),
  `3` = c(2, "unsigned"),
  `4` = c(2, "signed"),
  `5` = c(4, "unsigned"),
  `6` = c(4, "signed"),
  `7` = c(8, "unsigned"),
  `8` = c(8, "signed"),
  `9` = c(4, "floating"),
  `10` = c(8, "floating")
)

# lidR names some columns differently from the LAS specification; pc:schemas and
# pc:statistics are keyed on the specification's names so that channel names
# line up with what other STAC tooling produces.
lidr_dimension_names <- c(
  gpstime = "GpsTime",
  EdgeOfFlightline = "EdgeOfFlightLine",
  PointSourceID = "PointSourceId",
  R = "Red",
  G = "Green",
  B = "Blue",
  NIR = "Infrared",
  ScanAngle = "ScanAngleRank",
  ScannerChannel = "ScanChannel"
)


# `[[` on a named vector errors for an absent name rather than returning NULL,
# and both lookups below are routinely absent: a channel may have no schema to
# index into, and most lidR column names need no translation.
pc_lookup <- function(table, name) {
  if (name %in% names(table)) table[[name]] else NULL
}


#' Build Point Cloud Schema Objects from a LAS Header
#'
#' @description
#' Derives the `pc:schemas` dimension list for a LAS/LAZ file from its point
#' data record format, plus any additional dimensions declared in the file's
#' Extra Bytes variable length record.
#'
#' @param header A `LASheader` object from `lidR::readLASheader()`, or a `LAS`
#'   object (its header is used).
#'
#' @return A list of [pc_schema()] objects, or `NULL` if the point data record
#'   format is not recognised.
#'
#' @details
#' Only the header is read, so this is fast even for very large files. Sizes
#' follow the whole-byte, unpacked convention described in
#' [add_pointcloud_extension()].
#'
#' @seealso [item_from_lidr()], [add_pointcloud_extension()]
#'
#' @examples
#' \dontrun{
#' header <- lidR::readLASheader("points.laz")
#' schemas_from_lidr(header)
#' }
#'
#' @export
schemas_from_lidr <- function(header) {
  header <- as_lidr_header(header)
  phb <- header@PHB

  format_id <- phb[["Point Data Format ID"]]
  if (is.null(format_id)) {
    return(NULL)
  }

  # LAS 1.4 sets the high bits of the format ID to flag LAZ compression; the
  # record layout is carried in the low 6 bits.
  format_id <- bitwAnd(as.integer(format_id), 0x3f)

  dimensions <- las_point_formats[[as.character(format_id)]]
  if (is.null(dimensions)) {
    cli::cli_warn(c(
      "Unrecognised LAS point data record format {format_id}.",
      "i" = "{.field pc:schemas} is omitted; pass {.arg schemas} to
             {.fn add_pointcloud_extension} to set it explicitly."
    ))
    return(NULL)
  }

  schemas <- lapply(dimensions, function(name) {
    spec <- las_dimension_sizes[[name]]
    pc_schema(name, size = as.integer(spec[[1]]), type = spec[[2]])
  })

  c(schemas, extra_byte_schemas(header))
}


# Additional per-point dimensions declared by the Extra Bytes VLR.
extra_byte_schemas <- function(header) {
  extra <- header@VLR[["Extra_Bytes"]][["Extra Bytes Description"]]
  if (is.null(extra) || length(extra) == 0) {
    return(list())
  }

  schemas <- list()
  for (descriptor in extra) {
    name <- descriptor[["name"]]
    code <- descriptor[["data_type"]]
    if (is.null(name) || is.null(code)) next

    spec <- las_extra_byte_types[[as.character(code)]]
    if (is.null(spec)) {
      # 0 means "undocumented extra bytes"; the deprecated array codes 11-30
      # have no whole-byte scalar equivalent either.
      cli::cli_warn(
        "Skipping extra byte dimension {.val {name}}: unsupported data type {code}"
      )
      next
    }

    schemas[[length(schemas) + 1]] <- pc_schema(
      name,
      size = as.integer(spec[[1]]),
      type = spec[[2]]
    )
  }

  schemas
}


# Accepts a LAS, LASheader or file path and returns a LASheader.
as_lidr_header <- function(x, arg = "header") {
  check_lidr_installed()

  if (inherits(x, "LASheader")) {
    return(x)
  }
  if (inherits(x, "LAS")) {
    return(x@header)
  }
  if (is.character(x) && length(x) == 1) {
    return(lidR::readLASheader(x))
  }

  cli::cli_abort(
    "'{arg}' must be a LASheader, a LAS object, or a path to a LAS/LAZ file"
  )
}


check_lidr_installed <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package 'lidR' is required.",
      "i" = "Install with: install.packages('lidR')"
    ))
  }
  invisible(TRUE)
}


# X/Y/Z bounds are in the public header block, so min/max statistics for the
# coordinate channels come for free. Everything else needs the points.
header_statistics <- function(header, schemas) {
  phb <- header@PHB
  count <- phb[["Number of point records"]]

  positions <- stats::setNames(
    seq_along(schemas) - 1L,
    vapply(schemas, function(s) s$name, character(1))
  )

  stats_list <- list()
  for (axis in c("X", "Y", "Z")) {
    minimum <- phb[[paste("Min", axis)]]
    maximum <- phb[[paste("Max", axis)]]
    if (is.null(minimum) || is.null(maximum)) next

    stats_list[[length(stats_list) + 1]] <- pc_statistic(
      axis,
      position = pc_lookup(positions, axis),
      count = count,
      minimum = minimum,
      maximum = maximum
    )
  }

  if (length(stats_list) == 0) NULL else stats_list
}


# Full per-channel statistics, which require reading the points.
point_statistics <- function(las, schemas) {
  positions <- stats::setNames(
    seq_along(schemas) - 1L,
    vapply(schemas, function(s) s$name, character(1))
  )

  stats_list <- list()
  for (column in names(las@data)) {
    values <- las@data[[column]]
    # Logical columns are lidR's unpacked classification flag bits, which all
    # come from the single ClassFlags byte; summarising them as separate
    # channels would put several identically named entries in pc:statistics.
    if (!is.numeric(values)) next

    values <- as.numeric(values)
    values <- values[!is.na(values)]
    if (length(values) == 0) next

    name <- pc_lookup(lidr_dimension_names, column) %||% column
    variance <- if (length(values) > 1) stats::var(values) else NULL

    stats_list[[length(stats_list) + 1]] <- pc_statistic(
      name,
      position = pc_lookup(positions, name),
      average = mean(values),
      count = length(values),
      minimum = min(values),
      maximum = max(values),
      stddev = if (is.null(variance)) NULL else sqrt(variance),
      variance = variance
    )
  }

  if (length(stats_list) == 0) NULL else stats_list
}


# The item geometry is the file's bounding rectangle, transformed to WGS84.
extract_lidr_spatial_metadata <- function(header, reproject_to_wgs84 = TRUE) {
  crs <- sf::st_crs(header)

  bbox_sfc <- sf::st_as_sfc(sf::st_bbox(
    c(
      xmin = header@PHB[["Min X"]],
      ymin = header@PHB[["Min Y"]],
      xmax = header@PHB[["Max X"]],
      ymax = header@PHB[["Max Y"]]
    ),
    crs = crs
  ))
  bbox_sf <- sf::st_as_sf(data.frame(geometry = bbox_sfc))

  if (reproject_to_wgs84) {
    if (is.na(crs)) {
      cli::cli_abort(c(
        "The LAS file declares no CRS.",
        "i" = "STAC geometries are WGS84 longitude/latitude, so the CRS is
               needed to transform the file extent.",
        ">" = "Set it with {.code sf::st_crs(header) <- <crs>}, or pass
               {.code reproject_to_wgs84 = FALSE} if the coordinates are
               already longitude/latitude."
      ))
    }
    if (crs != sf::st_crs(4326)) {
      bbox_sf <- sf::st_transform(bbox_sf, 4326)
    }
  }

  list(
    geometry = geometry_from_sf(bbox_sf),
    bbox = bbox_from_sf(bbox_sf),
    crs = crs
  )
}


# LAS records file creation as a year plus a day of year. Both are commonly left
# at zero, which is not a date.
datetime_from_lidr <- function(header) {
  year <- header@PHB[["File Creation Year"]]
  doy <- header@PHB[["File Creation Day of Year"]]

  if (
    is.null(year) || is.null(doy) ||
      is.na(year) || is.na(doy) ||
      year <= 0 || doy <= 0
  ) {
    return(NULL)
  }

  date <- tryCatch(
    as.Date(doy - 1, origin = paste0(year, "-01-01")),
    error = function(e) NULL
  )
  if (is.null(date) || is.na(date)) {
    return(NULL)
  }

  format(date, "%Y-%m-%dT00:00:00Z")
}


# Projection extension fields in the file's own CRS, alongside the WGS84
# geometry that STAC itself requires.
add_projection_metadata_lidr <- function(item, header, crs) {
  if (is.na(crs)) {
    return(item)
  }

  ext_uri <- "https://stac-extensions.github.io/projection/v2.0.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }
  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  if (!is.null(crs$epsg) && !is.na(crs$epsg)) {
    item@properties$`proj:code` <- paste0("EPSG:", crs$epsg)
  }
  if (!is.null(crs$wkt) && !is.na(crs$wkt)) {
    item@properties$`proj:wkt2` <- crs$wkt
  }

  phb <- header@PHB
  item@properties$`proj:bbox` <- c(
    phb[["Min X"]], phb[["Min Y"]], phb[["Min Z"]],
    phb[["Max X"]], phb[["Max Y"]], phb[["Max Z"]]
  )

  item
}


#' Create a STAC Item from a LAS/LAZ Point Cloud
#'
#' @description
#' Creates a STAC Item from a point cloud read with the `lidR` package,
#' populating the Point Cloud extension from the file's public header block.
#' Geometry, bounding box, projection metadata, point count, density, and the
#' dimension schema are all derived from the header alone, so items can be built
#' from very large files without reading a single point.
#'
#' @param x A `LASheader` object, a `LAS` object, or a path to a LAS/LAZ file.
#' @param href (character, optional) URI for the point cloud asset. If provided,
#'   the file is added as an asset and `id` is derived from the basename when not
#'   explicitly set. Defaults to `x` when `x` is a file path.
#' @param id (character, optional) Item ID. If NULL, derived from `href`
#'   basename.
#' @param datetime (character, optional) ISO 8601 datetime string. If NULL, the
#'   file creation year and day of year from the LAS header are used; if those
#'   are unset (which is common), the current time is used with a warning.
#' @param properties (list, optional) Additional properties for the item.
#' @param assets (list, optional) Additional assets beyond the point cloud.
#' @param asset_key (character, optional) Key name for the point cloud asset.
#'   Default is "data".
#' @param asset_roles (character vector, optional) Roles for the point cloud
#'   asset. Default is `c("data")`.
#' @param pc_type (character, optional) The `pc:type` phenomenology value.
#'   Default is `"lidar"`.
#' @param add_pointcloud (logical, optional) If TRUE, adds the Point Cloud
#'   extension. Default is TRUE.
#' @param add_projection (logical, optional) If TRUE and the file declares a CRS,
#'   adds Projection extension fields in the file's native CRS. Default is TRUE.
#' @param add_schemas (logical, optional) If TRUE, derives `pc:schemas` from the
#'   point data record format and Extra Bytes VLR. Default is TRUE.
#' @param calculate_statistics (logical, optional) If TRUE, computes full
#'   per-channel `pc:statistics` (average, stddev, variance and so on). This
#'   reads every point and can be slow for large files. When FALSE, only the
#'   X/Y/Z bounds carried in the header are recorded. Default is FALSE.
#' @param reproject_to_wgs84 (logical, optional) If TRUE and the file is not in
#'   WGS84, reprojects the extent to EPSG:4326, which STAC requires. Default is
#'   TRUE.
#' @param ... Additional arguments passed to `stac_item()`.
#'
#' @details
#' ## Statistics
#' `calculate_statistics = FALSE` still records `minimum`, `maximum` and `count`
#' for the X, Y and Z channels, because the LAS public header block carries those
#' bounds. The remaining statistics, and statistics for any other channel,
#' require a full read of the points.
#'
#' ## Point Density
#' `pc:density` is `lidR`'s point density: the point count divided by the area of
#' the file's bounding rectangle, in the units of the file's own CRS. For data in
#' a projected CRS in metres this is points per square metre.
#'
#' @return A STAC Item object with the point cloud metadata.
#'
#' @seealso
#' * [items_from_lascatalog()] for building items for a whole tiled collection
#' * [add_pointcloud_extension()] to set the fields by hand
#' * [schemas_from_lidr()] for just the dimension schema
#'
#' @examples
#' \dontrun{
#' library(lidR)
#'
#' f <- system.file("extdata", "Megaplot.laz", package = "lidR")
#'
#' # Header only: fast even for very large files
#' item <- item_from_lidr(f)
#'
#' # With full per-channel statistics, which reads the points
#' item <- item_from_lidr(
#'   f,
#'   href = "https://example.com/Megaplot.laz",
#'   datetime = "2023-06-15T10:30:00Z",
#'   calculate_statistics = TRUE
#' )
#' }
#'
#' @export
item_from_lidr <- function(
  x,
  href = NULL,
  id = NULL,
  datetime = NULL,
  properties = list(),
  assets = list(),
  asset_key = "data",
  asset_roles = c("data"),
  pc_type = "lidar",
  add_pointcloud = TRUE,
  add_projection = TRUE,
  add_schemas = TRUE,
  calculate_statistics = FALSE,
  reproject_to_wgs84 = TRUE,
  ...
) {
  check_lidr_installed()
  if (!requireNamespace("sf", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package 'sf' is required.",
      "i" = "Install with: install.packages('sf')"
    ))
  }

  # A file path doubles as the default asset href
  if (is.null(href) && is.character(x) && length(x) == 1) {
    href <- x
  }

  las <- if (inherits(x, "LAS")) x else NULL
  header <- as_lidr_header(x, arg = "x")

  if (calculate_statistics && is.null(las)) {
    if (!is.character(x) || length(x) != 1) {
      cli::cli_abort(c(
        "'calculate_statistics = TRUE' needs the points, not just a header.",
        "i" = "Pass a LAS object or a file path as {.arg x}."
      ))
    }
    las <- lidR::readLAS(x)
  }

  if (is.null(id)) {
    if (!is.null(href)) {
      id <- tools::file_path_sans_ext(basename(href))
      # ".copc.laz" leaves a trailing ".copc" behind
      id <- sub("\\.copc$", "", id)
    } else {
      cli::cli_abort("'id' is required when 'href' is not provided")
    }
  }

  if (is.null(datetime)) {
    datetime <- datetime_from_lidr(header)
  }
  if (is.null(datetime)) {
    datetime <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
    cli::cli_warn(
      "No datetime provided and the LAS header records no creation date,
       using current time"
    )
  }

  spatial_meta <- extract_lidr_spatial_metadata(header, reproject_to_wgs84)

  item <- stac_item(
    id = id,
    geometry = spatial_meta$geometry,
    bbox = spatial_meta$bbox,
    datetime = datetime,
    properties = properties,
    assets = assets,
    ...
  )

  if (!is.null(href)) {
    item <- add_asset(
      item,
      key = asset_key,
      href = normalize_href(href),
      type = get_media_type(href),
      roles = asset_roles
    )
  }

  if (add_projection) {
    item <- add_projection_metadata_lidr(item, header, spatial_meta$crs)
  }

  if (add_pointcloud) {
    schemas <- if (add_schemas) schemas_from_lidr(header) else NULL

    statistics <- if (!is.null(las)) {
      point_statistics(las, schemas %||% list())
    } else {
      header_statistics(header, schemas %||% list())
    }

    item <- add_pointcloud_extension(
      item,
      count = header@PHB[["Number of point records"]],
      type = pc_type,
      schemas = schemas,
      density = density_from_lidr(header),
      statistics = statistics
    )
  }

  item
}


# lidR::density() errors on a degenerate (zero-area) extent, which a
# single-point or single-column file can produce.
density_from_lidr <- function(header) {
  value <- tryCatch(lidR::density(header), error = function(e) NULL)
  if (is.null(value) || !is.finite(value)) {
    return(NULL)
  }
  value
}


#' Create STAC Items from a LAScatalog
#'
#' @description
#' Creates one STAC Item per file in a `lidR` `LAScatalog`, which is the usual
#' way a tiled point cloud collection is described. Only file headers are read,
#' so a catalogue of thousands of tiles can be catalogued quickly.
#'
#' @param ctg A `LAScatalog` object, a directory containing LAS/LAZ files, or a
#'   character vector of file paths.
#' @param datetime_from_filename Function to extract a datetime from a filename.
#'   Should return an ISO 8601 string. If NULL, the LAS header creation date is
#'   used where available.
#' @param ... Additional arguments passed to `item_from_lidr()`.
#'
#' @return A list of STAC Item objects.
#'
#' @details
#' Files that cannot be read produce a warning and are skipped, so one damaged
#' tile does not abandon the whole catalogue. Pass the result to
#' [extent_from_items()] to build the matching Collection extent.
#'
#' @seealso [item_from_lidr()], [extent_from_items()]
#'
#' @examples
#' \dontrun{
#' library(lidR)
#'
#' ctg <- readLAScatalog("path/to/tiles")
#' items <- items_from_lascatalog(ctg)
#'
#' collection <- stac_collection(
#'   id = "als-tiles",
#'   description = "Airborne laser scanning tiles",
#'   license = "CC-BY-4.0",
#'   extent = extent_from_items(items)
#' )
#' }
#'
#' @export
items_from_lascatalog <- function(
  ctg,
  datetime_from_filename = NULL,
  ...
) {
  check_lidr_installed()

  files <- if (inherits(ctg, "LAScatalog")) {
    ctg$filename
  } else if (is.character(ctg)) {
    if (length(ctg) == 1 && dir.exists(ctg)) {
      list.files(
        ctg,
        pattern = "\\.(las|laz)$",
        full.names = TRUE,
        ignore.case = TRUE
      )
    } else {
      ctg
    }
  } else {
    cli::cli_abort(
      "'ctg' must be a LAScatalog, a directory, or a vector of file paths"
    )
  }

  if (length(files) == 0) {
    cli::cli_abort("No LAS/LAZ files found")
  }

  items <- list()
  failed <- character()

  cli::cli_progress_bar(
    "Creating items",
    total = length(files),
    .envir = environment()
  )

  for (file in files) {
    cli::cli_progress_update(.envir = environment())

    datetime <- if (!is.null(datetime_from_filename)) {
      datetime_from_filename(basename(file))
    } else {
      NULL
    }

    tryCatch(
      {
        items[[length(items) + 1]] <- item_from_lidr(
          file,
          datetime = datetime,
          ...
        )
      },
      error = function(e) {
        failed <<- c(failed, basename(file))
        cli::cli_warn("Failed to create item for {basename(file)}: {e$message}")
      }
    )
  }

  cli::cli_progress_done(.envir = environment())

  if (length(failed) > 0) {
    cli::cli_warn("Failed to create items for {length(failed)} file{?s}")
  }

  items
}
