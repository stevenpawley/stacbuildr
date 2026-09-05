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
    stac_asset = stac_asset(href = "./b4.tif", type = "image/tiff", roles = "data"),
    stac_provider = stac_provider(name = "USGS", roles = "producer"),
    stac_summaries = stac_summaries(platform = list("landsat-8")),
    raster_statistics = raster_statistics(minimum = 0, maximum = 1),
    raster_histogram = raster_histogram(count = 2, min = 0, max = 1, buckets = c(1, 2)),
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

test_that("every sub-object prints in the shared style", {
  local_reproducible_output(unicode = FALSE)

  cases <- list(
    "EO Band" = eo_band(name = "B4", common_name = "red", center_wavelength = 0.665),
    "Raster Band" = raster_band(data_type = "uint16", scale = 1, offset = 0),
    "Raster Statistics" = raster_statistics(minimum = 0, maximum = 1),
    "Raster Histogram" = raster_histogram(count = 1, min = 0, max = 1, buckets = 1),
    "Classification Class" = classification_class(value = 1, name = "water"),
    "Classification Bitfield" = classification_bitfield(
      offset = 1, length = 1,
      classes = list(classification_class(value = 0, name = "none"))
    ),
    "Datacube Dimension" = cube_dimension(type = "spatial", axis = "x", extent = list(0, 1)),
    "Datacube Variable" = cube_variable(dimensions = "x", type = "data"),
    "Render Object" = render_object(assets = "B4"),
    "Scientific Publication" = scientific_publication(doi = "10.1/x", citation = "c"),
    "Table Column" = table_column(name = "g", type = "geometry"),
    "STAC Asset" = stac_asset(href = "./b4.tif"),
    "STAC Provider" = stac_provider(name = "USGS"),
    "STAC Summaries" = stac_summaries(platform = list("landsat-8"))
  )

  for (title in names(cases)) {
    out <- capture.output(print(cases[[title]]))
    # a "<Title>" header, then aligned "label : value" lines
    expect_identical(out[[1]], sprintf("<%s>", title))
    expect_true(any(grepl(" : ", out, fixed = TRUE)), label = title)
  }
})

test_that("sub-object fields keep their units and formatting", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(eo_band(name = "B4", center_wavelength = 0.665)))
  expect_true(any(grepl("0.665 micrometres", out, fixed = TRUE)))

  out <- capture.output(print(classification_class(value = 1, color_hint = "0000FF", percentage = 12.5)))
  expect_true(any(grepl("#0000FF", out, fixed = TRUE)))
  expect_true(any(grepl("12.5%", out, fixed = TRUE)))

  out <- capture.output(print(classification_bitfield(
    offset = 1, length = 2,
    classes = list(classification_class(value = 0, name = "none"))
  )))
  expect_true(any(grepl("2 bit(s)", out, fixed = TRUE)))

  out <- capture.output(print(raster_band(data_type = "uint16", scale = 0.5, offset = 2)))
  expect_true(any(grepl("value = 0.5 * DN + 2", out, fixed = TRUE)))
})

test_that("sub-object sections expand", {
  local_reproducible_output(unicode = FALSE)

  bf <- classification_bitfield(
    offset = 1, length = 1,
    classes = list(
      classification_class(value = 0, name = "none"),
      classification_class(value = 1, name = "low")
    )
  )
  # collapsed: an arrow, a count and a preview, but no tree branches
  out <- capture.output(print(bf))
  expect_true(any(grepl("> classes", out, fixed = TRUE)))
  expect_false(any(grepl("`- ", out, fixed = TRUE)))

  # expanded: one branch per class, labelled "<value> <name>"
  out <- capture.output(print(bf, expand = TRUE))
  expect_true(any(grepl("v classes", out, fixed = TRUE)))
  expect_true(any(grepl("|- 0 none", out, fixed = TRUE)))
  expect_true(any(grepl("`- 1 low", out, fixed = TRUE)))

  band <- raster_band(
    data_type = "uint16", scale = 1, offset = 0,
    statistics = raster_statistics(minimum = 1, maximum = 10)
  )
  out <- capture.output(print(band, expand = "statistics"))
  expect_true(any(grepl("minimum", out, fixed = TRUE)))
})

test_that("the classed helpers stay ordinary lists", {
  # the class is for printing only: $ access, is.list() and [[ must all work
  objs <- list(
    stac_asset(href = "./b4.tif", type = "image/tiff"),
    stac_provider(name = "USGS"),
    stac_summaries(platform = list("landsat-8")),
    raster_statistics(minimum = 0, maximum = 1),
    raster_histogram(count = 1, min = 0, max = 1, buckets = 1),
    eo_band(name = "B4")
  )
  for (o in objs) {
    expect_true(is.list(o))
    expect_type(o, "list")
    expect_length(names(o), length(o))
  }

  expect_equal(stac_asset(href = "./b4.tif")$href, "./b4.tif")
  expect_equal(stac_provider(name = "USGS")[["name"]], "USGS")
  expect_equal(raster_statistics(minimum = 3)$minimum, 3)
})

test_that("classed helpers survive being embedded in S7 objects", {
  band <- raster_band(
    data_type = "uint16",
    statistics = raster_statistics(minimum = 1, maximum = 10),
    histogram = raster_histogram(count = 2, min = 0, max = 1, buckets = c(1, 2))
  )
  expect_s3_class(band@statistics, "raster_statistics")
  expect_s3_class(band@histogram, "raster_histogram")

  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )
  item <- add_asset(item, "B4", href = "./b4.tif", type = "image/tiff")
  expect_s3_class(item@assets$B4, "stac_asset")
})

test_that("the new classes do not leak into JSON", {
  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )
  item <- add_asset(
    item, "B4",
    href = "./b4.tif", type = "image/tiff", roles = "data"
  )
  path <- withr::local_tempfile(fileext = ".json")
  write_item(item, path)

  json <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  expect_named(json$assets$B4, c("href", "type", "roles"))
  expect_equal(json$assets$B4$href, "./b4.tif")
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
  band <- json$assets$B4$bands[[1]]
  expect_named(band, c("name", "eo:common_name"))
})
