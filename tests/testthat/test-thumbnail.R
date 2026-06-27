skip_if_not_installed("terra")
skip_if_not_installed("sf")

tif <- test_path("testdata", "L7_ETMs.tif")
sf_file <- system.file("shape/nc.shp", package = "sf")

test_that("preview_from_terra returns a valid thumbnail asset", {
  r <- terra::rast(tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- preview_from_terra(r, path = path)

  expect_true(file.exists(path))
  expect_equal(asset$type, "image/png")
  expect_equal(asset$roles, list("overview"))
  expect_equal(asset$href, gsub("\\\\", "/", normalizePath(path)))
})

test_that("preview_from_terra accepts a title", {
  r <- terra::rast(tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- preview_from_terra(r, path = path, title = "Preview")

  expect_equal(asset$title, "Preview")
})

test_that("preview_from_terra accepts custom dimensions", {
  r <- terra::rast(tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  preview_from_terra(r, path = path, width = 128, height = 128)

  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

test_that("preview_from_terra errors on non-SpatRaster input", {
  path <- tempfile(fileext = ".png")
  expect_error(preview_from_terra(list(), path = path), "must be a SpatRaster object")
})

test_that("preview_from_terra errors when path is missing", {
  r <- terra::rast(tif)
  expect_error(preview_from_terra(r, path = ""), "'path' is required")
})

test_that("thumbnail_from_sf returns a valid thumbnail asset", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_sf(nc, path = path)

  expect_true(file.exists(path))
  expect_equal(asset$type, "image/png")
  expect_equal(asset$roles, list("thumbnail"))
  expect_equal(asset$href, gsub("\\\\", "/", normalizePath(path)))
})

test_that("thumbnail_from_sf accepts a title", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_sf(nc, path = path, title = "Overview")

  expect_equal(asset$title, "Overview")
})

test_that("thumbnail_from_sf errors on non-sf input", {
  path <- tempfile(fileext = ".png")
  expect_error(thumbnail_from_sf(list(), path = path), "must be an sf object")
})

test_that("thumbnail_from_sf errors when path is missing", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  expect_error(thumbnail_from_sf(nc, path = ""), "'path' is required")
})

test_that("thumbnail asset can be added to a stac item", {
  r <- terra::rast(tif)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  item <- item_from_terra(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )
  asset <- preview_from_terra(r, path = path)
  item <- add_asset(item, key = "thumbnail", asset = asset)

  expect_true("thumbnail" %in% names(item@assets))
  expect_equal(item@assets$thumbnail$roles, list("overview"))
  expect_equal(item@assets$thumbnail$type, "image/png")
})
