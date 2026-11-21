# compare-with-pystac.R — differential JSON comparison of stacbuildr vs pystac
#
# Standalone dev script (not a test). It runs a battery of scenarios through
# every exported stacbuildr function, serializes each result with the package's
# own serialization policy (same as stac_to_json()), builds the equivalent
# objects with pystac via the companion dev/compare-with-pystac.py, and diffs
# the two JSON sets (object key order ignored; link arrays compared as sets;
# numbers at 1e-9 relative tolerance).
#
# ---------------------------------------------------------------------------
# HOW TO RUN
# ---------------------------------------------------------------------------
# From the package root:
#
#   Rscript dev/compare-with-pystac.R [output-dir]
#
# e.g.:
#
#   Rscript dev/compare-with-pystac.R /tmp/stac-compare
#
# Prerequisites:
#   * R with the package's dependencies installed (pkgload is used to load
#     the package from this source checkout when available, otherwise the
#     installed stacbuildr is used).
#   * A python environment with pystac installed. By default the script uses
#     ~/.virtualenvs/pystac/bin/python; point STACBUILDR_PYTHON at another
#     interpreter if needed:
#
#       STACBUILDR_PYTHON=/path/to/python Rscript dev/compare-with-pystac.R /tmp/out
#
#   * Optional integrations: terra + sf for the item_from_* / thumbnail / band
#     scenarios (skipped with an error entry if missing), lidR for the
#     item_from_lidr / items_from_lascatalog scenarios, network access for the
#     validate_stac_schema scenarios (remote JSON schemas).
#
# Outputs (written to the output dir, default tempdir()):
#   r_results.json    raw JSON produced by stacbuildr for every scenario
#   py_results.json   raw JSON produced by pystac for every scenario
#   report.md         markdown table: scenario | status | differences
#   diffs.json        machine-readable detail for every scenario
#   data/             fixture files created by the R scenarios (GeoTIFFs,
#                     GeoJSON) that the python side reads back
#   r_out/, py_out/   catalog trees written by write_stac() vs pystac save()
#
# Statuses in the report:
#   MATCH        identical JSON (key order ignored)
#   MATCH*       identical except pystac emits an empty "stac_extensions": []
#                on Items where stacbuildr omits the field when empty
#   DIFF         real difference — read the NOTE column, most are known
#                pystac-side conventions (auto root links, read_file injecting
#                self links, ...) rather than stacbuildr bugs
#   ERROR-R/-PY  the scenario errored on that side (e.g. lidR not installed)
#   PY-ONLY      pystac-native extension output recorded for version-gap notes
#
# ---------------------------------------------------------------------------
# ADDING A SCENARIO
# ---------------------------------------------------------------------------
# 1. Add a function to `scenarios` below, named after the stacbuildr function
#    it exercises. It must return a stac_object (or a list of them); the runner
#    serializes the return value with the package's own stac_to_json policy.
# 2. Add the same-named scenario to dev/compare-with-pystac.py building the
#    equivalent object with pystac (obj.to_dict() is applied for you).
# 3. Re-run the script. Name mismatches show up as R-ONLY / PY-ONLY rows.
#
# The python script can also be run standalone while debugging the pystac side:
#   python dev/compare-with-pystac.py --data-dir <out>/data --r-out <out>/r_out --out <out>
# ---------------------------------------------------------------------------

suppressMessages({
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", quiet = TRUE)
  } else {
    library(stacbuildr)
  }
  library(jsonlite)
})

suppressMessages({
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(".", quiet = TRUE)
  } else {
    library(stacbuildr)
  }
  library(jsonlite)
})

# Locate this script's directory (works under Rscript) and parse args
.args_all <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args_all, value = TRUE)
DEV_DIR <- if (length(.file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", .file_arg[1]), mustWork = FALSE))
} else {
  "dev"
}
.args_trailing <- commandArgs(trailingOnly = TRUE)
OUT_DIR <- if (length(.args_trailing) > 0) {
  normalizePath(.args_trailing[1], mustWork = FALSE)
} else {
  tempdir()
}
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
DATA_DIR <- file.path(OUT_DIR, "data")
R_OUT <- file.path(OUT_DIR, "r_out")
dir.create(DATA_DIR, recursive = TRUE, showWarnings = FALSE)
cat("Output dir:", OUT_DIR, "\n")

# lidR fixtures: small LAS files the python side reads back with laspy
if (requireNamespace("lidR", quietly = TRUE)) {
  set.seed(42)
  mk_las_fixture <- function(f) {
    n <- 500L
    df <- data.frame(
      X = runif(n, 712710, 713310),
      Y = runif(n, 5487090, 5487390),
      Z = runif(n, 400, 700),
      Intensity = as.integer(runif(n, 0, 255)),
      ReturnNumber = sample(1:3, n, TRUE),
      Classification = rep(2L, n),
      GpsTime = runif(n, 100000, 200000)
    )
    df$NumberOfReturns <- pmin(sample(1:3, n, TRUE), df$ReturnNumber + 2L)
    df$NumberOfReturns <- pmax(df$NumberOfReturns, df$ReturnNumber)
    las <- lidR::LAS(df)
    lidR::crs(las) <- "EPSG:32612"
    las@header@PHB[["File Creation Year"]] <- 2023L
    las@header@PHB[["File Creation Day of Year"]] <- 166L
    las@header@PHB[["Point Data Format ID"]] <- 1L
    lidR::writeLAS(las, f, index = FALSE)
  }
  mk_las_fixture(file.path(DATA_DIR, "test.las"))
  ctg_dir <- file.path(DATA_DIR, "las_ctg")
  dir.create(ctg_dir, showWarnings = FALSE)
  mk_las_fixture(file.path(ctg_dir, "plot_a.las"))
  mk_las_fixture(file.path(ctg_dir, "plot_b.las"))
}

# Serialization identical to stacbuildr:::stac_to_json(x, pretty = FALSE)
ser <- function(x) {
  x <- stacbuildr:::strip_stored_objects(x)
  if (inherits(x, "stac_object")) x <- as.list(x)
  jsonlite::toJSON(x, auto_unbox = TRUE, pretty = FALSE, null = "null", digits = I(15))
}

# Serialize a scenario result. A result may be:
#  - a stac_object / plain value  -> serialized directly
#  - a list of stac_objects (named or not) -> serialize element-wise
#    (named -> JSON object, unnamed -> JSON array)
ser_one <- function(o) {
  if (inherits(o, "stac_object")) {
    return(jsonlite::fromJSON(ser(o), simplifyVector = FALSE))
  }
  if (is.list(o)) {
    return(lapply(o, ser_one))
  }
  jsonlite::fromJSON(jsonlite::toJSON(o, auto_unbox = TRUE, null = "null", digits = I(15)),
                     simplifyVector = FALSE)
}

ser_result <- function(obj) {
  ser_one(obj)
}

scenarios <- list()

# ---- shared building blocks -------------------------------------------------
mk_point_item <- function(id = "observation-001") {
  stac_item(
    id = id,
    geometry = list(type = "Point", coordinates = c(-105.0, 40.0)),
    bbox = c(-105.0, 40.0, -105.0, 40.0),
    datetime = "2023-06-15T10:30:00Z"
  )
}

mk_polygon_item <- function(id = "LC08_L1TP_044034_20230615") {
  stac_item(
    id = id,
    geometry = list(
      type = "Polygon",
      coordinates = list(list(
        c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
        c(-105.5, 40.5), c(-105.5, 39.5)
      ))
    ),
    bbox = c(-105.5, 39.5, -104.5, 40.5),
    datetime = "2023-06-15T17:30:00Z",
    properties = list(
      title = "Landsat 8 Scene",
      platform = "landsat-8",
      instruments = c("oli", "tirs"),
      gsd = 30,
      `eo:cloud_cover` = 5.2
    )
  )
}

mk_extent <- function() {
  stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90), c(-120, 30, -110, 40)),
    temporal_interval = list(
      list("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z"),
      list("2021-01-01T00:00:00Z", NULL)
    )
  )
}

