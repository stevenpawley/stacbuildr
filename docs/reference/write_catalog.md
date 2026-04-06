# Write a Single STAC Catalog or Collection File

Writes a single STAC Catalog or Collection to a JSON file. Unlike
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md),
this does not recursively write children or items, and does not include
the stored child/item objects in the output (only the links).

## Usage

``` r
write_catalog(catalog, file, overwrite = FALSE, pretty = TRUE)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

- file:

  (character, required) Path to the output JSON file.

- overwrite:

  (logical, optional) If `TRUE`, overwrites existing file. Default is
  `FALSE`.

- pretty:

  (logical, optional) If `TRUE`, writes formatted JSON. Default is
  `TRUE`.

## Value

Invisibly returns the file path.

## Examples

``` r
if (FALSE) { # \dontrun{
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

write_catalog(catalog, "catalog.json")
} # }
```
