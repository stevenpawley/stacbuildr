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
#'     count = 10653336,
#'     type = "lidar",
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
      if (!inherits(schemas[[i]], "pc_schema")) {
        cli::cli_abort(c(
          "'schemas[[{i}]]' is not a valid Schema object",
          i = "Create them with {.fn pc_schema}"
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
      if (!inherits(statistics[[i]], "pc_statistic")) {
        cli::cli_abort(c(
          "'statistics[[{i}]]' is not a valid Stats object",
          i = "Create them with {.fn pc_statistic}"
        ))
      }
    }
  }
  ext_uri <- "https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json"
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  fields <- list()
  fields$`pc:count` <- count
  fields$`pc:type` <- type
  if (!is.null(schemas)) {
    fields$`pc:schemas` <- unname(schemas)
  }
  if (!is.null(density)) {
    fields$`pc:density` <- density
  }
  if (!is.null(statistics)) {
    fields$`pc:statistics` <- unname(statistics)
  }
  if (!is.null(asset_key)) {
    if (is.null(item$assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }
    for (field_name in names(fields)) {
      item$assets[[asset_key]]$extra_fields[[field_name]] <- fields[[
        field_name
      ]]
    }
  } else {
    for (field_name in names(fields)) {
      item$properties[[field_name]] <- fields[[field_name]]
    }
  }
  return(item)
}


# Point counts are typed "integer" in the schema, so a double is only accepted
# when it holds a whole number. LAS 1.4 allows more points than an R integer
# can hold, and jsonlite writes a whole double without a decimal point, so the
# double is passed through rather than coerced.
coerce_pc_count <- function(count, arg = "count") {
  if (!is.numeric(count) || length(count) != 1 || is.na(count)) {
    cli::cli_abort("'{arg}' must be a single number")
  }
  if (count != trunc(count)) {
    cli::cli_abort("'{arg}' must be a whole number, not {count}")
  }
  return(
    if (is.integer(count) || count <= .Machine$integer.max) {
      as.integer(count)
    } else {
      count
    }
  )
}

validate_pc_count <- function(count, arg = "count") {
  count <- coerce_pc_count(count, arg)
  if (count < 0) {
    cli::cli_abort("'{arg}' must be greater than or equal to 0")
  }
  return(count)
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

  return(type)
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
#' @return A `pc_schema` S3 object. Access fields with `$`.
#'
#' @seealso [add_pointcloud_extension()], [pc_statistic()]
#'
#' @examples
#' pc_schema("X", size = 8, type = "floating")
#' pc_schema("Intensity", size = 2, type = "unsigned")
#'
#' @export
pc_schema <- function(
  name = cli::cli_abort("'name' is required"),
  size = cli::cli_abort("'size' is required"),
  type = cli::cli_abort("'type' is required")
) {
  object <- list(name = name, size = size, type = type)
  object <- (function(self, value) {
    if (
      !is.numeric(value) ||
        length(value) != 1L ||
        is.na(value) ||
        value != trunc(value)
    ) {
      cli::cli_abort("'size' must be a whole number of bytes")
    }
    self$size <- as.integer(value)
    return(self)
  })(object, object[["size"]])
  if (!is.character(object[["name"]])) {
    cli::cli_abort("name must be character.")
  }
  if (
    length(object[["name"]]) != 1L ||
      is.na(object[["name"]]) ||
      !nzchar(object[["name"]])
  ) {
    cli::cli_abort(paste("name", "must be a non-empty string"))
  }
  if (!is.integer(object[["size"]])) {
    cli::cli_abort("size must be integer.")
  }
  if (
    length(object[["size"]]) != 1L ||
      is.na(object[["size"]]) ||
      object[["size"]] <= 0L
  ) {
    cli::cli_abort(paste("size", "must be greater than 0"))
  }
  if (!is.character(object[["type"]])) {
    cli::cli_abort("type must be character.")
  }
  if (
    length(object[["type"]]) != 1L ||
      is.na(object[["type"]]) ||
      !object[["type"]] %in%
        c(
          "floating",
          "unsigned",
          "signed"
        )
  ) {
    cli::cli_abort(paste("type", "must be floating, unsigned, or signed"))
  }
  class(object) <- c("pc_schema", "stac_object")
  return(object)
}

#'
#' @exportS3Method
as.list.pc_schema <- function(x, ...) {
  return(list(name = x$name, size = x$size, type = x$type))
}


#' Print method for pc_schema objects
#'
#' @param x A pc_schema object.
#' @param ... Additional arguments (ignored).
#'
#' @noRd
#'
#' @exportS3Method
print.pc_schema <- function(x, ...) {
  stac_print_header("Point Cloud Schema")
  stac_print_list_fields(
    list(name = x$name, size = x$size, type = x$type),
    units = c(size = "bytes"),
    styles = list(name = stac_style_id, type = stac_style_key)
  )
  return(invisible(x))
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
#' @return A `pc_statistic` S3 object. Access fields with `$`.
#'
#' @seealso [add_pointcloud_extension()], [pc_schema()]
#'
#' @examples
#' pc_statistic("Z", position = 2, minimum = 406.14, maximum = 615.26)
#'
#' @export
pc_statistic <- function(
  name = cli::cli_abort("'name' is required"),
  position = NULL,
  average = NULL,
  count = NULL,
  maximum = NULL,
  minimum = NULL,
  stddev = NULL,
  variance = NULL
) {
  object <- list(
    name = name,
    position = position,
    average = average,
    count = count,
    maximum = maximum,
    minimum = minimum,
    stddev = stddev,
    variance = variance
  )
  object <- (function(self, value) {
    if (!is.null(value)) {
      if (
        !is.numeric(value) ||
          length(value) != 1L ||
          is.na(value) ||
          value != trunc(value)
      ) {
        cli::cli_abort(
          "'position' must be a whole number greater than or equal to 0"
        )
      }
      value <- as.integer(value)
    }
    self$position <- value
    return(self)
  })(object, object[["position"]])
  object <- (function(self, value) {
    if (!is.null(value)) {
      value <- coerce_pc_count(value)
    }
    self$count <- value
    return(self)
  })(object, object[["count"]])
  if (!is.character(object[["name"]])) {
    cli::cli_abort("name must be character.")
  }
  if (
    length(object[["name"]]) != 1L ||
      is.na(object[["name"]]) ||
      !nzchar(object[["name"]])
  ) {
    cli::cli_abort(paste("name", "must be a non-empty string"))
  }
  if (!(is.null(object[["position"]]) || is.integer(object[["position"]]))) {
    cli::cli_abort("position must be NULL or integer.")
  }
  if (
    !is.null(object[["position"]]) &&
      (length(object[["position"]]) != 1L ||
        is.na(object[["position"]]) ||
        object[["position"]] < 0L)
  ) {
    cli::cli_abort(paste(
      "position",
      "must be a whole number greater than or equal to 0"
    ))
  }
  if (!(is.null(object[["average"]]) || is.numeric(object[["average"]]))) {
    cli::cli_abort("average must be NULL or numeric.")
  }
  if (
    !is.null(object[["average"]]) &&
      (length(object[["average"]]) != 1L || is.na(object[["average"]]))
  ) {
    cli::cli_abort("average must be a single number")
  }
  if (!(is.null(object[["count"]]) || is.numeric(object[["count"]]))) {
    cli::cli_abort("count must be NULL or numeric.")
  }
  if (
    !is.null(object[["count"]]) &&
      (length(object[["count"]]) != 1L ||
        is.na(object[["count"]]) ||
        object[["count"]] != trunc(object[["count"]]) ||
        object[["count"]] < 0)
  ) {
    cli::cli_abort(paste(
      "count",
      "must be a whole number greater than or equal to 0"
    ))
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
  if (!(is.null(object[["minimum"]]) || is.numeric(object[["minimum"]]))) {
    cli::cli_abort("minimum must be NULL or numeric.")
  }
  if (
    !is.null(object[["minimum"]]) &&
      (length(object[["minimum"]]) != 1L || is.na(object[["minimum"]]))
  ) {
    cli::cli_abort("minimum must be a single number")
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
  if (!(is.null(object[["variance"]]) || is.numeric(object[["variance"]]))) {
    cli::cli_abort("variance must be NULL or numeric.")
  }
  if (
    !is.null(object[["variance"]]) &&
      (length(object[["variance"]]) != 1L || is.na(object[["variance"]]))
  ) {
    cli::cli_abort("variance must be a single number")
  }
  values <- list(
    object$average,
    object$count,
    object$maximum,
    object$minimum,
    object$stddev,
    object$variance
  )
  if (all(vapply(values, is.null, logical(1)))) {
    cli::cli_abort("at least one statistic must be provided")
  }
  class(object) <- c("pc_statistic", "stac_object")
  return(object)
}

#'
#' @exportS3Method
as.list.pc_statistic <- function(x, ...) {
  return(compact_nulls(list(
    name = x$name,
    position = x$position,
    average = x$average,
    count = x$count,
    maximum = x$maximum,
    minimum = x$minimum,
    stddev = x$stddev,
    variance = x$variance
  )))
}


#' Print method for pc_statistic objects
#'
#' @param x A pc_statistic object.
#' @param ... Additional arguments (ignored).
#'
#' @noRd
#'
#' @exportS3Method
print.pc_statistic <- function(x, ...) {
  stac_print_header("Point Cloud Statistics")
  stac_print_list_fields(
    compact_nulls(list(
      name = x$name,
      position = x$position,
      average = x$average,
      count = x$count,
      maximum = x$maximum,
      minimum = x$minimum,
      stddev = x$stddev,
      variance = x$variance
    )),
    styles = list(name = stac_style_id)
  )
  return(invisible(x))
}
