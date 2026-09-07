# Package index

## Overview

- [`stacbuildr-package`](https://stevenpawley.github.io/stacbuildr/reference/stacbuildr-package.md)
  [`stacbuildr`](https://stevenpawley.github.io/stacbuildr/reference/stacbuildr-package.md)
  : stacbuildr: Build SpatioTemporal Asset Catalogs (STAC) in R

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
- [`print(`*`<stac_asset>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.stac_asset.md)
  : Print method for STAC assets

## Links

Build and manage the link graph between STAC objects.

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  : Add a link to a STAC catalog
- [`add_self_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_self_link.md)
  : Add a self link to a STAC catalog
- [`add_root_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_root_link.md)
  : Add a root link to a STAC catalog
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
- [`add_item_assets()`](https://stevenpawley.github.io/stacbuildr/reference/add_item_assets.md)
  : Add Item Asset Definitions to a Collection
- [`print(`*`<stac_provider>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.stac_provider.md)
  : Print method for STAC providers
- [`print(`*`<stac_summaries>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.stac_summaries.md)
  : Print method for STAC summaries

## terra Integration

Create STAC Items and preview/thumbnails directly from `terra` raster
objects, and extract band metadata.

- [`item_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_terra.md)
  : Create a STAC Item from a Terra SpatRaster Object
- [`bands_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/bands_from_terra.md)
  : Extract Raster Band Metadata from a Terra SpatRaster
- [`preview_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/preview_from_terra.md)
  : Generate a Thumbnail PNG from a Terra SpatRaster Object

## sf Integration

Create STAC Items and thumbnails from `sf` vector objects.

- [`item_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_sf.md)
  : Create a STAC Item from an sf Object
- [`geometry_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/geometry_from_sf.md)
  : Convert sf Geometry to GeoJSON
- [`thumbnail_from_sf()`](https://stevenpawley.github.io/stacbuildr/reference/thumbnail_from_sf.md)
  : Generate a Thumbnail PNG from an sf Object

## lidR Integration

Create STAC Items from LAS/LAZ point clouds and `lidR` catalogues,
deriving point cloud and projection metadata from the file header.

- [`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md)
  : Create a STAC Item from a LAS/LAZ Point Cloud
- [`items_from_lascatalog()`](https://stevenpawley.github.io/stacbuildr/reference/items_from_lascatalog.md)
  : Create STAC Items from a LAScatalog
- [`schemas_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/schemas_from_lidr.md)
  : Build Point Cloud Schema Objects from a LAS Header

## Raster Extension

Add the STAC Raster Extension to Items and build per-band metadata
objects.

- [`add_raster_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_raster_extension.md)
  : Add Raster Extension to a STAC Item or Asset
- [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md)
  : Creates a band object for use with the Raster Extension. Describes
  the characteristics of a single raster band including data type,
  nodata values, scale/offset transforms, and statistics.
- [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md)
  : Create Raster Statistics Object
- [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md)
  : Create Raster Histogram Object
- [`band_from_file()`](https://stevenpawley.github.io/stacbuildr/reference/band_from_file.md)
  : Extract Raster Band Metadata from a File
- [`print(`*`<raster_statistics>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.raster_statistics.md)
  : Print method for raster statistics
- [`print(`*`<raster_histogram>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.raster_histogram.md)
  : Print method for raster histograms

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
- [`worldview3_bands()`](https://stevenpawley.github.io/stacbuildr/reference/worldview3_bands.md)
  : Create Standard WorldView-3 Bands
- [`skysat_bands()`](https://stevenpawley.github.io/stacbuildr/reference/skysat_bands.md)
  : Create Standard Planet SkySat Bands
- [`planetscope_bands()`](https://stevenpawley.github.io/stacbuildr/reference/planetscope_bands.md)
  : Create Standard PlanetScope Bands

## Classification Extension

Add the STAC Classification Extension to Items

- [`add_classification_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_classification_extension.md)
  : Add Classification Extension to a STAC Item
- [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md)
  : Create a Classification Class Object
- [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md)
  : Create a Classification Bitfield Object
- [`print(`*`<classification_class>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.classification_class.md)
  : Print method for classification_class objects
- [`print(`*`<classification_bitfield>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.classification_bitfield.md)
  : Print method for classification_bitfield objects

## Scientific Citation Extension

Add the STAC Scientific Citation Extension to Items, recording the DOI,
human-readable citation, and related publications for a dataset.

- [`add_scientific_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_scientific_extension.md)
  : Add Scientific Citation Extension to a STAC Item
- [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md)
  : Create a Scientific Publication Object
- [`print(`*`<scientific_publication>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.scientific_publication.md)
  : Print method for scientific_publication objects

## Table Extension

Add the STAC Table Extension to Items, describing tabular datasets
(e.g. GeoParquet) including columns, primary geometry, and row count.

- [`add_table_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_table_extension.md)
  : Add Table Extension to a STAC Item
- [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md)
  : Create a Table Column Object
- [`print(`*`<table_column>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.table_column.md)
  : Print method for table_column objects

## Vector Extension

Add the STAC Vector Extension to Items, describing geometry types and
mapping resolution (minimum mapping unit/width, reference scale) of
vector data.

- [`add_vector_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_vector_extension.md)
  : Add Vector Extension to a STAC Item

## Projection Extension

Add the STAC Projection Extension to Items, recording the native CRS,
grid shape and affine transform alongside the WGS84 geometry that STAC
itself requires.

- [`add_projection_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_projection_extension.md)
  : Add the Projection Extension to a STAC Item

## Point Cloud Extension

Add the STAC Point Cloud Extension to Items, describing point count,
phenomenology, per-dimension schemas, density, and per-channel
statistics of point cloud datasets.

- [`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md)
  : Add the Point Cloud Extension to a STAC Item
- [`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md)
  : Create a Point Cloud Schema Object
- [`pc_statistic()`](https://stevenpawley.github.io/stacbuildr/reference/pc_statistic.md)
  : Create a Point Cloud Statistics Object
- [`print(`*`<pc_schema>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.pc_schema.md)
  : Print method for pc_schema objects
- [`print(`*`<pc_statistic>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.pc_statistic.md)
  : Print method for pc_statistic objects

## Datacube Extension

Add the STAC Datacube Extension to Items, describing N-dimensional data
cube dimensions (spatial, temporal, geometry, or additional) and
variables.

- [`add_datacube_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_datacube_extension.md)
  : Add Datacube Extension to a STAC Item
- [`cube_dimension()`](https://stevenpawley.github.io/stacbuildr/reference/cube_dimension.md)
  : Create a Datacube Dimension Object
- [`cube_variable()`](https://stevenpawley.github.io/stacbuildr/reference/cube_variable.md)
  : Create a Datacube Variable Object
- [`print(`*`<cube_dimension>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.cube_dimension.md)
  : Print method for cube_dimension objects
- [`print(`*`<cube_variable>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.cube_variable.md)
  : Print method for cube_variable objects

## Render Extension

Add the STAC Render Extension to Items or Collections, describing
aspects of rendering behaviour of items or collections in terms of
colour ramps, nodata values, and band scaling.

- [`render_object()`](https://stevenpawley.github.io/stacbuildr/reference/render_object.md)
  : Create a STAC Render Object
- [`add_render_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_render_extension.md)
  : Add Render Extension to a STAC Item or Collection
- [`print(`*`<render_object>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.render_object.md)
  : Print method for render_object objects

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

## Working with Catalogs as Data

Coerce Catalogs, Collections and Items into the shapes R works in. A
catalog answers [`length()`](https://rdrr.io/r/base/length.html) with
its item count and subsets to its Items;
[`as.data.frame()`](https://rspatial.github.io/terra/reference/as.data.frame.html)
gives one row per Item and
[`st_as_sf()`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
the same table with footprints attached. The `sf` accessors work on an
Item directly.

- [`length(`*`<stac_catalog>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/length.stac_catalog.md)
  : Number of Items in a STAC Catalog or Collection
- [`as.data.frame(`*`<stac_catalog>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/as.data.frame.stac_catalog.md)
  [`as.data.frame(`*`<stac_item>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/as.data.frame.stac_catalog.md)
  : Coerce a STAC Catalog, Collection or Item to a Data Frame
- [`st_as_sf(`*`<stac_catalog>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/st_as_sf.stac_catalog.md)
  [`st_as_sf(`*`<stac_item>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/st_as_sf.stac_catalog.md)
  : Coerce a STAC Catalog, Collection or Item to an sf Object
- [`st_geometry(`*`<stac_item>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/stac_item_sf_accessors.md)
  [`st_bbox(`*`<stac_item>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/stac_item_sf_accessors.md)
  [`st_crs(`*`<stac_item>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/stac_item_sf_accessors.md)
  : sf Accessors for a STAC Item
- [`` `[`( ``*`<stac_catalog>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/sub-.stac_catalog.md)
  [`` `[[`( ``*`<stac_catalog>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/sub-.stac_catalog.md)
  : Extract Items from a STAC Catalog or Collection

## Validation

Validate STAC objects against the specification.
[`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md)
applies fast, offline structural checks.
[`validate_stac_schema()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac_schema.md)
validates against the official JSON Schemas hosted at
`schemas.stacspec.org` (requires network access and the `jsonvalidate`
package).

- [`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md)
  : Validate a STAC Object
- [`validate_stac_schema()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac_schema.md)
  : Validate a STAC Object Against the Official JSON Schema
- [`print(`*`<stac_validation>`*`)`](https://stevenpawley.github.io/stacbuildr/reference/print.stac_validation.md)
  : Print method for STAC validation results
