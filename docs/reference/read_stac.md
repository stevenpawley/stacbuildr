# Read a STAC Catalog from Disk

Reads a STAC Catalog, Collection, or Item from a JSON file and returns
the corresponding S7 object (`stac_catalog`, `stac_collection`, or
`stac_item`). The returned object is fully usable with all package
functions, completing the write/read round-trip.

## Usage

``` r
read_stac(file)
```

## Arguments

- file:

  (character, required) Path to the STAC JSON file.

## Value

An S7 object of class `stac_catalog`, `stac_collection`, or `stac_item`,
depending on the `type` field in the JSON.

## Examples

``` r
if (FALSE) { # \dontrun{
catalog <- read_stac("path/to/catalog.json")
item    <- read_stac("path/to/item.json")
} # }
```
