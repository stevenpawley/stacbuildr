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


test_that("item and collection assets must be named dictionaries", {
  asset <- stac_asset("./a.tif")

  expect_error(
    stac_item(
      id = "scene",
      geometry = NULL,
      datetime = "2024-01-01T00:00:00Z",
      assets = list(asset)
    ),
    "non-empty name"
  )
  expect_error(
    stac_item(
      id = "scene",
      geometry = NULL,
      datetime = "2024-01-01T00:00:00Z",
      assets = setNames(list(asset, asset), c("data", "data"))
    ),
    "unique names"
  )

  extent <- stac_extent(
    spatial_bbox = list(c(0, 0, 1, 1)),
    temporal_interval = list(list(NULL, NULL))
  )
  expect_error(
    stac_collection(
      id = "collection",
      description = "Collection",
      license = "CC0-1.0",
      extent = extent,
      assets = list(asset)
    ),
    "non-empty name"
  )

  expect_no_error(
    stac_item(
      id = "scene",
      geometry = NULL,
      datetime = "2024-01-01T00:00:00Z",
      assets = list(data = asset)
    )
  )
  expect_no_error(
    stac_item(
      id = "scene",
      geometry = NULL,
      datetime = "2024-01-01T00:00:00Z",
      assets = list()
    )
  )
})
