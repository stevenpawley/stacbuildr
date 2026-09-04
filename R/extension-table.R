#' Add Table Extension to a STAC Item
#'
#' @description
#' Adds the Table Extension to a STAC Item. The Table Extension provides
#' fields to describe tabular datasets (e.g. GeoParquet, CSV, flat
#' GeoPackage/SQLite tables) referenced by an Item, including the columns
#' present, which column holds the primary geometry, and the number of rows.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param columns (list, optional) A list of column objects created with
#'   `table_column()`, one entry per column in the table.
#' @param primary_geometry (character, optional) The name of the column that
#'   holds the primary geometry, for use by libraries such as geopandas or
#'   `sf` when a table has multiple geometry columns.
#' @param row_count (numeric, optional) The number of rows in the dataset.
#' @param storage_options (list, optional) Additional keywords needed to open
#'   the dataset (e.g. for `fsspec`-style access). This is an asset-level
#'   field, so `asset_key` must also be provided when supplying it.
#' @param asset_key (character, optional) The asset to attach
#'   `storage_options` to. Required when `storage_options` is provided.
#'   `columns`, `primary_geometry`, and `row_count` are always written to
#'   item properties, matching the Table Extension specification.
#'
#' @details
#' ## Extension Schema URI
#' The Table Extension v1.2.0 schema URI is:
#' `https://stac-extensions.github.io/table/v1.2.0/schema.json`
#'
#' ## Field Placement
#' `table:columns`, `table:primary_geometry`, and `table:row_count` are Item
#' (and Collection) properties fields. `table:storage_options` is an
#' asset-level field, so it is always attached to the asset identified by
#' `asset_key`.
#'
#' ## Column Object Fields
#' Each entry in `columns` is created with `table_column()` and can include:
#' * `name`: The column name (required)
#' * `description`: Description of the column
#' * `type`: Data type of the column. If the underlying file format has a
#'   type system (e.g. Parquet), it is recommended to use those type names.
#'
#' ## Recommended Companion Extensions
#' The Table extension is often used with the **Projection** extension, to
#' describe the coordinate reference system and spatial bounds of the table.
#'
#' @return The modified STAC Item with Table extension fields added.
#'
#' @seealso
#' * [table_column()] for creating column objects
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' Table Extension Specification:
#' \url{https://github.com/stac-extensions/table}
#'
#' @examples
#' item <- stac_item(
#'   id = "my-parquet-dataset",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
#'       c(-105.5, 40.5), c(-105.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-105.5, 39.5, -104.5, 40.5),
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#'
#' cols <- list(
#'   table_column(name = "geometry", type = "binary", description = "Point geometry"),
#'   table_column(name = "id", type = "int64"),
#'   table_column(name = "value", type = "double")
#' )
#'
#' item <- item |>
#'   add_asset(
#'     "data",
#'     href = "https://example.com/data.parquet",
#'     type = "application/x-parquet",
#'     roles = c("data")
#'   ) |>
#'   add_table_extension(
#'     columns = cols,
#'     primary_geometry = "geometry",
#'     row_count = 15000,
#'     storage_options = list(anon = TRUE),
#'     asset_key = "data"
#'   )
#'
#' @export
add_table_extension <- function(
  item,
  columns = NULL,
  primary_geometry = NULL,
  row_count = NULL,
  storage_options = NULL,
  asset_key = NULL
) {
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }

  if (
    is.null(columns) &&
      is.null(primary_geometry) &&
      is.null(row_count) &&
      is.null(storage_options)
  ) {
    stop(
      "At least one of 'columns', 'primary_geometry', 'row_count', or ",
      "'storage_options' must be provided"
    )
  }

  if (!is.null(columns)) {
    if (!is.list(columns) || length(columns) == 0) {
      stop("'columns' must be a non-empty list of table_column objects")
    }
    not_col <- !vapply(columns, inherits, logical(1), "table_column")
    if (any(not_col)) {
      stop("All elements of 'columns' must be table_column objects")
    }
  }

  if (!is.null(primary_geometry)) {
    if (!is.character(primary_geometry) || length(primary_geometry) != 1) {
      stop("'primary_geometry' must be a single character string")
    }
  }

  if (!is.null(row_count)) {
    if (!is.numeric(row_count) || length(row_count) != 1 || row_count < 0) {
      stop("'row_count' must be a single non-negative number")
    }
  }

  if (!is.null(storage_options)) {
    if (!is.list(storage_options)) {
      stop("'storage_options' must be a list")
    }
    if (is.null(asset_key)) {
      stop(
        "'asset_key' must be provided when 'storage_options' is supplied, ",
        "as 'table:storage_options' is an asset-level field"
      )
    }
  }

  # Add extension to stac_extensions if not already present
  ext_uri <- "https://stac-extensions.github.io/table/v1.2.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  # table:columns, table:primary_geometry, table:row_count are always
  # item properties fields per the Table Extension specification
  if (!is.null(columns)) {
    item@properties$`table:columns` <- columns
  }

  if (!is.null(primary_geometry)) {
    item@properties$`table:primary_geometry` <- primary_geometry
  }

  if (!is.null(row_count)) {
    item@properties$`table:row_count` <- row_count
  }

  # table:storage_options is an asset-level field
  if (!is.null(storage_options)) {
    if (is.null(item@assets[[asset_key]])) {
      stop(sprintf("Asset '%s' does not exist in item", asset_key))
    }

    item@assets[[asset_key]]$`table:storage_options` <- storage_options
  }

  item
}


#' Create a Table Column Object
#'
#' @description
#' Creates a column object for use with the Table Extension. Describes a
#' single column of a tabular dataset, such as a GeoParquet file.
#'
#' @param name (character, required) The column name.
#' @param description (character, optional) Detailed description of the
#'   column. CommonMark 0.29 syntax may be used for rich text representation.
#' @param type (character, optional) Data type of the column. If the
#'   underlying file format has a type system (e.g. Parquet), it is
#'   recommended to use those type names (e.g. `"int64"`, `"double"`,
#'   `"string"`, `"bool"`, `"binary"`).
#' @param ... Additional fields for the column object.
#'
#' @return A named list of class `"table_column"`.
#'
#' @examples
#' # A geometry column
#' col <- table_column(
#'   name = "geometry",
#'   type = "binary",
#'   description = "Point geometry stored as WKB"
#' )
#'
#' # A simple attribute column
#' col <- table_column(name = "elevation", type = "double")
#'
#' @export
table_column <- function(name, description = NULL, type = NULL, ...) {
  if (missing(name) || !is.character(name) || length(name) != 1) {
    stop("'name' must be a single character string")
  }

  col <- list(name = name)

  if (!is.null(description)) {
    col$description <- description
  }

  if (!is.null(type)) {
    col$type <- type
  }

  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    col <- c(col, extra_fields)
  }

  class(col) <- c("table_column", "list")
  col
}


#' Print method for table_column objects
#'
#' @param x A table_column object.
#' @param ... Additional arguments (ignored).
#'
#' @export
print.table_column <- function(x, ...) {
  stac_print_header("Table Column")
  stac_print_list_fields(
    x,
    styles = list(name = stac_style_id, type = stac_style_key)
  )
  invisible(x)
}
