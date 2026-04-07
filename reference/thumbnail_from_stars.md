# Generate a Thumbnail PNG from a Stars Raster Object

Renders a `stars` raster object to a PNG image and returns a STAC asset
pointing to it. Multi-band rasters with 3 or more bands are rendered as
an RGB composite using the first three bands; single-band rasters are
rendered as greyscale.

## Usage

``` r
thumbnail_from_stars(
  stars_obj,
  path,
  width = 256,
  height = 256,
  title = NULL,
  ...
)
```

## Arguments

- stars_obj:

  A `stars` object.

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
  [`plot()`](https://rspatial.github.io/terra/reference/plot.html).

## Value

A STAC asset list with `href`, `type = "image/png"`, and
`roles = c("thumbnail")`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(stars)

r <- read_stars(system.file("tif/L7_ETMs.tif", package = "stars"))
asset <- thumbnail_from_stars(r, path = "thumbnail.png")

item <- item_from_stars(r, href = "image.tif", datetime = "2023-01-01T00:00:00Z")
item <- add_asset(item, key = "thumbnail", asset = asset)
} # }
```
