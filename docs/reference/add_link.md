# Add a link to a STAC catalog

Adds a link object to a STAC Catalog, Collection, or Item. Links are
used to connect STAC resources and provide relationships between
catalogs, collections, and items.

## Usage

``` r
add_link(catalog, rel, href, ...)
```

## Arguments

- catalog:

  A STAC catalog, collection, or item object.

- rel:

  (character, required) The link relation type. Common values include
  `"self"`, `"root"`, `"parent"`, `"child"`, and `"item"`. See the STAC
  specification for a full list of relation types.

- href:

  (character, required) The URL or path to the linked resource. Can be
  absolute or relative.

- ...:

  Additional link properties passed to [`stac_link()`](stac_link.md),
  such as `type`, `title`, `method`, `headers`, `body`, or `merge`.

## Value

The modified catalog object with the new link added.

## See also

- [`add_self_link()`](add_self_link.md) for adding a self link

- [`add_root_link()`](add_root_link.md) for adding a root link

- [`add_parent_link()`](add_parent_link.md) for adding a parent link

- [`add_child()`](add_child.md) for adding a child catalog or collection

## Examples

``` r
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

# Add a self link
catalog <- add_link(
  catalog,
  rel = "self",
  href = "https://example.com/catalog.json",
  type = "application/json"
)

# Add a related link with a title
catalog <- add_link(
  catalog,
  rel = "related",
  href = "https://example.com/metadata.html",
  type = "text/html",
  title = "Additional metadata"
)
```
