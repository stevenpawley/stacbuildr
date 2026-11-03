test_that("get_media_type maps known extensions", {
  expect_equal(get_media_type("a.tif"), "image/tiff; application=geotiff")
  expect_equal(get_media_type("a.tiff"), "image/tiff; application=geotiff")
  expect_equal(get_media_type("a.nc"), "application/x-netcdf")
  expect_equal(get_media_type("a.hdf"), "application/x-hdf")
  expect_equal(get_media_type("a.hdf5"), "application/x-hdf5")
  expect_equal(get_media_type("a.h5"), "application/x-hdf5")
  expect_equal(get_media_type("a.json"), "application/json")
  expect_equal(get_media_type("a.geojson"), "application/geo+json")
  expect_equal(get_media_type("a.shp"), "application/zipped-shapefile")
  expect_equal(get_media_type("a.png"), "image/png")
  expect_equal(get_media_type("a.jpg"), "image/jpeg")
  expect_equal(get_media_type("a.jpeg"), "image/jpeg")
  expect_equal(get_media_type("a.las"), "application/vnd.las")
  expect_equal(get_media_type("a.laz"), "application/vnd.laszip")
  expect_equal(get_media_type("a.copc.laz"), "application/vnd.laszip+copc")
})

test_that("get_media_type is case-insensitive and handles URLs", {
  expect_equal(get_media_type("A.NC"), "application/x-netcdf")
  expect_equal(
    get_media_type("https://example.com/data/a.geojson"),
    "application/geo+json"
  )
  expect_equal(
    get_media_type("https://example.com/data/a.nc?token=x"),
    "application/x-netcdf"
  )
})

test_that("get_media_type falls back to octet-stream for unknown extensions", {
  expect_equal(get_media_type("a.xyz"), "application/octet-stream")
  expect_equal(get_media_type("no_extension"), "application/octet-stream")
})

test_that("get_media_type marks remote GeoTIFFs as plain geotiff", {
  # is_cog() short-circuits for URLs, so no network request is made
  expect_equal(
    get_media_type("https://example.com/a.tif"),
    "image/tiff; application=geotiff"
  )
})
