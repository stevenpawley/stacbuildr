# Determine data type from a file path using GDAL

Parses `gdalinfo` output to extract the GDAL data type and maps it to
the STAC raster extension type string. More accurate than inferring from
R's [`typeof()`](https://rdrr.io/r/base/typeof.html), which loses
precision (e.g. UInt16 and Int32 both appear as "integer").

## Usage

``` r
gdal_dtype(file)
```

## Arguments

- file:

  Local file path.

## Value

A STAC raster data type string, or `"other"` if not determinable.
