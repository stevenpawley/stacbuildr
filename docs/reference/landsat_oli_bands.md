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

item <- stac_item(
  id = "LC09_L2SP_001002_20230615",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T10:30:00Z",
  properties = list()
)

item <- item |>
  add_eo_extension(bands = bands)
```
