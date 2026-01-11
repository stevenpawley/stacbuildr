#' Create a STAC Collection
#'
#' @description
#' Creates a STAC (SpatioTemporal Asset Catalog) Collection object following the 
#' STAC specification version 1.1.0. A Collection extends the Catalog specification 
#' with additional metadata that helps enable discovery, including spatial and 
#' temporal extents, license information, and summaries of the data.
#'
#' @param id (character, required) Identifier for the Collection. Must be unique 
#'   across all collections in the root catalog. Should contain only alphanumeric 
#'   characters, hyphens, and underscores.
#' @param description (character, required) Detailed multi-line description to 
#'   fully explain the Collection. CommonMark 0.29 syntax may be used for rich 
#'   text representation. This should provide comprehensive information about the 
#'   collection's contents, purpose, and scope.
#' @param license (character, required) Collection's license(s) as a 
#'   [SPDX License identifier](https://spdx.org/licenses/), `"various"`, or 
#'   `"other"`. If the collection includes data with multiple different licenses, 
#'   use `"various"` and add a link for each license. In STAC 1.1.0, `"proprietary"` 
#'   is deprecated in favor of `"other"`. Examples: `"CC-BY-4.0"`, `"MIT"`, 
#'   `"other"`.
#' @param extent (list, required) Spatial and temporal extents that describe the 
#'   bounds of all Items contained within this Collection. Must be a named list 
#'   with two elements:
#'   * `spatial`: A list with element `bbox` - a list of one or more bounding boxes. 
#'     Each bbox is a numeric vector of 4 or 6 numbers: `c(west, south, east, north)` 
#'     for 2D or `c(west, south, min_elev, east, north, max_elev)` for 3D. The 
#'     first bbox describes the overall spatial extent.
#'   * `temporal`: A list with element `interval` - a list of one or more time 
#'     intervals. Each interval is a character vector of length 2 with ISO 8601 
#'     datetime strings: `c("start", "end")`. Use `NULL` for open-ended intervals 
#'     (e.g., `c("2020-01-01T00:00:00Z", NULL)` for ongoing data).
#'   
#'   Use the helper function `stac_extent()` to create this structure easily.
#' @param title (character, optional) A short descriptive one-line title for the 
#'   Collection. Recommended for human-readable identification.
#' @param stac_version (character, optional) The STAC version the Collection 
#'   implements. Defaults to `"1.1.0"`.
#' @param type (character, optional) Must be set to `"Collection"`. Defaults to 
#'   `"Collection"`.
#' @param stac_extensions (character vector, optional) A list of extension 
#'   identifiers (URIs) that the Collection implements. Common extensions include 
#'   Item Assets, Version, Scientific Citation, and more. Each should be a full 
#'   URI to the extension's JSON schema. Default is `NULL`.
#' @param keywords (character vector, optional) List of keywords describing the 
#'   Collection. Helps with discovery and categorization.
#' @param providers (list, optional) A list of Provider objects. Each provider 
#'   should be a list with fields: `name` (required), `description`, `roles` 
#'   (e.g., "producer", "licensor", "processor", "host"), and `url`. Use the 
#'   helper function `stac_provider()` to create providers.
#' @param links (list, optional) An array of Link objects. Common link relations 
#'   for Collections include `"self"`, `"root"`, `"parent"`, `"item"`, `"child"`, 
#'   and `"license"`. Note that while Catalogs require at least one item or child 
#'   link, this is not required for Collections (but recommended). Defaults to an 
#'   empty list.
#' @param summaries (list, optional) A map of property summaries that describe the 
#'   range of values for properties found in the Items of this Collection. Strongly 
#'   recommended. Each property can be summarized as an array of unique values, a 
#'   range (with `minimum` and `maximum`), or a JSON Schema. Common properties to 
#'   summarize include `"datetime"`, `"platform"`, `"instruments"`, `"gsd"`, 
#'   `"eo:bands"`, etc. Use `stac_summaries()` helper to create this.
#' @param assets (list, optional) Dictionary of asset objects that can be downloaded 
#'   at the Collection level (not Item-specific assets). This is for assets that 
#'   apply to the entire collection, such as preview images or documentation. 
#'   For describing what assets are available in Items, use the Item Assets extension.
#' @param conformsTo (character vector, optional) A list of URIs declaring conformance 
#'   to STAC API specifications or other standards. Introduced in STAC 1.1.0.
#' @param ... Additional fields to include in the collection. This allows for custom 
#'   extensions or additional metadata beyond the core specification.
#'
#' @details
#' ## Required Fields
#' The STAC Collection specification requires these fields:
#' * `type`: Must be "Collection"
#' * `stac_version`: STAC specification version (currently "1.1.0")
#' * `id`: Unique identifier for the collection
#' * `description`: Detailed description of the collection
#' * `license`: License identifier
#' * `extent`: Spatial and temporal extents (both required)
#' * `links`: Array of link objects (can be empty)
#'
#' ## Recommended Fields
#' * `title`: Short, human-readable title
#' * `keywords`: Keywords for discovery
#' * `providers`: Information about data providers
#' * `summaries`: Summaries of Item properties
#'
#' ## Extent Structure
#' The extent object must contain both `spatial` and `temporal` extents:
#' 
#' ```r
#' extent = list(
#'   spatial = list(
#'     bbox = list(
#'       c(-180, -90, 180, 90)  # Overall spatial extent
#'     )
#'   ),
#'   temporal = list(
#'     interval = list(
#'       c("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z")
#'     )
#'   )
#' )
#' ```
#'
#' ## License Values in STAC 1.1.0
#' The license field was updated in STAC 1.1.0:
#' * Use SPDX identifiers when possible (e.g., "CC-BY-4.0", "MIT")
#' * Use `"other"` for custom/proprietary licenses (replaces deprecated "proprietary")
#' * Use `"various"` when the collection contains data with multiple licenses
#' * When using `"other"` or `"various"`, add license link(s) in the links array
#'
#' ## Summaries
#' Summaries help users understand the range of values in the collection without 
#' inspecting all Items. Three formats are supported:
#' * Array of unique values: `list(platform = c("landsat-8", "landsat-9"))`
#' * Range with min/max: `list(gsd = list(minimum = 15, maximum = 30))`
#' * JSON Schema: For complex validation rules
#'
#' @return An object of class `c("stac_collection", "stac_catalog", "list")` 
#'   containing the collection metadata. The object can be converted to JSON using 
#'   `jsonlite::toJSON()` or written to disk using `write_stac()`.
#'
#' @seealso 
#' * [stac_catalog()] for creating STAC Catalogs
#' * [stac_item()] for creating STAC Items
#' * [stac_extent()] for creating extent objects
#' * [stac_provider()] for creating provider objects
#' * [stac_summaries()] for creating summaries
#' * [add_link()] for adding links to collections
#'
#' @references
#' STAC Collection Specification: 
#' \url{https://github.com/radiantearth/stac-spec/blob/master/collection-spec/collection-spec.md}
#'
#' @examples
#' # Basic collection with minimal required fields
#' collection <- stac_collection(
#'   id = "landsat-8-c2-l2",
#'   description = "Landsat 8 Collection 2 Level-2 Surface Reflectance",
#'   license = "CC0-1.0",
#'   extent = list(
#'     spatial = list(bbox = list(c(-180, -90, 180, 90))),
#'     temporal = list(interval = list(c("2013-04-11T00:00:00Z", NULL)))
#'   )
#' )
#'
#' # Collection with all recommended fields
#' collection <- stac_collection(
#'   id = "sentinel-2-l2a",
#'   title = "Sentinel-2 Level-2A",
#'   description = paste(
#'     "Sentinel-2 Level-2A provides Bottom-Of-Atmosphere (BOA) reflectance",
#'     "images derived from the associated Level-1C products."
#'   ),
#'   license = "proprietary",
#'   extent = stac_extent(
#'     spatial_bbox = list(c(-180, -90, 180, 90)),
#'     temporal_interval = list(c("2015-06-27T00:00:00Z", NULL))
#'   ),
#'   keywords = c("sentinel", "esa", "msi", "copernicus", "earth observation"),
#'   providers = list(
#'     stac_provider(
#'       name = "ESA",
#'       roles = c("producer", "licensor"),
#'       url = "https://earth.esa.int/web/guest/home"
#'     )
#'   ),
#'   summaries = list(
#'     platform = c("sentinel-2a", "sentinel-2b"),
#'     instruments = c("msi"),
#'     gsd = c(10, 20, 60),
#'     `eo:bands` = list(
#'       list(name = "B01", common_name = "coastal", center_wavelength = 0.443),
#'       list(name = "B02", common_name = "blue", center_wavelength = 0.490),
#'       list(name = "B03", common_name = "green", center_wavelength = 0.560)
#'     )
#'   )
#' )
#'
#' # Add links
#' collection <- collection |>
#'   add_self_link("https://example.com/collections/sentinel-2-l2a.json") |>
#'   add_root_link("https://example.com/catalog.json") |>
#'   add_link(
#'     rel = "license",
#'     href = "https://sentinel.esa.int/documents/247904/690755/Sentinel_Data_Legal_Notice",
#'     type = "text/html",
#'     title = "Sentinel Data Terms and Conditions"
#'   )
#'
#' # Collection with multiple licenses
#' multi_license_collection <- stac_collection(
#'   id = "mixed-sources",
#'   description = "Collection with data from multiple sources with different licenses",
#'   license = "various",
#'   extent = stac_extent(
#'     spatial_bbox = list(c(-120, 30, -110, 40)),
#'     temporal_interval = list(c("2020-01-01T00:00:00Z", "2023-12-31T23:59:59Z"))
#'   )
#' ) |>
#'   add_link("license", "https://creativecommons.org/licenses/by/4.0/", 
#'            title = "CC-BY-4.0 for Landsat data") |>
#'   add_link("license", "https://example.com/custom-license.txt",
#'            title = "Custom license for commercial data")
#'
#' # Convert to JSON
#' collection_json <- jsonlite::toJSON(collection, auto_unbox = TRUE, pretty = TRUE)
#' cat(collection_json)
#'
#' @export
stac_collection <- function(id,
                           description,
                           license,
                           extent,
                           title = NULL,
                           stac_version = "1.1.0",
                           type = "Collection",
                           stac_extensions = NULL,
                           keywords = NULL,
                           providers = NULL,
                           links = list(),
                           summaries = NULL,
                           assets = NULL,
                           conformsTo = NULL,
                           ...) {
  
  # Validate required arguments
  if (missing(id) || is.null(id) || nchar(id) == 0) {
    stop("'id' is required and must be a non-empty string")
  }
  
  if (missing(description) || is.null(description) || nchar(description) == 0) {
    stop("'description' is required and must be a non-empty string")
  }
  
  if (missing(license) || is.null(license) || nchar(license) == 0) {
    stop("'license' is required and must be a non-empty string")
  }
  
  if (missing(extent) || is.null(extent)) {
    stop("'extent' is required")
  }
  
  # Validate extent structure
  if (!is.list(extent) || 
      !all(c("spatial", "temporal") %in% names(extent))) {
    stop("'extent' must be a list with 'spatial' and 'temporal' elements")
  }
  
  if (!is.list(extent$spatial) || !"bbox" %in% names(extent$spatial)) {
    stop("'extent$spatial' must be a list with a 'bbox' element")
  }
  
  if (!is.list(extent$temporal) || !"interval" %in% names(extent$temporal)) {
    stop("'extent$temporal' must be a list with an 'interval' element")
  }
  
  # Build the collection object with required fields
  collection <- list(
    type = type,
    stac_version = stac_version,
    id = id,
    description = description,
    license = license,
    extent = extent
  )
  
  # Add optional fields if provided (in spec order)
  if (!is.null(title)) {
    collection$title <- title
  }
  
  if (!is.null(keywords) && length(keywords) > 0) {
    collection$keywords <- keywords
  }
  
  if (!is.null(providers) && length(providers) > 0) {
    collection$providers <- providers
  }
  
  if (!is.null(stac_extensions) && length(stac_extensions) > 0) {
    collection$stac_extensions <- stac_extensions
  }
  
  # Add links (required field, but can be empty)
  collection$links <- links
  
  # Add optional Collection-specific fields
  if (!is.null(summaries) && length(summaries) > 0) {
    collection$summaries <- summaries
  }
  
  if (!is.null(assets) && length(assets) > 0) {
    collection$assets <- assets
  }
  
  if (!is.null(conformsTo) && length(conformsTo) > 0) {
    collection$conformsTo <- conformsTo
  }
  
  # Add any extra fields from ...
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    collection <- c(collection, extra_fields)
  }
  
  # Set class and return (note: Collection is also a Catalog)
  structure(
    collection,
    class = c("stac_collection", "stac_catalog", "list")
  )
}


