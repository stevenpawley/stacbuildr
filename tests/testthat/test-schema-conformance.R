# Validates serialised output against the official JSON Schemas published at
# schemas.stacspec.org.
#
# The rest of the suite asserts on R objects, which cannot see the class of bug
# that only appears once an object becomes JSON: a length-1 vector unboxed to a
# scalar where the schema wants an array, a list element dropped instead of
# written as null, or a field whose presence depends on a link. These tests
# close that gap by checking the bytes that are actually written.
#
# They need the network, so they skip when it is unavailable. bundle_schema_url()
# caches each schema in the session tempdir, so the downloads happen once.

skip_if_no_schema_validation <- function() {
  skip_if_not_installed("jsonvalidate")
  # skip_if_offline() calls check_installed("curl"), which errors rather than
  # skipping, so check for curl first. It also implies skip_on_cran().
  skip_if_not_installed("curl")
  skip_if_offline()
}

expect_valid_stac <- function(object) {
  result <- validate_stac_schema(object)
  expect_true(
    result$valid,
    info = paste0(
      "schema errors: ", paste(result$errors, collapse = "; ")
    )
  )
  invisible(result)
}

# Validate a written file against the schema for whatever type it declares,
# plus every extension it lists. Checks the writer's own bytes rather than a
# re-serialised object.
expect_valid_stac_file <- function(path) {
  parsed <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  version <- parsed$stac_version %||% "1.1.0"
  base <- paste0("https://schemas.stacspec.org/v", version)
  core <- switch(
    parsed$type,
    Feature = paste0(base, "/item-spec/json-schema/item.json"),
    Collection = paste0(base, "/collection-spec/json-schema/collection.json"),
    paste0(base, "/catalog-spec/json-schema/catalog.json")
  )

  json <- paste(readLines(path, warn = FALSE), collapse = "\n")
  errors <- run_schema_validation(json, core)
  for (uri in unlist(parsed$stac_extensions %||% list())) {
    errors <- c(errors, run_schema_validation(json, uri))
  }

  expect_true(
    length(errors) == 0,
    info = paste0(basename(path), " errors: ", paste(errors, collapse = "; "))
  )
  invisible(errors)
}

