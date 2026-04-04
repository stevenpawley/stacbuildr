catalog_url <- "https://raw.githubusercontent.com/radiantearth/stac-spec/refs/heads/master/catalog-spec/json-schema/catalog.json"
collection_url <- "https://raw.githubusercontent.com/radiantearth/stac-spec/refs/heads/master/collection-spec/json-schema/collection.json"


download.file(catalog_url, destfile = "inst/schema//catalog.json")
download.file(collection_url, destfile = "inst/schema/collection.json")

# download all jsons from item-spec/json-schema
item_schema_url <- "https://raw.githubusercontent.com/radiantearth/stac-spec/refs/heads/master/item-spec/json-schema/"
item_schema_files <- c(
  "bands.json",
  "basics.json",
  "common.json",
  "data-values.json",
  "datetime.json",
  "instrument.json",
  "item.json",
  "licensing.json",
  "provider.json"
)

for (file in item_schema_files) {
  download.file(
    paste(item_schema_url, file, sep = "/"),
    destfile = paste0("inst/schema/", file)
  )
}
