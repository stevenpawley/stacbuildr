# Add Item Asset Definitions to a Collection

Item assets serve two purposes:

1.  To provide a human-readable definition of the assets available on
    the items in a collection.

2.  To provide a means to programmatically query what assets are
    available in a collection without crawling through every item.

The `item_assets` field is created by inspecting the items already added
to a collection and using the assets present on those items. For each
unique asset key, the definition is taken from the first item that
contains it (minus the `href` field, which is item-specific).

An item asset is almost the same as a regular `stac_asset` object except
it doesn't include an `href` field because it is only used to describe
assets and does not point to the data itself.

## Usage

``` r
add_item_assets(collection)
```

## Arguments

- collection:

  A `stac_collection` object with items added via
  [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md).

## Value

The collection with `item_assets` populated.

## Note

Item assets are intended to describe the complete set of assets in a
collection, so they include every asset key found on any item. Because a
single shared definition is derived per key (from the first item that
contains it), fields such as `title`, `description`, `type`, and `roles`
should ideally be consistent across all items in a collection.

## References

STAC Collection Specification (`item_assets`):
<https://github.com/radiantearth/stac-spec/tree/master/collection-spec>

## See also

- [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md)
  for adding items to a collection

- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating collections

## Examples

``` r
if (FALSE) { # \dontrun{
collection <- stac_collection(
  id = "landsat",
  description = "Landsat imagery",
  license = "proprietary",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
  )
)

item <- stac_item(
  id = "LC09_001",
  geometry = list(type = "Point", coordinates = c(-120, 48)),
  bbox = c(-121, 47, -119, 49),
  datetime = "2023-07-01T00:00:00Z"
)
item <- add_asset(item,
  key = "red",
  href = "red.tif", type = "image/tiff", roles = "data", title = "Red Band"
)

collection <- add_item(collection, item)
collection <- add_item_assets(collection)
} # }
```
