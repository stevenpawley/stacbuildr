# Extract Spatial Metadata from Raster

Internal function to extract spatial metadata (geometry, bbox) from a
raster.

## Usage

``` r
extract_raster_spatial_metadata(r, reproject_to_wgs84 = TRUE)
```

## Arguments

- r:

  A SpatRaster object from terra.

- reproject_to_wgs84:

  If TRUE, reprojects to WGS84.

## Value

A list with geometry and bbox.
