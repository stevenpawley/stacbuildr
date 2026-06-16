# Creates a band object for use with the Raster Extension. Describes the characteristics of a single raster band including data type, nodata values, scale/offset transforms, and statistics.

`raster_band()` is an S7 object that is used to construct a
`raster:bands` STAC metadata entry

## Usage

``` r
raster_band(
  nodata = NULL,
  data_type = NULL,
  unit = NULL,
  statistics = NULL,
  sampling = NULL,
  bits_per_sample = NULL,
  spatial_resolution = NULL,
  scale = 1,
  offset = 0,
  histogram = NULL,
  ...
)
```

## Arguments

- nodata:

  (numeric or NULL, optional) Pixel value(s) that should be interpreted
  as "no data". Can be a single value or vector of values. Common
  values: 0, -9999, NaN.

- data_type:

  (character, optional) Data type of the band. Must be one of: "int8",
  "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64",
  "float16", "float32", "float64", "cint16", "cint32", "cfloat32",
  "cfloat64", or "other".

- unit:

  (character, optional) Unit of measurement for the pixel values.
  Examples: "m" (meters), "W sr-1 m-2" (radiance), "1"
  (unitless/reflectance).

- statistics:

  (list, optional) Statistics object created with
  [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md)
  describing the distribution of pixel values.

- sampling:

  single length character, must be either 'point' where the pixel value
  represents a point sample at the centre of the pixel, or 'area' where
  the pixel value should be assumed to represent a sampling over the
  region of the pixel

- bits_per_sample:

  (integer, optional) Actual number of bits used for this band. Only
  needed when different from the standard for the data type (e.g., 1-bit
  data stored in uint8).

- spatial_resolution:

  (numeric, optional) Average spatial resolution of pixels in the band,
  in meters. Useful when resolution varies or differs from ground sample
  distance (gsd).

- scale:

  (numeric, optional) Multiplicative scaling factor to transform pixel
  values: `physical_value = scale * DN + offset`. Default is 1.

- offset:

  (numeric, optional) Additive offset to transform pixel values:
  `physical_value = scale * DN + offset`. Default is 0.

- histogram:

  (list, optional) Histogram object created with
  [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md)
  describing the distribution of pixel values.

- ...:

  Additional fields for the band object. Can include fields from other
  extensions like `"common_name"`, `"center_wavelength"`.

## Value

An S7 class representing a raster band object.
