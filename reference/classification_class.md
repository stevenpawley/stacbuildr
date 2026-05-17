# Create a Classification Class Object

Creates a class object for use with the Classification Extension. Each
class maps a single integer pixel value to a human- and machine-readable
category definition, with optional display hints such as a colour.

## Usage

``` r
classification_class(
  value,
  name = NULL,
  title = NULL,
  description = NULL,
  color_hint = NULL,
  nodata = NULL,
  percentage = NULL,
  count = NULL
)
```

## Arguments

- value:

  (integer, required) The pixel value that corresponds to this class.
  Must be an integer.

- name:

  (character, optional) Short machine-readable identifier for the class.
  Required as of Classification Extension v2.0. Must consist only of
  letters, numbers, hyphens (`-`), and underscores (`_`).

- title:

  (character, optional) Human-readable label for use in legends and user
  interfaces.

- description:

  (character, optional) Longer description of the class. CommonMark 0.29
  syntax may be used for rich text.

- color_hint:

  (character, optional) A six-character upper-case hexadecimal RGB
  colour string (e.g., `"FF0000"` for red) suggested for rendering this
  class in a map or legend.

- nodata:

  (logical, optional) If `TRUE`, marks this value as a no-data value
  that should be excluded from analysis.

- percentage:

  (numeric, optional) Percentage of pixels in the dataset that belong to
  this class (0–100).

- count:

  (integer, optional) Number of pixels that belong to this class.

## Value

A named list representing a Classification class object.

## Details

### Name Format

The `name` field is required in Classification Extension v2.0. It must
contain only letters, numbers, hyphens, and underscores. It is used for
machine-readable identification, while `title` provides the
human-readable label.

### Colour Hints

`color_hint` should be exactly six upper-case hexadecimal characters,
for example `"0000FF"` (blue), `"008000"` (green), or `"FF0000"` (red).
The value is a display suggestion only and does not affect data
interpretation.

## Examples

``` r
# Minimal class with just a value
cls <- classification_class(value = 1)

# Full class definition
cls <- classification_class(
  value = 2,
  name = "urban",
  title = "Urban / Built-up",
  description = "Impervious surfaces including roads, buildings, and parking.",
  color_hint = "FF0000",
  percentage = 12.4,
  count = 24800L
)

# No-data class
nodata_cls <- classification_class(value = 0, name = "nodata", nodata = TRUE)
```
