library(sf)

# Create a catalog with all fields
catalog <- stac_catalog(
  id = "north-america-imagery",
  title = "North America Satellite Imagery",
  description = "A comprehensive catalog of satellite imagery covering North America from various sensors including Landsat, Sentinel, and commercial providers.",
  stac_version = "1.1.0",
  stac_extensions = NULL
) |>
  add_self_link("https://example.com/catalog.json") |>
  add_root_link("https://example.com/catalog.json")

# Add child catalogs
catalog <- catalog |>
  add_child(
    landsat_catalog,
    href = "./landsat/catalog.json",
    title = "Landsat Imagery"
  ) |>
  add_child(
    sentinel_catalog,
    href = "./sentinel/catalog.json",
    title = "Sentinel Imagery"
  )

# Print as JSON
cat(jsonlite::toJSON(catalog, auto_unbox = TRUE, pretty = TRUE))

# ---------------
# Create a collection
collection <- stac_collection(
  id = "sentinel-2",
  description = "Sentinel-2 data",
  license = "proprietary",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(c("2015-06-27T00:00:00Z", NULL))
  )
) |>
  add_self_link("https://example.com/collections/sentinel-2.json")

# Create an item
my_polygon <- st_polygon(list(matrix(c(
  -105, 40,
  -104, 40,
  -104, 41,
  -105, 41,
  -105, 40
), ncol = 2, byrow = TRUE)))

my_geometry <- st_sfc(my_polygon)
my_bbox <- as.numeric(st_bbox(my_polygon))

item <- stac_item(
  id = "S2A_MSIL2A_20230101",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-01-01T10:30:00Z"
)

# Add item with proper bidirectional links
collection <- add_item(
  collection,
  item,
  add_parent_links = TRUE,
  parent_href = "./collection.json",
  root_href = "../catalog.json"
)

# The updated item is available as an attribute
updated_item <- attr(collection, "items")

# Check how many items
count_items(collection)  # Returns: 1

# View all item links
get_item_links(collection, as_dataframe = TRUE)

# -----------------
# Datetime flexibility
# Single datetime
item <- stac_item(
  id = "item1",
  geometry = geom,
  bbox = my_bbox,
  datetime = "2023-01-01T12:00:00Z"
)

# Time range
item <- stac_item(
  id = "composite",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = NULL,
  start_datetime = "2023-01-01T00:00:00Z",
  end_datetime = "2023-12-31T23:59:59Z"
)

# --------------
# Non-spatial items
# Both geometry and bbox can be NULL
item <- stac_item(
  id = "report",
  geometry = NULL,
  bbox = NULL,
  datetime = "2023-12-31T00:00:00Z"
)

# --------------
# Rich metadata
item <- stac_item(
  id = "LC08_001",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-01-01T17:30:00Z",
  properties = list(
    platform = "landsat-8",
    instruments = c("oli", "tirs"),
    gsd = 30
  ),
  # Additional properties via ...
  "eo:cloud_cover" = 12.5,
  constellation = "landsat"
)

# ---------------
# complete workflow
# Create STAC item
item <- stac_item(
  id = "sentinel-2-tile-001",
  geometry = my_geometry,
  bbox = st_bbox(my_geometry),
  datetime = "2023-06-15T10:30:00Z",
  properties = list(
    title = "Sentinel-2 L2A Tile",
    platform = "sentinel-2a",
    instruments = c("msi"),
    gsd = 10
  ),
  "eo:cloud_cover" = 5.2
) |>
  add_asset(
    "visual",
    href = "https://example.com/data/visual.tif",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("visual", "data")
  ) |>
  add_asset(
    "thumbnail",
    href = "https://example.com/data/thumbnail.png",
    type = "image/png",
    roles = c("thumbnail")
  )

# Add to collection
collection <- add_item(
  collection,
  item,
  add_parent_links = TRUE,
  parent_href = "./collection.json"
)

# -----------------
# Raster extension
# Create item
item <- stac_item(
  id = "S2A_MSIL2A_20230615",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-06-15T10:30:00Z",
  properties = list(
    platform = "sentinel-2a",
    instruments = c("msi")
  )
)

