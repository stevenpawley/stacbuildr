# Extracted from test-thumbnail.R:60

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
skip_if_not_installed("stars")
skip_if_not_installed("sf")
tif <- system.file("tif/L7_ETMs.tif", package = "stars")
sf_file <- system.file("shape/nc.shp", package = "sf")

# test -------------------------------------------------------------------------
nc <- sf::st_read(sf_file, quiet = TRUE)
path <- tempfile(fileext = ".png")
on.exit(unlink(path))
asset <- thumbnail_from_sf(nc, path = path)
expect_true(file.exists(path))
expect_equal(asset$type, "image/png")
expect_equal(asset$roles, list("thumbnail"))
