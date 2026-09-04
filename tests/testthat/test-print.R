# Helpers ---------------------------------------------------------------

test_item <- function() {
  item <- stac_item(
    id = "test-item",
    collection = "test-collection",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox = c(-105, 40, -105, 40),
    datetime = "2023-01-01T00:00:00Z",
    properties = list("eo:cloud_cover" = 5)
  )
  item <- add_asset(
    item,
    key = "B4",
    href = "https://example.com/B4.tif",
    type = "image/tiff; application=geotiff",
    roles = "data"
  )
  add_self_link(item, "https://example.com/item.json")
}

test_collection <- function() {
  stac_collection(
    id = "test-collection",
    description = "A collection used for testing print output",
    license = "CC-BY-4.0",
    extent = stac_extent(
      spatial_bbox = list(c(-180, -90, 180, 90)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    ),
    providers = list(stac_provider(name = "Test Provider", roles = "producer")),
    summaries = list(platform = list("a", "b"))
  )
}

test_catalog <- function() {
  cat_obj <- stac_catalog(
    id = "test-catalog",
    description = "A catalog used for testing print output"
  )
  add_child(cat_obj, test_collection())
}

# Collapsed output ------------------------------------------------------

test_that("item prints scalar fields and collapsed sections", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(test_item()))

  expect_true(any(grepl("<STAC Item>", out, fixed = TRUE)))
  expect_true(any(grepl("id           : test-item", out, fixed = TRUE)))
  expect_true(any(grepl("> assets     : 1 [B4]", out, fixed = TRUE)))
  expect_true(any(grepl("> links      : 1 [self]", out, fixed = TRUE)))
  # collapsed sections show counts, not the detail
  expect_false(any(grepl("https://example.com/B4.tif", out, fixed = TRUE)))
  expect_true(any(grepl("collapsed section", out, fixed = TRUE)))
})

test_that("collection and catalog print collapsed sections", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(test_collection()))
  expect_true(any(grepl("<STAC Collection>", out, fixed = TRUE)))
  expect_true(any(grepl("> providers  : 1 [Test Provider]", out, fixed = TRUE)))
  expect_true(any(grepl("> summaries  : 1 [platform]", out, fixed = TRUE)))
  expect_false(any(grepl("producer", out, fixed = TRUE)))

  out <- capture.output(print(test_catalog()))
  expect_true(any(grepl("<STAC Catalog>", out, fixed = TRUE)))
  expect_true(any(grepl("> children   : 1 [test-collection]", out, fixed = TRUE)))
})

# Expansion -------------------------------------------------------------

test_that("expand = TRUE expands every section", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(test_item(), expand = TRUE))

  expect_true(any(grepl("v assets     : 1", out, fixed = TRUE)))
  expect_true(any(grepl("https://example.com/B4.tif", out, fixed = TRUE)))
  expect_true(any(grepl("https://example.com/item.json", out, fixed = TRUE)))
  expect_true(any(grepl("eo:cloud_cover", out, fixed = TRUE)))
  # nothing left collapsed, so no hint
  expect_false(any(grepl("collapsed section", out, fixed = TRUE)))
})

test_that("expand accepts a vector of section names", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(test_item(), expand = "assets"))

  expect_true(any(grepl("v assets     : 1", out, fixed = TRUE)))
  expect_true(any(grepl("https://example.com/B4.tif", out, fixed = TRUE)))
  # links stay collapsed
  expect_true(any(grepl("> links      : 1 [self]", out, fixed = TRUE)))
  expect_false(any(grepl("https://example.com/item.json", out, fixed = TRUE)))
})

test_that("children and items sections expand", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(test_catalog(), expand = "children"))
  expect_true(any(grepl("test-collection Collection", out, fixed = TRUE)))

  coll <- add_item(test_collection(), test_item())
  out <- capture.output(print(coll, expand = "items"))
  expect_true(any(grepl("test-item 2023-01-01T00:00:00Z", out, fixed = TRUE)))
})

test_that("the stacbuildr.print.expand option sets the default", {
  local_reproducible_output(unicode = FALSE)
  withr::local_options(stacbuildr.print.expand = TRUE)

  out <- capture.output(print(test_item()))
  expect_true(any(grepl("https://example.com/B4.tif", out, fixed = TRUE)))

  # an explicit argument still wins over the option
  out <- capture.output(print(test_item(), expand = FALSE))
  expect_false(any(grepl("https://example.com/B4.tif", out, fixed = TRUE)))
})

