# Helpers ------------------------------------------------------------------

py_to_r_json <- function(py_obj) {
  jsonlite::fromJSON(
    reticulate::py_to_r(
      reticulate::r_to_py(jsonlite::toJSON(py_obj, auto_unbox = TRUE))
    ),
    simplifyVector = FALSE
  )
}

r_to_r_json <- function(item) {
  jsonlite::fromJSON(
    jsonlite::toJSON(as.list(item), auto_unbox = TRUE, digits = 15),
    simplifyVector = FALSE
  )
}

# stacbuildr follows eo v2.0.0 / raster v2.0.0, which replaced the per-extension
# `eo:bands` and `raster:bands` arrays with the STAC 1.1 common `bands` array
# and prefixed the extension's own band fields. pystac still writes the older
# layout, so these helpers read bands out of whichever layout a document uses,
# keeping the comparison about values rather than about spelling.
bands_of <- function(x) {
  x$bands %||% x$`eo:bands` %||% x$`raster:bands`
}

band_field <- function(band, name) {
  band[[name]] %||%
    band[[paste0("eo:", name)]] %||%
    band[[paste0("raster:", name)]]
}

has_bands <- function(x) {
  any(c("bands", "eo:bands", "raster:bands") %in% names(x))
}

make_r_item <- function() {
  stac_item(
    id = "ext-test",
    geometry = list(type = "Point", coordinates = c(-105.0, 40.0)),
    bbox = c(-105.0, 40.0, -105.0, 40.0),
    datetime = "2023-06-15T10:30:00Z"
  )
}

make_r_asset <- function() {
  stac_asset(
    href = "https://example.com/image.tif",
    title = "RGB Image",
    media_type = "image/tiff; application=geotiff",
  )
}

# EO Extension -------------------------------------------------------------

test_that("add_eo_extension writes bands to item properties matching pystac", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")

  reticulate::py_run_string("
import pystac, datetime
from pystac.extensions.eo import EOExtension, Band

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
eo = EOExtension.ext(py_item, add_if_missing=True)
eo.bands = [Band.create(name='wv3', center_wavelength=0.5)]
py_eo_result = py_item.to_dict()
")

  py_json <- py_to_r_json(reticulate::py$py_eo_result)

  r_item <- make_r_item() |>
    add_eo_extension(bands = list(eo_band(name = "wv3", center_wavelength = 0.5)))
  r_json <- r_to_r_json(r_item)

  # bands in properties (not assets)
  expect_true("bands" %in% names(r_json$properties))
  expect_true(has_bands(py_json$properties))

  # Band count
  expect_length(r_json$properties$bands, length(bands_of(py_json$properties)))

  # Field values inside the band object
  r_band <- bands_of(r_json$properties)[[1]]
  py_band <- bands_of(py_json$properties)[[1]]

  expect_equal(band_field(r_band, "name"), band_field(py_band, "name"))
  expect_equal(
    band_field(r_band, "center_wavelength"),
    band_field(py_band, "center_wavelength")
  )

  # Extension URI registered
  expect_true(any(grepl("stac-extensions.github.io/eo/", r_json$stac_extensions)))
  expect_true(any(grepl("stac-extensions.github.io/eo/", py_json$stac_extensions)))
})

