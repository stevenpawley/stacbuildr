test_that("eo_band exposes standard fields with @ and extensions via extra_fields", {
  band <- eo_band(
    name = "B4",
    common_name = "red",
    center_wavelength = 0.665,
    "raster:scale" = 1e-4
  )

  expect_true(S7::S7_inherits(band, eo_band))
  expect_equal(band@name, "B4")
  expect_equal(band@common_name, "red")
  expect_equal(band@center_wavelength, 0.665)
  expect_equal(band@extra_fields$`raster:scale`, 1e-4)
})

test_that("EO bands remain S7 until serialization", {
  item <- stac_item(
    id = "eo",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  ) |>
    add_eo_extension(bands = list(eo_band("B4", "red")))

  expect_true(S7::S7_inherits(item@properties$bands[[1]], eo_band))

  json <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(item), auto_unbox = TRUE),
    simplifyVector = FALSE
  )
  expect_named(json$properties$bands[[1]], c("name", "eo:common_name"))
})
