# Add a child catalog or collection

Adds a child STAC Catalog or Collection to a parent. A `"child"` link is
added immediately, and the complete child is retained internally so that
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
can write it as part of the catalog tree.

## Usage

``` r
add_child(catalog, child, href = NULL, title = NULL)
```

## Arguments

- catalog:

  A STAC catalog or collection object to add the child to.

- child:

  A STAC catalog or collection object to add as a child.

- href:

  (character, optional) The URL or path to the child resource. If
  `NULL`, uses `"./<child_id>/catalog.json"` for a Catalog or
  `"./<child_id>/collection.json"` for a Collection.
  [`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
  regenerates this href for its output layout and `catalog_type`.

- title:

  (character, optional) A title for the link. If `NULL`, uses the
  child's `title` field if available.

## Value

The modified parent with the child link added and the complete child
retained internally for
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md).

## See also

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding arbitrary links

- [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
  for adding STAC Items

- See
  [`vignette("stac-catalog")`](https://stevenpawley.github.io/stacbuildr/articles/stac-catalog.md)
  for the recursive writing model

## Examples

``` r
parent <- stac_catalog(
  id = "parent-catalog",
  description = "Parent catalog"
)

child <- stac_catalog(
  id = "child-catalog",
  title = "Child Catalog",
  description = "A child catalog"
)

parent <- add_child(parent, child)
```
