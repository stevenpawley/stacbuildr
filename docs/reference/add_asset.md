# Add an Asset to a STAC Item

Adds an asset to a STAC Item's assets dictionary.

## Usage

``` r
add_asset(
  item,
  key,
  asset = NULL,
  href = NULL,
  title = NULL,
  description = NULL,
  type = NULL,
  roles = NULL,
  ...
)
```

## Arguments

- item:

  A STAC Item object.

- key:

  (character, required) The asset identifier/key (e.g., "visual",
  "thumbnail", "B4"). Must be unique within the Item's assets.

- asset:

  An optional asset object previously created using
  [`stac_asset()`](https://stevenpawley.github.io/stacbuildr/reference/stac_asset.md).
  Alternatively, the asset can be created from the `add_asset`
  arguments.

- href:

  (character, required) URI to the asset object.

- title:

  (character, optional) Displayed title for the asset.

- description:

  (character, optional) Description of the asset.

- type:

  (character, optional) Media type of the asset.

- roles:

  (character vector, optional) Semantic roles of the asset.

- ...:

  Additional asset fields (extension properties).

## Value

The modified Item object with the asset added.

## Examples

``` r
item <- stac_item(
  id = "my-item",
  geometry = list(type = "Point", coordinates = c(-105, 40)),
  bbox = c(-105, 40, -105, 40),
  datetime = "2023-01-01T00:00:00Z"
)

item <- add_asset(
  item,
  key = "visual",
  href = "https://example.com/visual.tif",
  title = "True Color Image",
  type = "image/tiff; application=geotiff",
  roles = c("visual")
)
```
