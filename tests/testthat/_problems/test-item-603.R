# Extracted from test-item.R:603

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
item <- stac_item(
    id       = "roles-test",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox     = c(0, 0, 0, 0),
    datetime = "2024-01-01T00:00:00Z"
  ) |>
    add_asset(
      key   = "data",
      href  = "https://example.com/data.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    )
expect_type(item@assets$data$roles, "list")
