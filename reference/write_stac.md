# Write a STAC Catalog Structure to Disk

Writes a Catalog and its attached child Catalogs, Collections, and Items
as a directory tree of STAC JSON files.

## Usage

``` r
write_stac(
  catalog,
  path,
  catalog_type = c("self-contained", "relative", "absolute"),
  overwrite = FALSE,
  pretty = TRUE,
  base_url = NULL
)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object created with
  [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  or
  [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md).

- path:

  (character, required) Root directory path where the catalog should be
  written. Will be created if it doesn't exist.

- catalog_type:

  (character, optional) Link layout: `"self-contained"` uses relative
  links without `self` links; `"relative"` adds an absolute `self` link
  to the root; and `"absolute"` uses absolute URLs throughout. The
  latter two require `base_url`. Default is `"self-contained"`.

- overwrite:

  (logical, optional) If `TRUE`, overwrites existing files. If `FALSE`,
  throws an error if files already exist. Default is `FALSE`.

- pretty:

  (logical, optional) If `TRUE`, writes formatted JSON with indentation.
  If `FALSE`, writes compact JSON. Default is `TRUE`.

- base_url:

  (character, optional) Base URL identifying where the catalog is
  published, for example `"https://example.com/stac"`. Required when
  `catalog_type` is `"relative"` or `"absolute"`; ignored otherwise.

## Value

Invisibly returns the path where the catalog was written.

## Details

### Attached objects and links

A Catalog's `links` property contains links to child catalogs and Items,
not the objects themselves. Complete objects attached by
[`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
and
[`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
are retained internally and written recursively. Structural links are
regenerated for `catalog_type` and the output layout, so custom child or
Item hrefs already in the catalog are not preserved.

`write_stac()` writes JSON only; it does not copy or move asset files.
See
[`vignette("stac-catalog")`](https://stevenpawley.github.io/stacbuildr/articles/stac-catalog.md)
for the complete writing model, directory layout, asset handling, and
catalog-type comparison.

## References

STAC best practices, [Use of
links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links),
which defines the self-contained, relative published and absolute
published layouts. See <https://stacspec.org/> for the specification as
a whole.

## See also

- [`write_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/write_catalog.md)
  for writing a single catalog/collection file

- [`write_item()`](https://stevenpawley.github.io/stacbuildr/reference/write_item.md)
  for writing a single item file

- [`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)
  for reading STAC catalogs from disk

- [`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
  for adding child catalogs with automatic storage

- [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
  for adding items with automatic storage

## Examples

``` r
if (FALSE) { # \dontrun{
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example STAC catalog"
)

write_stac(catalog, "output/stac")

write_stac(
  catalog,
  "output/absolute-stac",
  catalog_type = "absolute",
  base_url = "https://example.com/stac"
)
} # }
```
