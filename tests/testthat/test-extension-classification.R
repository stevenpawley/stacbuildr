# --- classification_class() ---

test_that("classification_class creates a minimal object with just value", {
  cls <- classification_class(value = 1)

  expect_equal(cls$value, 1L)
  expect_null(cls$name)
  expect_null(cls$color_hint)
  expect_s3_class(cls, "classification_class")
})

test_that("classification_class stores all optional fields", {
  cls <- classification_class(
    value       = 3,
    name        = "forest",
    title       = "Forest",
    description = "Dense forest canopy",
    color_hint  = "00FF00",
    nodata      = FALSE,
    percentage  = 45.2,
    count       = 9040L
  )

  expect_equal(cls$value, 3L)
  expect_equal(cls$name, "forest")
  expect_equal(cls$title, "Forest")
  expect_equal(cls$description, "Dense forest canopy")
  expect_equal(cls$color_hint, "00FF00")
  expect_false(cls$nodata)
  expect_equal(cls$percentage, 45.2)
  expect_equal(cls$count, 9040L)
})

test_that("classification_class coerces value and count to integer", {
  cls <- classification_class(value = 2.0, count = 500.0)

  expect_identical(cls$value, 2L)
  expect_identical(cls$count, 500L)
})

test_that("classification_class errors when value is missing", {
  expect_error(classification_class(), "'value' is required")
})

test_that("classification_class errors on invalid name characters", {
  expect_error(
    classification_class(value = 1, name = "bad name!"),
    "letters, numbers, hyphens, and underscores"
  )
})

test_that("classification_class errors on invalid color_hint", {
  # Lowercase
  expect_error(
    classification_class(value = 1, color_hint = "ff0000"),
    "upper-case hexadecimal"
  )
  # Wrong length
  expect_error(
    classification_class(value = 1, color_hint = "F00"),
    "upper-case hexadecimal"
  )
})

test_that("classification_class errors on out-of-range percentage", {
  expect_error(
    classification_class(value = 1, percentage = 101),
    "0 and 100"
  )
  expect_error(
    classification_class(value = 1, percentage = -1),
    "0 and 100"
  )
})

test_that("classification_class errors on non-logical nodata", {
  expect_error(
    classification_class(value = 1, nodata = "yes"),
    "TRUE or FALSE"
  )
})


# --- classification_bitfield() ---

make_classes <- function() {
  list(
    classification_class(value = 0, name = "clear"),
    classification_class(value = 1, name = "flagged")
  )
}

test_that("classification_bitfield creates a valid object", {
  bf <- classification_bitfield(offset = 0, length = 1, classes = make_classes())

  expect_equal(bf$offset, 0L)
  expect_equal(bf$length, 1L)
  expect_length(bf$classes, 2)
  expect_s3_class(bf, "classification_bitfield")
})

test_that("classification_bitfield stores optional fields", {
  bf <- classification_bitfield(
    offset      = 3,
    length      = 2,
    classes     = make_classes(),
    name        = "cloud_conf",
    description = "Cloud confidence",
    roles       = c("data", "cloud")
  )

  expect_equal(bf$offset, 3L)
  expect_equal(bf$length, 2L)
  expect_equal(bf$name, "cloud_conf")
  expect_equal(bf$description, "Cloud confidence")
  expect_equal(bf$roles, list("data", "cloud"))
})

test_that("classification_bitfield coerces offset and length to integer", {
  bf <- classification_bitfield(offset = 2.0, length = 1.0, classes = make_classes())

  expect_identical(bf$offset, 2L)
  expect_identical(bf$length, 1L)
})

test_that("classification_bitfield errors when required args are missing", {
  expect_error(
    classification_bitfield(length = 1, classes = make_classes()),
    "required"
  )
  expect_error(
    classification_bitfield(offset = 0, classes = make_classes()),
    "required"
  )
  expect_error(
    classification_bitfield(offset = 0, length = 1),
    "required"
  )
})

test_that("classification_bitfield errors on negative offset", {
  expect_error(
    classification_bitfield(offset = -1, length = 1, classes = make_classes()),
    "non-negative"
  )
})

