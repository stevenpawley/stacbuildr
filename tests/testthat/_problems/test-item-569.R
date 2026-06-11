# Extracted from test-item.R:569

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
item <- stac_item(
    id = "test-add-asset",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox = c(-105, 40, -105, 40),
    datetime = "2023-01-01T00:00:00Z"
  )
item <- add_asset(
    item,
    key = "thumbnail",
    href = "https://example.com/thumb.png",
    title = "Thumbnail",
    type = "image/png",
    roles = c("thumbnail")
  )
expect_true("thumbnail" %in% names(item@assets))
expect_equal(item@assets$thumbnail$href, "https://example.com/thumb.png")
expect_equal(item@assets$thumbnail$title, "Thumbnail")
expect_equal(item@assets$thumbnail$type, "image/png")
data_asset <- stac_asset(
    href = "https://example.com/data.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  )
item <- add_asset(item, key = "data", asset = data_asset)
expect_true("data" %in% names(item@assets))
expect_equal(item@assets$data$href, "https://example.com/data.tif")
expect_equal(item@assets$data$type, "image/tiff; application=geotiff")
expect_equal(item@assets$data$roles, list("data"))
