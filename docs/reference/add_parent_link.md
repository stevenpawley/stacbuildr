# Add a parent link to a STAC catalog

Adds a parent link to a STAC Catalog, Collection, or Item. A parent link
provides the URL to the parent catalog or collection in the STAC
hierarchy. Non-root catalogs should include a parent link.

## Usage

``` r
add_parent_link(catalog, href)
```

## Arguments

- catalog:

  A STAC catalog, collection, or item object.

- href:

  (character, required) The URL to the parent catalog or collection. Can
  be absolute or relative.

## Value

The modified catalog object with the parent link added.

## See also

- [`add_self_link()`](add_self_link.md) for adding a self link

- [`add_root_link()`](add_root_link.md) for adding a root link

- [`add_link()`](add_link.md) for adding arbitrary links

## Examples

``` r
catalog <- stac_catalog(
  id = "child-catalog",
  description = "A child catalog"
)

catalog <- add_parent_link(catalog, "../parent/catalog.json")
```