# Method 1: Extract from file automatically
bands <- raster_from_file(
  "~/Downloads/landsat_multiband.tif",
  calculate_statistics = TRUE,
  sample_size = 100000  # Sample for speed
)

item <- item |>
  add_asset(
    "visual",
    href = "data/S2A_20230615.tif",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("data")
  ) |>
  add_raster_extension(bands = bands, asset_key = "visual")

# Method 2: Create bands manually with full control
red_band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  unit = "1",  # Reflectance is unitless
  spatial_resolution = 10,
  scale = 0.0001,
  offset = -0.1,
  sampling = "area",
  bits_per_sample = 15,
  statistics = raster_statistics(
    minimum = 1,
    maximum = 10000,
    mean = 2500,
    stddev = 1200,
    valid_percent = 99.8
  ),
  # Add EO extension fields too
  "eo:common_name" = "red",
  "eo:center_wavelength" = 0.665,
  "eo:full_width_half_max" = 0.038
)

green_band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  unit = "1",
  spatial_resolution = 10,
  scale = 0.0001,
  offset = -0.1,
  "eo:common_name" = "green",
  "eo:center_wavelength" = 0.560
)

blue_band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  unit = "1",
  spatial_resolution = 10,
  scale = 0.0001,
  offset = -0.1,
  "eo:common_name" = "blue",
  "eo:center_wavelength" = 0.490
)

item <- item |>
  add_raster_extension(
    bands = list(red_band, green_band, blue_band),
    asset_key = "visual"
  )

# Convert to JSON
cat(jsonlite::toJSON(item, auto_unbox = TRUE, pretty = TRUE))

# ---------------
# eo extension
# Create a Landsat 8 item
item <- stac_item(
  id = "LC08_L2SP_044034_20230615",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-06-15T17:30:00Z",
  properties = list(
    platform = "landsat-8",
    instruments = c("oli", "tirs"),
    constellation = "landsat",
    gsd = 30
  )
)

# Method 1: Use predefined Landsat bands
item <- item |>
  add_asset(
    "multispectral",
    href = "https://example.com/LC08_multispectral.tif",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("data")
  ) |>
  add_eo_extension(
    bands = landsat_oli_bands(),
    cloud_cover = 5.2,
    asset_key = "multispectral"
  )

# Method 2: Create custom bands
red_band <- eo_band(
  name = "B4",
  common_name = "red",
  center_wavelength = 0.655,
  full_width_half_max = 0.04,
  description = "Red band (0.64-0.67 μm)"
)

nir_band <- eo_band(
  name = "B5",
  common_name = "nir",
  center_wavelength = 0.865,
  full_width_half_max = 0.03,
  description = "Near infrared band (0.85-0.88 μm)"
)

item <- item |>
  add_eo_extension(
    bands = list(red_band, nir_band),
    cloud_cover = 5.2
  )

# Method 3: Combine EO and Raster extensions
combined_bands <- lapply(landsat_oli_bands(), function(band) {
  # Add raster metadata to each band
  band$nodata <- 0
  band$data_type <- "uint16"
  band$unit <- "1"  # Reflectance is unitless
  band$`raster:spatial_resolution` <- 30
  band$`raster:scale` <- 0.0001
  band$`raster:offset` <- 0
  band
})

item <- item |>
  add_asset(
    "sr",
    href = "https://example.com/LC08_sr.tif",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("data", "reflectance")
  ) |>
  add_eo_extension(
    bands = combined_bands,
    cloud_cover = 5.2,
    snow_cover = 0,
    asset_key = "sr"
  )

# Sentinel-2 example
s2_item <- stac_item(
  id = "S2A_MSIL2A_20230615T103021",
  geometry = my_geometry,
  bbox = my_bbox,
  datetime = "2023-06-15T10:30:21Z",
  properties = list(
    platform = "sentinel-2a",
    instruments = c("msi"),
    constellation = "sentinel-2"
  )
) |>
  add_asset(
    "visual",
    href = "https://example.com/S2A_visual.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_eo_extension(
    bands = sentinel2_msi_bands(),
    cloud_cover = 12.5,
    asset_key = "visual"
  )

# Convert to JSON
cat(jsonlite::toJSON(item, auto_unbox = TRUE, pretty = TRUE))


