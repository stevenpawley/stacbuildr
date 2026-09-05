#' Add Vector Extension to a STAC Item
#'
#' @description
#' Adds the Vector Extension to a STAC Item. The Vector Extension describes
#' basic properties and metrics of vector data (geometries with additional
#' properties), such as which geometry types are present in the dataset and
#' the minimum mapping unit/width used when the data was digitized.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param geometry_types (character, optional) A vector of the geometry types
#'   present in the dataset. Must be one or more of `"Point"`,
#'   `"MultiPoint"`, `"LineString"`, `"MultiLineString"`, `"Polygon"`,
#'   `"MultiPolygon"`, or `"GeometryCollection"`. Each type may only appear
#'   once.
#' @param mmu (numeric, optional) Minimum Mapping Unit: the area, in square
#'   meters, of the smallest polygon represented in the dataset. Must be
#'   greater than 0.
#' @param mmw (numeric, optional) Minimal Mapping Width: the width, in
#'   meters, of the smallest real-world feature represented as a polygon in
#'   the dataset. Must be greater than 0.
#' @param reference_scale (numeric, optional) The representative fraction
#'   denominator of the scale that the data was originally digitized or
#'   captured at (e.g. `50000` for a scale of 1:50,000). Must be greater than
#'   0.
#' @param asset_key (character, optional) If provided, adds the vector fields
#'   to a specific asset rather than to the item properties. Useful when
#'   different assets within an item represent vector data digitized at
#'   different scales or containing different geometry types.
#'
#' @details
#' ## Extension Schema URI
#' The Vector Extension v0.1.0 schema URI is:
#' `https://stac-extensions.github.io/vector/v0.1.0/schema.json`
#'
#' ## Field Placement
#' All four fields may be placed either on item properties (the default) or
#' on a specific asset via `asset_key`. The extension also allows these
#' fields to be set on individual Table Column objects (see
#' [table_column()]) — pass them as extra named arguments to `table_column()`
#' (e.g. `"vector:geometry_types" = "Point"`) when a table has multiple
#' geometry columns with different characteristics.
#'
#' ## Companion Extensions
#' The Vector Extension is commonly used alongside the **Table Extension**
#' (see [add_table_extension()]) for tabular/columnar vector datasets such as
#' GeoParquet.
#'
#' @return The modified STAC Item with Vector extension fields added.
#'
#' @seealso
#' * [add_table_extension()] for describing tabular vector datasets
#' * [table_column()] for creating table column objects
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' Vector Extension Specification:
#' \url{https://github.com/stac-extensions/vector}
#'
#' @examples
#' item <- stac_item(
#'   id = "my-vector-dataset",
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
#' item <- item |>
#'   add_vector_extension(
#'     geometry_types  = c("Polygon", "MultiPolygon"),
#'     mmu             = 100,
#'     reference_scale = 50000
#'   )
#'
#' @export
add_vector_extension <- function(
  item,
  geometry_types = NULL,
  mmu = NULL,
  mmw = NULL,
  reference_scale = NULL,
  asset_key = NULL
) {
  if (!inherits(item, "stac_item")) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (
    is.null(geometry_types) &&
      is.null(mmu) &&
      is.null(mmw) &&
      is.null(reference_scale)
  ) {
    cli::cli_abort(
      "At least one of 'geometry_types', 'mmu', 'mmw', or 'reference_scale' must be provided"
    )
  }

  if (!is.null(geometry_types)) {
    valid_geometry_types <- c(
      "Point",
      "MultiPoint",
      "LineString",
      "MultiLineString",
      "Polygon",
      "MultiPolygon",
      "GeometryCollection"
    )

    if (!is.character(geometry_types) || length(geometry_types) == 0) {
      cli::cli_abort("'geometry_types' must be a non-empty character vector")
    }

    invalid <- setdiff(geometry_types, valid_geometry_types)
    if (length(invalid) > 0) {
      cli::cli_abort(c(
        "Invalid geometry type(s): {paste(invalid, collapse = ', ')}",
        "i" = "Valid types: {paste(valid_geometry_types, collapse = ', ')}"
      ))
    }

    if (any(duplicated(geometry_types))) {
      cli::cli_abort("'geometry_types' must not contain duplicate values")
    }
  }

  if (!is.null(mmu)) {
    if (!is.numeric(mmu) || length(mmu) != 1 || mmu <= 0) {
      cli::cli_abort("'mmu' must be a single number greater than 0")
    }
  }

  if (!is.null(mmw)) {
    if (!is.numeric(mmw) || length(mmw) != 1 || mmw <= 0) {
      cli::cli_abort("'mmw' must be a single number greater than 0")
    }
  }

  if (!is.null(reference_scale)) {
    if (
      !is.numeric(reference_scale) ||
        length(reference_scale) != 1 ||
        reference_scale <= 0
    ) {
      cli::cli_abort(
        "'reference_scale' must be a single number greater than 0"
      )
    }
  }

  # Add extension to stac_extensions if not already present
  ext_uri <- "https://stac-extensions.github.io/vector/v0.1.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  fields <- list()
  if (!is.null(geometry_types)) {
    fields$`vector:geometry_types` <- as_json_array(geometry_types)
  }
  if (!is.null(mmu)) fields$`vector:mmu` <- mmu
  if (!is.null(mmw)) fields$`vector:mmw` <- mmw
  if (!is.null(reference_scale)) fields$`vector:reference_scale` <- reference_scale

  if (!is.null(asset_key)) {
    # Add to specific asset
    if (is.null(item@assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }

    for (field_name in names(fields)) {
      item@assets[[asset_key]][[field_name]] <- fields[[field_name]]
    }
  } else {
    # Add to item properties
    for (field_name in names(fields)) {
      item@properties[[field_name]] <- fields[[field_name]]
    }
  }

  item
}
