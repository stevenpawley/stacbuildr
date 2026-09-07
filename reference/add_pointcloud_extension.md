# Add the Point Cloud Extension to a STAC Item

Adds the Point Cloud Extension to a STAC Item. The extension describes
point cloud datasets acquired from either active or passive sensors —
most commonly LiDAR, but also radar, sonar, or imagery-derived
(coincidence matched) point clouds — recording how many points the
dataset holds, the dimensions (channels) each point carries, and
per-channel statistics.

## Usage

``` r
add_pointcloud_extension(
  item,
  count,
  type,
  schemas = NULL,
  density = NULL,
  statistics = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- count:

  (integer) **Required.** The number of points in the Item. Must be a
  whole number greater than or equal to 0. Values beyond
  `.Machine$integer.max` may be passed as a double.

- type:

  (character) **Required.** The phenomenology type of the point cloud.
  The specification does not constrain this to a fixed list, but
  suggests `"lidar"`, `"eopc"`, `"radar"`, `"sonar"`, and `"other"`; any
  other value is accepted with a warning.

- schemas:

  (list, optional) A list of Schema objects created with
  [`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md),
  defining the dimensions/channels of the point cloud in order.

- density:

  (numeric, optional) The number of points per square unit area, in the
  units of the data's own coordinate reference system. Must be greater
  than or equal to 0.

- statistics:

  (list, optional) A list of Stats objects created with
  [`pc_statistic()`](https://stevenpawley.github.io/stacbuildr/reference/pc_statistic.md),
  giving per-channel statistics.

- asset_key:

  (character, optional) If provided, adds the point cloud fields to a
  specific asset rather than to the item properties. Useful when an item
  bundles several point cloud files that differ in point count, density,
  or dimensions.

## Value

The modified STAC Item with Point Cloud extension fields added.

## Details

### Extension Schema URI

The Point Cloud Extension v2.0.0 schema URI is:
`https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json`

### Field Placement

All five fields may be placed either on item properties (the default) or
on a specific asset via `asset_key`. Asset-level fields were introduced
in v2.0.0 of the extension.

### The `type` Field

Unlike most enumerated STAC fields, `pc:type` is typed in the JSON
Schema as a free-form non-empty string. The values listed in the
specification are suggestions rather than a closed set, so an
unrecognised value produces a warning rather than an error and is
written through unchanged.

### Whole-byte Dimensions

`pc:schemas` sizes are in whole bytes. Several LAS point record fields
(`ReturnNumber`, `NumberOfReturns`, `ScanDirectionFlag`, and the
classification flags) are bit-packed into shared bytes in the file
itself and cannot be described that way. The convention established by
PDAL, and followed by
[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md),
is to report each as the unpacked, whole-byte dimension a reader
materialises it into.

## References

Point Cloud Extension Specification:
<https://github.com/stac-extensions/pointcloud>

## See also

- [`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md)
  for creating Schema objects

- [`pc_statistic()`](https://stevenpawley.github.io/stacbuildr/reference/pc_statistic.md)
  for creating Stats objects

- [`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md)
  for building an item straight from a LAS/LAZ file

## Examples

``` r
item <- stac_item(
  id = "autzen",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-123.1, 44.0), c(-123.0, 44.0), c(-123.0, 44.1),
      c(-123.1, 44.1), c(-123.1, 44.0)
    ))
  ),
  bbox = c(-123.1, 44.0, -123.0, 44.1),
  datetime = "2023-06-15T00:00:00Z"
)

item <- item |>
  add_pointcloud_extension(
    count   = 10653336,
    type    = "lidar",
    density = 4.664,
    schemas = list(
      pc_schema("X", size = 8, type = "floating"),
      pc_schema("Y", size = 8, type = "floating"),
      pc_schema("Z", size = 8, type = "floating"),
      pc_schema("Intensity", size = 2, type = "unsigned")
    ),
    statistics = list(
      pc_statistic("Z", position = 2, minimum = 406.14, maximum = 615.26)
    )
  )
```
