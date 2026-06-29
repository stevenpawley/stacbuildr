#' Create a STAC Item from a Terra SpatRaster Object
#'
#' @description
#' Creates a STAC Item from a `terra` `SpatRaster` object. Automatically
#' extracts spatial metadata including geometry, bbox, CRS, and optionally band
#' information and statistics.
#'
#' @param terra_obj A `SpatRaster` object (from the `terra` package).
#' @param href (character, optional) URI for the main raster asset. If provided,
#'   the raster is added as an asset and `id` is derived from the basename when
#'   not explicitly set. If NULL, no asset is added and `id` must be supplied.
#' @param id (character, optional) Item ID. If NULL, derived from `href` basename.
#' @param datetime (character, optional) ISO 8601 datetime string. If NULL, uses
#'   current time.
#' @param properties (list, optional) Additional properties for the item.
#' @param assets (list, optional) Additional assets beyond the main raster. The
#'   main raster is automatically added as an asset.
#' @param asset_key (character, optional) Key name for the main raster asset.
#'   Default is "data".
#' @param asset_roles (character vector, optional) Roles for the main raster asset.
#'   Default is c("data").
#' @param add_raster_bands (logical, optional) If TRUE, adds raster extension with
#'   band metadata. Default is TRUE.
#' @param add_eo_bands (logical, optional) If TRUE and band information is available,
#'   adds EO extension. Requires band metadata. Default is FALSE.
#' @param calculate_statistics (logical, optional) If TRUE, calculates band
#'   statistics (min, max, mean, stddev). Can be slow for large rasters. Default
#'   is FALSE.
#' @param reproject_to_wgs84 (logical, optional) If TRUE and raster is not in
#'   WGS84, reprojects the bbox geometry to WGS84 (EPSG:4326). STAC requires
#'   WGS84. Default is TRUE.
#' @param ... Additional arguments passed to `stac_item()`.
#'
#' @details
#' **STAC CRS Requirement:**
#' STAC Items must use WGS84 (EPSG:4326) for geometry and bbox. If your raster
#' uses a different CRS, the geometry will be reprojected automatically when
#' `reproject_to_wgs84 = TRUE`.
#'
#' @return A STAC Item object with the raster metadata.
#'
#' @examples
#' \dontrun{
#' library(terra)
#'
#' r <- rast("path/to/image.tif")
#'
#' item <- item_from_terra(
#'   r,
#'   href = "path/to/image.tif",
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#'
#' item <- item_from_terra(
#'   r,
#'   href = "https://example.com/image.tif",
#'   id = "LC08_001",
#'   datetime = "2023-06-15T10:30:00Z",
#'   properties = list(platform = "landsat-8"),
#'   calculate_statistics = TRUE
#' )
#' }
#'
#' @export
item_from_terra <- function(
  terra_obj,
  href = NULL,
  id = NULL,
  datetime = NULL,
  properties = list(),
  assets = list(),
  asset_key = "data",
  asset_roles = c("data"),
  add_raster_bands = TRUE,
  add_eo_bands = FALSE,
  calculate_statistics = FALSE,
  reproject_to_wgs84 = TRUE,
  ...
) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required. Install with: install.packages('sf')")
  }

  if (!inherits(terra_obj, "SpatRaster")) {
    stop("'terra_obj' must be a SpatRaster object")
  }

  # Generate ID from href if not provided
  if (is.null(id)) {
    if (!is.null(href)) {
      id <- tools::file_path_sans_ext(basename(href))
    } else {
      stop("'id' is required when 'href' is not provided")
    }
  }

  # Use current time if datetime not provided
  if (is.null(datetime)) {
    datetime <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
    warning("No datetime provided, using current time")
  }

  # Extract spatial metadata
  spatial_meta <- extract_terra_spatial_metadata(terra_obj, reproject_to_wgs84)

  # Create the item
  item <- stac_item(
    id = id,
    geometry = spatial_meta$geometry,
    bbox = spatial_meta$bbox,
    datetime = datetime,
    properties = properties,
    ...
  )

  # Add the main raster as an asset if href provided
  if (!is.null(href)) {
    item <- add_asset(
      item,
      key = asset_key,
      href = normalize_href(href),
      type = get_media_type(href),
      roles = asset_roles
    )

    # Add nodata for file-backed rasters
    src <- terra::sources(terra_obj)
    if (length(src) > 0 && nchar(src[1]) > 0 && file.exists(src[1])) {
      nodata_val <- gdal_nodata(src[1])
      if (!is.null(nodata_val)) {
        item@assets[[asset_key]]$nodata <- nodata_val
      }
    }
  }

  # Add any additional assets
  if (length(assets) > 0) {
    for (asset_name in names(assets)) {
      asset <- assets[[asset_name]]
      item <- add_asset(
        item,
        key = asset_name,
        href = asset@href,
        title = asset@title,
        type = asset@type,
        roles = asset@roles
      )
    }
  }

  # Extract and add band information
  if (add_raster_bands || add_eo_bands) {
    bands <- bands_from_terra(
      terra_obj,
      calculate_statistics = calculate_statistics
    )

    if (add_raster_bands) {
      item <- add_raster_extension(
        item,
        bands = bands,
        asset_key = if (!is.null(href)) asset_key else NULL
      )
    }

    if (add_eo_bands) {
      warning(
        "EO extension requires wavelength metadata not available in raster data"
      )
    }
  }

  # Add projection extension if CRS is not WGS84
  crs <- terra::crs(terra_obj, describe = TRUE)
  if (crs$code != 4326L) {
    item <- add_projection_metadata_terra(item, terra_obj)
  }

  item
}


