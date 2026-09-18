test_that("providers use validated S3 fields", {
  provider <- stac_provider(
    name = "USGS",
    description = "United States Geological Survey",
    roles = c("producer", "host"),
    url = "https://www.usgs.gov"
  )

  expect_s3_class(provider, "stac_provider")
  expect_identical(provider$name, "USGS")
  expect_identical(provider$roles, c("producer", "host"))
  expect_error(stac_provider(""), "non-empty string")
  expect_error(stac_provider("USGS", roles = "invalid"), "invalid roles")
})

test_that("collections normalize providers and serialize them as arrays", {
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

  expect_s3_class(collection$providers[[1]], "stac_provider")
  expect_identical(collection$providers[[1]]$roles, "producer")
  expect_identical(
    as.list(collection)$providers,
    list(list(name = "USGS", roles = list("producer")))
  )
})
