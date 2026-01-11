#' Create a STAC Item from a Raster File
#'
#' @description
#' Creates a STAC Item from a raster file using the terra package. Automatically 
#' extracts spatial metadata including geometry, bbox, CRS, and optionally band 
#' information and statistics.
#'
#' @param file (character, required) Path to the raster file (GeoTIFF, NetCDF, etc.).
#' @param id (character, optional) Item ID. If NULL, uses the filename without extension.
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
#' This function automates the creation of STAC Items from raster files by:
#' 1. Reading the raster metadata using terra
#' 2. Extracting the spatial extent and converting to bbox
#' 3. Creating a geometry polygon from the extent
#' 4. Reprojecting to WGS84 if necessary (STAC standard)
#' 5. Optionally extracting band metadata and statistics
#' 6. Creating the STAC Item with appropriate extensions
#'
#' **STAC CRS Requirement:**
#' STAC Items must use WGS84 (EPSG:4326) for geometry and bbox. If your raster 
#' uses a different CRS, the geometry will be reprojected automatically when 
#' `reproject_to_wgs84 = TRUE`.
#'
#' @return A STAC Item object with the raster metadata.
#'
#' @examples
#' \dontrun{
#' # Basic item creation
#' item <- item_from_raster(
#'   file = "path/to/image.tif",
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#'
#' # With statistics
#' item <- item_from_raster(
#'   file = "landsat8.tif",
#'   id = "LC08_001",
#'   datetime = "2023-06-15T10:30:00Z",
#'   properties = list(platform = "landsat-8"),
#'   calculate_statistics = TRUE
#' )
#'
#' # With custom asset configuration
#' item <- item_from_raster(
#'   file = "sentinel2.tif",
#'   asset_key = "visual",
#'   asset_roles = c("data", "visual"),
#'   add_eo_bands = TRUE
#' )
#' }
#'
#' @export
item_from_raster <- function(file,
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
                             ...) {
  
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }
  
  if (!file.exists(file)) {
    stop(sprintf("File not found: %s", file))
  }
  
  # Read raster
  r <- terra::rast(file)
  
  # Generate ID if not provided
  if (is.null(id)) {
    id <- tools::file_path_sans_ext(basename(file))
  }
  
  # Use current time if datetime not provided
  if (is.null(datetime)) {
    datetime <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
    warning("No datetime provided, using current time")
  }
  
  # Extract spatial metadata
  spatial_meta <- extract_raster_spatial_metadata(r, reproject_to_wgs84)
  
  # Create the item
  item <- stac_item(
    id = id,
    geometry = spatial_meta$geometry,
    bbox = spatial_meta$bbox,
    datetime = datetime,
    properties = properties,
    ...
  )
  
  # Add the main raster as an asset
  item <- add_asset(
    item,
    key = asset_key,
    href = normalizePath(file),
    type = get_media_type(file),
    roles = asset_roles
  )
  
  # Add any additional assets
  if (length(assets) > 0) {
    for (asset_name in names(assets)) {
      asset <- assets[[asset_name]]
      item <- add_asset(
        item,
        key = asset_name,
        href = asset$href,
        title = asset$title,
        type = asset$type,
        roles = asset$roles
      )
    }
  }
  
  # Extract and add band information
  if (add_raster_bands || add_eo_bands) {
    bands <- raster_from_file(
      file,
      calculate_statistics = calculate_statistics
    )
    
    if (add_raster_bands) {
      item <- add_raster_extension(
        item,
        bands = bands,
        asset_key = asset_key
      )
    }
    
    if (add_eo_bands) {
      # Note: EO bands typically need wavelength info which isn't in raster metadata
      # This would need to be provided separately
      warning("EO extension requires wavelength metadata not available in raster file")
    }
  }
  
  # Add projection extension info if CRS is not WGS84
  if (!is_wgs84(terra::crs(r))) {
    item <- add_projection_metadata(item, r, asset_key)
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
#' @param asset_href (character, optional) If provided, creates an asset pointing 
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
item_from_sf <- function(sf_obj,
                        id,
                        datetime,
                        properties = list(),
                        asset_href = NULL,
                        ...) {
  
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
  if (!is.null(asset_href)) {
    item <- add_asset(
      item,
      key = "source",
      href = asset_href,
      type = get_media_type(asset_href),
      roles = c("data")
    )
  }
  
  item
}


#' Convert sf Geometry to GeoJSON
#'
#' @description
#' Converts an sf object's geometry to a GeoJSON-compatible list structure.
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
    stop("Package 'geojsonsf' is required. Install with: install.packages('geojsonsf')")
  }
  
  # Get the first feature (STAC items represent single features)
  if (nrow(sf_obj) > 1) {
    warning("sf object has multiple features, using only the first")
    sf_obj <- sf_obj[1, ]
  }
  
  # Convert to GeoJSON string then parse to list
  geojson_str <- geojsonsf::sf_geojson(sf_obj, atomise = TRUE)
  geojson_list <- jsonlite::fromJSON(geojson_str, simplifyVector = FALSE)
  
  # Extract geometry
  geojson_list$geometry
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


