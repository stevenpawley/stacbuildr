# Create STAC Summaries

Helper function to create property summaries for STAC Collections.
Summaries describe the range of values for properties in the
collection's Items.

## Usage

``` r
stac_summaries(...)
```

## Arguments

- ...:

  Named arguments where each name is a property and the value is either:

  - A vector of unique values

  - A list with `minimum` and `maximum` elements

  - A nested list for complex properties

## Value

A list of property summaries.

## Examples

``` r
summaries <- stac_summaries(
  platform = c("landsat-8", "landsat-9"),
  instruments = c("oli", "tirs"),
  gsd = list(minimum = 15, maximum = 30),
  `eo:bands` = list(
    list(name = "B1", common_name = "coastal"),
    list(name = "B2", common_name = "blue")
  )
)
```
