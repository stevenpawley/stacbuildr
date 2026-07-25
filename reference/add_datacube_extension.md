# Add Datacube Extension to a STAC Item

Adds the Datacube Extension to a STAC Item. The Datacube Extension
describes N-dimensional data cubes (e.g. NetCDF, Zarr, multi-band raster
stacks) by specifying the dimensions of the cube (spatial, temporal, or
additional custom dimensions) and, optionally, the variables it
contains.

## Usage

``` r
add_datacube_extension(
  item,
  dimensions = NULL,
  variables = NULL,
  asset_key = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- dimensions:

  (named list, optional) A named list of dimension objects created with
  [`cube_dimension()`](https://stevenpawley.github.io/stacbuildr/reference/cube_dimension.md).
  Names are used as the dimension keys (e.g. `"x"`, `"y"`, `"time"`) and
  must be unique.

- variables:

  (named list, optional) A named list of variable objects created with
  [`cube_variable()`](https://stevenpawley.github.io/stacbuildr/reference/cube_variable.md).
  Names are used as the variable keys and must be unique, and must not
  clash with any name used in `dimensions`.

- asset_key:

  (character, optional) If provided, adds the datacube fields to a
  specific asset rather than to the item properties. Useful when
  different assets within an item (e.g. separate NetCDF files) describe
  different data cubes.

## Value

The modified STAC Item with Datacube extension fields added.

## Details

### Extension Schema URI

The Datacube Extension v2.3.0 schema URI is:
`https://stac-extensions.github.io/datacube/v2.3.0/schema.json`

### Field Placement

`cube:dimensions` and `cube:variables` may be placed either on item
properties (the default) or on a specific asset via `asset_key`.

### Key Uniqueness

The keys of `dimensions` and `variables` should be unique together; a
key such as `"lat"` should not be used for both a dimension and a
variable.

## References

Datacube Extension Specification:
<https://github.com/stac-extensions/datacube>

## See also

- [`cube_dimension()`](https://stevenpawley.github.io/stacbuildr/reference/cube_dimension.md)
  for creating dimension objects

- [`cube_variable()`](https://stevenpawley.github.io/stacbuildr/reference/cube_variable.md)
  for creating variable objects

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

## Examples

``` r
item <- stac_item(
  id = "my-datacube",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-06-15T00:00:00Z"
)

dims <- list(
  x = cube_dimension(
    type = "spatial", axis = "x", extent = c(-105.5, -104.5),
    reference_system = 4326
  ),
  y = cube_dimension(
    type = "spatial", axis = "y", extent = c(39.5, 40.5),
    reference_system = 4326
  ),
  time = cube_dimension(
    type = "temporal",
    extent = c("2023-06-01T00:00:00Z", "2023-06-30T00:00:00Z")
  )
)

vars <- list(
  temperature = cube_variable(
    type = "data",
    dimensions = c("x", "y", "time"),
    unit = "degC",
    data_type = "float32"
  )
)

item <- item |>
  add_datacube_extension(dimensions = dims, variables = vars)
```