mk_collection <- function(id = "sentinel-2-l2a") {
  stac_collection(
    id = id,
    title = "Sentinel-2 Level-2A",
    description = "Sentinel-2 Level-2A BOA reflectance products.",
    license = "CC-BY-4.0",
    extent = mk_extent(),
    keywords = c("sentinel", "esa", "msi"),
    providers = list(
      stac_provider(
        name = "ESA",
        description = "European Space Agency",
        roles = c("producer", "licensor"),
        url = "https://earth.esa.int/web/guest/home"
      )
    ),
    summaries = stac_summaries(
      platform = c("sentinel-2a", "sentinel-2b"),
      gsd = list(minimum = 10, maximum = 60),
      bands = list(
        list(name = "B01", `eo:common_name` = "coastal"),
        list(name = "B02", `eo:common_name` = "blue")
      )
    )
  )
}

# ---- core ---------------------------------------------------------------------
scenarios[["stac_catalog_min"]] <- function() {
  stac_catalog(id = "my-catalog", description = "A catalog of satellite imagery")
}

scenarios[["stac_catalog_full"]] <- function() {
  stac_catalog(
    id = "versioned-catalog",
    title = "Versioned Catalog",
    description = "A catalog with version tracking",
    stac_extensions = c("https://stac-extensions.github.io/version/v1.2.0/schema.json"),
    conformsTo = c("https://stacspec.org/api/conformance"),
    links = list(stac_link("self", "https://example.com/catalog.json", type = "application/json")),
    version = "1.0.0",
    deprecated = FALSE
  )
}

scenarios[["stac_link_full"]] <- function() {
  stac_link(
    rel = "related", href = "https://example.com/metadata.html",
    type = "text/html", title = "Additional metadata",
    method = "POST", body = list(a = 1),
    `x-custom` = "yes"
  )
}

scenarios[["add_link_catalog"]] <- function() {
  catalog <- stac_catalog(id = "my-catalog", description = "Example catalog")
  catalog <- add_link(catalog, rel = "self", href = "https://example.com/catalog.json", type = "application/json")
  catalog <- add_link(catalog, rel = "related", href = "https://example.com/metadata.html", type = "text/html", title = "Additional metadata")
  catalog
}

scenarios[["add_self_link_root_link"]] <- function() {
  catalog <- stac_catalog(id = "my-catalog", description = "Example catalog")
  catalog <- add_self_link(catalog, "https://example.com/catalog.json")
  catalog <- add_root_link(catalog, "https://example.com/catalog.json", title = "Root catalog")
  catalog
}

scenarios[["add_child_catalog"]] <- function() {
  parent <- stac_catalog(id = "parent-catalog", description = "Parent catalog", title = "Parent")
  child <- stac_catalog(id = "landsat", title = "Landsat Imagery", description = "Landsat satellite imagery")
  add_child(parent, child)
}

scenarios[["add_child_collection"]] <- function() {
  parent <- stac_catalog(id = "parent-catalog", description = "Parent catalog")
  add_child(parent, mk_collection("sentinel-2-l2a"))
}

scenarios[["stac_collection_min"]] <- function() {
  stac_collection(
    id = "landsat-8-c2-l2",
    description = "Landsat 8 Collection 2 Level-2 Surface Reflectance",
    license = "CC0-1.0",
    extent = stac_extent(
      spatial_bbox = list(c(-180, -90, 180, 90)),
      temporal_interval = list(list("2013-04-11T00:00:00Z", NULL))
    )
  )
}

scenarios[["stac_collection_full"]] <- function() {
  col <- mk_collection()
  col <- add_self_link(col, "https://example.com/collections/sentinel-2-l2a.json")
  col <- add_root_link(col, "https://example.com/catalog.json")
  col <- add_link(col, rel = "license", href = "https://creativecommons.org/licenses/by/4.0/", type = "text/html", title = "CC-BY-4.0")
  col <- add_asset2collection(col)
  col
}

add_asset2collection <- function(col) {
  # add a collection-level asset via the assets argument path
  col$assets <- normalize_assets(list(thumbnail = stac_asset(
    href = "https://example.com/thumb.png", title = "Thumbnail",
    type = "image/png", roles = c("thumbnail")
  )))
  col
}

scenarios[["stac_collection_ext_conforms"]] <- function() {
  stac_collection(
    id = "col-ext",
    description = "Collection with extensions",
    license = "other",
    extent = mk_extent(),
    stac_extensions = c("https://stac-extensions.github.io/render/v2.0.0/schema.json"),
    conformsTo = c("https://stacspec.org/api/conformance"),
    custom_field = list(a = 1)
  )
}

scenarios[["stac_extent"]] <- function() {
  mk_extent()
}

scenarios[["stac_extent_3d"]] <- function() {
  stac_extent(
    spatial_bbox = list(c(-105.5, 39.5, 100, -104.5, 40.5, 2500)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z"))
  )
}

scenarios[["stac_provider_full"]] <- function() {
  stac_provider(
    name = "USGS",
    description = "United States Geological Survey",
    roles = c("producer", "licensor", "host"),
    url = "https://www.usgs.gov"
  )
}

scenarios[["stac_provider_min"]] <- function() {
  stac_provider(name = "ESA")
}

scenarios[["stac_summaries"]] <- function() {
  stac_summaries(
    platform = c("landsat-8", "landsat-9"),
    instruments = c("oli"),
    gsd = list(minimum = 15, maximum = 30),
    bands = list(list(name = "B1", `eo:common_name` = "coastal")),
    single = "one-value"
  )
}

scenarios[["stac_item_point_min"]] <- function() {
  mk_point_item()
}

scenarios[["stac_item_polygon_props"]] <- function() {
  mk_polygon_item()
}

scenarios[["stac_item_timerange"]] <- function() {
  stac_item(
    id = "composite-2023-q2",
    geometry = list(type = "Polygon", coordinates = list(list(
      c(-180, -90), c(180, -90), c(180, 90), c(-180, 90), c(-180, -90)
    ))),
    bbox = c(-180, -90, 180, 90),
    datetime = NULL,
    start_datetime = "2023-04-01T00:00:00Z",
    end_datetime = "2023-06-30T23:59:59Z",
    properties = list(title = "Q2 2023 Global Composite")
  )
}

scenarios[["stac_item_3d"]] <- function() {
  stac_item(
    id = "lidar-001",
    geometry = list(type = "Point", coordinates = c(-105.0, 40.0, 1500)),
    bbox = c(-105.0, 40.0, 1500, -105.0, 40.0, 1500),
    datetime = "2023-06-15T14:00:00Z"
  )
}

scenarios[["stac_item_nonspatial"]] <- function() {
  stac_item(
    id = "global-report-2023",
    geometry = NULL,
    bbox = NULL,
    datetime = "2023-12-31T23:59:59Z",
    properties = list(title = "Annual Global Climate Report")
  )
}

scenarios[["stac_item_ext_collection"]] <- function() {
  stac_item(
    id = "item-ext",
    geometry = list(type = "Point", coordinates = c(-105.0, 40.0)),
    bbox = c(-105.0, 40.0, -105.0, 40.0),
    datetime = "2023-06-15T10:30:00Z",
    stac_extensions = c("https://stac-extensions.github.io/eo/v2.0.0/schema.json"),
    collection = "sentinel-2-l2a"
  )
}

scenarios[["stac_asset_full"]] <- function() {
  stac_asset(
    href = "./data/LC08_B4.tif",
    title = "Band 4 - Red",
    description = "Red band reflectance",
    type = "image/tiff; application=geotiff",
    roles = c("data", "reflectance"),
    bands = list(list(name = "B4", `eo:common_name` = "red"))
  )
}

scenarios[["stac_asset_min"]] <- function() {
  stac_asset(href = "https://example.com/image.tif")
}

scenarios[["add_asset_item"]] <- function() {
  item <- mk_point_item()
  item <- add_asset(item, key = "visual", href = "https://example.com/LC08_visual.tif",
                    title = "True Color Image", type = "image/tiff; application=geotiff", roles = c("visual"))
  item <- add_asset(item, key = "thumbnail", href = "https://example.com/LC08_thumb.png",
                    title = "Thumbnail", type = "image/png", roles = c("thumbnail"))
  item
}

scenarios[["stac_geometry_point"]] <- function() {
  stac_geometry("Point", coordinates = c(-105, 40))
}

scenarios[["stac_geometry_polygon"]] <- function() {
  stac_geometry("Polygon", coordinates = list(list(
    c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5), c(-105.5, 40.5), c(-105.5, 39.5)
  )))
}

