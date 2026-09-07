# Create STAC Items from a LAScatalog

Creates one STAC Item per file in a `lidR` `LAScatalog`, which is the
usual way a tiled point cloud collection is described. Only file headers
are read, so a catalogue of thousands of tiles can be catalogued
quickly.

## Usage

``` r
items_from_lascatalog(ctg, datetime_from_filename = NULL, ...)
```

## Arguments

- ctg:

  A `LAScatalog` object, a directory containing LAS/LAZ files, or a
  character vector of file paths.

- datetime_from_filename:

  Function to extract a datetime from a filename. Should return an ISO
  8601 string. If NULL, the LAS header creation date is used where
  available.

- ...:

  Additional arguments passed to
  [`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md).

## Value

A list of STAC Item objects.

## Details

Files that cannot be read produce a warning and are skipped, so one
damaged tile does not abandon the whole catalogue. Pass the result to
[`extent_from_items()`](https://stevenpawley.github.io/stacbuildr/reference/extent_from_items.md)
to build the matching Collection extent.

## See also

[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md),
[`extent_from_items()`](https://stevenpawley.github.io/stacbuildr/reference/extent_from_items.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(lidR)

ctg <- readLAScatalog("path/to/tiles")
items <- items_from_lascatalog(ctg)

collection <- stac_collection(
  id = "als-tiles",
  description = "Airborne laser scanning tiles",
  license = "CC-BY-4.0",
  extent = extent_from_items(items)
)
} # }
```
