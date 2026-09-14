test_that("assets validate assignments and preserve JSON metadata", {
  asset <- stac_asset("./a.tif", roles = "data", `proj:code` = "EPSG:4326")
  expect_true(S7::S7_inherits(asset, stac_asset))
  expect_identical(asset@roles, "data")
  expect_error(asset@href <- "", "non-empty")
  expect_error(asset@href <- NA_character_, "non-empty")
  expect_error(asset@roles <- 1, "roles")
  asset@href <- "./b.tif"
  expect_identical(as.list(asset), list(href = "./b.tif", roles = list("data"),
                                      `proj:code` = "EPSG:4326"))
})

test_that("assets remain S7 through extensions and disk round trips", {
  item <- stac_item("scene", geometry = NULL, datetime = "2024-01-01T00:00:00Z",
                    assets = list(data = list(href = "./a.tif", roles = list("data"))))
  item <- add_raster_extension(item, list(raster_band(scale = 0.1)), asset_key = "data")
  expect_true(S7::S7_inherits(item@assets$data, stac_asset))
  expect_equal(item@assets$data@extra_fields$bands[[1]]$`raster:scale`, 0.1)
  path <- withr::local_tempfile(fileext = ".json")
  write_item(item, path)
  restored <- read_stac(path)
  expect_true(S7::S7_inherits(restored@assets$data, stac_asset))
  expect_identical(restored@assets$data@roles, "data")
  expect_equal(as.list(restored@assets$data), as.list(item@assets$data))
})