#' Create a STAC Item from an sf Object
#'
#' @description
#' Creates a STAC Item from an sf (simple features) object.
#'
#' @param sf_obj An sf object (point, line, polygon, etc.).
#' @param id (character, required) Item ID.
#' @param datetime (character, required) ISO 8601 datetime string.
#' @param properties (list, optional) Additional properties for the item.
#' @param href (character, optional) If provided, creates an asset pointing
#'   to the original file.
#' @param ... Additional arguments passed to `stac_item()`.
#'
#' @return A STAC Item object.
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' # Read a shapefile
#' polygon <- st_read("boundary.shp")
#'
#' # Create STAC item
#' item <- item_from_sf(
#'   polygon,
#'   id = "study-area",
#'   datetime = "2023-01-01T00:00:00Z",
#'   properties = list(title = "Study Area Boundary")
#' )
#' }
#'
#' @export
item_from_sf <- function(
  sf_obj,
  id,
  datetime,
  properties = list(),
  href = NULL,
  ...
) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required. Install with: install.packages('sf')")
  }

  if (!inherits(sf_obj, "sf")) {
    stop("'sf_obj' must be an sf object")
  }

  # Convert to WGS84 if necessary
  if (sf::st_crs(sf_obj)$epsg != 4326) {
    sf_obj <- sf::st_transform(sf_obj, 4326)
  }

  # Extract geometry and bbox
  geom_geojson <- geometry_from_sf(sf_obj)
  bbox_vec <- bbox_from_sf(sf_obj)

  # Create item
  item <- stac_item(
    id = id,
    geometry = geom_geojson,
    bbox = bbox_vec,
    datetime = datetime,
    properties = properties,
    ...
  )

  # Add asset if href provided
  if (!is.null(href)) {
    item <- add_asset(
      item,
      key = "source",
      href = normalize_href(href),
      type = get_media_type(href),
      roles = c("data")
    )
  }

  item
}


