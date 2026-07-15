# --- add_vector_extension() ---

make_item <- function() {
  stac_item(
    id       = "test-vector",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  )
}

make_item_with_asset <- function() {
  make_item() |>
    add_asset(
      "data",
      href = "https://example.com/data.parquet",
      type = "application/x-parquet",
      roles = c("data")
    )
}

test_that("add_vector_extension errors on non-item input", {
  expect_error(
    add_vector_extension("not_an_item", mmu = 10),
    "'item' must be a stac_item"
  )
})

test_that("add_vector_extension errors when all fields are NULL", {
  expect_error(
    add_vector_extension(make_item()),
    "At least one of 'geometry_types', 'mmu', 'mmw', or 'reference_scale'"
  )
})

test_that("add_vector_extension errors on invalid geometry types", {
  expect_error(
    add_vector_extension(make_item(), geometry_types = "Circle"),
    "Invalid geometry type"
  )
})

test_that("add_vector_extension errors on duplicate geometry types", {
  expect_error(
    add_vector_extension(make_item(), geometry_types = c("Point", "Point")),
    "duplicate values"
  )
})

test_that("add_vector_extension errors when mmu is invalid", {
  expect_error(
    add_vector_extension(make_item(), mmu = -1),
    "greater than 0"
  )
  expect_error(
    add_vector_extension(make_item(), mmu = c(1, 2)),
    "single number"
  )
})

test_that("add_vector_extension errors when mmw is invalid", {
  expect_error(
    add_vector_extension(make_item(), mmw = 0),
    "greater than 0"
  )
})

test_that("add_vector_extension errors when reference_scale is invalid", {
  expect_error(
    add_vector_extension(make_item(), reference_scale = 0),
    "greater than 0"
  )
})

test_that("add_vector_extension errors when asset_key does not exist", {
  expect_error(
    add_vector_extension(make_item(), mmu = 10, asset_key = "missing"),
    "does not exist in item"
  )
})

test_that("add_vector_extension adds schema URI to stac_extensions", {
  item <- add_vector_extension(make_item(), mmu = 100)

  expect_true(
    "https://stac-extensions.github.io/vector/v0.1.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_vector_extension does not duplicate schema URI", {
  item <- make_item() |>
    add_vector_extension(mmu = 100) |>
    add_vector_extension(mmw = 5)

  n_vector_uris <- sum(grepl("vector", item@stac_extensions))
  expect_equal(n_vector_uris, 1L)
})

test_that("add_vector_extension writes fields to item properties by default", {
  item <- add_vector_extension(
    make_item(),
    geometry_types  = c("Polygon", "MultiPolygon"),
    mmu             = 100,
    mmw             = 5,
    reference_scale = 50000
  )

  expect_equal(item@properties$`vector:geometry_types`, c("Polygon", "MultiPolygon"))
  expect_equal(item@properties$`vector:mmu`, 100)
  expect_equal(item@properties$`vector:mmw`, 5)
  expect_equal(item@properties$`vector:reference_scale`, 50000)
})

test_that("add_vector_extension writes fields to the specified asset", {
  item <- add_vector_extension(
    make_item_with_asset(),
    geometry_types = "Point",
    mmu = 10,
    asset_key = "data"
  )

  expect_equal(item@assets$data$`vector:geometry_types`, "Point")
  expect_equal(item@assets$data$`vector:mmu`, 10)
  expect_null(item@properties$`vector:geometry_types`)
  expect_null(item@properties$`vector:mmu`)
})