#' Create a STAC Extent Object
#'
#' @description
#' Helper function to create a properly formatted extent object for STAC Collections.
#'
#' @param spatial_bbox List of bounding boxes. Each bbox should be a numeric vector 
#'   of 4 values `c(west, south, east, north)` or 6 values for 3D 
#'   `c(west, south, min_elev, east, north, max_elev)`. The first bbox is the 
#'   overall extent.
#' @param temporal_interval List of time intervals. Each interval should be a 
#'   character vector of length 2: `c("start", "end")`. Use `NULL` for open-ended 
#'   intervals. Times should be in ISO 8601 format.
#'
#' @return A list with `spatial` and `temporal` elements formatted for STAC Collections.
#'
#' @examples
#' # Simple global extent
#' extent <- stac_extent(
#'   spatial_bbox = list(c(-180, -90, 180, 90)),
#'   temporal_interval = list(c("2020-01-01T00:00:00Z", "2020-12-31T23:59:59Z"))
#' )
#'
#' # Open-ended temporal extent (ongoing collection)
#' extent <- stac_extent(
#'   spatial_bbox = list(c(-120, 30, -110, 40)),
#'   temporal_interval = list(c("2015-01-01T00:00:00Z", NULL))
#' )
#'
#' # Multiple spatial extents (e.g., disjoint regions)
#' extent <- stac_extent(
#'   spatial_bbox = list(
#'     c(-180, -90, 180, 90),  # Overall extent
#'     c(-120, 30, -110, 40),  # Western US
#'     c(-10, 35, 5, 45)       # Western Europe
#'   ),
#'   temporal_interval = list(c("2020-01-01T00:00:00Z", "2023-12-31T23:59:59Z"))
#' )
#'
#' @export
stac_extent <- function(spatial_bbox, temporal_interval) {
  list(
    spatial = list(bbox = spatial_bbox),
    temporal = list(interval = temporal_interval)
  )
}


