#' Create a STAC Item from a Stars Object
#'
#' @description
#' Creates a STAC Item from a `stars` raster object. Automatically extracts
#' spatial metadata including geometry, bbox, CRS, and optionally band
#' information and statistics.
#'
#' @param stars_obj A `stars` object.
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
#' library(stars)
#'
#' r <- read_stars("path/to/image.tif")
#'
#' item <- item_from_stars(
#'   r,
#'   href = "path/to/image.tif",
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#'
#' item <- item_from_stars(
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
item_from_stars <- function(
  stars_obj,
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
  if (!requireNamespace("stars", quietly = TRUE)) {
    stop("Package 'stars' is required. Install with: install.packages('stars')")
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required. Install with: install.packages('sf')")
  }

  if (!inherits(stars_obj, "stars")) {
    stop("'stars_obj' must be a stars object")
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
  spatial_meta <- extract_stars_spatial_metadata(stars_obj, reproject_to_wgs84)

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
    bands <- bands_from_stars(
      stars_obj,
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
  crs <- sf::st_crs(stars_obj)
  if (!isTRUE(crs$epsg == 4326L)) {
    item <- add_projection_metadata_stars(item, stars_obj)
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


#' Extract Spatial Metadata from a Stars Object
#'
#' @description
#' Internal function to extract spatial metadata (geometry, bbox) from a stars
#' object.
#'
#' @param stars_obj A stars object.
#' @param reproject_to_wgs84 If TRUE, reprojects to WGS84.
#'
#' @return A list with geometry and bbox.
#'
#' @keywords internal
extract_stars_spatial_metadata <- function(stars_obj, reproject_to_wgs84 = TRUE) {
  bbox_sfc <- sf::st_as_sfc(sf::st_bbox(stars_obj))
  bbox_sf <- sf::st_as_sf(data.frame(geometry = bbox_sfc))

  if (reproject_to_wgs84 && !isTRUE(sf::st_crs(stars_obj)$epsg == 4326L)) {
    bbox_sf <- sf::st_transform(bbox_sf, 4326)
  }

  list(
    geometry = geometry_from_sf(bbox_sf),
    bbox = bbox_from_sf(bbox_sf)
  )
}


#' Add Projection Extension Metadata from a Stars Object
#'
#' @description
#' Adds projection extension metadata to a STAC Item for rasters not in WGS84.
#'
#' @param item A STAC Item object.
#' @param stars_obj A stars object.
#'
#' @return The modified STAC Item.
#'
#' @keywords internal
add_projection_metadata_stars <- function(item, stars_obj) {
  ext_uri <- "https://stac-extensions.github.io/projection/v1.1.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  crs <- sf::st_crs(stars_obj)
  dims <- stars::st_dimensions(stars_obj)

  if (!is.na(crs$epsg)) {
    item@properties$`proj:epsg` <- as.integer(crs$epsg)
  }

  item@properties$`proj:wkt2` <- crs$wkt

  x_dim <- dims[["x"]]
  y_dim <- dims[["y"]]
  item@properties$`proj:shape` <- c(
    y_dim$to - y_dim$from + 1L,
    x_dim$to - x_dim$from + 1L
  )

  item@properties$`proj:transform` <- c(
    x_dim$delta, 0, x_dim$offset,
    0, y_dim$delta, y_dim$offset
  )

  item
}


#' Create a STAC Item from a SpatRaster Object
#'
#' @description
#' Creates a STAC Item from a `terra` `SpatRaster` object. Automatically
#' extracts spatial metadata including geometry, bbox, CRS, and optionally
#' band information and statistics.
#'
#' @param spat_rast A `SpatRaster` object (from the `terra` package).
#' @param href (character, optional) URI for the main raster asset. If
#'   provided, the raster is added as an asset and `id` is derived from the
#'   basename when not explicitly set. If NULL, no asset is added and `id`
#'   must be supplied.
#' @param id (character, optional) Item ID. If NULL, derived from `href`
#'   basename.
#' @param datetime (character, optional) ISO 8601 datetime string. If NULL,
#'   uses current time.
#' @param properties (list, optional) Additional properties for the item.
#' @param assets (list, optional) Additional assets beyond the main raster.
#' @param asset_key (character, optional) Key name for the main raster asset.
#'   Default is `"data"`.
#' @param asset_roles (character vector, optional) Roles for the main raster
#'   asset. Default is `c("data")`.
#' @param add_raster_bands (logical, optional) If TRUE, adds raster extension
#'   with band metadata. Default is TRUE.
#' @param calculate_statistics (logical, optional) If TRUE, calculates band
#'   statistics (min, max, mean, stddev). Can be slow for large rasters.
#'   Default is FALSE.
#' @param reproject_to_wgs84 (logical, optional) If TRUE and raster is not in
#'   WGS84, reprojects the bbox geometry to WGS84 (EPSG:4326). STAC requires
#'   WGS84. Default is TRUE.
#' @param ... Additional arguments passed to `stac_item()`.
#'
#' @return A STAC Item object with the raster metadata.
#'
#' @examples
#' \dontrun{
#' library(terra)
#'
#' r <- rast("path/to/image.tif")
#'
#' item <- item_from_spatraster(
#'   r,
#'   href = "path/to/image.tif",
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#' }
#'
#' @export
item_from_spatraster <- function(
  spat_rast,
  href = NULL,
  id = NULL,
  datetime = NULL,
  properties = list(),
  assets = list(),
  asset_key = "data",
  asset_roles = c("data"),
  add_raster_bands = TRUE,
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

  if (!inherits(spat_rast, "SpatRaster")) {
    stop("'spat_rast' must be a SpatRaster object")
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
  spatial_meta <- extract_terra_spatial_metadata(spat_rast, reproject_to_wgs84)

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

  # Add raster extension band metadata
  if (add_raster_bands) {
    bands <- bands_from_spatraster(
      spat_rast,
      calculate_statistics = calculate_statistics
    )
    item <- add_raster_extension(
      item,
      bands = bands,
      asset_key = if (!is.null(href)) asset_key else NULL
    )
  }

  # Add projection extension if CRS is set and not WGS84
  crs_wkt <- terra::crs(spat_rast)
  epsg    <- suppressWarnings(
    as.integer(terra::crs(spat_rast, describe = TRUE)$code)
  )
  if (nchar(crs_wkt) > 0 && !isTRUE(epsg == 4326L)) {
    item <- add_projection_metadata_terra(item, spat_rast)
  }

  item
}


#' Extract Spatial Metadata from a SpatRaster Object
#'
#' @keywords internal
extract_terra_spatial_metadata <- function(spat_rast, reproject_to_wgs84 = TRUE) {
  crs_wkt <- terra::crs(spat_rast)

  # Convert extent polygon to sf
  bbox_sf <- sf::st_as_sf(
    terra::as.polygons(terra::ext(spat_rast), crs = crs_wkt)
  )

  epsg <- suppressWarnings(
    as.integer(terra::crs(spat_rast, describe = TRUE)$code)
  )

  if (reproject_to_wgs84 && nchar(crs_wkt) > 0 && !isTRUE(epsg == 4326L)) {
    bbox_sf <- sf::st_transform(bbox_sf, 4326)
  }

  list(
    geometry = geometry_from_sf(bbox_sf),
    bbox     = bbox_from_sf(bbox_sf)
  )
}


#' Add Projection Extension Metadata from a SpatRaster Object
#'
#' @keywords internal
add_projection_metadata_terra <- function(item, spat_rast) {
  ext_uri <- "https://stac-extensions.github.io/projection/v1.1.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }
  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  epsg <- suppressWarnings(
    as.integer(terra::crs(spat_rast, describe = TRUE)$code)
  )
  if (!is.na(epsg)) {
    item@properties$`proj:epsg` <- epsg
  }

  item@properties$`proj:wkt2`      <- terra::crs(spat_rast)
  item@properties$`proj:shape`     <- c(terra::nrow(spat_rast),
                                         terra::ncol(spat_rast))

  r <- terra::res(spat_rast)
  item@properties$`proj:transform` <- c(
    r[1], 0, terra::xmin(spat_rast),
    0, -r[2], terra::ymax(spat_rast)
  )

  item
}


#' Extract Raster Band Metadata from a SpatRaster Object
#'
#' @description
#' Extracts per-band metadata from a `SpatRaster` object. Creates band objects
#' with data type and spatial resolution, optionally calculating statistics.
#'
#' @param spat_rast A `SpatRaster` object.
#' @param calculate_statistics (logical, optional) If TRUE, calculates min,
#'   max, mean, and standard deviation for each layer using `terra::global()`.
#'   Default is FALSE.
#'
#' @return A list of raster band objects, one per layer.
#'
#' @export
bands_from_spatraster <- function(spat_rast, calculate_statistics = FALSE) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }
  if (!inherits(spat_rast, "SpatRaster")) {
    stop("'spat_rast' must be a SpatRaster object")
  }

  n_layers <- terra::nlyr(spat_rast)
  dtypes   <- terra::datatype(spat_rast)           # one per layer
  r        <- terra::res(spat_rast)
  spatial_resolution <- mean(r)

  bands <- vector("list", n_layers)

  for (i in seq_len(n_layers)) {
    band <- raster_band(
      data_type          = terra_dtype(dtypes[i]),
      spatial_resolution = spatial_resolution
    )

    if (calculate_statistics) {
      lyr    <- spat_rast[[i]]
      n_cell <- terra::ncell(lyr)
      n_valid <- terra::global(lyr, "notNA", na.rm = TRUE)[[1]]
      st     <- terra::global(lyr, c("min", "max", "mean", "sd"),
                              na.rm = TRUE)

      band$statistics <- raster_statistics(
        minimum      = st$min,
        maximum      = st$max,
        mean         = st$mean,
        stddev       = st$sd,
        valid_percent = 100 * n_valid / n_cell
      )
    }

    bands[[i]] <- band
  }

  bands
}


#' Map terra Data Type Strings to STAC Raster Data Types
#'
#' @keywords internal
terra_dtype <- function(dtype_str) {
  switch(dtype_str,
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
  bboxes <- lapply(items, function(item) item$bbox)

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
    if (!is.null(item@properties$datetime) && item$properties$datetime != "null") {
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
    temporal_interval = list(c(temporal_start, temporal_end))
  )
}


#' Extract Raster Band Metadata from a Stars Object
#'
#' @description
#' Extracts band metadata from a `stars` object. Creates band objects with data
#' type and spatial resolution, optionally calculating statistics.
#'
#' @param stars_obj A `stars` object.
#' @param calculate_statistics (logical, optional) If TRUE, calculates min, max,
#'   mean, and standard deviation for each band. Default is FALSE.
#' @param sample_size (integer, optional) Number of pixels to sample per band
#'   when calculating statistics. If NULL, all pixels are used.
#'
#' @return A list of raster band objects, one per band.
#'
#' @export
bands_from_stars <- function(stars_obj, calculate_statistics = FALSE, sample_size = NULL) {
  if (!requireNamespace("stars", quietly = TRUE)) {
    stop("Package 'stars' is required. Install with: install.packages('stars')")
  }

  if (!inherits(stars_obj, "stars")) {
    stop("'stars_obj' must be a stars object")
  }

  dims <- stars::st_dimensions(stars_obj)

  # Spatial resolution from x/y dimension deltas
  x_dim <- dims[["x"]]
  y_dim <- dims[["y"]]
  if (!is.null(x_dim) && !is.null(y_dim)) {
    spatial_resolution <- mean(c(abs(x_dim$delta), abs(y_dim$delta)))
  } else {
    spatial_resolution <- NULL
  }

  # Bands are either a named "band" dimension or separate attributes
  band_dim_idx <- which(names(dims) == "band")
  has_band_dim <- length(band_dim_idx) > 0
  is_proxy <- inherits(stars_obj, "stars_proxy")

  # For proxy objects, extract the source file path for GDAL dtype lookup
  proxy_file <- if (is_proxy) {
    src <- stars_obj[[1]][[1]]
    if (is.character(src) && file.exists(src)) src else NULL
  } else {
    NULL
  }

  if (has_band_dim) {
    n_bands <- dims[["band"]]$to - dims[["band"]]$from + 1L
    get_band_values <- function(i) {
      as.vector(stars_obj[, , , i][[1]])
    }
    data_type <- if (!is.null(proxy_file)) gdal_dtype(proxy_file) else stars_dtype(stars_obj[[1]])
    data_types <- rep(data_type, n_bands)
  } else {
    n_bands <- length(stars_obj)
    get_band_values <- function(i) as.vector(stars_obj[[i]])
    if (!is.null(proxy_file)) {
      data_type <- gdal_dtype(proxy_file)
      data_types <- rep(data_type, n_bands)
    } else {
      data_types <- vapply(
        seq_len(n_bands),
        function(i) stars_dtype(stars_obj[[i]]),
        character(1)
      )
    }
  }

  bands <- vector("list", n_bands)

  for (i in seq_len(n_bands)) {
    band <- raster_band(
      data_type = data_types[[i]],
      spatial_resolution = spatial_resolution
    )

    if (calculate_statistics) {
      all_vals <- get_band_values(i)
      n_total <- length(all_vals)
      vals <- all_vals[!is.na(all_vals)]

      if (!is.null(sample_size) && length(vals) > sample_size) {
        vals <- sample(vals, sample_size)
      }

      if (length(vals) > 0) {
        band$statistics <- raster_statistics(
          minimum = min(vals),
          maximum = max(vals),
          mean = mean(vals),
          stddev = stats::sd(vals),
          valid_percent = 100 * length(all_vals[!is.na(all_vals)]) / n_total
        )
      }
    }

    bands[[i]] <- band
  }

  bands
}


#' Map R typeof to STAC raster data type string
#'
#' @keywords internal
stars_dtype <- function(x) {
  switch(typeof(x),
    "integer" = "int32",
    "double"  = "float64",
    "logical" = "uint8",
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


#' Batch Create Items from Raster Files
#'
#' @description
#' Creates multiple STAC Items from a directory of raster files.
#'
#' @param directory Directory containing raster files.
#' @param pattern File pattern to match (regex). Default matches common raster formats.
#' @param datetime_from_filename Function to extract datetime from filename.
#'   Should return ISO 8601 string. If NULL, uses current time.
#' @param ... Additional arguments passed to `item_from_stars()`.
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

  if (!requireNamespace("stars", quietly = TRUE)) {
    stop("Package 'stars' is required. Install with: install.packages('stars')")
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
        r <- stars::read_stars(file, quiet = TRUE)
        item <- item_from_stars(
          stars_obj = r,
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
