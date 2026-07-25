# Generate a Thumbnail PNG from a Terra SpatRaster Object

Renders a `SpatRaster` object to a PNG image and returns a STAC asset
pointing to it. Multi-band rasters with 3 or more bands are rendered as
an RGB composite using the first three bands; single-band rasters are
rendered as greyscale.

## Usage

``` r
preview_from_terra(
  terra_obj,
  path,
  width = 256,
  height = 256,
  title = NULL,
  ...
)
```

## Arguments

- terra_obj:

  A `SpatRaster` object (from the `terra` package).

- path:

  (character, required) File path for the output PNG.

- width:

  (integer) Image width in pixels. Default is 256.

- height:

  (integer) Image height in pixels. Default is 256.

- title:

  (character, optional) Title for the returned asset.

- ...:

  Additional arguments passed to
  [`terra::plotRGB()`](https://rspatial.github.io/terra/reference/plotRGB.html)
  or
  [`terra::plot()`](https://rspatial.github.io/terra/reference/plot.html).

## Value

A STAC asset list with `href`, `type = "image/png"`, and
`roles = c("overview")`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)

r <- rast(system.file("ex/logo.tif", package = "terra"))
asset <- preview_from_terra(r, path = "thumbnail.png")

item <- item_from_terra(r, href = "image.tif",
                        datetime = "2023-01-01T00:00:00Z")
item <- add_asset(item, key = "thumbnail", asset = asset)
} # }
```
