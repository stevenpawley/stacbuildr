# Add a child catalog or collection

Adds a child STAC Catalog or Collection to a parent catalog by creating
a link with relation type `"child"`. The child resource can be another
catalog or a collection.

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

  (character, optional) The URL or path to the child resource. If `NULL`
  (default), automatically generates a path using the pattern
  `"./<child_id>/catalog.json"`.

- title:

  (character, optional) A title for the link. If `NULL`, uses the
  child's `title` field if available.

## Value

The modified parent catalog object with the child link added.

## See also

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding arbitrary links

- [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
  for adding STAC Items

- [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  for creating catalogs

- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating collections

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

# Add child with automatic href generation
parent <- add_child(parent, child)

# Add child with custom href and title
parent <- add_child(
  parent,
  child,
  href = "./children/custom-catalog.json",
  title = "Custom Child"
)
```
