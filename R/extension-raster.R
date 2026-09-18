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
#' The Raster Extension v2.0.0 schema URI is:
#' `https://stac-extensions.github.io/raster/v2.0.0/schema.json`
#'
#' ## Band Object Fields
#' Version 2.0.0 removed the older `raster:bands` field in favour of the
#' unified `bands` array introduced by STAC 1.1.0. Each band holds both common
#' metadata fields and raster-specific ones:
#'
#' **Common Metadata:**
#' * `nodata`: Pixel values to be interpreted as nodata
#' * `data_type`: Data type of the band (e.g., "uint8", "int16", "float32")
#' * `unit`: Unit of measurement for pixel values
#' * `statistics`: Object with min, max, mean, stddev, valid_percent
#'
#' **Raster-specific (prefixed):**
#' * `raster:sampling`: Pixel sampling method ("area" or "point")
#' * `raster:bits_per_sample`: Actual number of bits used per sample
#' * `raster:spatial_resolution`: Average spatial resolution in meters
#' * `raster:scale`: Multiplicative scaling factor to convert DN to values
#' * `raster:offset`: Additive offset to convert DN to values
#' * `raster:histogram`: Histogram distribution of pixel values
#'
#' The arguments of [raster_band()] keep their unprefixed names; the prefix is
#' applied when the band is written out.
#'
#' Because `bands` is shared with the other band-level extensions,
#' [add_eo_extension()] can describe the same bands: passing a list of the same
#' length merges its fields into the bands already present rather than
#' replacing them.
#'
#' ## Scale and Offset
#' In remote sensing, raster data often stores raw Digital Numbers (DN) that
#' must be transformed to physical values using:
#'
#' **value = scale * DN + offset**
#'
#' For example, storing reflectance (0-1) as integers (0-10000) with
#' scale=0.0001.
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
    cli::cli_abort("'item' must be a stac_item object")
  }
  if (!is.list(bands)) {
    cli::cli_abort("'bands' must be a list of band objects")
  }
  if (
    length(bands) == 1 &&
      is.list(bands[[1]]) &&
      !inherits(bands[[1]], "raster_band")
  ) {
    cli::cli_abort(c(
      "'bands' appears to be double-wrapped.",
      i = "Use bands = band_from_file(...), not bands = list(band_from_file(...))."
    ))
  }
  ext_uri <- "https://stac-extensions.github.io/raster/v2.0.0/schema.json"
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  return(set_bands(item, bands, asset_key = asset_key))
}

# raster_band ----

#' Creates a band object for use with the Raster Extension. Describes the
#' characteristics of a single raster band including data type, nodata values,
#' scale/offset transforms, and statistics.
#'
#' @description
#' `raster_band()` is an S3 object that is used to construct an entry in the
#' `bands` array, carrying the Raster extension's fields
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
#' @returns An S3 class representing a raster band object.
#' @export
raster_band <- function(
  nodata = NULL,
  data_type = NULL,
  unit = NULL,
  statistics = NULL,
  sampling = NULL,
  bits_per_sample = NULL,
  spatial_resolution = NULL,
  scale = 1,
  offset = 0,
  histogram = NULL,
  ...
) {
  object <- list(
    nodata = nodata %||% numeric(0),
    data_type = data_type %||% character(0),
    unit = unit %||%
      character(0),
    statistics = as_raster_statistics(statistics),
    sampling = sampling %||% character(0),
    bits_per_sample = if (is.null(bits_per_sample)) {
      integer(0)
    } else {
      as.integer(bits_per_sample)
    },
    spatial_resolution = spatial_resolution %||% numeric(0),
    scale = scale,
    offset = offset,
    histogram = as_raster_histogram(histogram),
    extra_fields = list(...)
  )
  if (!is.numeric(object[["nodata"]])) {
    cli::cli_abort("nodata must be numeric.")
  }
  if (!is.character(object[["data_type"]])) {
    cli::cli_abort("data_type must be character.")
  }
  if (length(object[["data_type"]]) > 0) {
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
    if (!object[["data_type"]] %in% valid_types) {
      cli::cli_warn(c(
        "'{value}' is not a standard data type.",
        i = "Valid types: {paste(valid_types, collapse = ', ')}"
      ))
    }
  }
  if (!is.character(object[["unit"]])) {
    cli::cli_abort("unit must be character.")
  }
  if (
    !is.null(object[["statistics"]]) &&
      !inherits(object[["statistics"]], "raster_statistics")
  ) {
    cli::cli_abort(paste(
      "statistics",
      "must be a raster_statistics object or NULL"
    ))
  }
  if (!is.character(object[["sampling"]])) {
    cli::cli_abort("sampling must be character.")
  }
  if (length(object[["sampling"]]) > 0) {
    if (!object[["sampling"]] %in% c("area", "point")) {
      cli::cli_abort("'sampling' must be either 'area' or 'point'")
    }
  }
  if (!is.integer(object[["bits_per_sample"]])) {
    cli::cli_abort("bits_per_sample must be integer.")
  }
  if (!is.numeric(object[["spatial_resolution"]])) {
    cli::cli_abort("spatial_resolution must be numeric.")
  }
  if (length(object[["spatial_resolution"]]) > 0) {
    if (object[["spatial_resolution"]] <= 0) {
      cli::cli_abort("'spatial_resolution' must be greater than zero")
    }
  }
  if (!is.numeric(object[["scale"]])) {
    cli::cli_abort("scale must be numeric.")
  }
  if (!is.numeric(object[["offset"]])) {
    cli::cli_abort("offset must be numeric.")
  }
  if (
    !is.null(object[["histogram"]]) &&
      !inherits(object[["histogram"]], "raster_histogram")
  ) {
    cli::cli_abort(paste(
      "histogram",
      "must be a raster_histogram object or NULL"
    ))
  }
  if (!is.list(object[["extra_fields"]])) {
    cli::cli_abort("extra_fields must be list.")
  }
  class(object) <- c("raster_band", "stac_object")
  return(object)
}