scenarios[["stac_geometry_collection"]] <- function() {
  stac_geometry("GeometryCollection", geometries = list(
    stac_geometry("Point", coordinates = c(-105, 40)),
    stac_geometry("LineString", coordinates = list(c(-105, 40), c(-104, 41)))
  ))
}

scenarios[["add_item_collection"]] <- function() {
  col <- mk_collection()
  col <- add_self_link(col, "https://example.com/collections/sentinel-2-l2a.json")
  col <- add_root_link(col, "https://example.com/catalog.json")
  item <- mk_point_item("item-001")
  item$properties$title <- "First item"
  col <- add_item(col, item, add_parent_links = TRUE)
  list(collection = col, stored_item = get_items(col)[[1]])
}

scenarios[["add_item_catalog_default_href"]] <- function() {
  catalog <- stac_catalog(id = "cat", description = "d")
  catalog <- add_item(catalog, mk_point_item("item-001"))
  list(collection = catalog, stored_item = get_items(catalog)[[1]])
}

scenarios[["extent_from_items"]] <- function() {
  items <- list(
    mk_point_item("i1"),
    stac_item(id = "i2", geometry = list(type = "Point", coordinates = c(-100, 45)),
              bbox = c(-100, 45, -100, 45), datetime = "2023-07-01T00:00:00Z"),
    stac_item(id = "i3", geometry = NULL, bbox = NULL, datetime = "2023-08-01T00:00:00Z")
  )
  items[[1]]$properties$datetime <- "2023-06-01T00:00:00Z"
  extent_from_items(items)
}

scenarios[["get_item_links"]] <- function() {
  catalog <- stac_catalog(id = "cat", description = "d")
  catalog <- add_item(catalog, mk_point_item("item-001"))
  catalog <- add_item(catalog, mk_point_item("item-002"))
  get_item_links(catalog)
}

scenarios[["get_items_get_children"]] <- function() {
  catalog <- stac_catalog(id = "cat", description = "d")
  catalog <- add_child(catalog, stac_catalog(id = "child-1", description = "c"))
  catalog <- add_item(catalog, mk_point_item("item-001"))
  list(items = unname(get_items(catalog)), children = unname(get_children(catalog)))
}

scenarios[["count_items"]] <- function() {
  catalog <- stac_catalog(id = "cat", description = "d")
  catalog <- add_item(catalog, mk_point_item("item-001"))
  catalog <- add_item(catalog, mk_point_item("item-002"))
  count_items(catalog)
}

scenarios[["remove_item"]] <- function() {
  catalog <- stac_catalog(id = "cat", description = "d")
  catalog <- add_item(catalog, mk_point_item("item-001"))
  catalog <- add_item(catalog, mk_point_item("item-002"))
  remove_item(catalog, item_id = "item-001")
}

scenarios[["add_item_assets"]] <- function() {
  col <- mk_collection()
  item <- mk_point_item("item-001")
  item <- add_asset(item, key = "red", href = "red.tif", type = "image/tiff", roles = "data", title = "Red Band")
  item <- add_eo_extension(item, bands = list(eo_band(name = "B4", common_name = "red")), asset_key = "red")
  col <- add_item(col, item)
  add_item_assets(col)
}

# ---- EO extension -------------------------------------------------------------
scenarios[["eo_band_min"]] <- function() {
  eo_band(name = "B4", common_name = "red")
}

scenarios[["eo_band_full"]] <- function() {
  eo_band(
    name = "B2", common_name = "blue", description = "Blue band (0.45-0.51)",
    center_wavelength = 0.490, full_width_half_max = 0.065, solar_illumination = 1959.66
  )
}

scenarios[["add_eo_extension_cloud"]] <- function() {
  add_eo_extension(mk_point_item(), cloud_cover = 12.5, snow_cover = 3.1)
}

scenarios[["add_eo_extension_bands_props"]] <- function() {
  bands <- list(
    eo_band(name = "B4", common_name = "red", center_wavelength = 0.665, full_width_half_max = 0.038),
    eo_band(name = "B3", common_name = "green", center_wavelength = 0.560, full_width_half_max = 0.043)
  )
  suppressWarnings(add_eo_extension(mk_point_item(), bands = bands, cloud_cover = 5.2))
}

scenarios[["add_eo_extension_bands_asset"]] <- function() {
  item <- add_asset(mk_point_item(), key = "visual", href = "https://example.com/LC08_visual.tif",
                    type = "image/tiff; application=geotiff", roles = c("data"))
  bands <- list(
    eo_band(name = "B4", common_name = "red", center_wavelength = 0.665, full_width_half_max = 0.038),
    eo_band(name = "B3", common_name = "green", center_wavelength = 0.560, full_width_half_max = 0.043),
    eo_band(name = "B2", common_name = "blue", center_wavelength = 0.490, full_width_half_max = 0.038)
  )
  add_eo_extension(item, bands = bands, cloud_cover = 5.2, asset_key = "visual")
}

scenarios[["eo_bands_landsat_oli"]] <- function() {
  landsat_oli_bands(include_thermal = TRUE)
}

scenarios[["eo_bands_sentinel2"]] <- function() {
  sentinel2_msi_bands()
}

scenarios[["eo_bands_worldview3"]] <- function() {
  worldview3_bands()
}

scenarios[["eo_bands_skysat"]] <- function() {
  skysat_bands()
}

scenarios[["eo_bands_planetscope"]] <- function() {
  planetscope_bands()
}

# ---- Raster extension -----------------------------------------------------------
scenarios[["raster_band_full"]] <- function() {
  raster_band(
    nodata = 0, data_type = "uint16", unit = "1",
    statistics = raster_statistics(minimum = 1, maximum = 10000, mean = 2500, stddev = 1200, valid_percent = 99.5),
    sampling = "area", bits_per_sample = 16L, spatial_resolution = 30,
    scale = 0.0001, offset = -0.1,
    histogram = raster_histogram(count = 5L, min = 0, max = 100, buckets = c(1500L, 3200L, 4100L, 2800L, 1400L))
  )
}

scenarios[["raster_band_defaults"]] <- function() {
  raster_band()
}

scenarios[["raster_statistics"]] <- function() {
  raster_statistics(minimum = 0, maximum = 10000, mean = 2500, stddev = 1200, valid_percent = 99.8)
}

scenarios[["raster_histogram"]] <- function() {
  raster_histogram(count = 5L, min = 0, max = 100, buckets = c(1500L, 3200L, 4100L, 2800L, 1400L))
}

scenarios[["add_raster_extension_asset"]] <- function() {
  item <- add_asset(mk_point_item(), key = "data", href = "https://example.com/image.tif",
                    type = "image/tiff; application=geotiff", roles = c("data"))
  bands <- list(
    raster_band(nodata = 0, data_type = "uint16", spatial_resolution = 10, scale = 0.0001, offset = -0.1,
                statistics = raster_statistics(minimum = 1, maximum = 10000, mean = 2500, stddev = 1200, valid_percent = 99.5)),
    raster_band(nodata = 0, data_type = "uint16", spatial_resolution = 10, scale = 0.0001, offset = -0.1)
  )
  add_raster_extension(item, bands = bands, asset_key = "data")
}

