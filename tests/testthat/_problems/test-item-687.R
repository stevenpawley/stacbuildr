# Extracted from test-item.R:687

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
item <- stac_item(
    id       = "roles-roundtrip",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox     = c(0, 0, 0, 0),
    datetime = "2024-01-01T00:00:00Z"
  ) |>
    add_asset(
      key   = "data",
      href  = "https://example.com/data.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    ) |>
    add_asset(
      key   = "thumbnail",
      href  = "https://example.com/thumb.jpg",
      type  = "image/jpeg",
      roles = c("thumbnail")
    )
path <- tempfile(fileext = ".json")
on.exit(unlink(path))
write_item(item, path)
raw_json <- paste(readLines(path, warn = FALSE), collapse = "\n")
expect_match(raw_json, '"roles":\\s*\\[',         perl = TRUE)
expect_no_match(raw_json, '"roles":\\s*"',        perl = TRUE)
restored <- read_stac(path)
expect_type(restored@assets$data$roles,      "list")
expect_type(restored@assets$thumbnail$roles, "list")
expect_equal(restored@assets$data$roles,      list("data"))
expect_equal(restored@assets$thumbnail$roles, list("thumbnail"))
