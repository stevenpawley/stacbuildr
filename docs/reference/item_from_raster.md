# Create a STAC Item from a Stars Object

Creates a STAC Item from a `stars` raster object. Automatically extracts
spatial metadata including geometry, bbox, CRS, and optionally band
information and statistics.

## Usage

``` r
item_from_raster(
  stars_obj,
  href = NULL,
  id = NULL,
  datetime = NULL,
  properties = list(),
  assets = list(),
  asset_key = "data",
  asset_roles = c("data"),
  add_raster_bands = TRUE,
  add_eo_bands = FALSE,
  calculate_statistics = FALSE,
  reproject_to_wgs84 = TRUE,
  ...
)
```

## Arguments

- stars_obj:

  A `stars` object.

- href:

  (character, optional) URI for the main raster asset. If provided, the
  raster is added as an asset and `id` is derived from the basename when
  not explicitly set. If NULL, no asset is added and `id` must be
  supplied.

- id:

  (character, optional) Item ID. If NULL, derived from `href` basename.

- datetime:

  (character, optional) ISO 8601 datetime string. If NULL, uses current
  time.

- properties:

  (list, optional) Additional properties for the item.

- assets:

  (list, optional) Additional assets beyond the main raster. The main
  raster is automatically added as an asset.

- asset_key:

  (character, optional) Key name for the main raster asset. Default is
  "data".

- asset_roles:

  (character vector, optional) Roles for the main raster asset. Default
  is c("data").

- add_raster_bands:

  (logical, optional) If TRUE, adds raster extension with band metadata.
  Default is TRUE.

- add_eo_bands:

  (logical, optional) If TRUE and band information is available, adds EO
  extension. Requires band metadata. Default is FALSE.

- calculate_statistics:

  (logical, optional) If TRUE, calculates band statistics (min, max,
  mean, stddev). Can be slow for large rasters. Default is FALSE.

- reproject_to_wgs84:

  (logical, optional) If TRUE and raster is not in WGS84, reprojects the
  bbox geometry to WGS84 (EPSG:4326). STAC requires WGS84. Default is
  TRUE.

- ...:

  Additional arguments passed to
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

## Value

A STAC Item object with the raster metadata.

## Details

**STAC CRS Requirement:** STAC Items must use WGS84 (EPSG:4326) for
geometry and bbox. If your raster uses a different CRS, the geometry
will be reprojected automatically when `reproject_to_wgs84 = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(stars)

r <- read_stars("path/to/image.tif")

item <- item_from_raster(
  r,
  href = "path/to/image.tif",
  datetime = "2023-06-15T10:30:00Z"
)

item <- item_from_raster(
  r,
  href = "https://example.com/image.tif",
  id = "LC08_001",
  datetime = "2023-06-15T10:30:00Z",
  properties = list(platform = "landsat-8"),
  calculate_statistics = TRUE
)
} # }
```
