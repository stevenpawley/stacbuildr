# Add a self link to a STAC catalog

Adds a self link to a STAC Catalog, Collection, or Item. A self link
provides the absolute URL to the current resource and is strongly
recommended by the STAC specification.

## Usage

``` r
add_self_link(catalog, href)
```

## Arguments

- catalog:

  A STAC catalog, collection, or item object.

- href:

  (character, required) The absolute URL to the current resource.

## Value

The modified catalog object with the self link added.

## See also

- [`add_root_link()`](add_root_link.md) for adding a root link

- [`add_parent_link()`](add_parent_link.md) for adding a parent link

- [`add_link()`](add_link.md) for adding arbitrary links

## Examples

``` r
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

catalog <- add_self_link(catalog, "https://example.com/catalog.json")
```
