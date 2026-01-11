#' Add Raster Extension to a STAC Item or Asset
#'
#' @description
#' Adds the Raster Extension to a STAC Item or modifies an asset to include 
#' raster-specific metadata. The Raster Extension describes raster assets at the 
#' band level with information such as data type, nodata values, scale/offset 
#' transforms, and statistics.
#'
#' **Important Note on STAC 1.1.0 Changes:**
#' In STAC 1.1.0, the `raster:bands` field was deprecated in favor of a common 
#' `bands` construct that merges functionality from both `eo:bands` and 
#' `raster:bands`. Some raster-specific fields (like `nodata`, `data_type`, 
#' `statistics`, `unit`) are now part of STAC common metadata and should be 
#' included directly in band objects. The remaining raster-specific fields 
#' (`raster:sampling`, `raster:bits_per_sample`, `raster:spatial_resolution`, 
#' `raster:scale`, `raster:offset`, `raster:histogram`) retain the `raster:` prefix.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param bands A list of band objects created with `raster_band()`. Each band 
#'   describes the characteristics of a single raster band (or layer). If the 
#'   asset has multiple bands, provide a list with one entry per band in order.
#' @param asset_key (character, optional) If provided, adds the bands to a 
#'   specific asset rather than to the item properties. Useful when different 
#'   assets have different band structures.
#'
#' @details
#' ## Extension Schema URI
#' The Raster Extension v1.1.0 schema URI is:
#' `https://stac-extensions.github.io/raster/v1.1.0/schema.json`
#'
#' ## Band Object Fields
#' Each band can contain both common metadata fields and raster-specific fields:
#'
#' **Common Metadata (no prefix):**
#' * `nodata`: Pixel values to be interpreted as nodata
#' * `data_type`: Data type of the band (e.g., "uint8", "int16", "float32")
#' * `unit`: Unit of measurement for pixel values
#' * `statistics`: Object with min, max, mean, stddev, valid_percent
#'
#' **Raster-Specific (raster: prefix):**
#' * `raster:sampling`: Pixel sampling method ("area" or "point")
#' * `raster:bits_per_sample`: Actual number of bits used per sample
#' * `raster:spatial_resolution`: Average spatial resolution in meters
#' * `raster:scale`: Multiplicative scaling factor to convert DN to values
#' * `raster:offset`: Additive offset to convert DN to values
#' * `raster:histogram`: Histogram distribution of pixel values
#'
#' ## Scale and Offset
#' In remote sensing, raster data often stores raw Digital Numbers (DN) that 
#' must be transformed to physical values using:
#' 
#' **value = scale × DN + offset**
#' 
#' For example, storing reflectance (0-1) as integers (0-10000) with scale=0.0001.
#'
#' ## Data Types
#' Supported data type values include:
#' * `"int8"`, `"int16"`, `"int32"`, `"int64"`
#' * `"uint8"`, `"uint16"`, `"uint32"`, `"uint64"`
#' * `"float16"`, `"float32"`, `"float64"`
#' * `"cint16"`, `"cint32"` (complex integers)
#' * `"cfloat32"`, `"cfloat64"` (complex floats)
#' * `"other"` (for custom types)
#'
#' @return The modified STAC Item with raster extension fields added.
#'
#' @seealso 
#' * [raster_band()] for creating band objects
#' * [raster_statistics()] for creating statistics objects
#' * [raster_histogram()] for creating histogram objects
#' * [add_asset()] for adding assets to items
#'
#' @references
#' Raster Extension Specification: 
#' \url{https://github.com/stac-extensions/raster}
#'
#' @examples
#' # Create an item
#' item <- stac_item(
#'   id = "my-raster",
#'   geometry = list(type = "Point", coordinates = c(-105, 40)),
#'   bbox = c(-105, 40, -105, 40),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' # Add a single-band raster asset
#' band <- raster_band(
#'   nodata = 0,
#'   data_type = "uint16",
#'   spatial_resolution = 30,
#'   scale = 0.0001,
#'   offset = 0
#' )
#'
#' item <- add_raster_extension(item, bands = list(band))
#'
#' # Add multi-band raster with statistics
#' red_band <- raster_band(
#'   nodata = 0,
#'   data_type = "uint16",
#'   spatial_resolution = 10,
#'   scale = 0.0001,
#'   offset = -0.1,
#'   statistics = raster_statistics(
#'     minimum = 1,
#'     maximum = 10000,
#'     mean = 2500,
#'     stddev = 1200,
#'     valid_percent = 99.5
#'   )
#' )
#'
#' green_band <- raster_band(
#'   nodata = 0,
#'   data_type = "uint16",
#'   spatial_resolution = 10,
#'   scale = 0.0001,
#'   offset = -0.1
#' )
#'
#' item <- item |>
#'   add_asset(
#'     key = "visual",
#'     href = "https://example.com/image.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_raster_extension(
#'     bands = list(red_band, green_band),
#'     asset_key = "visual"
#'   )
#'
#' @export
add_raster_extension <- function(item, bands, asset_key = NULL) {
  
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }
  
  if (!is.list(bands)) {
    stop("'bands' must be a list of band objects")
  }
  
  # Add extension to stac_extensions if not already present
  ext_uri <- "https://stac-extensions.github.io/raster/v1.1.0/schema.json"
  
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  
  # Add bands to asset or item properties
  if (!is.null(asset_key)) {
    # Add to specific asset
    if (is.null(item$assets[[asset_key]])) {
      stop(sprintf("Asset '%s' does not exist in item", asset_key))
    }
    
    item$assets[[asset_key]]$bands <- bands
  } else {
    # Add to item properties
    item$properties$bands <- bands
  }
  
  item
}


