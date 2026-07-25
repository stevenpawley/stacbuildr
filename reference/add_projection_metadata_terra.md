# Add Projection Extension Metadata from a Terra SpatRaster

Adds projection extension metadata to a STAC Item for rasters not in
WGS84.

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
