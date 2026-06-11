# Extracted from test-item.R:625

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
item <- stac_item(
    id       = "roles-json-test",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox     = c(0, 0, 0, 0),
    datetime = "2024-01-01T00:00:00Z"
  ) |>
    add_asset(
      key   = "B1",
      href  = "https://example.com/B1.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    )
json   <- jsonlite::toJSON(as.list(item), auto_unbox = TRUE, null = "null")
parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
expect_type(parsed$assets$B1$roles, "list")
