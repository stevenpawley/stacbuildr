# Create Standard WorldView-3 Bands

Helper function to create standard band definitions for WorldView-3
sensors.

## Usage

``` r
worldview3_bands()
```

## Value

A list of EO band objects representing WorldView-3 bands.

## Examples

``` r
bands <- worldview3_bands()
#> Warning: 'yellow' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'nir01' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'nir02' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir01' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir02' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir03' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir04' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir05' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir06' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir07' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
#> Warning: 'swir08' is not a standard common_name. Standard names: coastal, blue, green, red, rededge, rededge071, rededge075, rededge078, nir, nir08, nir09, cirrus, swir16, swir22, lwir, lwir11, lwir12, pan
```
