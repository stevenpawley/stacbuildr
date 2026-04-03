# Add EO Extension to a STAC Item

Adds the Electro-Optical (EO) Extension to a STAC Item. EO data is
considered to be data that represents a snapshot of the Earth for a
single date and time. It could consist of multiple spectral bands in any
part of the electromagnetic spectrum.

**Important Note on STAC 1.1.0 Changes:** This extension formerly had a
field eo:bands, which has been removed in favor of a general field bands
in STAC common metadata. The structure is the same—it's an array of Band
Objects—but fields from the EO extension now have an `eo:` prefix, while
more general fields like `description` have been moved to common
metadata and don't need a prefix.

## Usage

``` r
add_eo_extension(
  item,
  bands = NULL,
  cloud_cover = NULL,
  snow_cover = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with [`stac_item()`](stac_item.md).

- bands:

  (list, optional) A list of band objects created with
  [`eo_band()`](eo_band.md). Each band describes the characteristics of
  a spectral band. If the asset has multiple bands, provide a list with
  one entry per band in order.

- cloud_cover:

  (numeric, optional) Estimate of cloud cover as a percentage (0-100).
  Should only include valid data regions, excluding nodata areas. If not
  available or cannot be calculated, should not be provided.

- snow_cover:

  (numeric, optional) Estimate of snow/ice cover as a percentage (0-100)
  of the entire scene. Should only include valid data regions. If not
  available, should not be provided.

- asset_key:

  (character, optional) If provided, adds the bands to a specific asset
  rather than to the item properties. The cloud_cover and snow_cover
  properties will always be added to item properties (not assets) as
  they typically apply to the entire scene.

## Value

The modified STAC Item with EO extension fields added.

## Details

### Extension Schema URI

The EO Extension v1.1.0 schema URI is:
`https://stac-extensions.github.io/eo/v1.1.0/schema.json`

### Band Object Fields

Each band can contain the following EO-specific fields (all with `eo:`
prefix):

- `eo:common_name`: Common name of the band (e.g., "red", "green",
  "blue", "nir")

- `eo:center_wavelength`: Center wavelength in micrometers (μm)

- `eo:full_width_half_max`: Full width at half maximum (FWHM) in
  micrometers

- `eo:solar_illumination`: Solar illumination at the band's wavelength

Plus common metadata fields without prefix:

- `name`: Name of the band (e.g., "B01", "B02", "B1", "B5")

- `description`: Description of the band

### Common Band Names

The EO extension defines standard common names for typical spectral
bands:

- **Visible**: `"coastal"`, `"blue"`, `"green"`, `"red"`

- **Red Edge**: `"rededge"`, `"rededge071"`, `"rededge075"`,
  `"rededge078"`

- **Near Infrared**: `"nir"`, `"nir08"`, `"nir09"`

- **Short-wave Infrared**: `"cirrus"`, `"swir16"`, `"swir22"`

- **Long-wave Infrared**: `"lwir"`, `"lwir11"`, `"lwir12"`

- **Panchromatic**: `"pan"`

### Coverage Percentages

It is important to consider only the valid data regions, excluding any
"nodata" areas while calculating both the coverages. Usually,
cloud_cover and snow_cover should be used in Item Properties rather than
Item Assets, as an Item from an electro-optical source is a single
snapshot of the Earth, so the coverages usually apply to all assets.

### Wavelength Units

For example, if we were given a band described as (0.4um - 0.5um) the
eo:center_wavelength would be 0.45um and the eo:full_width_half_max
would be 0.1um.

### Recommended Companion Extensions

The EO extension is often used with:

- **Instrument Fields** (common metadata): platform, instruments,
  constellation

- **View Extension**: For view geometry (off-nadir, azimuth, sun angles)

- **Raster Extension**: For data type, nodata, scale/offset

## References

EO Extension Specification: <https://github.com/stac-extensions/eo>

## See also

- [`eo_band()`](eo_band.md) for creating EO band objects

- [`add_raster_extension()`](add_raster_extension.md) for adding raster
  metadata

- [`stac_item()`](stac_item.md) for creating STAC Items

## Examples

``` r
# Create an item
item <- stac_item(
  id = "LC08_L2SP_001002_20230615",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-06-15T10:30:00Z",
  properties = list(
    platform = "landsat-8",
    instruments = c("oli", "tirs")
  )
)
#> Error: object 'my_geometry' not found

# Add EO extension with cloud cover
item <- add_eo_extension(
  item,
  cloud_cover = 12.5
)
#> Error: object 'item' not found

# Create multispectral bands
red_band <- eo_band(
  name = "B4",
  common_name = "red",
  center_wavelength = 0.665,
  full_width_half_max = 0.038
)

green_band <- eo_band(
  name = "B3",
  common_name = "green",
  center_wavelength = 0.560,
  full_width_half_max = 0.043
)

blue_band <- eo_band(
  name = "B2",
  common_name = "blue",
  center_wavelength = 0.490,
  full_width_half_max = 0.038
)

nir_band <- eo_band(
  name = "B5",
  common_name = "nir",
  center_wavelength = 0.865,
  full_width_half_max = 0.033
)

# Add bands to the item
item <- item |>
  add_asset(
    "visual",
    href = "https://example.com/LC08_visual.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_eo_extension(
    bands = list(red_band, green_band, blue_band, nir_band),
    cloud_cover = 5.2,
    asset_key = "visual"
  )
#> Error: object 'item' not found

# Combine EO and Raster extensions
combined_band <- eo_band(
  name = "B4",
  common_name = "red",
  center_wavelength = 0.665,
  full_width_half_max = 0.038,
  description = "Red band (0.64-0.67 μm)"
)

# Add raster properties to the same band
combined_band$nodata <- 0
combined_band$data_type <- "uint16"
combined_band$`raster:spatial_resolution` <- 30
combined_band$`raster:scale` <- 0.0001
combined_band$`raster:offset` <- 0

item <- item |>
  add_eo_extension(bands = list(combined_band)) |>
  add_raster_extension(bands = list(combined_band))
#> Error: object 'item' not found
```
