# Package index

## Core STAC Objects

Create and manipulate the three fundamental STAC object types.

- [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  : Create a STAC Catalog
- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  : Create a STAC Collection
- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  : Create a STAC Item

## Assets

Create and attach data assets to STAC Items and Collections.

- [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md)
  : Create a STAC Asset
- [`add_asset()`](https://stevenpawley.github.io/stacbuildr/reference/add_asset.md)
  : Add an Asset to a STAC Item

## Links

Build and manage the link graph between STAC objects.

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  : Add a link to a STAC catalog
- [`add_self_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_self_link.md)
  : Add a self link to a STAC catalog
- [`add_root_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_root_link.md)
  : Add a root link to a STAC catalog
- [`add_parent_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_parent_link.md)
  : Add a parent link to a STAC catalog
- [`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
  : Add a child catalog or collection
- [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
  : Add an Item to a STAC Catalog or Collection
- [`get_children()`](https://stevenpawley.github.io/stacbuildr/reference/get_children.md)
  : Get Stored Children from Catalog
- [`get_items()`](https://stevenpawley.github.io/stacbuildr/reference/get_items.md)
  : Get Stored Items from Catalog or Collection
- [`get_item_links()`](https://stevenpawley.github.io/stacbuildr/reference/get_item_links.md)
  : Get All Item Links from a STAC Catalog or Collection
- [`count_items()`](https://stevenpawley.github.io/stacbuildr/reference/count_items.md)
  : Count Items in a STAC Catalog or Collection
- [`remove_item()`](https://stevenpawley.github.io/stacbuildr/reference/remove_item.md)
  : Remove Items from a STAC Catalog or Collection

## Collection Metadata Helpers

Helper constructors for Collection fields.

- [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md)
  : Create a STAC Extent Object
- [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md)
  : Create a STAC Provider Object
- [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md)
  : Create STAC Summaries
- [`extent_from_items()`](https://stevenpawley.github.io/stacbuildr/reference/extent_from_items.md)
  : Create Collection Extent from Multiple Items

## stars Integration

Create STAC Items and thumbnails directly from `stars` raster objects,
and extract band metadata.

- [`item_from_stars()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_stars.md)
  : Create a STAC Item from a Stars Object
- [`bands_from_stars()`](https://stevenpawley.github.io/stacbuildr/reference/bands_from_stars.md)
  : Extract Raster Band Metadata from a Stars Object
- [`items_from_directory()`](https://stevenpawley.github.io/stacbuildr/reference/items_from_directory.md)
  : Batch Create Items from Raster Files
- [`thumbnail_from_stars()`](https://stevenpawley.github.io/stacbuildr/reference/thumbnail_from_stars.md)
  : Generate a Thumbnail PNG from a Stars Raster Object

## terra Integration

Create STAC Items and thumbnails directly from `terra` `SpatRaster`
objects, and extract band metadata.

- [`item_from_spatraster()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_spatraster.md)
  : Create a STAC Item from a SpatRaster Object
- [`bands_from_spatraster()`](https://stevenpawley.github.io/stacbuildr/reference/bands_from_spatraster.md)
  : Extract Raster Band Metadata from a SpatRaster Object
- [`thumbnail_from_spatraster()`](https://stevenpawley.github.io/stacbuildr/reference/thumbnail_from_spatraster.md)
  : Generate a Thumbnail PNG from a SpatRaster Object

## sf Integration

Create STAC Items and thumbnails from `sf` vector objects.

- [`item_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_sf.md)
  : Create a STAC Item from an sf Object
- [`geometry_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/geometry_from_sf.md)
  : Convert sf Geometry to GeoJSON
- [`bbox_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/bbox_from_sf.md)
  : Calculate Bounding Box from sf Object
- [`thumbnail_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/thumbnail_from_sf.md)
  : Generate a Thumbnail PNG from an sf Object

## Raster Extension

Add the STAC Raster Extension to Items and build per-band metadata
objects.

- [`add_raster_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_raster_extension.md)
  : Add Raster Extension to a STAC Item or Asset
- [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md)
  : Create a Raster Band Object
- [`print(`*`<raster_band>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.raster_band.md)
  : Print method for raster band objects
- [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md)
  : Create Raster Statistics Object
- [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md)
  : Create Raster Histogram Object
- [`raster_from_file()`](https://stevenpawley.github.io/stacbuildr/reference/raster_from_file.md)
  : Extract Raster Band Metadata from a File

## EO Extension

Add the STAC Electro-Optical Extension to Items, with pre-built band
definitions for common sensors.

- [`add_eo_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_eo_extension.md)
  : Add EO Extension to a STAC Item
- [`eo_band()`](https://stevenpawley.github.io/stacbuildr/reference/eo_band.md)
  : Create an EO Band Object
- [`print(`*`<eo_band>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.eo_band.md)
  : Print method for EO band objects
- [`landsat_oli_bands()`](https://stevenpawley.github.io/stacbuildr/reference/landsat_oli_bands.md)
  : Create Standard Landsat 8/9 OLI Bands
- [`sentinel2_msi_bands()`](https://stevenpawley.github.io/stacbuildr/reference/sentinel2_msi_bands.md)
  : Create Standard Sentinel-2 MSI Bands

## Read / Write

Serialise STAC objects to JSON on disk and read them back.

- [`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
  : Write a STAC Catalog Structure to Disk
- [`write_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/write_catalog.md)
  : Write a Single STAC Catalog or Collection File
- [`write_item()`](https://stevenpawley.github.io/stacbuildr/reference/write_item.md)
  : Write a Single STAC Item File
- [`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)
  : Read a STAC Catalog from Disk

## Validation

Validate STAC objects against the specification.

- [`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md)
  : Validate a STAC Object
