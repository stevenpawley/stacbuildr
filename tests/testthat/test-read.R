fixture <- function(name) testthat::test_path("fixtures", name)

# ── read_stac: item ──────────────────────────────────────────────────────────

test_that("read_stac returns a stac_item for a Feature JSON", {
  item <- read_stac(fixture("simple-item.json"))

  expect_s3_class(item, "stac_item")
  expect_equal(item@id, "20201211_223832_CS2")
  expect_equal(item@type, "Feature")
  expect_equal(item@stac_version, "1.1.0")
})

test_that("read_stac restores item geometry correctly", {
  item <- read_stac(fixture("simple-item.json"))

  expect_equal(item@geometry$type, "Polygon")
  expect_length(item@geometry$coordinates, 1L)
})

test_that("read_stac restores item bbox as a numeric vector", {
  item <- read_stac(fixture("simple-item.json"))

  expect_type(item@bbox, "double")
  expect_length(item@bbox, 4L)
  expect_equal(item@bbox[1], 172.91173669923782)
})

test_that("read_stac restores item datetime in properties", {
  item <- read_stac(fixture("simple-item.json"))

  expect_equal(item@properties$datetime, "2020-12-11T22:38:32.125000Z")
})

test_that("read_stac restores item assets", {
  item <- read_stac(fixture("simple-item.json"))

  expect_true("visual" %in% names(item@assets))
  expect_true("thumbnail" %in% names(item@assets))
  expect_equal(
    item@assets$visual$href,
    "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2.tif"
  )
  expect_equal(item@assets$visual$roles, list("visual"))
})

test_that("read_stac restores item links", {
  item <- read_stac(fixture("simple-item.json"))

  rels <- vapply(item@links, `[[`, character(1), "rel")
  expect_true("collection" %in% rels)
  expect_true("root" %in% rels)
  expect_true("parent" %in% rels)
})

test_that("read_stac restores item collection field", {
  item <- read_stac(fixture("simple-item.json"))

  expect_equal(item@collection, "simple-collection")
})

# ── read_stac: catalog ───────────────────────────────────────────────────────

test_that("read_stac returns a stac_catalog for a Catalog JSON", {
  catalog <- read_stac(fixture("catalog.json"))

  expect_s3_class(catalog, "stac_catalog")
  expect_false(inherits(catalog, "stac_collection"))
})

test_that("read_stac restores catalog core fields", {
  catalog <- read_stac(fixture("catalog.json"))

  expect_equal(catalog@id, "examples")
  expect_equal(catalog@type, "Catalog")
  expect_equal(catalog@stac_version, "1.1.0")
  expect_equal(catalog@title, "Example Catalog")
  expect_false(is.null(catalog@description))
})

test_that("read_stac restores catalog links", {
  catalog <- read_stac(fixture("catalog.json"))

  rels <- vapply(catalog@links, `[[`, character(1), "rel")
  expect_true("root" %in% rels)
  expect_true("child" %in% rels)
  expect_equal(sum(rels == "child"), 3L)
})

# ── read_stac: collection ────────────────────────────────────────────────────

test_that("read_stac returns a stac_collection for a Collection JSON", {
  collection <- read_stac(fixture("collection.json"))

  expect_s3_class(collection, "stac_collection")
  expect_s3_class(collection, "stac_catalog")
})

test_that("read_stac restores collection core fields", {
  collection <- read_stac(fixture("collection.json"))

  expect_equal(collection@id, "simple-collection")
  expect_equal(collection@type, "Collection")
  expect_equal(collection@stac_version, "1.1.0")
  expect_equal(collection@license, "CC-BY-4.0")
  expect_equal(collection@title, "Simple Example Collection")
})

test_that("read_stac restores collection stac_extensions as character vector", {
  collection <- read_stac(fixture("collection.json"))

  expect_type(collection@stac_extensions, "character")
  expect_length(collection@stac_extensions, 3L)
  expect_true(any(grepl("eo", collection@stac_extensions)))
})

test_that("read_stac restores collection keywords as character vector", {
  collection <- read_stac(fixture("collection.json"))

  expect_type(collection@keywords, "character")
  expect_equal(collection@keywords, c("simple", "example", "collection"))
})

test_that("read_stac restores collection spatial extent as numeric bboxes", {
  collection <- read_stac(fixture("collection.json"))

  bbox <- collection@extent@spatial@bbox[[1]]
  expect_type(bbox, "double")
  expect_length(bbox, 4L)
  expect_equal(bbox[1], 172.91173669923782)
})

test_that("read_stac restores collection temporal extent", {
  collection <- read_stac(fixture("collection.json"))

  interval <- collection@extent@temporal@interval[[1]]
  expect_length(interval, 2L)
  expect_equal(interval[[1]], "2020-12-11T22:38:32.125Z")
  expect_equal(interval[[2]], "2020-12-14T18:02:31.437Z")
})

