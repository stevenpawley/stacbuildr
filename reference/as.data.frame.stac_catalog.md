# Coerce a STAC Catalog, Collection or Item to a Data Frame

Returns one row per Item, with `id` and `collection` followed by a
column for every field in the Items' `properties`. Items need not share
the same properties: a field missing from an Item is `NA` in its row.

A property whose values are not all length-1 atomics becomes a list
column, since STAC properties routinely hold vectors (`proj:transform`)
and objects (`bands`). Use
[st_as_sf()](https://r-spatial.github.io/sf/reference/st_as_sf.html)
instead to get the same table with the Item footprints attached as a
geometry column.

## Usage

``` r
# S3 method for class 'stac_catalog'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  resolve = FALSE,
  base_path = "."
)

# S3 method for class 'stac_item'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A `stac_catalog`, `stac_collection` or `stac_item` object.

- row.names, optional:

  Ignored, for compatibility with the generic.

- ...:

  Ignored.

- resolve:

  (logical) When the Items are not held in memory — as after
  [`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)
  — read each one from its `item` link. Default `FALSE`.

- base_path:

  (character) Directory that relative item hrefs are resolved against
  when `resolve = TRUE`. Default `"."`.

## Value

A data frame with one row per Item. A catalog with no Items gives a
zero-row data frame; if it has `item` links but no Items in memory, a
warning points at `resolve = TRUE`.

## Examples

``` r
item <- stac_item(
  id = "scene-1",
  geometry = list(type = "Point", coordinates = c(-114, 51)),
  bbox = c(-114, 51, -114, 51),
  datetime = "2024-06-01T00:00:00Z",
  properties = list(`eo:cloud_cover` = 7.5)
)

as.data.frame(item)
#>        id collection             datetime eo:cloud_cover
#> 1 scene-1       <NA> 2024-06-01T00:00:00Z            7.5

collection <- stac_collection(
  id = "scenes",
  description = "Example",
  license = "CC-BY-4.0",
  extent = stac_extent(
    spatial_bbox = list(c(-115, 50, -113, 52)),
    temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
  )
)
collection <- add_item(collection, item)

df <- as.data.frame(collection)
df[df$`eo:cloud_cover` < 20, c("id", "datetime")]
#>        id             datetime
#> 1 scene-1 2024-06-01T00:00:00Z
```
