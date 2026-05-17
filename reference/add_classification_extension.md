# Add Classification Extension to a STAC Item

Adds the Classification Extension to a STAC Item. The Classification
Extension defines how pixel values in a raster asset map to named
categories (thematic classes) or to bit-encoded values (bitfields). It
supports two mutually exclusive modes:

- **Classes** (`classification:classes`): A list of class objects, each
  mapping an integer pixel value to a name, description, and optional
  display properties. Suitable for thematic maps like land cover or QA
  flags represented as discrete values.

- **Bitfields** (`classification:bitfields`): A list of bitfield
  objects, each describing a group of bits within an integer pixel
  value. Each bitfield carries its own list of class objects. Suitable
  for packed QA / mask bands where multiple flags are stored in a single
  integer (e.g., Landsat QA_PIXEL).

Only one of `classes` or `bitfields` should be provided. If both are
supplied the function will error.

## Usage

``` r
add_classification_extension(
  item,
  classes = NULL,
  bitfields = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- classes:

  (list, optional) A list of class objects created with
  [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md).
  Use this for simple thematic classifications where each integer pixel
  value maps to a named category.

- bitfields:

  (list, optional) A list of bitfield objects created with
  [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md).
  Use this for packed bitmask bands where multiple classification flags
  are encoded within a single integer value.

- asset_key:

  (character, optional) If provided, attaches the classification
  metadata to a specific asset rather than to the item-level properties.
  The asset must already exist in the item.

## Value

The modified STAC Item with Classification extension fields added.

## Details

### Extension Schema URI

`https://stac-extensions.github.io/classification/v2.0.0/schema.json`

### Classes vs Bitfields

Use `classes` when each pixel value unambiguously identifies one
category (e.g., 1 = Water, 2 = Urban, 3 = Forest). Use `bitfields` when
pixel values are bitmasks where individual bits or groups of bits carry
independent meaning (e.g., Landsat CFMask QA band).

### Placement

The classification fields are typically placed on the asset that
contains the classified raster (via `asset_key`). They can also be
placed on item properties when the classification applies to the whole
item or when the extension is used in collection-level item asset
definitions.

## References

Classification Extension Specification:
<https://github.com/stac-extensions/classification>

## See also

- [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md)
  for creating class objects

- [`classification_bitfield()`](https://stevenpawley.github.io/stacbuildr/reference/classification_bitfield.md)
  for creating bitfield objects

- [`add_raster_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_raster_extension.md)
  for adding raster metadata

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

## Examples

``` r
# Create an item representing a land cover map
item <- stac_item(
  id = "lc-2023",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-01-01T00:00:00Z"
)

# Define land cover classes
classes <- list(
  classification_class(value = 1, name = "water",  title = "Water",  color_hint = "0000FF"),
  classification_class(value = 2, name = "urban",  title = "Urban",  color_hint = "FF0000"),
  classification_class(value = 3, name = "forest", title = "Forest", color_hint = "00FF00"),
  classification_class(value = 0, name = "nodata", nodata = TRUE)
)

# Add classification to an asset
item <- item |>
  add_asset(
    key = "landcover",
    href = "https://example.com/lc-2023.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_classification_extension(classes = classes, asset_key = "landcover")

# Bitfield example: Landsat-style QA band
qa_classes <- list(
  classification_class(value = 0, name = "no_fill", title = "No Fill"),
  classification_class(value = 1, name = "fill",    title = "Fill")
)

qa_bitfields <- list(
  classification_bitfield(
    offset = 0,
    length = 1,
    classes = qa_classes,
    name = "fill",
    description = "Image or fill data"
  )
)

item <- item |>
  add_asset(
    key = "qa_pixel",
    href = "https://example.com/qa_pixel.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_classification_extension(bitfields = qa_bitfields, asset_key = "qa_pixel")
```
