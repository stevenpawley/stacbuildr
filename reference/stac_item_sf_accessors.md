# sf Accessors for a STAC Item

A STAC Item is a GeoJSON Feature, so the `sf` accessors work on it
directly.

- [`st_geometry()`](https://r-spatial.github.io/sf/reference/st_geometry.html)
  returns the Item's footprint as a length-1 `sfc`.

- [`st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html)
  returns its bounding box from the Item's `bbox` field. A STAC Item
  must carry one whenever it has a geometry, so the empty bbox comes
  back only for a non-spatial Item with neither.

- [`st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  returns EPSG:4326. An Item's `geometry` and `bbox` are WGS84 by
  specification whatever projection the underlying data uses; the native
  CRS, when recorded, is in the `proj:code` property.

## Usage

``` r
# S3 method for class 'stac_item'
st_geometry(obj, ...)

# S3 method for class 'stac_item'
st_bbox(obj, ...)

# S3 method for class 'stac_item'
st_crs(x, ...)
```

## Arguments

- obj:

  A `stac_item` object.

- ...:

  Ignored.

- x:

  A `stac_item` object.

## Value

[`st_geometry()`](https://r-spatial.github.io/sf/reference/st_geometry.html)
an `sfc`;
[`st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html) a
`bbox`;
[`st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html) a
`crs`.

## Examples

``` r
item <- stac_item(
  id = "scene-1",
  geometry = list(type = "Point", coordinates = c(-114, 51)),
  bbox = c(-114, 51, -114, 51),
  datetime = "2024-06-01T00:00:00Z"
)

sf::st_geometry(item)
#> Geometry set for 1 feature 
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -114 ymin: 51 xmax: -114 ymax: 51
#> Geodetic CRS:  WGS 84
#> POINT (-114 51)
sf::st_bbox(item)
#> xmin ymin xmax ymax 
#> -114   51 -114   51 
sf::st_crs(item)$epsg
#> [1] 4326
```
