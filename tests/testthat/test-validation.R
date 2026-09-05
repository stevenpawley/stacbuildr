test_that("validation catches invalid items", {
  # A plain list without stac_item class is an unknown type
  invalid_item <- list(type = "Feature", id = "test")
  result <- validate_stac(invalid_item)
  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validation catches invalid bbox", {
  item <- stac_item(
    id = "test-invalid-bbox",
    geometry = list(type = "Point", coordinates = c(-104.5, 40.5)),
    bbox = c(10, 20, 5, 15), # south > north
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  result <- validate_stac(item)
  expect_false(result$valid)
  expect_true(any(grepl("south.*north", result$errors, ignore.case = TRUE)))
})

test_that("validation accepts a bbox crossing the antimeridian", {
  # RFC 7946 section 5.2 represents an antimeridian-crossing bbox with a west
  # value greater than the east value; this is the Fiji example from the RFC.
  item <- stac_item(
    id = "fiji",
    geometry = list(type = "Point", coordinates = c(179, -18)),
    bbox = c(177, -20, -178, -16),
    datetime = "2023-06-15T17:30:00Z"
  )

  expect_true(validate_stac(item)$valid)

  extent <- stac_extent(
    spatial_bbox = list(c(177, -20, -178, -16)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )
  collection <- stac_collection(
    id = "fiji",
    description = "Straddles the antimeridian",
    license = "MIT",
    extent = extent
  )

  expect_true(validate_stac(collection)$valid)
})

test_that("validation still orders latitude and elevation", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(0, 20, 1, 10)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    ),
    "south \\(20\\) must be <= north"
  )

  expect_error(
    stac_extent(
      spatial_bbox = list(c(0, 0, 100, 1, 1, 50)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    ),
    "min elevation \\(100\\) must be <= max elevation"
  )
})

test_that("validation catches missing datetime", {
  expect_error(
    stac_item(
      id = "test-no-datetime",
      geometry = list(type = "Point", coordinates = c(-104.5, 40.5)),
      bbox = c(-105, 40, -104, 41),
      datetime = NULL,
      properties = list()
    ),
    "datetime"
  )
})

test_that("suppress_unknown_format_warnings muffles ajv unknown-format warnings", {
  expect_silent(
    suppress_unknown_format_warnings(
      warning('unknown format "iri" ignored in schema at path "#/properties/href"')
    )
  )
})

test_that("suppress_unknown_format_warnings lets other warnings through", {
  expect_warning(
    suppress_unknown_format_warnings(warning("something actually wrong")),
    "something actually wrong"
  )
})

test_that("suppress_unknown_format_warnings returns the expression value", {
  expect_equal(suppress_unknown_format_warnings(41 + 1), 42)
})
