# Create a Datacube Dimension Object

Creates a dimension object for use with the Datacube Extension.
Describes a single dimension of an N-dimensional data cube, such as an
`x`/`y` spatial axis, a vertical axis, a temporal axis, a geometry
(vector data cube) dimension, or an additional custom dimension (e.g.
wavelength, pressure level).

## Usage

``` r
cube_dimension(
  type,
  extent = NULL,
  values = NULL,
  step = NULL,
  unit = NULL,
  reference_system = NULL,
  description = NULL,
  axis = NULL,
  axes = NULL,
  bbox = NULL,
  geometry_types = NULL,
  ...
)
```

## Arguments

- type:

  (character, required) The type of the dimension. One of `"spatial"`
  (horizontal x/y or vertical z axis), `"geometry"` (vector data cube
  dimension), `"temporal"`, or a custom string for an "additional"
  dimension (e.g. `"spectral"`, `"pressure"`). Custom values must not be
  `"spatial"` or `"geometry"`.

- extent:

  (numeric or character, optional/required) The extent of the dimension
  as `c(min, max)`. Required for horizontal spatial (`x`/`y`) and
  temporal dimensions. For vertical (`z`) and additional dimensions,
  either `extent` or `values` must be given. `NA` may be used for an
  open-ended bound.

- values:

  (numeric or character, optional) An explicit, potentially irregularly
  spaced, list of values in the dimension, used instead of or in
  addition to `extent`.

- step:

  (numeric or character, optional) The distance between two consecutive
  values, e.g. the spatial resolution or an ISO 8601 duration for a
  temporal dimension. `NULL`/absent means irregular spacing.

- unit:

  (character, optional) The unit of measurement for the values and
  extent.

- reference_system:

  (optional) The spatial (or other) reference system, e.g. an EPSG code,
  WKT2 string, or PROJJSON object. Applies to `"spatial"` and
  `"geometry"` dimensions. Defaults to EPSG:4326 per the spec if omitted
  for spatial dimensions.

- description:

  (character, optional) Detailed description of the dimension.
  CommonMark 0.29 syntax may be used for rich text representation.

- axis:

  (character, required for `type = "spatial"`) The axis of the spatial
  dimension: `"x"`, `"y"`, or `"z"`.

- axes:

  (character, optional) For `type = "geometry"` dimensions, the axes
  that the `bbox` and geometries are given in, e.g. `c("x", "y")`.
  Defaults to `c("x", "y")` per the spec if omitted.

- bbox:

  (numeric, required for `type = "geometry"`) The bounding box of the
  geometries as `c(xmin, ymin, xmax, ymax)` (or with a `z` axis).

- geometry_types:

  (character, optional) For `type = "geometry"` dimensions, the allowed
  GeoJSON geometry types (e.g. `"Point"`, `"Polygon"`).

- ...:

  Additional fields for the dimension object.

## Value

A named list of class `"cube_dimension"`.

## Details

### Dimension Types

- **Horizontal spatial** (`type = "spatial"`, `axis = "x"` or `"y"`):
  `extent` is required.

- **Vertical spatial** (`type = "spatial"`, `axis = "z"`): `extent` or
  `values` is required.

- **Geometry** (`type = "geometry"`): describes a vector data cube
  dimension; `bbox` is required.

- **Temporal** (`type = "temporal"`): `extent` is required, given as ISO
  8601 datetime strings (or `NA` for an open bound).

- **Additional** (any other `type`, e.g. `"spectral"`): a custom
  dimension such as wavelength or pressure level; `extent` or `values`
  is required.

## Examples

``` r
# Horizontal spatial dimensions
x_dim <- cube_dimension(
  type = "spatial", axis = "x", extent = c(-105.5, -104.5),
  reference_system = 4326
)
y_dim <- cube_dimension(
  type = "spatial", axis = "y", extent = c(39.5, 40.5),
  reference_system = 4326
)

# Temporal dimension
time_dim <- cube_dimension(
  type = "temporal",
  extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z"),
  step = "P1D"
)

# Additional dimension (e.g. spectral band index)
band_dim <- cube_dimension(
  type = "bands",
  values = c("B02", "B03", "B04", "B08")
)
```
