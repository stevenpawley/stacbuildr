# Add Projection Extension Metadata from a Terra SpatRaster

Reads the CRS and grid geometry from a `SpatRaster` and hands them to
[`add_projection_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_projection_extension.md).

## Usage

``` r
add_projection_metadata_terra(item, terra_obj)
```

## Arguments

- item:

  A STAC Item object.

- terra_obj:

  A `SpatRaster` object.

## Value

The modified STAC Item.
