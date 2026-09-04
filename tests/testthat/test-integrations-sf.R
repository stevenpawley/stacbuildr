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
  expect_equal(item@assets$source$href, gsub("\\\\", "/", normalizePath(sf_file)))
  expect_equal(item@assets$source$roles, list("data"))
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


test_that("geometry_from_sf returns a bare geometry, not a Feature", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  # sf_geojson(atomise = TRUE) only drops the Feature wrapper when the sf
  # object carries no attribute columns, so a single row of a normal sf table
  # used to serialise as a whole Feature with a nested "geometry" member.
  geometry <- geometry_from_sf(nc[1, ])

  expect_setequal(names(geometry), c("type", "coordinates"))
  expect_equal(geometry$type, "MultiPolygon")
  expect_false("properties" %in% names(geometry))

  # geometry-only input keeps working
  geometry_only <- geometry_from_sf(sf::st_sf(geometry = sf::st_geometry(nc[1, ])))
  expect_setequal(names(geometry_only), c("type", "coordinates"))
})

test_that("geometry_from_sf preserves full coordinate precision", {
  nc <- sf::st_read(sf_file, quiet = TRUE)
  one <- nc[1, ]

  geometry <- geometry_from_sf(one)
  first <- unlist(geometry$coordinates[[1]][[1]][[1]])
  expected <- as.numeric(sf::st_coordinates(one)[1, 1:2])

  expect_equal(first, expected, tolerance = 0)
})

test_that("item_from_sf produces a schema-shaped geometry for one feature", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  item <- item_from_sf(nc[1, ], id = "nc-1", datetime = "2025-01-01T00:00:00Z")

  expect_setequal(names(item@geometry), c("type", "coordinates"))
  expect_true(item@geometry$type %in% c("Polygon", "MultiPolygon"))
})

test_that("geometry_from_sf rejects an sf object with no geometries", {
  nc <- sf::st_read(sf_file, quiet = TRUE)

  expect_error(geometry_from_sf(nc[0, ]), "no geometries")
})

test_that("item_from_sf accepts any WGS84 lon/lat CRS, not just EPSG:4326", {
  # st_crs(x)$epsg is NA for a CRS not given as an EPSG code, so comparing the
  # code rejected OGC:CRS84 even though it is WGS84 longitude/latitude
  crs84 <- sf::st_sf(
    a = 1,
    geometry = sf::st_sfc(sf::st_point(c(10, 20)), crs = "OGC:CRS84")
  )

  item <- item_from_sf(crs84, id = "crs84", datetime = "2020-01-01T00:00:00Z")
  expect_equal(item@bbox, c(10, 20, 10, 20), ignore_attr = TRUE)
})

test_that("item_from_sf reprojects a non-WGS84 CRS", {
  webmerc <- sf::st_sf(
    a = 1,
    geometry = sf::st_sfc(sf::st_point(c(1113195, 2273031)), crs = 3857)
  )

  item <- item_from_sf(webmerc, id = "3857", datetime = "2020-01-01T00:00:00Z")
  expect_equal(item@bbox[1:2], c(10, 20), tolerance = 1e-4, ignore_attr = TRUE)
})

test_that("item_from_sf reports a missing CRS instead of failing on NA", {
  no_crs <- sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(c(10, 20))))

  # Previously "missing value where TRUE/FALSE needed" from NA != 4326
  expect_error(
    item_from_sf(no_crs, id = "none", datetime = "2020-01-01T00:00:00Z"),
    "no CRS"
  )
})
