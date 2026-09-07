# Add the Projection Extension to a STAC Item

Adds the Projection Extension to a STAC Item, recording the coordinate
reference system and grid geometry of the source data.

STAC requires an Item's `geometry` and `bbox` to be WGS84
longitude/latitude, whatever projection the data is actually stored in.
The Projection Extension carries the native CRS alongside it, so a
client can locate a pixel or read a window without opening the file:

- **`proj:code`**: The CRS as an `AUTHORITY:CODE` string, e.g.
  `"EPSG:32612"`.

- **`proj:wkt2`**: The CRS as a WKT2 string, for CRSs with no authority
  code.

- **`proj:projjson`**: The CRS as a PROJJSON object.

- **`proj:geometry`** / **`proj:bbox`**: Footprint in the native CRS.

- **`proj:shape`**: Raster dimensions as `c(rows, columns)`.

- **`proj:transform`**: The affine transform from pixel to CRS
  coordinates.

- **`proj:centroid`**: Centroid as WGS84 latitude and longitude.

[`item_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_terra.md)
and
[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md)
call this function for you. Use it directly when building an Item by
hand, or when attaching projection metadata to an Item created with
[`item_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_sf.md).

## Usage

``` r
add_projection_extension(
  item,
  code = NULL,
  wkt2 = NULL,
  projjson = NULL,
  geometry = NULL,
  bbox = NULL,
  centroid = NULL,
  shape = NULL,
  transform = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- code:

  (character, optional) The CRS as an `AUTHORITY:CODE` string, e.g.
  `"EPSG:32612"` or `"OGC:CRS84"`. This field replaced the deprecated
  `proj:epsg` in v2.0.0 of the extension, so a bare EPSG number must be
  prefixed with its authority.

- wkt2:

  (character, optional) The CRS as a WKT2 string. Use this for a CRS
  with no authority code, or alongside `code` for clients that prefer a
  full definition.

- projjson:

  (list, optional) The CRS as a PROJJSON object, supplied as a named
  list.

- geometry:

  (list, optional) A GeoJSON geometry giving the footprint in the native
  CRS, as a named list with `type` and `coordinates`. Unlike the Item's
  own `geometry`, this is *not* reprojected to WGS84.

- bbox:

  (numeric, optional) Bounding box in the native CRS: four values
  (`xmin, ymin, xmax, ymax`) for 2D data, or six
  (`xmin, ymin, zmin, xmax, ymax, zmax`) for 3D data such as a point
  cloud.

- centroid:

  (optional) The centroid in WGS84, as a named numeric vector or list
  with `lat` and `lon` elements.

- shape:

  (numeric, optional) Raster dimensions as `c(rows, columns)` — height
  first, then width.

- transform:

  (numeric, optional) The affine transform mapping pixel coordinates to
  CRS coordinates. Six values in the order
  `c(xscale, rowrot, xmin, colrot, yscale, ymax)`, optionally followed
  by the bottom row `c(0, 0, 1)` for nine in total. `yscale` is normally
  negative for a north-up raster.

- asset_key:

  (character, optional) Key of an asset in the Item. When supplied, the
  fields are written to that asset rather than to the Item's properties.
  Use this when assets in one Item are in different projections or at
  different resolutions.

## Value

The modified STAC Item with projection metadata attached.

## Details

### Extension Schema URI

`https://stac-extensions.github.io/projection/v2.0.0/schema.json`

### Item or asset placement

Every field may sit on the Item's properties or on an individual asset.
Put them on the Item when all its assets share a projection, and on
assets when they do not — a common case being a Sentinel-2 scene whose
10 m, 20 m and 60 m bands share a CRS but differ in `proj:shape` and
`proj:transform`.

## See also

[`item_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_terra.md)
and
[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md),
which add these fields automatically from a raster or point cloud.

## Examples

``` r
item <- stac_item(
  id = "utm-scene",
  geometry = list(type = "Point", coordinates = c(-113.5, 51.0)),
  bbox = c(-113.5, 51.0, -113.5, 51.0),
  datetime = "2024-06-01T00:00:00Z"
)

# A projected raster: CRS, grid shape and affine transform
item <- add_projection_extension(
  item,
  code = "EPSG:32612",
  shape = c(5558, 9559),
  transform = c(30, 0, 712710, 0, -30, 5654790),
  bbox = c(712710, 5487090, 999480, 5654790)
)

item@properties$`proj:code`
#> [1] "EPSG:32612"

# Per-asset placement, for assets at different resolutions
item <- add_asset(
  item,
  key = "swir",
  href = "https://example.com/swir.tif",
  type = "image/tiff; application=geotiff"
)
item <- add_projection_extension(
  item,
  shape = c(2779, 4780),
  transform = c(60, 0, 712710, 0, -60, 5654790),
  asset_key = "swir"
)
```
