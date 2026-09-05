#' Add the Point Cloud Extension to a STAC Item
#'
#' @description
#' Adds the Point Cloud Extension to a STAC Item. The extension describes
#' point cloud datasets acquired from either active or passive sensors — most
#' commonly LiDAR, but also radar, sonar, or imagery-derived (coincidence
#' matched) point clouds — recording how many points the dataset holds, the
#' dimensions (channels) each point carries, and per-channel statistics.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param count (integer) **Required.** The number of points in the Item. Must
#'   be a whole number greater than or equal to 0. Values beyond
#'   `.Machine$integer.max` may be passed as a double.
#' @param type (character) **Required.** The phenomenology type of the point
#'   cloud. The specification does not constrain this to a fixed list, but
#'   suggests `"lidar"`, `"eopc"`, `"radar"`, `"sonar"`, and `"other"`; any
#'   other value is accepted with a warning.
#' @param schemas (list, optional) A list of Schema objects created with
#'   [pc_schema()], defining the dimensions/channels of the point cloud in
#'   order.
#' @param density (numeric, optional) The number of points per square unit
#'   area, in the units of the data's own coordinate reference system. Must be
#'   greater than or equal to 0.
#' @param statistics (list, optional) A list of Stats objects created with
#'   [pc_statistic()], giving per-channel statistics.
#' @param asset_key (character, optional) If provided, adds the point cloud
#'   fields to a specific asset rather than to the item properties. Useful when
#'   an item bundles several point cloud files that differ in point count,
#'   density, or dimensions.
#'
#' @details
#' ## Extension Schema URI
#' The Point Cloud Extension v2.0.0 schema URI is:
#' `https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json`
#'
#' ## Field Placement
#' All five fields may be placed either on item properties (the default) or on
#' a specific asset via `asset_key`. Asset-level fields were introduced in
#' v2.0.0 of the extension.
#'
#' ## The `type` Field
#' Unlike most enumerated STAC fields, `pc:type` is typed in the JSON Schema as
#' a free-form non-empty string. The values listed in the specification are
#' suggestions rather than a closed set, so an unrecognised value produces a
#' warning rather than an error and is written through unchanged.
#'
#' ## Whole-byte Dimensions
#' `pc:schemas` sizes are in whole bytes. Several LAS point record fields
#' (`ReturnNumber`, `NumberOfReturns`, `ScanDirectionFlag`, and the
#' classification flags) are bit-packed into shared bytes in the file itself
#' and cannot be described that way. The convention established by PDAL, and
#' followed by [item_from_lidr()], is to report each as the unpacked, whole-byte
#' dimension a reader materialises it into.
#'
#' @return The modified STAC Item with Point Cloud extension fields added.
#'
#' @seealso
#' * [pc_schema()] for creating Schema objects
#' * [pc_statistic()] for creating Stats objects
#' * [item_from_lidr()] for building an item straight from a LAS/LAZ file
#'
#' @references
#' Point Cloud Extension Specification:
#' \url{https://github.com/stac-extensions/pointcloud}
#'
#' @examples
#' item <- stac_item(
#'   id = "autzen",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-123.1, 44.0), c(-123.0, 44.0), c(-123.0, 44.1),
#'       c(-123.1, 44.1), c(-123.1, 44.0)
#'     ))
#'   ),
#'   bbox = c(-123.1, 44.0, -123.0, 44.1),
#'   datetime = "2023-06-15T00:00:00Z"
#' )
#'
#' item <- item |>
#'   add_pointcloud_extension(
#'     count   = 10653336,
#'     type    = "lidar",
#'     density = 4.664,
#'     schemas = list(
#'       pc_schema("X", size = 8, type = "floating"),
#'       pc_schema("Y", size = 8, type = "floating"),
#'       pc_schema("Z", size = 8, type = "floating"),
#'       pc_schema("Intensity", size = 2, type = "unsigned")
#'     ),
#'     statistics = list(
#'       pc_statistic("Z", position = 2, minimum = 406.14, maximum = 615.26)
#'     )
#'   )
#'
#' @export
add_pointcloud_extension <- function(
  item,
  count,
  type,
  schemas = NULL,
  density = NULL,
  statistics = NULL,
  asset_key = NULL
) {
  if (!inherits(item, "stac_item")) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (missing(count)) {
    cli::cli_abort("'count' is required by the Point Cloud extension")
  }
  if (missing(type)) {
    cli::cli_abort("'type' is required by the Point Cloud extension")
  }

  count <- validate_pc_count(count)
  type <- validate_pc_type(type)

  if (!is.null(density)) {
    if (!is.numeric(density) || length(density) != 1 || is.na(density)) {
      cli::cli_abort("'density' must be a single number")
    }
    if (density < 0) {
      cli::cli_abort("'density' must be greater than or equal to 0")
    }
  }

  if (!is.null(schemas)) {
    if (!is.list(schemas) || length(schemas) == 0) {
      cli::cli_abort("'schemas' must be a non-empty list of pc_schema objects")
    }
    for (i in seq_along(schemas)) {
      if (!is.list(schemas[[i]]) || is.null(schemas[[i]]$name)) {
        cli::cli_abort(c(
          "'schemas[[{i}]]' is not a valid Schema object",
          "i" = "Create them with {.fn pc_schema}"
        ))
      }
    }
  }

  if (!is.null(statistics)) {
    if (!is.list(statistics) || length(statistics) == 0) {
      cli::cli_abort(
        "'statistics' must be a non-empty list of pc_statistic objects"
      )
    }
    for (i in seq_along(statistics)) {
      if (!is.list(statistics[[i]]) || is.null(statistics[[i]]$name)) {
        cli::cli_abort(c(
          "'statistics[[{i}]]' is not a valid Stats object",
          "i" = "Create them with {.fn pc_statistic}"
        ))
      }
    }
  }

  ext_uri <- "https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  fields <- list()
  fields$`pc:count` <- count
  fields$`pc:type` <- type
  if (!is.null(schemas)) fields$`pc:schemas` <- unname(schemas)
  if (!is.null(density)) fields$`pc:density` <- density
  if (!is.null(statistics)) fields$`pc:statistics` <- unname(statistics)

  if (!is.null(asset_key)) {
    if (is.null(item@assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }

    for (field_name in names(fields)) {
      item@assets[[asset_key]][[field_name]] <- fields[[field_name]]
    }
  } else {
    for (field_name in names(fields)) {
      item@properties[[field_name]] <- fields[[field_name]]
    }
  }

  item
}


# Point counts are typed "integer" in the schema, so a double is only accepted
# when it holds a whole number. LAS 1.4 allows more points than an R integer
# can hold, and jsonlite writes a whole double without a decimal point, so the
# double is passed through rather than coerced.
validate_pc_count <- function(count, arg = "count") {
  if (!is.numeric(count) || length(count) != 1 || is.na(count)) {
    cli::cli_abort("'{arg}' must be a single number")
  }
  if (count != trunc(count)) {
    cli::cli_abort("'{arg}' must be a whole number, not {count}")
  }
  if (count < 0) {
    cli::cli_abort("'{arg}' must be greater than or equal to 0")
  }
  if (is.integer(count) || count <= .Machine$integer.max) {
    as.integer(count)
  } else {
    count
  }
}


# pc:type is a free-form non-empty string in the schema; the specification only
# suggests values, so an unknown one warns instead of aborting.
validate_pc_type <- function(type) {
  if (!is.character(type) || length(type) != 1 || is.na(type)) {
    cli::cli_abort("'type' must be a single character string")
  }
  if (!nzchar(type)) {
    cli::cli_abort("'type' must not be an empty string")
  }

  suggested <- c("lidar", "eopc", "radar", "sonar", "other")
  if (!type %in% suggested) {
    cli::cli_warn(c(
      "'type' is {.val {type}}, which is not one of the suggested values.",
      "i" = "The specification suggests {.val {suggested}}, but does not
             restrict {.field pc:type} to them, so this value is kept."
    ))
  }

  type
}


#' Create a Point Cloud Schema Object
#'
#' @description
#' Creates a Schema object for the `pc:schemas` field of the Point Cloud
#' Extension. Each object describes one dimension (channel) of the point cloud:
#' its name, its size in whole bytes, and how its bytes are interpreted.
#'
#' @param name (character) **Required.** The name of the dimension, e.g.
#'   `"X"`, `"Intensity"`, or `"Classification"`.
#' @param size (integer) **Required.** The size of the dimension in whole
#'   bytes. Must be a whole number greater than 0.
#' @param type (character) **Required.** The dimension type. One of
#'   `"floating"`, `"unsigned"`, or `"signed"`.
#'
#' @details
#' Only whole-byte sizes are representable. Bit-packed LAS fields such as
#' `ReturnNumber` are conventionally reported as the unpacked one-byte
#' dimension a reader materialises, which is what [item_from_lidr()] does.
#'
#' @return A `pc_schema` object (a list with a print method).
#'
#' @seealso [add_pointcloud_extension()], [pc_statistic()]
#'
#' @examples
#' pc_schema("X", size = 8, type = "floating")
#' pc_schema("Intensity", size = 2, type = "unsigned")
#'
#' @export
pc_schema <- function(name, size, type) {
  if (missing(name) || !is.character(name) || length(name) != 1 || is.na(name)) {
    cli::cli_abort("'name' must be a single character string")
  }
  if (!nzchar(name)) {
    cli::cli_abort("'name' must not be an empty string")
  }

  if (missing(size) || !is.numeric(size) || length(size) != 1 || is.na(size)) {
    cli::cli_abort("'size' must be a single number")
  }
  if (size != trunc(size) || size <= 0) {
    cli::cli_abort("'size' must be a whole number of bytes greater than 0")
  }

  valid_types <- c("floating", "unsigned", "signed")
  if (missing(type) || !is.character(type) || length(type) != 1 || is.na(type)) {
    cli::cli_abort("'type' must be a single character string")
  }
  if (!type %in% valid_types) {
    cli::cli_abort(c(
      "Invalid dimension type: {.val {type}}",
      "i" = "Valid types: {paste(valid_types, collapse = ', ')}"
    ))
  }

  schema <- list(name = name, size = as.integer(size), type = type)
  class(schema) <- c("pc_schema", "list")
  schema
}


#' Print method for pc_schema objects
#'
#' @param x A pc_schema object.
#' @param ... Additional arguments (ignored).
#'
#' @export
print.pc_schema <- function(x, ...) {
  stac_print_header("Point Cloud Schema")
  stac_print_list_fields(
    x,
    units = c(size = "bytes"),
    styles = list(name = stac_style_id, type = stac_style_key)
  )
  invisible(x)
}


#' Create a Point Cloud Statistics Object
#'
#' @description
#' Creates a Stats object for the `pc:statistics` field of the Point Cloud
#' Extension, giving statistics for one dimension (channel) of the point cloud.
#'
#' @param name (character) **Required.** The name of the channel, matching the
#'   corresponding [pc_schema()] `name`.
#' @param position (integer, optional) The zero-based position of the channel
#'   within `pc:schemas`.
#' @param average (numeric, optional) The average of the channel.
#' @param count (integer, optional) The number of elements in the channel.
#' @param maximum (numeric, optional) The maximum value of the channel.
#' @param minimum (numeric, optional) The minimum value of the channel.
#' @param stddev (numeric, optional) The standard deviation of the channel.
#' @param variance (numeric, optional) The variance of the channel.
#'
#' @details
#' The specification requires the channel name and at least one statistic, so
#' supplying `name` alone is an error.
#'
#' @return A `pc_statistic` object (a list with a print method).
#'
#' @seealso [add_pointcloud_extension()], [pc_schema()]
#'
#' @examples
#' pc_statistic("Z", position = 2, minimum = 406.14, maximum = 615.26)
#'
#' @export
pc_statistic <- function(
  name,
  position = NULL,
  average = NULL,
  count = NULL,
  maximum = NULL,
  minimum = NULL,
  stddev = NULL,
  variance = NULL
) {
  if (missing(name) || !is.character(name) || length(name) != 1 || is.na(name)) {
    cli::cli_abort("'name' must be a single character string")
  }
  if (!nzchar(name)) {
    cli::cli_abort("'name' must not be an empty string")
  }

  stat <- list(name = name)

  if (!is.null(position)) {
    if (
      !is.numeric(position) ||
        length(position) != 1 ||
        is.na(position) ||
        position != trunc(position) ||
        position < 0
    ) {
      cli::cli_abort("'position' must be a whole number greater than or equal to 0")
    }
    stat$position <- as.integer(position)
  }

  numeric_stats <- list(
    average = average,
    maximum = maximum,
    minimum = minimum,
    stddev = stddev,
    variance = variance
  )
  for (field in names(numeric_stats)) {
    value <- numeric_stats[[field]]
    if (is.null(value)) next
    if (!is.numeric(value) || length(value) != 1 || is.na(value)) {
      cli::cli_abort("'{field}' must be a single number")
    }
    stat[[field]] <- value
  }

  if (!is.null(count)) {
    stat$count <- validate_pc_count(count)
  }

  if (length(stat) == 1L) {
    cli::cli_abort(c(
      "A Stats object needs the channel name and at least one statistic",
      "i" = "Supply one or more of 'average', 'count', 'maximum', 'minimum',
             'stddev', or 'variance'"
    ))
  }

  # Field order follows the specification's table rather than argument order
  ordered <- c(
    "name", "position", "average", "count",
    "maximum", "minimum", "stddev", "variance"
  )
  stat <- stat[intersect(ordered, names(stat))]

  class(stat) <- c("pc_statistic", "list")
  stat
}


#' Print method for pc_statistic objects
#'
#' @param x A pc_statistic object.
#' @param ... Additional arguments (ignored).
#'
#' @export
print.pc_statistic <- function(x, ...) {
  stac_print_header("Point Cloud Statistics")
  stac_print_list_fields(
    x,
    styles = list(name = stac_style_id)
  )
  invisible(x)
}
