# Read a STAC Catalog from Disk

Reads a STAC Catalog, Collection, or Item from a JSON file.

## Usage

``` r
read_stac(file)
```

## Arguments

- file:

  (character, required) Path to the STAC JSON file.

## Value

A STAC object (catalog, collection, or item) with the appropriate class.

## Examples

``` r
if (FALSE) { # \dontrun{
catalog <- read_stac("path/to/catalog.json")
item <- read_stac("path/to/item.json")
} # }
```