scenarios[["add_raster_extension_props"]] <- function() {
  item <- add_asset(mk_point_item(), key = "data", href = "https://example.com/image.tif",
                    type = "image/tiff; application=geotiff", roles = c("data"))
  bands <- list(raster_band(nodata = 0, data_type = "uint16", spatial_resolution = 30, scale = 0.0001))
  # asset also has bands so the properties-bands warning does not fire
  item <- add_raster_extension(item, bands = bands, asset_key = "data")
  suppressWarnings(add_raster_extension(item, bands = list(raster_band(data_type = "uint16"))))
}

scenarios[["add_eo_and_raster_merged"]] <- function() {
  item <- add_asset(mk_point_item(), key = "visual", href = "https://example.com/v.tif",
                    type = "image/tiff; application=geotiff", roles = c("data"))
  item <- add_eo_extension(item,
    bands = list(eo_band(name = "B4", common_name = "red", center_wavelength = 0.665, full_width_half_max = 0.038, description = "Red band (0.64-0.67)")),
    cloud_cover = 5.2, asset_key = "visual")
  item <- add_raster_extension(item,
    bands = list(raster_band(nodata = 0, data_type = "uint16", spatial_resolution = 30, scale = 0.0001)),
    asset_key = "visual")
  item
}

scenarios[["bands_from_terra"]] <- function() {
  r <- terra::rast(nrows = 10, ncols = 20, xmin = 712710, ymin = 5487090, xmax = 713310, ymax = 5487390,
                   crs = "EPSG:32612", nlyrs = 2)
  terra::values(r) <- rep(1:200, length.out = 400)
  f <- file.path(DATA_DIR, "test.tif")
  terra::writeRaster(r, f, overwrite = TRUE)
  bands_from_terra(terra::rast(f), calculate_statistics = TRUE, sample_size = NULL)
}

scenarios[["band_from_file"]] <- function() {
  f <- file.path(DATA_DIR, "test.tif")
  if (!file.exists(f)) {
    r <- terra::rast(nrows = 10, ncols = 20, xmin = 712710, ymin = 5487090, xmax = 713310, ymax = 5487390,
                     crs = "EPSG:32612")
    terra::values(r) <- 1:200
    terra::writeRaster(r, f, overwrite = TRUE)
  }
  band_from_file(f)
}

# ---- Projection extension -------------------------------------------------------
scenarios[["add_projection_extension_full"]] <- function() {
  add_projection_extension(
    mk_point_item("utm-scene"),
    code = "EPSG:32612",
    wkt2 = "PROJCRS[\"WGS 84 / UTM zone 12N\"]",
    projjson = list(type = "ProjectedCRS", name = "WGS 84 / UTM zone 12N"),
    geometry = list(type = "Polygon", coordinates = list(list(
      c(712710, 5487090), c(999480, 5487090), c(999480, 5654790), c(712710, 5654790), c(712710, 5487090)
    ))),
    bbox = c(712710, 5487090, 999480, 5654790),
    centroid = c(lat = 51.05, lon = -114.07),
    shape = c(5558, 9559),
    transform = c(30, 0, 712710, 0, -30, 5654790)
  )
}

scenarios[["add_projection_extension_asset"]] <- function() {
  item <- add_asset(mk_point_item(), key = "swir", href = "https://example.com/swir.tif",
                    type = "image/tiff; application=geotiff")
  add_projection_extension(item, shape = c(2779, 4780), transform = c(60, 0, 712710, 0, -60, 5654790), asset_key = "swir")
}

# ---- Classification extension ---------------------------------------------------
scenarios[["classification_class_full"]] <- function() {
  classification_class(value = 2L, name = "urban", title = "Urban / Built-up",
                       description = "Impervious surfaces.", color_hint = "FF0000",
                       percentage = 12.4, count = 24800L)
}

scenarios[["classification_class_nodata"]] <- function() {
  classification_class(value = 0L, name = "nodata", nodata = TRUE)
}

scenarios[["classification_bitfield"]] <- function() {
  classification_bitfield(
    offset = 0L, length = 1L,
    classes = list(
      classification_class(value = 0L, name = "no_fill", title = "No Fill"),
      classification_class(value = 1L, name = "fill", title = "Fill")
    ),
    name = "fill", description = "Image or fill data", roles = c("data")
  )
}

scenarios[["add_classification_extension_classes_asset"]] <- function() {
  item <- add_asset(mk_polygon_item("lc-2023"), key = "landcover", href = "https://example.com/lc-2023.tif",
                    type = "image/tiff; application=geotiff", roles = c("data"))
  classes <- list(
    classification_class(value = 1L, name = "water", title = "Water", color_hint = "0000FF"),
    classification_class(value = 2L, name = "urban", title = "Urban", color_hint = "FF0000"),
    classification_class(value = 0L, name = "nodata", nodata = TRUE)
  )
  add_classification_extension(item, classes = classes, asset_key = "landcover")
}

scenarios[["add_classification_extension_bitfields_props"]] <- function() {
  bitfields <- list(classification_bitfield(
    offset = 0L, length = 1L,
    classes = list(
      classification_class(value = 0L, name = "no_fill"),
      classification_class(value = 1L, name = "fill")
    ),
    name = "fill", description = "Image or fill data"
  ))
  add_classification_extension(mk_point_item(), bitfields = bitfields)
}

# ---- Point cloud extension ------------------------------------------------------
scenarios[["pc_schema"]] <- function() {
  list(pc_schema("X", size = 8L, type = "floating"), pc_schema("Intensity", size = 2L, type = "unsigned"))
}

scenarios[["pc_statistic"]] <- function() {
  pc_statistic("Z", position = 2L, average = 500.1, count = 10653336L, maximum = 615.26,
               minimum = 406.14, stddev = 10.5, variance = 110.25)
}

scenarios[["add_pointcloud_extension_full"]] <- function() {
  add_pointcloud_extension(
    mk_polygon_item("autzen"),
    count = 10653336L, type = "lidar", density = 4.664,
    schemas = list(
      pc_schema("X", size = 8L, type = "floating"),
      pc_schema("Y", size = 8L, type = "floating"),
      pc_schema("Z", size = 8L, type = "floating"),
      pc_schema("Intensity", size = 2L, type = "unsigned")
    ),
    statistics = list(pc_statistic("Z", position = 2L, minimum = 406.14, maximum = 615.26))
  )
}

scenarios[["add_pointcloud_extension_asset"]] <- function() {
  item <- add_asset(mk_polygon_item("autzen"), key = "lidar", href = "https://example.com/autzen.laz",
                    type = "application/vnd.laszip", roles = c("data"))
  add_pointcloud_extension(item, count = 10653336L, type = "lidar",
                           schemas = list(pc_schema("X", size = 8L, type = "floating")),
                           asset_key = "lidar")
}

# ---- Datacube extension ---------------------------------------------------------
scenarios[["cube_dimension_spatial"]] <- function() {
  cube_dimension(type = "spatial", axis = "x", extent = c(0, 100), values = c(0, 100), step = 1,
                 unit = "m", reference_system = 32612, description = "x axis",
                 geometry_types = c("Point"), bbox = c(0, 0, 100, 100))
}

scenarios[["cube_dimension_temporal"]] <- function() {
  cube_dimension(type = "temporal", extent = list("2020-01-01T00:00:00Z", NULL),
                 values = c("2020-01-01T00:00:00Z"))
}

