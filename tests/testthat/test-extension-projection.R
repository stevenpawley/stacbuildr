proj_item <- function() {
  stac_item(
    id = "proj-test",
    geometry = list(type = "Point", coordinates = c(-113.5, 51.0)),
    bbox = c(-113.5, 51.0, -113.5, 51.0),
    datetime = "2024-06-01T00:00:00Z"
  )
}

proj_uri <- "https://stac-extensions.github.io/projection/v2.0.0/schema.json"

test_that("add_projection_extension declares the extension and sets fields", {
  item <- add_projection_extension(
    proj_item(),
    code = "EPSG:32612",
    shape = c(5558, 9559),
    transform = c(30, 0, 712710, 0, -30, 5654790)
  )

  expect_true(proj_uri %in% item@stac_extensions)
  expect_equal(item@properties$`proj:code`, "EPSG:32612")
  expect_equal(item@properties$`proj:shape`, c(5558, 9559))
  expect_length(item@properties$`proj:transform`, 6)
})

test_that("add_projection_extension writes every supported field", {
  item <- add_projection_extension(
    proj_item(),
    code = "EPSG:32612",
    wkt2 = "PROJCRS[\"WGS 84 / UTM zone 12N\"]",
    projjson = list(type = "ProjectedCRS", name = "WGS 84 / UTM zone 12N"),
    geometry = list(type = "Point", coordinates = c(712710, 5654790)),
    bbox = c(712710, 5487090, 999480, 5654790),
    centroid = c(lat = 51.05, lon = -114.07),
    shape = c(100, 200),
    transform = c(30, 0, 712710, 0, -30, 5654790, 0, 0, 1)
  )

  props <- item@properties
  expect_equal(props$`proj:wkt2`, "PROJCRS[\"WGS 84 / UTM zone 12N\"]")
  expect_equal(props$`proj:projjson`$type, "ProjectedCRS")
  expect_equal(props$`proj:geometry`$type, "Point")
  expect_length(props$`proj:bbox`, 4)
  expect_equal(props$`proj:centroid`, list(lat = 51.05, lon = -114.07))
  expect_length(props$`proj:transform`, 9)
})

test_that("add_projection_extension does not duplicate the extension URI", {
  item <- add_projection_extension(proj_item(), code = "EPSG:4326")
  item <- add_projection_extension(item, shape = c(10, 10))

  expect_equal(sum(item@stac_extensions == proj_uri), 1L)
  # The second call adds to, rather than replaces, what the first wrote
  expect_equal(item@properties$`proj:code`, "EPSG:4326")
  expect_equal(item@properties$`proj:shape`, c(10, 10))
})

test_that("add_projection_extension writes to an asset when given asset_key", {
  item <- add_asset(
    proj_item(),
    key = "swir",
    href = "https://example.com/swir.tif",
    type = "image/tiff; application=geotiff"
  )
  item <- add_projection_extension(
    item,
    shape = c(2779, 4780),
    transform = c(60, 0, 712710, 0, -60, 5654790),
    asset_key = "swir"
  )

  expect_equal(item@assets$swir$`proj:shape`, c(2779, 4780))
  # Asset-level placement leaves the item properties alone
  expect_null(item@properties$`proj:shape`)
  expect_true(proj_uri %in% item@stac_extensions)
})

test_that("add_projection_extension rejects a missing asset", {
  expect_error(
    add_projection_extension(proj_item(), code = "EPSG:4326", asset_key = "nope"),
    "does not exist"
  )
})

test_that("add_projection_extension requires at least one field", {
  expect_error(
    add_projection_extension(proj_item()),
    "At least one projection field"
  )
})

test_that("add_projection_extension requires an authority on proj:code", {
  # proj:epsg was replaced by proj:code in v2.0.0, so a bare number is wrong
  expect_error(add_projection_extension(proj_item(), code = "32612"), "AUTHORITY:CODE")
  expect_error(add_projection_extension(proj_item(), code = "EPSG"), "AUTHORITY:CODE")
  expect_error(add_projection_extension(proj_item(), code = ""), "non-empty")

  expect_no_error(add_projection_extension(proj_item(), code = "OGC:CRS84"))
  expect_no_error(add_projection_extension(proj_item(), code = "IAU_2015:49900"))
})

