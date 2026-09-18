test_that("raster statistics validate at construction", {
  stats <- raster_statistics(
    minimum = 0,
    maximum = 100,
    mean = 42,
    stddev = 5,
    valid_percent = 99
  )

  expect_s3_class(stats, "raster_statistics")
  expect_identical(
    as.list(stats),
    list(minimum = 0, maximum = 100, mean = 42, stddev = 5, valid_percent = 99)
  )
  expect_error(raster_statistics(minimum = "zero"), "minimum")
  expect_warning(raster_statistics(valid_percent = 101), "between 0 and 100")
})

test_that("raster histograms coerce and validate at construction", {
  histogram <- raster_histogram(3, 0, 3, c(4, 5, 6))

  expect_identical(histogram$count, 3L)
  expect_identical(histogram$buckets, c(4L, 5L, 6L))
  expect_error(raster_histogram(c(1L, 2L), 0, 3, 1:3), "single integer")
  expect_error(raster_histogram(3, 0, 3, c(1, 2.5, 3)), "only integers")
  expect_error(raster_histogram(3, 0, -1, 1:3), "smaller than")
})

test_that("raster bands normalize legacy metadata lists", {
  band <- raster_band(
    statistics = list(minimum = 1, maximum = 10),
    histogram = list(count = 2, min = 0, max = 2, buckets = c(3, 4))
  )

  expect_s3_class(band$statistics, "raster_statistics")
  expect_s3_class(band$histogram, "raster_histogram")
  expect_identical(band$statistics$minimum, 1)
  expect_identical(band$histogram$count, 2L)

  serialized <- as.list(band)
  expect_identical(serialized$statistics, list(minimum = 1, maximum = 10))
  expect_identical(
    serialized$`raster:histogram`,
    list(count = 2L, min = 0, max = 2, buckets = c(3L, 4L))
  )
})
