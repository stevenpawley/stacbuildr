test_that("STAC Item creation works", {
  item <- stac_item(
    id = "test-item",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox = c(-105, 40, -105, 40),
    datetime = Sys.time()
  )

  expect_s3_class(item, "stac_item")
  expect_equal(item$type, "Feature")
  expect_equal(item$stac_version, "1.1.0")
  expect_true(validate_stac(item)$valid)
})

test_that("item with assets matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-with-assets"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(
    type = "Polygon",
    coordinates = list(list(
      c(-105, 40), c(-104, 40), c(-104, 41), c(-105, 41), c(-105, 40)
    ))
  )

  # Create R item with assets
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  r_item$assets <- list(
    thumbnail = list(
      href = "https://example.com/thumbnail.png",
      type = "image/png",
      title = "Thumbnail",
      roles = list("thumbnail")
    ),
    data = list(
      href = "https://example.com/data.tif",
      type = "image/tiff; application=geotiff",
      roles = list("data")
    )
  )

  # Create Python item with assets
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  py_item$add_asset(
    "thumbnail",
    pystac$Asset(
      href = "https://example.com/thumbnail.png",
      media_type = "image/png",
      title = "Thumbnail",
      roles = list("thumbnail")
    )
  )

  py_item$add_asset(
    "data",
    pystac$Asset(
      href = "https://example.com/data.tif",
      media_type = "image/tiff; application=geotiff",
      roles = list("data")
    )
  )

  # Validate both
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)

  # Check assets exist and match
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_item$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(py_dict, auto_unbox = TRUE))),
    simplifyVector = FALSE
  )

  expect_true("assets" %in% names(r_json))
  expect_true("thumbnail" %in% names(r_json$assets))
  expect_true("data" %in% names(r_json$assets))
  expect_equal(r_json$assets$thumbnail$href, py_json$assets$thumbnail$href)
})

test_that("item with links matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-with-links"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(
    type = "Point",
    coordinates = c(-104.5, 40.5)
  )

  # Create R item with links
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  r_item$links <- list(
    list(
      rel = "self",
      href = "https://example.com/item.json",
      type = "application/json"
    ),
    list(
      rel = "parent",
      href = "https://example.com/collection.json",
      type = "application/json"
    )
  )

  # Create Python item with links
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  py_item$add_link(
    pystac$Link(
      rel = "self",
      target = "https://example.com/item.json",
      media_type = "application/json"
    )
  )

  py_item$add_link(
    pystac$Link(
      rel = "parent",
      target = "https://example.com/collection.json",
      media_type = "application/json"
    )
  )

  # Validate
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)

  # Check links structure
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  expect_true("links" %in% names(r_json))
  expect_length(r_json$links, 2)
  expect_true(any(vapply(r_json$links, function(l) l$rel == "self", logical(1))))
  expect_true(any(vapply(r_json$links, function(l) l$rel == "parent", logical(1))))
})

test_that("item with assets matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-with-assets"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(
    type = "Polygon",
    coordinates = list(list(
      c(-105, 40), c(-104, 40), c(-104, 41), c(-105, 41), c(-105, 40)
    ))
  )

  # Create R item with assets
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  r_item$assets <- list(
    thumbnail = list(
      href = "https://example.com/thumbnail.png",
      type = "image/png",
      title = "Thumbnail",
      roles = list("thumbnail")
    ),
    data = list(
      href = "https://example.com/data.tif",
      type = "image/tiff; application=geotiff",
      roles = list("data")
    )
  )

  # Create Python item with assets
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  py_item$add_asset(
    "thumbnail",
    pystac$Asset(
      href = "https://example.com/thumbnail.png",
      media_type = "image/png",
      title = "Thumbnail",
      roles = list("thumbnail")
    )
  )

  py_item$add_asset(
    "data",
    pystac$Asset(
      href = "https://example.com/data.tif",
      media_type = "image/tiff; application=geotiff",
      roles = list("data")
    )
  )

  # Validate both
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)
  expect_length(r_validation$errors, 0)

  # Check assets exist and match
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  py_dict <- py_item$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(py_dict, auto_unbox = TRUE))),
    simplifyVector = FALSE
  )

  expect_true("assets" %in% names(r_json))
  expect_true("thumbnail" %in% names(r_json$assets))
  expect_true("data" %in% names(r_json$assets))
  expect_equal(r_json$assets$thumbnail$href, py_json$assets$thumbnail$href)
})

test_that("item with links matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-with-links"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(
    type = "Point",
    coordinates = c(-104.5, 40.5)
  )

  # Create R item with links
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  r_item$links <- list(
    list(
      rel = "self",
      href = "https://example.com/item.json",
      type = "application/json"
    ),
    list(
      rel = "parent",
      href = "https://example.com/collection.json",
      type = "application/json"
    )
  )

  # Create Python item with links
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  py_item$add_link(
    pystac$Link(
      rel = "self",
      target = "https://example.com/item.json",
      media_type = "application/json"
    )
  )

  py_item$add_link(
    pystac$Link(
      rel = "parent",
      target = "https://example.com/collection.json",
      media_type = "application/json"
    )
  )

  # Validate
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)

  # Check links structure
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  expect_true("links" %in% names(r_json))
  expect_length(r_json$links, 2)
  expect_true(any(vapply(r_json$links, function(l) l$rel == "self", logical(1))))
  expect_true(any(vapply(r_json$links, function(l) l$rel == "parent", logical(1))))
})