scenarios[["cube_dimension_geometry"]] <- function() {
  cube_dimension(type = "geometry", bbox = c(0, 0, 100, 100),
                 geometry_types = c("Point", "Polygon"), axes = c("x", "y"),
                 reference_system = 32612, description = "footprint")
}

scenarios[["cube_variable"]] <- function() {
  cube_variable(dimensions = c("x", "t"), type = "data", extent = c(0, 100), values = c(0, 100),
                unit = "m", nodata = 0, data_type = "uint16", description = "temperature")
}

scenarios[["add_datacube_extension"]] <- function() {
  add_datacube_extension(
    mk_point_item("cube-item"),
    dimensions = list(
      x = cube_dimension(type = "spatial", axis = "x", extent = c(0, 100)),
      t = cube_dimension(type = "temporal", extent = list("2020-01-01T00:00:00Z", NULL))
    ),
    variables = list(
      temp = cube_variable(dimensions = c("x", "t"), type = "data", data_type = "float32", nodata = -9999)
    )
  )
}

scenarios[["add_datacube_extension_asset"]] <- function() {
  item <- add_asset(mk_point_item(), key = "data", href = "https://example.com/cube.nc",
                    type = "application/x-netcdf", roles = c("data"))
  add_datacube_extension(item,
    variables = list(temp = cube_variable(dimensions = c("x"), type = "data", data_type = "float32")),
    asset_key = "data")
}

# ---- Table extension ------------------------------------------------------------
scenarios[["table_column"]] <- function() {
  table_column(name = "id", description = "Identifier", type = "integer")
}

scenarios[["add_table_extension_props"]] <- function() {
  add_table_extension(
    mk_point_item("tbl"),
    columns = list(
      table_column(name = "id", description = "Identifier", type = "integer"),
      table_column(name = "value", type = "float64")
    ),
    primary_geometry = "geometry",
    row_count = 100
  )
}

scenarios[["add_table_extension_asset"]] <- function() {
  item <- add_asset(mk_point_item(), key = "data", href = "https://example.com/t.parquet",
                    type = "application/octet-stream", roles = c("data"))
  add_table_extension(item,
    columns = list(table_column(name = "id", type = "integer")),
    storage_options = list(io = "s3"),
    asset_key = "data")
}

# ---- Vector extension -----------------------------------------------------------
scenarios[["add_vector_extension"]] <- function() {
  add_vector_extension(mk_polygon_item("vec"), geometry_types = c("Point", "Polygon"),
                       mmu = 1.0, mmw = 2.5, reference_scale = 1000)
}

# ---- Render extension -----------------------------------------------------------
scenarios[["render_object_full"]] <- function() {
  render_object(
    assets = c("visual"), title = "RGB", rescale = list(c(0, 255)), nodata = 0,
    colormap_name = "viridis", colormap = list("0" = "#000000"),
    color_formula = "x", resampling = "nearest", expression = "b1",
    minmax_zoom = c(10L, 14L), bidx = c(1L)
  )
}

scenarios[["add_render_extension_item"]] <- function() {
  add_render_extension(mk_point_item(), renders = list(
    rgb = render_object(assets = c("visual"), title = "RGB", rescale = list(c(0, 255)), nodata = 0)
  ))
}

scenarios[["add_render_extension_collection"]] <- function() {
  add_render_extension(mk_collection(), renders = list(
    rgb = render_object(assets = c("visual"), colormap_name = "viridis")
  ))
}

# ---- Scientific extension -------------------------------------------------------
scenarios[["scientific_publication"]] <- function() {
  scientific_publication(doi = "10.1000/abc", citation = "A publication citation")
}

scenarios[["add_scientific_extension_doi"]] <- function() {
  add_scientific_extension(mk_point_item(), doi = "10.1000/xyz123")
}

scenarios[["add_scientific_extension_full"]] <- function() {
  add_scientific_extension(
    mk_point_item(),
    doi = "10.1000/xyz123",
    citation = "Some citation",
    publications = list(scientific_publication(doi = "10.1000/abc", citation = "Pub citation"))
  )
}

# ---- sf / terra integrations ----------------------------------------------------
mk_sf_polygon <- function() {
  sf::st_as_sf(
    data.frame(name = "study-area"),
    sf::st_sfc(sf::st_polygon(list(matrix(c(-105.5, 39.5, -104.5, 39.5, -104.5, 40.5, -105.5, 40.5, -105.5, 39.5), ncol = 2, byrow = TRUE))), crs = 4326)
  )
}

scenarios[["geometry_from_sf"]] <- function() {
  geometry_from_sf(mk_sf_polygon())
}

scenarios[["item_from_sf"]] <- function() {
  sf_obj <- mk_sf_polygon()
  gj <- file.path(DATA_DIR, "boundary.geojson")
  sf::st_write(sf_obj, gj, driver = "GeoJSON", quiet = TRUE, delete_dsn = TRUE)
  item_from_sf(sf_obj, id = "study-area", datetime = "2023-01-01T00:00:00Z",
               properties = list(title = "Study Area Boundary"), href = gj)
}

scenarios[["item_from_sf_multi"]] <- function() {
  geom <- sf::st_sfc(
    sf::st_polygon(list(matrix(c(-105.5, 39.5, -104.5, 39.5, -104.5, 40.5, -105.5, 40.5, -105.5, 39.5), ncol = 2, byrow = TRUE))),
    sf::st_polygon(list(matrix(c(-100, 45, -99, 45, -99, 46, -100, 46, -100, 45), ncol = 2, byrow = TRUE))),
    crs = 4326
  )
  both <- sf::st_as_sf(data.frame(name = c("a", "b")), geom)
  item <- item_from_sf(both, id = "multi", datetime = "2023-01-01T00:00:00Z")
  # dump the unioned geometry for the python side to reuse
  u <- sf::st_union(sf::st_geometry(both))
  writeLines(geojsonsf::sfc_geojson(u), file.path(DATA_DIR, "multi_geom.json"))
  item
}

scenarios[["item_from_sf_mixed_geometry"]] <- function() {
  geom <- sf::st_sfc(
    sf::st_polygon(list(matrix(c(-105.5, 39.5, -104.5, 39.5, -104.5, 40.5, -105.5, 40.5, -105.5, 39.5), ncol = 2, byrow = TRUE))),
    sf::st_point(c(-100, 50)),
    crs = 4326
  )
  both <- sf::st_as_sf(data.frame(name = c("a", "b")), geom)
  item_from_sf(both, id = "mixed", datetime = "2023-01-01T00:00:00Z")
}

scenarios[["item_from_terra"]] <- function() {
  r <- terra::rast(nrows = 10, ncols = 20, xmin = 712710, ymin = 5487090, xmax = 713310, ymax = 5487390,
                   crs = "EPSG:32612", nlyrs = 2)
  terra::values(r) <- rep(1:200, length.out = 400)
  f <- file.path(DATA_DIR, "scene.tif")
  terra::writeRaster(r, f, overwrite = TRUE)
  item_from_terra(terra::rast(f), href = f, datetime = "2023-06-15T10:30:00Z",
                  properties = list(platform = "landsat-8"))
}

scenarios[["item_from_terra_wgs84"]] <- function() {
  r <- terra::rast(nrows = 5, ncols = 5, xmin = -105.5, ymin = 39.5, xmax = -104.5, ymax = 40.5, crs = "EPSG:4326")
  terra::values(r) <- 1:25
  f <- file.path(DATA_DIR, "wgs84.tif")
  terra::writeRaster(r, f, overwrite = TRUE)
  item_from_terra(terra::rast(f), href = f, id = "wgs84-item", datetime = "2023-06-15T10:30:00Z")
}

scenarios[["thumbnail_from_sf"]] <- function() {
  p <- file.path(DATA_DIR, "thumb_sf.png")
  thumbnail_from_sf(mk_sf_polygon(), path = p, title = "Study area thumbnail")
}

