skip_if_no_lidr <- function() {
  skip_if_not_installed("lidR")
}

lidr_test_file <- function() {
  f <- system.file("extdata", "Megaplot.laz", package = "lidR")
  skip_if(f == "", "lidR example data not available")
  f
}

test_that("an item is built from a LAS header alone", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  # Megaplot.laz records no creation date, so the current time is used
  expect_warning(item <- item_from_lidr(f), "records no creation date")

  expect_equal(item@id, "Megaplot")
  expect_equal(item@properties$`pc:count`, 81590L)
  expect_equal(item@properties$`pc:type`, "lidar")
  expect_true(item@properties$`pc:density` > 0)

  # the extent is transformed out of EPSG:26917 into WGS84
  expect_true(all(item@bbox[c(1, 3)] > -180 & item@bbox[c(1, 3)] < 0))
  expect_true(all(item@bbox[c(2, 4)] > 0 & item@bbox[c(2, 4)] < 90))
})

test_that("the point cloud asset gets the LAZ media type", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  suppressWarnings(item <- item_from_lidr(f))
  expect_equal(item@assets$data$type, "application/vnd.laszip")
  expect_equal(item@assets$data$roles, list("data"))
})

test_that("COPC files are recognised by name", {
  expect_equal(get_media_type("tiles/a.copc.laz"), "application/vnd.laszip+copc")
  expect_equal(get_media_type("https://x.test/a.copc.laz"), "application/vnd.laszip+copc")
  expect_equal(get_media_type("a.laz"), "application/vnd.laszip")
  expect_equal(get_media_type("a.las"), "application/vnd.las")

  # the ".copc" must not linger in an id derived from the basename
  skip_if_no_lidr()
  f <- lidr_test_file()
  suppressWarnings(
    item <- item_from_lidr(f, href = "https://x.test/tile.copc.laz")
  )
  expect_equal(item@id, "tile")
})

test_that("projection metadata records the file's own CRS", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  suppressWarnings(item <- item_from_lidr(f))

  expect_true(
    "https://stac-extensions.github.io/projection/v2.0.0/schema.json" %in%
      item@stac_extensions
  )
  expect_equal(item@properties$`proj:code`, "EPSG:26917")
  # proj:bbox is 3D for a point cloud, and in the native CRS
  expect_length(item@properties$`proj:bbox`, 6)
  expect_true(item@properties$`proj:bbox`[[1]] > 600000)
})

test_that("schemas come from the point data record format", {
  skip_if_no_lidr()
  header <- lidR::readLASheader(lidr_test_file())

  schemas <- schemas_from_lidr(header)
  names <- vapply(schemas, function(s) s$name, character(1))

  # Megaplot.laz is point format 1: the base dimensions plus GPS time
  expect_equal(names[1:3], c("X", "Y", "Z"))
  expect_true("GpsTime" %in% names)
  expect_false("Red" %in% names)

  expect_equal(schemas[[1]]$size, 8L)
  expect_equal(schemas[[1]]$type, "floating")

  intensity <- schemas[[which(names == "Intensity")]]
  expect_equal(intensity$size, 2L)
  expect_equal(intensity$type, "unsigned")

  # bit-packed fields are reported as whole unpacked bytes
  rn <- schemas[[which(names == "ReturnNumber")]]
  expect_equal(rn$size, 1L)
})

test_that("every LAS point format maps to known dimensions", {
  for (format_id in as.character(0:10)) {
    dims <- las_point_formats[[format_id]]
    expect_true(length(dims) > 0, label = format_id)
    expect_true(
      all(dims %in% names(las_dimension_sizes)),
      label = paste("format", format_id)
    )
    expect_false(any(duplicated(dims)), label = paste("format", format_id))
  }
})

test_that("header-only statistics carry the X/Y/Z bounds", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  suppressWarnings(item <- item_from_lidr(f))
  stats <- item@properties$`pc:statistics`

  expect_length(stats, 3)
  expect_equal(vapply(stats, function(s) s$name, character(1)), c("X", "Y", "Z"))
  # position indexes into pc:schemas and is zero-based
  expect_equal(vapply(stats, function(s) s$position, integer(1)), 0:2)
  expect_equal(stats[[3]]$minimum, 0)
  expect_true(stats[[3]]$maximum > 0)
})

