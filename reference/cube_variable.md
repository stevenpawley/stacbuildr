# Create a Datacube Variable Object

Creates a variable object for use with the Datacube Extension. Describes
a single variable stored in an N-dimensional data cube (e.g. a NetCDF
variable such as `temperature` or `precipitation`), including the
dimensions it varies over.

## Usage

``` r
cube_variable(
  type,
  dimensions = character(0),
  extent = NULL,
  values = NULL,
  unit = NULL,
  nodata = NULL,
  data_type = NULL,
  description = NULL,
  ...
)
```

## Arguments

- type:

  (character, required) The type of the variable: `"data"` for the
  primary data variable(s) or `"auxiliary"` for supporting variables
  (e.g. quality flags, coordinate variables).

- dimensions:

  (character, required) A character vector of dimension keys (matching
  names used in `dimensions` passed to
  [`add_datacube_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_datacube_extension.md))
  that this variable varies over. Use `character(0)` for a scalar
  variable with no dimensions.

- extent:

  (optional) The extent of the values of the variable, as `c(min, max)`.

- values:

  (optional) An explicit list of values, e.g. for variables with a small
  number of distinct values.

- unit:

  (character, optional) The unit of measurement for the values.

- nodata:

  (optional) The no-data value(s) for the variable.

- data_type:

  (character, optional) The data type of the variable, e.g. `"float32"`,
  `"int16"`.

- description:

  (character, optional) Detailed description of the variable. CommonMark
  0.29 syntax may be used for rich text representation.

- ...:

  Additional fields for the variable object.

## Value

A named list of class `"cube_variable"`.

## Examples

``` r
temperature <- cube_variable(
  type = "data",
  dimensions = c("x", "y", "time"),
  unit = "degC",
  data_type = "float32"
)

quality_flag <- cube_variable(
  type = "auxiliary",
  dimensions = c("x", "y", "time"),
  data_type = "uint8"
)
```
