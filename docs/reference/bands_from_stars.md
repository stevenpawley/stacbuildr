# Extract Raster Band Metadata from a Stars Object

Extracts band metadata from a `stars` object. Creates band objects with
data type and spatial resolution, optionally calculating statistics.

## Usage

``` r
bands_from_stars(stars_obj, calculate_statistics = FALSE, sample_size = NULL)
```

## Arguments

- stars_obj:

  A `stars` object.

- calculate_statistics:

  (logical, optional) If TRUE, calculates min, max, mean, and standard
  deviation for each band. Default is FALSE.

- sample_size:

  (integer, optional) Number of pixels to sample per band when
  calculating statistics. If NULL, all pixels are used.

## Value

A list of raster band objects, one per band.