test_that("calculate_statistics adds the channels that need the points", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  suppressWarnings(item <- item_from_lidr(f, calculate_statistics = TRUE))
  stats <- item@properties$`pc:statistics`
  names <- vapply(stats, function(s) s$name, character(1))

  expect_true(length(stats) > 3)
  expect_true("Intensity" %in% names)
  # lidR's column names are mapped onto the specification's
  expect_true("GpsTime" %in% names)
  expect_false("gpstime" %in% names)

  z <- stats[[which(names == "Z")]]
  expect_true(!is.null(z$average) && !is.null(z$stddev) && !is.null(z$variance))
  expect_equal(z$count, 81590L)
  expect_equal(z$stddev^2, z$variance)
})

test_that("statistics cannot be calculated from a header alone", {
  skip_if_no_lidr()
  header <- lidR::readLASheader(lidr_test_file())

  expect_error(
    item_from_lidr(header, href = "a.laz", calculate_statistics = TRUE),
    "needs the points"
  )
})

test_that("a header creation date becomes the item datetime", {
  skip_if_no_lidr()
  header <- lidR::readLASheader(lidr_test_file())

  # 2023 day 166 is 2023-06-15
  header@PHB[["File Creation Year"]] <- 2023L
  header@PHB[["File Creation Day of Year"]] <- 166L

  item <- item_from_lidr(header, href = "megaplot.laz")
  expect_equal(item@properties$datetime, "2023-06-15T00:00:00Z")

  # an explicit datetime still wins
  item <- item_from_lidr(header, href = "megaplot.laz", datetime = "2020-01-01T00:00:00Z")
  expect_equal(item@properties$datetime, "2020-01-01T00:00:00Z")
})

test_that("a file with no CRS is reported rather than silently mislocated", {
  skip_if_no_lidr()
  header <- lidR::readLASheader(lidr_test_file())
  header@VLR <- list()

  expect_error(
    suppressWarnings(item_from_lidr(header, href = "megaplot.laz")),
    "declares no CRS"
  )

  # Opting out of the transform is only for coordinates that are already
  # longitude/latitude; projected metres still fail the item's bbox check.
  expect_error(
    suppressWarnings(
      item_from_lidr(header, href = "megaplot.laz", reproject_to_wgs84 = FALSE)
    ),
    "longitudes must be in"
  )

  header@PHB[c("Min X", "Max X", "Min Y", "Max Y")] <- list(-105.5, -104.5, 39.5, 40.5)
  suppressWarnings(
    item <- item_from_lidr(header, href = "megaplot.laz", reproject_to_wgs84 = FALSE)
  )
  expect_equal(unname(item@bbox), c(-105.5, 39.5, -104.5, 40.5))
})

test_that("extension fields can be turned off", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  suppressWarnings(
    item <- item_from_lidr(f, add_pointcloud = FALSE, add_projection = FALSE)
  )
  expect_null(item@properties$`pc:count`)
  expect_null(item@properties$`proj:code`)

  suppressWarnings(item <- item_from_lidr(f, add_schemas = FALSE))
  expect_null(item@properties$`pc:schemas`)
  # statistics still get positions, just none to index into
  expect_length(item@properties$`pc:statistics`, 3)
})

test_that("a catalogue yields one item per file", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  ctg <- lidR::readLAScatalog(f)
  suppressWarnings(items <- items_from_lascatalog(ctg))

  expect_length(items, 1)
  expect_equal(items[[1]]@id, "Megaplot")

  # a directory and a file vector are accepted too
  suppressWarnings(items <- items_from_lascatalog(dirname(f)))
  expect_true(length(items) >= 1)

  expect_error(items_from_lascatalog(42), "must be a LAScatalog")
})

test_that("an unreadable tile is skipped rather than fatal", {
  skip_if_no_lidr()
  f <- lidr_test_file()

  bad <- withr::local_tempfile(fileext = ".laz")
  writeLines("not a las file", bad)

  suppressWarnings(items <- items_from_lascatalog(c(f, bad)))
  expect_length(items, 1)
})

test_that("extra byte data type codes map to whole-byte dimensions", {
  for (code in names(las_extra_byte_types)) {
    spec <- las_extra_byte_types[[code]]
    expect_no_error(
      pc_schema("extra", size = as.integer(spec[[1]]), type = spec[[2]])
    )
  }
})