#'
#' @exportS3Method
as.list.raster_band <- function(x, ...) {
  y <- list()

  if (length(x$nodata) > 0) {
    y$nodata <- x$nodata
  }

  if (length(x$data_type) > 0) {
    y$data_type <- x$data_type
  }

  if (length(x$unit) > 0) {
    y$unit <- x$unit
  }

  if (!is.null(x$statistics) && length(x$statistics) > 0) {
    y$statistics <- as.list(x$statistics)
  }

  # nodata, data_type, unit and statistics are STAC Common Metadata and keep
  # their bare names; everything below is raster-specific and, since v2.0.0 of
  # the extension, is written with a `raster:` prefix.
  if (length(x$sampling) > 0) {
    y$`raster:sampling` <- x$sampling
  }

  if (length(x$bits_per_sample) > 0) {
    y$`raster:bits_per_sample` <- x$bits_per_sample
  }

  if (length(x$spatial_resolution) > 0) {
    y$`raster:spatial_resolution` <- x$spatial_resolution
  }

  if (length(x$scale) > 0) {
    y$`raster:scale` <- x$scale
  }

  if (length(x$offset) > 0) {
    y$`raster:offset` <- x$offset
  }

  if (!is.null(x$histogram) && length(x$histogram) > 0) {
    y$`raster:histogram` <- as.list(x$histogram)
  }

  if (length(x$extra_fields) > 0) {
    y <- c(y, x$extra_fields)
  }

  return(y)
}

