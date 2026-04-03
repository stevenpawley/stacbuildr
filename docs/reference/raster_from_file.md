# Extract Raster Metadata from File

Extracts raster metadata from a raster file using the terra package.
Creates band objects with data type, nodata values, and spatial
resolution. Optionally calculates statistics if requested.

## Usage

``` r
raster_from_file(file, calculate_statistics = FALSE, sample_size = NULL)
```

## Arguments

- file:

  (character, required) Path to the raster file.

- calculate_statistics:

  (logical, optional) If TRUE, calculates min, max, mean, and standard
  deviation for each band. Default is FALSE (can be slow for large
  files).

- sample_size:

  (integer, optional) Maximum number of pixels to sample when
  calculating statistics. Helps speed up processing for large rasters.
  Default is NULL (use all pixels).

## Value

A list of raster band objects, one per band in the file.

## Examples

``` r
if (FALSE) { # \dontrun{
# Extract basic metadata
bands <- raster_from_file("path/to/image.tif")

# Extract metadata with statistics
bands <- raster_from_file(
  "path/to/image.tif",
  calculate_statistics = TRUE
)

# Add to STAC item
item <- item |>
  add_asset("data", "path/to/image.tif", type = "image/tiff") |>
  add_raster_extension(bands = bands, asset_key = "data")
} # }
```
