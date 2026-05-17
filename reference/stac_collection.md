# Create a STAC Collection

Creates a STAC (SpatioTemporal Asset Catalog) Collection object
following the STAC specification version 1.1.0. A Collection extends the
Catalog specification with additional metadata that helps enable
discovery, including spatial and temporal extents, license information,
and summaries of the data.

## Usage

``` r
stac_collection(
  id,
  description,
  license,
  extent,
  title = NULL,
  stac_version = "1.1.0",
  type = "Collection",
  stac_extensions = NULL,
  keywords = NULL,
  providers = NULL,
  links = list(),
  summaries = NULL,
  assets = NULL,
  conformsTo = NULL,
  ...
)
```

## Arguments

- id:

  (character, required) Identifier for the Collection. Must be unique
  across all collections in the root catalog. Should contain only
  alphanumeric characters, hyphens, and underscores.

- description:

  (character, required) Detailed multi-line description to fully explain
  the Collection. CommonMark 0.29 syntax may be used for rich text
  representation. This should provide comprehensive information about
  the collection's contents, purpose, and scope.

- license:

  (character, required) Collection's license(s) as a [SPDX License
  identifier](https://spdx.org/licenses/), `"various"`, or `"other"`. If
  the collection includes data with multiple different licenses, use
  `"various"` and add a link for each license. In STAC 1.1.0,
  `"proprietary"` is deprecated in favor of `"other"`. Examples:
  `"CC-BY-4.0"`, `"MIT"`, `"other"`.

- extent:

  (list, required) Spatial and temporal extents that describe the bounds
  of all Items contained within this Collection. Must be a named list
  with two elements:

  - `spatial`: A list with element `bbox` - a list of one or more
    bounding boxes. Each bbox is a numeric vector of 4 or 6 numbers:
    `c(west, south, east, north)` for 2D or
    `c(west, south, min_elev, east, north, max_elev)` for 3D. The first
    bbox describes the overall spatial extent.

  - `temporal`: A list with element `interval` - a list of one or more
    time intervals. Each interval is a character vector of length 2 with
    ISO 8601 datetime strings: `list("start", "end")`. Use `NULL` for
    open-ended intervals (e.g., `list("2020-01-01T00:00:00Z", NULL)` for
    ongoing data). Note: use
    [`list()`](https://rdrr.io/r/base/list.html) not
    [`c()`](https://rdrr.io/r/base/c.html) —
    [`c()`](https://rdrr.io/r/base/c.html) drops `NULL`, which would
    produce an invalid interval.

  Use the helper function
  [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md)
  to create this structure easily.

- title:

  (character, optional) A short descriptive one-line title for the
  Collection. Recommended for human-readable identification.

- stac_version:

  (character, optional) The STAC version the Collection implements.
  Defaults to `"1.1.0"`.

- type:

  (character, optional) Must be set to `"Collection"`. Defaults to
  `"Collection"`.

- stac_extensions:

  (character vector, optional) A list of extension identifiers (URIs)
  that the Collection implements. Common extensions include Item Assets,
  Version, Scientific Citation, and more. Each should be a full URI to
  the extension's JSON schema. Default is `NULL`.

- keywords:

  (character vector, optional) List of keywords describing the
  Collection. Helps with discovery and categorization.

- providers:

  (list, optional) A list of Provider objects. Each provider should be a
  list with fields: `name` (required), `description`, `roles` (e.g.,
  "producer", "licensor", "processor", "host"), and `url`. Use the
  helper function
  [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md)
  to create providers.

- links:

  (list, optional) An array of Link objects. Common link relations for
  Collections include `"self"`, `"root"`, `"parent"`, `"item"`,
  `"child"`, and `"license"`. Note that while Catalogs require at least
  one item or child link, this is not required for Collections (but
  recommended). Defaults to an empty list.

- summaries:

  (list, optional) A map of property summaries that describe the range
  of values for properties found in the Items of this Collection.
  Strongly recommended. Each property can be summarized as an array of
  unique values, a range (with `minimum` and `maximum`), or a JSON
  Schema. Common properties to summarize include `"datetime"`,
  `"platform"`, `"instruments"`, `"gsd"`, `"eo:bands"`, etc. Use
  [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md)
  helper to create this.

- assets:

  (list, optional) Dictionary of asset objects that can be downloaded at
  the Collection level (not Item-specific assets). This is for assets
  that apply to the entire collection, such as preview images or
  documentation. For describing what assets are available in Items, use
  the Item Assets extension.

- conformsTo:

  (character vector, optional) A list of URIs declaring conformance to
  STAC API specifications or other standards. Introduced in STAC 1.1.0.

- ...:

  Additional fields to include in the collection. This allows for custom
  extensions or additional metadata beyond the core specification.

## Value

An S7 object of class `stac_collection` (extending `stac_catalog`)
containing the collection metadata. Convert to a plain list for JSON
serialization with [`as.list()`](https://rdrr.io/r/base/list.html), or
write directly to disk using
[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md).

## Details

### Required Fields

The STAC Collection specification requires these fields:

- `type`: Must be "Collection"

- `stac_version`: STAC specification version (currently "1.1.0")

- `id`: Unique identifier for the collection

- `description`: Detailed description of the collection

- `license`: License identifier

- `extent`: Spatial and temporal extents (both required)

- `links`: Array of link objects (can be empty)

### Recommended Fields

- `title`: Short, human-readable title

- `keywords`: Keywords for discovery

- `providers`: Information about data providers

- `summaries`: Summaries of Item properties

### Extent Structure

The extent object must contain both `spatial` and `temporal` extents:

    extent = list(
      spatial = list(
        bbox = list(
          c(-180, -90, 180, 90)  # Overall spatial extent
        )
      ),
      temporal = list(
        interval = list(
          c("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z")
        )
      )
    )

### License Values in STAC 1.1.0

The license field was updated in STAC 1.1.0:

- Use SPDX identifiers when possible (e.g., "CC-BY-4.0", "MIT")

- Use `"other"` for custom/proprietary licenses (replaces deprecated
  "proprietary")

- Use `"various"` when the collection contains data with multiple
  licenses

- When using `"other"` or `"various"`, add license link(s) in the links
  array

### Summaries

Summaries help users understand the range of values in the collection
without inspecting all Items. Three formats are supported:

- Array of unique values: `list(platform = c("landsat-8", "landsat-9"))`

- Range with min/max: `list(gsd = list(minimum = 15, maximum = 30))`

- JSON Schema: For complex validation rules

## References

STAC Collection Specification:
<https://github.com/radiantearth/stac-spec/blob/master/collection-spec/collection-spec.md>

## See also

- [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  for creating STAC Catalogs

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

- [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md)
  for creating extent objects

- [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md)
  for creating provider objects

- [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md)
  for creating summaries

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding links to collections

## Examples

``` r
# Basic collection with minimal required fields
collection <- stac_collection(
  id = "landsat-8-c2-l2",
  description = "Landsat 8 Collection 2 Level-2 Surface Reflectance",
  license = "CC0-1.0",
  extent = list(
    spatial = list(bbox = list(c(-180, -90, 180, 90))),
    temporal = list(interval = list(list("2013-04-11T00:00:00Z", NULL)))
  )
)

# Collection with all recommended fields
collection <- stac_collection(
  id = "sentinel-2-l2a",
  title = "Sentinel-2 Level-2A",
  description = paste(
    "Sentinel-2 Level-2A provides Bottom-Of-Atmosphere (BOA) reflectance",
    "images derived from the associated Level-1C products."
  ),
  license = "proprietary",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2015-06-27T00:00:00Z", NULL))
  ),
  keywords = c("sentinel", "esa", "msi", "copernicus", "earth observation"),
  providers = list(
    stac_provider(
      name = "ESA",
      roles = c("producer", "licensor"),
      url = "https://earth.esa.int/web/guest/home"
    )
  ),
  summaries = list(
    platform = c("sentinel-2a", "sentinel-2b"),
    instruments = c("msi"),
    gsd = c(10, 20, 60),
    `eo:bands` = list(
      list(name = "B01", common_name = "coastal", center_wavelength = 0.443),
      list(name = "B02", common_name = "blue", center_wavelength = 0.490),
      list(name = "B03", common_name = "green", center_wavelength = 0.560)
    )
  )
)

# Add links
collection <- collection |>
  add_self_link("https://example.com/collections/sentinel-2-l2a.json") |>
  add_root_link("https://example.com/catalog.json") |>
  add_link(
    rel = "license",
    href = "https://sentinel.esa.int/documents/247904/690755/Sentinel_Data_Legal_Notice",
    type = "text/html",
    title = "Sentinel Data Terms and Conditions"
  )

# Collection with multiple licenses
multi_license_collection <- stac_collection(
  id = "mixed-sources",
  description = "Collection with data from multiple sources with different licenses",
  license = "various",
  extent = stac_extent(
    spatial_bbox = list(c(-120, 30, -110, 40)),
    temporal_interval = list(c("2020-01-01T00:00:00Z", "2023-12-31T23:59:59Z"))
  )
) |>
  add_link("license", "https://creativecommons.org/licenses/by/4.0/",
    title = "CC-BY-4.0 for Landsat data"
  ) |>
  add_link("license", "https://example.com/custom-license.txt",
    title = "Custom license for commercial data"
  )

# Convert to JSON
collection_json <- jsonlite::toJSON(as.list(collection), auto_unbox = TRUE, pretty = TRUE)
cat(collection_json)
#> {
#>   "type": "Collection",
#>   "stac_version": "1.1.0",
#>   "id": "sentinel-2-l2a",
#>   "description": "Sentinel-2 Level-2A provides Bottom-Of-Atmosphere (BOA) reflectance images derived from the associated Level-1C products.",
#>   "license": "proprietary",
#>   "extent": {
#>     "spatial": {
#>       "bbox": [
#>         [-180, -90, 180, 90]
#>       ]
#>     },
#>     "temporal": {
#>       "interval": [
#>         [
#>           "2015-06-27T00:00:00Z",
#>           {}
#>         ]
#>       ]
#>     }
#>   },
#>   "title": "Sentinel-2 Level-2A",
#>   "keywords": ["sentinel", "esa", "msi", "copernicus", "earth observation"],
#>   "providers": [
#>     {
#>       "name": "ESA",
#>       "roles": ["producer", "licensor"],
#>       "url": "https://earth.esa.int/web/guest/home"
#>     }
#>   ],
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "https://example.com/collections/sentinel-2-l2a.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "https://example.com/catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "license",
#>       "href": "https://sentinel.esa.int/documents/247904/690755/Sentinel_Data_Legal_Notice",
#>       "type": "text/html",
#>       "title": "Sentinel Data Terms and Conditions"
#>     }
#>   ],
#>   "summaries": {
#>     "platform": ["sentinel-2a", "sentinel-2b"],
#>     "instruments": "msi",
#>     "gsd": [10, 20, 60],
#>     "eo:bands": [
#>       {
#>         "name": "B01",
#>         "common_name": "coastal",
#>         "center_wavelength": 0.443
#>       },
#>       {
#>         "name": "B02",
#>         "common_name": "blue",
#>         "center_wavelength": 0.49
#>       },
#>       {
#>         "name": "B03",
#>         "common_name": "green",
#>         "center_wavelength": 0.56
#>       }
#>     ]
#>   },
#>   "links.1": []
#> }
```
