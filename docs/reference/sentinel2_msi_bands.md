# Create Standard Sentinel-2 MSI Bands

Helper function to create standard band definitions for Sentinel-2
MultiSpectral Instrument (MSI) sensors.

## Usage

``` r
sentinel2_msi_bands()
```

## Value

A list of EO band objects representing Sentinel-2 MSI bands.

## Examples

``` r
bands <- sentinel2_msi_bands()

item <- item |>
  add_eo_extension(bands = bands)
#> Error: object 'item' not found
```
