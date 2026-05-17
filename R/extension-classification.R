#' Add Classification Extension to a STAC Item
#'
#' @description
#' Adds the Classification Extension to a STAC Item. The Classification
#' Extension defines how pixel values in a raster asset map to named categories
#' (thematic classes) or to bit-encoded values (bitfields). It supports two
#' mutually exclusive modes:
#'
#' * **Classes** (`classification:classes`): A list of class objects, each
#'   mapping an integer pixel value to a name, description, and optional
#'   display properties. Suitable for thematic maps like land cover or QA flags
#'   represented as discrete values.
#'
#' * **Bitfields** (`classification:bitfields`): A list of bitfield objects,
#'   each describing a group of bits within an integer pixel value. Each
#'   bitfield carries its own list of class objects. Suitable for packed QA /
#'   mask bands where multiple flags are stored in a single integer (e.g.,
#'   Landsat QA_PIXEL).
#'
#' Only one of `classes` or `bitfields` should be provided. If both are
#' supplied the function will error.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param classes (list, optional) A list of class objects created with
#'   `classification_class()`. Use this for simple thematic classifications
#'   where each integer pixel value maps to a named category.
#' @param bitfields (list, optional) A list of bitfield objects created with
#'   `classification_bitfield()`. Use this for packed bitmask bands where
#'   multiple classification flags are encoded within a single integer value.
#' @param asset_key (character, optional) If provided, attaches the
#'   classification metadata to a specific asset rather than to the item-level
#'   properties. The asset must already exist in the item.
#'
#' @details
#' ## Extension Schema URI
#' `https://stac-extensions.github.io/classification/v2.0.0/schema.json`
#'
#' ## Classes vs Bitfields
#' Use `classes` when each pixel value unambiguously identifies one category
#' (e.g., 1 = Water, 2 = Urban, 3 = Forest). Use `bitfields` when pixel values
#' are bitmasks where individual bits or groups of bits carry independent
#' meaning (e.g., Landsat CFMask QA band).
#'
#' ## Placement
#' The classification fields are typically placed on the asset that contains
#' the classified raster (via `asset_key`). They can also be placed on item
#' properties when the classification applies to the whole item or when the
#' extension is used in collection-level item asset definitions.
#'
#' @return The modified STAC Item with Classification extension fields added.
#'
#' @seealso
#' * [classification_class()] for creating class objects
#' * [classification_bitfield()] for creating bitfield objects
#' * [add_raster_extension()] for adding raster metadata
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' Classification Extension Specification:
#' \url{https://github.com/stac-extensions/classification}
#'
#' @examples
#' # Create an item representing a land cover map
#' item <- stac_item(
#'   id = "lc-2023",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
#'       c(-105.5, 40.5), c(-105.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-105.5, 39.5, -104.5, 40.5),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' # Define land cover classes
#' classes <- list(
#'   classification_class(value = 1, name = "water",  title = "Water",  color_hint = "0000FF"),
#'   classification_class(value = 2, name = "urban",  title = "Urban",  color_hint = "FF0000"),
#'   classification_class(value = 3, name = "forest", title = "Forest", color_hint = "00FF00"),
#'   classification_class(value = 0, name = "nodata", nodata = TRUE)
#' )
#'
#' # Add classification to an asset
#' item <- item |>
#'   add_asset(
#'     key = "landcover",
#'     href = "https://example.com/lc-2023.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_classification_extension(classes = classes, asset_key = "landcover")
#'
#' # Bitfield example: Landsat-style QA band
#' qa_classes <- list(
#'   classification_class(value = 0, name = "no_fill", title = "No Fill"),
#'   classification_class(value = 1, name = "fill",    title = "Fill")
#' )
#'
#' qa_bitfields <- list(
#'   classification_bitfield(
#'     offset = 0,
#'     length = 1,
#'     classes = qa_classes,
#'     name = "fill",
#'     description = "Image or fill data"
#'   )
#' )
#'
#' item <- item |>
#'   add_asset(
#'     key = "qa_pixel",
#'     href = "https://example.com/qa_pixel.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_classification_extension(bitfields = qa_bitfields, asset_key = "qa_pixel")
#'
#' @export
add_classification_extension <- function(
  item,
  classes = NULL,
  bitfields = NULL,
  asset_key = NULL
) {
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }

  if (!is.null(classes) && !is.null(bitfields)) {
    stop("Only one of 'classes' or 'bitfields' may be provided, not both")
  }

  if (is.null(classes) && is.null(bitfields)) {
    stop("At least one of 'classes' or 'bitfields' must be provided")
  }

  if (!is.null(classes) && !is.list(classes)) {
    stop("'classes' must be a list of classification_class objects")
  }

  if (!is.null(bitfields) && !is.list(bitfields)) {
    stop("'bitfields' must be a list of classification_bitfield objects")
  }

  ext_uri <- "https://stac-extensions.github.io/classification/v2.0.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  if (!is.null(asset_key)) {
    if (is.null(item@assets[[asset_key]])) {
      stop(sprintf("Asset '%s' does not exist in item", asset_key))
    }

    if (!is.null(classes)) {
      item@assets[[asset_key]]$`classification:classes` <- classes
    } else {
      item@assets[[asset_key]]$`classification:bitfields` <- bitfields
    }
  } else {
    if (!is.null(classes)) {
      item@properties$`classification:classes` <- classes
    } else {
      item@properties$`classification:bitfields` <- bitfields
    }
  }

  item
}


