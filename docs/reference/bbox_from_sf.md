# Calculate Bounding Box from sf Object

Calculates a bounding box from an sf object in the format required by
STAC.

## Usage

``` r
bbox_from_sf(sf_obj)
```

## Arguments

- sf_obj:

  An sf object.

## Value

A numeric vector of length 4: c(west, south, east, north).
