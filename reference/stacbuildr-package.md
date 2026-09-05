# stacbuildr: Build SpatioTemporal Asset Catalogs (STAC) in R

`stacbuildr` provides functions for constructing, validating, and
writing STAC Catalogs, Collections, and Items, including support for
common STAC extensions (Raster, EO, Classification, Scientific).

### Object Types

The package uses two kinds of objects: **S7 classes** for the core STAC
structures, and **plain lists** for lightweight sub-objects.

#### S7 Classes (use `@` to access properties)

The primary STAC document types, `raster_band` and the extent objects
are S7 objects. Use the `@` operator to read or modify their properties:

|  |  |  |
|----|----|----|
| Constructor | Class | Example access |
| [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md) | `stac_item` | `item@id`, `item@assets` |
| [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md) | `stac_catalog` | `catalog@title` |
| [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md) | `stac_collection` | `collection@description` |
| [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md) | `raster_band` | `band@data_type`, `band@scale` |
| [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md) | `Extent` | `extent@spatial`, `extent@temporal` |

Note that `stac_collection` extends `stac_catalog`, so a Collection
satisfies `inherits(x, "stac_catalog")` as well.

#### Classed Lists (use `$` to access fields)

The remaining constructors return ordinary R lists carrying an S3 class.
They are embedded inside S7 objects but are not S7 classes themselves.
The class exists so that each object prints as itself; fields are
reached with `$` as for any list, and the class is dropped on
serialisation so it never reaches the written JSON.

|  |  |  |
|----|----|----|
| Constructor | Class | Typically used in |
| [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md) | `stac_asset` | `item@assets` |
| [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md) | `raster_statistics` | `band@statistics` |
| [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md) | `raster_histogram` | `band@histogram` |
| [`eo_band()`](https://stevenpawley.github.io/stacbuildr/reference/eo_band.md) | `eo_band` | asset `"bands"` field |
| [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md) | `stac_provider` | `collection@providers` |
| [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md) | `stac_summaries` | `collection@summaries` |
| [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md) | `classification_class` | classification extension |
| [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md) | `classification_bitfield` | classification extension |
| [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md) | `scientific_publication` | scientific extension |
| [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md) | `table_column` | table extension |
| [`render_object()`](https://stevenpawley.github.io/stacbuildr/reference/render_object.md) | `render_object` | render extension |
| [`cube_dimension()`](https://stevenpawley.github.io/stacbuildr/reference/cube_dimension.md) | `cube_dimension` | datacube extension |
| [`cube_variable()`](https://stevenpawley.github.io/stacbuildr/reference/cube_variable.md) | `cube_variable` | datacube extension |

### Printing

Catalogs, Collections and Items print a coloured summary. Fields that
hold more than one value (assets, links, properties, children, items,
extensions, providers, summaries) are shown as collapsed sections marked
with a `▸` arrow, listing a count and a short preview. Expand them with
the `expand` argument:

    print(item)                          # everything collapsed
    print(item, expand = TRUE)           # expand every section
    print(item, expand = c("assets"))    # expand only the assets

Two options change the defaults:

- `stacbuildr.print.expand` - the default value of `expand`, e.g.
  `options(stacbuildr.print.expand = TRUE)` to always print in full.

- `stacbuildr.print.hint` - set to `FALSE` to suppress the footer that
  reports how many sections were collapsed.

Extension metadata is shown wherever it is stored: item-level fields
such as `"sci:doi"` or `"eo:cloud_cover"` appear in the `properties`
section, asset-level fields such as `"bands"` or
`"classification:classes"` appear under the asset that carries them, and
the declared schema URIs are listed in the `extensions` section by name
and version. Arrays of objects are summarised by the name of each
object, e.g. `bands [B4, B5]`.

Colour and the box-drawing characters come from cli and are dropped
automatically when the console does not support them (log files, knitr,
`R CMD check`). Use `options(cli.num_colors = 1)` to turn colour off.

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
