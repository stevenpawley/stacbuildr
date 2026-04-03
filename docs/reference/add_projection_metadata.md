# Add Projection Extension Metadata

Adds projection extension metadata to a STAC Item for rasters not in
WGS84.

## Usage

``` r
add_projection_metadata(item, r, asset_key)
```

## Arguments

- item:

  A STAC Item object.

- r:

  A SpatRaster object.

- asset_key:

  The asset key to add projection metadata to.

## Value

The modified STAC Item.
