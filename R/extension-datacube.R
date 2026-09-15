#' Add Datacube Extension to a STAC Item
#'
#' @description
#' Adds the Datacube Extension to a STAC Item. The Datacube Extension
#' describes N-dimensional data cubes (e.g. NetCDF, Zarr, multi-band raster
#' stacks) by specifying the dimensions of the cube (spatial, temporal, or
#' additional custom dimensions) and, optionally, the variables it contains.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param dimensions (named list, optional) A named list of dimension objects
#'   created with `cube_dimension()`. Names are used as the dimension keys
#'   (e.g. `"x"`, `"y"`, `"time"`) and must be unique.
#' @param variables (named list, optional) A named list of variable objects
#'   created with `cube_variable()`. Names are used as the variable keys and
#'   must be unique, and must not clash with any name used in `dimensions`.
#' @param asset_key (character, optional) If provided, adds the datacube
#'   fields to a specific asset rather than to the item properties. Useful
#'   when different assets within an item (e.g. separate NetCDF files)
#'   describe different data cubes.
#'
#' @details
#' ## Extension Schema URI
#' The Datacube Extension v2.3.0 schema URI is:
#' `https://stac-extensions.github.io/datacube/v2.3.0/schema.json`
#'
#' ## Field Placement
#' `cube:dimensions` and `cube:variables` may be placed either on item
#' properties (the default) or on a specific asset via `asset_key`.
#'
#' ## Key Uniqueness
#' The keys of `dimensions` and `variables` should be unique together; a key
#' such as `"lat"` should not be used for both a dimension and a variable.
#'
#' @return The modified STAC Item with Datacube extension fields added.
#'
#' @seealso
#' * [cube_dimension()] for creating dimension objects
#' * [cube_variable()] for creating variable objects
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' Datacube Extension Specification:
#' \url{https://github.com/stac-extensions/datacube}
#'
#' @examples
#' item <- stac_item(
#'   id = "my-datacube",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
#'       c(-105.5, 40.5), c(-105.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-105.5, 39.5, -104.5, 40.5),
#'   datetime = "2023-06-15T00:00:00Z"
#' )
#'
#' dims <- list(
#'   x = cube_dimension(
#'     type = "spatial", axis = "x", extent = c(-105.5, -104.5),
#'     reference_system = 4326
#'   ),
#'   y = cube_dimension(
#'     type = "spatial", axis = "y", extent = c(39.5, 40.5),
#'     reference_system = 4326
#'   ),
#'   time = cube_dimension(
#'     type = "temporal",
#'     extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z")
#'   )
#' )
#'
#' vars <- list(
#'   temperature = cube_variable(
#'     type = "data",
#'     dimensions = c("x", "y", "time"),
#'     unit = "degC",
#'     data_type = "float32"
#'   )
#' )
#'
#' item <- item |>
#'   add_datacube_extension(dimensions = dims, variables = vars)
#'
#' @export
add_datacube_extension <- function(
  item,
  dimensions = NULL,
  variables = NULL,
  asset_key = NULL
) {
  if (!S7::S7_inherits(item, stac_item)) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (is.null(dimensions) && is.null(variables)) {
    cli::cli_abort(
      "At least one of 'dimensions' or 'variables' must be provided"
    )
  }

  if (!is.null(dimensions)) {
    dimensions <- validate_cube_named_list(
      dimensions,
      "dimensions",
      "cube_dimension"
    )
  }

  if (!is.null(variables)) {
    variables <- validate_cube_named_list(
      variables,
      "variables",
      "cube_variable"
    )
  }

  if (!is.null(dimensions) && !is.null(variables)) {
    overlap <- intersect(names(dimensions), names(variables))
    if (length(overlap) > 0) {
      cli::cli_abort(
        "'dimensions' and 'variables' must not share keys: {paste(overlap, collapse = ', ')}"
      )
    }
  }

  # Add extension to stac_extensions if not already present
  ext_uri <- "https://stac-extensions.github.io/datacube/v2.3.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  fields <- list()
  if (!is.null(dimensions)) {
    fields$`cube:dimensions` <- dimensions
  }
  if (!is.null(variables)) {
    fields$`cube:variables` <- variables
  }

  if (!is.null(asset_key)) {
    # Add to specific asset
    if (is.null(item@assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }

    for (field_name in names(fields)) {
      item@assets[[asset_key]]@extra_fields[[field_name]] <- fields[[
        field_name
      ]]
    }
  } else {
    # Add to item properties
    for (field_name in names(fields)) {
      item@properties[[field_name]] <- fields[[field_name]]
    }
  }

  item
}


#' @noRd
validate_cube_named_list <- function(x, arg_name, class_name) {
  if (!is.list(x) || length(x) == 0) {
    cli::cli_abort("'{arg_name}' must be a non-empty named list")
  }

  nms <- names(x)
  if (is.null(nms) || any(nms == "") || any(is.na(nms))) {
    cli::cli_abort("'{arg_name}' must be a fully named list")
  }

  if (any(duplicated(nms))) {
    cli::cli_abort("'{arg_name}' must not contain duplicate names")
  }

  cls <- get(class_name, envir = asNamespace("stacbuildr"))
  not_cls <- !vapply(x, S7::S7_inherits, logical(1), cls)
  if (any(not_cls)) {
    cli::cli_abort(
      "All elements of '{arg_name}' must be {class_name} objects"
    )
  }

  x
}


#' Create a Datacube Dimension Object
#'
#' @description
#' Creates a dimension object for use with the Datacube Extension. Describes
#' a single dimension of an N-dimensional data cube, such as an `x`/`y`
#' spatial axis, a vertical axis, a temporal axis, a geometry (vector data
#' cube) dimension, or an additional custom dimension (e.g. wavelength,
#' pressure level).
#'
#' @param type (character, required) The type of the dimension. One of
#'   `"spatial"` (horizontal x/y or vertical z axis), `"geometry"` (vector
#'   data cube dimension), `"temporal"`, or a custom string for an
#'   "additional" dimension (e.g. `"spectral"`, `"pressure"`). Custom values
#'   must not be `"spatial"` or `"geometry"`.
#' @param extent (numeric or character, optional/required) The extent of the
#'   dimension as `c(min, max)`. Required for horizontal spatial (`x`/`y`)
#'   and temporal dimensions. For vertical (`z`) and additional dimensions,
#'   either `extent` or `values` must be given. `NA` may be used for an
#'   open-ended bound.
#' @param values (numeric or character, optional) An explicit, potentially
#'   irregularly spaced, list of values in the dimension, used instead of or
#'   in addition to `extent`.
#' @param step (numeric or character, optional) The distance between two
#'   consecutive values, e.g. the spatial resolution or an ISO 8601 duration
#'   for a temporal dimension. `NULL`/absent means irregular spacing.
#' @param unit (character, optional) The unit of measurement for the values
#'   and extent.
#' @param reference_system (optional) The spatial (or other) reference
#'   system, e.g. an EPSG code, WKT2 string, or PROJJSON object. Applies to
#'   `"spatial"` and `"geometry"` dimensions. Defaults to EPSG:4326 per the
#'   spec if omitted for spatial dimensions.
#' @param description (character, optional) Detailed description of the
#'   dimension. CommonMark 0.29 syntax may be used for rich text
#'   representation.
#' @param axis (character, required for `type = "spatial"`) The axis of the
#'   spatial dimension: `"x"`, `"y"`, or `"z"`.
#' @param axes (character, optional) For `type = "geometry"` dimensions, the
#'   axes that the `bbox` and geometries are given in, e.g. `c("x", "y")`.
#'   Defaults to `c("x", "y")` per the spec if omitted.
#' @param bbox (numeric, required for `type = "geometry"`) The bounding box
#'   of the geometries as `c(xmin, ymin, xmax, ymax)` (or with a `z` axis).
#' @param geometry_types (character, optional) For `type = "geometry"`
#'   dimensions, the allowed GeoJSON geometry types (e.g. `"Point"`,
#'   `"Polygon"`).
#' @param ... Additional fields for the dimension object.
#'
#' @return A `cube_dimension` S7 object. Access fields with `@`.
#'
#' @details
#' ## Dimension Types
#' * **Horizontal spatial** (`type = "spatial"`, `axis = "x"` or `"y"`):
#'   `extent` is required.
#' * **Vertical spatial** (`type = "spatial"`, `axis = "z"`): `extent` or
#'   `values` is required.
#' * **Geometry** (`type = "geometry"`): describes a vector data cube
#'   dimension; `bbox` is required.
#' * **Temporal** (`type = "temporal"`): `extent` is required, given as ISO
#'   8601 datetime strings (or `NA` for an open bound).
#' * **Additional** (any other `type`, e.g. `"spectral"`): a custom
#'   dimension such as wavelength or pressure level; `extent` or `values` is
#'   required.
#'
#' @examples
#' # Horizontal spatial dimensions
#' x_dim <- cube_dimension(
#'   type = "spatial", axis = "x", extent = c(-105.5, -104.5),
#'   reference_system = 4326
#' )
#' y_dim <- cube_dimension(
#'   type = "spatial", axis = "y", extent = c(39.5, 40.5),
#'   reference_system = 4326
#' )
#'
#' # Temporal dimension
#' time_dim <- cube_dimension(
#'   type = "temporal",
#'   extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z"),
#'   step = "P1D"
#' )
#'
#' # Additional dimension (e.g. spectral band index)
#' band_dim <- cube_dimension(
#'   type = "bands",
#'   values = c("B02", "B03", "B04", "B08")
#' )
#'
#' @export
cube_dimension <- S7::new_class(
  "cube_dimension",
  properties = list(
    type = S7::class_character,
    extent = S7::class_any,
    values = S7::class_any,
    step = S7::class_any,
    unit = S7::class_any,
    reference_system = S7::class_any,
    description = S7::class_any,
    axis = S7::class_any,
    axes = S7::class_any,
    bbox = S7::class_any,
    geometry_types = S7::class_any,
    extra_fields = S7::new_property(S7::class_list, default = list())
  ),
  constructor = function(
    type,
    extent = NULL,
    values = NULL,
    step = NULL,
    unit = NULL,
    reference_system = NULL,
    description = NULL,
    axis = NULL,
    axes = NULL,
    bbox = NULL,
    geometry_types = NULL,
    ...
  ) {
    if (
      missing(type) || !is.character(type) || length(type) != 1 || is.na(type)
    ) {
      cli::cli_abort("'type' must be a single character string")
    }

    if (type == "spatial") {
      if (is.null(axis) || !axis %in% c("x", "y", "z")) {
        cli::cli_abort(
          "'axis' must be one of 'x', 'y', or 'z' when type = 'spatial'"
        )
      }

      if (axis %in% c("x", "y")) {
        if (is.null(extent) || length(extent) != 2) {
          cli::cli_abort(
            "'extent' (length 2) is required for horizontal spatial dimensions"
          )
        }
      } else if (is.null(extent) && is.null(values)) {
        cli::cli_abort(
          "Either 'extent' or 'values' is required for vertical ('z') spatial dimensions"
        )
      }
    } else if (type == "geometry") {
      if (is.null(bbox)) {
        cli::cli_abort("'bbox' is required when type = 'geometry'")
      }
    } else if (type == "temporal") {
      if (is.null(extent) || length(extent) != 2) {
        cli::cli_abort("'extent' (length 2) is required when type = 'temporal'")
      }
    } else if (is.null(extent) && is.null(values)) {
      cli::cli_abort(
        "Either 'extent' or 'values' is required for additional dimensions"
      )
    }

    S7::new_object(
      S7::S7_object(),
      type = type,
      extent = extent,
      values = if (is.null(values)) NULL else unlist(values, use.names = FALSE),
      step = step,
      unit = unit,
      reference_system = if (type %in% c("spatial", "geometry")) {
        reference_system
      } else {
        NULL
      },
      description = description,
      axis = if (type == "spatial") axis else NULL,
      axes = if (type == "geometry" && !is.null(axes)) {
        unlist(axes, use.names = FALSE)
      } else {
        NULL
      },
      bbox = if (type == "geometry") bbox else NULL,
      geometry_types = if (type == "geometry" && !is.null(geometry_types)) {
        unlist(geometry_types, use.names = FALSE)
      } else {
        NULL
      },
      extra_fields = list(...)
    )
  }
)

S7::method(as.list, cube_dimension) <- function(x, ...) {
  fields <- compact_nulls(list(
    type = x@type,
    axis = x@axis,
    axes = if (is.null(x@axes)) NULL else as_json_array(x@axes),
    bbox = x@bbox,
    geometry_types = if (is.null(x@geometry_types)) {
      NULL
    } else {
      as_json_array(x@geometry_types)
    },
    extent = x@extent,
    values = if (is.null(x@values)) NULL else as_json_array(x@values),
    step = x@step,
    unit = x@unit,
    reference_system = x@reference_system,
    description = x@description
  ))
  c(fields, x@extra_fields)
}


#' Print method for cube_dimension objects
#'
#' @param x A cube_dimension object.
#' @param ... Additional arguments (ignored).
#'
#' @noRd
S7::method(print, cube_dimension) <- function(x, ...) {
  stac_print_header("Datacube Dimension")
  fields <- c(
    compact_nulls(list(
      type = x@type,
      axis = x@axis,
      axes = x@axes,
      bbox = x@bbox,
      geometry_types = x@geometry_types,
      extent = x@extent,
      values = x@values,
      step = x@step,
      unit = x@unit,
      reference_system = x@reference_system,
      description = x@description
    )),
    x@extra_fields
  )
  stac_print_list_fields(fields, styles = list(type = stac_style_key))
  invisible(x)
}


#' Create a Datacube Variable Object
#'
#' @description
#' Creates a variable object for use with the Datacube Extension. Describes
#' a single variable stored in an N-dimensional data cube (e.g. a NetCDF
#' variable such as `temperature` or `precipitation`), including the
#' dimensions it varies over.
#'
#' @param type (character, required) The type of the variable: `"data"` for
#'   the primary data variable(s) or `"auxiliary"` for supporting variables
#'   (e.g. quality flags, coordinate variables).
#' @param dimensions (character, required) A character vector of dimension
#'   keys (matching names used in `dimensions` passed to
#'   `add_datacube_extension()`) that this variable varies over. Use
#'   `character(0)` for a scalar variable with no dimensions.
#' @param extent (optional) The extent of the values of the variable, as
#'   `c(min, max)`.
#' @param values (optional) An explicit list of values, e.g. for variables
#'   with a small number of distinct values.
#' @param unit (character, optional) The unit of measurement for the values.
#' @param nodata (optional) The no-data value(s) for the variable.
#' @param data_type (character, optional) The data type of the variable,
#'   e.g. `"float32"`, `"int16"`.
#' @param description (character, optional) Detailed description of the
#'   variable. CommonMark 0.29 syntax may be used for rich text
#'   representation.
#' @param ... Additional fields for the variable object.
#'
#' @return A `cube_variable` S7 object. Access fields with `@`.
#'
#' @examples
#' temperature <- cube_variable(
#'   type = "data",
#'   dimensions = c("x", "y", "time"),
#'   unit = "degC",
#'   data_type = "float32"
#' )
#'
#' quality_flag <- cube_variable(
#'   type = "auxiliary",
#'   dimensions = c("x", "y", "time"),
#'   data_type = "uint8"
#' )
#'
#' @export
cube_variable <- S7::new_class(
  "cube_variable",
  properties = list(
    type = S7::class_character,
    dimensions = S7::class_character,
    extent = S7::class_any,
    values = S7::class_any,
    unit = S7::class_any,
    nodata = S7::class_any,
    data_type = S7::class_any,
    description = S7::class_any,
    extra_fields = S7::new_property(S7::class_list, default = list())
  ),
  constructor = function(
    type,
    dimensions = character(0),
    extent = NULL,
    values = NULL,
    unit = NULL,
    nodata = NULL,
    data_type = NULL,
    description = NULL,
    ...
  ) {
    if (
      missing(type) || !is.character(type) || length(type) != 1 || is.na(type)
    ) {
      cli::cli_abort("'type' must be a single character string")
    }

    if (!type %in% c("data", "auxiliary")) {
      cli::cli_abort("'type' must be either 'data' or 'auxiliary'")
    }

    if (!is.character(dimensions)) {
      cli::cli_abort(
        "'dimensions' must be a character vector (use character(0) for none)"
      )
    }

    S7::new_object(
      S7::S7_object(),
      type = type,
      dimensions = dimensions,
      extent = extent,
      values = if (is.null(values)) NULL else unlist(values, use.names = FALSE),
      unit = unit,
      nodata = nodata,
      data_type = data_type,
      description = description,
      extra_fields = list(...)
    )
  }
)

S7::method(as.list, cube_variable) <- function(x, ...) {
  fields <- compact_nulls(list(
    dimensions = as_json_array(x@dimensions),
    type = x@type,
    extent = x@extent,
    values = if (is.null(x@values)) NULL else as_json_array(x@values),
    unit = x@unit,
    nodata = x@nodata,
    data_type = x@data_type,
    description = x@description
  ))
  c(fields, x@extra_fields)
}


#' Print method for cube_variable objects
#'
#' @param x A cube_variable object.
#' @param ... Additional arguments (ignored).
#'
#' @noRd
S7::method(print, cube_variable) <- function(x, ...) {
  stac_print_header("Datacube Variable")
  fields <- c(
    compact_nulls(list(
      dimensions = x@dimensions,
      type = x@type,
      extent = x@extent,
      values = x@values,
      unit = x@unit,
      nodata = x@nodata,
      data_type = x@data_type,
      description = x@description
    )),
    x@extra_fields
  )
  stac_print_list_fields(fields, styles = list(type = stac_style_key))
  invisible(x)
}
