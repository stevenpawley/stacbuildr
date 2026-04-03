# Recursively Write Catalog Structure

Internal function to recursively write a catalog and all its children
and items. Retrieves stored child and item objects and writes them to
the appropriate locations.

## Usage

``` r
write_catalog_recursive(
  catalog,
  path,
  catalog_type,
  base_url,
  overwrite,
  pretty,
  is_root = FALSE,
  parent_href = NULL
)
```
