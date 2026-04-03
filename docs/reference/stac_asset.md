# Create a STAC Asset

Creates an asset object for use in STAC Items. Assets are the actual
data files or resources associated with an Item (e.g., imagery files,
metadata documents, thumbnails).

## Usage

``` r
stac_asset(
  href,
  title = NULL,
  description = NULL,
  type = NULL,
  roles = NULL,
  ...
)
```

## Arguments

- href:

  (character, required) URI to the asset object. Can be relative or
  absolute. Examples: `"./data/image.tif"`,
  `"https://example.com/image.tif"`.

- title:

  (character, optional) Displayed title for the asset.

- description:

  (character, optional) Description of the asset.

- type:

  (character, optional) Media type of the asset. Examples:
  `"image/tiff; application=geotiff"`, `"image/png"`,
  `"application/json"`. See
  <https://www.iana.org/assignments/media-types/media-types.xhtml>.

- roles:

  (character vector, optional) Semantic roles of the asset. Common
  values include: `"thumbnail"`, `"overview"`, `"data"`, `"metadata"`,
  `"visual"`, `"composite"`.

- ...:

  Additional fields for the asset. This allows for extension-specific
  properties like `"eo:bands"`, `"raster:bands"`, `"proj:shape"`, etc.

## Value

A list representing a STAC asset object.

## Examples

``` r
# Simple asset
asset <- stac_asset(
  href = "https://example.com/image.tif",
  title = "RGB Image",
  type = "image/tiff; application=geotiff"
)

# Asset with roles
asset <- stac_asset(
  href = "./data/LC08_B4.tif",
  title = "Band 4 - Red",
  type = "image/tiff; application=geotiff",
  roles = c("data", "reflectance")
)

# Asset with extension properties
asset <- stac_asset(
  href = "./data/multispectral.tif",
  type = "image/tiff; application=geotiff; profile=cloud-optimized",
  roles = c("data"),
  "eo:bands" = list(
    list(name = "B1", common_name = "red", center_wavelength = 0.665),
    list(name = "B2", common_name = "green", center_wavelength = 0.560),
    list(name = "B3", common_name = "blue", center_wavelength = 0.490)
  ),
  "raster:bands" = list(
    list(data_type = "uint16", scale = 0.0001, offset = 0)
  )
)
```
