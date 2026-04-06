# Count Items in a STAC Catalog or Collection

Counts the number of Item links in a Catalog or Collection.

## Usage

``` r
count_items(catalog)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

## Value

Integer count of item links.

## Examples

``` r
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)
n <- count_items(catalog)
cat("Catalog contains", n, "items\n")
#> Catalog contains 0 items
```
