# Get Stored Children from Catalog

Retrieves the stored child catalogs/collections from a catalog object.
When children are not in memory (e.g. after
[`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)),
set `resolve = TRUE` to follow the `child` links and load them from
disk.

## Usage

``` r
get_children(catalog, resolve = FALSE, base_path = ".")
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

- resolve:

  (logical) If `TRUE` and no children are stored in memory, follow the
  `child` links and read each one from disk. Relative hrefs are resolved
  against `base_path`. Default is `FALSE`.

- base_path:

  (character) Directory used to resolve relative hrefs when
  `resolve = TRUE`. Defaults to the working directory.

## Value

A named list of child catalogs/collections, or NULL if none exist.

## Examples

``` r
if (FALSE) { # \dontrun{
# In-memory children
children <- get_children(catalog)

# After read_stac(), follow links from disk
catalog <- read_stac("path/to/catalog.json")
children <- get_children(catalog, resolve = TRUE, base_path = "path/to")
names(children)
} # }
```