test_that("add_eo_extension writes bands to asset matching pystac", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")

  reticulate::py_run_string("
import pystac, datetime
from pystac.extensions.eo import EOExtension, Band

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
py_item.add_asset('data', pystac.Asset(
    href='https://example.com/image.tif',
    media_type='image/tiff; application=geotiff'
))

eo = EOExtension.ext(py_item, add_if_missing=True)
eo.apply(
    bands=[
        Band.create(name='B4', common_name='red', center_wavelength=0.665),
        Band.create(name='B3', common_name='green', center_wavelength=0.560),
        Band.create(name='B2', common_name='blue', center_wavelength=0.490),
    ])

py_asset_eo_result = py_item.to_dict()
")

  py_json <- py_to_r_json(reticulate::py$py_asset_eo_result)

  r_item <- make_r_item() |>
    add_asset("data", href = "https://example.com/image.tif",
              type = "image/tiff; application=geotiff") |>
    add_eo_extension(
      bands = list(
        eo_band(name = "B4", common_name = "red",   center_wavelength = 0.665),
        eo_band(name = "B3", common_name = "green", center_wavelength = 0.560),
        eo_band(name = "B2", common_name = "blue",  center_wavelength = 0.490)
      ),
      asset_key = "data"
    )
  r_json <- r_to_r_json(r_item)

  # bands on the asset, not item properties
  expect_true("bands" %in% names(r_json$assets$data))
  expect_null(r_json$properties$bands)

  # Band count matches
  expect_length(
    r_json$assets$data$bands,
    length(bands_of(py_json$properties))
  )

  # Field values
  for (i in seq_along(bands_of(py_json$properties))) {
    r_band <- bands_of(r_json$assets$data)[[i]]
    py_band <- bands_of(py_json$properties)[[i]]

    expect_equal(band_field(r_band, "name"), band_field(py_band, "name"))
    expect_equal(
      band_field(r_band, "common_name"),
      band_field(py_band, "common_name")
    )
    expect_equal(
      band_field(r_band, "center_wavelength"),
      band_field(py_band, "center_wavelength")
    )
  }
})

# Raster Extension ---------------------------------------------------------

test_that("add_raster_extension places bands on asset matching pystac", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")

  reticulate::py_run_string("
import pystac, datetime
from pystac.extensions.raster import RasterExtension, RasterBand

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
asset = pystac.Asset(
    href='https://example.com/image.tif',
    media_type='image/tiff; application=geotiff',
    title='RGB Image'
)
py_item.add_asset('test', asset)
raster = RasterExtension.ext(asset, add_if_missing=True)
raster.bands = [RasterBand.create(nodata=0, sampling='point', spatial_resolution=10)]
py_raster_result = py_item.to_dict()
")

  py_json <- py_to_r_json(reticulate::py$py_raster_result)

  r_item <- make_r_item() |>
    add_asset("test", href = "https://example.com/image.tif",
              type = "image/tiff; application=geotiff", title = "RGB Image") |>
    add_raster_extension(
      bands    = list(raster_band(nodata = 0, sampling = "point", spatial_resolution = 10)),
      asset_key = "test"
    )
  r_json <- r_to_r_json(r_item)

  # bands on the asset (not item properties)
  expect_true("bands" %in% names(r_json$assets$test))
  expect_true(has_bands(py_json$assets$test))
  expect_null(r_json$properties$bands)

  r_band <- bands_of(r_json$assets$test)[[1]]
  py_band <- bands_of(py_json$assets$test)[[1]]

  # Values match regardless of the layout each library writes
  expect_equal(band_field(r_band, "nodata"), band_field(py_band, "nodata"))
  expect_equal(band_field(r_band, "sampling"), band_field(py_band, "sampling"))
  expect_equal(
    band_field(r_band, "spatial_resolution"),
    band_field(py_band, "spatial_resolution")
  )

  # Extension URI registered
  expect_true(any(grepl("stac-extensions.github.io/raster/", r_json$stac_extensions)))
  expect_true(any(grepl("stac-extensions.github.io/raster/", py_json$stac_extensions)))
})

