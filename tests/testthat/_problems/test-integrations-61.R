# Extracted from test-integrations.R:61

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
skip_if_not_installed("stars")
skip_if_not_installed("sf")
tif <- system.file("tif/L7_ETMs.tif", package = "stars")

# test -------------------------------------------------------------------------
r <- stars::read_stars(tif, quiet = TRUE)
item <- item_from_stars(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z",
    asset_key = "data",
    asset_roles = c("data")
  )
expect_true("data" %in% names(item@assets))
expect_equal(item@assets$data$href, gsub("\\\\", "/", tif))
expect_equal(item@assets$data$type, "image/tiff; application=geotiff")
expect_equal(item@assets$data$roles, list("data"))
