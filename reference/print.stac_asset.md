# Print method for STAC assets

Print method for STAC assets

## Usage

``` r
# S3 method for class 'stac_asset'
print(x, ..., expand = NULL)
```

## Arguments

- x:

  A STAC asset object created with
  [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md).

- ...:

  Additional arguments (ignored).

- expand:

  Controls the collapsible extension-field section. `TRUE` expands it,
  `FALSE` (the default) collapses it, or give the section name
  `"fields"`. Defaults to the `stacbuildr.print.expand` option.

## Value

`x`, invisibly.
