# Extracted from test-thumbnail.R:99

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
skip_if_not_installed("terra")
skip_if_not_installed("sf")
tif <- test_path("testdata", "L7_ETMs.tif")
sf_file <- system.file("shape/nc.shp", package = "sf")

# test -------------------------------------------------------------------------
r <- terra::rast(tif)
path <- tempfile(fileext = ".png")
on.exit(unlink(path))
item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )
asset <- preview_from_terra(r, path = path)
item <- add_asset(item, key = "thumbnail", asset = asset)
expect_true("thumbnail" %in% names(item@assets))
expect_equal(item@assets$thumbnail$roles, list("overview"))
