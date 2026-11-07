# Tests for the extension registry (R/extension-registry.R): the single
# table of schema versions the package declares, and the helpers that read it.
# The per-extension test files already assert the exact URIs that
# add_*_extension() declares, so they pin the behaviour this refactor must
# preserve; these tests pin the registry mechanics themselves.

test_that("registry covers the bundled extensions with well-formed entries", {
  expect_setequal(
    names(stac_extension_registry),
    c(
      "classification", "datacube", "eo", "pointcloud", "projection",
      "raster", "render", "scientific", "table", "vector"
    )
  )

  for (name in names(stac_extension_registry)) {
    entry <- stac_extension_registry[[name]]
    expect_match(entry$version, "^v[0-9]+\\.[0-9]+\\.[0-9]+$")
    expect_type(entry$experimental, "logical")

    uri <- extension_schema_uri(name)
    expect_equal(
      uri,
      paste0(
        "https://stac-extensions.github.io/", name, "/",
        entry$version, "/schema.json"
      )
    )

    # The print helpers parse URIs back into name + version; registry URIs
    # must round-trip through them
    expect_equal(stac_extension_names(uri), name)
    expect_equal(stac_extension_versions(uri), entry$version)
  }
})


test_that("pre-1.0 extensions are flagged experimental", {
  expect_true(stac_extension_is_experimental("vector"))
  expect_false(stac_extension_is_experimental("eo"))
  expect_error(stac_extension_is_experimental("nope"), "Unknown stacbuildr extension")
})


test_that("extension_schema_uri precedence: argument, then option, then registry", {
  expect_equal(
    extension_schema_uri("eo"),
    "https://stac-extensions.github.io/eo/v2.0.0/schema.json"
  )
  expect_equal(
    extension_schema_uri("eo", version = "v9.9.9"),
    "https://stac-extensions.github.io/eo/v9.9.9/schema.json"
  )

  withr::local_options(stacbuildr.extension_versions = c(eo = "v3.0.0"))
  expect_equal(
    extension_schema_uri("eo"),
    "https://stac-extensions.github.io/eo/v3.0.0/schema.json"
  )
  # An explicit argument beats the option
  expect_equal(
    extension_schema_uri("eo", version = "v9.9.9"),
    "https://stac-extensions.github.io/eo/v9.9.9/schema.json"
  )
  # The option is per-extension; other extensions keep their registry default
  expect_equal(
    extension_schema_uri("raster"),
    "https://stac-extensions.github.io/raster/v2.0.0/schema.json"
  )
})


test_that("extension_schema_uri rejects unknown extension names", {
  expect_error(extension_schema_uri("nope"), "Unknown stacbuildr extension")
})


test_that("add_stac_extension declares the URI once, on items and collections", {
  item <- stac_item(
    id = "i1",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z"
  )

  item <- add_stac_extension(item, "eo")
  expect_equal(item$stac_extensions, extension_schema_uri("eo"))

  # Declaring the same extension twice does not duplicate the URI
  item <- add_stac_extension(item, "eo")
  expect_length(item$stac_extensions, 1L)

  # Collections carry stac_extensions too (the render extension needs this)
  collection <- stac_collection(
    id = "col",
    description = "d",
    license = "CC-BY-4.0",
    extent = stac_extent(
      spatial_bbox = list(c(-1, -1, 1, 1)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    )
  )
  collection <- add_stac_extension(collection, "render")
  expect_equal(collection$stac_extensions, extension_schema_uri("render"))
})


test_that("the extension_versions option flows through add_*_extension", {
  withr::local_options(stacbuildr.extension_versions = c(eo = "v9.9.9"))

  item <- stac_item(
    id = "i1",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z"
  )
  item <- add_eo_extension(item, cloud_cover = 5)

  expect_true(
    "https://stac-extensions.github.io/eo/v9.9.9/schema.json" %in%
      item$stac_extensions
  )
  # The registry default is untouched
  expect_equal(
    extension_schema_uri("eo", version = NULL),
    "https://stac-extensions.github.io/eo/v9.9.9/schema.json"
  )
  expect_equal(
    stac_extension_registry$eo$version,
    "v2.0.0"
  )
})
