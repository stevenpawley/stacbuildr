# --- raster_band() ---

test_that("raster_band creates an S7 raster_band object", {
  band <- raster_band(data_type = "uint16")

  expect_true(S7::S7_inherits(band, raster_band))
  expect_equal(band@data_type, "uint16")

  as.list(band)
})

test_that("raster_band stores all optional fields", {
  band <- raster_band(
    nodata = 0,
    data_type = "float32",
    spatial_resolution = 10,
    scale = 2.75e-5,
    offset = -0.2,
    unit = "reflectance",
    bits_per_sample = 16
  )

  expect_equal(band@nodata, 0)
  expect_equal(band@data_type, "float32")
  expect_equal(band@spatial_resolution, 10)
  expect_equal(band@scale, 2.75e-5)
  expect_equal(band@offset, -0.2)
  expect_equal(band@unit, "reflectance")
  expect_equal(band@bits_per_sample, 16L)
})


# --- add_raster_extension() ---
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

test_that("add_raster_extension adds schema URI to stac_extensions", {
  item <- make_item() |>
    add_raster_extension(
      bands = list(raster_band(data_type = "uint16"))
    )

  expect_true(
    "https://stac-extensions.github.io/raster/v1.1.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_raster_extension writes raster:bands to item properties", {
  bands <- list(
    raster_band(data_type = "uint16", nodata = 0),
    raster_band(data_type = "uint16", nodata = 0)
  )
  item <- make_item() |>
    add_raster_extension(bands = bands)

  expect_length(item@properties$`raster:bands`, 2L)
  expect_equal(item@properties$`raster:bands`[[1]]$data_type, "uint16")
})

test_that("add_raster_extension writes raster:bands to a named asset", {
  bands <- list(raster_band(data_type = "uint16"))
  item  <- make_item() |>
    add_raster_extension(bands = bands, asset_key = "B4")

  expect_length(item@assets$B4$`raster:bands`, 1L)
  expect_null(item@properties$`raster:bands`)
})

test_that("add_raster_extension errors on missing asset_key", {
  bands <- list(raster_band(data_type = "uint16"))

  expect_error(
    make_item() |>
      add_raster_extension(bands = bands, asset_key = "nonexistent"),
    "does not exist"
  )
})


# --- raster:scale precision regression ---
#
# raster:scale values like 2.75e-5 were previously rounded to 0 in JSON output
# because jsonlite::toJSON() defaults to digits = 4.  The fix adds digits = 15
# to all write_item() / write_catalog() calls.  These tests guard that
# small-magnitude numeric fields survive the write → read round-trip exactly.

test_that("raster:scale survives write/read round-trip precision", {
  item <- make_item() |>
    add_raster_extension(bands = list(
      raster_band(
        nodata = 0,
        data_type = "uint16",
        spatial_resolution = 30,
        scale = 2.75e-5,
        offset = -0.2
      )
    ))

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(item, path)

  restored <- read_stac(path)

  expect_equal(restored@properties$`raster:bands`[[1]]$scale, 2.75e-5)
  expect_equal(restored@properties$`raster:bands`[[1]]$offset, -0.2)
})

test_that("raster:scale is not rounded to zero in raw JSON output", {
  item <- make_item() |>
    add_raster_extension(
      bands = list(raster_band(data_type = "uint16", scale = 2.75e-5))
    )

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(item, path)

  raw_json <- paste(readLines(path, warn = FALSE), collapse = "\n")

  # Must not appear as 0 or 0.0
  expect_no_match(raw_json, '"scale":\\s*0[,\\s]', perl = TRUE)
  # Must contain the actual value
  expect_match(raw_json, '"scale"', fixed = TRUE)

  parsed <- jsonlite::fromJSON(raw_json, simplifyVector = FALSE)
  scale_val <- parsed$properties$`raster:bands`[[1]]$scale
  expect_gt(scale_val, 0)
  expect_equal(scale_val, 2.75e-5)
})

test_that("very small raster:offset survives write/read with full precision", {
  item <- make_item() |>
    add_raster_extension(bands = list(raster_band(
      data_type = "float32",
      scale = 1e-8,
      offset = -1e-6
    )))

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(item, path)

  restored <- read_stac(path)
  expect_equal(restored@properties$`raster:bands`[[1]]$scale, 1e-8)
  expect_equal(restored@properties$`raster:bands`[[1]]$offset, -1e-6)
})

test_that("raster:scale precision holds when bands are on an asset, not item", {
  item <- make_item() |>
    add_raster_extension(
      bands = list(raster_band(data_type = "uint16", scale = 2.75e-5)),
      asset_key = "B4"
    )

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  write_item(item, path)

  restored <- read_stac(path)
  expect_equal(restored@assets$B4$`raster:bands`[[1]]$scale, 2.75e-5)
})