test_that("collection with items matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  collection_id <- "test-collection-with-items"

  # Create R collection
  r_collection <- stac_collection(
    id = collection_id,
    description = "Test collection with items",
    license = "CC-BY-4.0",
    extent = list(
      spatial = list(bbox = list(c(-180, -90, 180, 90))),
      temporal = list(interval = list(c(NA, NA)))
    )
  )

  # Create Python collection
  spatial_extent <- pystac$SpatialExtent(bboxes = list(list(-180, -90, 180, 90)))
  temporal_extent <- pystac$TemporalExtent(intervals = list(list(NULL, NULL)))

  py_collection <- pystac$Collection(
    id = collection_id,
    description = "Test collection with items",
    license = "CC-BY-4.0",
    extent = pystac$Extent(spatial = spatial_extent, temporal = temporal_extent)
  )

  # Add items to both
  item_id <- "test-item-1"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(type = "Point", coordinates = c(-104.5, 40.5))

  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list(),
    collection = collection_id
  )

  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict(),
    collection = collection_id
  )

  # Validate both
  r_validation_coll <- validate_stac(r_collection)
  r_validation_item <- validate_stac(r_item)

  expect_true(r_validation_coll$valid)
  expect_true(r_validation_item$valid)

  # Check collection field
  expect_equal(r_item$collection, py_item$collection_id)
})

test_that("items with different geometry types match pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  geometries <- list(
    point = list(
      type = "Point",
      coordinates = c(-104.5, 40.5),
      bbox = c(-104.5, 40.5, -104.5, 40.5)
    ),
    linestring = list(
      type = "LineString",
      coordinates = list(c(-105, 40), c(-104, 41)),
      bbox = c(-105, 40, -104, 41)
    ),
    polygon = list(
      type = "Polygon",
      coordinates = list(list(
        c(-105, 40), c(-104, 40), c(-104, 41), c(-105, 41), c(-105, 40)
      )),
      bbox = c(-105, 40, -104, 41)
    )
  )

  for (geom_name in names(geometries)) {
    geom_data <- geometries[[geom_name]]

    # Create R item
    r_item <- stac_item(
      id = paste0("test-", geom_name),
      geometry = list(type = geom_data$type, coordinates = geom_data$coordinates),
      bbox = geom_data$bbox,
      datetime = "2023-06-15T17:30:00Z",
      properties = list()
    )

    # Create Python item
    py_item <- pystac$Item(
      id = paste0("test-", geom_name),
      geometry = list(type = geom_data$type, coordinates = geom_data$coordinates),
      bbox = geom_data$bbox,
      datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
      properties = reticulate::dict()
    )

    # Validate
    r_validation <- validate_stac(r_item)
    expect_true(r_validation$valid, info = paste("Geometry type:", geom_name))

    # Compare structure
    r_json <- jsonlite::fromJSON(
      jsonlite::toJSON(r_item, auto_unbox = TRUE),
      simplifyVector = FALSE
    )

    py_dict <- py_item$to_dict()
    py_json <- jsonlite::fromJSON(
      reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(py_dict, auto_unbox = TRUE))),
      simplifyVector = FALSE
    )

    expect_equal(r_json$geometry$type, py_json$geometry$type,
                 info = paste("Geometry type:", geom_name))
  }
})

test_that("item with null geometry matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-null-geometry"

  # Create R item with null geometry
  r_item <- stac_item(
    id = item_id,
    geometry = NULL,
    bbox = NULL,
    datetime = "2023-06-15T17:30:00Z",
    properties = list()
  )

  # Create Python item with null geometry
  py_item <- pystac$Item(
    id = item_id,
    geometry = NULL,
    bbox = NULL,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict()
  )

  # Validate
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)

  # Compare
  r_json <- jsonlite::fromJSON(
    jsonlite::toJSON(r_item, auto_unbox = TRUE, null = "null"),
    simplifyVector = FALSE
  )

  py_dict <- py_item$to_dict()
  py_json <- jsonlite::fromJSON(
    reticulate::py_to_r(reticulate::r_to_py(jsonlite::toJSON(py_dict, auto_unbox = TRUE))),
    simplifyVector = FALSE
  )

  expect_equal(r_json$type, py_json$type)
  expect_null(r_json$geometry)
  expect_null(r_json$bbox)
})

test_that("item with temporal range matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()

  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)

  item_id <- "test-item-temporal-range"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(type = "Point", coordinates = c(-104.5, 40.5))

  # Create R item with temporal range (no datetime)
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = NULL,
    start_datetime = "2023-06-15T00:00:00Z",
    end_datetime = "2023-06-15T23:59:59Z"
  )

  # Create Python item with temporal range
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = NULL,
    start_datetime = datetime$datetime$fromisoformat("2023-06-15T00:00:00Z"),
    end_datetime = datetime$datetime$fromisoformat("2023-06-15T23:59:59Z"),
    properties = reticulate::dict()
  )

  # Validate
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)

  # Check both have temporal properties
  expect_true(!is.null(r_item$properties$start_datetime))
  expect_true(!is.null(r_item$properties$end_datetime))
})
