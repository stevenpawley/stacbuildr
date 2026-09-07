# Extract Items from a STAC Catalog or Collection

Treats a Catalog or Collection as the container of Items that
[`length()`](https://rdrr.io/r/base/length.html) reports, so Items can
be pulled out by position or by `id`.

- `x[i]` returns a list of Items.

- `x[[i]]` returns a single Item.

Both accept a character index, matched against Item `id`s. Subsetting
reads the Items held in memory; it does not follow `item` links to disk,
so it returns nothing for a catalog read back with
[`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md).
Use
[`get_items()`](https://stevenpawley.github.io/stacbuildr/reference/get_items.md)
with `resolve = TRUE` for that.

## Usage

``` r
# S3 method for class 'stac_catalog'
x[i]

# S3 method for class 'stac_catalog'
x[[i]]
```

## Arguments

- x:

  A `stac_catalog` or `stac_collection` object.

- i:

  Item positions, or Item `id`s as a character vector.

## Value

`[` a list of `stac_item` objects; `[[` a single `stac_item`.

## Examples

``` r
collection <- stac_collection(
  id = "scenes",
  description = "Example",
  license = "CC-BY-4.0",
  extent = stac_extent(
    spatial_bbox = list(c(-115, 50, -113, 52)),
    temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
  )
)
collection <- add_item(collection, stac_item(
  id = "scene-1",
  geometry = list(type = "Point", coordinates = c(-114, 51)),
  bbox = c(-114, 51, -114, 51),
  datetime = "2024-06-01T00:00:00Z"
))

collection[["scene-1"]]@id
#> [1] "scene-1"
length(collection[1])
#> [1] 1
```
