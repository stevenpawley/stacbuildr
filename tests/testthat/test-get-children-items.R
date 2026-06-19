# Tests for get_children() and get_items() — both in-memory and after a
# write_stac() / read_stac() round-trip.

# ── Shared test fixture ───────────────────────────────────────────────────────

make_catalog_tree <- function() {
  asset <- stac_asset(
    href  = "https://example.com/dem.tif",
    type  = "image/tiff; application=geotiff",
    title = "Digital Elevation Model",
    roles = c("data")
  )

  item <- stac_item(
    id       = "dem-2023",
    geometry = list(type = "Point", coordinates = c(-114.0, 51.0)),
    bbox     = c(-114.0, 51.0, -114.0, 51.0),
    datetime = "2023-06-15T00:00:00Z"
  )
  item <- add_asset(item, key = "dem", asset)

  collection <- stac_collection(
    id          = "elevation",
    description = "Elevation datasets",
    license     = "OGL-Canada-2.0",
    title       = "Elevation",
    extent      = stac_extent(
      spatial_bbox      = list(c(-114.0, 51.0, -114.0, 51.0)),
      temporal_interval = list(list("2023-06-15T00:00:00Z", NULL))
    )
  )
  collection <- add_item(collection, item)

  catalog <- stac_catalog(
    id          = "test-catalog",
    description = "A test catalog",
    title       = "Test Catalog"
  )
  catalog <- add_child(catalog, collection)

  list(catalog = catalog, collection = collection, item = item, asset = asset)
}

# ── In-memory: get_children() ─────────────────────────────────────────────────

test_that("get_children returns a named list in memory", {
  tree <- make_catalog_tree()
  children <- get_children(tree$catalog)

  expect_type(children, "list")
  expect_named(children, "elevation")
})

test_that("get_children returns the correct collection in memory", {
  tree <- make_catalog_tree()
  children <- get_children(tree$catalog)

  expect_s3_class(children[["elevation"]], "stac_collection")
  expect_equal(children[["elevation"]]@id, "elevation")
  expect_equal(children[["elevation"]]@title, "Elevation")
})

test_that("get_children returns NULL when no children added", {
  catalog <- stac_catalog(id = "empty", description = "Empty catalog")
  expect_null(get_children(catalog))
})

# ── In-memory: get_items() ────────────────────────────────────────────────────

test_that("get_items returns a list in memory", {
  tree <- make_catalog_tree()
  items <- get_items(tree$collection)

  expect_type(items, "list")
  expect_length(items, 1L)
})

test_that("get_items returns the correct item in memory", {
  tree <- make_catalog_tree()
  items <- get_items(tree$collection)

  expect_s3_class(items[[1]], "stac_item")
  expect_equal(items[[1]]@id, "dem-2023")
  expect_equal(items[[1]]@properties$datetime, "2023-06-15T00:00:00Z")
})

test_that("get_items item contains the expected asset in memory", {
  tree <- make_catalog_tree()
  items <- get_items(tree$collection)

  expect_true("dem" %in% names(items[[1]]@assets))
  expect_equal(items[[1]]@assets$dem$href, "https://example.com/dem.tif")
  expect_equal(items[[1]]@assets$dem$type, "image/tiff; application=geotiff")
})

test_that("get_items returns NULL when no items added", {
  collection <- stac_collection(
    id          = "empty",
    description = "Empty collection",
    license     = "CC0-1.0",
    extent      = stac_extent(
      spatial_bbox      = list(c(0, 0, 0, 0)),
      temporal_interval = list(list("2023-01-01T00:00:00Z", NULL))
    )
  )
  expect_null(get_items(collection))
})

# ── Round-trip: write_stac() then read_stac() ─────────────────────────────────

test_that("get_children with resolve = TRUE returns collections after round-trip", {
  tree <- make_catalog_tree()

  dir <- tempfile()
  on.exit(unlink(dir, recursive = TRUE))
  write_stac(tree$catalog, dir)

  restored <- read_stac(file.path(dir, "catalog.json"))
  children  <- get_children(restored, resolve = TRUE, base_path = dir)

  expect_type(children, "list")
  expect_named(children, "elevation")
  expect_s3_class(children[["elevation"]], "stac_collection")
  expect_equal(children[["elevation"]]@id, "elevation")
  expect_equal(children[["elevation"]]@title, "Elevation")
})

test_that("get_items with resolve = TRUE returns items after round-trip", {
  tree <- make_catalog_tree()

  dir <- tempfile()
  on.exit(unlink(dir, recursive = TRUE))
  write_stac(tree$catalog, dir)

  collection_path <- file.path(dir, "elevation")
  collection <- read_stac(file.path(collection_path, "collection.json"))
  items <- get_items(collection, resolve = TRUE, base_path = collection_path)

  expect_type(items, "list")
  expect_length(items, 1L)
  expect_s3_class(items[[1]], "stac_item")
  expect_equal(items[[1]]@id, "dem-2023")
  expect_equal(items[[1]]@properties$datetime, "2023-06-15T00:00:00Z")
})

test_that("resolved item contains the expected asset after round-trip", {
  tree <- make_catalog_tree()

  dir <- tempfile()
  on.exit(unlink(dir, recursive = TRUE))
  write_stac(tree$catalog, dir)

  collection_path <- file.path(dir, "elevation")
  collection <- read_stac(file.path(collection_path, "collection.json"))
  items <- get_items(collection, resolve = TRUE, base_path = collection_path)

  expect_true("dem" %in% names(items[[1]]@assets))
  expect_equal(items[[1]]@assets$dem$href, "https://example.com/dem.tif")
  expect_equal(items[[1]]@assets$dem$type, "image/tiff; application=geotiff")
})

test_that("get_children returns NULL without resolve after round-trip", {
  tree <- make_catalog_tree()

  dir <- tempfile()
  on.exit(unlink(dir, recursive = TRUE))
  write_stac(tree$catalog, dir)

  restored <- read_stac(file.path(dir, "catalog.json"))
  expect_null(get_children(restored))
})

test_that("get_items returns NULL without resolve after round-trip", {
  tree <- make_catalog_tree()

  dir <- tempfile()
  on.exit(unlink(dir, recursive = TRUE))
  write_stac(tree$catalog, dir)

  collection_path <- file.path(dir, "elevation")
  collection <- read_stac(file.path(collection_path, "collection.json"))
  expect_null(get_items(collection))
})