#' Convert sf Geometry to GeoJSON
#'
#' @description
#' Converts an sf object's geometry to a GeoJSON-compatible list structure.
#' If the sf object contains multiple features, they are unioned into a single
#' geometry, since a STAC item has one geometry.
#'
#' @param sf_obj An sf object.
#'
#' @return A GeoJSON geometry object (list).
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' polygon <- st_read("boundary.shp")
#' geojson <- geometry_from_sf(polygon)
#' }
#'
#' @export
geometry_from_sf <- function(sf_obj) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required")
  }

  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop(
      "Package 'geojsonsf' is required. Install with: install.packages('geojsonsf')"
    )
  }

  # A STAC item has one geometry — union multiple features into one
  if (nrow(sf_obj) > 1) {
    sf_obj <- sf::st_sf(geometry = sf::st_union(sf_obj))
  }

  # atomise = TRUE returns the geometry JSON directly (no Feature wrapper)
  geojson_str <- geojsonsf::sf_geojson(sf_obj, atomise = TRUE)
  jsonlite::fromJSON(geojson_str, simplifyVector = FALSE)
}


#' Calculate Bounding Box from sf Object
#'
#' @description
#' Calculates a bounding box from an sf object in the format required by STAC.
#'
#' @param sf_obj An sf object.
#'
#' @return A numeric vector of length 4: c(west, south, east, north).
#'
#' @export
bbox_from_sf <- function(sf_obj) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required")
  }

  bbox <- sf::st_bbox(sf_obj)
  c(bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"])
}


#' Extract Spatial Metadata from a Terra SpatRaster
#'
#' @description
#' Internal function to extract spatial metadata (geometry, bbox) from a
#' `SpatRaster` object.
#'
#' @param terra_obj A `SpatRaster` object.
#' @param reproject_to_wgs84 If TRUE, reprojects to WGS84.
#'
#' @return A list with geometry and bbox.
#'
#' @keywords internal
extract_terra_spatial_metadata <- function(terra_obj, reproject_to_wgs84 = TRUE) {
  crs <- sf::st_crs(terra::crs(terra_obj))
  bbox_sfc <- sf::st_as_sfc(
    sf::st_bbox(
      c(
        xmin = terra::xmin(terra_obj),
        ymin = terra::ymin(terra_obj),
        xmax = terra::xmax(terra_obj),
        ymax = terra::ymax(terra_obj)
      ),
      crs = crs
    )
  )
  bbox_sf <- sf::st_as_sf(data.frame(geometry = bbox_sfc))

  if (reproject_to_wgs84 && !isTRUE(crs$epsg == 4326L)) {
    bbox_sf <- sf::st_transform(bbox_sf, 4326)
  }

  list(
    geometry = geometry_from_sf(bbox_sf),
    bbox = bbox_from_sf(bbox_sf)
  )
}


#' Add Projection Extension Metadata from a Terra SpatRaster
#'
#' @description
#' Adds projection extension metadata to a STAC Item for rasters not in WGS84.
#'
#' @param item A STAC Item object.
#' @param terra_obj A `SpatRaster` object.
#'
#' @return The modified STAC Item.
#'
#' @keywords internal
add_projection_metadata_terra <- function(item, terra_obj) {
  ext_uri <- "https://stac-extensions.github.io/projection/v1.1.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  crs <- terra::crs(terra_obj, describe = TRUE)

  if (!is.na(crs$code)) {
    item@properties$`proj:epsg` <- as.integer(crs$code)
  }

  item@properties$`proj:wkt2` <- terra::crs(terra_obj)

  item@properties$`proj:shape` <- c(
    terra::nrow(terra_obj),
    terra::ncol(terra_obj)
  )


  # add affine transform parameters  
  item@properties$`proj:transform` <- c(
    terra::ext(terra_obj)$xmin, # xoff
    terra::xres(terra_obj),     # xscale
    0,                          # xskew
    terra::ext(terra_obj)$ymax, # yoff
    0,                          # yskew
    -terra::yres(terra_obj)     # yscale (negative)
  )

  item
}


