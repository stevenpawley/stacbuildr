sf_file <- system.file("shape/nc.shp", package = "sf")

skip_if_not_installed("sf")
skip_if_not_installed("geojsonsf")

test_that("item_from_sf creates a valid item from a multi-feature sf object", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(nc, id = "nc", datetime = "2025-01-01T00:00:00Z")

  expect_s3_class(item, "stac_item")
  expect_equal(item@id, "nc")
  expect_equal(item@type, "Feature")
  expect_equal(item@properties$datetime, "2025-01-01T00:00:00Z")
})

test_that("item_from_sf unions all features into a single geometry", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(nc, id = "nc", datetime = "2025-01-01T00:00:00Z")

  # 100 county polygons should be unioned into one MultiPolygon
  expect_equal(item@geometry$type, "MultiPolygon")
  expect_false(is.null(item@geometry$coordinates))
})

test_that("item_from_sf reprojects non-WGS84 input to WGS84", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  # nc.shp is EPSG:4267 (NAD27), not WGS84
  expect_false(isTRUE(sf::st_crs(nc)$epsg == 4326L))

  item <- item_from_sf(nc, id = "nc", datetime = "2025-01-01T00:00:00Z")

  # bbox should cover North Carolina in WGS84 degrees
  bbox <- item@bbox
  expect_length(bbox, 4)
  expect_true(bbox[1] > -85 && bbox[1] < -84) # xmin
  expect_true(bbox[2] > 33 && bbox[2] < 34) # ymin
  expect_true(bbox[3] > -76 && bbox[3] < -75) # xmax
  expect_true(bbox[4] > 36 && bbox[4] < 37) # ymax
})

test_that("item_from_sf adds a source asset when href is provided", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(
    nc,
    id = "nc",
    datetime = "2025-01-01T00:00:00Z",
    href = sf_file
  )

  expect_true("source" %in% names(item@assets))
  expect_equal(item@assets$source$href, sf_file)
  expect_equal(item@assets$source$roles, c("data"))
})

test_that("item_from_sf creates no assets when href is not provided", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  item <- item_from_sf(nc, id = "nc", datetime = "2025-01-01T00:00:00Z")
  expect_length(item@assets, 0)
})

test_that("item_from_sf passes additional properties through", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(
    nc,
    id = "nc",
    datetime = "2025-01-01T00:00:00Z",
    properties = list(title = "North Carolina Counties")
  )

  expect_equal(item@properties$title, "North Carolina Counties")
})

test_that("item_from_sf produces a valid STAC item", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(
    nc,
    id = "nc",
    datetime = "2025-01-01T00:00:00Z",
    href = sf_file
  )

  result <- validate_stac(item)
  expect_true(result$valid)
})

test_that("item_from_sf errors on non-sf input", {
  expect_error(
    item_from_sf(list(), id = "nc", datetime = "2025-01-01T00:00:00Z"),
    "'sf_obj' must be an sf object"
  )
})

