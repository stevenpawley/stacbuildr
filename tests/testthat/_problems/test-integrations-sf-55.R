# Extracted from test-integrations-sf.R:55

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
sf_file <- system.file("shape/nc.shp", package = "sf")
skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

# test -------------------------------------------------------------------------
nc <- sf::st_read(sf_file, quiet = TRUE)
item <- item_from_sf(
    nc,
    id = "nc",
    datetime = "2025-01-01T00:00:00Z",
    href = sf_file
  )
expect_true("source" %in% names(item@assets))
expect_equal(item@assets$source$href, gsub("\\\\", "/", normalizePath(sf_file)))
expect_equal(item@assets$source$roles, list("data"))
