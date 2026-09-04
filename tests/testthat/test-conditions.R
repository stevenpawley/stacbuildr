test_that("errors are raised as cli conditions", {
  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )

  # cli_abort() produces an rlang error, not a bare simpleError
  expect_error(add_asset(item, "k", asset = list(no_href = 1)), class = "rlang_error")
  expect_error(stac_asset(href = ""), class = "rlang_error")
  expect_error(add_item(item, item), class = "rlang_error")
})

test_that("error messages keep their text and interpolate values", {
  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )

  expect_error(
    add_eo_extension(item, bands = list(eo_band(name = "B4")), asset_key = "nope"),
    "Asset 'nope' does not exist in item",
    fixed = TRUE
  )
  expect_error(
    raster_histogram(count = 3, min = 0, max = 1, buckets = c(1, 2)),
    "'buckets' length (2) must equal 'count' (3)",
    fixed = TRUE
  )
})

test_that("hints are carried as a separate bullet", {
  local_reproducible_output(unicode = FALSE)

  err <- tryCatch(
    stac_item(
      id = "i",
      geometry = list(type = "Point", coordinates = c(0, 0)),
      bbox = c(0, 0, 0, 0),
      datetime = "2023-01-01T00:00:00Z"
    ) |> add_asset("k", asset = list(no_href = 1)),
    error = function(e) e
  )
  msg <- conditionMessage(err)

  expect_match(msg, "'asset' must be a list with at least an 'href' field", fixed = TRUE)
  expect_match(msg, "Use stac_asset() to build one.", fixed = TRUE)
})

test_that("warnings are raised as cli conditions", {
  expect_warning(
    eo_band(name = "B4", common_name = "not-a-name"),
    "is not a standard common_name"
  )
  expect_warning(
    raster_statistics(valid_percent = 150),
    class = "rlang_warning"
  )
})
