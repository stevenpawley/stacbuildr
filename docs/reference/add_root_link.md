# Add a root link to a STAC catalog

Adds a root link to a STAC Catalog, Collection, or Item. A root link
provides the URL to the root catalog of the STAC hierarchy and is
strongly recommended by the STAC specification.

## Usage

``` r
add_root_link(catalog, href)
```

## Arguments

- catalog:

  A STAC catalog, collection, or item object.

- href:

  (character, required) The URL to the root catalog. Can be absolute or
  relative.

## Value

The modified catalog object with the root link added.

## See also

- [`add_self_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_self_link.md)
  for adding a self link

- [`add_parent_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_parent_link.md)
  for adding a parent link

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding arbitrary links

## Examples

``` r
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

catalog <- add_root_link(catalog, "https://example.com/catalog.json")
```
