#' stacbuildr: Build SpatioTemporal Asset Catalogs (STAC) in R
#'
#' @description
#' `stacbuildr` provides functions for constructing, validating, and writing
#' STAC Catalogs, Collections, and Items, including support for common STAC
#' extensions (Raster, EO, Classification, Scientific).
#'
#' ## Object Types
#'
#' The package uses two kinds of objects: **S7 classes** for the core STAC
#' structures, and **plain lists** for lightweight sub-objects.
#'
#' ### S7 Classes (use `@` to access properties)
#'
#' The primary STAC document types and `raster_band` are S7 objects. Use the
#' `@` operator to read or modify their properties:
#'
#' | Constructor | Class | Example access |
#' | --- | --- | --- |
#' | [stac_item()] | `stac_item` | `item@id`, `item@assets` |
#' | [stac_catalog()] | `stac_catalog` | `catalog@title` |
#' | [stac_collection()] | `stac_collection` | `collection@description` |
#' | [raster_band()] | `raster_band` | `band@data_type`, `band@scale` |
#'
#' ### Plain Lists (use `$` to access fields)
#'
#' Helper constructors return ordinary R lists. These are embedded inside S7
#' objects but are not S7 classes themselves:
#'
#' | Constructor | Typically used in |
#' | --- | --- |
#' | [stac_asset()] | `item@assets` |
#' | [raster_statistics()] | `band@statistics` |
#' | [raster_histogram()] | `band@histogram` |
#' | [eo_band()] | asset `"eo:bands"` field |
#' | [stac_provider()] | `collection@providers` |
#' | [stac_extent()] | `collection@extent` |
#' | [stac_summaries()] | `collection@summaries` |
#' | [classification_class()] | classification extension |
#' | [classification_bitfield()] | classification extension |
#' | [scientific_publication()] | scientific extension |
#'
#' ## Printing
#'
#' Catalogs, Collections and Items print a coloured summary. Fields that hold
#' more than one value (assets, links, properties, children, items,
#' extensions, providers, summaries) are shown as collapsed sections marked
#' with a `▸` arrow, listing a count and a short preview. Expand them with
#' the `expand` argument:
#'
#' ```r
#' print(item)                          # everything collapsed
#' print(item, expand = TRUE)           # expand every section
#' print(item, expand = c("assets"))    # expand only the assets
#' ```
#'
#' Two options change the defaults:
#'
#' * `stacbuildr.print.expand` - the default value of `expand`, e.g.
#'   `options(stacbuildr.print.expand = TRUE)` to always print in full.
#' * `stacbuildr.print.hint` - set to `FALSE` to suppress the footer that
#'   reports how many sections were collapsed.
#'
#' Extension metadata is shown wherever it is stored: item-level fields such
#' as `"sci:doi"` or `"eo:cloud_cover"` appear in the `properties` section,
#' asset-level fields such as `"eo:bands"` or `"raster:bands"` appear under
#' the asset that carries them, and the declared schema URIs are listed in the
#' `extensions` section by name and version. Arrays of objects are summarised
#' by the name of each object, e.g. `eo:bands [B4, B5]`.
#'
#' Colour and the box-drawing characters come from \pkg{cli} and are dropped
#' automatically when the console does not support them (log files, knitr,
#' `R CMD check`). Use `options(cli.num_colors = 1)` to turn colour off.
#'
#' ## Typical Workflow
#'
#' ```r
#' library(stacbuildr)
#'
#' # 1. Create a STAC Item (S7 object)
#' item <- stac_item(
#'   id       = "my-scene",
#'   geometry = list(type = "Point", coordinates = c(-105, 40)),
#'   bbox     = c(-105, 40, -105, 40),
#'   datetime = "2024-06-01T00:00:00Z"
#' )
#'
#' # 2. Add an asset (plain list embedded in the item)
#' item <- add_asset(
#'   item,
#'   key   = "B4",
#'   href  = "https://example.com/B4.tif",
#'   type  = "image/tiff; application=geotiff",
#'   roles = "data"
#' )
#'
#' # 3. Describe the band with the Raster extension (S7 raster_band)
#' band <- raster_band(
#'   data_type          = "uint16",
#'   nodata             = 0,
#'   scale              = 0.0001,
#'   spatial_resolution = 30,
#'   statistics         = raster_statistics(minimum = 1, maximum = 10000)
#' )
#'
#' item <- add_raster_extension(item, bands = list(band), asset_key = "B4")
#'
#' # 4. Access S7 properties with @
#' item@id
#' band@scale
#'
#' # 5. Write to disk
#' write_item(item, "my-scene.json")
#' ```
#'
#' @seealso
#' * [stac_item()], [stac_catalog()], [stac_collection()] for creating STAC
#'   documents
#' * [write_item()], [write_catalog()], [write_stac()] for writing to disk
#' * [read_stac()] for reading STAC JSON files
#' * [validate_stac()] for validating against the STAC specification
#'
#' @references
#' STAC Specification: \url{https://stacspec.org}
#'
#' @importFrom stats setNames
#' @importFrom utils tail
#' @docType package
#' @name stacbuildr-package
#' @aliases stacbuildr
"_PACKAGE"
