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
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

# Get as list
item_links <- get_item_links(catalog)

# Get as data.frame
item_df <- get_item_links(catalog, as_dataframe = TRUE)
print(item_df)
#> data frame with 0 columns and 0 rows
```
