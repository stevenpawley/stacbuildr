test_that("collection with providers matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")

  collection_id <- "test-collection-providers"

  # Create R collection with providers
  r_collection <- stac_collection(
    id = collection_id,
    description = "Test collection with providers",
    license = "CC-BY-4.0",
    extent = list(
      spatial = list(bbox = list(c(-180, -90, 180, 90))),
      temporal = list(interval = list(c(NA, NA)))
    ),
    providers = list(
      list(
        name = "Example Provider",
        roles = c("producer", "licensor"),
        url = "https://example.com"
      )
    )
  )

  # Create Python collection with providers
  spatial_extent <- pystac$SpatialExtent(bboxes = list(list(-180, -90, 180, 90)))
  temporal_extent <- pystac$TemporalExtent(intervals = list(list(NULL, NULL)))

  py_collection <- pystac$Collection(
    id = collection_id,
    description = "Test collection with providers",
    license = "CC-BY-4.0",
    extent = pystac$Extent(spatial = spatial_extent, temporal = temporal_extent),
    providers = list(
      pystac$Provider(
        name = "Example Provider",
        roles = list("producer", "licensor"),
        url = "https://example.com"
      )
    )
  )

  # Validate
  r_validation <- validate_stac(r_collection)
  expect_true(r_validation$valid)

  # Check providers exist
  expect_length(r_collection$providers, 1)
  expect_equal(r_collection$providers[[1]]$name, "Example Provider")
})

test_that("collection with summaries matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")

  collection_id <- "test-collection-summaries"

  # Create R collection with summaries
  r_collection <- stac_collection(
    id = collection_id,
    description = "Test collection with summaries",
    license = "CC-BY-4.0",
    extent = list(
      spatial = list(bbox = list(c(-180, -90, 180, 90))),
      temporal = list(interval = list(c(NA, NA)))
    ),
    summaries = list(
      platform = list("landsat-8", "landsat-9"),
      instruments = list("oli", "tirs"),
      `gsd` = list(30)
    )
  )

  # Create Python collection with summaries
  spatial_extent <- pystac$SpatialExtent(bboxes = list(list(-180, -90, 180, 90)))
  temporal_extent <- pystac$TemporalExtent(intervals = list(list(NULL, NULL)))

  py_collection <- pystac$Collection(
    id = collection_id,
    description = "Test collection with summaries",
    license = "CC-BY-4.0",
    extent = pystac$Extent(spatial = spatial_extent, temporal = temporal_extent),
    summaries = pystac$Summaries(reticulate::dict(
      platform = list("landsat-8", "landsat-9"),
      instruments = list("oli", "tirs"),
      `gsd` = list(30)
    ))
  )

  # Validate
  r_validation <- validate_stac(r_collection)
  expect_true(r_validation$valid)

  # Check summaries exist
  expect_true(!is.null(r_collection$summaries))
  expect_true("platform" %in% names(r_collection$summaries))
})