test_that("read_stac restores collection providers", {
  collection <- read_stac(fixture("collection.json"))

  expect_length(collection@providers, 1L)
  expect_equal(collection@providers[[1]]$name, "Remote Data, Inc")
})

test_that("read_stac restores collection summaries", {
  collection <- read_stac(fixture("collection.json"))

  expect_false(is.null(collection@summaries))
  expect_true("platform" %in% names(collection@summaries))
})

test_that("read_stac restores collection links", {
  collection <- read_stac(fixture("collection.json"))

  rels <- vapply(collection@links, `[[`, character(1), "rel")
  expect_true("root" %in% rels)
  expect_equal(sum(rels == "item"), 3L)
})

# ── write/read round-trip ────────────────────────────────────────────────────

test_that("stac_item survives a write/read round-trip", {
  original <- stac_item(
    id       = "round-trip-item",
    geometry = list(type = "Point", coordinates = c(-105.0, 40.0)),
    bbox     = c(-105.0, 40.0, -105.0, 40.0),
    datetime = "2023-06-15T10:30:00Z",
    properties = list(platform = "landsat-8", gsd = 30)
  )
  original <- add_asset(
    original,
    key   = "visual",
    href  = "https://example.com/visual.tif",
    type  = "image/tiff; application=geotiff",
    roles = c("visual")
  )

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(original, path)
  restored <- read_stac(path)

  expect_s3_class(restored, "stac_item")
  expect_equal(restored@id, original@id)
  expect_equal(restored@bbox, original@bbox)
  expect_equal(restored@properties$datetime, "2023-06-15T10:30:00Z")
  expect_equal(restored@properties$platform, "landsat-8")
  expect_equal(restored@properties$gsd, 30)
  expect_equal(restored@assets$visual$href, "https://example.com/visual.tif")
})

test_that("stac_item with time range survives a write/read round-trip", {
  original <- stac_item(
    id             = "range-item",
    geometry       = list(type = "Point", coordinates = c(0.0, 0.0)),
    bbox           = c(0.0, 0.0, 0.0, 0.0),
    datetime       = NULL,
    start_datetime = "2023-01-01T00:00:00Z",
    end_datetime   = "2023-06-30T23:59:59Z"
  )

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(original, path)
  restored <- read_stac(path)

  expect_null(restored@properties$datetime)
  expect_equal(restored@properties$start_datetime, "2023-01-01T00:00:00Z")
  expect_equal(restored@properties$end_datetime,   "2023-06-30T23:59:59Z")
})

test_that("stac_catalog survives a write/read round-trip", {
  original <- stac_catalog(
    id          = "my-catalog",
    description = "A test catalog",
    title       = "Test Catalog"
  ) |>
    add_root_link("./catalog.json") |>
    add_link("child", "./sub/collection.json", type = "application/json")

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_catalog(original, path)
  restored <- read_stac(path)

  expect_s3_class(restored, "stac_catalog")
  expect_false(inherits(restored, "stac_collection"))
  expect_equal(restored@id, "my-catalog")
  expect_equal(restored@title, "Test Catalog")
  expect_equal(restored@description, "A test catalog")
  expect_length(restored@links, 2L)
})

test_that("stac_collection survives a write/read round-trip", {
  original <- stac_collection(
    id          = "my-collection",
    description = "A test collection",
    license     = "CC0-1.0",
    title       = "Test Collection",
    keywords    = c("test", "example"),
    stac_extensions = "https://stac-extensions.github.io/eo/v2.0.0/schema.json",
    extent = stac_extent(
      spatial_bbox      = list(c(-180, -90, 180, 90)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    )
  ) |>
    add_root_link("./catalog.json")

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_catalog(original, path)
  restored <- read_stac(path)

  expect_s3_class(restored, "stac_collection")
  expect_equal(restored@id, "my-collection")
  expect_equal(restored@license, "CC0-1.0")
  expect_equal(restored@keywords, c("test", "example"))
  expect_equal(restored@stac_extensions,
               "https://stac-extensions.github.io/eo/v2.0.0/schema.json")

  bbox <- restored@extent@spatial@bbox[[1]]
  expect_equal(bbox, c(-180, -90, 180, 90))

  interval <- restored@extent@temporal@interval[[1]]
  expect_equal(interval[[1]], "2020-01-01T00:00:00Z")
  expect_null(interval[[2]])

  expect_length(restored@links, 1L)
})

test_that("read_stac errors when file does not exist", {
  expect_error(read_stac("nonexistent.json"), "File not found")
})

test_that("read_stac errors when type field is missing", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  writeLines('{"id": "foo"}', path)

  expect_error(read_stac(path), "missing 'type' field")
})
