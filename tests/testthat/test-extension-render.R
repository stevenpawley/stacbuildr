# --- render_object() ---

test_that("render_object creates a minimal render object", {
  render <- render_object(assets = c("B4", "B3", "B2"))

  expect_equal(render$assets, list("B4", "B3", "B2"))
  expect_s3_class(render, "render_object")
})

test_that("render_object stores all optional fields", {
  cmap <- list("0" = "#ffffff", "255" = "#000000")

  render <- render_object(
    assets = c("B5", "B4"),
    title = "NDVI",
    rescale = list(c(-1, 1)),
    nodata = 0,
    colormap_name = "ylgn",
    colormap = cmap,
    color_formula = "gamma R 1.2",
    resampling = "average",
    expression = "(B5-B4)/(B5+B4)",
    minmax_zoom = c(0, 18),
    bidx = c(1, 2)
  )

  expect_equal(render$title, "NDVI")
  expect_equal(render$rescale, list(c(-1, 1)))
  expect_equal(render$nodata, 0)
  expect_equal(render$colormap_name, "ylgn")
  expect_equal(render$colormap, cmap)
  expect_equal(render$color_formula, "gamma R 1.2")
  expect_equal(render$resampling, "average")
  expect_equal(render$expression, "(B5-B4)/(B5+B4)")
  expect_equal(render$minmax_zoom, c(0, 18))
  expect_equal(render$bidx, list(1, 2))
})

test_that("render_object stores extra fields via ...", {
  render <- render_object(
    assets = c("B4"),
    width = 1024,
    height = 1024,
    bands = c("B4")
  )

  expect_equal(render$width, 1024)
  expect_equal(render$height, 1024)
  expect_equal(render$bands, c("B4"))
})

test_that("render_object errors when assets is missing", {
  expect_error(render_object(), "'assets' must be a non-empty character vector")
})

test_that("render_object errors when assets is empty", {
  expect_error(render_object(assets = character(0)), "'assets' must be a non-empty character vector")
})

test_that("render_object errors when title is not a single string", {
  expect_error(render_object(assets = "B4", title = c("a", "b")), "'title' must be a single character string")
})

test_that("render_object errors when rescale is malformed", {
  expect_error(
    render_object(assets = "B4", rescale = list(c(0, 1, 2))),
    "Each element of 'rescale' must be a numeric vector of length 2"
  )
  expect_error(
    render_object(assets = "B4", rescale = c(0, 1)),
    "'rescale' must be a non-empty list of numeric vectors"
  )
})

test_that("render_object errors when minmax_zoom is not length 2", {
  expect_error(
    render_object(assets = "B4", minmax_zoom = c(0, 10, 20)),
    "'minmax_zoom' must be a numeric vector of length 2"
  )
})


# --- add_render_extension() ---

make_item <- function() {
  stac_item(
    id       = "render-test",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  ) |>
    add_asset(
      key   = "B4",
      href  = "https://example.com/B4.tif",
      type  = "image/tiff; application=geotiff",
      roles = c("data")
    )
}

make_collection <- function() {
  stac_collection(
    id = "render-collection",
    description = "Collection with render support",
    license = "CC0-1.0",
    extent = stac_extent(
      spatial_bbox = list(c(-180, -90, 180, 90)),
      temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
    )
  )
}

test_that("add_render_extension errors on non-STAC input", {
  expect_error(
    add_render_extension("not_stac", renders = list(rgb = render_object("B4"))),
    "'item' must be a stac_item or stac_collection object"
  )
})

test_that("add_render_extension errors when renders is not named", {
  expect_error(
    add_render_extension(make_item(), renders = list(render_object("B4"))),
    "'renders' must be a fully named list"
  )
})

test_that("add_render_extension errors on duplicate render keys", {
  expect_error(
    add_render_extension(
      make_item(),
      renders = list(rgb = render_object("B4"), rgb = render_object("B3"))
    ),
    "'renders' must not contain duplicate names"
  )
})

test_that("add_render_extension errors when elements are not render objects", {
  expect_error(
    add_render_extension(make_item(), renders = list(rgb = "not a render")),
    "All elements of 'renders' must be render_object objects"
  )
})

test_that("add_render_extension adds schema URI to item stac_extensions", {
  item <- make_item() |>
    add_render_extension(renders = list(rgb = render_object("B4")))

  expect_true(
    "https://stac-extensions.github.io/render/v2.0.0/schema.json" %in%
      item@stac_extensions
  )
})

test_that("add_render_extension adds schema URI to collection stac_extensions", {
  collection <- make_collection() |>
    add_render_extension(renders = list(rgb = render_object("B4")))

  expect_true(
    "https://stac-extensions.github.io/render/v2.0.0/schema.json" %in%
      collection@stac_extensions
  )
})

test_that("add_render_extension does not duplicate schema URI", {
  item <- make_item() |>
    add_render_extension(renders = list(rgb = render_object("B4"))) |>
    add_render_extension(renders = list(ndvi = render_object("B5")))

  n_render_uris <- sum(grepl("render", item@stac_extensions))
  expect_equal(n_render_uris, 1L)
})

test_that("add_render_extension writes renders to item properties", {
  item <- make_item() |>
    add_render_extension(renders = list(
      rgb = render_object(assets = c("B4", "B3", "B2"))
    ))

  expect_length(item@properties$renders, 1)
  expect_equal(item@properties$renders$rgb$assets, list("B4", "B3", "B2"))
})

test_that("add_render_extension writes renders to collection extra_fields", {
  collection <- make_collection() |>
    add_render_extension(renders = list(
      rgb = render_object(assets = c("B4", "B3", "B2"))
    ))

  expect_length(collection@extra_fields$renders, 1)
  expect_equal(collection@extra_fields$renders$rgb$assets, list("B4", "B3", "B2"))
})

test_that("add_render_extension merges and overwrites render objects", {
  item <- make_item() |>
    add_render_extension(renders = list(
      rgb = render_object(assets = c("B4"))
    )) |>
    add_render_extension(renders = list(
      rgb = render_object(assets = c("B4", "B3", "B2")),
      ndvi = render_object(assets = c("B5", "B4"))
    ))

  expect_length(item@properties$renders, 2)
  expect_equal(item@properties$renders$rgb$assets, list("B4", "B3", "B2"))
  expect_equal(item@properties$renders$ndvi$assets, list("B5", "B4"))
})
