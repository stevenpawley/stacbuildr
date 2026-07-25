# Create Standard PlanetScope Bands

Helper function to create standard band definitions for PlanetScope
sensors (Dove Classic, Dove-R, SuperDove).

## Usage

``` r
planetscope_bands()
```

## Value

A list of EO band objects representing PlanetScope bands.

## Examples

``` r
bands <- planetscope_bands()
#> Warning: 'green1' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'yellow' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
```
