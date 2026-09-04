skip_if_not_installed("terra")
skip_if_not_installed("sf")

tif <- test_path("testdata", "L7_ETMs.tif")

test_that("item_from_terra creates a valid item from a SpatRaster", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )

  expect_s3_class(item, "stac_item")
  expect_equal(item@id, "L7_ETMs")
  expect_equal(item@type, "Feature")
  expect_equal(item@properties$datetime, "2023-06-15T10:30:00Z")

  # Geometry should be a polygon (extent reprojected to WGS84)
  expect_equal(item@geometry$type, "Polygon")

  # bbox should be in WGS84 (northeast Brazil, ~35°W / 8°S)
  bbox <- item@bbox
  expect_length(bbox, 4)
  expect_true(bbox[1] > -36 && bbox[1] < -34) # xmin
  expect_true(bbox[2] > -9 && bbox[2] < -7) # ymin
  expect_true(bbox[3] > -36 && bbox[3] < -34) # xmax
  expect_true(bbox[4] > -9 && bbox[4] < -7) # ymax
})

test_that("item_from_terra derives id from href when id is NULL", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    datetime = "2023-06-15T10:30:00Z"
  )

  expect_equal(item@id, "L7_ETMs")
})

test_that("item_from_terra adds the main asset with correct fields", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z",
    asset_key = "data",
    asset_roles = c("data")
  )

  expect_true("data" %in% names(item@assets))
  expect_equal(item@assets$data$href, gsub("\\\\", "/", normalizePath(tif)))
  expect_equal(item@assets$data$type, "image/tiff; application=geotiff")
  expect_equal(item@assets$data$roles, list("data"))
})

test_that("item_from_terra adds raster extension with 6 band objects", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z",
    add_raster_bands = TRUE
  )

  raster_ext <- "https://stac-extensions.github.io/raster/v1.1.0/schema.json"
  expect_true(raster_ext %in% item@stac_extensions)

  bands <- item@assets$data$`raster:bands`
  expect_length(bands, 6)
  expect_equal(bands[[1]]$data_type, "uint8")
  expect_equal(bands[[1]]$spatial_resolution, 28.5)
})

test_that("item_from_terra skips raster extension when add_raster_bands is FALSE", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z",
    add_raster_bands = FALSE
  )

  raster_ext <- "https://stac-extensions.github.io/raster/v1.1.0/schema.json"
  expect_false(raster_ext %in% item@stac_extensions)
  expect_null(item@assets$data$`raster:bands`)
})

test_that("item_from_terra adds projection extension for non-WGS84 CRS", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )

  proj_ext <- "https://stac-extensions.github.io/projection/v1.1.0/schema.json"
  expect_true(proj_ext %in% item@stac_extensions)

  expect_equal(item@properties$`proj:epsg`, 31985L)
  expect_false(is.null(item@properties$`proj:wkt2`))
  expect_equal(item@properties$`proj:shape`, c(352L, 349L)) # rows (y), cols (x)
  expect_length(item@properties$`proj:transform`, 6)
  expect_equal(item@properties$`proj:transform`[[1]], 28.5) # x pixel size
  expect_equal(item@properties$`proj:transform`[[5]], -28.5) # y pixel size (negative)
})

test_that("item_from_terra validates correctly", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )

  result <- validate_stac(item)
  expect_true(result$valid)
})

test_that("bands_from_terra returns one band object per band", {
  r <- terra::rast(tif)
  bands <- bands_from_terra(r)

  expect_length(bands, 6)
  expect_equal(bands[[1]]@data_type, "uint8")
  expect_equal(bands[[1]]@spatial_resolution, 28.5)
  expect_length(bands[[1]]@statistics, 0)
})

test_that("bands_from_terra calculates statistics when requested", {
  r <- terra::rast(tif)
  bands <- bands_from_terra(r, calculate_statistics = TRUE)

  expect_length(bands, 6)

  for (band in bands) {
    expect_true(length(band@statistics) > 0)
    expect_true(band@statistics$minimum <= band@statistics$maximum)
    expect_true(band@statistics$valid_percent > 0)
    expect_true(band@statistics$valid_percent <= 100)
  }
})

test_that("item_from_terra errors on non-SpatRaster input", {
  expect_error(
    item_from_terra(
      "not_a_SpatRaster",
      href = tif,
      datetime = "2023-06-15T10:30:00Z"
    ),
    "'terra_obj' must be a SpatRaster object"
  )
})

test_that("item_from_terra works without href when id is supplied", {
  r <- terra::rast(tif)

  item <- item_from_terra(
    r,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )

  expect_equal(item@id, "L7_ETMs")
  expect_length(item@assets, 0)
})

test_that("item_from_terra errors when both href and id are NULL", {
  r <- terra::rast(tif)

  expect_error(
    item_from_terra(r, datetime = "2023-06-15T10:30:00Z"),
    "'id' is required when 'href' is not provided"
  )
})

test_that("item_from_terra handles CRSs without an EPSG code", {
  skip_if_not_installed("terra")

  make <- function(crs) {
    r <- terra::rast(
      nrows = 4, ncols = 4, xmin = 0, xmax = 1, ymin = 0, ymax = 1, crs = crs
    )
    terra::values(r) <- 1
    r
  }

  # OGC:CRS84 is WGS84 lon/lat but has no EPSG code; proj:epsg must be left
  # unset rather than coerced from "CRS84" to NA
  item <- expect_no_warning(
    item_from_terra(make("OGC:CRS84"), id = "crs84", datetime = "2020-01-01T00:00:00Z")
  )
  expect_null(item@properties$`proj:epsg`)
  expect_equal(item@bbox, c(0, 0, 1, 1), ignore_attr = TRUE)

  # A genuine EPSG code is still recorded
  utm <- item_from_terra(make("EPSG:32633"), id = "utm", datetime = "2020-01-01T00:00:00Z")
  expect_equal(utm@properties$`proj:epsg`, 32633L)
})

test_that("item_from_terra reports a missing CRS instead of failing in st_crs", {
  skip_if_not_installed("terra")

  r <- terra::rast(
    nrows = 4, ncols = 4, xmin = 0, xmax = 1, ymin = 0, ymax = 1, crs = ""
  )
  terra::values(r) <- 1

  # terra reports a missing CRS as "", which st_crs() rejects as "invalid crs"
  expect_error(
    item_from_terra(r, id = "none", datetime = "2020-01-01T00:00:00Z"),
    "no CRS"
  )

  # reproject_to_wgs84 = FALSE is the escape hatch for lon/lat with no CRS set
  expect_no_error(
    item_from_terra(
      r, id = "none", datetime = "2020-01-01T00:00:00Z",
      reproject_to_wgs84 = FALSE
    )
  )
})