#' Create a Raster Band Object
#'
#' @description
#' Creates a band object for use with the Raster Extension. Describes the 
#' characteristics of a single raster band including data type, nodata values, 
#' scale/offset transforms, and statistics.
#'
#' @param nodata (numeric or NULL, optional) Pixel value(s) that should be 
#'   interpreted as "no data". Can be a single value or vector of values. 
#'   Common values: 0, -9999, NaN.
#' @param data_type (character, optional) Data type of the band. Must be one of: 
#'   "int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64", 
#'   "float16", "float32", "float64", "cint16", "cint32", "cfloat32", "cfloat64", 
#'   or "other".
#' @param unit (character, optional) Unit of measurement for the pixel values. 
#'   Examples: "m" (meters), "W⋅sr⁻¹⋅m⁻²" (radiance), "1" (unitless/reflectance).
#' @param statistics (list, optional) Statistics object created with 
#'   `raster_statistics()` describing the distribution of pixel values.
#' @param sampling (character, optional) Pixel sampling method. Either "area" 
#'   (pixel represents area) or "point" (pixel represents point). Default is "area".
#' @param bits_per_sample (integer, optional) Actual number of bits used for 
#'   this band. Only needed when different from the standard for the data type 
#'   (e.g., 1-bit data stored in uint8).
#' @param spatial_resolution (numeric, optional) Average spatial resolution of 
#'   pixels in the band, in meters. Useful when resolution varies or differs 
#'   from ground sample distance (gsd).
#' @param scale (numeric, optional) Multiplicative scaling factor to transform 
#'   pixel values: `physical_value = scale × DN + offset`. Default is 1.
#' @param offset (numeric, optional) Additive offset to transform pixel values: 
#'   `physical_value = scale × DN + offset`. Default is 0.
#' @param histogram (list, optional) Histogram object created with 
#'   `raster_histogram()` describing the distribution of pixel values.
#' @param ... Additional fields for the band object. Can include fields from 
#'   other extensions like `"eo:common_name"`, `"eo:center_wavelength"`.
#'
#' @return A list representing a raster band object.
#'
#' @examples
#' # Simple band with just data type
#' band <- raster_band(data_type = "uint8")
#'
#' # Band with nodata and scale/offset
#' band <- raster_band(
#'   nodata = 0,
#'   data_type = "uint16",
#'   scale = 0.0001,
#'   offset = 0,
#'   unit = "1"
#' )
#'
#' # Band with statistics
#' band <- raster_band(
#'   nodata = -9999,
#'   data_type = "int16",
#'   spatial_resolution = 30,
#'   statistics = raster_statistics(
#'     minimum = -1000,
#'     maximum = 8000,
#'     mean = 2500,
#'     stddev = 1500
#'   )
#' )
#'
#' # Band combining raster and EO extension
#' band <- raster_band(
#'   nodata = 0,
#'   data_type = "uint16",
#'   scale = 0.0001,
#'   offset = -0.1,
#'   spatial_resolution = 10,
#'   unit = "1",
#'   "eo:common_name" = "red",
#'   "eo:center_wavelength" = 0.665,
#'   "eo:full_width_half_max" = 0.038
#' )
#'
#' @export
raster_band <- function(nodata = NULL,
                       data_type = NULL,
                       unit = NULL,
                       statistics = NULL,
                       sampling = NULL,
                       bits_per_sample = NULL,
                       spatial_resolution = NULL,
                       scale = NULL,
                       offset = NULL,
                       histogram = NULL,
                       ...) {
  
  band <- list()
  
  # Common metadata fields (no prefix)
  if (!is.null(nodata)) band$nodata <- nodata
  if (!is.null(data_type)) {
    # Validate data_type
    valid_types <- c(
      "int8", "int16", "int32", "int64",
      "uint8", "uint16", "uint32", "uint64",
      "float16", "float32", "float64",
      "cint16", "cint32", "cfloat32", "cfloat64",
      "other"
    )
    if (!data_type %in% valid_types) {
      warning(sprintf(
        "'%s' is not a standard data type. Valid types: %s",
        data_type,
        paste(valid_types, collapse = ", ")
      ))
    }
    band$data_type <- data_type
  }
  if (!is.null(unit)) band$unit <- unit
  if (!is.null(statistics)) band$statistics <- statistics
  
  # Raster-specific fields (raster: prefix)
  if (!is.null(sampling)) {
    if (!sampling %in% c("area", "point")) {
      stop("'sampling' must be either 'area' or 'point'")
    }
    band$`raster:sampling` <- sampling
  }
  if (!is.null(bits_per_sample)) {
    band$`raster:bits_per_sample` <- as.integer(bits_per_sample)
  }
  if (!is.null(spatial_resolution)) {
    band$`raster:spatial_resolution` <- spatial_resolution
  }
  if (!is.null(scale)) band$`raster:scale` <- scale
  if (!is.null(offset)) band$`raster:offset` <- offset
  if (!is.null(histogram)) band$`raster:histogram` <- histogram
  
  # Add any extra fields (e.g., from EO extension)
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    band <- c(band, extra_fields)
  }
  
  band
}


