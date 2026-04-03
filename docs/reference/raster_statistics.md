# Create Raster Statistics Object

Creates a statistics object for describing the distribution of pixel
values in a raster band.

## Usage

``` r
raster_statistics(
  minimum = NULL,
  maximum = NULL,
  mean = NULL,
  stddev = NULL,
  valid_percent = NULL
)
```

## Arguments

- minimum:

  (numeric, optional) Minimum pixel value in the band.

- maximum:

  (numeric, optional) Maximum pixel value in the band.

- mean:

  (numeric, optional) Mean (average) pixel value in the band.

- stddev:

  (numeric, optional) Standard deviation of pixel values.

- valid_percent:

  (numeric, optional) Percentage of valid (non-nodata) pixels. Should be
  between 0 and 100.

## Value

A list representing a statistics object.

## Examples

``` r
stats <- raster_statistics(
  minimum = 0,
  maximum = 10000,
  mean = 2500,
  stddev = 1200,
  valid_percent = 99.8
)
```
