# Add Vector Extension to a STAC Item

Adds the Vector Extension to a STAC Item. The Vector Extension describes
basic properties and metrics of vector data (geometries with additional
properties), such as which geometry types are present in the dataset and
the minimum mapping unit/width used when the data was digitized.

## Usage

``` r
add_vector_extension(
  item,
  geometry_types = NULL,
  mmu = NULL,
  mmw = NULL,
  reference_scale = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- geometry_types:

  (character, optional) A vector of the geometry types present in the
  dataset. Must be one or more of `"Point"`, `"MultiPoint"`,
  `"LineString"`, `"MultiLineString"`, `"Polygon"`, `"MultiPolygon"`, or
  `"GeometryCollection"`. Each type may only appear once.

- mmu:

  (numeric, optional) Minimum Mapping Unit: the area, in square meters,
  of the smallest polygon represented in the dataset. Must be greater
  than 0.

- mmw:

  (numeric, optional) Minimal Mapping Width: the width, in meters, of
  the smallest real-world feature represented as a polygon in the
  dataset. Must be greater than 0.

- reference_scale:

  (numeric, optional) The representative fraction denominator of the
  scale that the data was originally digitized or captured at (e.g.
  `50000` for a scale of 1:50,000). Must be greater than 0.

- asset_key:

  (character, optional) If provided, adds the vector fields to a
  specific asset rather than to the item properties. Useful when
  different assets within an item represent vector data digitized at
  different scales or containing different geometry types.

## Value

The modified STAC Item with Vector extension fields added.

## Details

### Extension Schema URI

The Vector Extension v0.1.0 schema URI is:
`https://stac-extensions.github.io/vector/v0.1.0/schema.json`

### Field Placement

All four fields may be placed either on item properties (the default) or
on a specific asset via `asset_key`. The extension also allows these
fields to be set on individual Table Column objects (see
[`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md))
— pass them as extra named arguments to
[`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md)
(e.g. `"vector:geometry_types" = "Point"`) when a table has multiple
geometry columns with different characteristics.

### Companion Extensions

The Vector Extension is commonly used alongside the **Table Extension**
(see
[`add_table_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_table_extension.md))
for tabular/columnar vector datasets such as GeoParquet.

## References

Vector Extension Specification:
<https://github.com/stac-extensions/vector>

## See also

- [`add_table_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_table_extension.md)
  for describing tabular vector datasets

- [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md)
  for creating table column objects

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

## Examples

``` r
item <- stac_item(
  id = "my-vector-dataset",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T00:00:00Z"
)

item <- item |>
  add_vector_extension(
    geometry_types  = c("Polygon", "MultiPolygon"),
    mmu             = 100,
    reference_scale = 50000
  )
```
