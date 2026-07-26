# Create a STAC Render Object

Creates a render object for use with the STAC Render Extension. A render
object describes how one or more assets should be visualized (e.g. in a
web map or dynamic tile server).

## Usage

``` r
render_object(
  assets,
  title = NULL,
  rescale = NULL,
  nodata = NULL,
  colormap_name = NULL,
  colormap = NULL,
  color_formula = NULL,
  resampling = NULL,
  expression = NULL,
  minmax_zoom = NULL,
  bidx = NULL,
  ...
)
```

## Arguments

- assets:

  (character, required) Asset keys referencing the assets that are used
  to make the rendering. These must be local asset keys defined in the
  same STAC Item.

- title:

  (character, optional) Title of the rendering.

- rescale:

  (list, optional) A list of numeric vectors, each of length 2, giving
  the minimum and maximum range per band. For example,
  `list(c(0, 10000), c(0, 10000), c(0, 10000))` for an RGB composite.

- nodata:

  (numeric or character, optional) Nodata value to use for the
  referenced assets.

- colormap_name:

  (character, optional) Named color map to apply to a raster band (e.g.
  `"ylgn"`, `"rainbow"`).

- colormap:

  (list, optional) A custom color map JSON definition.

- color_formula:

  (character, optional) Color formula to apply to a raster band (see
  TiTiler documentation for examples).

- resampling:

  (character, optional) GDAL resampling algorithm to apply to the
  referenced assets (e.g. `"nearest"`, `"bilinear"`, `"average"`).

- expression:

  (character, optional) Band arithmetic formula to apply to the
  referenced assets (e.g. `"(B5-B4)/(B5+B4)"`).

- minmax_zoom:

  (numeric, optional) Zoom level range applicable for the visualization,
  as a length-2 numeric vector `c(min_zoom, max_zoom)`.

- bidx:

  (numeric, optional) Band indexes to use for rendering.

- ...:

  Additional fields allowed by the open-ended Render Object schema.

## Value

A named list of class `"render_object"`.

## Details

### Render Object Fields

The Render Extension defines the following standard fields inside each
render object:

- `assets`: Required. Asset keys used for rendering.

- `title`: Optional human-readable title.

- `rescale`: Optional per-band min/max ranges.

- `nodata`: Optional nodata value.

- `colormap_name`: Optional named color map.

- `colormap`: Optional custom color map definition.

- `color_formula`: Optional color formula.

- `resampling`: Optional resampling method.

- `expression`: Optional band arithmetic expression.

- `minmax_zoom`: Optional zoom level range.

- `bidx`: Optional band indexes.

Additional fields may be supplied via `...`.

## Examples

``` r
rgb_render <- render_object(
  assets = c("B4", "B3", "B2"),
  title = "True Color",
  rescale = list(c(0, 10000), c(0, 10000), c(0, 10000)),
  resampling = "bilinear"
)

ndvi_render <- render_object(
  assets = c("B5", "B4"),
  title = "NDVI",
  expression = "(B5-B4)/(B5+B4)",
  rescale = list(c(-1, 1)),
  colormap_name = "ylgn",
  resampling = "average"
)
```
