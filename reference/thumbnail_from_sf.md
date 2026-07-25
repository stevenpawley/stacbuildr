# Generate a Thumbnail PNG from an sf Object

Renders the geometry of an `sf` object to a PNG image and returns a STAC
asset pointing to it.

## Usage

``` r
thumbnail_from_sf(sf_obj, path, width = 256, height = 256, title = NULL, ...)
```

## Arguments

- sf_obj:

  An `sf` object.

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
library(sf)

nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
asset <- thumbnail_from_sf(nc, path = "thumbnail.png")

item <- item_from_sf(nc, id = "nc", datetime = "2023-01-01T00:00:00Z")
item <- add_asset(item, key = "thumbnail", asset = asset)
} # }
```
