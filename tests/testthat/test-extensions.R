test_that("item with extensions matches pystac", {
  skip_if_not_installed("reticulate")
  skip_if_no_pystac()
  
  pystac <- reticulate::import("pystac")
  datetime <- reticulate::import("datetime", convert = FALSE)
  
  item_id <- "test-item-extensions"
  bbox <- c(-105, 40, -104, 41)
  geometry <- list(type = "Point", coordinates = c(-104.5, 40.5))
  
  # Create R item with extensions
  r_item <- stac_item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = "2023-06-15T17:30:00Z",
    properties = list(),
    stac_extensions = list(
      "https://stac-extensions.github.io/eo/v1.0.0/schema.json"
    )
  )
  
  # Create Python item with extensions
  py_item <- pystac$Item(
    id = item_id,
    geometry = geometry,
    bbox = bbox,
    datetime = datetime$datetime$fromisoformat("2023-06-15T17:30:00Z"),
    properties = reticulate::dict(),
    stac_extensions = list(
      "https://stac-extensions.github.io/eo/v1.0.0/schema.json"
    )
  )
  
  # Validate
  r_validation <- validate_stac(r_item)
  expect_true(r_validation$valid)
  
  # Check extensions
  expect_length(r_item$stac_extensions, 1)
  expect_true(grepl("eo", r_item$stac_extensions[[1]]))
})