scenarios[["thumbnail_from_terra"]] <- function() {
  r <- terra::rast(nrows = 5, ncols = 5, xmin = -105.5, ymin = 39.5, xmax = -104.5, ymax = 40.5, crs = "EPSG:4326")
  terra::values(r) <- 1:25
  p <- file.path(DATA_DIR, "thumb_terra.png")
  suppressWarnings(thumbnail_from_terra(r, path = p))
}

scenarios[["preview_from_terra"]] <- function() {
  r <- terra::rast(nrows = 5, ncols = 5, xmin = -105.5, ymin = 39.5, xmax = -104.5, ymax = 40.5, crs = "EPSG:4326")
  terra::values(r) <- 1:25
  p <- file.path(DATA_DIR, "thumb_terra.png")
  suppressWarnings(preview_from_terra(r, path = p))
}

# ---- read / write ---------------------------------------------------------------
scenarios[["write_read_roundtrip_item"]] <- function() {
  item <- add_eo_extension(add_asset(mk_polygon_item(), key = "visual",
                                     href = "https://example.com/v.tif", type = "image/tiff; application=geotiff",
                                     roles = c("data")),
                           bands = list(eo_band(name = "B4", common_name = "red", center_wavelength = 0.665)),
                           cloud_cover = 5.2, asset_key = "visual")
  f <- file.path(DATA_DIR, "roundtrip_item.json")
  write_item(item, f, overwrite = TRUE)
  read_stac(f)
}

scenarios[["write_stac_tree"]] <- function() {
  catalog <- stac_catalog(id = "root-cat", description = "Root catalog", title = "Root")
  child <- stac_catalog(id = "child-cat", description = "Child catalog")
  col <- mk_collection("col-1")
  item <- mk_point_item("item-001")
  item <- add_asset(item, key = "data", href = "https://example.com/data.tif", type = "image/tiff; application=geotiff", roles = c("data"))
  col <- add_item(col, item)
  child <- add_child(child, col)
  catalog <- add_child(catalog, child)
  out <- file.path(OUT_DIR, "r_out")
  unlink(out, recursive = TRUE)
  write_stac(catalog, out, catalog_type = "self-contained", overwrite = TRUE)
  # record the tree
  files <- list.files(out, recursive = TRUE, full.names = TRUE)
  files <- files[!dir.exists(files)]
  rel <- sub(paste0("^", out, "/"), "", files)
  setNames(lapply(files, function(f) jsonlite::fromJSON(f, simplifyVector = FALSE)), rel)
}

scenarios[["write_stac_tree_relative"]] <- function() {
  catalog <- stac_catalog(id = "root-cat", description = "Root catalog")
  item <- mk_point_item("item-001")
  catalog <- add_item(catalog, item)
  out <- file.path(OUT_DIR, "r_out_rel")
  unlink(out, recursive = TRUE)
  write_stac(catalog, out, catalog_type = "relative", base_url = "https://example.com/stac", overwrite = TRUE)
  files <- list.files(out, recursive = TRUE, full.names = TRUE)
  files <- files[!dir.exists(files)]
  rel <- sub(paste0("^", out, "/"), "", files)
  setNames(lapply(files, function(f) jsonlite::fromJSON(f, simplifyVector = FALSE)), rel)
}

scenarios[["write_catalog_file"]] <- function() {
  catalog <- add_self_link(stac_catalog(id = "c", description = "d"), "https://example.com/c/catalog.json")
  f <- file.path(OUT_DIR, "r_out", "single_catalog.json")
  dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
  write_catalog(catalog, f, overwrite = TRUE)
  jsonlite::fromJSON(f, simplifyVector = FALSE)
}

scenarios[["write_item_file"]] <- function() {
  f <- file.path(OUT_DIR, "r_out", "single_item.json")
  dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
  write_item(mk_point_item("single"), f, overwrite = TRUE)
  jsonlite::fromJSON(f, simplifyVector = FALSE)
}

scenarios[["read_stac_catalog"]] <- function() {
  f <- file.path(OUT_DIR, "r_out", "single_catalog.json")
  if (!file.exists(f)) {
    catalog <- add_self_link(stac_catalog(id = "c", description = "d"), "https://example.com/c/catalog.json")
    dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
    write_catalog(catalog, f, overwrite = TRUE)
  }
  read_stac(f)
}

# ---- validation -----------------------------------------------------------------
scenarios[["validate_stac_item_ok"]] <- function() {
  validate_stac(mk_polygon_item())
}

scenarios[["validate_stac_item_bad"]] <- function() {
  item <- mk_point_item("bad")
  item$properties$datetime <- "not-a-date"
  tryCatch(validate_stac(item), error = function(e) stac_validation(errors = conditionMessage(e)))
}

scenarios[["validate_stac_collection_ok"]] <- function() {
  validate_stac(mk_collection())
}

scenarios[["validate_stac_catalog_ok"]] <- function() {
  validate_stac(stac_catalog(id = "c", description = "d"))
}

scenarios[["validate_stac_schema_item"]] <- function() {
  validate_stac_schema(add_eo_extension(mk_polygon_item(), cloud_cover = 5.2))
}

scenarios[["validate_stac_schema_collection"]] <- function() {
  validate_stac_schema(mk_collection())
}

# ---- lidR integrations (need lidR; the python side reads the same files with laspy)
scenarios[["item_from_lidr"]] <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) stop("lidR not installed")
  item_from_lidr(file.path(DATA_DIR, "test.las"), datetime = "2023-06-15T10:30:00Z")
}

scenarios[["item_from_lidr_datetime_from_header"]] <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) stop("lidR not installed")
  # datetime = NULL -> derived from the LAS header creation year/day-of-year
  item_from_lidr(file.path(DATA_DIR, "test.las"))
}

scenarios[["item_from_lidr_stats"]] <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) stop("lidR not installed")
  f <- file.path(DATA_DIR, "test.las")
  item_from_lidr(
    lidR::readLAS(f), href = f, calculate_statistics = TRUE,
    datetime = "2023-06-15T10:30:00Z"
  )
}

scenarios[["items_from_lascatalog"]] <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) stop("lidR not installed")
  # NB: a fixed datetime must go through datetime_from_filename; a bare
  # `datetime = ...` would partial-match the datetime_from_filename formal.
  unname(items_from_lascatalog(
    file.path(DATA_DIR, "las_ctg"),
    datetime_from_filename = function(f) "2023-06-15T10:30:00Z"
  ))
}

scenarios[["schemas_from_lidr"]] <- function() {
  if (!requireNamespace("lidR", quietly = TRUE)) stop("lidR not installed")
  schemas_from_lidr(file.path(DATA_DIR, "test.las"))
}

# ---- run R scenarios ------------------------------------------------------------
results <- list()
for (name in names(scenarios)) {
  res <- tryCatch(
    {
      obj <- scenarios[[name]]()
      list(ok = TRUE, value = ser_result(obj))
    },
    error = function(e) list(ok = FALSE, value = list(`__error__` = conditionMessage(e)))
  )
  results[[name]] <- res
  cat(sprintf("%-45s %s\n", name, if (res$ok) "OK" else paste("ERROR:", res$value$`__error__`)))
}

meta <- list(
  r_version = R.version.string,
  stacbuildr_version = as.character(utils::packageVersion("stacbuildr")),
  jsonlite = as.character(utils::packageVersion("jsonlite"))
)
writeLines(
  jsonlite::toJSON(list(meta = meta, results = results), auto_unbox = TRUE, pretty = TRUE,
                   null = "null", digits = I(15)),
  file.path(OUT_DIR, "r_results.json")
)
cat("Wrote", file.path(OUT_DIR, "r_results.json"), "\n")

