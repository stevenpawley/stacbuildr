# Comparison with PySTAC

``` r

library(stacbuildr)
library(reticulate)
py_require("pystac")
```

## Comparison with PySTAC

Basic catalog:

``` r

catalog <- stac_catalog(
  id = "environmental-data",
  description = "A collection of environmental data",
  title = "Environmental Data Catalog"
)

jsonlite::toJSON(as.list(catalog), pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Catalog",
#>   "stac_version": "1.1.0",
#>   "id": "environmental-data",
#>   "description": "A collection of environmental data",
#>   "title": "Environmental Data Catalog",
#>   "links": []
#> }
```

``` r

pystac <- import("pystac")
#> Downloading uv...Done!

catalog_py <- pystac$Catalog(
  id = "environmental-data",
  description = "A collection of environmental data",
  title = "Environmental Data Catalog"
)

jsonlite::toJSON(catalog_py$to_dict(), pretty = TRUE, auto_unbox = TRUE)
#> {
#>   "type": "Catalog",
#>   "id": "environmental-data",
#>   "stac_version": "1.1.0",
#>   "description": "A collection of environmental data",
#>   "links": [],
#>   "title": "Environmental Data Catalog"
#> }
```

Items

``` r

item <- stac_item(
  id = "environmental-data/temperature",
  geometry = list(
    type = "Point",
    coordinates = c(-122.45, 54.34)
  ),
  bbox = c(-125, 50, -120, 55),
  datetime = "2023-07-06T08:00:00Z"
)

catalog_with_item <- catalog |>
  add_self_link(normalizePath("~/catalog.json")) |>
  add_root_link(normalizePath("~/catalog.json")) |>
  add_item(item)
#> Warning in normalizePath("~/catalog.json"):
#> path[1]="/home/runner/catalog.json": No such file or directory
#> Warning in normalizePath("~/catalog.json"):
#> path[1]="/home/runner/catalog.json": No such file or directory

r_json <- jsonlite::toJSON(as.list(catalog_with_item), pretty = TRUE, auto_unbox = TRUE)
r_json
#> {
#>   "type": "Catalog",
#>   "stac_version": "1.1.0",
#>   "id": "environmental-data",
#>   "description": "A collection of environmental data",
#>   "title": "Environmental Data Catalog",
#>   "links": [
#>     {
#>       "rel": "self",
#>       "href": "/home/runner/catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "root",
#>       "href": "/home/runner/catalog.json",
#>       "type": "application/json"
#>     },
#>     {
#>       "rel": "item",
#>       "href": "./environmental-data/temperature/environmental-data/temperature.json",
#>       "type": "application/geo+json"
#>     }
#>   ]
#> }
```

``` r

item_py <- pystac$Item(
  id = "environmental-data/temperature",
  geometry = list(
    type = "Point",
    coordinates = c(-122.45, 54.34)
  ),
  bbox = c(-125, 50, -120, 55),
  datetime = "2023-07-06T08:00:00Z",
  properties = list()
)

catalog_py$add_item(item_py)
#> <Link rel=item target=<Item id=environmental-data/temperature>>
catalog_py$normalize_hrefs("/Users/stevenpawley/catalog.json")

py_json <- jsonlite::toJSON(catalog_py$to_dict(), pretty = TRUE, auto_unbox = TRUE)
py_json
#> {
#>   "type": "Catalog",
#>   "id": "environmental-data",
#>   "stac_version": "1.1.0",
#>   "description": "A collection of environmental data",
#>   "links": [
#>     {
#>       "rel": "root",
#>       "href": "/Users/stevenpawley/catalog.json",
#>       "type": "application/json",
#>       "title": "Environmental Data Catalog"
#>     },
#>     {
#>       "rel": "item",
#>       "href": "/Users/stevenpawley/environmental-data/temperature/environmental-data/temperature.json",
#>       "type": "application/geo+json"
#>     },
#>     {
#>       "rel": "self",
#>       "href": "/Users/stevenpawley/catalog.json",
#>       "type": "application/json"
#>     }
#>   ],
#>   "title": "Environmental Data Catalog"
#> }
```

``` r

# test outputs are the same
stopifnot(all(
  names(jsonlite::parse_json(py_json)) %in%
    names(jsonlite::parse_json(r_json))
))

stopifnot(
  length(jsonlite::parse_json(py_json)$links) == length(jsonlite::parse_json(r_json)$links)
)
```
