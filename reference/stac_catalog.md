# Create a STAC Catalog

Creates a STAC (SpatioTemporal Asset Catalog) Catalog object following
the STAC specification version 1.1.0. A Catalog is a top-level
organizational structure that groups related Collections and Items,
providing a hierarchical structure for organizing geospatial assets,
making them indexable and discoverable.

## Usage

``` r
stac_catalog(
  id,
  description,
  title = NULL,
  stac_version = "1.1.0",
  type = "Catalog",
  stac_extensions = NULL,
  conformsTo = NULL,
  ...
)
```

## Arguments

- id:

  (character, required) Identifier for the Catalog. Must be unique
  within the parent catalog if one exists. Should contain only
  alphanumeric characters, hyphens, and underscores. This field is
  required by the STAC specification.

- description:

  (character, required) Detailed multi-line description to fully explain
  the Catalog. This field should provide comprehensive information about
  the catalog's contents, purpose, and scope. This field is required by
  the STAC specification.

- title:

  (character, optional) A short descriptive one-line title for the
  Catalog. Recommended for human-readable identification.

- stac_version:

  (character, required) The STAC version the Catalog implements.
  Defaults to `"1.1.0"`. This field is required by the STAC
  specification.

- type:

  (character, optional) Must be set to `"Catalog"` for catalogs.
  Defaults to `"Catalog"`. For collections, this would be
  `"Collection"`. This field is required by the STAC specification.

- stac_extensions:

  (character vector, optional) A list of extension URLs that the Catalog
  implements. Extensions listed here must only contain extensions that
  extend the Catalog specification itself, not extensions for Items or
  Collections. Each extension should be a full URI to the extension's
  JSON schema. Default is `NULL` (no extensions).

- conformsTo:

  (character vector, optional) A list of URIs declaring conformance to
  STAC API specifications or other standards. Typically used when the
  catalog is served via an API. Introduced in STAC 1.1.0. Default is
  `NULL`.

- ...:

  Additional fields to include in the catalog. Any extra named arguments
  will be added to the catalog object. This allows for custom extensions
  or additional metadata beyond the core specification.

## Value

An S7 object of class `stac_catalog` containing the catalog metadata.
Convert to a plain list for JSON serialization with
[`as.list()`](https://rdrr.io/r/base/list.html), or write directly to
disk using
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md).

## Details

### Required Fields

The STAC Catalog specification requires the following fields:

- `type`: Must be "Catalog"

- `stac_version`: STAC specification version (currently "1.1.0")

- `id`: Unique identifier for the catalog

- `description`: Detailed description of the catalog

### Recommended Fields

- `title`: Short, human-readable title

### Link Relations

Catalogs use links to connect to other STAC resources. Common link
relation types include:

- `root`: URL to the root STAC Catalog or Collection

- `self`: Absolute URL to the current catalog file

- `parent`: URL to the parent STAC Catalog or Collection

- `child`: URL to a child STAC Catalog or Collection

- `item`: URL to a STAC Item

Use the helper functions
[`add_self_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_self_link.md),
[`add_root_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_root_link.md),
[`add_parent_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_parent_link.md),
[`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md),
and
[`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
to manage links after creating the catalog. A `self` link and a `root`
link are strongly recommended. Non-root Catalogs should include a
`parent` link.

### Extensions

STAC extensions provide additional fields and capabilities. When using
extensions at the catalog level, reference them in the `stac_extensions`
parameter with their full schema URI. Note that most extensions apply to
Items or Collections rather than Catalogs.

## References

STAC Catalog Specification:
<https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md>

## See also

- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating STAC Collections

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding links to catalogs

- [`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
  for adding child catalogs or collections

- [`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
  for writing catalogs to the filesystem

## Examples

``` r
# Create a basic catalog
catalog <- stac_catalog(
  id = "my-catalog",
  description = "A catalog of satellite imagery for environmental monitoring"
)

# Create a catalog with all optional fields
catalog <- stac_catalog(
  id = "north-america-imagery",
  title = "North America Satellite Imagery",
  description = paste(
    "A comprehensive catalog of satellite imagery covering North America",
    "from various sensors including Landsat, Sentinel, and commercial",
    "providers. Data spans from 2013 to present."
  ),
  stac_version = "1.1.0"
)

# Add links to the catalog
catalog <- catalog |>
  add_self_link("https://example.com/catalog.json") |>
  add_root_link("https://example.com/catalog.json")

# Add child catalogs
landsat_catalog <- stac_catalog(
  id = "landsat",
  description = "Landsat satellite imagery"
)

catalog <- add_child(
  catalog,
  landsat_catalog,
  href = "./landsat/catalog.json",
  title = "Landsat Imagery"
)

# Create a catalog with a custom extension
catalog_with_version <- stac_catalog(
  id = "versioned-catalog",
  description = "A catalog with version tracking",
  stac_extensions = c(
    "https://stac-extensions.github.io/version/v1.2.0/schema.json"
  ),
  # Custom fields from the version extension
  version = "1.0.0",
  deprecated = FALSE
)

# Convert to JSON
catalog_json <- jsonlite::toJSON(as.list(catalog), auto_unbox = TRUE, pretty = TRUE)
cat(catalog_json)
#> {
#>   "type": "Catalog",
#>   "stac_version": "1.1.0",
#>   "id": "north-america-imagery",
#>   "description": "A comprehensive catalog of satellite imagery covering North America from various sensors including Landsat, Sentinel, and commercial providers. Data spans from 2013 to present.",
#>   "title": "North America Satellite Imagery",
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "https://example.com/catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "https://example.com/catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "child",
#>       "href": "./landsat/catalog.json",
#>       "type": "application/json",
#>       "title": "Landsat Imagery"
#>     }
#>   ]
#> }
```
