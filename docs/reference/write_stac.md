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

  (character, optional) Type of catalog to create. One of:

  - `"self-contained"`: All links use relative paths within the catalog
    structure. Best for portability and publishing.

  - `"relative"`: Links use relative paths but may reference external
    resources.

  - `"absolute"`: All links use absolute URLs. Best for web-served
    catalogs. Default is `"self-contained"`.

- overwrite:

  (logical, optional) If `TRUE`, overwrites existing files. If `FALSE`,
  throws an error if files already exist. Default is `FALSE`.

- pretty:

  (logical, optional) If `TRUE`, writes formatted JSON with indentation.
  If `FALSE`, writes compact JSON. Default is `TRUE`.

- base_url:

  (character, optional) Base URL for absolute links when
  `catalog_type = "absolute"`. For example,
  `"https://example.com/stac"`. Required when using absolute catalog
  type.

## Value

Invisibly returns the path where the catalog was written.

## Details

### Catalog Types

**Self-Contained Catalogs:** All links use relative paths and all
referenced resources are within the catalog directory structure. This is
the most portable option and recommended for sharing or archiving
catalogs.

**Relative Catalogs:** Links use relative paths but may reference
resources outside the catalog tree. Useful when integrating with
existing file structures.

**Absolute Catalogs:** All links use absolute URLs. Required when the
catalog will be served from a web server. Requires `base_url` to be
specified.

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