#' Normalize an href for use in a STAC asset
#'
#' @description
#' Expands local file paths (e.g. `~/...`) to absolute paths so they are valid
#' URIs. Remote URLs (containing `://`) are returned unchanged.
#'
#' @param href A file path or URL string.
#'
#' @return A normalized path or unchanged URL string.
#'
#' @keywords internal
normalize_href <- function(href) {
  if (!grepl("://", href, fixed = TRUE)) {
    href <- normalizePath(href, mustWork = FALSE)
    href <- gsub("\\\\", "/", href)
  }
  href
}


#' Get Media Type for File
#'
#' @description
#' Determines the appropriate MIME type for a file based on extension.
#' For GeoTIFF files that exist locally, checks whether the file is a
#' Cloud Optimized GeoTIFF and appends "; profile=cloud-optimized" if so.
#'
#' @param file File path or URL.
#'
#' @return Media type string.
#'
#' @keywords internal
get_media_type <- function(file) {
  ext <- tolower(tools::file_ext(file))

  base_type <- switch(ext,
    "tif" = "image/tiff; application=geotiff",
    "tiff" = "image/tiff; application=geotiff",
    "nc" = "application/netcdf",
    "hdf" = "application/x-hdf",
    "hdf5" = "application/x-hdf5",
    "h5" = "application/x-hdf5",
    "json" = "application/json",
    "geojson" = "application/geo+json",
    "shp" = "application/x-shapefile",
    "png" = "image/png",
    "jpg" = "image/jpeg",
    "jpeg" = "image/jpeg",
    "application/octet-stream" # Default
  )

  if (ext %in% c("tif", "tiff") && is_cog(file)) {
    base_type <- paste0(base_type, "; profile=cloud-optimized")
  }

  base_type
}


#' Check whether a local GeoTIFF is a Cloud Optimized GeoTIFF
#'
#' @description
#' Uses GDAL structural metadata to detect the COG layout flag. Returns FALSE
#' for remote URLs or files that cannot be read.
#'
#' @param file File path (local only; URLs return FALSE).
#'
#' @return Logical scalar.
#'
#' @keywords internal
is_cog <- function(file) {
  if (grepl("://", file, fixed = TRUE)) {
    return(FALSE)
  }
  local_path <- normalizePath(file, mustWork = FALSE)
  if (!file.exists(local_path)) {
    return(FALSE)
  }
  tryCatch(
    {
      info <- sf::gdal_utils("info", source = local_path, quiet = TRUE)
      grepl("LAYOUT=COG", info, fixed = TRUE)
    },
    error = function(e) FALSE
  )
}


#' Create Collection Extent from Multiple Items
#'
#' @description
#' Calculates the spatial and temporal extent for a collection from a list of items.
#'
#' @param items A list of STAC Item objects.
#'
#' @return A list with spatial and temporal extent suitable for `stac_collection()`.
#'
#' @examples
#' \dontrun{
#' items <- list(item1, item2, item3)
#' extent <- extent_from_items(items)
#'
#' collection <- stac_collection(
#'   id = "my-collection",
#'   description = "Collection of items",
#'   license = "CC0-1.0",
#'   extent = extent
#' )
#' }
#'
#' @export
extent_from_items <- function(items) {
  if (length(items) == 0) {
    stop("No items provided")
  }

  # Extract all bboxes
  bboxes <- lapply(items, function(item) item@bbox)

  # Calculate overall spatial extent
  xmins <- sapply(bboxes, function(b) b[1])
  ymins <- sapply(bboxes, function(b) b[2])
  xmaxs <- sapply(bboxes, function(b) b[3])
  ymaxs <- sapply(bboxes, function(b) b[4])

  overall_bbox <- c(
    min(xmins),
    min(ymins),
    max(xmaxs),
    max(ymaxs)
  )

  # Extract all datetimes
  datetimes <- character()

  for (item in items) {
    if (!is.null(item@properties$datetime) && item@properties$datetime != "null") {
      datetimes <- c(datetimes, item@properties$datetime)
    } else if (!is.null(item@properties$start_datetime)) {
      datetimes <- c(datetimes, item@properties$start_datetime)
    }

    if (!is.null(item@properties$end_datetime)) {
      datetimes <- c(datetimes, item@properties$end_datetime)
    }
  }

  if (length(datetimes) == 0) {
    stop("No datetime information found in items")
  }

  # Calculate temporal extent
  temporal_start <- min(datetimes)
  temporal_end <- max(datetimes)

  # If all datetimes are the same, use NULL for end (ongoing)
  if (temporal_start == temporal_end) {
    temporal_end <- NULL
  }

  stac_extent(
    spatial_bbox = list(overall_bbox),
    temporal_interval = list(list(temporal_start, temporal_end))
  )
}