test_that("add_projection_extension accepts 2D and 3D bboxes only", {
  expect_no_error(add_projection_extension(proj_item(), bbox = c(0, 0, 1, 1)))
  expect_no_error(
    add_projection_extension(proj_item(), bbox = c(0, 0, 0, 1, 1, 1))
  )
  expect_error(
    add_projection_extension(proj_item(), bbox = c(0, 0, 1)),
    "length 4 or 6"
  )
  expect_error(
    add_projection_extension(proj_item(), bbox = c(0, 0, 1, NA)),
    "missing values"
  )
})

test_that("add_projection_extension accepts 6- and 9-element transforms only", {
  expect_no_error(
    add_projection_extension(proj_item(), transform = c(30, 0, 0, 0, -30, 0))
  )
  expect_no_error(
    add_projection_extension(
      proj_item(),
      transform = c(30, 0, 0, 0, -30, 0, 0, 0, 1)
    )
  )
  expect_error(
    add_projection_extension(proj_item(), transform = c(30, 0, 0)),
    "length 6 or 9"
  )
})

test_that("add_projection_extension requires shape to be two positive integers", {
  expect_error(add_projection_extension(proj_item(), shape = c(10, 10, 10)), "length 2")
  expect_error(add_projection_extension(proj_item(), shape = c(0, 10)), "positive whole")
  expect_error(add_projection_extension(proj_item(), shape = c(1.5, 10)), "positive whole")
})

test_that("add_projection_extension validates the centroid", {
  expect_error(
    add_projection_extension(proj_item(), centroid = c(x = 1, y = 2)),
    "'lat' and 'lon'"
  )
  expect_error(
    add_projection_extension(proj_item(), centroid = c(lat = 91, lon = 0)),
    "WGS84 degrees"
  )
  expect_error(
    add_projection_extension(proj_item(), centroid = c(lat = 0, lon = 181)),
    "WGS84 degrees"
  )
  # A list is accepted as well as a named vector
  item <- add_projection_extension(
    proj_item(),
    centroid = list(lat = 51.05, lon = -114.07)
  )
  expect_equal(item@properties$`proj:centroid`$lat, 51.05)
})

test_that("add_projection_extension validates geometry and item type", {
  expect_error(
    add_projection_extension(proj_item(), geometry = list(coordinates = c(1, 2))),
    "'type' field"
  )
  expect_error(
    add_projection_extension(list(id = "not-an-item"), code = "EPSG:4326"),
    "must be a stac_item"
  )
})

test_that("projection fields survive a write/read round trip", {
  item <- add_projection_extension(
    proj_item(),
    code = "EPSG:32612",
    bbox = c(712710, 5487090, 999480, 5654790),
    shape = c(5558, 9559),
    transform = c(30, 0, 712710, 0, -30, 5654790)
  )

  path <- withr::local_tempfile(fileext = ".json")
  write_item(item, path)
  back <- read_stac(path)

  expect_equal(back@properties$`proj:code`, "EPSG:32612")
  expect_length(back@properties$`proj:shape`, 2)
  expect_length(back@properties$`proj:transform`, 6)
  expect_true(proj_uri %in% back@stac_extensions)
})

test_that("numeric projection fields are stored without names", {
  # terra hands back named vectors from ext(); a named vector would serialise
  # as a JSON object where the spec requires an array
  item <- add_projection_extension(
    proj_item(),
    bbox = c(xmin = 0, ymin = 0, xmax = 1, ymax = 1),
    shape = c(rows = 10, cols = 20),
    transform = c(xscale = 30, a = 0, xmin = 0, b = 0, yscale = -30, ymax = 1)
  )

  expect_null(names(item@properties$`proj:bbox`))
  expect_null(names(item@properties$`proj:shape`))
  expect_null(names(item@properties$`proj:transform`))
})
