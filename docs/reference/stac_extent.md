# Create a STAC Extent Object

Helper function to create a properly formatted extent object for STAC
Collections.

## Usage

``` r
stac_extent(spatial_bbox, temporal_interval)
```

## Arguments

- spatial_bbox:

  List of bounding boxes. Each bbox should be a numeric vector of 4
  values `c(west, south, east, north)` or 6 values for 3D
  `c(west, south, min_elev, east, north, max_elev)`. The first bbox is
  the overall extent.

- temporal_interval:

  List of time intervals. Each interval should be a list of length 2:
  `list("start", "end")`. Use `NULL` for open-ended intervals:
  `list("start", NULL)`. Times should be in ISO 8601 format. Note: use
  [`list()`](https://rdrr.io/r/base/list.html) not
  [`c()`](https://rdrr.io/r/base/c.html) —
  [`c()`](https://rdrr.io/r/base/c.html) drops `NULL`, producing an
  invalid interval.

## Value

An `Extent` S7 object formatted for STAC Collections.

## Examples

``` r
# Simple global extent
extent <- stac_extent(
  spatial_bbox = list(c(-180, -90, 180, 90)),
  temporal_interval = list(list("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z"))
)

# Open-ended temporal extent (ongoing collection)
extent <- stac_extent(
  spatial_bbox = list(c(-120, 30, -110, 40)),
  temporal_interval = list(list("2015-01-01T00:00:00Z", NULL))
)

# Multiple spatial extents (e.g., disjoint regions)
extent <- stac_extent(
  spatial_bbox = list(
    c(-180, -90, 180, 90),  # Overall extent
    c(-120, 30, -110, 40),  # Western US
    c(-10, 35, 5, 45)       # Western Europe
  ),
  temporal_interval = list(list("2020-01-01T00:00:00Z", "2023-12-31T23:59:59Z"))
)
```