#' Extract Raster Band Metadata from a Terra SpatRaster
#'
#' @description
#' Extracts band metadata from a `SpatRaster` object. Creates band objects with
#' data type and spatial resolution, optionally calculating statistics.
#'
#' @param terra_obj A `SpatRaster` object (from the `terra` package).
#' @param calculate_statistics (logical, optional) If TRUE, calculates min, max,
#'   mean, and standard deviation for each band. Default is FALSE.
#' @param sample_size (integer, optional) Number of pixels to sample per band
#'   when calculating statistics. Default is 1000 pixels.
#'
#' @return A list of raster band objects, one per band.
#'
#' @export
bands_from_terra <- function(terra_obj, calculate_statistics = FALSE, sample_size = 1000L) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }

  if (!inherits(terra_obj, "SpatRaster")) {
    stop("'terra_obj' must be a SpatRaster object")
  }

  spatial_resolution <- mean(terra::res(terra_obj))
  n_bands <- terra::nlyr(terra_obj)

  data_types <- vapply(
    seq_len(n_bands),
    function(i) terra_dtype(terra::datatype(terra_obj)[i]),
    character(1)
  )

  bands <- vector("list", n_bands)

  for (i in seq_len(n_bands)) {
    band <- raster_band(
      data_type = data_types[[i]],
      spatial_resolution = spatial_resolution
    )

    if (calculate_statistics) {
      if (!is.null(sample_size)) {
        vals <- as.vector(
          terra::spatSample(terra_obj[[i]], sample_size, as.df = FALSE)
        )
      } else {
        vals <- as.vector(terra::values(terra_obj[[i]]))
      }

      if (length(vals) > 0) {
        band@statistics <- raster_statistics(
          minimum = min(vals, na.rm = TRUE),
          maximum = max(vals, na.rm = TRUE),
          mean = mean(vals, na.rm = TRUE),
          stddev = stats::sd(vals, na.rm = TRUE),
          valid_percent = 100 * length(vals[!is.na(vals)]) / length(vals)
        )
      }
    }

    bands[[i]] <- band
  }

  bands
}


#' Map terra datatype string to STAC raster data type string
#'
#' @keywords internal
terra_dtype <- function(dt) {
  switch(dt,
    "INT1U"  = "uint8",
    "INT2U"  = "uint16",
    "INT2S"  = "int16",
    "INT4U"  = "uint32",
    "INT4S"  = "int32",
    "FLT4S"  = "float32",
    "FLT8S"  = "float64",
    "other"
  )
}


