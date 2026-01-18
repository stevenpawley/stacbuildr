test_that("validation catches invalid items", {
  # Missing required fields
  invalid_item <- list(
    type = "Feature",
    id = "test"
    # missing other required fields
  )
  class(invalid_item) <- c("stac_item", "list")
  
  result <- validate_stac(invalid_item)
  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validation catches invalid bbox", {
  item <- stac_item(
    id = "test-invalid-bbox",
    geometry = list(type = "Point", coordinates = c(-104.5, 40.5)),
    bbox = c(10, 20, 5, 15),  # west > east, south > north
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )
  
  result <- validate_stac(item)
  expect_false(result$valid)
  expect_true(any(grepl("west.*east", result$errors, ignore.case = TRUE)))
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
    "'datetime' is required"
  )
})
