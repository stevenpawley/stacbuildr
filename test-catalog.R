library(here)
library(stars)
library(lubridate)

devtools::load_all()

catalog <- stac_catalog(
  id="homelab",
  description="Spatiotemporal Asset Catalog for open source homelab datasets",
  title="HomeLab STAC Catalog",
)

tif_path <- "/Users/stevenpawley/Data/terrain/alos.tif"
r <- read_stars(tif_path)

item <- r |> 
  item_from_stars(
    id = "alos-dem", 
    datetime = format_ISO8601(now(), usetz = "Z")
  ) |> 
  add_asset(
    "dem",
    href = tif_path,
    title = "Digital Elevation Model (DEM)",
    description = "Gridded Digital Elevation Model (DEM)",
    type = "image/tiff; application=geotiff; profile=cloud-optimized", 
    roles = "data"
  )

collection <- stac_collection(
  id = "ALOS",
  description = "Advanced Land Observing Satellite (ALOS)",
  title = "ALOS Collection",
  license = "CC-BY-SA-4.0",
  extent = stac_extent(
    spatial_bbox = list(as.numeric(st_bbox(r))),
    temporal_interval = list(list("2016-07-12T00:00:00Z", NULL))
    
  )
)

collection <- add_item(collection, item)
catalog <- add_child(catalog, collection)

write_stac(
  catalog,
  "~/Data/catalog",
  catalog_type = "self-contained",
  overwrite = TRUE
)