# ---- run pystac side ------------------------------------------------------------
PY_BIN <- Sys.getenv("STACBUILDR_PYTHON", unset = path.expand("~/.virtualenvs/pystac/bin/python"))
if (!file.exists(PY_BIN)) {
  stop("Python interpreter not found: ", PY_BIN,
       "\nSet STACBUILDR_PYTHON to a python with pystac installed.", call. = FALSE)
}
PY_SCRIPT <- file.path(DEV_DIR, "compare-with-pystac.py")
cat("Running pystac side with:", PY_BIN, "\n")
status <- system2(PY_BIN, args = c(shQuote(PY_SCRIPT), "--data-dir", shQuote(DATA_DIR),
                                   "--r-out", shQuote(R_OUT), "--out", shQuote(OUT_DIR)))
if (!identical(status, 0L)) {
  stop("compare-with-pystac.py failed with exit status ", status, call. = FALSE)
}

# ---- order-insensitive JSON diff --------------------------------------------------
mask_dirs <- unique(c(OUT_DIR, DATA_DIR, R_OUT,
                      normalizePath(c(OUT_DIR, DATA_DIR, R_OUT), mustWork = FALSE)))
# longest first so "/private/tmp/..." is masked before "/tmp/..."
mask_dirs <- mask_dirs[order(nchar(mask_dirs), decreasing = TRUE)]

mask_strings <- function(x) {
  if (is.character(x)) {
    for (d in mask_dirs) x <- gsub(d, "<DIR>", x, fixed = TRUE)
    # WKT strings differ cosmetically between PROJ consumers (sf/terra vs
    # pyproj/rasterio): same CRS, different whitespace/quoting. Mask them.
    wkt_roots <- c("PROJCRS[", "DERIVEDPROJCRS[", "GEOGCRS[", "GEODCRS[",
                   "PROJCS[", "GEOGCS[", "VERTCRS[", "COMPOUNDCRS[",
                   "BOUNDCRS[", "ENGCRS[", "LOCAL_CS[")
    if (any(startsWith(x, wkt_roots))) return("<WKT>")
    return(x)
  }
  if (is.list(x)) return(lapply(x, mask_strings))
  x
}

sort_keys_rec <- function(x) {
  if (is.list(x)) {
    x <- lapply(x, sort_keys_rec)
    n <- names(x)
    if (!is.null(n)) x <- x[order(n)]
  }
  x
}

canon <- function(x) {
  jsonlite::toJSON(sort_keys_rec(mask_strings(x)), auto_unbox = TRUE, null = "null", digits = I(15))
}

is_dict <- function(x) is.list(x) && !is.null(names(x)) && all(nzchar(names(x)))

num_eq <- function(a, b) {
  if (is.logical(a) || is.logical(b)) return(identical(a, b))
  if (is.numeric(a) && is.numeric(b)) {
    return(isTRUE(a == b) || abs(a - b) <= 1e-9 * max(1, abs(a), abs(b)))
  }
  identical(a, b)
}

diff_json <- function(a, b, path = "", ignore = character()) {
  res <- list()
  add <- function(kind, p, val) res[[length(res) + 1L]] <<- list(kind = kind, path = p, value = val)
  sub_path <- function(k) if (nzchar(path)) paste0(path, ".", k) else k
  if (path %in% ignore) return(res)

  if (is_dict(a) && is_dict(b)) {
    for (k in names(a)) if (!k %in% names(b)) add("missing_in_pystac", sub_path(k), a[[k]])
    for (k in names(b)) if (!k %in% names(a)) add("extra_in_pystac", sub_path(k), b[[k]])
    for (k in intersect(names(a), names(b))) {
      res <- c(res, diff_json(a[[k]], b[[k]], sub_path(k), ignore))
    }
  } else if (is.list(a) && is.list(b) && is.null(names(a)) && is.null(names(b))) {
    is_links <- length(a) > 0 && length(b) > 0 &&
      all(vapply(a, function(x) is_dict(x) && "rel" %in% names(x), logical(1))) &&
      all(vapply(b, function(x) is_dict(x) && "rel" %in% names(x), logical(1)))
    if (is_links) {
      ca <- sort(vapply(a, canon, character(1)))
      cb <- sort(vapply(b, canon, character(1)))
      if (!identical(ca, cb)) {
        for (item in setdiff(cb, ca)) add("extra_in_pystac", path, jsonlite::fromJSON(item, simplifyVector = FALSE))
        for (item in setdiff(ca, cb)) add("missing_in_pystac", path, jsonlite::fromJSON(item, simplifyVector = FALSE))
      }
      return(res)
    }
    if (length(a) != length(b)) add("length", path, list(length(a), length(b)))
    for (i in seq_len(min(length(a), length(b)))) {
      res <- c(res, diff_json(a[[i]], b[[i]], paste0(path, "[", i, "]"), ignore))
    }
    if (length(a) == length(b) && length(a) > 0) {
      ca <- sort(vapply(a, canon, character(1)))
      cb <- sort(vapply(b, canon, character(1)))
      if (!identical(ca, cb) && identical(sort(ca), sort(cb))) add("reordered_only", path, NULL)
    }
  } else {
    if (!num_eq(a, b)) add("value", path, list(a, b))
  }
  res
}

# ---- compare ----------------------------------------------------------------------
r_res <- jsonlite::fromJSON(file.path(OUT_DIR, "r_results.json"), simplifyVector = FALSE)
p_res <- jsonlite::fromJSON(file.path(OUT_DIR, "py_results.json"), simplifyVector = FALSE)
R <- r_res$results
P <- p_res$results

IGNORE <- list(
  item_from_terra = "properties.proj:wkt2",
  item_from_terra_wgs84 = "properties.proj:wkt2"
)
NOTES <- c(
  item_from_terra = "proj:wkt2 ignored (terra WKT vs rasterio WKT string formats differ environmentally)",
  item_from_terra_wgs84 = "proj:wkt2 ignored (not emitted for EPSG:4326 anyway)"
)
ANNOTATIONS <- c(
  add_link_catalog = "pystac auto-adds a `root` link when a `self` link is set on a Catalog; stacbuildr's add_self_link/add_link does not",
  add_self_link_root_link = "pystac auto-adds a `root` link when `self` is set; stacbuildr does not",
  stac_catalog_full = "pystac auto-adds `root` link (with catalog title) when `self` link present; stacbuildr keeps only the explicit links",
  stac_collection_full = "pystac auto-adds `root` link when `self` set; stacbuildr keeps only explicit links",
  write_catalog_file = "pystac set_self_href also injects a `root` link; stacbuildr write_catalog writes only the links on the object",
  add_item_collection = "pystac auto-adds `root` link on the collection when `self` set; plus pystac emits empty `stac_extensions: []` on Items (stacbuildr omits it when empty)",
  get_items_get_children = "pystac add_item/add_child inject parent/root links into the child objects in memory; stacbuildr stores children unchanged and adds links at write time; plus empty stac_extensions[] on items",
  read_stac_catalog = "pystac read_file injects `self`+`root` links from the file path; stacbuildr read_stac preserves the links stored in the file",
  write_read_roundtrip_item = "pystac read_file injects a `self` link from the file path on read; stacbuildr read_stac does not",
  item_from_terra = "proj:wkt2 ignored (terra vs rasterio WKT)",
  item_from_terra_wgs84 = "proj:wkt2 ignored",
  add_projection_extension_asset = "pystac emits `proj:code: null` when only shape/transform are set; stacbuildr omits null fields",
  add_scientific_extension_full = "pystac adds a `cite-as` link for each publication DOI too; stacbuildr adds one only for the item-level sci:doi",
  validate_stac_collection_ok = "pystac schema validation rejects 2-element extent.spatial.bbox (STAC 1.1.0 schema oneOf allows exactly 1 or >=3 bboxes); stacbuildr validate_stac is structural-only. validate_stac_schema agrees with pystac (both invalid)"
)
NATIVE_NOTE <- "pystac-native extension output (older schema version than stacbuildr targets) — recorded for the version-gap analysis"

