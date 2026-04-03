# Get All Item Links from a STAC Catalog or Collection

Retrieves all Item links from a Catalog or Collection.

## Usage

``` r
get_item_links(catalog, as_dataframe = FALSE)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

- as_dataframe:

  (logical, optional) If `TRUE`, returns results as a data.frame.
  Default is `FALSE` (returns list).

## Value

A list of link objects (or data.frame if `as_dataframe = TRUE`)
containing all item links.

## Examples

``` r
# Get as list
item_links <- get_item_links(catalog)
#> Error: object 'catalog' not found

# Get as data.frame
item_df <- get_item_links(catalog, as_dataframe = TRUE)
#> Error: object 'catalog' not found
print(item_df)
#> Error: object 'item_df' not found
```
