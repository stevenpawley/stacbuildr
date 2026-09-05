# Join a relative path onto a base URL

Appends `rel` to `base`, collapsing any `.` and `..` segments so the
result is a clean absolute URL.

## Usage

``` r
url_join(base, rel)
```

## Arguments

- base:

  Absolute base URL, for example `"https://example.com/stac/item"`.

- rel:

  Relative path, for example `"../data/dem.tif"`.

## Value

An absolute URL string.
