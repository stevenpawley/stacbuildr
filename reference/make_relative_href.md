# Strip Stored Objects from STAC Object

Compute a relative path from a directory to a target file

## Usage

``` r
make_relative_href(target, from_dir)
```

## Arguments

- target:

  Absolute path to the target file.

- from_dir:

  Absolute path to the directory to compute relative to.

## Value

A relative path string, or `target` unchanged if it is a URL or already
relative.
