# Create Standard Landsat 8/9 OLI Bands

Helper function to create standard band definitions for Landsat 8 and 9
Operational Land Imager (OLI) sensors.

## Usage

``` r
landsat_oli_bands(include_thermal = FALSE)
```

## Arguments

- include_thermal:

  (logical, optional) If TRUE, includes TIRS thermal bands (B10, B11).
  Default is FALSE (OLI bands only).

## Value

A list of EO band objects representing Landsat OLI/TIRS bands.

## Examples

``` r
bands <- landsat_oli_bands()

item <- item |>
  add_eo_extension(bands = bands)
#> Error: object 'item' not found
```