#' Create Raster Statistics Object
#'
#' @description
#' Creates a statistics object for describing the distribution of pixel values 
#' in a raster band.
#'
#' @param minimum (numeric, optional) Minimum pixel value in the band.
#' @param maximum (numeric, optional) Maximum pixel value in the band.
#' @param mean (numeric, optional) Mean (average) pixel value in the band.
#' @param stddev (numeric, optional) Standard deviation of pixel values.
#' @param valid_percent (numeric, optional) Percentage of valid (non-nodata) 
#'   pixels. Should be between 0 and 100.
#'
#' @return A list representing a statistics object.
#'
#' @examples
#' stats <- raster_statistics(
#'   minimum = 0,
#'   maximum = 10000,
#'   mean = 2500,
#'   stddev = 1200,
#'   valid_percent = 99.8
#' )
#'
#' @export
raster_statistics <- function(minimum = NULL,
                             maximum = NULL,
                             mean = NULL,
                             stddev = NULL,
                             valid_percent = NULL) {
  
  stats <- list()
  
  if (!is.null(minimum)) stats$minimum <- minimum
  if (!is.null(maximum)) stats$maximum <- maximum
  if (!is.null(mean)) stats$mean <- mean
  if (!is.null(stddev)) stats$stddev <- stddev
  if (!is.null(valid_percent)) {
    if (valid_percent < 0 || valid_percent > 100) {
      warning("'valid_percent' should be between 0 and 100")
    }
    stats$valid_percent <- valid_percent
  }
  
  stats
}


#' Create Raster Histogram Object
#'
#' @description
#' Creates a histogram object describing the distribution of pixel values in a 
#' raster band. The histogram format follows the structure produced by GDAL's 
#' `gdalinfo -hist -json` command.
#'
#' @param count (integer, required) Number of buckets in the histogram.
#' @param min (numeric, required) Lower bound of the histogram.
#' @param max (numeric, required) Upper bound of the histogram.
#' @param buckets (integer vector, required) Array of counts for each bucket. 
#'   Length must equal `count`.
#'
#' @return A list representing a histogram object.
#'
#' @examples
#' # Simple histogram with 5 buckets
#' hist <- raster_histogram(
#'   count = 5,
#'   min = 0,
#'   max = 100,
#'   buckets = c(1500, 3200, 4100, 2800, 1400)
#' )
#'
#' @export
raster_histogram <- function(count, min, max, buckets) {
  
  if (missing(count) || missing(min) || missing(max) || missing(buckets)) {
    stop("'count', 'min', 'max', and 'buckets' are all required")
  }
  
  if (length(buckets) != count) {
    stop(sprintf(
      "'buckets' length (%d) must equal 'count' (%d)",
      length(buckets),
      count
    ))
  }
  
  list(
    count = as.integer(count),
    min = min,
    max = max,
    buckets = as.integer(buckets)
  )
}


