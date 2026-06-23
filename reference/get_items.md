# Get Stored Items from Catalog or Collection

Retrieves the stored items from a catalog or collection object. When
items are not in memory (e.g. after
[`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)),
set `resolve = TRUE` to follow the `item` links and load them from disk.

## Usage

``` r
get_items(catalog, resolve = FALSE, base_path = ".")
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

- resolve:

  (logical) If `TRUE` and no items are stored in memory, follow the
  `item` links and read each one from disk. Relative hrefs are resolved
  against `base_path`. Default is `FALSE`.

- base_path:

  (character) Directory used to resolve relative hrefs when
  `resolve = TRUE`. Defaults to the working directory.

## Value

A list of items, or NULL if none exist.

## Examples

``` r
if (FALSE) { # \dontrun{
# In-memory items
items <- get_items(collection)

# After read_stac(), follow links from disk
collection <- read_stac("path/to/collection.json")
items <- get_items(collection, resolve = TRUE, base_path = "path/to")
length(items)
} # }
```
