# stacbuildr: Build SpatioTemporal Asset Catalogs (STAC) in R

`stacbuildr` provides functions for constructing, validating, and
writing STAC Catalogs, Collections, and Items, including support for
common STAC extensions (Raster, EO, Classification, Scientific).

### Object Types

The package uses two kinds of objects: **S7 classes** for the core STAC
structures, and **plain lists** for lightweight sub-objects.

#### S7 Classes (use `@` to access properties)

The primary STAC document types and `raster_band` are S7 objects. Use
the `@` operator to read or modify their properties:

|  |  |  |
|----|----|----|
| Constructor | Class | Example access |
| [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md) | `stac_item` | `item@id`, `item@assets` |
| [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md) | `stac_catalog` | `catalog@title` |
| [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md) | `stac_collection` | `collection@description` |
| [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md) | `raster_band` | `band@data_type`, `band@scale` |

#### Plain Lists (use `$` to access fields)

Helper constructors return ordinary R lists. These are embedded inside
S7 objects but are not S7 classes themselves:

|  |  |
|----|----|
| Constructor | Typically used in |
| [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md) | `item@assets` |
| [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md) | `band@statistics` |
| [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md) | `band@histogram` |
| [`eo_band()`](https://stevenpawley.github.io/stacbuildr/reference/eo_band.md) | asset `"eo:bands"` field |
| [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md) | `collection@providers` |
| [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md) | `collection@extent` |
| [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md) | `collection@summaries` |
| [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md) | classification extension |
| [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md) | classification extension |
| [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md) | scientific extension |

### Typical Workflow

    library(stacbuildr)

    # 1. Create a STAC Item (S7 object)
    item <- stac_item(
      id       = "my-scene",
      geometry = list(type = "Point", coordinates = c(-105, 40)),
      bbox     = c(-105, 40, -105, 40),
      datetime = "2024-06-01T00:00:00Z"
    )

    # 2. Add an asset (plain list embedded in the item)
    item <- add_asset(
      item,
      key   = "B4",
      href  = "https://example.com/B4.tif",
      type  = "image/tiff; application=geotiff",
      roles = "data"
    )

    # 3. Describe the band with the Raster extension (S7 raster_band)
    band <- raster_band(
      data_type          = "uint16",
      nodata             = 0,
      scale              = 0.0001,
      spatial_resolution = 30,
      statistics         = raster_statistics(minimum = 1, maximum = 10000)
    )

    item <- add_raster_extension(item, bands = list(band), asset_key = "B4")

    # 4. Access S7 properties with @
    item@id
    band@scale

    # 5. Write to disk
    write_item(item, "my-scene.json")

## References

STAC Specification: <https://stacspec.org>

## See also

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md),
  [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md),
  [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating STAC documents

- [`write_item()`](https://stevenpawley.github.io/stacbuildr/reference/write_item.md),
  [`write_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/write_catalog.md),
  [`write_stac()`](https://stevenpawley.github.io/stacbuildr/reference/write_stac.md)
  for writing to disk

- [`read_stac()`](https://stevenpawley.github.io/stacbuildr/reference/read_stac.md)
  for reading STAC JSON files

- [`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md)
  for validating against the STAC specification

## Author

**Maintainer**: Steven Pawley <dr.stevenpawley@gmail.com>

Authors:

- Steven Pawley <dr.stevenpawley@gmail.com>
