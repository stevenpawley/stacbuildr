skip_if_not_installed("stars")
skip_if_not_installed("sf")

tif <- system.file("tif/L7_ETMs.tif", package = "stars")
sf_file <- system.file("shape/nc.shp", package = "sf")

test_that("thumbnail_from_raster returns a valid thumbnail asset", {
  r <- stars::read_stars(tif, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_raster(r, path = path)

  expect_true(file.exists(path))
  expect_equal(asset$type, "image/png")
  expect_equal(asset$roles, c("thumbnail"))
  expect_equal(asset$href, gsub("\\\\", "/", normalizePath(path)))
})

test_that("thumbnail_from_raster accepts a title", {
  r <- stars::read_stars(tif, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_raster(r, path = path, title = "Preview")

  expect_equal(asset$title, "Preview")
})

test_that("thumbnail_from_raster accepts custom dimensions", {
  r <- stars::read_stars(tif, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  thumbnail_from_raster(r, path = path, width = 128, height = 128)

  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

test_that("thumbnail_from_raster errors on non-stars input", {
  path <- tempfile(fileext = ".png")
  expect_error(thumbnail_from_raster(list(), path = path), "must be a stars object")
})

test_that("thumbnail_from_raster errors when path is missing", {
  r <- stars::read_stars(tif, quiet = TRUE)
  expect_error(thumbnail_from_raster(r, path = ""), "'path' is required")
})

test_that("thumbnail_from_sf returns a valid thumbnail asset", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  asset <- thumbnail_from_sf(nc, path = path)

  expect_true(file.exists(path))
  expect_equal(asset$type, "image/png")
  expect_equal(asset$roles, c("thumbnail"))
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
  r <- stars::read_stars(tif, quiet = TRUE)
  path <- tempfile(fileext = ".png")
  on.exit(unlink(path))

  item <- item_from_raster(
    r,
    href = tif,
    id = "L7_ETMs",
    datetime = "2023-06-15T10:30:00Z"
  )
  asset <- thumbnail_from_raster(r, path = path)
  item <- add_asset(item, key = "thumbnail", asset = asset)

  expect_true("thumbnail" %in% names(item@assets))
  expect_equal(item@assets$thumbnail$roles, c("thumbnail"))
  expect_equal(item@assets$thumbnail$type, "image/png")
})