test_that("the hint can be switched off", {
  local_reproducible_output(unicode = FALSE)
  withr::local_options(stacbuildr.print.hint = FALSE)

  out <- capture.output(print(test_item()))
  expect_false(any(grepl("collapsed section", out, fixed = TRUE)))
})

# Extensions ------------------------------------------------------------

test_that("extensions print as name and version", {
  local_reproducible_output(unicode = FALSE)
  item <- add_eo_extension(
    test_item(),
    bands = list(eo_band(name = "B4", common_name = "red")),
    asset_key = "B4"
  )

  out <- capture.output(print(item))
  expect_true(any(grepl("> extensions : 1 [eo]", out, fixed = TRUE)))

  out <- capture.output(print(item, expand = "extensions"))
  expect_true(any(grepl("eo v1.1.0", out, fixed = TRUE)))
})

test_that("an unrecognised extension URI is printed in full", {
  local_reproducible_output(unicode = FALSE)
  item <- test_item()
  item@stac_extensions <- "https://example.com/my-extension.json"

  out <- capture.output(print(item, expand = "extensions"))
  expect_true(any(grepl("https://example.com/my-extension.json", out, fixed = TRUE)))
})

test_that("item-level extension fields print in the properties section", {
  local_reproducible_output(unicode = FALSE)
  item <- add_scientific_extension(
    test_item(),
    doi = "10.1000/xyz123",
    citation = "Someone et al. (2023)."
  )

  out <- capture.output(print(item, expand = "properties"))
  expect_true(any(grepl("sci:doi", out, fixed = TRUE)))
  expect_true(any(grepl("10.1000/xyz123", out, fixed = TRUE)))
})

test_that("asset-level extension fields print under their asset", {
  local_reproducible_output(unicode = FALSE)
  item <- add_eo_extension(
    test_item(),
    bands = list(
      eo_band(name = "B4", common_name = "red"),
      eo_band(name = "B5", common_name = "nir")
    ),
    asset_key = "B4"
  )
  item <- add_raster_extension(
    item,
    bands = list(raster_band(data_type = "uint16", nodata = 0)),
    asset_key = "B4"
  )

  out <- capture.output(print(item, expand = "assets"))
  # arrays of objects are labelled by the name of each object
  expect_true(any(grepl("eo:bands     [B4, B5]", out, fixed = TRUE)))
  expect_true(any(grepl("raster:bands [uint16]", out, fixed = TRUE)))
  # ... and stay hidden while the section is collapsed
  out <- capture.output(print(item))
  expect_false(any(grepl("eo:bands", out, fixed = TRUE)))
})

test_that("unlabelled arrays of objects fall back to a count", {
  local_reproducible_output(unicode = FALSE)
  item <- test_item()
  item@properties$`custom:things` <- list(list(a = 1), list(a = 2))

  out <- capture.output(print(item, expand = "properties"))
  expect_true(any(grepl("custom:things +<2 items>", out)))
})

# Console width ---------------------------------------------------------

test_that("output is truncated to the console width", {
  local_reproducible_output(unicode = FALSE)
  item <- add_asset(
    test_item(),
    key = "long",
    href = paste0("https://data.example.com/", strrep("x", 200), ".tif"),
    type = "image/tiff"
  )

  for (w in c(40L, 60L, 100L)) {
    withr::local_options(cli.width = w)
    out <- capture.output(print(item, expand = TRUE))
    expect_true(all(nchar(out) <= w))
  }
})

# Styling ---------------------------------------------------------------

test_that("output is plain text when the console has no colour", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(test_item(), expand = TRUE))
  expect_false(any(grepl("\033[", out, fixed = TRUE)))
})

test_that("output is coloured when the console supports it", {
  withr::local_options(cli.num_colors = 256, cli.unicode = TRUE)
  out <- capture.output(print(test_item(), expand = TRUE))
  expect_true(any(grepl("\033[", out, fixed = TRUE)))
})

test_that("print returns its input invisibly", {
  local_reproducible_output(unicode = FALSE)

  for (obj in list(test_item(), test_collection(), test_catalog())) {
    expect_output(res <- withVisible(print(obj)))
    expect_false(res$visible)
    expect_identical(res$value, obj)
  }
})
