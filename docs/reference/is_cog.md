# Check whether a local GeoTIFF is a Cloud Optimized GeoTIFF

Uses GDAL structural metadata to detect the COG layout flag. Returns
FALSE for remote URLs or files that cannot be read.

## Usage

``` r
is_cog(file)
```

## Arguments

- file:

  File path (local only; URLs return FALSE).

## Value

Logical scalar.
