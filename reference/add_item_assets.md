# Add Item Asset Definitions to a Collection

Inspects the items already added to a collection and derives the
`item_assets` field automatically, using the assets present on those
items. For each unique asset key, the definition is taken from the first
item that contains it (minus the `href` field, which is item-specific).
The Item Assets extension URI is added to `stac_extensions`
automatically.

## Usage

``` r
add_item_assets(collection)
```

## Arguments

- collection:

  A `stac_collection` object with items added via
  [`add_item()`](https://stevenpawley.github.io/stacbuildr/reference/add_item.md).

## Value

The collection with `item_assets` populated and the Item Assets
extension added to `stac_extensions`.

## References

STAC Item Assets Definition Extension:
<https://stac-extensions.github.io/item-assets/v1.0.0/schema.json>

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
item <- add_asset(item, key = "red",
  href = "red.tif", type = "image/tiff", roles = "data", title = "Red Band")

collection <- add_item(collection, item)
collection <- add_item_assets(collection)
} # }
```
