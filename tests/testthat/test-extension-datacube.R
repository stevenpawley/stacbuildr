# --- cube_dimension() ---

test_that("cube_dimension creates a horizontal spatial dimension", {
  dim <- cube_dimension(type = "spatial", axis = "x", extent = c(-105.5, -104.5))

  expect_equal(dim$type, "spatial")
  expect_equal(dim$axis, "x")
  expect_equal(dim$extent, c(-105.5, -104.5))
  expect_s3_class(dim, "cube_dimension")
})

test_that("cube_dimension errors on missing type", {
  expect_error(cube_dimension(), "'type' must be a single character string")
})

test_that("cube_dimension errors on horizontal spatial dimension without axis", {
  expect_error(
    cube_dimension(type = "spatial", extent = c(0, 1)),
    "'axis' must be one of 'x', 'y', or 'z'"
  )
})

test_that("cube_dimension errors on horizontal spatial dimension without extent", {
  expect_error(
    cube_dimension(type = "spatial", axis = "x"),
    "'extent' \\(length 2\\) is required for horizontal spatial dimensions"
  )
})

test_that("cube_dimension allows vertical spatial dimension with only values", {
  dim <- cube_dimension(type = "spatial", axis = "z", values = c(0, 10, 20))

  expect_equal(dim$axis, "z")
  expect_equal(dim$values, list(0, 10, 20))
})

test_that("cube_dimension errors on vertical spatial dimension without extent or values", {
  expect_error(
    cube_dimension(type = "spatial", axis = "z"),
    "Either 'extent' or 'values' is required for vertical"
  )
})

test_that("cube_dimension creates a geometry dimension", {
  dim <- cube_dimension(type = "geometry", bbox = c(-105.5, 39.5, -104.5, 40.5))

  expect_equal(dim$type, "geometry")
  expect_equal(dim$bbox, c(-105.5, 39.5, -104.5, 40.5))
})

test_that("cube_dimension errors on geometry dimension without bbox", {
  expect_error(
    cube_dimension(type = "geometry"),
    "'bbox' is required when type = 'geometry'"
  )
})

test_that("cube_dimension creates a temporal dimension", {
  dim <- cube_dimension(
    type = "temporal",
    extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z")
  )

  expect_equal(dim$type, "temporal")
  expect_length(dim$extent, 2)
})

test_that("cube_dimension errors on temporal dimension without extent", {
  expect_error(
    cube_dimension(type = "temporal"),
    "'extent' \\(length 2\\) is required when type = 'temporal'"
  )
})

test_that("cube_dimension creates an additional (custom) dimension", {
  dim <- cube_dimension(type = "bands", values = c("B02", "B03", "B04"))

  expect_equal(dim$type, "bands")
  expect_equal(dim$values, list("B02", "B03", "B04"))
})

test_that("cube_dimension errors on additional dimension without extent or values", {
  expect_error(
    cube_dimension(type = "bands"),
    "Either 'extent' or 'values' is required for additional dimensions"
  )
})

test_that("cube_dimension stores extra fields via ...", {
  dim <- cube_dimension(
    type = "temporal",
    extent = c("2023-06-01T00:00:00Z", NA),
    reference_system = "custom"
  )

  # reference_system is only kept for spatial/geometry dimensions
  expect_null(dim$reference_system)
})


# --- cube_variable() ---

test_that("cube_variable creates a minimal data variable", {
  var <- cube_variable(type = "data", dimensions = c("x", "y", "time"))

  expect_equal(var$type, "data")
  expect_equal(var$dimensions, list("x", "y", "time"))
  expect_s3_class(var, "cube_variable")
})

test_that("cube_variable allows an empty dimensions vector", {
  var <- cube_variable(type = "auxiliary", dimensions = character(0))

  expect_equal(var$dimensions, list())
})

test_that("cube_variable stores all optional fields", {
  var <- cube_variable(
    type = "data",
    dimensions = c("x", "y", "time"),
    unit = "degC",
    data_type = "float32",
    nodata = -9999,
    description = "Air temperature"
  )

  expect_equal(var$unit, "degC")
  expect_equal(var$data_type, "float32")
  expect_equal(var$nodata, -9999)
  expect_equal(var$description, "Air temperature")
})

