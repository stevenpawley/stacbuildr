# Get Stored Children from Catalog

Retrieves the stored child catalogs/collections from a catalog object.

## Usage

``` r
get_children(catalog)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

## Value

A named list of child catalogs/collections, or NULL if none exist.

## Examples

``` r
if (FALSE) { # \dontrun{
children <- get_children(catalog)
names(children) # Get IDs of child catalogs
} # }
```
