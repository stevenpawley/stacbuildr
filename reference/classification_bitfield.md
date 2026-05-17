# Create a Classification Bitfield Object

Creates a bitfield object for use with the Classification Extension. A
bitfield describes a contiguous group of bits within an integer pixel
value, mapping the bit-encoded integer to a set of named classes.
Bitfields are used when a single raster band packs multiple independent
flags or categories into one integer (e.g., Landsat QA_PIXEL, Sentinel-2
SCL masks).

## Usage

``` r
classification_bitfield(
  offset,
  length,
  classes,
  name = NULL,
  description = NULL,
  roles = NULL
)
```

## Arguments

- offset:

  (integer, required) Zero-based bit position of the least significant
  bit of this bitfield. For example, `offset = 0` starts at bit 0 (the
  least significant bit).

- length:

  (integer, required) Number of bits that this bitfield spans. A
  single-bit flag has `length = 1`; a two-bit quality field has
  `length = 2` (representing values 0–3).

- classes:

  (list, required) A list of
  [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md)
  objects describing the possible values within this bitfield.

- name:

  (character, optional) Short machine-readable name for the bitfield
  (e.g., `"cloud"`, `"shadow"`). Same format rules as
  [`classification_class()`](https://stevenpawley.github.io/stacbuildr/reference/classification_class.md)
  name.

- description:

  (character, optional) Human-readable description of what this bitfield
  encodes.

- roles:

  (character vector, optional) Roles associated with the bitfield. Uses
  the same role vocabulary as STAC asset roles.

## Value

A named list representing a Classification bitfield object.

## Details

### Bit Extraction

To extract the value of a bitfield from a pixel value `x`, the operation
is:

    mask  <- (2^length - 1)
    bits  <- bitwAnd(bitwShiftR(x, offset), mask)

For example, bits 2–3 of a QA band (`offset = 2`, `length = 2`) are
extracted as `bitwAnd(bitwShiftR(x, 2), 3L)`.

## Examples

``` r
# Single-bit cloud flag (bit 3 of Landsat QA_PIXEL)
cloud_classes <- list(
  classification_class(value = 0, name = "not_cloud", title = "Not Cloud"),
  classification_class(value = 1, name = "cloud",     title = "Cloud")
)

cloud_bit <- classification_bitfield(
  offset = 3,
  length = 1,
  classes = cloud_classes,
  name = "cloud",
  description = "Cloud mask flag"
)

# Two-bit cloud confidence field (bits 8–9 of Landsat QA_PIXEL)
confidence_classes <- list(
  classification_class(value = 0, name = "none",   title = "No Confidence"),
  classification_class(value = 1, name = "low",    title = "Low Confidence"),
  classification_class(value = 2, name = "medium", title = "Medium Confidence"),
  classification_class(value = 3, name = "high",   title = "High Confidence")
)

confidence_bit <- classification_bitfield(
  offset = 8,
  length = 2,
  classes = confidence_classes,
  name = "cloud_confidence",
  description = "Cloud confidence level"
)
```
