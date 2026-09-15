test_that("raster statistics use S7 properties", {
  stats <- raster_statistics(
    minimum = 0,
    maximum = 100,
    mean = 42,
    stddev = 5,
    valid_percent = 99
  )

  expect_true(S7::S7_inherits(stats, raster_statistics))
  expect_identical(stats@minimum, 0)
  expect_identical(stats@valid_percent, 99)
  expect_error(stats@minimum <- "zero", "minimum")
  expect_identical(
    as.list(stats),
    list(minimum = 0, maximum = 100, mean = 42, stddev = 5, valid_percent = 99)
  )
})

test_that("raster histograms use validated S7 properties", {
  histogram <- raster_histogram(
    count = 3,
    min = 0,
    max = 3,
    buckets = c(4, 5, 6)
  )

  expect_true(S7::S7_inherits(histogram, raster_histogram))
  expect_identical(histogram@count, 3L)
  expect_identical(histogram@buckets, c(4L, 5L, 6L))
  expect_error(histogram@count <- c(1L, 2L), "single integer")
  expect_error(histogram@min <- c(0, 1), "single number")
  expect_error(histogram@max <- -1, "smaller than")
  expect_error(histogram@buckets <- 1L, "must equal")
  expect_identical(
    as.list(histogram),
    list(count = 3L, min = 0, max = 3, buckets = c(4L, 5L, 6L))
  )
})

test_that("raster bands normalize legacy metadata lists", {
  band <- raster_band(
    statistics = list(minimum = 1, maximum = 10),
    histogram = list(count = 2, min = 0, max = 2, buckets = c(3, 4))
  )

  expect_true(S7::S7_inherits(band@statistics, raster_statistics))
  expect_true(S7::S7_inherits(band@histogram, raster_histogram))
  expect_identical(band@statistics@minimum, 1)
  expect_identical(band@histogram@count, 2L)
  expect_error(band@statistics <- list(minimum = 0), "raster_statistics")

  serialized <- as.list(band)
  expect_identical(serialized$statistics, list(minimum = 1, maximum = 10))
  expect_identical(
    serialized$`raster:histogram`,
    list(count = 2L, min = 0, max = 2, buckets = c(3L, 4L))
  )
})