test_that("add_raster_extension places bands on the asset it was given", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")

  reticulate::py_run_string("
import pystac, datetime
from pystac.extensions.raster import RasterExtension, RasterBand

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
py_asset = pystac.Asset(
    href='https://example.com/image.tif',
    title='RGB Image',
    media_type='image/tiff; application=geotiff',
)
py_item.add_asset('test', py_asset)

raster = RasterExtension.ext(py_asset, add_if_missing=True)
raster.bands = [RasterBand.create(data_type='uint16', nodata=0, spatial_resolution=30)]

py_raster_props_result = py_item.to_dict()
")

  py_json <- py_to_r_json(reticulate::py$py_raster_props_result)

  r_item <- make_r_item() |>
    add_asset("test", make_r_asset()) |>
    add_raster_extension(
      bands = list(
        raster_band(data_type = "uint16", nodata = 0, spatial_resolution = 30)
      ),
      asset_key = "test"
    )
  r_json <- r_to_r_json(r_item)

  expect_true("bands" %in% names(r_json$assets$test))
  expect_true(has_bands(py_json$assets$test))

  r_band <- bands_of(r_json$assets$test)[[1]]
  py_band <- bands_of(py_json$assets$test)[[1]]

  expect_equal(band_field(r_band, "nodata"), band_field(py_band, "nodata"))
  expect_equal(band_field(r_band, "data_type"), band_field(py_band, "data_type"))
  expect_equal(
    band_field(r_band, "spatial_resolution"),
    band_field(py_band, "spatial_resolution")
  )
})

# Combined EO + Raster -----------------------------------------------------

test_that("combined EO and raster extensions match pystac structure", {
  skip_if_not_installed("reticulate")
  reticulate::py_require("pystac")

  reticulate::py_run_string("
import pystac, datetime
from pystac.extensions.eo import EOExtension, Band
from pystac.extensions.raster import RasterExtension, RasterBand

dt = datetime.datetime(2023, 6, 15, 10, 30, 0, tzinfo=datetime.timezone.utc)
py_item = pystac.Item(
    id='ext-test',
    geometry={'type': 'Point', 'coordinates': [-105.0, 40.0]},
    bbox=[-105.0, 40.0, -105.0, 40.0],
    datetime=dt,
    properties={}
)
asset = pystac.Asset(
    href='https://example.com/image.tif',
    media_type='image/tiff; application=geotiff',
    title='RGB Image'
)
py_item.add_asset('test', asset)

eo = EOExtension.ext(py_item, add_if_missing=True)
eo.bands = [Band.create(name='wv3', center_wavelength=0.5)]

raster = RasterExtension.ext(asset, add_if_missing=True)
raster.bands = [RasterBand.create(nodata=0, sampling='point', spatial_resolution=10)]

py_combined_result = py_item.to_dict()
")

  py_json <- py_to_r_json(reticulate::py$py_combined_result)

  r_item <- make_r_item() |>
    add_asset("test", href = "https://example.com/image.tif",
              type = "image/tiff; application=geotiff", title = "RGB Image") |>
    add_eo_extension(
      bands = list(eo_band(name = "wv3", center_wavelength = 0.5))
    ) |>
    add_raster_extension(
      bands     = list(raster_band(nodata = 0, sampling = "point", spatial_resolution = 10)),
      asset_key = "test"
    )
  r_json <- r_to_r_json(r_item)

  # Both extensions registered
  expect_true(any(grepl("stac-extensions.github.io/eo/",     r_json$stac_extensions)))
  expect_true(any(grepl("stac-extensions.github.io/raster/", r_json$stac_extensions)))
  expect_true(any(grepl("stac-extensions.github.io/eo/",     py_json$stac_extensions)))
  expect_true(any(grepl("stac-extensions.github.io/raster/", py_json$stac_extensions)))

  # EO bands in item properties
  expect_true("bands" %in% names(r_json$properties))
  expect_true(has_bands(py_json$properties))
  expect_equal(
    band_field(bands_of(r_json$properties)[[1]], "center_wavelength"),
    band_field(bands_of(py_json$properties)[[1]], "center_wavelength")
  )

  # Raster bands on the asset
  expect_true("bands" %in% names(r_json$assets$test))
  expect_true(has_bands(py_json$assets$test))
  expect_equal(
    band_field(bands_of(r_json$assets$test)[[1]], "nodata"),
    band_field(bands_of(py_json$assets$test)[[1]], "nodata")
  )

  # The two calls target different places, so neither leaks into the other
  expect_null(band_field(bands_of(r_json$properties)[[1]], "nodata"))
  expect_null(band_field(bands_of(r_json$assets$test)[[1]], "center_wavelength"))
})