# writing STAC -------
# Build catalog structure
catalog <- stac_catalog(
  id = "earth-observation",
  title = "Earth Observation Data",
  description = "Satellite imagery catalog"
)

collection <- stac_collection(
  id = "landsat-8",
  title = "Landsat 8",
  description = "Landsat 8 Level-2 Surface Reflectance",
  license = "CC0-1.0",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(c("2013-04-11T00:00:00Z", NULL))
  )
)

# Create items
item1 <- stac_item(
  id = "LC08_001",
  geometry = list(type = "Point", coordinates = c(-105, 40)),
  bbox = c(-105, 40, -105, 40),
  datetime = "2023-01-01T00:00:00Z"
) |>
  add_asset(
    "visual",
    href = "https://example.com/LC08_001.tif",
    type = "image/tiff",
    roles = c("data")
  )

item2 <- stac_item(
  id = "LC08_002",
  geometry = list(type = "Point", coordinates = c(-104, 39)),
  bbox = c(-104, 39, -104, 39),
  datetime = "2023-01-15T00:00:00Z"
)

# Add items to collection
collection <- add_item(collection, item1)
collection <- add_item(collection, item2)

# Add collection to catalog
catalog <- add_child(catalog, collection, href = "./landsat-8/collection.json")

# Method 1: Write with automatic structure
write_stac(catalog, "output/stac")

# Method 2: Write with explicit children and items
write_stac_complete(
  catalog,
  path = "output/stac",
  children = list(
    "landsat-8" = collection
  )
)

write_stac_complete(
  collection,
  path = "output/stac/landsat-8",
  items = list(item1, item2)
)

# Write for web serving
write_stac(
  catalog,
  "output/stac",
  catalog_type = "absolute",
  base_url = "https://mydata.com/stac",
  overwrite = TRUE
)

# Read back
catalog_read <- read_stac("output/stac/catalog.json")
item_read <- read_stac("output/stac/landsat-8/items/LC08_001.json")

# -----------
# linking assets
# ==============================================================================
# Complete STAC Package Usage Example
# ==============================================================================
# This example demonstrates the full workflow of creating and writing a STAC
# catalog with automatic child and item storage.

library(stacbuilder)

# ==============================================================================
# 1. Create Items
# ==============================================================================

# Create Item 1 - Landsat scene from January
item1 <- stac_item(
  id = "LC08_L2SP_044034_20230115",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5),
      c(-104.5, 39.5),
      c(-104.5, 40.5),
      c(-105.5, 40.5),
      c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-01-15T17:30:00Z",
  properties = list(
    title = "Landsat 8 Scene - January 2023",
    platform = "landsat-8",
    instruments = c("oli", "tirs"),
    gsd = 30,
    constellation = "landsat"
  )
) |>
  # Add assets
  add_asset(
    key = "SR_B4",
    href = "https://example.com/LC08_20230115_B4.tif",
    title = "Band 4 - Red",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("data", "reflectance")
  ) |>
  add_asset(
    key = "SR_B5",
    href = "https://example.com/LC08_20230115_B5.tif",
    title = "Band 5 - NIR",
    type = "image/tiff; application=geotiff; profile=cloud-optimized",
    roles = c("data", "reflectance")
  ) |>
  add_asset(
    key = "thumbnail",
    href = "https://example.com/LC08_20230115_thumb.png",
    type = "image/png",
    roles = c("thumbnail")
  )

# Add EO extension with bands
red_band <- eo_band(
  name = "B4",
  common_name = "red",
  center_wavelength = 0.655,
  full_width_half_max = 0.04,
  # Add raster metadata to the same band
  nodata = 0,
  data_type = "uint16",
  unit = "1",
  "raster:spatial_resolution" = 30,
  "raster:scale" = 0.0001,
  "raster:offset" = 0
)

nir_band <- eo_band(
  name = "B5",
  common_name = "nir",
  center_wavelength = 0.865,
  full_width_half_max = 0.03,
  nodata = 0,
  data_type = "uint16",
  unit = "1",
  "raster:spatial_resolution" = 30,
  "raster:scale" = 0.0001,
  "raster:offset" = 0
)

