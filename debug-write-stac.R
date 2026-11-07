# Step-through playground for write_stac().

pkgload::load_all(quiet = TRUE)

out_dir <- file.path(tempdir(), "stac-debug")

# --- Build a small tree ------------------------------------------------------
# my-catalog/
#   catalog.json
#   terrain/            <- child Collection
#     collection.json
#     dem/              <- item
#       dem.json
#   ortho/              <- child Catalog (nested one level deeper)
#     catalog.json
#     rgb/              <- item
#       rgb.json

extent <- stac_extent(
  spatial_bbox = list(c(-105.0, 39.9, -104.9, 40.0)),
  temporal_interval = list(list("2020-01-01T00:00:00Z", NULL))
)

dem <- stac_item(
  id = "dem",
  geometry = list(type = "Point", coordinates = c(-104.95, 39.95)),
  bbox = c(-105.0, 39.9, -104.9, 40.0),
  datetime = "2020-06-01T00:00:00Z",
  properties = list(title = "Digital elevation model")
)
dem <- add_asset(dem, "data", href = "/tmp/data/dem.tif", type = "image/tiff")

rgb <- stac_item(
  id = "rgb",
  geometry = list(type = "Point", coordinates = c(-104.95, 39.95)),
  bbox = c(-105.0, 39.9, -104.9, 40.0),
  datetime = "2020-06-01T00:00:00Z",
  properties = list(title = "Orthoimage")
)
rgb <- add_asset(rgb, "data", href = "https://example.com/rgb.tif")

terrain <- stac_collection(
  id = "terrain",
  description = "Terrain datasets",
  license = "CC-BY-4.0",
  extent = extent
)
terrain <- add_item(terrain, dem)

ortho <- stac_catalog(id = "ortho", description = "Imagery")
ortho <- add_item(ortho, rgb)

root <- stac_catalog(id = "my-catalog", description = "Debug catalog")
root <- add_child(root, terrain)
root <- add_child(root, ortho)

# --- Write -------------------------------------------------------------------
# Good breakpoints in R/write.R:
#   write_stac()               line ~86  - entry, before match.arg
#   write_catalog_recursive()  line ~275 - catalog_file choice
#   write_catalog_recursive()  line ~293 - root_href computation
#   write_catalog_recursive()  line ~299 - after update_catalog_links()
#   write_catalog_recursive()  line ~333 - before recursing into a child
#   write_catalog_recursive()  line ~365 - item link rewriting (absolute branch)
#   write_catalog_recursive()  line ~377 - item link rewriting (relative branch)
#   update_catalog_links()     line ~433 - self_href decision
#   make_relative_href()       line ~672 - asset path relativization
#
# Useful things to print at a breakpoint: catalog$id, path, depth, is_root,
# parent_href, root_href, catalog_type.

write_stac(root, out_dir, overwrite = TRUE)

# --- Inspect the result ------------------------------------------------------
# Switch catalog_type to "relative" or "absolute" (with a base_url) and re-run
# to see how every href changes.
list.files(out_dir, recursive = TRUE)

for (f in list.files(out_dir, pattern = "\\.json$", recursive = TRUE, full.names = TRUE)) {
  message("\n--- ", substring(f, nchar(out_dir) + 2), " ---")
  obj <- read_stac(f)
  for (lnk in obj$links) {
    message(sprintf("  %-10s %s", lnk$rel, lnk$href))
  }
  if (inherits(obj, "stac_item")) {
    for (nm in names(obj$assets)) {
      message(sprintf("  asset:%-4s %s", nm, obj$assets[[nm]]$href))
    }
  }
}
