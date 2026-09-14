test_that("providers use validated S7 properties", {
  provider <- stac_provider(
    name = "USGS",
    description = "United States Geological Survey",
    roles = c("producer", "host"),
    url = "https://www.usgs.gov"
  )

  expect_true(S7::S7_inherits(provider, stac_provider))
  expect_identical(provider@name, "USGS")
  expect_identical(provider@roles, c("producer", "host"))
  expect_error(provider@name <- "", "non-empty string")
  expect_error(provider@roles <- "invalid", "invalid roles")
})

test_that("collections normalize providers and serialize them as JSON arrays", {
  collection <- stac_collection(
    id = "collection",
    description = "A collection",
    license = "other",
    extent = stac_extent(
      spatial_bbox = list(c(-1, -1, 1, 1)),
      temporal_interval = list(list(NULL, NULL))
    ),
    providers = list(list(name = "USGS", roles = list("producer")))
  )

  expect_true(S7::S7_inherits(collection@providers[[1]], stac_provider))
  expect_identical(collection@providers[[1]]@roles, "producer")
  expect_error(
    collection@providers <- list(list(name = "invalid")),
    "stac_provider objects"
  )
  expect_identical(
    as.list(collection)$providers,
    list(list(name = "USGS", roles = list("producer")))
  )
})
