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
n <- count_items(catalog)
#> Error: object 'catalog' not found
cat("Catalog contains", n, "items\n")
#> Error: object 'n' not found
```