#' Determine data type from a file path using GDAL
#'
#' @description
#' Parses `gdalinfo` output to extract the GDAL data type and maps it to the
#' STAC raster extension type string. More accurate than inferring from R's
#' `typeof()`, which loses precision (e.g. UInt16 and Int32 both appear as
#' "integer").
#'
#' @param file Local file path.
#'
#' @return A STAC raster data type string, or `"other"` if not determinable.
#'
#' @keywords internal
gdal_dtype <- function(file) {
  if (!file.exists(file)) return("other")
  tryCatch(
    {
      info <- sf::gdal_utils("info", source = file, quiet = TRUE)
      # gdalinfo reports e.g. "Type=Float32" once per band — take the first
      m <- regmatches(info, regexpr("Type=(\\w+)", info))
      if (length(m) == 0) return("other")
      gdal_type <- sub("Type=", "", m[[1]])
      switch(gdal_type,
        "Byte"     = "uint8",
        "UInt16"   = "uint16",
        "Int16"    = "int16",
        "UInt32"   = "uint32",
        "Int32"    = "int32",
        "Float32"  = "float32",
        "Float64"  = "float64",
        "CInt16"   = "cint16",
        "CInt32"   = "cint32",
        "CFloat32" = "cfloat32",
        "CFloat64" = "cfloat64",
        "other"
      )
    },
    error = function(e) "other"
  )
}


#' Extract the NoData Value from a File Using GDAL
#'
#' @keywords internal
gdal_nodata <- function(file) {
  if (!file.exists(file)) return(NULL)
  tryCatch(
    {
      info <- sf::gdal_utils("info", source = file, quiet = TRUE)
      m <- regmatches(info, regexpr("NoData Value=([^\\n\\r]+)", info))
      if (length(m) == 0) return(NULL)
      val <- trimws(sub("NoData Value=", "", m[[1]]))
      as.numeric(val)
    },
    error = function(e) NULL
  )
}


#' Batch Create Items from Raster Files
#'
#' @description
#' Creates multiple STAC Items from a directory of raster files.
#'
#' @param directory Directory containing raster files.
#' @param pattern File pattern to match (regex). Default matches common raster formats.
#' @param datetime_from_filename Function to extract datetime from filename.
#'   Should return ISO 8601 string. If NULL, uses current time.
#' @param ... Additional arguments passed to `item_from_terra()`.
#'
#' @return A list of STAC Item objects.
#'
#' @examples
#' \dontrun{
#' # Create items for all GeoTIFFs in a directory
#' items <- items_from_directory(
#'   "path/to/rasters",
#'   pattern = "\\.tif$"
#' )
#'
#' # With custom datetime extraction
#' extract_datetime <- function(filename) {
#'   # Extract date from filename like "LC08_20230615_..."
#'   date_str <- sub(".*_(\\d{8})_.*", "\\1", filename)
#'   paste0(
#'     substr(date_str, 1, 4), "-",
#'     substr(date_str, 5, 6), "-",
#'     substr(date_str, 7, 8), "T00:00:00Z"
#'   )
#' }
#'
#' items <- items_from_directory(
#'   "landsat",
#'   datetime_from_filename = extract_datetime
#' )
#' }
#'
#' @export
items_from_directory <- function(
  directory,
  pattern = "\\.(tif|tiff|nc|hdf|hdf5)$",
  datetime_from_filename = NULL,
  ...
) {
  if (!dir.exists(directory)) {
    stop(sprintf("Directory not found: %s", directory))
  }

  # Find matching files
  files <- list.files(
    directory,
    pattern = pattern,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) == 0) {
    stop(sprintf(
      "No files matching pattern '%s' found in %s",
      pattern,
      directory
    ))
  }

  message(sprintf("Creating items for %d files...", length(files)))

  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }

  # Create items
  items <- list()

  for (file in files) {
    # Extract datetime if function provided
    datetime <- if (!is.null(datetime_from_filename)) {
      datetime_from_filename(basename(file))
    } else {
      NULL
    }

    tryCatch(
      {
        r <- terra::rast(file)
        item <- item_from_terra(
          terra_obj = r,
          href = normalizePath(file),
          datetime = datetime,
          ...
        )
        items[[length(items) + 1]] <- item
        message(sprintf("  \u2713 Created item: %s", item@id))
      },
      error = function(e) {
        warning(sprintf(
          "  \u2717 Failed to create item for %s: %s",
          basename(file),
          e$message
        ))
      }
    )
  }

  message(sprintf("Successfully created %d items", length(items)))

  items
}
