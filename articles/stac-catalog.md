# Building a STAC Catalog

This vignette demonstrates how to build a STAC catalog with
`stacbuildr`, covering:

1.  Creating a catalog, collection, and item from a raster file
2.  Writing a static catalog to disk
3.  Loading into a PostgreSQL database and serving a STAC API *(requires
    infrastructure)*

## Setup

``` r

library(stacbuildr)
library(stars)
#> Loading required package: abind
#> Loading required package: sf
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
```

## Create a synthetic DEM

For this example we create a small synthetic Digital Elevation Model and
write it to a temporary file. In practice, replace `tif_path` with the
path to your own raster file.

``` r

set.seed(42)
m <- matrix(runif(100, 100, 3000), nrow = 10, ncol = 10)
dem <- st_as_stars(m)
dem <- st_set_dimensions(dem, 1, offset = -120, delta = 0.1)
dem <- st_set_dimensions(dem, 2, offset = 49, delta = -0.1)
st_crs(dem) <- 4326
names(dem) <- "elevation"

tif_path <- file.path(tempdir(), "dem.tif")
write_stars(dem, tif_path)

r <- read_stars(tif_path)
```

## Create a STAC Item from the raster

[`item_from_stars()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_stars.md)
extracts the spatial extent, CRS, and geometry from the `stars` object
and returns a `stac_item`. We then attach the raster file as an asset.

``` r

item <- r |>
  item_from_stars(
    id = "dem-001",
    datetime = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
  ) |>
  add_asset(
    key = "dem",
    href = tif_path,
    title = "Digital Elevation Model",
    description = "Synthetic DEM for demonstration",
    type = "image/tiff; application=geotiff",
    roles = "data"
  )

item
#> <STAC Item>
#>   id          : dem-001
#>   stac_version: 1.1.0
#>   datetime    : 2026-06-23T02:39:47Z
#>   geometry    : Polygon
#>   bbox        : [-120.0000, 48.0000, -119.0000, 49.0000]
#>   assets      : 1 [dem]
#>   extensions  : 1
#>   links       : 0
```

## Create a Collection and Catalog

``` r

collection <- stac_collection(
  id = "terrain",
  description = "Terrain datasets",
  title = "Terrain Collection",
  license = "CC-BY-4.0",
  extent = stac_extent(
    spatial_bbox = list(as.numeric(st_bbox(r))),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )
)

catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example STAC catalog",
  title = "My Catalog"
)

collection <- add_item(collection, item)
catalog <- add_child(catalog, collection)
```

## Write a static catalog to disk

[`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
recursively writes the catalog, collection, and item JSON files. The
`catalog_type` argument controls how links and asset hrefs are written:

- `"self-contained"` — all links and asset hrefs are relative paths
  within the catalog directory. Most portable: zip and share or move the
  folder anywhere. Use for sharing or archiving.
- `"relative"` — links between catalog/collection/item files are
  relative, but asset hrefs are left as-is (absolute local paths or
  external URLs). Use when the catalog indexes large on-disk data you
  don’t want to copy.
- `"absolute"` — all links use full URLs built from `base_url`. Use when
  publishing to a web server so remote clients can crawl the catalog
  over HTTP. Assets should also be URLs (S3, HTTPS) in this case.

Since the DEM lives in
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) alongside the
catalog, we use `"self-contained"` here:

``` r

catalog_dir <- file.path(tempdir(), "catalog")

write_stac(
  catalog,
  catalog_dir,
  catalog_type = "self-contained",
  overwrite = TRUE
)
#> STAC catalog written to: /tmp/RtmpGtm4sS/catalog
```

The resulting directory structure looks like:

    catalog/
      catalog.json
      terrain/
        collection.json
        dem-001/
          dem-001.json

We can read it back:

``` r

cat_read <- read_stac(file.path(catalog_dir, "catalog.json"))
coll_read <- read_stac(file.path(catalog_dir, "terrain", "collection.json"))
item_read <- read_stac(file.path(
  catalog_dir,
  "terrain",
  "dem-001",
  "dem-001.json"
))

item_read
#> <STAC Item>
#>   id          : dem-001
#>   collection  : terrain
#>   stac_version: 1.1.0
#>   datetime    : 2026-06-23T02:39:47Z
#>   geometry    : Polygon
#>   bbox        : [-120.0000, 48.0000, -119.0000, 49.0000]
#>   assets      : 1 [dem]
#>   extensions  : 1
#>   links       : 4 [self, parent, collection, root]
```

## Database-backed STAC API

The following sections require a running PostgreSQL database and
(optionally) a Posit Connect server to deploy the API. They are shown
for reference but are not evaluated when the vignette is built.

### Set up the database

``` r

library(DBI)

con <- dbConnect(
  RPostgres::Postgres(),
  host = "localhost",
  port = 5432,
  dbname = "stac",
  user = Sys.getenv("PG_USER"),
  password = Sys.getenv("PG_PASSWORD")
)

stac_db_setup(con)
```

### Insert a collection and item

``` r

stac_db_insert_collection(con, collection)

item@collection <- "terrain"
stac_db_insert_item(con, item)
```

### Run the STAC API locally

[`stac_api_router()`](https://stevenpawley.github.io/stacbuildr/reference/stac_api_router.md)
returns a plumber router pre-wired with all STAC endpoints. For local
development, pass `require_auth = FALSE` to skip authentication.

Asset hrefs should be HTTP-accessible URLs when serving via the API. For
local development, run a file server alongside the API so that GDAL/QGIS
can fetch assets over HTTP, then set the asset `href` to
`http://127.0.0.1:<port>/...`.

Two lightweight options (run in a terminal from your data directory):

``` sh
# Python (built-in, no install required)
python3 -m http.server 8000 --directory ~/Data

# Ruby (built-in on macOS)
ruby -run -e httpd ~/Data -p 8000
```

The asset href would then be, for example:

``` r

href = "http://127.0.0.1:8000/terrain/alos.tif"
```

In production, use blob storage URLs (S3, Azure Blob, GCS) so clients
can fetch assets directly without going through the API.

``` r

library(plumber)

pr <- stac_api_router(
  con,
  base_url = "http://127.0.0.1:3485"
)

pr_run(pr, port = 3485)
```

### Deploying to Posit Connect

When deploying to Posit Connect with multiple concurrent users, replace
the single DBI connection with a connection pool from the `pool`
package. A pool manages multiple connections and hands them out to
simultaneous requests without contention. Store credentials in
environment variables rather than hardcoding them — Posit Connect lets
you set these per-deployment under the Vars tab.

``` r

library(pool)
library(plumber)

pool <- dbPool(
  RPostgres::Postgres(),
  host = Sys.getenv("PG_HOST"),
  dbname = Sys.getenv("PG_DBNAME"),
  user = Sys.getenv("PG_USER"),
  password = Sys.getenv("PG_PASSWORD")
)

onStop(function() poolClose(pool))

pr <- stac_api_router(
  pool,
  base_url = Sys.getenv("STAC_BASE_URL") # e.g. "https://connect.example.com/stac"
)

pr_run(pr)
```
