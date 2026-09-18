# stacbuildr: Build SpatioTemporal Asset Catalogs (STAC) in R

`stacbuildr` provides functions for constructing, validating, and
writing STAC Catalogs, Collections, and Items, including support for
common STAC extensions (Raster, EO, Classification, Scientific).

### Object Types

The package uses validated **S3 classes** for core STAC structures and
metadata helper objects.

#### S3 objects (use `$` to access fields)

The primary STAC document types and most extension helper objects are S3
objects backed by named lists. Use `$` to read or modify declared
fields:

|  |  |  |
|----|----|----|
| Constructor | Class | Example access |
| [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md) | `stac_asset` | `asset$href`, `asset$extra_fields` |
| [`stac_provider()`](https://stevenpawley.github.io/stacbuildr/reference/stac_provider.md) | `stac_provider` | `provider$name`, `provider$roles` |
| [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md) | `stac_item` | `item$id`, `item$assets` |
| [`stac_geometry()`](https://stevenpawley.github.io/stacbuildr/reference/stac_geometry.md) | `stac_geometry` | `geometry$type` |
| [`stac_link()`](https://stevenpawley.github.io/stacbuildr/reference/stac_link.md) | `stac_link` | `link$rel`, `link$href` |
| [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md) | `stac_catalog` | `catalog$title` |
| [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md) | `stac_collection` | `collection$description` |
| [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md) | `raster_band` | `band$data_type`, `band$scale` |
| [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md) | `raster_statistics` | `stats$minimum` |
| [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md) | `raster_histogram` | `hist$buckets` |
| [`eo_band()`](https://stevenpawley.github.io/stacbuildr/reference/eo_band.md) | `eo_band` | `band$common_name` |
| [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md) | `scientific_publication` | `publication$doi` |
| [`table_column()`](https://stevenpawley.github.io/stacbuildr/reference/table_column.md) | `table_column` | `column$name` |
| [`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md) | `pc_schema` | `schema$size` |
| [`pc_statistic()`](https://stevenpawley.github.io/stacbuildr/reference/pc_statistic.md) | `pc_statistic` | `statistic$minimum` |
| [`render_object()`](https://stevenpawley.github.io/stacbuildr/reference/render_object.md) | `render_object` | `render$assets` |
| [`cube_dimension()`](https://stevenpawley.github.io/stacbuildr/reference/cube_dimension.md) | `cube_dimension` | `dimension$axis` |
| [`cube_variable()`](https://stevenpawley.github.io/stacbuildr/reference/cube_variable.md) | `cube_variable` | `variable$dimensions` |
| [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md) | `classification_class` | `class$value` |
| [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md) | `classification_bitfield` | `bitfield$classes` |
| [`stac_summaries()`](https://stevenpawley.github.io/stacbuildr/reference/stac_summaries.md) | `stac_summaries` | `summaries$extra_fields` |
| [`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md) | `stac_validation` | `result$valid`, `result$errors` |
| [`stac_extent()`](https://stevenpawley.github.io/stacbuildr/reference/stac_extent.md) | `Extent` | `extent$spatial`, `extent$temporal` |

Note that `stac_collection` extends `stac_catalog`, so
`inherits(x, "stac_catalog")` is also true for a Collection.

#### Dictionaries (use `[[ ]]` to access entries)

STAC permits arbitrary keys in dictionaries such as an Item's
`properties` and `assets`, and an Asset's `extra_fields`. These
containers remain named lists. Use `[[ ]]` when the key is held in a
variable or is not a syntactic R name; `$` is also available for
ordinary literal names:

    item$properties[["datetime"]]
    item$assets[["B4"]]$href
    item$assets[["B4"]]$extra_fields[["bands"]]

Both access styles are idiomatic R: `$` is convenient for known names
and `[[ ]]` is the right choice for computed names.

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

    # 1. Create a STAC Item (validated S3 object)
    item <- stac_item(
      id       = "my-scene",
      geometry = list(type = "Point", coordinates = c(-105, 40)),
      bbox     = c(-105, 40, -105, 40),
      datetime = "2024-06-01T00:00:00Z"
    )

    # 2. Add an asset (S3 object embedded in the item)
    item <- add_asset(
      item,
      key   = "B4",
      href  = "https://example.com/B4.tif",
      type  = "image/tiff; application=geotiff",
      roles = "data"
    )

    # 3. Describe the band with the Raster extension
    band <- raster_band(
      data_type          = "uint16",
      nodata             = 0,
      scale              = 0.0001,
      spatial_resolution = 30,
      statistics         = raster_statistics(minimum = 1, maximum = 10000)
    )

    item <- add_raster_extension(item, bands = list(band), asset_key = "B4")

    # 4. Access known fields with $ and dynamic dictionary entries with [[ ]]
    item$id
    item$geometry$type
    item$assets[["B4"]]$href
    band$scale

    # 5. Write to disk
    write_item(item, "my-scene.json")

\[ \]: R:%20 \[ \]: R:%20 \["datetime"\]: R:%22datetime%22 \["B4"\]:
R:%22B4%22 \["B4"\]: R:%22B4%22 \["bands"\]: R:%22bands%22 \[ \]: R:%20
\[B4, B5\]: R:B4,%20B5 \[ \]: R:%20 \["B4"\]: R:%22B4%22

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
