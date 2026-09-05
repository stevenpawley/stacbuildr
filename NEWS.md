# stacbuildr 0.0.0.9000

First development cycle. The package has not been released, so everything below
is new, and breaking changes are still expected between commits.

## STAC API server moved to its own package

* The database backend and `plumber` router that served a STAC API now live in
  [stacserver](https://github.com/stevenpawley/stacserver). `stac_api_router()`,
  the `stac_db_*()` functions and the `sign_azure_ad()` / `sign_gcp()` /
  `sign_aws_s3()` asset signers moved there unchanged. stacbuildr builds and
  writes static catalogs; stacserver serves them.

* As a result stacbuildr no longer suggests `DBI`, `RPostgres`, `plumber`,
  `pool`, `httr2`, `AzureStor`, `AzureAuth`, `googleCloudStorageR` or
  `paws.storage`.

## Specification updates

* The EO and Raster extensions were migrated to v2.0.0. Both dropped their own
  band arrays in favour of the common `bands` array that STAC 1.1 defines, and
  moved their fields behind a prefix (`eo:common_name`, `raster:scale`). The
  arguments of `eo_band()` and `raster_band()` keep their short names, so only
  the serialised keys changed. Because both `add_eo_extension()` and
  `add_raster_extension()` now write to the same array, describing the same
  bands with each in turn merges their fields rather than overwriting.

* `proj:epsg` was replaced by `proj:code`, following v2.0.0 of the Projection
  extension. It is an `AUTHORITY:CODE` string, so codes from authorities other
  than EPSG (such as `OGC:CRS84`) are recorded as well.

* `add_item_assets()` no longer declares the `item-assets` extension URI on
  STAC 1.1.0 collections, where `item_assets` is part of the Collection spec
  itself. The URI is still declared for earlier STAC versions.

## Extensions

* `add_projection_extension()` is now exported. The Projection extension fields
  were previously reachable only through `item_from_terra()` and
  `item_from_lidr()`, so an Item built by hand had no way to record its CRS.
  It takes all eight v2.0.0 fields and, like the other extensions, an
  `asset_key` to place them on a single asset.

* Added the Point Cloud, Datacube, Table, Vector and Render extensions, with
  their supporting constructors (`pc_schema()`, `pc_statistic()`,
  `cube_dimension()`, `cube_variable()`, `table_column()`, `render_object()`).

* Added the Classification and Scientific Citation extensions, with
  `classification_class()`, `classification_bitfield()` and
  `scientific_publication()`.

* Added band presets for common sensors: `landsat_oli_bands()`,
  `sentinel2_msi_bands()`, `worldview3_bands()`, `skysat_bands()` and
  `planetscope_bands()`.

## Working with catalogs as data

* Catalogs and Collections now answer the generics an R user reaches for.
  `length()` returns the item count, and `[` and `[[` pull Items out by
  position or by `id`. Previously `length()` returned `1` for any catalog, a
  wrong answer rather than an error, and S7 objects could not be subset at all.

* `as.data.frame()` returns one row per Item — `id`, `collection`, `datetime`,
  then a column for every property. Items need not share properties; a field
  missing from an Item is `NA`. Properties holding vectors or objects
  (`proj:transform`, `bands`) become list columns.

* `sf::st_as_sf()` returns that same table with the Item footprints attached as
  a geometry column, in EPSG:4326. Both take `resolve = TRUE` to follow `item`
  links for a catalog read back with `read_stac()`, and warn rather than
  returning a silently empty table when Items are linked but not in memory.

* `sf::st_geometry()`, `sf::st_bbox()` and `sf::st_crs()` work on a
  `stac_item` directly, since an Item is a GeoJSON Feature.

## Integrations

* `item_from_lidr()` and `items_from_lascatalog()` create Items from LAS/LAZ
  point clouds, populating geometry, extent, projection and Point Cloud
  extension fields from the public header block alone.

* `item_from_terra()`, `band_from_file()` and `preview_from_terra()` build
  Items from rasters, and `item_from_sf()`, `geometry_from_sf()` and
  `thumbnail_from_sf()` from vector data.

## Writing and validation

* `write_stac()` gained a `catalog_type` argument aligned with the STAC
  best-practices layouts: `"self-contained"` (relative links throughout and no
  `self` link), `"relative"` (relative links plus an absolute `self` link on the
  root) and `"absolute"` (absolute links, for web hosting). These correspond to
  PySTAC's `SELF_CONTAINED`, `RELATIVE_PUBLISHED` and `ABSOLUTE_PUBLISHED`.

* `validate_stac()` runs offline structural checks; `validate_stac_schema()`
  validates serialised output against the published schemas at
  `schemas.stacspec.org`. Repeated errors produced by walking the schema are
  filtered out of the report.

* Errors, warnings and messages are raised through `cli`, and Catalogs,
  Collections, Items, extents, geometries and validation results all print as
  readable reports rather than S7 internals.

## Bug fixes

* `remove_item()` now drops the Item itself, not just its link. `write_stac()`
  rebuilds item links from the Items a catalog holds, so removing the link
  alone was undone on write: the removed Item was written to disk and relinked.
  It also left `length()` and `count_items()` disagreeing with `get_items()`,
  `as.data.frame()` and `[[`.

* Bounding boxes that cross the antimeridian are accepted rather than rejected
  as invalid.

* Adding a child or Item with an id that already exists is now an error.
  `write_stac()` names each file after the id, so the second would previously
  have overwritten the first while both links survived.

* Ids that cannot be used as directory names are rejected when writing.

* An Item's `collection` field and its `collection` link are kept in step.

* STAC fields that the specification types as arrays stay JSON arrays when they
  hold a single value, instead of collapsing to a scalar.

* Items with a datetime range keep a null `datetime` property, as the
  specification requires.

* The `sf` and `terra` paths compare CRS objects rather than EPSG codes, so a
  CRS with no EPSG code is handled correctly.

* `geometry_from_sf()` returns a bare geometry rather than a wrapped object.
