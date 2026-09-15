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

  Additional fields for the asset. This allows for common metadata such
  as `"bands"` and extension-specific properties like `"proj:shape"`,
  etc.

## Value

An S7 asset. Access core fields with `asset@href` and arbitrary metadata
with `asset@extra_fields`.

## Details

`roles` is a character vector in memory and a JSON array when
serialized. Assets retain their S7 class when attached to Items or
Collections and when restored with
[`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md).
The assets dictionary remains a named list: use
`item@assets[["data"]]@href` to access an asset's URL. Use
`as.list(asset)` to obtain the JSON-ready representation.

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
asset@href
#> [1] "./data/LC08_B4.tif"
asset@roles
#> [1] "data"        "reflectance"

# Asset with extension properties
asset <- stac_asset(
  href = "./data/multispectral.tif",
  type = "image/tiff; application=geotiff; profile=cloud-optimized",
  roles = c("data"),
  bands = list(
    list(name = "B1", "eo:common_name" = "red",
         "eo:center_wavelength" = 0.665, data_type = "uint16"),
    list(name = "B2", "eo:common_name" = "green",
         "eo:center_wavelength" = 0.560, data_type = "uint16"),
    list(name = "B3", "eo:common_name" = "blue",
         "eo:center_wavelength" = 0.490, data_type = "uint16")
  )
)
```
