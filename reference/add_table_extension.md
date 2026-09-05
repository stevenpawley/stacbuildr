# Add Table Extension to a STAC Item

Adds the Table Extension to a STAC Item. The Table Extension provides
fields to describe tabular datasets (e.g. GeoParquet, CSV, flat
GeoPackage/SQLite tables) referenced by an Item, including the columns
present, which column holds the primary geometry, and the number of
rows.

## Usage

``` r
add_table_extension(
  item,
  columns = NULL,
  primary_geometry = NULL,
  row_count = NULL,
  storage_options = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- columns:

  (list, optional) A list of column objects created with
  [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md),
  one entry per column in the table.

- primary_geometry:

  (character, optional) The name of the column that holds the primary
  geometry, for use by libraries such as geopandas or `sf` when a table
  has multiple geometry columns.

- row_count:

  (numeric, optional) The number of rows in the dataset.

- storage_options:

  (list, optional) Additional keywords needed to open the dataset (e.g.
  for `fsspec`-style access). This is an asset-level field, so
  `asset_key` must also be provided when supplying it.

- asset_key:

  (character, optional) If provided, adds the table fields to a specific
  asset rather than to the item properties. Useful when an item bundles
  several tabular assets with different schemas. Required when
  `storage_options` is provided, since `table:storage_options` has no
  item-level meaning.

## Value

The modified STAC Item with Table extension fields added.

## Details

### Extension Schema URI

The Table Extension v1.2.0 schema URI is:
`https://stac-extensions.github.io/table/v1.2.0/schema.json`

### Field Placement

`asset_key` routes every field it can, as in the other
`add_*_extension()` functions: omit it and `table:columns`,
`table:primary_geometry` and `table:row_count` are written to the item
properties; supply it and they are written to that asset instead.

Omitting `asset_key` gives the placement the Table Extension README
describes, which lists those three under "Item Properties and Collection
Fields". Item-level placement is the right default for the common case
of an item wrapping a single table. Per-asset placement is useful when
one item holds several tables; the extension's JSON schema validates
table fields on assets and `item_assets` as well as on properties.

`table:storage_options` is the exception. The README gives it its own
"Asset Object fields" section, and it carries `fsspec`-style arguments
for opening one particular file, so it is always written to the asset
and `asset_key` is required whenever it is supplied.

### Column Object Fields

Each entry in `columns` is created with
[`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md)
and can include:

- `name`: The column name (required)

- `description`: Description of the column

- `type`: Data type of the column. If the underlying file format has a
  type system (e.g. Parquet), it is recommended to use those type names.

### Recommended Companion Extensions

The Table extension is often used with the **Projection** extension, to
describe the coordinate reference system and spatial bounds of the
table.

## References

Table Extension Specification:
<https://github.com/stac-extensions/table>

## See also

- [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md)
  for creating column objects

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

## Examples

``` r
item <- stac_item(
  id = "my-parquet-dataset",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T10:30:00Z"
)

cols <- list(
  table_column(name = "geometry", type = "binary", description = "Point geometry"),
  table_column(name = "id", type = "int64"),
  table_column(name = "value", type = "double")
)

item <- item |>
  add_asset(
    "data",
    href = "https://example.com/data.parquet",
    type = "application/x-parquet",
    roles = c("data")
  ) |>
  add_table_extension(
    columns = cols,
    primary_geometry = "geometry",
    row_count = 15000,
    storage_options = list(anon = TRUE),
    asset_key = "data"
  )
```
