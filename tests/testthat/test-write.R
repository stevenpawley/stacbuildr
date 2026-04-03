test_that("write_stac output is readable and valid according to pystac", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")
  pystac <- reticulate::import("pystac")

  item_id <- "observation-001"
  collection_id <- "landsat-8-c2-l2"
  catalog_id <- "test-catalog"
  bbox <- c(-105.0, 40.0, -105.0, 40.0)
  geometry <- list(type = "Point", coordinates = c(-105.0, 40.0))
  asset_href <- "https://example.com/LC08_visual.tif"

  r_dir <- tempfile("r_stac_")

  r_catalog <- stac_catalog(
    id = catalog_id,
    description = "Test catalog"
  )

  r_collection <- stac_collection(
    id = collection_id,
    description = "Landsat 8 Collection 2 Level-2 Surface Reflectance",
    license = "CC0-1.0",
    extent = list(
      spatial = list(bbox = list(c(-180, -90, 180, 90))),
      temporal = list(interval = list(list("2013-04-11T00:00:00Z", NULL)))
    )
  )

  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T10:30:00Z"
  )

  r_item <- add_asset(
    r_item,
    key = "visual",
    asset = stac_asset(
      href = asset_href,
      title = "True Color Image",
      type = "image/tiff; application=geotiff",
      roles = c("visual")
    )
  )

  r_collection <- add_item(r_collection, r_item)
  r_catalog <- add_child(r_catalog, r_collection)
  write_stac(r_catalog, r_dir)

  # Verify the directory structure was created
  catalog_file <- file.path(r_dir, "catalog.json")
  collection_file <- file.path(r_dir, collection_id, "collection.json")
  item_file <- file.path(
    r_dir, collection_id, item_id, paste0(item_id, ".json")
  )

  expect_true(file.exists(catalog_file))
  expect_true(file.exists(collection_file))
  expect_true(file.exists(item_file))

  # Read back with pystac and check it validates without errors
  py_catalog <- pystac$read_file(catalog_file)
  expect_equal(
    reticulate::py_to_r(py_catalog$id),
    catalog_id
  )
  expect_equal(
    reticulate::py_to_r(py_catalog$description),
    "Test catalog"
  )

  # Read back the collection and check its fields
  py_collection <- pystac$read_file(collection_file)
  expect_equal(reticulate::py_to_r(py_collection$id), collection_id)
  expect_equal(
    reticulate::py_to_r(py_collection$description),
    "Landsat 8 Collection 2 Level-2 Surface Reflectance"
  )
  expect_equal(reticulate::py_to_r(py_collection$license), "CC0-1.0")

  # Read back the item and check its fields
  py_item <- pystac$read_file(item_file)
  expect_equal(reticulate::py_to_r(py_item$id), item_id)

  py_bbox <- reticulate::py_to_r(py_item$bbox)
  expect_equal(unlist(py_bbox), bbox)

  py_geom_type <- reticulate::py_to_r(py_item$geometry[["type"]])
  expect_equal(py_geom_type, "Point")

  # Check asset round-trips correctly
  py_assets <- reticulate::py_to_r(py_item$assets)
  expect_true("visual" %in% names(py_assets))

  py_visual <- py_item$assets[["visual"]]
  expect_equal(reticulate::py_to_r(py_visual$href), asset_href)
  expect_equal(
    reticulate::py_to_r(py_visual$title),
    "True Color Image"
  )
  expect_equal(
    reticulate::py_to_r(py_visual$media_type),
    "image/tiff; application=geotiff"
  )

  # Check links: catalog should have a child link to the collection
  expect_gt(length(py_catalog$get_child_links()), 0L)

  # Check links: collection should have an item link
  expect_gt(length(py_collection$get_item_links()), 0L)

  # Check item link hrefs are relative to the item's own subdirectory
  r_item_json <- jsonlite::fromJSON(item_file, simplifyVector = FALSE)
  item_links <- setNames(
    lapply(r_item_json$links, `[[`, "href"),
    vapply(r_item_json$links, `[[`, character(1), "rel")
  )
  expect_equal(item_links[["self"]], paste0("./", item_id, ".json"))
  expect_equal(item_links[["parent"]], "../collection.json")
  expect_equal(item_links[["root"]], "../../catalog.json")

  unlink(r_dir, recursive = TRUE)
})
