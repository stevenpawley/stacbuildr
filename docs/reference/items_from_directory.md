# Batch Create Items from Raster Files

Creates multiple STAC Items from a directory of raster files.

## Usage

``` r
items_from_directory(
  directory,
  pattern = "\\.(tif|tiff|nc|hdf|hdf5)$",
  datetime_from_filename = NULL,
  ...
)
```

## Arguments

- directory:

  Directory containing raster files.

- pattern:

  File pattern to match (regex). Default matches common raster formats.

- datetime_from_filename:

  Function to extract datetime from filename. Should return ISO 8601
  string. If NULL, uses current time.

- ...:

  Additional arguments passed to
  [`item_from_stars()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_stars.md).

## Value

A list of STAC Item objects.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create items for all GeoTIFFs in a directory
items <- items_from_directory(
  "path/to/rasters",
  pattern = "\\.tif$"
)

# With custom datetime extraction
extract_datetime <- function(filename) {
  # Extract date from filename like "LC08_20230615_..."
  date_str <- sub(".*_(\\d{8})_.*", "\\1", filename)
  paste0(
    substr(date_str, 1, 4), "-",
    substr(date_str, 5, 6), "-",
    substr(date_str, 7, 8), "T00:00:00Z"
  )
}

items <- items_from_directory(
  "landsat",
  datetime_from_filename = extract_datetime
)
} # }
```
