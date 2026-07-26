# Add Render Extension to a STAC Item or Collection

Adds the STAC Render extension to a STAC Item or Collection. The Render
extension provides rendering hints that tell consumers how to visualize
the item's assets (e.g. on a web map).

## Usage

``` r
add_render_extension(item, renders)
```

## Arguments

- item:

  A STAC Item (`stac_item`) or Collection (`stac_collection`) object.

- renders:

  (named list, required) A named list of render objects created with
  [`render_object()`](https://stevenpawley.github.io/stacbuildr/reference/render_object.md).
  Names are used as render keys and must be unique.

## Value

The modified STAC Item or Collection with Render extension fields added.

## Details

### Extension Schema URI

The Render Extension v2.0.0 schema URI is:
`https://stac-extensions.github.io/render/v2.0.0/schema.json`

### Field Placement

- For **Items**, `renders` is placed in `properties`.

- For **Collections**, `renders` is placed at the top level of the
  Collection object.

### Render Keys

Each render object is stored under a unique key inside `renders`. Common
keys include `"thumbnail"`, `"true_color"`, `"ndvi"`, etc.

## References

Render Extension Specification:
<https://github.com/stac-extensions/render>

## See also

- [`render_object()`](https://stevenpawley.github.io/stacbuildr/reference/render_object.md)
  for creating render objects

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

- [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md)
  for creating STAC Collections

## Examples

``` r
item <- stac_item(
  id = "LC08_L1TP_044033_20210305",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-122.5, 39.5), c(-120.5, 39.5), c(-120.5, 40.5),
      c(-122.5, 40.5), c(-122.5, 39.5)
    ))
  ),
  bbox = c(-122.5, 39.5, -120.5, 40.5),
  datetime = "2021-03-05T18:45:37Z"
) |>
  add_asset(
    key = "B4",
    href = "https://example.com/B4.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_asset(
    key = "B3",
    href = "https://example.com/B3.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_asset(
    key = "B2",
    href = "https://example.com/B2.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  )

item <- item |>
  add_render_extension(renders = list(
    true_color = render_object(
      assets = c("B4", "B3", "B2"),
      title = "True Color",
      rescale = list(c(0, 10000), c(0, 10000), c(0, 10000)),
      resampling = "bilinear"
    )
  ))
```
