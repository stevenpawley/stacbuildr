demo_item <- function(id = "s01", i = 1, cloud = 7.5, geometry = "polygon") {
  geom <- switch(
    geometry,
    polygon = list(type = "Polygon", coordinates = list(list(
      c(-114 + i / 10, 51), c(-113 + i / 10, 51), c(-113 + i / 10, 52),
      c(-114 + i / 10, 52), c(-114 + i / 10, 51)
    ))),
    point = list(type = "Point", coordinates = c(-114 + i / 10, 51)),
    none = NULL
  )
  stac_item(
    id = id,
    geometry = geom,
    bbox = if (is.null(geom)) NULL else c(-114 + i / 10, 51, -113 + i / 10, 52),
    datetime = sprintf("2024-%02d-01T00:00:00Z", i),
    properties = list(`eo:cloud_cover` = cloud)
  )
}

demo_collection <- function(n = 3) {
  coll <- stac_collection(
    id = "scenes",
    description = "Example",
    license = "CC-BY-4.0",
    extent = stac_extent(
      spatial_bbox = list(c(-115, 50, -113, 52)),
      temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
    )
  )
  for (i in seq_len(n)) {
    coll <- add_item(coll, demo_item(sprintf("s%02d", i), i, i * 7.5))
  }
  coll
}

# length ------------------------------------------------------------------

test_that("length() counts items and agrees with count_items()", {
  coll <- demo_collection(3)
  expect_equal(length(coll), 3L)
  expect_equal(length(coll), count_items(coll))
})

test_that("length() is 0 for a catalog with no items", {
  expect_equal(length(stac_catalog(id = "c", description = "d")), 0L)
})

test_that("length() counts links, so it survives a round trip to disk", {
  root <- add_child(stac_catalog(id = "root", description = "d"), demo_collection(2))
  dir <- withr::local_tempdir()
  suppressMessages(write_stac(root, dir))

  back <- read_stac(file.path(dir, "scenes", "collection.json"))
  expect_equal(length(back), 2L)
})

test_that("length() counts items, not child catalogs", {
  root <- add_child(stac_catalog(id = "root", description = "d"), demo_collection(2))
  # The child's items are not the root's
  expect_equal(length(root), 0L)
  expect_length(get_children(root), 1L)
})

# as.data.frame -----------------------------------------------------------

test_that("as.data.frame() gives one row per item", {
  df <- as.data.frame(demo_collection(3))
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 3L)
  expect_equal(df$id, c("s01", "s02", "s03"))
})

test_that("as.data.frame() leads with id, collection and datetime", {
  df <- as.data.frame(demo_collection(1))
  expect_equal(names(df)[1:3], c("id", "collection", "datetime"))
})

test_that("as.data.frame() promotes properties to columns", {
  df <- as.data.frame(demo_collection(3))
  expect_true("eo:cloud_cover" %in% names(df))
  expect_equal(df$`eo:cloud_cover`, c(7.5, 15, 22.5))
})

test_that("as.data.frame() fills a property missing from an item with NA", {
  coll <- add_item(
    demo_collection(1),
    stac_item(
      id = "odd",
      geometry = list(type = "Point", coordinates = c(0, 0)),
      bbox = c(0, 0, 0, 0),
      datetime = "2024-06-01T00:00:00Z",
      properties = list(`custom:field` = "only here")
    )
  )
  df <- as.data.frame(coll)

  expect_equal(nrow(df), 2L)
  expect_true(is.na(df$`custom:field`[1]))
  expect_equal(df$`custom:field`[2], "only here")
  expect_true(is.na(df$`eo:cloud_cover`[2]))
})

test_that("as.data.frame() uses a list column for non-scalar properties", {
  item <- add_projection_extension(
    demo_item(),
    code = "EPSG:32612",
    transform = c(30, 0, 0, 0, -30, 0)
  )
  df <- as.data.frame(item)

  expect_true(is.list(df$`proj:transform`))
  expect_equal(df$`proj:transform`[[1]], c(30, 0, 0, 0, -30, 0))
  # A scalar property alongside it stays a plain column
  expect_type(df$`proj:code`, "character")
})

test_that("as.data.frame() on a single item gives one row", {
  df <- as.data.frame(demo_item("solo"))
  expect_equal(nrow(df), 1L)
  expect_equal(df$id, "solo")
})

test_that("as.data.frame() gives a zero-row frame for an empty catalog", {
  df <- as.data.frame(stac_catalog(id = "c", description = "d"))
  expect_equal(nrow(df), 0L)
  expect_true(all(c("id", "collection") %in% names(df)))
})

# st_as_sf ----------------------------------------------------------------

test_that("st_as_sf() returns an sf object in EPSG:4326", {
  s <- sf::st_as_sf(demo_collection(3))
  expect_s3_class(s, "sf")
  expect_equal(nrow(s), 3L)
  expect_equal(sf::st_crs(s)$epsg, 4326L)
})

test_that("st_as_sf() reconstructs polygon footprints, not just points", {
  s <- sf::st_as_sf(demo_collection(2))
  expect_equal(as.character(unique(sf::st_geometry_type(s))), "POLYGON")
  # Five coordinates: the ring closes back on the first corner
  expect_equal(nrow(sf::st_coordinates(s[1, ])), 5L)
})

