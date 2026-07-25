# Extract Raster Band Metadata from a Terra SpatRaster

Extracts band metadata from a `SpatRaster` object. Creates band objects
with data type and spatial resolution, optionally calculating
statistics.

## Usage

``` r
bands_from_terra(terra_obj, calculate_statistics = FALSE, sample_size = 1000L)
```

## Arguments

- terra_obj:

  A `SpatRaster` object (from the `terra` package).

- calculate_statistics:

  (logical, optional) If TRUE, calculates min, max, mean, and standard
  deviation for each band. Default is FALSE.

- sample_size:

  (integer, optional) Number of pixels to sample per band when
  calculating statistics. Default is 1000 pixels.

## Value

A list of raster band objects, one per band.
