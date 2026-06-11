# Extracted from test-extent.R:9

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(
      list("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z")
    )
  )
expect_true(inherits(extent, "Extent"))
