# Extracted from test-extension-raster.R:116

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
      bands = list(
        raster_band(
          nodata             = 0,
          data_type          = "uint16",
          spatial_resolution = 30,
          scale              = 2.75e-5,
          offset             = -0.2
        )
      )
    )
path <- tempfile(fileext = ".json")
on.exit(unlink(path))
write_item(item, path)
restored <- read_stac(path)
expect_equal(
    restored@properties$`raster:bands`[[1]]$`raster:scale`,
    2.75e-5
  )
