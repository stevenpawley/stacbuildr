# Extract Raster Band Metadata from a File

Extracts raster metadata from a file using `stars` and
[`sf::gdal_utils`](https://r-spatial.github.io/sf/reference/gdal_utils.html).
Creates band objects with data type, spatial resolution, and optionally
statistics.

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

  (integer, optional) Number of pixels to sample per band when
  calculating statistics. If NULL, all pixels are used.

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
