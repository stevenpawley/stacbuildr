test_that("every S3 print method is registered where dispatch can find it", {
  # Methods filed only in the package's own S3 methods table are invisible to
  # UseMethod() outside this namespace; .onLoad() re-registers them in base's.
  private <- ls(asNamespace("stacbuildr")[[".__S3MethodsTable__."]])
  base_table <- ls(get(".__S3MethodsTable__.", envir = asNamespace("base")))

  expect_true(all(private %in% base_table))
})

test_that("print dispatches for the S3 sub-object classes", {
  local_reproducible_output(unicode = FALSE)

  cases <- list(
    eo_band = eo_band(name = "B4", common_name = "red"),
    classification_class = classification_class(value = 1, name = "water"),
    classification_bitfield = classification_bitfield(
      offset = 2, length = 2,
      classes = list(classification_class(value = 0, name = "none"))
    ),
    render_object = render_object(assets = "B4"),
    scientific_publication = scientific_publication(
      doi = "10.1000/xyz", citation = "Someone et al."
    ),
    cube_dimension = cube_dimension(type = "spatial", axis = "x", extent = list(0, 1)),
    cube_variable = cube_variable(dimensions = c("x", "y"), type = "data"),
    table_column = table_column(name = "geom", type = "geometry")
  )

  for (cls in names(cases)) {
    expect_s3_class(cases[[cls]], cls)
    # the raw list dump ends in an "attr(,"class")" line; a dispatched method
    # does not
    out <- capture.output(print(cases[[cls]]))
    expect_false(any(grepl("attr(,\"class\")", out, fixed = TRUE)), label = cls)
  }
})

test_that("eo_band carries its class through extra fields", {
  # c() drops attributes, so the class has to survive the extra-field merge
  band <- eo_band(name = "B4", "raster:scale" = 1e-4)
  expect_s3_class(band, "eo_band")
  expect_equal(band$`raster:scale`, 1e-4)
})

test_that("the eo_band class does not leak into JSON", {
  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )
  item <- add_asset(item, "B4", href = "./b4.tif", type = "image/tiff")
  item <- add_eo_extension(
    item,
    bands = list(eo_band(name = "B4", common_name = "red")),
    asset_key = "B4"
  )

  json <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(item), auto_unbox = TRUE),
    simplifyVector = FALSE
  )
  band <- json$assets$B4$`eo:bands`[[1]]
  expect_named(band, c("name", "common_name"))
})
