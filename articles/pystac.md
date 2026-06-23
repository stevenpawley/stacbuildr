# Comparison with PySTAC

``` r

library(stacbuildr)
library(reticulate)

py_require(c("pystac", "tzdata"))
pystac <- import("pystac")
#> Downloading uv...Done!
dt <- import("datetime")
```

## Comparison with PySTAC

This vignette compares stacbuildr with the Python
[PySTAC](https://pystac.readthedocs.io/) library by writing equivalent
catalog structures to disk and comparing the resulting JSON.

### Building a catalog with an item

#### stacbuildr

``` r

catalog <- stac_catalog(
  id = "environmental-data",
  description = "A collection of environmental data",
  title = "Environmental Data Catalog"
)

item <- stac_item(
  id = "temperature",
  geometry = list(
    type = "Point",
    coordinates = c(-122.45, 54.34)
  ),
  bbox = c(-125, 50, -120, 55),
  datetime = "2023-07-06T08:00:00Z"
)

catalog <- catalog |> 
  add_item(item)
```

#### PySTAC

``` r

catalog_py <- pystac$Catalog(
  id = "environmental-data",
  description = "A collection of environmental data",
  title = "Environmental Data Catalog",
  catalog_type = pystac$CatalogType$RELATIVE_PUBLISHED
)

item_py <- pystac$Item(
  id = "temperature",
  geometry = reticulate::dict(
    type = "Point",
    coordinates = list(c(-122.45, 54.34))
  ),
  bbox = list(-125, 50, -120, 55),
  datetime = dt$datetime$fromisoformat("2023-07-06T08:00:00+00:00"),
  properties = reticulate::dict()
)

catalog_py$add_item(item_py)
#> <Link rel=item target=<Item id=temperature>>
```

### Writing to disk and comparing

Both libraries are asked to write a relative catalog. stacbuildr uses
`catalog_type = "relative"` and PySTAC uses
`CatalogType$RELATIVE_PUBLISHED`, which are equivalent.

``` r

r_path <- file.path(tempdir(), "r-stac")
write_stac(catalog, r_path, catalog_type = "relative", overwrite = TRUE)
#> STAC catalog written to: /tmp/Rtmp9ekDn1/r-stac
catalog_rjson <- jsonlite::read_json(file.path(r_path, "catalog.json"))

py_path <- file.path(tempdir(), "py-stac")
catalog_py$normalize_hrefs(py_path)
catalog_py$save(dest_href = py_path)
catalog_pyjson <- jsonlite::read_json(file.path(py_path, "catalog.json"))
```

#### Catalog JSON

``` r

cat("R json output: \n")
#> R json output:
jsonlite::toJSON(catalog_rjson, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Catalog",
#>   "stac_version": "1.1.0",
#>   "id": "environmental-data",
#>   "description": "A collection of environmental data",
#>   "title": "Environmental Data Catalog",
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "./catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "./catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "item",
#>       "href": "./temperature/temperature.json",
#>       "type": "application/geo+json"
#>     }
#>   ]
#> }

cat("\nPython json output: \n")
#> 
#> Python json output:
jsonlite::toJSON(catalog_pyjson, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Catalog",
#>   "id": "environmental-data",
#>   "stac_version": "1.1.0",
#>   "description": "A collection of environmental data",
#>   "links": [
#>     {
#>       "rel": "root",
#>       "href": "./catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     },
#>     {
#>       "rel": "item",
#>       "href": "./temperature/temperature.json",
#>       "type": "application/geo+json"
#>     },
#>     {
#>       "rel": "self",
#>       "href": "/tmp/Rtmp9ekDn1/py-stac/catalog.json",
#>       "type": "application/json"
#>     }
#>   ],
#>   "title": "Environmental Data Catalog"
#> }
```

#### Item JSON

``` r

r_item <- jsonlite::read_json(file.path(r_path, "temperature", "temperature.json"))
py_item <- jsonlite::read_json(file.path(py_path, "temperature", "temperature.json"))

jsonlite::toJSON(r_item, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Feature",
#>   "stac_version": "1.1.0",
#>   "id": "temperature",
#>   "geometry": {
#>     "type": "Point",
#>     "coordinates": [
#>       -122.45,
#>       54.34
#>     ]
#>   },
#>   "properties": {
#>     "datetime": "2023-07-06T08:00:00Z"
#>   },
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "./temperature.json",
#>       "type": "application/geo+json"
#>     },
#>     {
#>       "rel": "parent",
#>       "href": "../catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "../catalog.json",
#>       "type": "application/json"
#>     }
#>   ],
#>   "assets": {},
#>   "bbox": [
#>     -125,
#>     50,
#>     -120,
#>     55
#>   ]
#> }
jsonlite::toJSON(py_item, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Feature",
#>   "stac_version": "1.1.0",
#>   "stac_extensions": [],
#>   "id": "temperature",
#>   "geometry": {
#>     "type": "Point",
#>     "coordinates": [
#>       [
#>         -122.45,
#>         54.34
#>       ]
#>     ]
#>   },
#>   "bbox": [
#>     -125,
#>     50,
#>     -120,
#>     55
#>   ],
#>   "properties": {
#>     "datetime": "2023-07-06T08:00:00Z"
#>   },
#>   "links": [
#>     {
#>       "rel": "root",
#>       "href": "../catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     },
#>     {
#>       "rel": "parent",
#>       "href": "../catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     }
#>   ],
#>   "assets": {}
#> }
```

### Assets

The item assets are functionally equivalent, with the same fields and
values.

``` r

catalog <- stac_catalog(
  id = "environmental-data",
  description = "A collection of environmental data",
  title = "Environmental Data Catalog"
)

item <- stac_item(
  id = "temperature",
  geometry = list(
    type = "Point",
    coordinates = c(-122.45, 54.34)
  ),
  bbox = c(-125, 50, -120, 55),
  datetime = "2023-07-06T08:00:00Z"
)

asset <- stac_asset(
  href = "https://example.com/temperature.tif",
  title = "Temperature GeoTIFF",
  description = "A GeoTIFF file containing temperature data.",
  type = "image/tiff; application=geotiff"
)

item <- item |> 
  add_asset("temperature", asset)

catalog <- catalog |> 
  add_item(item)
```

``` r

asset_py <- pystac$Asset(
  href = "https://example.com/temperature.tif",
  title = "Temperature GeoTIFF",
  description = "A GeoTIFF file containing temperature data.",
  media_type = "image/tiff; application=geotiff"
)

item_py$add_asset("temperature", asset_py)
```

Write the catalogs to disk again to include the asset and read the item
JSON:

``` r

write_stac(catalog, r_path, catalog_type = "relative", overwrite = TRUE)
#> STAC catalog written to: /tmp/Rtmp9ekDn1/r-stac
catalog_rjson <- jsonlite::read_json(file.path(r_path, "catalog.json"))

catalog_py$normalize_hrefs(py_path)
catalog_py$save(dest_href = py_path)
catalog_pyjson <- jsonlite::read_json(file.path(py_path, "catalog.json"))
```

Compare the asset in the resulting item JSON:

``` r

r_item <- jsonlite::read_json(file.path(r_path, "temperature", "temperature.json"))
py_item <- jsonlite::read_json(file.path(py_path, "temperature", "temperature.json"))

cat("R json output: \n")
#> R json output:
jsonlite::toJSON(r_item, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Feature",
#>   "stac_version": "1.1.0",
#>   "id": "temperature",
#>   "geometry": {
#>     "type": "Point",
#>     "coordinates": [
#>       -122.45,
#>       54.34
#>     ]
#>   },
#>   "properties": {
#>     "datetime": "2023-07-06T08:00:00Z"
#>   },
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "./temperature.json",
#>       "type": "application/geo+json"
#>     },
#>     {
#>       "rel": "parent",
#>       "href": "../catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "../catalog.json",
#>       "type": "application/json"
#>     }
#>   ],
#>   "assets": {
#>     "temperature": {
#>       "href": "https://example.com/temperature.tif",
#>       "title": "Temperature GeoTIFF",
#>       "description": "A GeoTIFF file containing temperature data.",
#>       "type": "image/tiff; application=geotiff"
#>     }
#>   },
#>   "bbox": [
#>     -125,
#>     50,
#>     -120,
#>     55
#>   ]
#> }

cat("\nPython json output: \n")
#> 
#> Python json output:
jsonlite::toJSON(py_item, pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Feature",
#>   "stac_version": "1.1.0",
#>   "stac_extensions": [],
#>   "id": "temperature",
#>   "geometry": {
#>     "type": "Point",
#>     "coordinates": [
#>       [
#>         -122.45,
#>         54.34
#>       ]
#>     ]
#>   },
#>   "bbox": [
#>     -125,
#>     50,
#>     -120,
#>     55
#>   ],
#>   "properties": {
#>     "datetime": "2023-07-06T08:00:00Z"
#>   },
#>   "links": [
#>     {
#>       "rel": "root",
#>       "href": "../catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     },
#>     {
#>       "rel": "parent",
#>       "href": "../catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     }
#>   ],
#>   "assets": {
#>     "temperature": {
#>       "href": "https://example.com/temperature.tif",
#>       "type": "image/tiff; application=geotiff",
#>       "title": "Temperature GeoTIFF",
#>       "description": "A GeoTIFF file containing temperature data."
#>     }
#>   }
#> }
```
