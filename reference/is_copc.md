# Check whether a file is a Cloud Optimized Point Cloud

Recognises the `.copc.laz` naming convention that COPC files use. Unlike
[`is_cog()`](https://stevenpawley.github.io/stacbuildr/reference/is_cog.md)
this is a name check rather than a structural one, so it works for
remote URLs as well as local files.

## Usage

``` r
is_copc(file)
```

## Arguments

- file:

  File path or URL.

## Value

Logical scalar.
