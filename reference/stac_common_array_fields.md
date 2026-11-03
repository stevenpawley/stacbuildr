# STAC Common Metadata fields that the spec types as JSON arrays. These may appear on Item properties and on Asset objects, so both normalise them through as_json_array() to stop a single value collapsing to a scalar. Taken from basics.json (keywords, roles), instrument.json (instruments), provider.json (providers) and bands.json (bands) in the item spec.

STAC Common Metadata fields that the spec types as JSON arrays. These
may appear on Item properties and on Asset objects, so both normalise
them through as_json_array() to stop a single value collapsing to a
scalar. Taken from basics.json (keywords, roles), instrument.json
(instruments), provider.json (providers) and bands.json (bands) in the
item spec.

## Usage

``` r
stac_common_array_fields
```
