# --- table_column() ---

test_that("table_column creates a minimal object with just name", {
  col <- table_column(name = "geometry")

  expect_equal(col$name, "geometry")
  expect_null(col$description)
  expect_null(col$type)
  expect_s3_class(col, "table_column")
})

test_that("table_column stores all optional fields", {
  col <- table_column(
    name        = "elevation",
    description = "Elevation in meters",
    type        = "double"
  )

  expect_equal(col$name, "elevation")
  expect_equal(col$description, "Elevation in meters")
  expect_equal(col$type, "double")
})

test_that("table_column stores extra fields via ...", {
  col <- table_column(name = "id", type = "int64", unit = "count")

  expect_equal(col$unit, "count")
})

test_that("table_column errors when name is missing or invalid", {
  expect_error(table_column(), "'name' must be a single character string")
  expect_error(
    table_column(name = c("a", "b")),
    "'name' must be a single character string"
  )
  expect_error(table_column(name = 123), "'name' must be a single character string")
})


# --- add_table_extension() ---

make_item <- function() {
  stac_item(
    id       = "test-table",
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

test_that("add_table_extension errors on non-item input", {
  expect_error(
    add_table_extension("not_an_item", row_count = 10),
    "'item' must be a stac_item"
  )
})

test_that("add_table_extension errors when all fields are NULL", {
  expect_error(
    add_table_extension(make_item()),
    "At least one of 'columns', 'primary_geometry', 'row_count', or"
  )
})

test_that("add_table_extension errors when columns is not a list of table_column objects", {
  expect_error(
    add_table_extension(make_item(), columns = list("not a column")),
    "table_column objects"
  )
  expect_error(
    add_table_extension(make_item(), columns = list()),
    "non-empty list"
  )
})

test_that("add_table_extension errors when primary_geometry is not a single string", {
  expect_error(
    add_table_extension(make_item(), primary_geometry = c("a", "b")),
    "single character string"
  )
})

test_that("add_table_extension errors when row_count is invalid", {
  expect_error(
    add_table_extension(make_item(), row_count = -1),
    "non-negative number"
  )
  expect_error(
    add_table_extension(make_item(), row_count = c(1, 2)),
    "non-negative number"
  )
})

test_that("add_table_extension errors when storage_options is given without asset_key", {
  expect_error(
    add_table_extension(make_item(), storage_options = list(anon = TRUE)),
    "'asset_key' must be provided"
  )
})

test_that("add_table_extension errors when asset_key does not exist", {
  expect_error(
    add_table_extension(
      make_item(),
      storage_options = list(anon = TRUE),
      asset_key = "missing"
    ),
    "does not exist in item"
  )
})

test_that("add_table_extension errors on a missing asset_key without storage_options", {
  expect_error(
    add_table_extension(make_item(), row_count = 10, asset_key = "missing"),
    "does not exist in item"
  )
})

test_that("add_table_extension adds schema URI to stac_extensions", {
  item <- add_table_extension(make_item(), row_count = 100)

  expect_true(
    "https://stac-extensions.github.io/table/v1.2.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_table_extension does not duplicate schema URI", {
  item <- make_item() |>
    add_table_extension(row_count = 100) |>
    add_table_extension(primary_geometry = "geometry")

  n_table_uris <- sum(grepl("table", item@stac_extensions))
  expect_equal(n_table_uris, 1L)
})

test_that("add_table_extension writes table:columns to item properties", {
  cols <- list(
    table_column(name = "geometry", type = "binary"),
    table_column(name = "id", type = "int64")
  )
  item <- add_table_extension(make_item(), columns = cols)

  expect_length(item@properties$`table:columns`, 2)
  expect_equal(item@properties$`table:columns`[[1]]$name, "geometry")
  expect_equal(item@properties$`table:columns`[[2]]$name, "id")
})

test_that("add_table_extension writes table:primary_geometry to item properties", {
  item <- add_table_extension(make_item(), primary_geometry = "geometry")

  expect_equal(item@properties$`table:primary_geometry`, "geometry")
})

test_that("add_table_extension writes table:row_count to item properties", {
  item <- add_table_extension(make_item(), row_count = 15000)

  expect_equal(item@properties$`table:row_count`, 15000)
})

test_that("add_table_extension writes table:storage_options to the specified asset", {
  item <- add_table_extension(
    make_item_with_asset(),
    storage_options = list(anon = TRUE),
    asset_key = "data"
  )

  expect_equal(item@assets$data$`table:storage_options`, list(anon = TRUE))
  expect_null(item@properties$`table:storage_options`)
})

test_that("add_table_extension can set all fields at once", {
  cols <- list(table_column(name = "geometry", type = "binary"))
  item <- add_table_extension(
    make_item_with_asset(),
    columns          = cols,
    primary_geometry = "geometry",
    row_count        = 42,
    storage_options  = list(anon = TRUE),
    asset_key        = "data"
  )

  # asset_key routes every field it can, as in the other extensions
  expect_length(item@assets$data$`table:columns`, 1)
  expect_equal(item@assets$data$`table:primary_geometry`, "geometry")
  expect_equal(item@assets$data$`table:row_count`, 42)
  expect_equal(item@assets$data$`table:storage_options`, list(anon = TRUE))

  expect_null(item@properties$`table:columns`)
  expect_null(item@properties$`table:primary_geometry`)
  expect_null(item@properties$`table:row_count`)
})

test_that("add_table_extension routes columns to an asset when asset_key is given", {
  cols <- list(
    table_column(name = "geometry", type = "binary"),
    table_column(name = "id", type = "int64")
  )
  item <- add_table_extension(
    make_item_with_asset(),
    columns = cols,
    asset_key = "data"
  )

  expect_length(item@assets$data$`table:columns`, 2)
  expect_null(item@properties$`table:columns`)
})

test_that("add_table_extension keeps item-level placement when asset_key is omitted", {
  item <- add_table_extension(
    make_item_with_asset(),
    columns          = list(table_column(name = "geometry")),
    primary_geometry = "geometry",
    row_count        = 42
  )

  expect_length(item@properties$`table:columns`, 1)
  expect_equal(item@properties$`table:primary_geometry`, "geometry")
  expect_equal(item@properties$`table:row_count`, 42)
  expect_null(item@assets$data$`table:columns`)
})
