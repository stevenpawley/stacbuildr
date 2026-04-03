# Convert sf Geometry to GeoJSON

Converts an sf object's geometry to a GeoJSON-compatible list structure.
If the sf object contains multiple features, they are unioned into a
single geometry, since a STAC item has one geometry.

## Usage

``` r
geometry_from_sf(sf_obj)
```

## Arguments

- sf_obj:

  An sf object.

## Value

A GeoJSON geometry object (list).

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)

polygon <- st_read("boundary.shp")
geojson <- geometry_from_sf(polygon)
} # }
```
