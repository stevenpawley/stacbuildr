# Helper to create a minimal stac_item for testing
make_item <- function(id, bbox, datetime = NULL, start_datetime = NULL, end_datetime = NULL) {
  stac_item(
    id = id,
    geometry = list(
      type = "Polygon",
      coordinates = list(list(
        c(bbox[1], bbox[2]),
        c(bbox[3], bbox[2]),
        c(bbox[3], bbox[4]),
        c(bbox[1], bbox[4]),
        c(bbox[1], bbox[2])
      ))
    ),
    bbox = bbox,
    datetime = datetime,
    start_datetime = start_datetime,
    end_datetime = end_datetime
  )
}

# --- Error conditions ---

test_that("extent_from_items errors on empty list", {
  expect_error(extent_from_items(list()), "No items provided")
})

test_that("extent_from_items errors when no datetime information is present", {
  # datetime = "null" (the string) is treated as absent by extent_from_items,
  # and with no start_datetime/end_datetime no datetimes are collected.
  item <- make_item("a", c(-10, -10, 10, 10), datetime = "null")

  expect_error(
    extent_from_items(list(item)),
    "No datetime information found in items"
  )
})

# --- Single item ---

test_that("extent_from_items returns correct bbox for a single item", {
  item <- make_item("a", c(-10, -20, 10, 20), datetime = "2023-06-01T00:00:00Z")
  result <- extent_from_items(list(item))

  expect_equal(result@spatial@bbox[[1]], c(-10, -20, 10, 20))
})

test_that("extent_from_items returns single-point temporal extent for one item", {
  item <- make_item("a", c(-10, -20, 10, 20), datetime = "2023-06-01T00:00:00Z")
  result <- extent_from_items(list(item))

  interval <- result@temporal@interval[[1]]
  expect_equal(interval[[1]], "2023-06-01T00:00:00Z")
  expect_null(interval[[2]])
})

# --- Multiple items ---

test_that("extent_from_items unions bboxes across multiple items", {
  items <- list(
    make_item("a", c(-10, -20,   0,   0), datetime = "2023-01-01T00:00:00Z"),
    make_item("b", c(  0,   0,  10,  20), datetime = "2023-06-01T00:00:00Z"),
    make_item("c", c(-5,  -5,   5,   5), datetime = "2023-03-01T00:00:00Z")
  )

  result <- extent_from_items(items)
  bbox <- result@spatial@bbox[[1]]

  expect_equal(bbox[1], -10) # xmin
  expect_equal(bbox[2], -20) # ymin
  expect_equal(bbox[3],  10) # xmax
  expect_equal(bbox[4],  20) # ymax
})

test_that("extent_from_items sets temporal interval to min/max datetime", {
  items <- list(
    make_item("a", c(-10, -10, 10, 10), datetime = "2023-01-01T00:00:00Z"),
    make_item("b", c(-10, -10, 10, 10), datetime = "2023-12-31T00:00:00Z"),
    make_item("c", c(-10, -10, 10, 10), datetime = "2023-06-15T00:00:00Z")
  )

  result <- extent_from_items(items)
  interval <- result@temporal@interval[[1]]

  expect_equal(interval[[1]], "2023-01-01T00:00:00Z")
  expect_equal(interval[[2]], "2023-12-31T00:00:00Z")
})

# --- Items with start/end_datetime ---

test_that("extent_from_items handles items using start_datetime and end_datetime", {
  items <- list(
    make_item(
      "a",
      c(-10, -10, 10, 10),
      start_datetime = "2022-01-01T00:00:00Z",
      end_datetime   = "2022-06-30T00:00:00Z"
    ),
    make_item(
      "b",
      c(-10, -10, 10, 10),
      start_datetime = "2022-07-01T00:00:00Z",
      end_datetime   = "2022-12-31T00:00:00Z"
    )
  )

  result <- extent_from_items(items)
  interval <- result@temporal@interval[[1]]

  expect_equal(interval[[1]], "2022-01-01T00:00:00Z")
  expect_equal(interval[[2]], "2022-12-31T00:00:00Z")
})

test_that("extent_from_items handles a mix of datetime and start/end_datetime items", {
  items <- list(
    make_item("a", c(-10, -10, 10, 10), datetime = "2021-06-01T00:00:00Z"),
    make_item(
      "b",
      c(-10, -10, 10, 10),
      start_datetime = "2023-01-01T00:00:00Z",
      end_datetime   = "2023-12-31T00:00:00Z"
    )
  )

  result <- extent_from_items(items)
  interval <- result@temporal@interval[[1]]

  expect_equal(interval[[1]], "2021-06-01T00:00:00Z")
  expect_equal(interval[[2]], "2023-12-31T00:00:00Z")
})

# --- Return type ---

test_that("extent_from_items returns an Extent S7 object", {
  item <- make_item("a", c(-10, -10, 10, 10), datetime = "2023-01-01T00:00:00Z")
  result <- extent_from_items(list(item))

  expect_true(any(grepl("Extent",         class(result),           fixed = TRUE)))
  expect_true(any(grepl("SpatialExtent",  class(result@spatial),   fixed = TRUE)))
  expect_true(any(grepl("TemporalExtent", class(result@temporal),  fixed = TRUE)))
})