#' Create a Classification Class Object
#'
#' @description
#' Creates a class object for use with the Classification Extension. Each class
#' maps a single integer pixel value to a human- and machine-readable category
#' definition, with optional display hints such as a colour.
#'
#' @param value (integer, required) The pixel value that corresponds to this
#'   class. Must be an integer.
#' @param name (character, optional) Short machine-readable identifier for the
#'   class. Required as of Classification Extension v2.0. Must consist only of
#'   letters, numbers, hyphens (`-`), and underscores (`_`).
#' @param title (character, optional) Human-readable label for use in legends
#'   and user interfaces.
#' @param description (character, optional) Longer description of the class.
#'   CommonMark 0.29 syntax may be used for rich text.
#' @param color_hint (character, optional) A six-character upper-case
#'   hexadecimal RGB colour string (e.g., `"FF0000"` for red) suggested for
#'   rendering this class in a map or legend.
#' @param nodata (logical, optional) If `TRUE`, marks this value as a no-data
#'   value that should be excluded from analysis.
#' @param percentage (numeric, optional) Percentage of pixels in the dataset
#'   that belong to this class (0–100).
#' @param count (integer, optional) Number of pixels that belong to this class.
#'
#' @return A named list representing a Classification class object.
#'
#' @details
#' ## Name Format
#' The `name` field is required in Classification Extension v2.0. It must
#' contain only letters, numbers, hyphens, and underscores. It is used for
#' machine-readable identification, while `title` provides the human-readable
#' label.
#'
#' ## Colour Hints
#' `color_hint` should be exactly six upper-case hexadecimal characters, for
#' example `"0000FF"` (blue), `"008000"` (green), or `"FF0000"` (red). The
#' value is a display suggestion only and does not affect data interpretation.
#'
#' @examples
#' # Minimal class with just a value
#' cls <- classification_class(value = 1)
#'
#' # Full class definition
#' cls <- classification_class(
#'   value = 2,
#'   name = "urban",
#'   title = "Urban / Built-up",
#'   description = "Impervious surfaces including roads, buildings, and parking.",
#'   color_hint = "FF0000",
#'   percentage = 12.4,
#'   count = 24800L
#' )
#'
#' # No-data class
#' nodata_cls <- classification_class(value = 0, name = "nodata", nodata = TRUE)
#'
#' @export
classification_class <- function(
  value,
  name = NULL,
  title = NULL,
  description = NULL,
  color_hint = NULL,
  nodata = NULL,
  percentage = NULL,
  count = NULL
) {
  if (missing(value)) {
    stop("'value' is required")
  }
  if (!is.numeric(value) || length(value) != 1) {
    stop("'value' must be a single integer")
  }

  if (!is.null(name)) {
    if (!grepl("^[A-Za-z0-9_-]+$", name)) {
      stop("'name' must consist only of letters, numbers, hyphens, and underscores")
    }
  }

  if (!is.null(color_hint)) {
    if (!grepl("^[0-9A-F]{6}$", color_hint)) {
      stop("'color_hint' must be exactly 6 upper-case hexadecimal characters (e.g., 'FF0000')")
    }
  }

  if (!is.null(percentage)) {
    if (!is.numeric(percentage) || percentage < 0 || percentage > 100) {
      stop("'percentage' must be a number between 0 and 100")
    }
  }

  if (!is.null(nodata) && !is.logical(nodata)) {
    stop("'nodata' must be TRUE or FALSE")
  }

  cls <- list(value = as.integer(value))

  if (!is.null(name))        cls$name        <- name
  if (!is.null(title))       cls$title       <- title
  if (!is.null(description)) cls$description <- description
  if (!is.null(color_hint))  cls$color_hint  <- color_hint
  if (!is.null(nodata))      cls$nodata      <- nodata
  if (!is.null(percentage))  cls$percentage  <- percentage
  if (!is.null(count))       cls$count       <- as.integer(count)

  class(cls) <- c("classification_class", "list")
  cls
}


