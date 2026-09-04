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
#' @param asset_key (character, optional) If provided, adds the table fields
#'   to a specific asset rather than to the item properties. Useful when an
#'   item bundles several tabular assets with different schemas. Required when
#'   `storage_options` is provided, since `table:storage_options` has no
#'   item-level meaning.
#'
#' @details
#' ## Extension Schema URI
#' The Table Extension v1.2.0 schema URI is:
#' `https://stac-extensions.github.io/table/v1.2.0/schema.json`
#'
#' ## Field Placement
#' `asset_key` routes every field it can, as in the other `add_*_extension()`
#' functions: omit it and `table:columns`, `table:primary_geometry` and
#' `table:row_count` are written to the item properties; supply it and they are
#' written to that asset instead.
#'
#' Omitting `asset_key` gives the placement the Table Extension README
#' describes, which lists those three under "Item Properties and Collection
#' Fields". Item-level placement is the right default for the common case of an
#' item wrapping a single table. Per-asset placement is useful when one item
#' holds several tables; the extension's JSON schema validates table fields on
#' assets and `item_assets` as well as on properties.
#'
#' `table:storage_options` is the exception. The README gives it its own "Asset
#' Object fields" section, and it carries `fsspec`-style arguments for opening
#' one particular file, so it is always written to the asset and `asset_key` is
#' required whenever it is supplied.
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
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (
    is.null(columns) &&
      is.null(primary_geometry) &&
      is.null(row_count) &&
      is.null(storage_options)
  ) {
    cli::cli_abort(
      "At least one of 'columns', 'primary_geometry', 'row_count', or 'storage_options' must be provided"
    )
  }

  if (!is.null(columns)) {
    if (!is.list(columns) || length(columns) == 0) {
      cli::cli_abort(
        "'columns' must be a non-empty list of table_column objects"
      )
    }
    not_col <- !vapply(columns, inherits, logical(1), "table_column")
    if (any(not_col)) {
      cli::cli_abort("All elements of 'columns' must be table_column objects")
    }
  }

  if (!is.null(primary_geometry)) {
    if (!is.character(primary_geometry) || length(primary_geometry) != 1) {
      cli::cli_abort("'primary_geometry' must be a single character string")
    }
  }

  if (!is.null(row_count)) {
    if (!is.numeric(row_count) || length(row_count) != 1 || row_count < 0) {
      cli::cli_abort("'row_count' must be a single non-negative number")
    }
  }

  if (!is.null(storage_options)) {
    if (!is.list(storage_options)) {
      cli::cli_abort("'storage_options' must be a list")
    }
    if (is.null(asset_key)) {
      cli::cli_abort(c(
        "'asset_key' must be provided when 'storage_options' is supplied.",
        "i" = "'table:storage_options' is an asset-level field."
      ))
    }
  }

  if (!is.null(asset_key)) {
    if (!is.character(asset_key) || length(asset_key) != 1) {
      cli::cli_abort("'asset_key' must be a single character string")
    }
    if (is.null(item@assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
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

  # table:columns, table:primary_geometry and table:row_count follow
  # `asset_key`, as in the other add_*_extension() functions. Omitting it gives
  # the item-level placement the Table Extension README describes.
  fields <- list()

  if (!is.null(columns)) fields$`table:columns` <- columns
  if (!is.null(primary_geometry)) {
    fields$`table:primary_geometry` <- primary_geometry
  }
  if (!is.null(row_count)) fields$`table:row_count` <- row_count

  if (is.null(asset_key)) {
    for (field_name in names(fields)) {
      item@properties[[field_name]] <- fields[[field_name]]
    }
  } else {
    for (field_name in names(fields)) {
      item@assets[[asset_key]][[field_name]] <- fields[[field_name]]
    }
  }

  # table:storage_options is always an asset-level field
  if (!is.null(storage_options)) {
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
    cli::cli_abort("'name' must be a single character string")
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