item1 <- item1 |>
  add_eo_extension(
    bands = list(red_band, nir_band),
    cloud_cover = 5.2
  )


# Create Item 2 - Landsat scene from February
item2 <- stac_item(
  id = "LC08_L2SP_044034_20230216",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5),
      c(-104.5, 39.5),
      c(-104.5, 40.5),
      c(-105.5, 40.5),
      c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-02-16T17:30:00Z",
  properties = list(
    title = "Landsat 8 Scene - February 2023",
    platform = "landsat-8",
    instruments = c("oli", "tirs"),
    gsd = 30,
    constellation = "landsat"
  )
) |>
  add_asset(
    key = "visual",
    href = "https://example.com/LC08_20230216_visual.tif",
    title = "True Color Image",
    type = "image/tiff; application=geotiff",
    roles = c("visual")
  ) |>
  add_eo_extension(
    bands = landsat_oli_bands(),  # Use pre-defined bands
    cloud_cover = 12.8
  )


# ==============================================================================
# 2. Create Collection
# ==============================================================================

collection_landsat <- stac_collection(
  id = "landsat-8-l2",
  title = "Landsat 8 Level-2 Surface Reflectance",
  description = paste(
    "Landsat 8 Level-2 science products consist of atmospherically corrected",
    "surface reflectance and land surface temperature derived from the",
    "Operational Land Imager (OLI) and Thermal Infrared Sensor (TIRS)."
  ),
  license = "CC0-1.0",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(c("2013-04-11T00:00:00Z", NULL))
  ),
  keywords = c("landsat", "usgs", "earth observation", "surface reflectance"),
  providers = list(
    stac_provider(
      name = "USGS",
      description = "United States Geological Survey",
      roles = c("producer", "licensor", "host"),
      url = "https://www.usgs.gov"
    )
  ),
  summaries = stac_summaries(
    platform = c("landsat-8"),
    instruments = c("oli", "tirs"),
    gsd = c(15, 30, 100),
    `eo:bands` = landsat_oli_bands()
  )
)

# Add items to collection - they are automatically stored!
collection_landsat <- collection_landsat |>
  add_item(item1) |>
  add_item(item2)

# Verify items were stored
stored_items <- get_items(collection_landsat)
cat(sprintf("Collection contains %d stored items\n", length(stored_items)))


# ==============================================================================
# 3. Create Another Collection (Sentinel-2)
# ==============================================================================

item3 <- stac_item(
  id = "S2A_MSIL2A_20230615T103021",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.0, 39.8),
      c(-104.8, 39.8),
      c(-104.8, 40.0),
      c(-105.0, 40.0),
      c(-105.0, 39.8)
    ))
  ),
  bbox = c(-105.0, 39.8, -104.8, 40.0),
  datetime = "2023-06-15T10:30:21Z",
  properties = list(
    title = "Sentinel-2A MSI Level-2A",
    platform = "sentinel-2a",
    instruments = c("msi"),
    gsd = 10,
    constellation = "sentinel-2"
  )
) |>
  add_asset(
    key = "visual",
    href = "https://example.com/S2A_visual.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_eo_extension(
    bands = sentinel2_msi_bands(),
    cloud_cover = 3.5
  )

collection_sentinel <- stac_collection(
  id = "sentinel-2-l2a",
  title = "Sentinel-2 Level-2A",
  description = "Sentinel-2 Level-2A Bottom-Of-Atmosphere reflectance",
  license = "proprietary",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(c("2015-06-27T00:00:00Z", NULL))
  ),
  keywords = c("sentinel", "esa", "copernicus", "msi"),
  providers = list(
    stac_provider(
      name = "ESA",
      roles = c("producer", "licensor"),
      url = "https://earth.esa.int"
    )
  )
) |>
  add_item(item3)


# ==============================================================================
# 4. Create Root Catalog
# ==============================================================================

catalog <- stac_catalog(
  id = "earth-observation-catalog",
  title = "Earth Observation Data Catalog",
  description = paste(
    "A comprehensive catalog of satellite imagery from multiple sensors",
    "including Landsat and Sentinel missions."
  )
)

