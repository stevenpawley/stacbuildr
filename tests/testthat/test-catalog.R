test_that("catalog structure matches pystac output", {
  # Import pystac
  skip_if_no_pystac()
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
    jsonlite::toJSON(as.list(r_catalog), auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_catalog$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::import("json")$dumps(py_dict)),
    simplifyVector = FALSE
  )
  py_json <- py_json[names(r_json)]

  # Compare the complete serialized catalog, not only selected fields.
  expect_equal(r_json, py_json)

  # Validate both catalogs
  r_validation <- validate_stac(r_catalog)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})

test_that("collection structure matches pystac output", {
  # Import pystac
  skip_if_no_pystac()
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
      temporal = list(interval = list(list(NULL, NULL)))
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
    jsonlite::toJSON(as.list(r_collection), auto_unbox = TRUE, null = "null"),
    simplifyVector = FALSE
  )

  py_dict <- py_collection$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::import("json")$dumps(py_dict)),
    simplifyVector = FALSE
  )
  py_json <- py_json[names(r_json)]

  # Compare the complete serialized collection, not only selected fields.
  expect_equal(r_json, py_json)

  # Validate both collections
  r_validation <- validate_stac(r_collection)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})

test_that("item structure matches pystac output", {
  # Import pystac
  skip_if_no_pystac()
  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

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

  # Create R item
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  # Create Python item
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  # Convert to JSON-like structures
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(r_item), auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_item$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::import("json")$dumps(py_dict)),
    simplifyVector = FALSE
  )
  if (identical(py_json$stac_extensions, list())) {
    py_json$stac_extensions <- NULL
  }
  py_json <- py_json[names(r_json)]

  # Compare the complete serialized item, not only selected fields.
  expect_equal(r_json, py_json)

  # Validate both items
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)
})

test_that("catalog with child catalogs matches pystac", {
  # Import pystac
  skip_if_no_pystac()
  pystac <- reticulate::import("pystac")

  # Create R parent and child catalogs
  r_parent <- stac_catalog(
    id = "parent-catalog",
    description = "Parent catalog",
    title = "Parent"
  )

  r_child <- stac_catalog(
    id = "child-catalog",
    description = "Child catalog",
    title = "Child"
  )

  # Create Python parent and child catalogs
  py_parent <- pystac$Catalog(
    id = "parent-catalog",
    description = "Parent catalog",
    title = "Parent"
  )

  py_child <- pystac$Catalog(
    id = "child-catalog",
    description = "Child catalog",
    title = "Child"
  )

  # Validate both
  expect_true(validate_stac(r_parent)$valid)
  expect_true(validate_stac(r_child)$valid)

  # Check structure
  expect_equal(r_parent$type, "Catalog")
  expect_equal(r_child$type, "Catalog")
})

test_that("add_child rejects duplicate child ids", {
  catalog <- stac_catalog(id = "root", description = "d")
  child <- function(id) stac_catalog(id = id, description = "d")

  expect_error(
    add_child(add_child(catalog, child("x")), child("x")),
    "duplicate id"
  )

  expect_no_error(add_child(add_child(catalog, child("x")), child("y")))
})
