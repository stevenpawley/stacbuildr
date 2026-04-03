# Create Raster Histogram Object

Creates a histogram object describing the distribution of pixel values
in a raster band. The histogram format follows the structure produced by
GDAL's `gdalinfo -hist -json` command.

## Usage

``` r
raster_histogram(count, min, max, buckets)
```

## Arguments

- count:

  (integer, required) Number of buckets in the histogram.

- min:

  (numeric, required) Lower bound of the histogram.

- max:

  (numeric, required) Upper bound of the histogram.

- buckets:

  (integer vector, required) Array of counts for each bucket. Length
  must equal `count`.

## Value

A list representing a histogram object.

## Examples

``` r
# Simple histogram with 5 buckets
hist <- raster_histogram(
  count = 5,
  min = 0,
  max = 100,
  buckets = c(1500, 3200, 4100, 2800, 1400)
)
```
