# Convert sf Geometry to GeoJSON

Converts an sf object's geometry to a
[`stac_geometry()`](https://stevenpawley.github.io/stacbuildr/reference/stac_geometry.md)
S3 object. If the sf object contains multiple features, they are unioned
into a single geometry, since a STAC item has one geometry.

## Usage

``` r
geometry_from_sf(sf_obj)
```

## Arguments

- sf_obj:

  An sf object.

## Value

A `stac_geometry` S3 object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)

polygon <- st_read("boundary.shp")
geometry <- geometry_from_sf(polygon)
geometry$type
} # }
```
