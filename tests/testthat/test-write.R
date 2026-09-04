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
  # A self-contained catalog carries no self links, since they must be absolute
  expect_false("self" %in% names(item_links))
  expect_equal(item_links[["parent"]], "../collection.json")
  expect_equal(item_links[["root"]], "../../catalog.json")

  unlink(r_dir, recursive = TRUE)
})


# Build a three-level catalog: root > mid > sub, with one item holding a
# relative asset href, for exercising each catalog type.
nested_test_catalog <- function() {
  item <- stac_item(
    id = "i1",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z"
  )
  item <- add_asset(
    item,
    key = "dem",
    asset = stac_asset(href = "../../data/dem.tif", type = "image/tiff")
  )

  sub <- add_item(stac_catalog(id = "sub", description = "d"), item)
  mid <- add_child(stac_catalog(id = "mid", description = "d"), sub)
  add_child(stac_catalog(id = "root", description = "d"), mid)
}

link_hrefs <- function(file) {
  json <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  setNames(
    lapply(json$links, `[[`, "href"),
    vapply(json$links, `[[`, character(1), "rel")
  )
}


test_that("self-contained catalogs have no self links at any level", {
  dir <- tempfile("self_contained_")
  on.exit(unlink(dir, recursive = TRUE))

  write_stac(nested_test_catalog(), dir, catalog_type = "self-contained")

  root <- link_hrefs(file.path(dir, "catalog.json"))
  sub <- link_hrefs(file.path(dir, "mid", "sub", "catalog.json"))
  item <- link_hrefs(file.path(dir, "mid", "sub", "i1", "i1.json"))

  expect_false("self" %in% names(root))
  expect_false("self" %in% names(sub))
  expect_false("self" %in% names(item))
})


test_that("relative catalogs carry one absolute self link on the root", {
  dir <- tempfile("relative_")
  on.exit(unlink(dir, recursive = TRUE))

  write_stac(
    nested_test_catalog(),
    dir,
    catalog_type = "relative",
    base_url = "https://example.com/stac"
  )

  root <- link_hrefs(file.path(dir, "catalog.json"))
  sub <- link_hrefs(file.path(dir, "mid", "sub", "catalog.json"))
  item <- link_hrefs(file.path(dir, "mid", "sub", "i1", "i1.json"))

  expect_equal(root[["self"]], "https://example.com/stac/catalog.json")
  expect_false("self" %in% names(sub))
  expect_false("self" %in% names(item))

  # Every other link stays relative, as in a self-contained catalog
  expect_equal(root[["root"]], "./catalog.json")
  expect_equal(sub[["parent"]], "../catalog.json")
})


test_that("relative catalogs require base_url", {
  expect_error(
    write_stac(nested_test_catalog(), tempfile(), catalog_type = "relative"),
    "base_url"
  )
})


test_that("root links account for nesting depth", {
  dir <- tempfile("depth_")
  on.exit(unlink(dir, recursive = TRUE))

  write_stac(nested_test_catalog(), dir)

  mid <- link_hrefs(file.path(dir, "mid", "catalog.json"))
  sub <- link_hrefs(file.path(dir, "mid", "sub", "catalog.json"))
  item <- link_hrefs(file.path(dir, "mid", "sub", "i1", "i1.json"))

  expect_equal(mid[["root"]], "../catalog.json")
  expect_equal(sub[["root"]], "../../catalog.json")
  expect_equal(item[["root"]], "../../../catalog.json")
})


test_that("absolute catalogs resolve relative asset hrefs against base_url", {
  dir <- tempfile("absolute_")
  on.exit(unlink(dir, recursive = TRUE))

  write_stac(
    nested_test_catalog(),
    dir,
    catalog_type = "absolute",
    base_url = "https://example.com/stac"
  )

  item_file <- file.path(dir, "mid", "sub", "i1", "i1.json")
  item <- link_hrefs(item_file)
  assets <- jsonlite::fromJSON(item_file, simplifyVector = FALSE)$assets

  expect_equal(item[["self"]], "https://example.com/stac/mid/sub/i1/i1.json")
  expect_equal(item[["root"]], "https://example.com/stac/catalog.json")

  # "../../data/dem.tif" resolved from the item's own URL
  expect_equal(
    assets$dem$href,
    "https://example.com/stac/mid/data/dem.tif"
  )
})


test_that("absolute catalogs leave URL asset hrefs alone", {
  dir <- tempfile("absolute_url_")
  on.exit(unlink(dir, recursive = TRUE))

  item <- stac_item(
    id = "i1",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z"
  )
  item <- add_asset(
    item,
    key = "dem",
    asset = stac_asset(href = "s3://bucket/dem.tif", type = "image/tiff")
  )
  catalog <- add_item(stac_catalog(id = "root", description = "d"), item)

  write_stac(
    catalog,
    dir,
    catalog_type = "absolute",
    base_url = "https://example.com/stac"
  )

  assets <- jsonlite::fromJSON(
    file.path(dir, "i1", "i1.json"),
    simplifyVector = FALSE
  )$assets

  expect_equal(assets$dem$href, "s3://bucket/dem.tif")
})


test_that("absolute catalogs warn about local asset paths", {
  dir <- tempfile("absolute_local_")
  on.exit(unlink(dir, recursive = TRUE))

  item <- stac_item(
    id = "i1",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z"
  )
  item <- add_asset(
    item,
    key = "dem",
    asset = stac_asset(href = "/data/dem.tif", type = "image/tiff")
  )
  catalog <- add_item(stac_catalog(id = "root", description = "d"), item)

  expect_warning(
    write_stac(
      catalog,
      dir,
      catalog_type = "absolute",
      base_url = "https://example.com/stac"
    ),
    "cannot be made absolute"
  )
})


test_that("url_join collapses relative segments", {
  expect_equal(
    url_join("https://example.com/stac/mid/sub/i1", "../../data/dem.tif"),
    "https://example.com/stac/mid/data/dem.tif"
  )
  expect_equal(
    url_join("https://example.com/stac/i1", "./dem.tif"),
    "https://example.com/stac/i1/dem.tif"
  )
  expect_equal(
    url_join("https://example.com", "dem.tif"),
    "https://example.com/dem.tif"
  )
})
