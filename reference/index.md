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
- [`add_item_assets()`](https://stevenpawley.github.io/stacbuildr/reference/add_item_assets.md)
  : Add Item Asset Definitions to a Collection

## terra Integration

Create STAC Items and preview/thumbnails directly from `terra` raster
objects, and extract band metadata.

- [`item_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_terra.md)
  : Create a STAC Item from a Terra SpatRaster Object
- [`bands_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/bands_from_terra.md)
  : Extract Raster Band Metadata from a Terra SpatRaster
- [`items_from_directory()`](https://stevenpawley.github.io/stacbuildr/reference/items_from_directory.md)
  : Batch Create Items from Raster Files
- [`preview_from_terra()`](https://stevenpawley.github.io/stacbuildr/reference/preview_from_terra.md)
  : Generate a Thumbnail PNG from a Terra SpatRaster Object

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
  : Creates a band object for use with the Raster Extension. Describes
  the characteristics of a single raster band including data type,
  nodata values, scale/offset transforms, and statistics.
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

## Database Backend

Set up and manage a PostgreSQL/PostGIS database backing store for STAC
Collections and Items.

- [`stac_db_setup()`](https://stevenpawley.github.io/stacbuildr/reference/stac_db_setup.md)
  : Create the STAC database schema
- [`stac_db_insert_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_db_insert_collection.md)
  : Insert or update a STAC Collection in the database
- [`stac_db_insert_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_db_insert_item.md)
  : Insert or update a STAC Item in the database
- [`stac_db_delete_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_db_delete_collection.md)
  : Delete a STAC Collection and all its items from the database
- [`stac_db_delete_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_db_delete_item.md)
  : Delete a STAC Item from the database

## STAC API Server

Serve a STAC API 1.0 compliant HTTP API via `plumber`, backed by the
PostgreSQL database. Includes asset signing helpers for Azure Blob
Storage.

- [`stac_api_router()`](https://stevenpawley.github.io/stacbuildr/reference/stac_api_router.md)
  : Create a plumber router serving a minimal STAC API
- [`sign_azure_ad()`](https://stevenpawley.github.io/stacbuildr/reference/sign_azure_ad.md)
  : Sign an Azure Blob Storage href using Azure AD authentication.
- [`sign_aws_s3()`](https://stevenpawley.github.io/stacbuildr/reference/sign_aws_s3.md)
  : Sign an AWS S3 href using a presigned URL.
- [`sign_gcp()`](https://stevenpawley.github.io/stacbuildr/reference/sign_gcp.md)
  : Sign a Google Cloud Storage href using Application Default
  Credentials.
