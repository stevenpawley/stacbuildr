# Normalize an href for use in a STAC asset

Expands local file paths (e.g. `~/...`) to absolute paths so they are
valid URIs. Remote URLs (containing `://`) are returned unchanged.

## Usage

``` r
normalize_href(href)
```

## Arguments

- href:

  A file path or URL string.

## Value

A normalized path or unchanged URL string.
