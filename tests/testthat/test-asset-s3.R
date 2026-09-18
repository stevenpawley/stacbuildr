test_that("assets remain S3 through extensions and disk round trips", {
  item <- stac_item(
    id = "scene",
    geometry = NULL,
    datetime = "2024-01-01T00:00:00Z",
    assets = list(data = list(href = "./a.tif", roles = list("data")))
  )
  
  item <- add_raster_extension(
    item,
    list(raster_band(scale = 0.1)),
    asset_key = "data"
  )
  expect_true(inherits(item$assets$data, "stac_asset"))
  expect_equal(item$assets$data$extra_fields$bands[[1]]$scale, 0.1)
  path <- withr::local_tempfile(fileext = ".json")
  write_item(item, path)
  restored <- read_stac(path)
  expect_true(inherits(restored$assets$data, "stac_asset"))
  expect_identical(restored$assets$data$roles, "data")
  expect_equal(
    as.list(restored$assets$data),
    stacbuildr:::stac_json_value(as.list(item$assets$data))
  )
})
