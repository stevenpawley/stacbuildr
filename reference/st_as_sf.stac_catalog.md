# Coerce a STAC Catalog, Collection or Item to an sf Object

Returns the table that
[as.data.frame()](https://stevenpawley.github.io/stacbuildr/reference/as.data.frame.stac_catalog.md)
gives, with the Item footprints attached as a geometry column. This is
the shape most spatial work in R wants: filter on properties, plot the
footprints, join against other layers.

STAC types an Item's `geometry` as GeoJSON in WGS84 whatever projection
the underlying data uses, so the result is always in EPSG:4326. The
native CRS, when an Item records one, is in its `proj:code` property —
see
[`add_projection_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_projection_extension.md).

An Item with a null geometry, which STAC allows for non-spatial data,
gets an empty geometry rather than being dropped.

## Usage

``` r
# S3 method for class 'stac_catalog'
st_as_sf(x, ..., resolve = FALSE, base_path = ".")

# S3 method for class 'stac_item'
st_as_sf(x, ...)
```

## Arguments

- x:

  A `stac_catalog`, `stac_collection` or `stac_item` object.

- ...:

  Ignored.

- resolve:

  (logical) When the Items are not held in memory — as after
  [`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)
  — read each one from its `item` link. Default `FALSE`.

- base_path:

  (character) Directory that relative item hrefs are resolved against
  when `resolve = TRUE`. Default `"."`.

## Value

An `sf` object with one row per Item, in EPSG:4326.

## Examples

``` r
item <- stac_item(
  id = "scene-1",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-114, 51), c(-113, 51), c(-113, 52), c(-114, 52), c(-114, 51)
    ))
  ),
  bbox = c(-114, 51, -113, 52),
  datetime = "2024-06-01T00:00:00Z",
  properties = list(`eo:cloud_cover` = 7.5)
)

scenes <- sf::st_as_sf(item)
sf::st_bbox(scenes)
#> xmin ymin xmax ymax 
#> -114   51 -113   52 
```
