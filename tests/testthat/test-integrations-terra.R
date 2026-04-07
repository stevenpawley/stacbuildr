skip_if_not_installed("terra")

elev_tif  <- system.file("ex/elev.tif",  package = "terra")  # 1-band, WGS84
logo_tif  <- system.file("ex/logo.tif",  package = "terra")  # 3-band, no CRS

# ── item_from_spatraster ──────────────────────────────────────────────────────

test_that("item_from_spatraster creates a valid stac_item", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(
    r,
    href     = elev_tif,
    id       = "elev",
    datetime = "2023-06-15T10:30:00Z"
  )

  expect_s3_class(item, "stac_item")
  expect_equal(item@id, "elev")
  expect_equal(item@type, "Feature")
  expect_equal(item@properties$datetime, "2023-06-15T10:30:00Z")
})

test_that("item_from_spatraster derives id from href when id is NULL", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(r, href = elev_tif, datetime = "2023-01-01T00:00:00Z")

  expect_equal(item@id, "elev")
})

test_that("item_from_spatraster errors when id and href are both NULL", {
  r <- terra::rast(elev_tif)
  expect_error(
    item_from_spatraster(r, datetime = "2023-01-01T00:00:00Z"),
    "'id' is required"
  )
})

test_that("item_from_spatraster geometry is a Polygon in WGS84", {
  r    <- terra::rast(elev_tif)   # already WGS84
  item <- item_from_spatraster(r, id = "elev", datetime = "2023-01-01T00:00:00Z")

  expect_equal(item@geometry$type, "Polygon")
  bbox <- item@bbox
  expect_length(bbox, 4L)
  # elev.tif covers a small area in Luxembourg/Belgium ~5.7–6.5°E, 49.4–50.2°N
  expect_true(bbox[1] > 5 && bbox[1] < 7)
  expect_true(bbox[2] > 48 && bbox[2] < 51)
})

test_that("item_from_spatraster adds the main asset with correct fields", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(
    r,
    href      = elev_tif,
    id        = "elev",
    datetime  = "2023-01-01T00:00:00Z",
    asset_key = "data"
  )

  expect_true("data" %in% names(item@assets))
  expect_equal(item@assets$data$href, gsub("\\\\", "/", normalizePath(elev_tif)))
  expect_equal(item@assets$data$type, "image/tiff; application=geotiff")
  expect_equal(item@assets$data$roles, c("data"))
})

test_that("item_from_spatraster does not add asset when href is NULL", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(r, id = "elev", datetime = "2023-01-01T00:00:00Z")

  expect_length(item@assets, 0L)
})

test_that("item_from_spatraster warns when datetime is NULL", {
  r <- terra::rast(elev_tif)
  expect_warning(
    item_from_spatraster(r, id = "elev"),
    "No datetime provided"
  )
})

test_that("item_from_spatraster adds raster extension by default", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(
    r,
    href     = elev_tif,
    id       = "elev",
    datetime = "2023-01-01T00:00:00Z"
  )

  ext_uris <- item@stac_extensions %||% character(0)
  expect_true(any(grepl("raster", ext_uris)))
})

test_that("item_from_spatraster skips raster extension when add_raster_bands = FALSE", {
  r    <- terra::rast(elev_tif)
  item <- item_from_spatraster(
    r,
    id               = "elev",
    datetime         = "2023-01-01T00:00:00Z",
    add_raster_bands = FALSE
  )

  ext_uris <- item@stac_extensions %||% character(0)
  expect_false(any(grepl("raster", ext_uris)))
})

test_that("item_from_spatraster adds projection extension for non-WGS84 CRS", {
  # Project elev to a UTM CRS so it is no longer WGS84
  r_utm <- terra::project(terra::rast(elev_tif), "EPSG:32632")
  item  <- item_from_spatraster(
    r_utm,
    id       = "elev-utm",
    datetime = "2023-01-01T00:00:00Z"
  )

  ext_uris <- item@stac_extensions %||% character(0)
  expect_true(any(grepl("projection", ext_uris)))
  expect_equal(item@properties$`proj:epsg`, 32632L)
  expect_false(is.null(item@properties$`proj:shape`))
  expect_false(is.null(item@properties$`proj:transform`))
})

test_that("item_from_spatraster does not add projection extension for WGS84", {
  r    <- terra::rast(elev_tif)   # already EPSG:4326
  item <- item_from_spatraster(r, id = "elev", datetime = "2023-01-01T00:00:00Z")

  ext_uris <- item@stac_extensions %||% character(0)
  expect_false(any(grepl("projection", ext_uris)))
})

test_that("item_from_spatraster reprojects geometry to WGS84 from UTM", {
  r_utm <- terra::project(terra::rast(elev_tif), "EPSG:32632")
  item  <- item_from_spatraster(
    r_utm,
    id                = "elev-utm",
    datetime          = "2023-01-01T00:00:00Z",
    reproject_to_wgs84 = TRUE
  )

  # bbox should still be in WGS84 coordinates
  bbox <- item@bbox
  expect_true(bbox[1] > -180 && bbox[1] < 180)
  expect_true(bbox[2] > -90  && bbox[2] < 90)
})

