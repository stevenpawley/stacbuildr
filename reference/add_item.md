# Add an Item to a STAC Catalog or Collection

Adds one or more STAC Items to a Catalog or Collection. An `"item"` link
is added immediately, and the complete Item is retained internally so
that
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
can write it as part of the catalog tree.

## Usage

``` r
add_item(
  catalog,
  item,
  href = NULL,
  add_parent_links = FALSE,
  parent_href = NULL,
  root_href = NULL
)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object (created with
  [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  or
  [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)).

- item:

  A STAC Item object (created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)).
  Can also be a list of Items to add multiple items at once.

- href:

  (character, optional) Href for each Item link. If `NULL`, uses
  `"./{item@id}/{item@id}.json"`. Supply one href per Item.
  [`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
  regenerates these hrefs for its output layout and `catalog_type`.

- add_parent_links:

  (logical, optional) If `TRUE`, add `"parent"` and `"root"` links to
  each retained Item. Items added to a Collection also get a
  `"collection"` link and `collection` field. Default is `FALSE`.

- parent_href:

  (character, optional) The href for the parent catalog/collection. Only
  used if `add_parent_links = TRUE`. If not provided and a `"self"` link
  exists in the catalog, uses that; otherwise uses a placeholder.

- root_href:

  (character, optional) The href for the root catalog. Only used if
  `add_parent_links = TRUE`. If not provided, attempts to use the
  catalog's `"root"` link or defaults to `parent_href`.

## Value

The modified catalog/collection object with the Item link(s) added and
the complete Item object(s) retained internally for
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md).

## Details

A Catalog's `links` property contains links to Items, not the Items
themselves. Complete Items are retained in the internal `"stac_items"`
attribute, which is excluded from Catalog JSON. Use
[`get_items()`](https://stevenpawley.github.io/stacbuildr/reference/get_items.md)
to retrieve them. See
[`vignette("stac-catalog")`](https://stevenpawley.github.io/stacbuildr/articles/stac-catalog.md)
for the full writing model.

## See also

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding links to STAC objects

- [`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
  for adding child catalogs/collections

## Examples

``` r
catalog <- stac_catalog(id = "example", description = "Example catalog")
item <- stac_item(
  id = "item-1",
  geometry = NULL,
  bbox = NULL,
  datetime = "2020-01-01T00:00:00Z"
)

catalog <- add_item(catalog, item)
get_item_links(catalog)
#> [[1]]
#> [[1]]$rel
#> [1] "item"
#> 
#> [[1]]$href
#> [1] "./item-1/item-1.json"
#> 
#> [[1]]$type
#> [1] "application/geo+json"
#> 
#> 
get_items(catalog)
#> [[1]]
#> <STAC Item>
#>   id           : item-1
#>   stac_version : 1.1.0
#>   datetime     : 2020-01-01T00:00:00Z
#>   geometry     : NULL (non-spatial)
#>     assets     : 0
#>     links      : 0
#> 
```