test_extent <- function() {
  stac_extent(
    spatial_bbox = list(c(-120, 30, -100, 50)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", "2021-01-01T00:00:00Z"))
  )
}

test_item <- function(id = "item-1", ...) {
  stac_item(
    id = id,
    geometry = list(
      type = "Polygon",
      coordinates = list(list(
        c(-120, 30), c(-100, 30), c(-100, 50), c(-120, 50), c(-120, 30)
      ))
    ),
    bbox = c(-120, 30, -100, 50),
    datetime = "2020-06-01T00:00:00Z",
    ...
  ) |>
    add_asset(
      "data",
      href = "./data.tif",
      type = "image/tiff; application=geotiff",
      roles = "data"
    )
}

test_that("core objects validate against the published schemas", {
  skip_if_no_schema_validation()

  expect_valid_stac(stac_catalog(id = "c", description = "A catalog"))
  expect_valid_stac(stac_collection(
    id = "col",
    description = "A collection",
    license = "CC-BY-4.0",
    extent = test_extent()
  ))
  expect_valid_stac(test_item())
})

test_that("single-valued array fields validate against the published schemas", {
  skip_if_no_schema_validation()

  # One keyword, one provider role and one instrument: each collapses to a
  # JSON scalar under auto_unbox unless deliberately kept as an array
  expect_valid_stac(stac_collection(
    id = "col",
    description = "A collection",
    license = "CC-BY-4.0",
    extent = test_extent(),
    keywords = "dem",
    providers = list(stac_provider("ACME", roles = "host")),
    summaries = stac_summaries(platform = "landsat-8")
  ))

  expect_valid_stac(test_item(instruments = "oli"))
})

test_that("an item with a datetime range validates", {
  skip_if_no_schema_validation()

  # datetime must be present and null, with the range beside it
  expect_valid_stac(stac_item(
    id = "range",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    start_datetime = "2020-01-01T00:00:00Z",
    end_datetime = "2020-12-31T00:00:00Z"
  ))
})

test_that("an antimeridian bbox validates", {
  skip_if_no_schema_validation()

  expect_valid_stac(stac_item(
    id = "fiji",
    geometry = list(type = "Point", coordinates = c(179, -18)),
    bbox = c(177, -20, -178, -16),
    datetime = "2020-06-01T00:00:00Z"
  ))
})

test_that("each extension validates against its own schema", {
  skip_if_no_schema_validation()

  expect_valid_stac(add_eo_extension(
    test_item(),
    asset_key = "data",
    bands = list(eo_band("B4", "red", wavelength = 0.665)),
    cloud_cover = 12
  ))

  expect_valid_stac(add_raster_extension(
    test_item(),
    asset_key = "data",
    bands = list(raster_band(data_type = "uint16", nodata = 0))
  ))

  expect_valid_stac(add_classification_extension(
    test_item(),
    asset_key = "data",
    classes = list(classification_class(value = 1, name = "water"))
  ))

  expect_valid_stac(add_scientific_extension(
    test_item(),
    doi = "10.1234/abcd",
    citation = "A citation"
  ))

  expect_valid_stac(add_table_extension(
    test_item(),
    columns = list(table_column("a", type = "int64")),
    row_count = 10
  ))

  # Single-valued fields in each of these used to collapse to scalars
  expect_valid_stac(add_vector_extension(
    test_item(),
    geometry_types = "Polygon"
  ))

  expect_valid_stac(add_render_extension(
    test_item(),
    renders = list(rgb = render_object(assets = "data"))
  ))

  expect_valid_stac(add_datacube_extension(
    test_item(),
    dimensions = list(b = cube_dimension("bands", values = "B1"))
  ))

  expect_valid_stac(add_pointcloud_extension(
    test_item(),
    count = 81590,
    type = "lidar",
    density = 1.5356,
    schemas = list(pc_schema("X", size = 8, type = "floating")),
    statistics = list(pc_statistic("X", position = 0, minimum = 0, maximum = 1))
  ))

  # pc:count is typed as an integer, so a count past R's integer range must not
  # pick up a decimal point on the way out
  expect_valid_stac(add_pointcloud_extension(
    test_item(),
    count = 5e9,
    type = "lidar"
  ))
})

test_that("a collection with item_assets validates", {
  skip_if_no_schema_validation()

  collection <- stac_collection(
    id = "col",
    description = "A collection",
    license = "CC-BY-4.0",
    extent = test_extent()
  ) |>
    add_item(test_item()) |>
    add_item_assets()

  expect_valid_stac(collection)
})

# Every written file in a full tree, for each of the three link layouts
for (layout in c("self-contained", "relative", "absolute")) {
  local({
    catalog_type <- layout

    test_that(paste0("a written ", catalog_type, " catalog validates"), {
      skip_if_no_schema_validation()

      collection <- stac_collection(
        id = "col-a",
        description = "A collection",
        license = "CC-BY-4.0",
        extent = test_extent()
      ) |>
        add_item(test_item())

      catalog <- stac_catalog(id = "root", description = "Root") |>
        add_child(
          add_child(stac_catalog(id = "sub", description = "Sub"), collection)
        )

      path <- withr::local_tempdir()
      base_url <- if (catalog_type == "self-contained") {
        NULL
      } else {
        "https://example.com/stac"
      }
      write_stac(
        catalog,
        path,
        catalog_type = catalog_type,
        overwrite = TRUE,
        base_url = base_url
      )

      files <- list.files(path, pattern = "[.]json$", recursive = TRUE, full.names = TRUE)
      expect_length(files, 4)
      for (file in files) {
        expect_valid_stac_file(file)
      }
    })
  })
}
