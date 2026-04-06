# Get Stored Items from Catalog or Collection

Retrieves the stored items from a catalog or collection object.

## Usage

``` r
get_items(catalog)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

## Value

A list of items, or NULL if none exist.

## Examples

``` r
if (FALSE) { # \dontrun{
items <- get_items(collection)
length(items) # Number of items
} # }
```
