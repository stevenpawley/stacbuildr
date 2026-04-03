# Extract Spatial Metadata from a Stars Object

Internal function to extract spatial metadata (geometry, bbox) from a
stars object.

## Usage

``` r
extract_stars_spatial_metadata(stars_obj, reproject_to_wgs84 = TRUE)
```

## Arguments

- stars_obj:

  A stars object.

- reproject_to_wgs84:

  If TRUE, reprojects to WGS84.

## Value

A list with geometry and bbox.
