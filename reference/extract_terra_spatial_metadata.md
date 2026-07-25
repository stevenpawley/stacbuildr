# Extract Spatial Metadata from a Terra SpatRaster

Internal function to extract spatial metadata (geometry, bbox) from a
`SpatRaster` object.

## Usage

``` r
extract_terra_spatial_metadata(terra_obj, reproject_to_wgs84 = TRUE)
```

## Arguments

- terra_obj:

  A `SpatRaster` object.

- reproject_to_wgs84:

  If TRUE, reprojects to WGS84.

## Value

A list with geometry and bbox.
