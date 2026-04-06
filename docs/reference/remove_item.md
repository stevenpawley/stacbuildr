# Remove Items from a STAC Catalog or Collection

Removes Item link(s) from a Catalog or Collection. Can remove by Item
ID, href, or remove all items.

## Usage

``` r
remove_item(catalog, item_id = NULL, href = NULL, all = FALSE)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object.

- item_id:

  (character, optional) ID(s) of the item(s) to remove. The function
  will attempt to match these IDs from the href (e.g., if href is
  "./items/my-item.json", it will match item_id "my-item").

- href:

  (character, optional) Specific href(s) to remove.

- all:

  (logical, optional) If `TRUE`, removes all item links. Default is
  `FALSE`. Use with caution.

## Value

The modified catalog/collection object with Item link(s) removed.

## Examples

``` r
catalog <- stac_catalog(
  id = "my-catalog",
  description = "Example catalog"
)

# Remove specific item by ID
catalog <- remove_item(catalog, item_id = "my-item-001")

# Remove multiple items
catalog <- remove_item(catalog, item_id = c("item1", "item2"))

# Remove by href
catalog <- remove_item(catalog, href = "./items/my-item.json")

# Remove all items
catalog <- remove_item(catalog, all = TRUE)
```
