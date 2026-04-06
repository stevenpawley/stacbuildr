test_that("stac_extent creates a valid extent with closed temporal interval", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(
      list("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z")
    )
  )

  expect_s3_class(extent, "stacbuildr::Extent")
  expect_equal(extent@spatial@bbox[[1]], c(-180, -90, 180, 90))
  expect_equal(extent@temporal@interval[[1]][[1]], "2020-01-01T00:00:00Z")
  expect_equal(extent@temporal@interval[[1]][[2]], "2020-12-31T23:59:59Z")
})

test_that("stac_extent accepts open-ended temporal interval (NULL end)", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2015-01-01T00:00:00Z", NULL))
  )

  expect_null(extent@temporal@interval[[1]][[2]])
})

test_that("stac_extent accepts fully open temporal interval (NULL, NULL)", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list(NULL, NULL))
  )

  expect_null(extent@temporal@interval[[1]][[1]])
  expect_null(extent@temporal@interval[[1]][[2]])
})

test_that("stac_extent accepts multiple spatial bboxes", {
  extent <- stac_extent(
    spatial_bbox = list(
      c(-180, -90, 180, 90),
      c(-120, 30, -110, 40),
      c(-10, 35, 5, 45)
    ),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )

  expect_length(extent@spatial@bbox, 3)
  expect_equal(extent@spatial@bbox[[2]], c(-120, 30, -110, 40))
  expect_equal(extent@spatial@bbox[[3]], c(-10, 35, 5, 45))
})

test_that("stac_extent accepts multiple temporal intervals", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(
      list("2015-01-01T00:00:00Z", "2017-12-31T23:59:59Z"),
      list("2020-01-01T00:00:00Z", NULL)
    )
  )

  expect_length(extent@temporal@interval, 2)
  expect_equal(extent@temporal@interval[[1]][[1]], "2015-01-01T00:00:00Z")
  expect_equal(extent@temporal@interval[[2]][[1]], "2020-01-01T00:00:00Z")
})

test_that("stac_extent accepts a 3D bbox (6 coordinates)", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, -100, 180, 90, 1000)),
    temporal_interval = list(list(NULL, NULL))
  )

  expect_length(extent@spatial@bbox[[1]], 6)
})

test_that("stac_extent serialises correctly with as.list", {
  extent <- stac_extent(
    spatial_bbox = list(c(-10, 35, 5, 45)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )

  lst <- as.list(extent)

  expect_named(lst, c("spatial", "temporal"))
  expect_equal(lst$spatial$bbox[[1]], c(-10, 35, 5, 45))
  expect_equal(lst$temporal$interval[[1]][[1]], "2020-01-01T00:00:00Z")
  expect_null(lst$temporal$interval[[1]][[2]])
})

test_that("stac_extent errors when spatial bbox is empty", {
  expect_error(
    stac_extent(
      spatial_bbox = list(),
      temporal_interval = list(list(NULL, NULL))
    )
  )
})

test_that("stac_extent errors when a bbox has wrong number of coordinates", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(-180, -90, 180)),
      temporal_interval = list(list(NULL, NULL))
    )
  )
})

test_that("stac_extent errors when west > east", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(10, -90, -10, 90)),
      temporal_interval = list(list(NULL, NULL))
    )
  )
})

test_that("stac_extent errors when south > north", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(-180, 90, 180, -90)),
      temporal_interval = list(list(NULL, NULL))
    )
  )
})

test_that("stac_extent errors when temporal interval is empty", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(-180, -90, 180, 90)),
      temporal_interval = list()
    )
  )
})

test_that("stac_extent errors when an interval does not have 2 elements", {
  expect_error(
    stac_extent(
      spatial_bbox = list(c(-180, -90, 180, 90)),
      temporal_interval = list(list("2020-01-01T00:00:00Z"))
    )
  )
})

test_that("stac_extent serialises named interval elements as a JSON array", {
  # list(start=..., end=...) must produce ["...", "..."] not {"start":...}
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(
      list(start = "2020-01-01T00:00:00Z", end = "2021-01-01T00:00:00Z")
    )
  )

  json <- jsonlite::toJSON(as.list(extent), auto_unbox = TRUE)
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)

  interval <- parsed$temporal$interval[[1]]
  expect_type(interval, "list")
  expect_null(names(interval))
  expect_equal(interval[[1]], "2020-01-01T00:00:00Z")
  expect_equal(interval[[2]], "2021-01-01T00:00:00Z")
})

test_that("stac_extent round-trips through a stac_collection and validates", {
  extent <- stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )

  collection <- stac_collection(
    id = "test-extent-collection",
    description = "Collection for extent test",
    license = "CC0-1.0",
    extent = extent
  )

  result <- validate_stac(collection)
  expect_true(result$valid)
})
