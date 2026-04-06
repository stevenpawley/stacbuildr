# Add an Item to a STAC Catalog or Collection

Adds a STAC Item to a Catalog or Collection by creating the appropriate
link relationship. This function modifies the catalog/collection object
to include an `"item"` link pointing to the Item. Optionally, it can
also modify the Item to include links back to the parent (`"parent"`,
`"collection"`, and `"root"`).

## Usage

``` r
add_item(
  catalog,
  item,
  href = NULL,
  add_parent_links = FALSE,
  parent_href = NULL,
  root_href = NULL
)
```

## Arguments

- catalog:

  A STAC Catalog or Collection object (created with
  [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  or
  [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)).

- item:

  A STAC Item object (created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)).
  Can also be a list of Items to add multiple items at once.

- href:

  (character, optional) The relative or absolute path where the Item
  JSON file will be located. If `NULL` (default), generates a path based
  on the item's ID: `"./items/{item@id}.json"`. Can be a vector of paths
  when `item` is a list.

- add_parent_links:

  (logical, optional) If `TRUE`, modifies the Item(s) to include
  reciprocal links back to the parent catalog. Adds `"parent"` and
  `"root"` links. If the parent is a Collection, also adds a
  `"collection"` link. Default is `FALSE` to avoid modifying the
  original Item object.

- parent_href:

  (character, optional) The href for the parent catalog/collection. Only
  used if `add_parent_links = TRUE`. If not provided and a `"self"` link
  exists in the catalog, uses that; otherwise uses a placeholder.

- root_href:

  (character, optional) The href for the root catalog. Only used if
  `add_parent_links = TRUE`. If not provided, attempts to use the
  catalog's `"root"` link or defaults to `parent_href`.

## Value

The modified catalog/collection object with the Item link(s) added. If
`add_parent_links = TRUE`, also returns the Item(s) with updated links
as an attribute named `"items"` (accessible via
`attr(result, "items")`).

## Details

### Link Relations

This function creates an `"item"` link in the catalog that points to the
Item. Based on the STAC specification, Items are strongly recommended to
provide a link to a STAC Collection, so when adding Items to a
Collection, consider setting `add_parent_links = TRUE`.

When `add_parent_links = TRUE`:

- Adds `"parent"` link to the Item pointing to the catalog/collection

- Adds `"root"` link to the Item pointing to the root catalog

- If parent is a Collection, adds `"collection"` link and sets the
  `collection` property in the Item (required when collection link is
  present)

### Multiple Items

You can add multiple items at once by passing a list of Item objects. In
this case, `href` should be either:

- `NULL` to auto-generate paths for all items

- A vector of the same length as the number of items

### Item Requirements

Based on the STAC Item specification, each Item must have the following
fields:

- `type`: "Feature"

- `stac_version`: e.g., "1.1.0"

- `id`: Unique identifier within the collection

- `geometry`: GeoJSON geometry or null

- `bbox`: Bounding box (required if geometry is not null)

- `properties`: Object with metadata (must include `datetime`)

- `links`: Array of links

- `assets`: Object describing available data files

## See also

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

- [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md)
  for creating STAC Catalogs

- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating STAC Collections

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding links to STAC objects

- [`add_child()`](https://stevenpawley.github.io/stacbuildr/reference/add_child.md)
  for adding child catalogs/collections

## Examples

``` r
# Create a collection
collection <- stac_collection(
  id = "landsat-8",
  description = "Landsat 8 imagery",
  license = "CC0-1.0",
  extent = stac_extent(
    spatial_bbox = list(c(-180, -90, 180, 90)),
    temporal_interval = list(list("2013-04-11T00:00:00Z", NULL))
  )
)

# Create an item
item <- stac_item(
  id = "LC08_L1TP_001001_20200101_20200101_01_T1",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-180, -90), c(180, -90), c(180, 90), c(-180, 90), c(-180, -90)
    ))
  ),
  bbox = c(-180, -90, 180, 90),
  datetime = "2020-01-01T00:00:00Z",
  properties = list()
)

# Add the item to the collection (simple)
collection <- add_item(collection, item)

# Add the item with parent links
collection <- add_item(
  collection,
  item,
  add_parent_links = TRUE,
  parent_href = "./collection.json",
  root_href = "../catalog.json"
)

# Add multiple items
items <- list(item, item, item)
collection <- add_item(collection, items)

# Add multiple items with custom hrefs
collection <- add_item(
  collection,
  items,
  href = c("./2020/item1.json", "./2020/item2.json", "./2020/item3.json")
)
```
