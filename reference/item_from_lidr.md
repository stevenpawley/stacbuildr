# Create a STAC Item from a LAS/LAZ Point Cloud

Creates a STAC Item from a point cloud read with the `lidR` package,
populating the Point Cloud extension from the file's public header
block. Geometry, bounding box, projection metadata, point count,
density, and the dimension schema are all derived from the header alone,
so items can be built from very large files without reading a single
point.

## Usage

``` r
item_from_lidr(
  x,
  href = NULL,
  id = NULL,
  datetime = NULL,
  properties = list(),
  assets = list(),
  asset_key = "data",
  asset_roles = c("data"),
  pc_type = "lidar",
  add_pointcloud = TRUE,
  add_projection = TRUE,
  add_schemas = TRUE,
  calculate_statistics = FALSE,
  reproject_to_wgs84 = TRUE,
  ...
)
```

## Arguments

- x:

  A `LASheader` object, a `LAS` object, or a path to a LAS/LAZ file.

- href:

  (character, optional) URI for the point cloud asset. If provided, the
  file is added as an asset and `id` is derived from the basename when
  not explicitly set. Defaults to `x` when `x` is a file path.

- id:

  (character, optional) Item ID. If NULL, derived from `href` basename.

- datetime:

  (character, optional) ISO 8601 datetime string. If NULL, the file
  creation year and day of year from the LAS header are used; if those
  are unset (which is common), the current time is used with a warning.

- properties:

  (list, optional) Additional properties for the item.

- assets:

  (list, optional) Additional assets beyond the point cloud.

- asset_key:

  (character, optional) Key name for the point cloud asset. Default is
  "data".

- asset_roles:

  (character vector, optional) Roles for the point cloud asset. Default
  is `c("data")`.

- pc_type:

  (character, optional) The `pc:type` phenomenology value. Default is
  `"lidar"`.

- add_pointcloud:

  (logical, optional) If TRUE, adds the Point Cloud extension. Default
  is TRUE.

- add_projection:

  (logical, optional) If TRUE and the file declares a CRS, adds
  Projection extension fields in the file's native CRS. Default is TRUE.

- add_schemas:

  (logical, optional) If TRUE, derives `pc:schemas` from the point data
  record format and Extra Bytes VLR. Default is TRUE.

- calculate_statistics:

  (logical, optional) If TRUE, computes full per-channel `pc:statistics`
  (average, stddev, variance and so on). This reads every point and can
  be slow for large files. When FALSE, only the X/Y/Z bounds carried in
  the header are recorded. Default is FALSE.

- reproject_to_wgs84:

  (logical, optional) If TRUE and the file is not in WGS84, reprojects
  the extent to EPSG:4326, which STAC requires. Default is TRUE.

- ...:

  Additional arguments passed to
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

## Value

A STAC Item object with the point cloud metadata.

## Details

### Statistics

`calculate_statistics = FALSE` still records `minimum`, `maximum` and
`count` for the X, Y and Z channels, because the LAS public header block
carries those bounds. The remaining statistics, and statistics for any
other channel, require a full read of the points.

### Point Density

`pc:density` is `lidR`'s point density: the point count divided by the
area of the file's bounding rectangle, in the units of the file's own
CRS. For data in a projected CRS in metres this is points per square
metre.

## See also

- [`items_from_lascatalog()`](https://stevenpawley.github.io/stacbuildr/reference/items_from_lascatalog.md)
  for building items for a whole tiled collection

- [`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md)
  to set the fields by hand

- [`schemas_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/schemas_from_lidr.md)
  for just the dimension schema

## Examples

``` r
if (FALSE) { # \dontrun{
library(lidR)

f <- system.file("extdata", "Megaplot.laz", package = "lidR")

# Header only: fast even for very large files
item <- item_from_lidr(f)

# With full per-channel statistics, which reads the points
item <- item_from_lidr(
  f,
  href = "https://example.com/Megaplot.laz",
  datetime = "2023-06-15T10:30:00Z",
  calculate_statistics = TRUE
)
} # }
```
