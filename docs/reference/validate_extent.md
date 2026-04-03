# Validate Extent Object

Validates the spatial and temporal extent fields of a STAC Collection.
Checks for required bbox and interval fields and ensures proper
structure.

## Usage

``` r
validate_extent(extent)
```

## Details

The extent object must contain two required fields:

- `spatial`: Contains a `bbox` field with a list of one or more bounding
  boxes. Each bounding box must be a numeric vector of length 4 (2D:
  c(west, south, east, north)) or 6 (3D: c(west, south, min_elevation,
  east, north, max_elevation)).

- `temporal`: Contains an `interval` field with a time interval. The
  time interval must be a vector of 2 elements representing start and
  end times (as character or NA for open-ended intervals).