#' Create a Classification Bitfield Object
#'
#' @description
#' Creates a bitfield object for use with the Classification Extension. A
#' bitfield describes a contiguous group of bits within an integer pixel value,
#' mapping the bit-encoded integer to a set of named classes. Bitfields are
#' used when a single raster band packs multiple independent flags or categories
#' into one integer (e.g., Landsat QA_PIXEL, Sentinel-2 SCL masks).
#'
#' @param offset (integer, required) Zero-based bit position of the least
#'   significant bit of this bitfield. For example, `offset = 0` starts at
#'   bit 0 (the least significant bit).
#' @param length (integer, required) Number of bits that this bitfield spans.
#'   A single-bit flag has `length = 1`; a two-bit quality field has
#'   `length = 2` (representing values 0–3).
#' @param classes (list, required) A list of `classification_class()` objects
#'   describing the possible values within this bitfield.
#' @param name (character, optional) Short machine-readable name for the
#'   bitfield (e.g., `"cloud"`, `"shadow"`). Same format rules as
#'   `classification_class()` name.
#' @param description (character, optional) Human-readable description of what
#'   this bitfield encodes.
#' @param roles (character vector, optional) Roles associated with the
#'   bitfield. Uses the same role vocabulary as STAC asset roles.
#'
#' @return A named list representing a Classification bitfield object.
#'
#' @details
#' ## Bit Extraction
#' To extract the value of a bitfield from a pixel value `x`, the operation is:
#'
#' ```
#' mask  <- (2^length - 1)
#' bits  <- bitwAnd(bitwShiftR(x, offset), mask)
#' ```
#'
#' For example, bits 2–3 of a QA band (`offset = 2`, `length = 2`) are
#' extracted as `bitwAnd(bitwShiftR(x, 2), 3L)`.
#'
#' @examples
#' # Single-bit cloud flag (bit 3 of Landsat QA_PIXEL)
#' cloud_classes <- list(
#'   classification_class(value = 0, name = "not_cloud", title = "Not Cloud"),
#'   classification_class(value = 1, name = "cloud",     title = "Cloud")
#' )
#'
#' cloud_bit <- classification_bitfield(
#'   offset = 3,
#'   length = 1,
#'   classes = cloud_classes,
#'   name = "cloud",
#'   description = "Cloud mask flag"
#' )
#'
#' # Two-bit cloud confidence field (bits 8–9 of Landsat QA_PIXEL)
#' confidence_classes <- list(
#'   classification_class(value = 0, name = "none",   title = "No Confidence"),
#'   classification_class(value = 1, name = "low",    title = "Low Confidence"),
#'   classification_class(value = 2, name = "medium", title = "Medium Confidence"),
#'   classification_class(value = 3, name = "high",   title = "High Confidence")
#' )
#'
#' confidence_bit <- classification_bitfield(
#'   offset = 8,
#'   length = 2,
#'   classes = confidence_classes,
#'   name = "cloud_confidence",
#'   description = "Cloud confidence level"
#' )
#'
#' @export
classification_bitfield <- function(
  offset,
  length,
  classes,
  name = NULL,
  description = NULL,
  roles = NULL
) {
  if (missing(offset) || missing(length) || missing(classes)) {
    stop("'offset', 'length', and 'classes' are all required")
  }

  if (!is.numeric(offset) || length(offset) != 1 || offset < 0) {
    stop("'offset' must be a non-negative integer")
  }

  if (!is.numeric(length) || length(length) != 1 || length < 1) {
    stop("'length' must be a positive integer")
  }

  if (!is.list(classes) || length(classes) == 0) {
    stop("'classes' must be a non-empty list of classification_class objects")
  }

  if (!is.null(name)) {
    if (!grepl("^[A-Za-z0-9_-]+$", name)) {
      stop("'name' must consist only of letters, numbers, hyphens, and underscores")
    }
  }

  if (!is.null(roles) && !is.character(roles)) {
    stop("'roles' must be a character vector")
  }

  bf <- list(
    offset  = as.integer(offset),
    length  = as.integer(length),
    classes = classes
  )

  if (!is.null(name))        bf$name        <- name
  if (!is.null(description)) bf$description <- description
  if (!is.null(roles))       bf$roles       <- as.list(roles)

  class(bf) <- c("classification_bitfield", "list")
  bf
}


#' Print method for classification_class objects
#'
#' @param x A classification_class object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.classification_class <- function(x, ...) {
  cat("Classification Class:\n")
  cat("  Value:", x$value, "\n")

  if (!is.null(x$name))        cat("  Name:", x$name, "\n")
  if (!is.null(x$title))       cat("  Title:", x$title, "\n")
  if (!is.null(x$description)) cat("  Description:", x$description, "\n")
  if (!is.null(x$color_hint))  cat("  Color Hint: #", x$color_hint, "\n", sep = "")
  if (isTRUE(x$nodata))        cat("  NoData: TRUE\n")
  if (!is.null(x$percentage))  cat("  Percentage:", x$percentage, "%\n")
  if (!is.null(x$count))       cat("  Count:", x$count, "\n")

  invisible(x)
}


#' Print method for classification_bitfield objects
#'
#' @param x A classification_bitfield object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.classification_bitfield <- function(x, ...) {
  cat("Classification Bitfield:\n")
  cat("  Offset:", x$offset, "\n")
  cat("  Length:", x$length, "bit(s)\n")

  if (!is.null(x$name))        cat("  Name:", x$name, "\n")
  if (!is.null(x$description)) cat("  Description:", x$description, "\n")
  if (!is.null(x$roles))       cat("  Roles:", paste(unlist(x$roles), collapse = ", "), "\n")

  cat("  Classes (", length(x$classes), "):\n", sep = "")
  for (cls in x$classes) {
    label <- if (!is.null(cls$title)) cls$title else if (!is.null(cls$name)) cls$name else "?"
    cat("    ", cls$value, ": ", label, "\n", sep = "")
  }

  invisible(x)
}
