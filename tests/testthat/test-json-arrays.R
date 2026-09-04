# The writers serialise with jsonlite's auto_unbox = TRUE, which collapses a
# length-1 atomic vector to a JSON scalar. Fields the STAC spec types as arrays
# have to stay arrays even when a single value was supplied, so these tests
# pin the serialised shape rather than the R value.

as_json <- function(x) {
  jsonlite::fromJSON(
    jsonlite::toJSON(
      if (inherits(x, "S7_object")) as.list(x) else x,
      auto_unbox = TRUE,
      null = "null",
      digits = 15
    ),
    simplifyVector = FALSE
  )
}

single_extent <- function() {
  stac_extent(
    spatial_bbox = list(c(-1, -1, 1, 1)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )
}

single_item <- function(...) {
  stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2020-01-01T00:00:00Z",
    ...
  )
}

test_that("a single keyword serialises as an array", {
  collection <- stac_collection(
    id = "c",
    description = "d",
    license = "MIT",
    extent = single_extent(),
    keywords = "dem"
  )

  expect_equal(as_json(collection)$keywords, list("dem"))
})

test_that("a single conformsTo URI serialises as an array", {
  uri <- "https://api.stacspec.org/v1.0.0/core"

  expect_equal(as_json(stac_catalog(
    id = "c", description = "d", conformsTo = uri
  ))$conformsTo, list(uri))

  expect_equal(as_json(stac_collection(
    id = "c", description = "d", license = "MIT",
    extent = single_extent(), conformsTo = uri
  ))$conformsTo, list(uri))
})

test_that("a single provider role serialises as an array", {
  provider <- stac_provider("ACME", roles = "host")
  expect_equal(as_json(provider)$roles, list("host"))
})

test_that("a single summary value serialises as an array", {
  summaries <- stac_summaries(
    platform = "landsat-8",
    gsd = list(minimum = 15, maximum = 30)
  )
  json <- as_json(summaries)

  expect_equal(json$platform, list("landsat-8"))
  # Range objects are not value sets and must stay objects
  expect_equal(json$gsd, list(minimum = 15, maximum = 30))
})

test_that("single-valued common metadata arrays survive on items and assets", {
  item <- single_item(instruments = "oli", platform = "landsat-8")
  json <- as_json(item)

  expect_equal(json$properties$instruments, list("oli"))
  # platform is a plain string in the spec and must not become an array
  expect_equal(json$properties$platform, "landsat-8")

  asset <- stac_asset(href = "d.tif", roles = "data")
  expect_equal(as_json(asset)$roles, list("data"))
})

test_that("a single vector:geometry_types value serialises as an array", {
  item <- add_vector_extension(single_item(), geometry_types = "Polygon")
  expect_equal(as_json(item)$properties$`vector:geometry_types`, list("Polygon"))
})

test_that("single-valued render fields serialise as arrays", {
  item <- add_render_extension(
    single_item(),
    renders = list(rgb = render_object(assets = "data", bidx = 1))
  )
  json <- as_json(item)$properties$renders$rgb

  expect_equal(json$assets, list("data"))
  expect_equal(json$bidx, list(1))
})

test_that("single-valued datacube fields serialise as arrays", {
  item <- add_datacube_extension(
    single_item(),
    dimensions = list(b = cube_dimension("bands", values = "B1")),
    variables = list(v = cube_variable(dimensions = "b", type = "data"))
  )
  json <- as_json(item)$properties

  expect_equal(json$`cube:dimensions`$b$values, list("B1"))
  expect_equal(json$`cube:variables`$v$dimensions, list("b"))
})

test_that("as_json_array leaves non-array values alone", {
  expect_null(as_json_array(NULL))
  # already a list: passed through untouched, including named lists
  expect_equal(as_json_array(list(a = 1)), list(a = 1))
  expect_equal(as_json_array(c("a", "b")), list("a", "b"))
  # character(0) stays an empty array rather than becoming NULL
  expect_equal(as_json_array(character(0)), list())
})
