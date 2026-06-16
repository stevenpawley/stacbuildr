# add_raster_extension ----

#' Add Raster Extension to a STAC Item or Asset
#'
#' @description
#' Adds the Raster Extension to a STAC Item or modifies an asset to include
#' raster-specific metadata. The Raster Extension describes raster assets at the
#' band level with information such as data type, nodata values, scale/offset
#' transforms, and statistics.
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
#' **Common Metadata:**
#' * `nodata`: Pixel values to be interpreted as nodata
#' * `data_type`: Data type of the band (e.g., "uint8", "int16", "float32")
#' * `unit`: Unit of measurement for pixel values
#' * `statistics`: Object with min, max, mean, stddev, valid_percent
#' * `raster`: Pixel sampling method ("area" or "point")
#' * `raster`: Actual number of bits used per sample
#' * `raster`: Average spatial resolution in meters
#' * `raster`: Multiplicative scaling factor to convert DN to values
#' * `raster`: Additive offset to convert DN to values
#' * `raster`: Histogram distribution of pixel values
#'
#' ## Scale and Offset
#' In remote sensing, raster data often stores raw Digital Numbers (DN) that
#' must be transformed to physical values using:
#'
#' **value = scale * DN + offset**
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

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  # Convert any S7 raster_band objects to plain lists for JSON serialization
  bands <- lapply(bands, function(b) {
    if (S7::S7_inherits(b, raster_band)) as.list(b) else b
  })

  # Add bands to asset or item properties
  if (!is.null(asset_key)) {
    # Add to specific asset
    if (is.null(item@assets[[asset_key]])) {
      stop(sprintf("Asset '%s' does not exist in item", asset_key))
    }

    item@assets[[asset_key]]$`raster:bands` <- bands
  } else {
    # Add to item properties
    item@properties$`raster:bands` <- bands
  }

  item
}

# raster_band ----

#' Creates a band object for use with the Raster Extension. Describes the
#' characteristics of a single raster band including data type, nodata values,
#' scale/offset transforms, and statistics.
#'
#' @description
#' `raster_band()` is an S7 object that is used to construct a `raster:bands`
#' STAC metadata entry
#'
#' @param nodata (numeric or NULL, optional) Pixel value(s) that should be
#'   interpreted as "no data". Can be a single value or vector of values. Common
#'   values: 0, -9999, NaN.
#' @param data_type (character, optional) Data type of the band. Must be one of:
#'   "int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64",
#'   "float16", "float32", "float64", "cint16", "cint32", "cfloat32",
#'   "cfloat64", or "other".
#' @param unit (character, optional) Unit of measurement for the pixel values.
#'   Examples: "m" (meters), "W sr-1 m-2" (radiance), "1"
#'   (unitless/reflectance).
#' @param statistics (list, optional) Statistics object created with
#'   `raster_statistics()` describing the distribution of pixel values.
#' @param sampling single length character, must be either 'point' where the
#'   pixel value represents a point sample at the centre of the pixel, or 'area'
#'   where the pixel value should be assumed to represent a sampling over the
#'   region of the pixel
#' @param bits_per_sample (integer, optional) Actual number of bits used for
#'   this band. Only needed when different from the standard for the data type
#'   (e.g., 1-bit data stored in uint8).
#' @param spatial_resolution (numeric, optional) Average spatial resolution of
#'   pixels in the band, in meters. Useful when resolution varies or differs
#'   from ground sample distance (gsd).
#' @param scale (numeric, optional) Multiplicative scaling factor to transform
#'   pixel values: `physical_value = scale * DN + offset`. Default is 1.
#' @param offset (numeric, optional) Additive offset to transform pixel values:
#'   `physical_value = scale * DN + offset`. Default is 0.
#' @param histogram (list, optional) Histogram object created with
#'   `raster_histogram()` describing the distribution of pixel values.
#' @param ... Additional fields for the band object. Can include fields from
#'   other extensions like `"common_name"`, `"center_wavelength"`.
#' @returns An S7 class representing a raster band object.
#' @export
raster_band <- S7::new_class(
  "raster_band",
  properties = list(
    nodata = S7::class_numeric,
    data_type = S7::new_property(
      S7::class_character,
      validator = function(value) {
        if (length(value) > 0) {
          valid_types <- c(
            "int8",
            "int16",
            "int32",
            "int64",
            "uint8",
            "uint16",
            "uint32",
            "uint64",
            "float16",
            "float32",
            "float64",
            "cint16",
            "cint32",
            "cfloat32",
            "cfloat64",
            "other"
          )

          if (!value %in% valid_types) {
            warning(sprintf(
              "'%s' is not a standard data type. Valid types: %s",
              value,
              paste(valid_types, collapse = ", ")
            ))
          }
        }
        return(NULL)
      }
    ),
    unit = S7::class_character,
    statistics = S7::class_any,
    sampling = S7::new_property(
      S7::class_character,
      validator = function(value) {
        if (length(value) > 0)
          if (!value %in% c("area", "point"))
            "'sampling' must be either 'area' or 'point'"
      }
    ),
    bits_per_sample = S7::class_integer,
    spatial_resolution = S7::new_property(
      S7::class_numeric,
      validator = function(value) {
        if (length(value) > 0)
          if (value <= 0)
            "'spatial_resolution' must be greater than zero"
      }
    ),
    scale = S7::new_property(S7::class_numeric, default = 1),
    offset = S7::new_property(S7::class_numeric, default = 0),
    histogram = S7::class_any,
    extra_fields = S7::new_property(S7::class_list, default = list())
  ),
  constructor = function(nodata = NULL,
                         data_type = NULL,
                         unit = NULL,
                         statistics = NULL,
                         sampling = NULL,
                         bits_per_sample = NULL,
                         spatial_resolution = NULL,
                         scale = 1,
                         offset = 0,
                         histogram = NULL,
                         ...) {
    S7::new_object(
      S7::S7_object(),
      nodata = nodata %||% numeric(0),
      data_type = data_type %||% character(0),
      unit = unit %||% character(0),
      statistics = statistics,
      sampling = sampling %||% character(0),
      bits_per_sample = if (is.null(bits_per_sample)) integer(0) else as.integer(bits_per_sample),
      spatial_resolution = spatial_resolution %||% numeric(0),
      scale = scale,
      offset = offset,
      histogram = histogram,
      extra_fields = list(...)
    )
  }
)

