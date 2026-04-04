devtools::load_all()
library(jsonvalidate)

# Common catalog parameters
catalog_id <- "test-catalog"
catalog_title <- "Test Catalog"
catalog_description <- "A test catalog for validation"

# Create R catalog
r_catalog <- stac_catalog(
  id = catalog_id,
  description = catalog_description,
  title = catalog_title
)

r_dir <- tempfile("r_stac_")
write_stac(r_catalog, r_dir)

json_validate(
  file.path(r_dir, "catalog.json"),
  schema = "inst/schema/catalog-spec/json-schema/catalog.json"
)
