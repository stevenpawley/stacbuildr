# Number of Items in a STAC Catalog or Collection

Returns the number of Items linked from a Catalog or Collection, so that
a catalog answers [`length()`](https://rdrr.io/r/base/length.html) the
way a container of Items should. This is the same count as
[`count_items()`](https://stevenpawley.github.io/stacbuildr/reference/count_items.md),
which counts `item` links rather than the Item objects held in memory,
so it is correct for a catalog read back from disk as well as one built
in the session.

Child catalogs are not counted; use `length(get_children(x))` for those.

## Usage

``` r
# S3 method for class 'stac_catalog'
length(x)
```

## Arguments

- x:

  A `stac_catalog` or `stac_collection` object.

## Value

An integer count of linked Items.

## Examples

``` r
catalog <- stac_catalog(id = "my-catalog", description = "Example")
length(catalog)
#> [1] 0
```
