# buildstac

**buildstac** is an R package for creating [STAC (SpatioTemporal Asset Catalog)](https://stacspec.org/) metadata. STAC is an open standard for describing geospatial data in a way that makes it indexable, searchable, and interoperable. The package implements STAC specification version 1.1.0 using [S7](https://rconsortium.github.io/S7/) classes and outputs valid STAC JSON.

## Installation

```r
# Install from GitHub
# install.packages("remotes")
remotes::install_github("stevenpawley/buildstac")
```

## Overview

A STAC catalog is a hierarchy of three object types:

| Object | Description |
|--------|-------------|
| **Catalog** | Top-level container that groups related Collections and Items |
| **Collection** | A Catalog extended with spatial/temporal extents, license, and summaries |
| **Item** | A GeoJSON Feature representing an individual asset (e.g. a single satellite scene) |

Each object contains **links** (JSON pointers connecting the hierarchy) and Items contain **assets** (references to the actual data files).

## Core functions

### Creating objects

```r
library(buildstac)

# Root catalog
catalog <- stac_catalog(
  id          = "my-catalog",
  title       = "My Satellite Imagery Catalog",
  description = "A catalog of satellite imagery for environmental monitoring"
)

# Collection (extends catalog with extent, license, etc.)
collection <- stac_collection(
  id          = "sentinel-2-l2a",
  title       = "Sentinel-2 Level-2A",
  description = "Bottom-of-atmosphere reflectance imagery from Sentinel-2",
  license     = "proprietary",
  extent      = stac_extent(
    spatial_bbox       = list(c(-180, -90, 180, 90)),
    temporal_interval  = list(list("2015-06-27T00:00:00Z", NULL))  # NULL = ongoing
  ),
  keywords  = c("sentinel", "esa", "optical"),
  providers = list(
    stac_provider(name = "ESA", roles = c("producer", "licensor"),
                  url  = "https://earth.esa.int")
  )
)

# Item (a single scene / data granule)
item <- stac_item(
  id       = "S2A_MSIL2A_20230615",
  geometry = list(type = "Polygon", coordinates = list(list(
    c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
    c(-105.5, 40.5), c(-105.5, 39.5)
  ))),
  bbox     = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T10:30:00Z",
  properties = list(platform = "sentinel-2a", instruments = c("msi"), gsd = 10)
)
```

### Managing links

```r
# Add standard navigation links
catalog <- catalog |>
  add_self_link("https://example.com/catalog.json") |>
  add_root_link("https://example.com/catalog.json")

# Add a child collection to the catalog
catalog <- add_child(catalog, collection)

# Add an item to a collection (with bidirectional links)
collection <- add_item(
  collection, item,
  add_parent_links = TRUE,
  parent_href = "./collection.json",
  root_href   = "../catalog.json"
)

# Add arbitrary links
collection <- add_link(collection, rel = "license",
                        href = "https://sentinel.esa.int/legal-notice.html",
                        type = "text/html")
```

### Adding assets to items

```r
item <- item |>
  add_asset(
    key   = "visual",
    href  = "https://example.com/S2A_20230615_visual.tif",
    title = "True Color Image",
    type  = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("visual", "data")
  ) |>
  add_asset(
    key   = "thumbnail",
    href  = "https://example.com/S2A_20230615_thumb.png",
    type  = "image/png",
    roles = c("thumbnail")
  )
```

### STAC extensions

#### Electro-Optical (EO) extension

```r
item <- item |>
  add_eo_extension(
    bands = list(
      eo_band(name = "B4", common_name = "red",   center_wavelength = 0.665),
      eo_band(name = "B3", common_name = "green", center_wavelength = 0.560),
      eo_band(name = "B2", common_name = "blue",  center_wavelength = 0.490)
    ),
    cloud_cover = 5.2,
    asset_key   = "visual"   # attach bands to a specific asset
  )

# Pre-built band definitions for common sensors
item <- add_eo_extension(item, bands = sentinel2_msi_bands())
item <- add_eo_extension(item, bands = landsat_oli_bands(include_thermal = TRUE))
```

#### Raster extension

```r
item <- item |>
  add_raster_extension(
    bands = list(
      raster_band(data_type = "uint16", nodata = 0,
                  spatial_resolution = 10, scale = 0.0001)
    ),
    asset_key = "visual"
  )
```

### Integrations with spatial R packages

```r
# Create a STAC Item directly from a GeoTIFF (via terra)
item <- item_from_raster(
  file                 = "path/to/image.tif",
  datetime             = "2023-06-15T10:30:00Z",
  add_raster_bands     = TRUE,
  calculate_statistics = FALSE
)

# Create a STAC Item from an sf object
library(sf)
boundary <- st_read("boundary.shp")
item <- item_from_sf(
  boundary,
  id       = "study-area",
  datetime = "2023-01-01T00:00:00Z"
)

# Batch-create items from a directory of rasters
items <- items_from_directory("path/to/rasters", pattern = "\\.tif$")

# Calculate a collection extent from a list of items automatically
extent <- extent_from_items(items)
```

### Writing and reading

```r
# Write the entire catalog hierarchy to disk as JSON files
write_stac(catalog, path = "output/stac")

# Write as an absolute-URL catalog (for web hosting)
write_stac(catalog, path = "output/stac",
           catalog_type = "absolute",
           base_url     = "https://example.com/stac")

# Write individual objects
write_catalog(collection, file = "collection.json")
write_item(item, file = "items/my-item.json")

# Read back from disk
catalog    <- read_stac("output/stac/catalog.json")
collection <- read_stac("output/stac/collection/collection.json")
```

The written directory structure follows STAC conventions:

```
output/stac/
  catalog.json
  sentinel-2-l2a/
    collection.json
    items/
      S2A_MSIL2A_20230615.json
```

### Validation

```r
result <- validate_stac(collection)
result$valid    # TRUE / FALSE
result$errors   # character vector of errors
result$warnings # character vector of warnings for missing recommended fields

# Strict mode also checks recommended fields
validate_stac(item, strict = TRUE)
```

### Inspecting catalog contents

```r
count_items(collection)                          # integer count of item links
get_item_links(collection, as_dataframe = TRUE)  # data.frame of item hrefs
get_items(collection)                            # list of stored item objects
get_children(catalog)                            # named list of child catalogs
```

## Dependencies

| Package | Role |
|---------|------|
| `S7` | Object-oriented class system |
| `jsonlite` | JSON serialisation |
| `sf` | Vector geometry handling |
| `terra` | Raster file reading |
| `geojsonsf` | sf ↔ GeoJSON conversion |
| `jsonvalidate` | JSON Schema validation |
| `httr` | HTTP utilities |
| `uuid` | Unique identifier generation |

Optional: `stars`, `rstac`

## References

- [STAC Specification](https://stacspec.org/)
- [STAC Catalog spec](https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md)
- [STAC Collection spec](https://github.com/radiantearth/stac-spec/blob/master/collection-spec/collection-spec.md)
- [STAC Item spec](https://github.com/radiantearth/stac-spec/blob/master/item-spec/item-spec.md)
- [EO Extension](https://github.com/stac-extensions/eo)
- [Raster Extension](https://github.com/stac-extensions/raster)
