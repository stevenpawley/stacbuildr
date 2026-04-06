# Create Collection Extent from Multiple Items

Calculates the spatial and temporal extent for a collection from a list
of items.

## Usage

``` r
extent_from_items(items)
```

## Arguments

- items:

  A list of STAC Item objects.

## Value

A list with spatial and temporal extent suitable for
[`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md).

## Examples

``` r
if (FALSE) { # \dontrun{
items <- list(item1, item2, item3)
extent <- extent_from_items(items)

collection <- stac_collection(
  id = "my-collection",
  description = "Collection of items",
  license = "CC0-1.0",
  extent = extent
)
} # }
```
