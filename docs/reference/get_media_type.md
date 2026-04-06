# Get Media Type for File

Determines the appropriate MIME type for a file based on extension. For
GeoTIFF files that exist locally, checks whether the file is a Cloud
Optimized GeoTIFF and appends "; profile=cloud-optimized" if so.

## Usage

``` r
get_media_type(file)
```

## Arguments

- file:

  File path or URL.

## Value

Media type string.
