test_that("STAC Item creation works", {
  item <- stac_item(
    id = "test-item",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox = c(-105, 40, -105, 40),
    datetime = Sys.time()
  )
  
  expect_s3_class(item, "stac_item")
  expect_equal(item$type, "Feature")
  expect_equal(item$stac_version, "1.1.0")
  expect_true(validate_stac(item))
})