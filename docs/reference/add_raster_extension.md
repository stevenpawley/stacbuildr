# Add Raster Extension to a STAC Item or Asset

Adds the Raster Extension to a STAC Item or modifies an asset to include
raster-specific metadata. The Raster Extension describes raster assets
at the band level with information such as data type, nodata values,
scale/offset transforms, and statistics.

**Important Note on STAC 1.1.0 Changes:** In STAC 1.1.0, the
`raster:bands` field was deprecated in favor of a common `bands`
construct that merges functionality from both `eo:bands` and
`raster:bands`. Some raster-specific fields (like `nodata`, `data_type`,
`statistics`, `unit`) are now part of STAC common metadata and should be
included directly in band objects. The remaining raster-specific fields
(`raster:sampling`, `raster:bits_per_sample`,
`raster:spatial_resolution`, `raster:scale`, `raster:offset`,
`raster:histogram`) retain the `raster:` prefix.

## Usage

``` r
add_raster_extension(item, bands, asset_key = NULL)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- bands:

  A list of band objects created with
  [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md).
  Each band describes the characteristics of a single raster band (or
  layer). If the asset has multiple bands, provide a list with one entry
  per band in order.

- asset_key:

  (character, optional) If provided, adds the bands to a specific asset
  rather than to the item properties. Useful when different assets have
  different band structures.

## Value

The modified STAC Item with raster extension fields added.

## Details

### Extension Schema URI

The Raster Extension v1.1.0 schema URI is:
`https://stac-extensions.github.io/raster/v1.1.0/schema.json`

### Band Object Fields

Each band can contain both common metadata fields and raster-specific
fields:

**Common Metadata (no prefix):**

- `nodata`: Pixel values to be interpreted as nodata

- `data_type`: Data type of the band (e.g., "uint8", "int16", "float32")

- `unit`: Unit of measurement for pixel values

- `statistics`: Object with min, max, mean, stddev, valid_percent

**Raster-Specific (raster: prefix):**

- `raster:sampling`: Pixel sampling method ("area" or "point")

- `raster:bits_per_sample`: Actual number of bits used per sample

- `raster:spatial_resolution`: Average spatial resolution in meters

- `raster:scale`: Multiplicative scaling factor to convert DN to values

- `raster:offset`: Additive offset to convert DN to values

- `raster:histogram`: Histogram distribution of pixel values

### Scale and Offset

In remote sensing, raster data often stores raw Digital Numbers (DN)
that must be transformed to physical values using:

**value = scale \* DN + offset**

For example, storing reflectance (0-1) as integers (0-10000) with
scale=0.0001.

### Data Types

Supported data type values include:

- `"int8"`, `"int16"`, `"int32"`, `"int64"`

- `"uint8"`, `"uint16"`, `"uint32"`, `"uint64"`

- `"float16"`, `"float32"`, `"float64"`

- `"cint16"`, `"cint32"` (complex integers)

- `"cfloat32"`, `"cfloat64"` (complex floats)

- `"other"` (for custom types)

## References

Raster Extension Specification:
<https://github.com/stac-extensions/raster>

## See also

- [`raster_band()`](https://stevenpawley.github.io/stacbuildr/reference/raster_band.md)
  for creating band objects

- [`raster_statistics()`](https://stevenpawley.github.io/stacbuildr/reference/raster_statistics.md)
  for creating statistics objects

- [`raster_histogram()`](https://stevenpawley.github.io/stacbuildr/reference/raster_histogram.md)
  for creating histogram objects

- [`add_asset()`](https://stevenpawley.github.io/stacbuildr/reference/add_asset.md)
  for adding assets to items

## Examples

``` r
# Create an item
item <- stac_item(
  id = "my-raster",
  geometry = list(type = "Point", coordinates = c(-105, 40)),
  bbox = c(-105, 40, -105, 40),
  datetime = "2023-01-01T00:00:00Z"
)

# Add a single-band raster asset
band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  spatial_resolution = 30,
  scale = 0.0001,
  offset = 0
)

item <- add_raster_extension(item, bands = list(band))

# Add multi-band raster with statistics
red_band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  spatial_resolution = 10,
  scale = 0.0001,
  offset = -0.1,
  statistics = raster_statistics(
    minimum = 1,
    maximum = 10000,
    mean = 2500,
    stddev = 1200,
    valid_percent = 99.5
  )
)

green_band <- raster_band(
  nodata = 0,
  data_type = "uint16",
  spatial_resolution = 10,
  scale = 0.0001,
  offset = -0.1
)

item <- item |>
  add_asset(
    key = "visual",
    href = "https://example.com/image.tif",
    type = "image/tiff; application=geotiff",
    roles = c("data")
  ) |>
  add_raster_extension(
    bands = list(red_band, green_band),
    asset_key = "visual"
  )
```