test_that("cube_variable errors on missing or invalid type", {
  expect_error(cube_variable(), "'type' must be a single character string")
  expect_error(
    cube_variable(type = "not-valid", dimensions = character(0)),
    "'type' must be either 'data' or 'auxiliary'"
  )
})

test_that("cube_variable errors when dimensions is not a character vector", {
  expect_error(
    cube_variable(type = "data", dimensions = 1:3),
    "'dimensions' must be a character vector"
  )
})


# --- add_datacube_extension() ---

make_item <- function() {
  stac_item(
    id       = "test-datacube",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  )
}

make_item_with_asset <- function() {
  make_item() |>
    add_asset(
      "data",
      href = "https://example.com/data.nc",
      type = "application/x-netcdf",
      roles = c("data")
    )
}

make_dims <- function() {
  list(
    x = cube_dimension(type = "spatial", axis = "x", extent = c(-105.5, -104.5)),
    y = cube_dimension(type = "spatial", axis = "y", extent = c(39.5, 40.5)),
    time = cube_dimension(
      type = "temporal",
      extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z")
    )
  )
}

test_that("add_datacube_extension errors on non-item input", {
  expect_error(
    add_datacube_extension("not_an_item", dimensions = make_dims()),
    "'item' must be a stac_item"
  )
})

test_that("add_datacube_extension errors when both dimensions and variables are NULL", {
  expect_error(
    add_datacube_extension(make_item()),
    "At least one of 'dimensions' or 'variables' must be provided"
  )
})

test_that("add_datacube_extension errors when dimensions is not fully named", {
  expect_error(
    add_datacube_extension(make_item(), dimensions = list(cube_dimension(
      type = "temporal",
      extent = c("2023-06-01T00:00:00Z", NA)
    ))),
    "must be a fully named list"
  )
})

test_that("add_datacube_extension errors on duplicate dimension names", {
  dims <- make_dims()
  names(dims) <- c("x", "x", "time")

  expect_error(
    add_datacube_extension(make_item(), dimensions = dims),
    "must not contain duplicate names"
  )
})

test_that("add_datacube_extension errors when elements are not cube_dimension objects", {
  expect_error(
    add_datacube_extension(make_item(), dimensions = list(x = "not a dimension")),
    "must be cube_dimension objects"
  )
})

test_that("add_datacube_extension errors when dimensions and variables share a key", {
  dims <- make_dims()
  vars <- list(x = cube_variable(type = "data", dimensions = c("x", "y", "time")))

  expect_error(
    add_datacube_extension(make_item(), dimensions = dims, variables = vars),
    "must not share keys"
  )
})

test_that("add_datacube_extension errors when asset_key does not exist", {
  expect_error(
    add_datacube_extension(make_item(), dimensions = make_dims(), asset_key = "missing"),
    "does not exist in item"
  )
})

test_that("add_datacube_extension adds schema URI to stac_extensions", {
  item <- add_datacube_extension(make_item(), dimensions = make_dims())

  expect_true(
    "https://stac-extensions.github.io/datacube/v2.3.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_datacube_extension does not duplicate schema URI", {
  item <- make_item() |>
    add_datacube_extension(dimensions = make_dims()) |>
    add_datacube_extension(variables = list(
      temperature = cube_variable(type = "data", dimensions = c("x", "y", "time"))
    ))

  n_datacube_uris <- sum(grepl("datacube", item@stac_extensions))
  expect_equal(n_datacube_uris, 1L)
})

test_that("add_datacube_extension writes fields to item properties by default", {
  vars <- list(
    temperature = cube_variable(type = "data", dimensions = c("x", "y", "time"))
  )
  item <- add_datacube_extension(make_item(), dimensions = make_dims(), variables = vars)

  expect_length(item@properties$`cube:dimensions`, 3)
  expect_equal(item@properties$`cube:dimensions`$x$axis, "x")
  expect_length(item@properties$`cube:variables`, 1)
  expect_equal(item@properties$`cube:variables`$temperature$type, "data")
})

test_that("add_datacube_extension writes fields to the specified asset", {
  item <- add_datacube_extension(
    make_item_with_asset(),
    dimensions = make_dims(),
    asset_key = "data"
  )

  expect_length(item@assets$data$`cube:dimensions`, 3)
  expect_null(item@properties$`cube:dimensions`)
})
