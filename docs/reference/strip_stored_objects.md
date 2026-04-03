# Strip Stored Objects from STAC Object

Internal function to remove stored child/item objects before writing to
JSON. This ensures only the standard STAC fields are written to the
file.

## Usage

``` r
strip_stored_objects(stac_obj)
```
