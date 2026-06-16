pkgload::load_all()

catalog = stac_catalog(
  id = "my-catalog",
  description = "A catalog of satellite imagery for environmental monitoring",
  title = "Test catalog"
)

item = stac_item(
  id = "observation-001",
  geometry = list(
    type = "Point",
    coordinates = c(-105.0, 40.0)
  ),
  bbox = c(-105.0, 40.0, -105.0, 40.0),
  datetime = "2023-06-15T10:30:00Z"
)

jsonlite::toJSON(as.list(item), pretty = TRUE, auto_unbox = TRUE)

asset = stac_asset(
  href = "https://example.com/image.tif",
  title = "RGB Image",
  type = "image/tiff; application=geotiff"
)

jsonlite::toJSON(as.list(asset), pretty = TRUE, auto_unbox = TRUE)

item_with_bands = add_raster_extension(item, bands = raster_band(nodata = 0))
item_with_bands@properties
item_with_bands@assets

item_with_asset = add_asset(item, "test", asset)
jsonlite::toJSON(as.list(item_with_asset), pretty = TRUE, auto_unbox = TRUE)

item_asset_lvl_bands = item_with_asset |>
  add_raster_extension(
    bands = list(
      raster_band(nodata = 0, spatial_resolution = 10, sampling = "point")
      # raster_band(nodata = 0, spatial_resolution = 10, sampling = "point")
    ),
    asset_key = "test"
  )


jsonlite::toJSON(as.list(item_asset_lvl_bands), pretty = TRUE, auto_unbox = TRUE)