#' @noRd
#'
#' @exportS3Method
print.raster_band <- function(x, ..., expand = NULL) {
  stac_print_header("Raster Band")
  width <- stac_print_list_fields(
    list(
      data_type = x$data_type,
      nodata = x$nodata,
      spatial_resolution = x$spatial_resolution,
      unit = x$unit,
      transform = sprintf("value = %g * DN + %g", x$scale, x$offset)
    ),
    units = c(spatial_resolution = "m"),
    styles = list(data_type = stac_style_key)
  )

  statistics <- if (!is.null(x$statistics)) {
    raster_statistics_fields(x$statistics)
  } else {
    list()
  }
  histogram <- if (!is.null(x$histogram)) {
    raster_histogram_fields(x$histogram)
  } else {
    list()
  }

  collapsed <- c(
    if (length(statistics) > 0) {
      stac_print_section(
        "statistics",
        length(statistics),
        summary = stac_preview(names(statistics)),
        lines = function() {
          return(stac_field_lines(statistics))
        },
        expanded = stac_expanded(expand, "statistics"),
        width = width
      )
    },
    if (length(histogram) > 0) {
      stac_print_section(
        "histogram",
        length(histogram),
        summary = stac_preview(names(histogram)),
        lines = function() {
          return(stac_field_lines(histogram))
        },
        expanded = stac_expanded(expand, "histogram"),
        width = width
      )
    }
  )

  stac_print_hint(sum(collapsed))
  return(invisible(x))
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
#' @return An S3 raster statistics object. Access its fields with `$`, for
#'   example `stats$minimum` and `stats$valid_percent`.
#'
#' @examples
#' stats <- raster_statistics(
#'   minimum = 0,
#'   maximum = 10000,
#'   mean = 2500,
#'   stddev = 1200,
#'   valid_percent = 99.8
#' )
#' stats$minimum
#' stats$valid_percent
#'
#' @export
raster_statistics <- function(
  minimum = NULL,
  maximum = NULL,
  mean = NULL,
  stddev = NULL,
  valid_percent = NULL
) {
  object <- list(
    minimum = minimum,
    maximum = maximum,
    mean = mean,
    stddev = stddev,
    valid_percent = valid_percent
  )
  object <- (function(self, value) {
    if (
      is.numeric(value) &&
        length(value) == 1L &&
        !is.na(value) &&
        (value < 0 || value > 100)
    ) {
      cli::cli_warn("'valid_percent' should be between 0 and 100")
    }
    self$valid_percent <- value
    return(self)
  })(object, object[["valid_percent"]])
  if (!(is.null(object[["minimum"]]) || is.numeric(object[["minimum"]]))) {
    cli::cli_abort("minimum must be NULL or numeric.")
  }
  if (
    !is.null(object[["minimum"]]) &&
      (length(object[["minimum"]]) != 1L || is.na(object[["minimum"]]))
  ) {
    cli::cli_abort("minimum must be a single number")
  }
  if (!(is.null(object[["maximum"]]) || is.numeric(object[["maximum"]]))) {
    cli::cli_abort("maximum must be NULL or numeric.")
  }
  if (
    !is.null(object[["maximum"]]) &&
      (length(object[["maximum"]]) != 1L || is.na(object[["maximum"]]))
  ) {
    cli::cli_abort("maximum must be a single number")
  }
  if (!(is.null(object[["mean"]]) || is.numeric(object[["mean"]]))) {
    cli::cli_abort("mean must be NULL or numeric.")
  }
  if (
    !is.null(object[["mean"]]) &&
      (length(object[["mean"]]) != 1L || is.na(object[["mean"]]))
  ) {
    cli::cli_abort("mean must be a single number")
  }
  if (!(is.null(object[["stddev"]]) || is.numeric(object[["stddev"]]))) {
    cli::cli_abort("stddev must be NULL or numeric.")
  }
  if (
    !is.null(object[["stddev"]]) &&
      (length(object[["stddev"]]) != 1L || is.na(object[["stddev"]]))
  ) {
    cli::cli_abort("stddev must be a single number")
  }
  if (
    !(is.null(object[["valid_percent"]]) ||
      is.numeric(object[["valid_percent"]]))
  ) {
    cli::cli_abort("valid_percent must be NULL or numeric.")
  }
  if (
    !is.null(object[["valid_percent"]]) &&
      (length(object[["valid_percent"]]) != 1L ||
        is.na(object[["valid_percent"]]))
  ) {
    cli::cli_abort(paste("valid_percent", "must be a single number"))
  }
  class(object) <- c("raster_statistics", "stac_object")
  return(object)
}

raster_statistics_fields <- function(x) {
  fields <- list(
    minimum = x$minimum,
    maximum = x$maximum,
    mean = x$mean,
    stddev = x$stddev,
    valid_percent = x$valid_percent
  )
  return(fields[!vapply(fields, is.null, logical(1))])
}

#'
#' @exportS3Method
as.list.raster_statistics <- function(x, ...) {
  return(raster_statistics_fields(x))
}

as_raster_statistics <- function(x) {
  if (is.null(x) || inherits(x, "raster_statistics")) {
    return(x)
  }
  if (!is.list(x)) {
    cli::cli_abort("'statistics' must be a raster_statistics object or a list.")
  }
  return(do.call(raster_statistics, x))
}


#' Print method for raster statistics
#'
#' @param x A statistics object created with [raster_statistics()].
#' @param ... Additional arguments (ignored).
#'
#' @return `x`, invisibly.
#'
#' @noRd
#'
#' @exportS3Method
print.raster_statistics <- function(x, ...) {
  stac_print_header("Raster Statistics")

  fields <- raster_statistics_fields(x)
  if (length(fields) == 0) {
    stac_print_empty()
    return(invisible(x))
  }

  # "valid_percent" is wider than the default label column
  width <- max(stac_label_width, nchar(names(fields)))
  for (key in names(fields)) {
    stac_print_field(
      key,
      stac_fmt_value(fields[[key]]),
      stac_style_value,
      width
    )
  }

  return(invisible(x))
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
#' @return An S3 raster histogram object. Access its fields with `$`, for
#'   example `hist$count` and `hist$buckets`.
#'
#' @examples
#' # Simple histogram with 5 buckets
#' hist <- raster_histogram(
#'   count = 5,
#'   min = 0,
#'   max = 100,
#'   buckets = c(1500, 3200, 4100, 2800, 1400)
#' )
#' hist$count
#' hist$buckets
#'
#' @export
raster_histogram <- function(
  count = cli::cli_abort("'count' is required"),
  min = cli::cli_abort("'min' is required"),
  max = cli::cli_abort("'max' is required"),
  buckets = cli::cli_abort("'buckets' is required")
) {
  object <- list(count = count, min = min, max = max, buckets = buckets)
  object <- (function(self, value) {
    if (
      !is.numeric(value) ||
        length(value) != 1L ||
        is.na(value) ||
        value != trunc(value)
    ) {
      cli::cli_abort("'count' must be a single integer")
    }
    self$count <- as.integer(value)
    return(self)
  })(object, object[["count"]])
  object <- (function(self, value) {
    if (!is.numeric(value) || anyNA(value) || !all(value == trunc(value))) {
      cli::cli_abort("'buckets' must contain only integers")
    }
    self$buckets <- as.integer(value)
    return(self)
  })(object, object[["buckets"]])
  if (!is.integer(object[["count"]])) {
    cli::cli_abort("count must be integer.")
  }
  if (
    length(object[["count"]]) != 1L ||
      is.na(object[["count"]]) ||
      object[["count"]] < 0L
  ) {
    cli::cli_abort(paste("count", "must be a single non-negative integer"))
  }
  if (!is.numeric(object[["min"]])) {
    cli::cli_abort("min must be numeric.")
  }
  if (length(object[["min"]]) != 1L || is.na(object[["min"]])) {
    cli::cli_abort(paste("min", "must be a single number"))
  }
  if (!is.numeric(object[["max"]])) {
    cli::cli_abort("max must be numeric.")
  }
  if (length(object[["max"]]) != 1L || is.na(object[["max"]])) {
    cli::cli_abort(paste("max", "must be a single number"))
  }
  if (!is.integer(object[["buckets"]])) {
    cli::cli_abort("buckets must be integer.")
  }
  if (
    length(object$count) != 1L ||
      is.na(object$count) ||
      length(object$min) != 1L ||
      is.na(object$min) ||
      length(object$max) != 1L ||
      is.na(object$max)
  ) {
    NULL
  }
  if (object$min >= object$max) {
    cli::cli_abort("'min' must be smaller than 'max'")
  }
  if (length(object$buckets) != object$count) {
    cli::cli_abort(sprintf(
      "'buckets' length (%d) must equal 'count' (%d)",
      length(object$buckets),
      object$count
    ))
  }
  class(object) <- c("raster_histogram", "stac_object")
  return(object)
}

raster_histogram_fields <- function(x) {
  return(list(count = x$count, min = x$min, max = x$max, buckets = x$buckets))
}

#'
#' @exportS3Method
as.list.raster_histogram <- function(x, ...) {
  return(raster_histogram_fields(x))
}

as_raster_histogram <- function(x) {
  if (is.null(x) || inherits(x, "raster_histogram")) {
    return(x)
  }
  if (!is.list(x)) {
    cli::cli_abort("'histogram' must be a raster_histogram object or a list.")
  }
  return(do.call(raster_histogram, x))
}


#' Print method for raster histograms
#'
#' @param x A histogram object created with [raster_histogram()].
#' @param ... Additional arguments (ignored).
#'
#' @return `x`, invisibly.
#'
#' @noRd
#'
#' @exportS3Method
print.raster_histogram <- function(x, ...) {
  stac_print_header("Raster Histogram")
  stac_print_field("count", stac_fmt_value(x$count), stac_style_count)
  stac_print_field("range", sprintf("%g / %g", x$min, x$max))
  stac_print_field("buckets", stac_fmt_value(x$buckets))

  return(invisible(x))
}


# band_from_file ----

#' Extract Raster Band Metadata from a File
#'
#' @description
#' Extracts raster metadata from a file using `terra` and `sf::gdal_utils`.
#' Creates band objects with data type, spatial resolution, and optionally
#' statistics.
#'
#' @param file (character, required) Path to the raster file.
#' @param calculate_statistics (logical, optional) If TRUE, calculates min, max,
#'   mean, and standard deviation for each band. Default is FALSE (can be slow
#'   for large files).
#' @param sample_size (integer, optional) Number of pixels to sample per band
#'   when calculating statistics. If NULL, all pixels are used. Default is
#'   1000 pixels.
#'
#' @return A list of raster band objects, one per band in the file.
#'
#' @examples
#' \dontrun{
#' # Extract basic metadata
#' bands <- band_from_file("path/to/image.tif")
#'
#' # Extract metadata with statistics
#' bands <- band_from_file(
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
band_from_file <- function(
  file,
  calculate_statistics = FALSE,
  sample_size = 1000L
) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package 'terra' is required.",
      "i" = "Install with: install.packages('terra')"
    ))
  }

  r <- terra::rast(file)
  return(bands_from_terra(
    r,
    calculate_statistics = calculate_statistics,
    sample_size = sample_size
  ))
}
