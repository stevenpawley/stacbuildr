# Validate a STAC Object

Validates a STAC Catalog, Collection, or Item against the STAC
specification. Checks for required fields, proper structure, and valid
values.

## Usage

``` r
validate_stac(stac_object, strict = FALSE)
```

## Arguments

- stac_object:

  A STAC object (catalog, collection, or item).

- strict:

  (logical, optional) If TRUE, enforces stricter validation including
  recommended fields. Default is FALSE.

## Value

A list with elements:

- `valid`: Logical indicating if the object is valid

- `errors`: Character vector of error messages (empty if valid)

- `warnings`: Character vector of warning messages for missing
  recommended fields
