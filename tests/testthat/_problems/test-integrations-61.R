# Extracted from test-integrations.R:61

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
skip_if_not_installed("terra")
skip_if_not_installed("sf")
tif <- test_path("testdata", "L7_ETMs.tif")

# test -------------------------------------------------------------------------
r <- terra::rast(tif)
item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z",
    asset_key = "data",
    asset_roles = c("data")
  )
expect_true("data" %in% names(item@assets))
expect_equal(item@assets$data$href, gsub("\\\\", "/", normalizePath(tif)))
expect_equal(item@assets$data$type, "image/tiff; application=geotiff")
expect_equal(item@assets$data$roles, list("data"))
