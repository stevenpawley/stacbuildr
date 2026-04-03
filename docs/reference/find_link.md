# Find a Link by Relation Type

Helper function to find a link with a specific relation type in a STAC
object.

## Usage

``` r
find_link(stac_object, rel)
```

## Arguments

- stac_object:

  A STAC Catalog, Collection, or Item object.

- rel:

  The link relation type to find (e.g., "self", "root", "parent").

## Value

The first link object with the matching rel type, or NULL if not found.
