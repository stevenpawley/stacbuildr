# stacbuildr

**stacbuildr** is an *experimental* R package for creating [STAC
(SpatioTemporal Asset Catalog)](https://stacspec.org/) metadata. STAC is
an open standard for describing geospatial data in a way that makes it
indexable, searchable, and interoperable. The package implements STAC
specification version 1.1.0 using
[S7](https://rconsortium.github.io/S7/) classes and outputs valid STAC
JSON.

*Note* this package is in active development: breaking changes are
expected and there is no guarantee of compliance with STACspec.

## Installation

``` r

# Install from GitHub
# install.packages("remotes")
remotes::install_github("stevenpawley/stacbuildr")
```

## Overview

A STAC catalog is a hierarchy of three object types:

| Object | Description |
|----|----|
| **Catalog** | Top-level container that groups related Collections and Items |
| **Collection** | A Catalog extended with spatial/temporal extents, license, and summaries |
| **Item** | A GeoJSON Feature representing an individual asset (e.g. a single satellite scene) |

Each object contains **links** (JSON pointers connecting the hierarchy)
and Items contain **assets** (references to the actual data files).

## Core functions

### Creating objects

``` r

library(stacbuildr)

# Root catalog
catalog <- stac_catalog(
  id = "my-catalog",
  title = "My Satellite Imagery Catalog",
  description = "A catalog of satellite imagery for environmental monitoring"
)

# Collection (extends catalog with extent, license, etc.)
collection <- stac_collection(
  id = "sentinel-2-l2a",
  title = "Sentinel-2 Level-2A",
  description = "Bottom-of-atmosphere reflectance imagery from Sentinel-2",
  license = "proprietary",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2015-06-27T00:00:00Z", NULL))  # NULL = ongoing
  ),
  keywords  = c("sentinel", "esa", "optical"),
  providers = list(
    stac_provider(name = "ESA", roles = c("producer", "licensor"),
                  url = "https://earth.esa.int")
  )
)

# Item (a single scene / data granule)
item <- stac_item(
  id = "S2A_MSIL2A_20230615",
  geometry = list(type = "Polygon", coordinates = list(list(
    c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
    c(-105.5, 40.5), c(-105.5, 39.5)
  ))),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T10:30:00Z",
  properties = list(platform = "sentinel-2a", instruments = c("msi"), gsd = 10)
)
```

### Managing links

``` r

# Add standard navigation links
catalog <- catalog |>
  add_self_link("https://example.com/catalog.json") |>
  add_root_link("https://example.com/catalog.json")

# Add a child collection to the catalog
catalog <- catalog |> 
  add_child(collection)

# Add an item to a collection (with bidirectional links)
collection <- collection |> 
  add_item(
    item,
    add_parent_links = TRUE,
    parent_href = "./collection.json",
    root_href = "../catalog.json"
  )

# Add arbitrary links
collection <- collection |> 
  add_link(
    rel = "license",
    href = "https://sentinel.esa.int/legal-notice.html",
    type = "text/html"
  )
```

### Adding assets to items

``` r

item <- item |>
  add_asset(
    key = "visual",
    href = "https://example.com/S2A_20230615_visual.tif",
    title = "True Color Image",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("visual", "data")
  ) |>
  add_asset(
    key = "thumbnail",
    href = "https://example.com/S2A_20230615_thumb.png",
    type = "image/png",
    roles = c("thumbnail")
  )
```

### STAC extensions

#### Electro-Optical (EO) extension

``` r
item <- item |>
  add_eo_extension(
    bands = list(
      eo_band(name = "B4", common_name = "red",   center_wavelength = 0.665),
      eo_band(name = "B3", common_name = "green", center_wavelength = 0.560),
      eo_band(name = "B2", common_name = "blue",  center_wavelength = 0.490)
    ),
    cloud_cover = 5.2,
    asset_key = "visual". # attach bands to a specific asset
  )

# Pre-built band definitions for common sensors
item <- item |> 
  add_eo_extension(bands = sentinel2_msi_bands())

item <- item |> 
  add_eo_extension(bands = landsat_oli_bands(include_thermal = TRUE))
```

#### Raster extension

``` r

item <- item |>
  add_raster_extension(
    bands = list(
      raster_band(
        data_type = "uint16",
        nodata = 0,
        spatial_resolution = 10,
        scale = 0.0001
      )
    ),
    asset_key = "visual"
  )
```

### Integrations with spatial R packages

``` r

# Create a STAC Item directly from a GeoTIFF (via terra)
item <- item_from_stars(
  file = "path/to/image.tif",
  datetime = "2023-06-15T10:30:00Z",
  add_raster_bands = TRUE,
  calculate_statistics = FALSE
)

# Create a STAC Item from an sf object
library(sf)
boundary <- st_read("boundary.shp")
item <- item_from_sf(
  boundary,
  id = "study-area",
  datetime = "2023-01-01T00:00:00Z"
)

# Batch-create items from a directory of rasters
items <- items_from_directory("path/to/rasters", pattern = "\\.tif$")

# Calculate a collection extent from a list of items automatically
extent <- extent_from_items(items)
```

### Writing and reading

``` r

# Write the entire catalog hierarchy to disk as JSON files
write_stac(catalog, path = "output/stac")

# Write as an absolute-URL catalog (for web hosting)
write_stac(catalog, path = "output/stac",
           catalog_type = "absolute",
           base_url = "https://example.com/stac")

# Write individual objects
write_catalog(collection, file = "collection.json")
write_item(item, file = "items/my-item.json")

# Read back from disk
catalog <- read_stac("output/stac/catalog.json")
collection <- read_stac("output/stac/collection/collection.json")
```

The written directory structure follows STAC conventions:

    output/stac/
      catalog.json
      sentinel-2-l2a/
        collection.json
        items/
          S2A_MSIL2A_20230615.json

### Validation

``` r

result <- validate_stac(collection)
result$valid    # TRUE / FALSE
result$errors   # character vector of errors
result$warnings # character vector of warnings for missing recommended fields

# Strict mode also checks recommended fields
validate_stac(item, strict = TRUE)
```

### Inspecting catalog contents

``` r

count_items(collection)                          # integer count of item links
get_item_links(collection, as_dataframe = TRUE)  # data.frame of item hrefs
get_items(collection)                            # list of stored item objects
get_children(catalog)                            # named list of child catalogs
```

## Serving a STAC API

stacbuildr can serve a live [STAC
API](https://github.com/radiantearth/stac-api-spec) backed by a
PostgreSQL database (with PostGIS). The API follows the OGC API –
Features and STAC API 1.0 specifications.

### Prerequisites

``` r

install.packages(c("DBI", "RPostgres", "plumber", "httr2"))
```

A PostgreSQL database with the PostGIS extension must be reachable.

### Set up the database

``` r
library(stacbuildr)
library(DBI)

con <- dbConnect(
  RPostgres::Postgres()
  host     = "localhost",
  dbname   = "stac",
  user     = "myuser",
  password = "mypassword"
)

# Create tables and indexes (idempotent — safe to run on every startup)
stac_db_setup(con)
```

### Ingest collections and items

``` r

# Insert a collection
stac_db_insert_collection(con, collection)

# Items must reference their collection before ingestion
item@collection <- "sentinel-2-l2a"
stac_db_insert_item(con, item)

# Items with extension metadata are stored as-is in JSONB —
# no schema changes are needed for new extensions
item_with_extensions <- item |>
  add_eo_extension(bands = sentinel2_msi_bands(), cloud_cover = 4.1) |>
  add_scientific_extension(doi = "10.1000/xyz123")

item_with_extensions@collection <- "sentinel-2-l2a"
stac_db_insert_item(con, item_with_extensions)
```

### Launch the API

``` r

router <- stac_api_router(
  con,
  base_url    = "http://localhost:8000",
  title       = "My STAC API",
  description = "Sentinel-2 imagery archive"
)

plumber::pr_run(router, port = 8000)
```

The router exposes these endpoints:

| Method | Path | Description |
|----|----|----|
| GET | `/` | Landing page |
| GET | `/conformance` | Conformance classes |
| GET | `/collections` | All collections |
| GET | `/collections/{collectionId}` | Single collection |
| GET | `/collections/{collectionId}/items` | Paged items |
| GET | `/collections/{collectionId}/items/{itemId}` | Single item |
| GET | `/search` | Cross-collection search |
| POST | `/search` | Search with JSON body |

**Search parameters:** `bbox`, `datetime`, `collections`, `ids`,
`limit`, `offset`. The POST `/search` endpoint additionally accepts a
`properties` object for filtering on any item property, including
extension fields:

``` json
{
  "bbox": [-106, 39, -104, 41],
  "datetime": "2023-01-01T00:00:00Z/2023-12-31T23:59:59Z",
  "collections": ["sentinel-2-l2a"],
  "limit": 20,
  "properties": {
    "eo:cloud_cover": 4.1,
    "sci:doi": "10.1000/xyz123"
  }
}
```

### Authentication

The API requires an `Authorization: Key <api-key>` header on every
request (the same convention used by Posit Connect for programmatic API
access). Key validation is resolved in this order:

1.  **`CONNECT_SERVER` env var set** — the key is validated live against
    Posit Connect’s user API. This env var is always set automatically
    when the content is deployed on Connect.
2.  **`STAC_API_KEY` env var set** — the key is compared to that static
    value. Useful for local development.
3.  **Neither set** — any correctly-formatted header is accepted. Use
    only when Connect is enforcing authentication at the infrastructure
    level.

To disable authentication during development:

``` r

router <- stac_api_router(con, require_auth = FALSE)
```

### Deploying to Posit Connect

The API can be deployed to [Posit
Connect](https://posit.co/products/enterprise/connect/) using the
standard plumber deployment workflow. Create an entrypoint file
(e.g. `plumber.R`) in your project:

``` r

# plumber.R
library(stacbuildr)
library(DBI)

con <- dbConnect(
  RPostgres::Postgres(),
  host     = Sys.getenv("DB_HOST"),
  dbname   = Sys.getenv("DB_NAME"),
  user     = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD")
)

stac_db_setup(con)

stac_api_router(
  con,
  base_url = Sys.getenv("CONNECT_CONTENT_URL")
)
```

Then publish and set database credentials as environment variables in
the Connect dashboard. In the content’s **Access** settings, set access
to **“All authenticated Posit Connect users”** (or a specific group) —
Connect will then validate API keys before requests reach the plumber
process, and the `CONNECT_SERVER` variable will be injected
automatically.

Callers authenticate using their personal Connect API key:

``` bash
curl -H "Authorization: Key <connect-api-key>" \
     https://connect.example.com/content/<id>/collections
```

## Dependencies

| Package     | Role                         |
|-------------|------------------------------|
| `S7`        | Object-oriented class system |
| `jsonlite`  | JSON serialisation           |
| `sf`        | Vector geometry handling     |
| `geojsonsf` | sf ↔︎ GeoJSON conversion      |

Optional: `stars` (reading raster files), `DBI` + `RPostgres` +
`plumber` + `httr2` (serving the STAC API)

## References

- [STAC Specification](https://stacspec.org/)
- [STAC Catalog
  spec](https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md)
- [STAC Collection
  spec](https://github.com/radiantearth/stac-spec/blob/master/collection-spec/collection-spec.md)
- [STAC Item
  spec](https://github.com/radiantearth/stac-spec/blob/master/item-spec/item-spec.md)
- [STAC API spec](https://github.com/radiantearth/stac-api-spec)
- [EO Extension](https://github.com/stac-extensions/eo)
- [Raster Extension](https://github.com/stac-extensions/raster)
- [Scientific Citation
  Extension](https://github.com/stac-extensions/scientific)
- [Classification
  Extension](https://github.com/stac-extensions/classification)
