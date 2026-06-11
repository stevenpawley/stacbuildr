# Extracted from test-extension-raster.R:136

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "stacbuildr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
make_item <- function() {
  stac_item(
    id       = "raster-test",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  ) |>
    add_asset(
      key   = "B4",
      href  = "https://example.com/B4.tif",
      type  = "image/tiff; application=geotiff; profile=cloud-optimized",
      roles = c("data")
    )
}

# test -------------------------------------------------------------------------
item <- make_item() |>
    add_raster_extension(
      bands = list(raster_band(data_type = "uint16", scale = 2.75e-5))
    )
path <- tempfile(fileext = ".json")
on.exit(unlink(path))
write_item(item, path)
raw_json <- paste(readLines(path, warn = FALSE), collapse = "\n")
expect_no_match(raw_json, '"raster:scale":\\s*0[,\\s]', perl = TRUE)
