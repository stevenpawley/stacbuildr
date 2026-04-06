# Create a STAC Item from an sf Object

Creates a STAC Item from an sf (simple features) object.

## Usage

``` r
item_from_sf(sf_obj, id, datetime, properties = list(), href = NULL, ...)
```

## Arguments

- sf_obj:

  An sf object (point, line, polygon, etc.).

- id:

  (character, required) Item ID.

- datetime:

  (character, required) ISO 8601 datetime string.

- properties:

  (list, optional) Additional properties for the item.

- href:

  (character, optional) If provided, creates an asset pointing to the
  original file.

- ...:

  Additional arguments passed to
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

## Value

A STAC Item object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)

# Read a shapefile
polygon <- st_read("boundary.shp")

# Create STAC item
item <- item_from_sf(
  polygon,
  id = "study-area",
  datetime = "2023-01-01T00:00:00Z",
  properties = list(title = "Study Area Boundary")
)
} # }
```