test_that("classification_bitfield errors on zero length", {
  expect_error(
    classification_bitfield(offset = 0, length = 0, classes = make_classes()),
    "positive integer"
  )
})

test_that("classification_bitfield errors on empty classes list", {
  expect_error(
    classification_bitfield(offset = 0, length = 1, classes = list()),
    "non-empty"
  )
})

test_that("classification_bitfield errors on invalid name", {
  expect_error(
    classification_bitfield(
      offset = 0, length = 1, classes = make_classes(), name = "bad name!"
    ),
    "letters, numbers, hyphens, and underscores"
  )
})


# --- add_classification_extension() ---

make_item <- function() {
  stac_item(
    id       = "test-classification",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  )
}

test_that("add_classification_extension adds schema URI to stac_extensions", {
  classes <- list(classification_class(value = 1, name = "water"))
  item <- add_classification_extension(make_item(), classes = classes)

  expect_true(
    "https://stac-extensions.github.io/classification/v2.0.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_classification_extension does not duplicate schema URI", {
  classes <- list(classification_class(value = 1, name = "water"))
  item <- make_item() |>
    add_classification_extension(classes = classes) |>
    add_classification_extension(classes = classes)

  n_classification_uris <- sum(grepl("classification", item@stac_extensions))
  expect_equal(n_classification_uris, 1L)
})

test_that("add_classification_extension writes classes to item properties", {
  classes <- list(
    classification_class(value = 1, name = "water"),
    classification_class(value = 2, name = "land")
  )

  item <- add_classification_extension(make_item(), classes = classes)

  expect_length(item@properties$`classification:classes`, 2)
  expect_equal(item@properties$`classification:classes`[[1]]$name, "water")
  expect_equal(item@properties$`classification:classes`[[2]]$name, "land")
})

test_that("add_classification_extension writes bitfields to item properties", {
  bfs <- list(
    classification_bitfield(offset = 0, length = 1, classes = make_classes(), name = "fill")
  )

  item <- add_classification_extension(make_item(), bitfields = bfs)

  expect_length(item@properties$`classification:bitfields`, 1)
  expect_equal(item@properties$`classification:bitfields`[[1]]$name, "fill")
})

test_that("add_classification_extension writes classes to a named asset", {
  classes <- list(classification_class(value = 1, name = "forest"))

  item <- make_item() |>
    add_asset(
      key   = "landcover",
      href  = "https://example.com/lc.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    ) |>
    add_classification_extension(classes = classes, asset_key = "landcover")

  expect_length(item@assets$landcover$`classification:classes`, 1)
  expect_equal(item@assets$landcover$`classification:classes`[[1]]$name, "forest")
  # should NOT be in item properties
  expect_null(item@properties$`classification:classes`)
})

test_that("add_classification_extension writes bitfields to a named asset", {
  bfs <- list(
    classification_bitfield(offset = 3, length = 1, classes = make_classes(), name = "cloud")
  )

  item <- make_item() |>
    add_asset(
      key   = "qa",
      href  = "https://example.com/qa.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    ) |>
    add_classification_extension(bitfields = bfs, asset_key = "qa")

  expect_length(item@assets$qa$`classification:bitfields`, 1)
  expect_equal(item@assets$qa$`classification:bitfields`[[1]]$name, "cloud")
  expect_null(item@properties$`classification:bitfields`)
})

test_that("add_classification_extension errors when both classes and bitfields given", {
  classes  <- list(classification_class(value = 1, name = "water"))
  bfs      <- list(classification_bitfield(offset = 0, length = 1, classes = make_classes()))

  expect_error(
    add_classification_extension(make_item(), classes = classes, bitfields = bfs),
    "not both"
  )
})

test_that("add_classification_extension errors when neither classes nor bitfields given", {
  expect_error(
    add_classification_extension(make_item()),
    "At least one"
  )
})

test_that("add_classification_extension errors on non-item input", {
  expect_error(
    add_classification_extension("not_an_item", classes = list()),
    "'item' must be a stac_item"
  )
})

test_that("add_classification_extension errors on missing asset_key", {
  classes <- list(classification_class(value = 1, name = "water"))

  expect_error(
    add_classification_extension(make_item(), classes = classes, asset_key = "nonexistent"),
    "does not exist"
  )
})
