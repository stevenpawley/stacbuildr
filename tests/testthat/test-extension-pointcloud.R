pc_test_item <- function() {
  item <- stac_item(
    id = "pc",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )
  add_asset(item, "data", href = "./points.laz", type = "application/vnd.laszip")
}

test_that("the extension writes its fields and schema URI", {
  item <- add_pointcloud_extension(
    pc_test_item(),
    count = 1000,
    type = "lidar",
    density = 4.5
  )

  expect_true(
    "https://stac-extensions.github.io/pointcloud/v2.0.0/schema.json" %in%
      item@stac_extensions
  )
  expect_equal(item@properties$`pc:count`, 1000L)
  expect_equal(item@properties$`pc:type`, "lidar")
  expect_equal(item@properties$`pc:density`, 4.5)
})

test_that("count and type are required", {
  expect_error(add_pointcloud_extension(pc_test_item(), type = "lidar"), "'count' is required")
  expect_error(add_pointcloud_extension(pc_test_item(), count = 10), "'type' is required")
})

test_that("count must be a whole, non-negative number", {
  expect_error(add_pointcloud_extension(pc_test_item(), count = 1.5, type = "lidar"), "whole number")
  expect_error(add_pointcloud_extension(pc_test_item(), count = -1, type = "lidar"), "greater than or equal to 0")
  expect_error(add_pointcloud_extension(pc_test_item(), count = "many", type = "lidar"), "single number")
})

test_that("counts beyond integer range survive as doubles", {
  # LAS 1.4 allows more points than an R integer can hold, and the schema types
  # pc:count as an integer, so the value must not gain a decimal point
  big <- 5e9
  item <- add_pointcloud_extension(pc_test_item(), count = big, type = "lidar")

  expect_equal(item@properties$`pc:count`, big)
  json <- jsonlite::toJSON(item@properties$`pc:count`, auto_unbox = TRUE)
  expect_equal(as.character(json), "5000000000")
})

test_that("an unsuggested pc:type warns but is kept", {
  expect_warning(
    item <- add_pointcloud_extension(pc_test_item(), count = 1, type = "photogrammetry"),
    "not one of the suggested values"
  )
  expect_equal(item@properties$`pc:type`, "photogrammetry")

  expect_silent(add_pointcloud_extension(pc_test_item(), count = 1, type = "sonar"))
  expect_error(add_pointcloud_extension(pc_test_item(), count = 1, type = ""), "empty string")
})

test_that("fields can go on an asset instead of properties", {
  item <- add_pointcloud_extension(
    pc_test_item(),
    count = 10, type = "lidar", asset_key = "data"
  )

  expect_equal(item@assets$data$`pc:count`, 10L)
  expect_null(item@properties$`pc:count`)
  expect_error(
    add_pointcloud_extension(pc_test_item(), count = 1, type = "lidar", asset_key = "nope"),
    "does not exist"
  )
})

test_that("pc_schema validates name, size and type", {
  s <- pc_schema("X", size = 8, type = "floating")
  expect_s3_class(s, "pc_schema")
  expect_equal(s$size, 8L)

  expect_error(pc_schema("X", size = 8, type = "double"), "Invalid dimension type")
  expect_error(pc_schema("X", size = 0, type = "floating"), "greater than 0")
  expect_error(pc_schema("X", size = 1.5, type = "floating"), "whole number")
  expect_error(pc_schema("", size = 1, type = "signed"), "empty string")
})

test_that("pc_statistic needs at least one statistic beside the name", {
  expect_error(pc_statistic("Z"), "at least one statistic")

  s <- pc_statistic("Z", position = 2, minimum = 1, maximum = 9)
  expect_s3_class(s, "pc_statistic")
  expect_equal(s$position, 2L)
  # fields follow the specification's order, not the argument order
  expect_equal(names(s), c("name", "position", "maximum", "minimum"))

  expect_error(pc_statistic("Z", position = -1, minimum = 1), "greater than or equal to 0")
})

test_that("schemas and statistics must be lists of the right objects", {
  expect_error(
    add_pointcloud_extension(pc_test_item(), count = 1, type = "lidar", schemas = list(list(size = 1))),
    "not a valid Schema object"
  )
  expect_error(
    add_pointcloud_extension(pc_test_item(), count = 1, type = "lidar", statistics = list(list(minimum = 1))),
    "not a valid Stats object"
  )
})

test_that("schemas and statistics stay JSON arrays and drop their classes", {
  item <- add_pointcloud_extension(
    pc_test_item(),
    count = 100,
    type = "lidar",
    schemas = list(pc_schema("X", size = 8, type = "floating")),
    statistics = list(pc_statistic("X", position = 0, minimum = 0, maximum = 1))
  )

  path <- withr::local_tempfile(fileext = ".json")
  write_item(item, path)
  json <- jsonlite::fromJSON(path, simplifyVector = FALSE)

  # a single-element list must not unbox to an object
  expect_true(is.list(json$properties$`pc:schemas`))
  expect_length(json$properties$`pc:schemas`, 1)
  expect_named(json$properties$`pc:schemas`[[1]], c("name", "size", "type"))
  expect_named(
    json$properties$`pc:statistics`[[1]],
    c("name", "position", "maximum", "minimum")
  )
})

test_that("the sub-objects print in the shared style", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(pc_schema("X", size = 8, type = "floating")))
  expect_identical(out[[1]], "<Point Cloud Schema>")
  expect_true(any(grepl("8 bytes", out, fixed = TRUE)))

  out <- capture.output(print(pc_statistic("Z", minimum = 1)))
  expect_identical(out[[1]], "<Point Cloud Statistics>")
})