rows <- list()
all_names <- sort(unique(c(names(R), names(P))))
for (name in all_names) {
  rv <- R[[name]]
  pv <- P[[name]]
  if (is.null(rv)) {
    rows[[name]] <- list(status = "PY-ONLY",
                         summary = if (grepl("_native$", name)) NATIVE_NOTE else "scenario only in pystac harness",
                         diffs = list(), r = NULL, py = NULL)
    next
  }
  if (is.null(pv)) {
    rows[[name]] <- list(status = "R-ONLY", summary = "scenario only in R harness",
                         diffs = list(), r = rv$value, py = NULL)
    next
  }
  if (!isTRUE(rv$ok) && !isTRUE(pv$ok)) {
    rows[[name]] <- list(status = "BOTH-ERROR",
                         summary = paste0("R: ", rv$value$`__error__`, " | pystac: ", pv$value$`__error__`),
                         diffs = list(), r = rv$value, py = pv$value)
    next
  }
  if (!isTRUE(rv$ok)) {
    rows[[name]] <- list(status = "ERROR-R", summary = rv$value$`__error__`, diffs = list(),
                         r = rv$value, py = pv$value)
    next
  }
  if (!isTRUE(pv$ok)) {
    rows[[name]] <- list(status = "ERROR-PY", summary = pv$value$`__error__`, diffs = list(),
                         r = rv$value, py = pv$value)
    next
  }
  a <- mask_strings(rv$value)
  b <- mask_strings(pv$value)
  if (startsWith(name, "validate_")) {
    av <- a$valid
    bv <- b$valid
    if (identical(av, bv)) {
      rows[[name]] <- list(status = paste0("MATCH (valid=", av, ")"),
                           summary = sprintf("error counts R=%d pystac=%d (messages differ by design)",
                                             length(a$errors %||% list()), length(b$errors %||% list())),
                           diffs = list(), r = a, py = b)
    } else {
      rows[[name]] <- list(status = "DIFF",
                           summary = sprintf("valid: R=%s pystac=%s; R errors=%s; pystac errors=%s",
                                             av, bv,
                                             paste(unlist(a$errors), collapse = " | "),
                                             paste(unlist(b$errors), collapse = " | ")),
                           diffs = list(), r = a, py = b)
    }
    next
  }
  ig <- IGNORE[name]
  d <- diff_json(a, b, ignore = if (is.null(ig[[1]])) character() else ig[[1]])
  if (length(d) == 0) {
    rows[[name]] <- list(status = "MATCH", summary = "", diffs = d, r = a, py = b)
  } else {
    minor <- all(vapply(d, function(x) {
      (x$kind %in% c("extra_in_pystac", "reordered_only")) &&
        (x$kind == "reordered_only" ||
         (grepl("stac_extensions$", x$path) && length(x$value) == 0))
    }, logical(1)))
    real <- Filter(function(x) x$kind != "reordered_only", d)
    reordered <- Filter(function(x) x$kind == "reordered_only", d)
    summary <- paste(vapply(real[seq_len(min(6, length(real)))], function(x) {
      sprintf("%s %s %s", x$kind, x$path,
              if (is.null(x$value)) "" else substr(jsonlite::toJSON(x$value, auto_unbox = TRUE, null = "null"), 1, 80))
    }, character(1)), collapse = "; ")
    if (length(real) > 6) summary <- paste0(summary, sprintf("; ... (%d more)", length(real) - 6))
    if (length(reordered) > 0) {
      summary <- paste0(summary, " [arrays reordered only: ",
                        paste(vapply(reordered, `[[`, character(1), "path"), collapse = ", "), "]")
    }
    note <- ANNOTATIONS[name]
    if (!is.na(note) && nzchar(note)) summary <- paste0(summary, " — NOTE: ", note)
    rows[[name]] <- list(status = if (minor) "MATCH*" else "DIFF", summary = summary,
                         diffs = d, r = a, py = b)
  }
}

# ---- report -----------------------------------------------------------------------
status_rank <- c("MATCH" = 0, "MATCH*" = 1, "DIFF" = 2, "ERROR-R" = 3, "ERROR-PY" = 3,
                 "BOTH-ERROR" = 4, "R-ONLY" = 5, "PY-ONLY" = 5)
rank_of <- function(s) {
  base <- strsplit(s, " ", fixed = TRUE)[[1]][1]
  r <- status_rank[base]
  if (is.na(r)) 9 else r
}
ord <- order(vapply(names(rows), rank_of, numeric(1)), names(rows))
rows <- rows[ord]

n_match <- sum(vapply(rows, function(x) startsWith(x$status, "MATCH"), logical(1)))
n_diff <- sum(vapply(rows, function(x) x$status == "DIFF", logical(1)))
n_err <- sum(vapply(rows, function(x) grepl("ERROR", x$status), logical(1)))

lines <- c(
  "# stacbuildr vs pystac — JSON output comparison",
  "",
  sprintf("- R: %s, stacbuildr %s, jsonlite %s", r_res$meta$r_version,
          r_res$meta$stacbuildr_version, r_res$meta$jsonlite),
  sprintf("- Python: pystac %s (STAC %s)", p_res$meta$pystac_version, p_res$meta$stac_version),
  "- Object key order ignored; link arrays compared as sets; numbers at 1e-9 relative tolerance; local paths masked to <DIR>.",
  "",
  sprintf("**Summary: %d scenarios — %d match, %d differ, %d error/skip**",
          length(rows), n_match, n_diff, n_err),
  "",
  "| # | scenario (function) | status | differences |",
  "|---|---|---|---|"
)
for (i in seq_along(rows)) {
  name <- names(rows)[i]
  x <- rows[[i]]
  summ <- gsub("|", "\\|", gsub("\n", " ", x$summary), fixed = TRUE)
  lines <- c(lines, sprintf("| %d | `%s` | %s | %s |", i, name, x$status, substr(summ, 1, 400)))
}
lines <- c(lines, "", "## Difference details")
for (name in names(rows)) {
  x <- rows[[name]]
  if (x$status %in% c("DIFF", "ERROR-R", "ERROR-PY", "BOTH-ERROR")) {
    lines <- c(lines, "", sprintf("### `%s` — %s", name, x$status))
    if (name %in% names(NOTES)) lines <- c(lines, paste("Note:", NOTES[name]))
    if (nzchar(x$summary)) lines <- c(lines, x$summary)
    if (length(x$diffs) > 0) {
      dd <- lapply(x$diffs[seq_len(min(12, length(x$diffs)))], function(d) {
        list(kind = d$kind, path = d$path,
             value = if (is.list(d$value)) d$value else list(d$value))
      })
      js <- substr(jsonlite::toJSON(dd, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = I(15)),
                   1, 3000)
      lines <- c(lines, "```json", js, "```")
    }
  }
}
writeLines(lines, file.path(OUT_DIR, "report.md"))

# machine-readable diffs
diffs_out <- lapply(names(rows), function(name) {
  x <- rows[[name]]
  list(status = x$status, summary = x$summary,
       diffs = lapply(x$diffs, function(d) list(kind = d$kind, path = d$path,
                                                value = if (is.list(d$value)) d$value else list(d$value))),
       r = x$r, py = x$py)
})
names(diffs_out) <- names(rows)
writeLines(jsonlite::toJSON(diffs_out, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = I(15)),
           file.path(OUT_DIR, "diffs.json"))

cat("\n")
for (name in names(rows)) {
  cat(sprintf("%-45s %s\n", name, rows[[name]]$status))
}
cat(sprintf("\nSummary: %d scenarios — %d match, %d differ, %d error/skip\n",
            length(rows), n_match, n_diff, n_err))
cat("Wrote", file.path(OUT_DIR, "report.md"), "and", file.path(OUT_DIR, "diffs.json"), "\n")