# Add collections as children - they are automatically stored!
catalog <- catalog |>
  add_child(collection_landsat) |>
  add_child(collection_sentinel)

# Verify children were stored
stored_children <- get_children(catalog)
cat(sprintf("Catalog contains %d stored children\n", length(stored_children)))
cat(sprintf("Child IDs: %s\n", paste(names(stored_children), collapse = ", ")))


# ==============================================================================
# 5. Write the Entire Catalog Structure
# ==============================================================================

# Option 1: Self-contained catalog (most portable)
write_stac(
  catalog,
  path = "output/stac",
  catalog_type = "self-contained",
  overwrite = TRUE
)

# This creates:
# output/stac/
#   catalog.json
#   landsat-8-l2/
#     collection.json
#     items/
#       LC08_L2SP_044034_20230115.json
#       LC08_L2SP_044034_20230216.json
#   sentinel-2-l2a/
#     collection.json
#     items/
#       S2A_MSIL2A_20230615T103021.json


# Option 2: Absolute catalog for web serving
write_stac(
  catalog,
  path = "output/stac-web",
  catalog_type = "absolute",
  base_url = "https://mydata.com/stac",
  overwrite = TRUE
)


# ==============================================================================
# 6. Read and Verify
# ==============================================================================

# Read the catalog back
catalog_read <- read_stac("output/stac/catalog.json")

cat("\nCatalog read successfully!\n")
cat(sprintf("ID: %s\n", catalog_read$id))
cat(sprintf("Title: %s\n", catalog_read$title))
cat(sprintf("Number of child links: %d\n", 
            sum(sapply(catalog_read$links, function(x) x$rel == "child"))))

# Read a collection
collection_read <- read_stac("output/stac/landsat-8-l2/collection.json")
cat(sprintf("\nCollection: %s\n", collection_read$title))
cat(sprintf("Number of item links: %d\n",
            sum(sapply(collection_read$links, function(x) x$rel == "item"))))

# Read an item
item_read <- read_stac("output/stac/landsat-8-l2/items/LC08_L2SP_044034_20230115.json")
cat(sprintf("\nItem: %s\n", item_read$properties$title))
cat(sprintf("Cloud cover: %.1f%%\n", item_read$properties$`eo:cloud_cover`))


# ==============================================================================
# 7. Individual File Writing (Alternative Approach)
# ==============================================================================

# You can also write individual files if you prefer more control
write_catalog(catalog, "output/manual/catalog.json", overwrite = TRUE)
write_catalog(collection_landsat, "output/manual/landsat/collection.json", overwrite = TRUE)
write_item(item1, "output/manual/landsat/items/item1.json", overwrite = TRUE)


# ==============================================================================
# 8. Summary
# ==============================================================================

cat("\n=== Summary ===\n")
cat("✓ Created 3 items with assets and extensions\n")
cat("✓ Created 2 collections with metadata\n")
cat("✓ Created 1 root catalog\n")
cat("✓ Added items to collections (automatically stored)\n")
cat("✓ Added collections to catalog (automatically stored)\n")
cat("✓ Wrote entire structure with single write_stac() call\n")
cat("✓ All links automatically updated for filesystem structure\n")
cat("\nThe catalog is ready to be served or shared!\n")

# -----------
# spatial integration
# ==============================================================================
# Example 1: Single raster file
# ==============================================================================

# Create item from a GeoTIFF
item <- item_from_raster(
  file = "data/LC08_L2SP_044034_20230615.tif",
  id = "LC08_044034_20230615",
  datetime = "2023-06-15T17:30:00Z",
  properties = list(
    title = "Landsat 8 Scene",
    platform = "landsat-8",
    instruments = c("oli", "tirs"),
    gsd = 30
  ),
  add_raster_bands = TRUE,
  calculate_statistics = TRUE
)

# The item now has:
# - Geometry (reprojected to WGS84)
# - Bbox (in WGS84)
# - Asset pointing to the file
# - Raster extension with band metadata
# - Projection extension (if not WGS84)


# ==============================================================================
# Example 2: Batch processing
# ==============================================================================