S7::method(as.list, raster_band) <- function(x, ...) {
  y <- list()

  if (length(x@nodata) > 0)
    y$nodata <- x@nodata

  if (length(x@data_type) > 0)
    y$data_type <- x@data_type

  if (length(x@unit) > 0)
    y$unit <- x@unit

  if (!is.null(x@statistics) && length(x@statistics) > 0)
    y$statistics <- x@statistics

  if (length(x@sampling) > 0)
    y$sampling <- x@sampling

  if (length(x@bits_per_sample) > 0)
    y$bits_per_sample <- x@bits_per_sample

  if (length(x@spatial_resolution) > 0)
    y$spatial_resolution <- x@spatial_resolution

  if (length(x@scale) > 0)
    y$scale <- x@scale

  if (length(x@offset) > 0)
    y$offset <- x@offset

  if (!is.null(x@histogram) && length(x@histogram) > 0)
    y$histogram <- x@histogram

  if (length(x@extra_fields) > 0)
    y <- c(y, x@extra_fields)

  return(y)
}

#' Print method for raster band objects
#'
#' @param x A raster band object
#' @param ... Additional arguments (ignored)
#'
#' @export
S7::method(print, raster_band) <- function(x, ...) {
  cat("Raster Band:\n")

  if (length(x@data_type) > 0) {
    cat("  Data Type:", x@data_type, "\n")
  }

  if (length(x@nodata) > 0) {
    cat("  NoData:", x@nodata, "\n")
  }

  if (length(x@spatial_resolution) > 0) {
    cat("  Spatial Resolution:", x@spatial_resolution, "m\n")
  }

  cat("  Transform: value =", x@scale, "* DN +", x@offset, "\n")

  if (length(x@unit) > 0) {
    cat("  Unit:", x@unit, "\n")
  }

  if (!is.null(x@statistics) && length(x@statistics) > 0) {
    cat("  Statistics:\n")
    if (!is.null(x@statistics$minimum)) {
      cat("    Min:", x@statistics$minimum, "\n")
    }
    if (!is.null(x@statistics$maximum)) {
      cat("    Max:", x@statistics$maximum, "\n")
    }
    if (!is.null(x@statistics$mean)) {
      cat("    Mean:", x@statistics$mean, "\n")
    }
    if (!is.null(x@statistics$stddev)) {
      cat("    Std Dev:", x@statistics$stddev, "\n")
    }
  }

  invisible(x)
}


# raster_statistics ----

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

  if (!is.null(minimum)) {
    stats$minimum <- minimum
  }
  if (!is.null(maximum)) {
    stats$maximum <- maximum
  }
  if (!is.null(mean)) {
    stats$mean <- mean
  }
  if (!is.null(stddev)) {
    stats$stddev <- stddev
  }
  if (!is.null(valid_percent)) {
    if (valid_percent < 0 || valid_percent > 100) {
      warning("'valid_percent' should be between 0 and 100")
    }
    stats$valid_percent <- valid_percent
  }

  stats
}

# raster_histogram ----

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
  if (length(count) != 1L || !is.numeric(count)) {
    stop("'count' must be a single number")
  }
  if (length(min) != 1L || !is.numeric(min)) {
    stop("'min' must be a single number")
  }
  if (length(max) != 1L || !is.numeric(max)) {
    stop("'max' must be a single number")
  }
  if (min >= max) {
    stop("'min' must be smaller than 'max'")
  }
  if (length(buckets) != count) {
    stop(sprintf(
      "'buckets' length (%d) must equal 'count' (%d)",
      length(buckets), as.integer(count)
    ))
  }

  list(
    count   = as.integer(count),
    min     = min,
    max     = max,
    buckets = as.integer(buckets)
  )
}


# raster_from_file ----
# TODO rename to band_from_file

#' Extract Raster Band Metadata from a File
#'
#' @description
#' Extracts raster metadata from a file using `stars` and `sf::gdal_utils`.
#' Creates band objects with data type, spatial resolution, and optionally
#' statistics.
#'
#' @param file (character, required) Path to the raster file.
#' @param calculate_statistics (logical, optional) If TRUE, calculates min, max,
#'   mean, and standard deviation for each band. Default is FALSE (can be slow
#'   for large files).
#' @param sample_size (integer, optional) Number of pixels to sample per band
#'   when calculating statistics. If NULL, all pixels are used.
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
  if (!requireNamespace("stars", quietly = TRUE)) {
    stop("Package 'stars' is required. Install with: install.packages('stars')")
  }

  r <- stars::read_stars(file, quiet = TRUE)
  bands_from_stars(r, calculate_statistics = calculate_statistics, sample_size = sample_size)
}