#' Extract Raster Metadata from File
#'
#' @description
#' Extracts raster metadata from a raster file using the terra package. 
#' Creates band objects with data type, nodata values, and spatial resolution.
#' Optionally calculates statistics if requested.
#'
#' @param file (character, required) Path to the raster file.
#' @param calculate_statistics (logical, optional) If TRUE, calculates min, max, 
#'   mean, and standard deviation for each band. Default is FALSE (can be slow 
#'   for large files).
#' @param sample_size (integer, optional) Maximum number of pixels to sample 
#'   when calculating statistics. Helps speed up processing for large rasters. 
#'   Default is NULL (use all pixels).
#'
#' @return A list of raster band objects, one per band in the file.
#'
#' @examples
#' \dontrun{
#' # Extract basic metadata
#' bands <- raster_from_file("path/to/image.tif")
#'
#' # Extract metadata with statistics
#' bands <- raster_from_file(
#'   "path/to/image.tif",
#'   calculate_statistics = TRUE
#' )
#'
#' # Add to STAC item
#' item <- item |>
#'   add_asset("data", "path/to/image.tif", type = "image/tiff") |>
#'   add_raster_extension(bands = bands, asset_key = "data")
#' }
#'
#' @export
raster_from_file <- function(file,
                            calculate_statistics = FALSE,
                            sample_size = NULL) {
  
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }
  
  # Read raster
  r <- terra::rast(file)
  n_bands <- terra::nlyr(r)
  
  # Get resolution (average of x and y)
  res <- terra::res(r)
  spatial_resolution <- mean(res)
  
  # Create band objects
  bands <- list()
  
  for (i in seq_len(n_bands)) {
    band_data <- r[[i]]
    
    # Get data type
    dt <- terra::datatype(band_data)
    data_type <- switch(
      dt,
      "INT1U" = "uint8",
      "INT2S" = "int16",
      "INT2U" = "uint16",
      "INT4S" = "int32",
      "INT4U" = "uint32",
      "FLT4S" = "float32",
      "FLT8S" = "float64",
      "other"
    )
    
    # Get nodata value
    nodata_val <- terra::NAflag(band_data)
    if (is.na(nodata_val)) nodata_val <- NULL
    
    # Initialize band
    band <- raster_band(
      nodata = nodata_val,
      data_type = data_type,
      spatial_resolution = spatial_resolution
    )
    
    # Calculate statistics if requested
    if (calculate_statistics) {
      if (!is.null(sample_size)) {
        # Sample the raster
        vals <- terra::spatSample(band_data, size = sample_size, method = "random", 
                                 na.rm = TRUE, as.df = TRUE)[, 1]
      } else {
        # Use all values (can be slow)
        vals <- terra::values(band_data, mat = FALSE, na.rm = TRUE)
      }
      
      if (length(vals) > 0) {
        band$statistics <- raster_statistics(
          minimum = min(vals, na.rm = TRUE),
          maximum = max(vals, na.rm = TRUE),
          mean = mean(vals, na.rm = TRUE),
          stddev = sd(vals, na.rm = TRUE),
          valid_percent = 100 * length(vals) / terra::ncell(band_data)
        )
      }
    }
    
    bands[[i]] <- band
  }
  
  bands
}


#' Print method for raster band objects
#'
#' @param x A raster band object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.raster_band <- function(x, ...) {
  cat("Raster Band:\n")
  
  if (!is.null(x$data_type)) {
    cat("  Data Type:", x$data_type, "\n")
  }
  
  if (!is.null(x$nodata)) {
    cat("  NoData:", x$nodata, "\n")
  }
  
  if (!is.null(x$`raster:spatial_resolution`)) {
    cat("  Spatial Resolution:", x$`raster:spatial_resolution`, "m\n")
  }
  
  if (!is.null(x$`raster:scale`) || !is.null(x$`raster:offset`)) {
    scale <- x$`raster:scale` %||% 1
    offset <- x$`raster:offset` %||% 0
    cat("  Transform: value =", scale, "× DN +", offset, "\n")
  }
  
  if (!is.null(x$unit)) {
    cat("  Unit:", x$unit, "\n")
  }
  
  if (!is.null(x$statistics)) {
    cat("  Statistics:\n")
    if (!is.null(x$statistics$minimum)) {
      cat("    Min:", x$statistics$minimum, "\n")
    }
    if (!is.null(x$statistics$maximum)) {
      cat("    Max:", x$statistics$maximum, "\n")
    }
    if (!is.null(x$statistics$mean)) {
      cat("    Mean:", x$statistics$mean, "\n")
    }
    if (!is.null(x$statistics$stddev)) {
      cat("    Std Dev:", x$statistics$stddev, "\n")
    }
  }
  
  invisible(x)
}

# Helper operator for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a
