# Add Projection Extension Metadata from a Stars Object

Adds projection extension metadata to a STAC Item for rasters not in
WGS84.

## Usage

``` r
add_projection_metadata_stars(item, stars_obj, asset_key)
```

## Arguments

- item:

  A STAC Item object.

- stars_obj:

  A stars object.

- asset_key:

  The asset key to add projection metadata to.

## Value

The modified STAC Item.
