test_that("catalog structure matches pystac output", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()
  skip_if_not(reticulate::py_module_available("pystac"), "pystac not available")

  # Import pystac
  pystac <- reticulate::import("pystac")

  # Common catalog parameters
  catalog_id <- "test-catalog"
  catalog_title <- "Test Catalog"
  catalog_description <- "A test catalog for validation"

  # Create R catalog
  r_catalog <- stac_catalog(
    id = catalog_id,
    description = catalog_description,
    title = catalog_title
  )

  # Create Python catalog
  py_catalog <- pystac$Catalog(
    id = catalog_id,
    description = catalog_description,
    title = catalog_title
  )

  # Convert to JSON-like structures for comparison
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_catalog, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_catalog$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(
      py_dict,
      auto_unbox = TRUE
    ))),
    simplifyVector = FALSE
  )

  # Compare required fields
  expect_equal(r_json$type, py_json$type)
  expect_equal(r_json$stac_version, py_json$stac_version)
  expect_equal(r_json$id, py_json$id)
  expect_equal(r_json$description, py_json$description)
  expect_equal(r_json$title, py_json$title)

  # Check that both have links field (even if empty)
  expect_true("links" %in% names(r_json))
  expect_true("links" %in% names(py_json))

  # Validate both catalogs
  r_validation <- validate_stac(r_catalog)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})

test_that("collection structure matches pystac output", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()
  skip_if_not(reticulate::py_module_available("pystac"), "pystac not available")

  pystac <- reticulate::import("pystac")

  # Common collection parameters
  collection_id <- "test-collection"
  collection_description <- "A test collection"
  collection_license <- "CC-BY-4.0"

  spatial_extent <- pystac$SpatialExtent(
    bboxes = list(list(-180, -90, 180, 90))
  )
  temporal_extent <- pystac$TemporalExtent(intervals = list(list(NULL, NULL)))

  # Create R collection
  r_collection <- stac_collection(
    id = collection_id,
    description = collection_description,
    license = collection_license,
    extent = list(
      spatial = list(bbox = list(c(-180, -90, 180, 90))),
      temporal = list(interval = list(c(NA, NA)))
    )
  )

  # Create Python collection
  py_collection <- pystac$Collection(
    id = collection_id,
    description = collection_description,
    license = collection_license,
    extent = pystac$Extent(spatial = spatial_extent, temporal = temporal_extent)
  )

  # Convert to JSON-like structures
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_collection, auto_unbox = TRUE, null = "null"),
    simplifyVector = FALSE
  )

  py_dict <- py_collection$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(
      py_dict,
      auto_unbox = TRUE
    ))),
    simplifyVector = FALSE
  )

  # Compare required fields
  expect_equal(r_json$type, py_json$type)
  expect_equal(r_json$stac_version, py_json$stac_version)
  expect_equal(r_json$id, py_json$id)
  expect_equal(r_json$description, py_json$description)
  expect_equal(r_json$license, py_json$license)

  # Check extent structure exists
  expect_true("extent" %in% names(r_json))
  expect_true("extent" %in% names(py_json))
  expect_true("spatial" %in% names(r_json$extent))
  expect_true("temporal" %in% names(r_json$extent))

  # Validate both collections
  r_validation <- validate_stac(r_collection)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})

test_that("item structure matches pystac output", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()
  skip_if_not(reticulate::py_module_available("pystac"), "pystac not available")

  pystac <- reticulate::import("pystac")

  # Common item parameters
  item_id <- "test-item"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(
    type = "Polygon",
    coordinates = list(list(
      c(-105, 40),
      c(-104, 40),
      c(-104, 41),
      c(-105, 41),
      c(-105, 40)
    ))
  )
  datetime_str <- "2023-06-15T17:30:00Z"

  # Create R item
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime_str,
    properties = list()
  )

  # Create Python item
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = reticulate::py_eval(sprintf(
      "__import__('datetime').datetime.fromisoformat('%s'.replace('Z', '+00:00'))",
      gsub("Z$", "", datetime_str)
    )),
    properties = reticulate::dict()
  )

  # Convert to JSON-like structures
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_item$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(
      py_dict,
      auto_unbox = TRUE
    ))),
    simplifyVector = FALSE
  )

  # Compare required fields
  expect_equal(r_json$type, py_json$type)
  expect_equal(r_json$stac_version, py_json$stac_version)
  expect_equal(r_json$id, py_json$id)
  expect_equal(r_json$bbox, py_json$bbox)

  # Check required fields exist
  expect_true("geometry" %in% names(r_json))
  expect_true("properties" %in% names(r_json))
  expect_true("links" %in% names(r_json))
  expect_true("assets" %in% names(r_json))

  # Validate both items
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})
