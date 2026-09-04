test_that("an extent prints its overall bbox and interval", {
  local_reproducible_output(unicode = FALSE)
  ext <- stac_extent(
    list(c(-180, -90, 180, 90)),
    list(list("2013-01-01T00:00:00Z", NULL))
  )
  out <- capture.output(print(ext))

  expect_identical(out[[1]], "<STAC Extent>")
  expect_true(any(grepl("bbox         : [-180, -90, 180, 90]", out, fixed = TRUE)))
  expect_true(any(grepl("2013-01-01T00:00:00Z / ..", out, fixed = TRUE)))
  # no S7 internals
  expect_false(any(grepl("@ spatial", out, fixed = TRUE)))
})

test_that("extra bboxes and intervals are counted", {
  local_reproducible_output(unicode = FALSE)
  ext <- stac_extent(
    list(c(-180, -90, 180, 90), c(-10, -10, 10, 10)),
    list(
      list("2013-01-01T00:00:00Z", NULL),
      list("2020-01-01T00:00:00Z", "2021-01-01T00:00:00Z")
    )
  )
  out <- capture.output(print(ext))

  expect_true(any(grepl("sub-regions  : 1", out, fixed = TRUE)))
  expect_true(any(grepl("sub-periods  : 1", out, fixed = TRUE)))
})

test_that("spatial and temporal extents list their entries", {
  local_reproducible_output(unicode = FALSE)
  ext <- stac_extent(
    list(c(-180, -90, 180, 90), c(-10, -10, 10, 10)),
    list(
      list("2013-01-01T00:00:00Z", NULL),
      list("2020-01-01T00:00:00Z", "2021-01-01T00:00:00Z")
    )
  )

  out <- capture.output(print(ext@spatial, expand = TRUE))
  expect_identical(out[[1]], "<Spatial Extent>")
  expect_true(any(grepl("[-10, -10, 10, 10]", out, fixed = TRUE)))

  out <- capture.output(print(ext@temporal, expand = TRUE))
  expect_identical(out[[1]], "<Temporal Extent>")
  expect_true(any(grepl("2020-01-01T00:00:00Z / 2021-01-01T00:00:00Z", out, fixed = TRUE)))

  # collapsed shows the first entry as a preview only
  out <- capture.output(print(ext@spatial))
  expect_true(any(grepl("> bbox       : 2", out, fixed = TRUE)))
  expect_false(any(grepl("[-10, -10, 10, 10]", out, fixed = TRUE)))
})

test_that("a 3D bbox reports its elevation pair separately", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(stacbuildr:::Bbox(coordinates = c(-1, -1, 0, 1, 1, 100))))
  expect_identical(out[[1]], "<Bbox>")
  expect_true(any(grepl("3D", out, fixed = TRUE)))
  expect_true(any(grepl("[-1, -1, 1, 1] elev [0, 100]", out, fixed = TRUE)))

  out <- capture.output(print(stacbuildr:::Bbox(coordinates = c(-1, -1, 1, 1))))
  expect_true(any(grepl("2D", out, fixed = TRUE)))
})

test_that("geometry coordinates are summarised by position count", {
  local_reproducible_output(unicode = FALSE)

  poly <- stacbuildr:::Geometry(
    type = "Polygon",
    coordinates = list(list(c(0, 0), c(1, 0), c(1, 1), c(0, 0)))
  )
  out <- capture.output(print(poly))
  expect_identical(out[[1]], "<Geometry>")
  expect_true(any(grepl("Polygon", out, fixed = TRUE)))
  expect_true(any(grepl("4 positions", out, fixed = TRUE)))

  pt <- stacbuildr:::Geometry(type = "Point", coordinates = c(-105, 40))
  out <- capture.output(print(pt))
  expect_true(any(grepl("[-105, 40]", out, fixed = TRUE)))
})
