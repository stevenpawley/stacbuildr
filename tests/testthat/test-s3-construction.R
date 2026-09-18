test_that("constructors validate values before creating S3 objects", {
  expect_error(stac_asset(""), "non-empty")
  expect_error(classification_class(value = 1.5), "single integer")
  expect_error(pc_schema("X", size = 0, type = "floating"), "greater than 0")
  expect_error(raster_histogram(2, 0, 1, 1L), "must equal")
})

test_that("ordinary S3 assignment preserves class without hidden validation", {
  asset <- stac_asset("./a.tif", roles = "data")

  asset$href <- "./b.tif"
  asset$roles <- "overview"

  expect_s3_class(asset, "stac_asset")
  expect_identical(asset$href, "./b.tif")
  expect_identical(asset$roles, "overview")
  expect_null(attr(asset, "stac_properties"))
  expect_null(attr(asset, "stac_validators"))
})