test_that("item_from_spatraster errors on non-SpatRaster input", {
  expect_error(
    item_from_spatraster(list(), id = "x", datetime = "2023-01-01T00:00:00Z"),
    "must be a SpatRaster"
  )
})

# ── bands_from_spatraster ─────────────────────────────────────────────────────

test_that("bands_from_spatraster returns one band object per layer", {
  r     <- terra::rast(elev_tif)
  bands <- bands_from_spatraster(r)

  expect_length(bands, 1L)
  expect_type(bands, "list")
})

test_that("bands_from_spatraster returns correct data_type for INT2S", {
  r     <- terra::rast(elev_tif)   # INT2S on disk
  bands <- bands_from_spatraster(r)

  expect_equal(bands[[1]]$data_type, "int16")
})

test_that("bands_from_spatraster returns correct data_type for INT1U", {
  r     <- terra::rast(logo_tif)   # INT1U (uint8) RGB
  bands <- bands_from_spatraster(r)

  expect_length(bands, 3L)
  expect_true(all(vapply(bands, function(b) b$data_type, character(1)) == "uint8"))
})

test_that("bands_from_spatraster includes spatial_resolution", {
  r     <- terra::rast(elev_tif)
  bands <- bands_from_spatraster(r)

  expect_true(!is.null(bands[[1]]$`raster:spatial_resolution`))
  expect_gt(bands[[1]]$`raster:spatial_resolution`, 0)
})

test_that("bands_from_spatraster calculates statistics when requested", {
  r     <- terra::rast(elev_tif)
  bands <- bands_from_spatraster(r, calculate_statistics = TRUE)

  st <- bands[[1]]$statistics
  expect_false(is.null(st))
  expect_true(st$minimum < st$maximum)
  expect_true(st$valid_percent > 0 && st$valid_percent <= 100)
})

test_that("bands_from_spatraster does not calculate statistics by default", {
  r     <- terra::rast(elev_tif)
  bands <- bands_from_spatraster(r)

  expect_null(bands[[1]]$statistics)
})

test_that("bands_from_spatraster errors on non-SpatRaster input", {
  expect_error(bands_from_spatraster(list()), "must be a SpatRaster")
})

# ── thumbnail_from_spatraster ─────────────────────────────────────────────────

test_that("thumbnail_from_spatraster creates a PNG for a single-band raster", {
  r    <- terra::rast(elev_tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_spatraster(r, path = path)

  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
  expect_equal(asset$type, "image/png")
  expect_equal(asset$roles, c("thumbnail"))
  expect_equal(asset$href, gsub("\\\\", "/", normalizePath(path)))
})

test_that("thumbnail_from_spatraster creates a PNG for a multi-band raster", {
  r    <- terra::rast(logo_tif)   # 3-band RGB
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_spatraster(r, path = path)

  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
  expect_equal(asset$type, "image/png")
})

test_that("thumbnail_from_spatraster accepts a title", {
  r    <- terra::rast(elev_tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_spatraster(r, path = path, title = "Elevation")

  expect_equal(asset$title, "Elevation")
})

test_that("thumbnail_from_spatraster errors on non-SpatRaster input", {
  expect_error(thumbnail_from_spatraster(list(), path = "x.png"), "must be a SpatRaster")
})

test_that("thumbnail_from_spatraster errors when path is empty", {
  r <- terra::rast(elev_tif)
  expect_error(thumbnail_from_spatraster(r, path = ""), "'path' is required")
})

test_that("thumbnail asset from SpatRaster can be added to a stac_item", {
  r    <- terra::rast(elev_tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  item  <- item_from_spatraster(r, id = "elev", datetime = "2023-01-01T00:00:00Z")
  asset <- thumbnail_from_spatraster(r, path = path)
  item  <- add_asset(item, key = "thumbnail", asset = asset)

  expect_true("thumbnail" %in% names(item@assets))
  expect_equal(item@assets$thumbnail$roles, c("thumbnail"))
  expect_equal(item@assets$thumbnail$type, "image/png")
})

# ── terra_dtype ───────────────────────────────────────────────────────────────

test_that("terra_dtype maps all expected terra type codes", {
  expect_equal(terra_dtype("INT1U"),  "uint8")
  expect_equal(terra_dtype("INT2U"),  "uint16")
  expect_equal(terra_dtype("INT2S"),  "int16")
  expect_equal(terra_dtype("INT4U"),  "uint32")
  expect_equal(terra_dtype("INT4S"),  "int32")
  expect_equal(terra_dtype("FLT4S"),  "float32")
  expect_equal(terra_dtype("FLT8S"),  "float64")
  expect_equal(terra_dtype("XXXXXX"), "other")
})
