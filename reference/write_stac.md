# Write a STAC Catalog Structure to Disk

Writes a complete STAC Catalog structure to the filesystem, including
all child catalogs, collections, and items. This function recursively
writes the entire catalog tree, creating the necessary directory
structure and JSON files. Children and items are automatically retrieved
from the catalog's stored objects.

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

  (character, optional) Type of catalog to create. These correspond to
  the three link layouts defined in [Use of
  links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links)
  in the STAC best-practices document, and to PySTAC's `CatalogType`
  values. One of:

  - `"self-contained"`: Every structural link is relative and no object
    carries a `self` link. Portable — the tree can be moved or archived.

  - `"relative"`: A self-contained catalog plus a single absolute `self`
    link on the root, identifying where the catalog is published.
    Requires `base_url`.

  - `"absolute"`: All links and asset hrefs use absolute URLs built from
    `base_url`, and every object carries a `self` link. Best for
    web-served catalogs. Requires `base_url`. Default is
    `"self-contained"`. Note that no catalog type copies or moves asset
    files — see Details.

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

### Catalog Types

The three types match the link layouts defined in [Use of
links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links)
in the STAC best-practices document, and map onto PySTAC's
`CatalogType$SELF_CONTAINED`, `CatalogType$RELATIVE_PUBLISHED` and
`CatalogType$ABSOLUTE_PUBLISHED`:

|  |  |  |
|----|----|----|
| `catalog_type` | STAC best practices | PySTAC |
| `"self-contained"` | [Self-contained Catalogs](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-catalogs) | `SELF_CONTAINED` |
| `"relative"` | [Relative Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#relative-published-catalog) | `RELATIVE_PUBLISHED` |
| `"absolute"` | [Absolute Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#absolute-published-catalog) | `ABSOLUTE_PUBLISHED` |

**Self-Contained Catalogs:** Links between catalog, collection and item
files are written as relative paths. Because a `self` link must be
absolute, self-contained catalogs carry no `self` link at all, and any
`self` link already present on an object is dropped. Asset hrefs that
are absolute local paths are rewritten relative to the directory holding
the item JSON; hrefs that are already relative, or that are URLs
(anything containing `://`), are left unchanged. This is the portable
layout: the written tree can be relocated without rewriting links.

**Relative Catalogs:** Identical to a self-contained catalog, except
that the root catalog or collection carries one absolute `self` link
built from `base_url`, recording where the catalog is published. No
other object gets a `self` link. Use this when the catalog is published
at a known location but should still be usable after being downloaded.

**Absolute Catalogs:** All links use absolute URLs and every object
carries a `self` link. Required when the catalog will be served from a
web server. Asset hrefs that are already URLs are left unchanged, and
relative asset hrefs are resolved against the item's URL. An asset href
that is an absolute local filesystem path has no URL equivalent, so it
is left unchanged and a warning is raised.

### Assets Are Not Copied

`write_stac()` writes JSON only. It never copies, moves, or rewrites
asset files, so an asset stored outside `path` stays there and is
referenced by a relative path that climbs out of the catalog directory,
such as `../../../data/dem.tif`.

This is narrower than a [self-contained catalog with
assets](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-with-assets),
where every referenced file lives inside the catalog directory so the
whole tree can be archived or relocated as a unit. A catalog written
here is [metadata
only](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-metadata-only)
unless you place the asset files under `path` yourself before calling
`write_stac()`; only then is the written catalog portable in that sense.

### Directory Structure

The function creates a directory structure based on the catalog
hierarchy:

    path/
      catalog.json                    # Root catalog
      collection1/
        collection.json               # Collection
        item1/
          item1.json                  # Items (each in own subdirectory)
        item2/
          item2.json
      collection2/
        collection.json
        subcatalog/
          catalog.json

### Automatic Object Retrieval

When you use
[`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
or
[`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md),
the child catalogs and items are automatically stored as attributes on
the parent catalog. The `write_stac()` function retrieves these stored
objects and writes them recursively.

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
# Create a catalog structure
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example STAC catalog"
)

collection <- stac_collection(
  id = "landsat-8",
  description = "Landsat 8 imagery",
  license = "CC0-1.0",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2013-04-11T00:00:00Z", NULL))
  )
)

item <- stac_item(
  id = "LC08_001",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-01-01T00:00:00Z"
)

# Add item to collection (automatically stored)
collection <- add_item(collection, item)

# Add collection to catalog (automatically stored)
catalog <- add_child(catalog, collection)

# Write entire structure - children and items are automatically written!
write_stac(catalog, "output/stac")

# Write as a relative catalog, recording where it is published
write_stac(
  catalog,
  "output/stac",
  catalog_type = "relative",
  base_url = "https://example.com/stac"
)

# Write as absolute catalog for web serving
write_stac(
  catalog,
  "output/stac",
  catalog_type = "absolute",
  base_url = "https://example.com/stac"
)

# Overwrite existing catalog
write_stac(catalog, "output/stac", overwrite = TRUE)
} # }
```
