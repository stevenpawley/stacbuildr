# stacbuildr

<!-- badges: start -->
[![R-CMD-check](https://github.com/stevenpawley/stacbuildr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/stevenpawley/stacbuildr/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/stacbuildr)](https://CRAN.R-project.org/package=stacbuildr)
[![R-universe version](https://stevenpawley.r-universe.dev/stacbuildr/badges/version)](https://stevenpawley.r-universe.dev/stacbuildr)
<!-- badges: end -->

**stacbuildr** is an *experimental* R package for creating [STAC (SpatioTemporal Asset Catalog)](https://stacspec.org/) metadata. STAC is an open standard for describing geospatial data in a way that makes it indexable, searchable, and interoperable. The package implements STAC specification version 1.1.0 using [S7](https://rconsortium.github.io/S7/) classes and outputs valid STAC JSON.

*Note* this package is in active development: breaking changes are expected and there is no guarantee of compliance with STACspec.

## Installation

```r
# Install from GitHub
# install.packages("remotes")
remotes::install_github("stevenpawley/stacbuildr")
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

```r
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

```r
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

```r
item <- item |>
  add_eo_extension(
    bands = list(
      eo_band(name = "B4", common_name = "red",   center_wavelength = 0.665),
      eo_band(name = "B3", common_name = "green", center_wavelength = 0.560),
      eo_band(name = "B2", common_name = "blue",  center_wavelength = 0.490)
    ),
    cloud_cover = 5.2,
    asset_key = "visual"  # attach bands to a specific asset
  )

# Pre-built band definitions for common sensors
item <- item |> 
  add_eo_extension(bands = sentinel2_msi_bands())

item <- item |> 
  add_eo_extension(bands = landsat_oli_bands(include_thermal = TRUE))
```

Following v2.0.0 of the EO and Raster extensions, band objects are written to
the `bands` array that STAC 1.1 shares between all band-level extensions, with
each extension's own fields prefixed (`eo:common_name`, `raster:scale`). Both
`add_*_extension()` functions write to the same array, so describing the same
bands with each in turn merges their fields.

#### Raster extension

```r
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

#### Projection extension

```r
item <- item |>
  add_projection_extension(
    code = "EPSG:32612",                             # AUTHORITY:CODE, not a bare number
    shape = c(5558, 9559),                           # rows, columns
    transform = c(30, 0, 712710, 0, -30, 5654790),   # affine pixel -> CRS
    bbox = c(712710, 5487090, 999480, 5654790)       # in the native CRS
  )
```

`item_from_terra()` and `item_from_lidr()` add these fields for you; call this
directly when building an item by hand. Pass `asset_key` to place the fields on
one asset, for items whose assets differ in resolution.

### Integrations with spatial R packages

```r
library(terra)

# Create a STAC Item from a SpatRaster (with projection extension added automatically)
r <- rast("path/to/image.tif")
item <- item_from_terra(
  r,
  href = "path/to/image.tif",
  id = "my-scene",
  datetime = "2023-06-15T10:30:00Z",
  add_raster_bands = TRUE,
  calculate_statistics = FALSE
)

# Or read raster band metadata separately and attach to an existing item
bands <- raster_from_file("path/to/image.tif", calculate_statistics = TRUE)
item <- item |>
  add_asset("data", href = "path/to/image.tif",
            type = "image/tiff; application=geotiff; profile=cloud-optimized",
            roles = list("data")) |>
  add_raster_extension(bands = bands, asset_key = "data")

# Generate a thumbnail PNG from a SpatRaster and attach it as an asset
item <- item |>
  add_asset("thumbnail", preview_from_terra(r, tempfile(fileext = ".png")))

# Create a STAC Item from an sf object
library(sf)
boundary <- st_read("boundary.shp")
item <- item_from_sf(
  boundary,
  id = "study-area",
  datetime = "2023-01-01T00:00:00Z"
)

# Batch-create items from a directory of rasters
files <- list.files("path/to/rasters", pattern = "\\.tif$", full.names = TRUE)
items <- lapply(files, function(f) {
  item_from_terra(terra::rast(f), id = tools::file_path_sans_ext(basename(f)))
})

# Calculate a collection extent from a list of items automatically
extent <- extent_from_items(items)
```

### Writing and reading

```r
# Write the entire catalog hierarchy to disk as JSON files.
# The default "self-contained" type uses relative links throughout, so the
# tree stays portable.
write_stac(catalog, path = "output/stac")

# Write as a relative catalog: relative links, plus one absolute self link on
# the root recording where the catalog is published
write_stac(catalog, path = "output/stac",
           catalog_type = "relative",
           base_url = "https://example.com/stac")

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

The `catalog_type` values correspond one-to-one with the link layouts in
[Use of links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links) in the STAC best-practices document, and with
PySTAC's `CatalogType`:

| `catalog_type` | STAC best practices | PySTAC |
| --- | --- | --- |
| `"self-contained"` | [Self-contained Catalogs](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-catalogs) | `SELF_CONTAINED` |
| `"relative"` | [Relative Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#relative-published-catalog) | `RELATIVE_PUBLISHED` |
| `"absolute"` | [Absolute Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#absolute-published-catalog) | `ABSOLUTE_PUBLISHED` |

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

### Working with a catalog as data

A Catalog or Collection behaves as the container of Items it is:

```r
length(collection)        # number of items
collection[["scene-1"]]   # one item, by id
collection[1:5]           # a list of items

# One row per item: id, collection, datetime, then every property as a column
as.data.frame(collection)

# The same table with the item footprints attached, in EPSG:4326
scenes <- sf::st_as_sf(collection)
scenes[scenes$`eo:cloud_cover` < 20, ]
plot(sf::st_geometry(scenes))
```

Items missing a property get `NA` for it, and properties that hold vectors or
objects (`proj:transform`, `bands`) become list columns. For a catalog read back
from disk with `read_stac()`, pass `resolve = TRUE` to follow the item links.

An Item is a GeoJSON Feature, so the `sf` accessors work on one directly:

```r
sf::st_geometry(item)   # the footprint as an sfc
sf::st_bbox(item)       # its bounding box
sf::st_crs(item)        # EPSG:4326 -- native CRS is in proj:code
```

### Inspecting catalog contents

```r
count_items(collection)                          # integer count of item links
get_item_links(collection, as_dataframe = TRUE)  # data.frame of item hrefs
get_items(collection)                            # list of stored item objects
get_children(catalog)                            # named list of child catalogs
```

## Serving a STAC API

Serving these catalogs as a live [STAC API](https://github.com/radiantearth/stac-api-spec)
is handled by the companion package
[stacserver](https://github.com/stevenpawley/stacserver), which ingests
stacbuildr objects into a PostgreSQL/PostGIS database and exposes them through
a `plumber` router.

## Dependencies

| Package | Role |
|---------|------|
| `S7` | Object-oriented class system |
| `jsonlite` | JSON serialisation |
| `sf` | Vector geometry handling |
| `geojsonsf` | sf ↔ GeoJSON conversion |

Optional: `terra` (raster integration — `item_from_terra`, `raster_from_file`, `preview_from_terra`), `lidR` (point-cloud integration — `item_from_lidr`, `items_from_lascatalog`), `jsonvalidate` (schema validation)

## References

- [STAC Specification](https://stacspec.org/)
- [STAC Catalog spec](https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md)
- [STAC Collection spec](https://github.com/radiantearth/stac-spec/blob/master/collection-spec/collection-spec.md)
- [STAC Item spec](https://github.com/radiantearth/stac-spec/blob/master/item-spec/item-spec.md)
- [STAC API spec](https://github.com/radiantearth/stac-api-spec)
- [EO Extension](https://github.com/stac-extensions/eo)
- [Raster Extension](https://github.com/stac-extensions/raster)
- [Scientific Citation Extension](https://github.com/stac-extensions/scientific)
- [Classification Extension](https://github.com/stac-extensions/classification)