#' Extract Spatial Metadata from Raster
#'
#' @description
#' Internal function to extract spatial metadata (geometry, bbox) from a raster.
#'
#' @param r A SpatRaster object from terra.
#' @param reproject_to_wgs84 If TRUE, reprojects to WGS84.
#'
#' @return A list with geometry and bbox.
#'
#' @keywords internal
extract_raster_spatial_metadata <- function(r, reproject_to_wgs84 = TRUE) {
  
  # Get extent
  ext <- terra::ext(r)
  
  # Create polygon from extent
  poly <- terra::as.polygons(ext, crs = terra::crs(r))
  
  # Reproject to WGS84 if needed
  if (reproject_to_wgs84 && !is_wgs84(terra::crs(r))) {
    poly <- terra::project(poly, "EPSG:4326")
  }
  
  # Convert to sf for easier GeoJSON conversion
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for CRS transformation")
  }
  
  poly_sf <- sf::st_as_sf(poly)
  
  # Get geometry as GeoJSON
  geometry <- geometry_from_sf(poly_sf)
  
  # Get bbox
  bbox <- bbox_from_sf(poly_sf)
  
  list(
    geometry = geometry,
    bbox = bbox
  )
}


#' Check if CRS is WGS84
#'
#' @description
#' Checks if a CRS string represents WGS84 (EPSG:4326).
#'
#' @param crs_str CRS string from terra::crs().
#'
#' @return Logical indicating if CRS is WGS84.
#'
#' @keywords internal
is_wgs84 <- function(crs_str) {
  if (is.null(crs_str) || crs_str == "") {
    return(FALSE)
  }
  
  # Check for common WGS84 identifiers
  grepl("EPSG:4326|WGS 84.*84|CRS84", crs_str, ignore.case = TRUE)
}


#' Add Projection Extension Metadata
#'
#' @description
#' Adds projection extension metadata to a STAC Item for rasters not in WGS84.
#'
#' @param item A STAC Item object.
#' @param r A SpatRaster object.
#' @param asset_key The asset key to add projection metadata to.
#'
#' @return The modified STAC Item.
#'
#' @keywords internal
add_projection_metadata <- function(item, r, asset_key) {
  
  # Add projection extension URI
  ext_uri <- "https://stac-extensions.github.io/projection/v1.1.0/schema.json"
  
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  
  # Get CRS info
  crs_info <- terra::crs(r, describe = TRUE)
  
  # Add projection fields to asset
  if (!is.null(item$assets[[asset_key]])) {
    # Get EPSG code if available
    if (!is.na(crs_info$code) && !is.null(crs_info$code)) {
      item$assets[[asset_key]]$`proj:epsg` <- as.integer(crs_info$code)
    }
    
    # Add WKT2
    item$assets[[asset_key]]$`proj:wkt2` <- terra::crs(r)
    
    # Add shape (rows, cols)
    item$assets[[asset_key]]$`proj:shape` <- c(terra::nrow(r), terra::ncol(r))
    
    # Add transform (affine transformation matrix)
    res <- terra::res(r)
    ext <- terra::ext(r)
    item$assets[[asset_key]]$`proj:transform` <- c(
      res[1], 0, ext$xmin,
      0, -res[2], ext$ymax
    )
  }
  
  item
}


#' Get Media Type for File
#'
#' @description
#' Determines the appropriate MIME type for a file based on extension.
#'
#' @param file File path.
#'
#' @return Media type string.
#'
#' @keywords internal
get_media_type <- function(file) {
  ext <- tolower(tools::file_ext(file))
  
  switch(
    ext,
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
    "application/octet-stream"  # Default
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
    if (!is.null(item$properties$datetime) && 
        item$properties$datetime != "null") {
      datetimes <- c(datetimes, item$properties$datetime)
    } else if (!is.null(item$properties$start_datetime)) {
      datetimes <- c(datetimes, item$properties$start_datetime)
    }
    
    if (!is.null(item$properties$end_datetime)) {
      datetimes <- c(datetimes, item$properties$end_datetime)
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


#' Batch Create Items from Raster Files
#'
#' @description
#' Creates multiple STAC Items from a directory of raster files.
#'
#' @param directory Directory containing raster files.
#' @param pattern File pattern to match (regex). Default matches common raster formats.
#' @param datetime_from_filename Function to extract datetime from filename. 
#'   Should return ISO 8601 string. If NULL, uses current time.
#' @param ... Additional arguments passed to `item_from_raster()`.
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
items_from_directory <- function(directory,
                                 pattern = "\\.(tif|tiff|nc|hdf|hdf5)$",
                                 datetime_from_filename = NULL,
                                 ...) {
  
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
    stop(sprintf("No files matching pattern '%s' found in %s", pattern, directory))
  }
  
  message(sprintf("Creating items for %d files...", length(files)))
  
  # Create items
  items <- list()
  
  for (file in files) {
    # Extract datetime if function provided
    datetime <- if (!is.null(datetime_from_filename)) {
      datetime_from_filename(basename(file))
    } else {
      NULL
    }
    
    tryCatch({
      item <- item_from_raster(
        file = file,
        datetime = datetime,
        ...
      )
      items[[length(items) + 1]] <- item
      message(sprintf("  ✓ Created item: %s", item$id))
    }, error = function(e) {
      warning(sprintf("  ✗ Failed to create item for %s: %s", 
                     basename(file), e$message))
    })
  }
  
  message(sprintf("Successfully created %d items", length(items)))
  
  items
}