#' Create a STAC Provider Object
#'
#' @description
#' Helper function to create a properly formatted provider object for STAC Collections.
#'
#' @param name (character, required) The name of the organization or individual.
#' @param description (character, optional) Description of the provider.
#' @param roles (character vector, optional) Roles of the provider. Common values: 
#'   "producer", "licensor", "processor", "host".
#' @param url (character, optional) Homepage URL for the provider.
#'
#' @return A list representing a STAC Provider.
#'
#' @examples
#' provider <- stac_provider(
#'   name = "USGS",
#'   description = "United States Geological Survey",
#'   roles = c("producer", "licensor", "host"),
#'   url = "https://www.usgs.gov"
#' )
#'
#' @export
stac_provider <- function(name, 
                         description = NULL, 
                         roles = NULL, 
                         url = NULL) {
  provider <- list(name = name)
  
  if (!is.null(description)) provider$description <- description
  if (!is.null(roles)) provider$roles <- roles
  if (!is.null(url)) provider$url <- url
  
  provider
}


#' Create STAC Summaries
#'
#' @description
#' Helper function to create property summaries for STAC Collections. Summaries 
#' describe the range of values for properties in the collection's Items.
#'
#' @param ... Named arguments where each name is a property and the value is either:
#'   * A vector of unique values
#'   * A list with `minimum` and `maximum` elements
#'   * A nested list for complex properties
#'
#' @return A list of property summaries.
#'
#' @examples
#' summaries <- stac_summaries(
#'   platform = c("landsat-8", "landsat-9"),
#'   instruments = c("oli", "tirs"),
#'   gsd = list(minimum = 15, maximum = 30),
#'   `eo:bands` = list(
#'     list(name = "B1", common_name = "coastal"),
#'     list(name = "B2", common_name = "blue")
#'   )
#' )
#'
#' @export
stac_summaries <- function(...) {
  summaries <- list(...)
  summaries
}


