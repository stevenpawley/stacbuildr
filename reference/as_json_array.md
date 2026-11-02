# Mark a value as a JSON array

The writers serialise with jsonlite's `auto_unbox = TRUE`, which
collapses a length-1 atomic vector to a JSON scalar. That is right for
the many STAC fields that are single values, but wrong for the ones the
spec types as arrays: a collection with one keyword would emit
`"keywords": "dem"` where the schema demands `["dem"]`. Wrapping in a
list forces the array form regardless of length, since `auto_unbox`
never unboxes a list.

## Usage

``` r
as_json_array(x)
```

## Details

`NULL` passes through so callers can use it on optional fields without
guarding, and a value that is already a list is left alone.

## Examples

``` r
# Without the helper, auto_unbox collapses a length-1 vector to a scalar,
# which the STAC schema rejects for array-typed fields
jsonlite::toJSON(list(keywords = "dem"), auto_unbox = TRUE)
#> {"keywords":"dem"} 
#> {"keywords":"dem"}

# Wrapping forces the array form, regardless of length
jsonlite::toJSON(list(keywords = as_json_array("dem")), auto_unbox = TRUE)
#> Error in as_json_array("dem"): could not find function "as_json_array"
#> {"keywords":["dem"]}

# Multi-element vectors serialise as arrays either way
jsonlite::toJSON(list(keywords = c("dem", "elevation")), auto_unbox = TRUE)
#> {"keywords":["dem","elevation"]} 
#> {"keywords":["dem","elevation"]}

# Values that are already lists are returned unchanged
jsonlite::toJSON(list(keywords = as_json_array(list("dem"))), auto_unbox = TRUE)
#> Error in as_json_array(list("dem")): could not find function "as_json_array"
#> {"keywords":["dem"]}

# NULL passes through, so optional fields can be passed unconditionally
str(as_json_array(NULL))
#> Error in as_json_array(NULL): could not find function "as_json_array"
#>  NULL
```