test_that("st_as_sf() carries the property columns through", {
  s <- sf::st_as_sf(demo_collection(3))
  expect_true(all(c("id", "datetime", "eo:cloud_cover") %in% names(s)))
  expect_equal(nrow(s[s$`eo:cloud_cover` < 20, ]), 2L)
})

test_that("st_as_sf() keeps an item with a null geometry", {
  coll <- add_item(demo_collection(1), demo_item("nogeom", geometry = "none"))
  s <- sf::st_as_sf(coll)

  expect_equal(nrow(s), 2L)
  expect_true(sf::st_is_empty(s$geometry[2]))
})

test_that("st_as_sf() on a single item gives one row", {
  s <- sf::st_as_sf(demo_item("solo"))
  expect_s3_class(s, "sf")
  expect_equal(nrow(s), 1L)
})

test_that("st_as_sf() gives a zero-row sf for an empty catalog", {
  s <- sf::st_as_sf(stac_catalog(id = "c", description = "d"))
  expect_s3_class(s, "sf")
  expect_equal(nrow(s), 0L)
})

# resolve -----------------------------------------------------------------

test_that("resolve = TRUE reads items back from their links", {
  root <- add_child(stac_catalog(id = "root", description = "d"), demo_collection(2))
  dir <- withr::local_tempdir()
  suppressMessages(write_stac(root, dir))
  back <- read_stac(file.path(dir, "scenes", "collection.json"))

  df <- as.data.frame(back, resolve = TRUE, base_path = file.path(dir, "scenes"))
  expect_equal(nrow(df), 2L)
  expect_equal(df$id, c("s01", "s02"))

  s <- sf::st_as_sf(back, resolve = TRUE, base_path = file.path(dir, "scenes"))
  expect_equal(nrow(s), 2L)
  expect_equal(sf::st_crs(s)$epsg, 4326L)
})

test_that("linked-but-unresolved items warn rather than give a silent empty table", {
  root <- add_child(stac_catalog(id = "root", description = "d"), demo_collection(2))
  dir <- withr::local_tempdir()
  suppressMessages(write_stac(root, dir))
  back <- read_stac(file.path(dir, "scenes", "collection.json"))

  expect_warning(df <- as.data.frame(back), "not held in memory")
  expect_equal(nrow(df), 0L)
})

test_that("an empty catalog does not warn", {
  expect_no_warning(as.data.frame(stac_catalog(id = "c", description = "d")))
})

# sf accessors on an item -------------------------------------------------

test_that("st_geometry() returns the item footprint", {
  g <- sf::st_geometry(demo_item())
  expect_s3_class(g, "sfc")
  expect_length(g, 1L)
  expect_equal(as.character(sf::st_geometry_type(g)), "POLYGON")
})

test_that("st_crs() is always 4326, since STAC geometry is WGS84", {
  expect_equal(sf::st_crs(demo_item())$epsg, 4326L)
  # Even when the item records a projected native CRS
  projected <- add_projection_extension(demo_item(), code = "EPSG:32612")
  expect_equal(sf::st_crs(projected)$epsg, 4326L)
})

test_that("st_bbox() uses the item's own bbox field", {
  bb <- sf::st_bbox(demo_item(i = 1))
  expect_s3_class(bb, "bbox")
  expect_equal(unname(bb[["xmin"]]), -113.9)
  expect_equal(unname(bb[["ymax"]]), 52)
  expect_equal(sf::st_crs(bb)$epsg, 4326L)
})

test_that("st_bbox() drops the elevation pair from a 3D STAC bbox", {
  item <- stac_item(
    id = "cloud",
    geometry = list(type = "Point", coordinates = c(-114, 51)),
    bbox = c(-114, 51, 100, -113, 52, 900),
    datetime = "2024-06-01T00:00:00Z"
  )
  bb <- sf::st_bbox(item)

  expect_length(bb, 4L)
  expect_equal(unname(bb[["xmax"]]), -113)
  expect_equal(unname(bb[["ymax"]]), 52)
})

test_that("st_bbox() gives an empty bbox for a non-spatial item", {
  # stac_item() requires a bbox whenever there is a geometry, so the only way
  # to reach the geometry fallback is an item with neither.
  item <- stac_item(
    id = "nobbox",
    geometry = NULL,
    datetime = "2024-06-01T00:00:00Z"
  )
  bb <- sf::st_bbox(item)

  expect_s3_class(bb, "bbox")
  expect_true(all(is.na(unclass(bb))))
})

# subsetting --------------------------------------------------------------

test_that("[[ returns a single item, by position or id", {
  coll <- demo_collection(3)
  expect_equal(coll[[2]]@id, "s02")
  expect_equal(coll[["s03"]]@id, "s03")
  expect_true(inherits(coll[[1]], "stac_item"))
})

test_that("[ returns a list of items, by position or id", {
  coll <- demo_collection(3)
  expect_type(coll[1:2], "list")
  expect_length(coll[1:2], 2L)
  expect_equal(vapply(coll[c("s01", "s03")], function(i) i@id, character(1)),
               c("s01", "s03"))
})

test_that("subsetting by an unknown id errors and lists what is available", {
  coll <- demo_collection(2)
  expect_error(coll[["nope"]], "No item with id")
  expect_error(coll[["nope"]], "s01")
  expect_error(coll["nope"], "No item with id")
})

test_that("[[ rejects a subscript selecting more than one item", {
  coll <- demo_collection(3)
  expect_error(coll[[c("s01", "s02")]], "exactly one item")
})