# Create items for all TIFFs in a directory
extract_datetime <- function(filename) {
  # Extract date from "LC08_L2SP_044034_20230615_..." pattern
  date_str <- sub(".*_(\\d{8})_.*", "\\1", filename)
  sprintf(
    "%s-%s-%sT17:30:00Z",
    substr(date_str, 1, 4),
    substr(date_str, 5, 6),
    substr(date_str, 7, 8)
  )
}

items <- items_from_directory(
  directory = "data/landsat",
  pattern = "^LC08.*\\.tif$",
  datetime_from_filename = extract_datetime,
  properties = list(
    platform = "landsat-8",
    instruments = c("oli", "tirs")
  ),
  add_raster_bands = TRUE
)


# ==============================================================================
# Example 3: Create collection from items
# ==============================================================================

# Calculate extent from all items
extent <- extent_from_items(items)

# Create collection
collection <- stac_collection(
  id = "landsat-8-colorado",
  title = "Landsat 8 Colorado Scenes",
  description = "Landsat 8 Level-2 surface reflectance over Colorado",
  license = "CC0-1.0",
  extent = extent,
  keywords = c("landsat", "colorado", "surface reflectance"),
  providers = list(
    stac_provider(
      name = "USGS",
      roles = c("producer", "licensor"),
      url = "https://www.usgs.gov"
    )
  )
)

# Add all items to collection
for (item in items) {
  collection <- add_item(collection, item)
}

# Write to disk
write_stac(collection, "output/stac")


# ==============================================================================
# Example 4: Vector data (sf objects)
# ==============================================================================

library(sf)

# Read a study area boundary
boundary <- st_read("study_area.shp")

# Create STAC item from the boundary
boundary_item <- item_from_sf(
  boundary,
  id = "study-area-boundary",
  datetime = "2023-01-01T00:00:00Z",
  properties = list(
    title = "Study Area Boundary",
    description = "Polygon defining the study area extent"
  ),
  asset_href = "study_area.shp"
)


# ==============================================================================
# Example 5: Raster with custom CRS (e.g., UTM)
# ==============================================================================

# Raster in UTM Zone 13N
item_utm <- item_from_raster(
  file = "data/dem_utm13n.tif",
  id = "dem-colorado",
  datetime = "2023-01-01T00:00:00Z",
  properties = list(
    title = "Digital Elevation Model"
  ),
  reproject_to_wgs84 = TRUE  # Geometry/bbox will be in WGS84
)

# The item will have:
# - Geometry and bbox in WGS84 (for STAC compliance)
# - Projection extension with original UTM CRS info
# - proj:epsg, proj:wkt2, proj:shape, proj:transform fields


# ==============================================================================
# Example 6: Complete catalog from directory
# ==============================================================================

# Process all Sentinel-2 scenes
s2_items <- items_from_directory(
  "data/sentinel2",
  pattern = "^S2._MSIL2A.*\\.tif$",
  datetime_from_filename = function(f) {
    # Extract from S2A_MSIL2A_20230615T103021_...
    date_part <- sub(".*_(\\d{8})T(\\d{6})_.*", "\\1T\\2", f)
    paste0(
      substr(date_part, 1, 4), "-",
      substr(date_part, 5, 6), "-",
      substr(date_part, 7, 8), "T",
      substr(date_part, 10, 11), ":",
      substr(date_part, 12, 13), ":",
      substr(date_part, 14, 15), "Z"
    )
  },
  properties = list(
    platform = "sentinel-2a",
    instruments = c("msi"),
    constellation = "sentinel-2"
  ),
  calculate_statistics = FALSE  # Faster
)

# Create collection
s2_collection <- stac_collection(
  id = "sentinel-2-colorado",
  title = "Sentinel-2 Colorado",
  description = "Sentinel-2 Level-2A imagery over Colorado",
  license = "proprietary",
  extent = extent_from_items(s2_items)
)

# Add items
for (item in s2_items) {
  s2_collection <- add_item(s2_collection, item)
}

# Create root catalog
catalog <- stac_catalog(
  id = "colorado-eo-data",
  title = "Colorado Earth Observation Data",
  description = "Multi-sensor Earth observation data for Colorado"
) |>
  add_child(collection) |>
  add_child(s2_collection)

# Write everything
write_stac(catalog, "output/colorado-stac", overwrite = TRUE)

