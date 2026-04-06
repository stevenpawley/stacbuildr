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

item <- stac_item(
  id = "S2A_MSIL2A_20230615T101021",
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
