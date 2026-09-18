# Create a GeoJSON Geometry

Creates an S3 representation of a GeoJSON geometry. Plain GeoJSON lists
are accepted by
[`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
and converted automatically, so this constructor is mainly useful when
building or inspecting geometries directly.

## Usage

``` r
stac_geometry(type, coordinates = NULL, geometries = list())
```

## Arguments

- type:

  A GeoJSON geometry type.

- coordinates:

  Coordinates for every geometry type except `"GeometryCollection"`.

- geometries:

  A list of geometries for `"GeometryCollection"`. Plain GeoJSON
  geometry lists are converted recursively.

## Value

A `stac_geometry` S3 object. Access its fields with `$`, for example
`geometry$type` and `geometry$coordinates`.

## Examples

``` r
geometry <- stac_geometry("Point", coordinates = c(-105, 40))
geometry$type
#> [1] "Point"
geometry$coordinates
#> [1] -105   40
```
