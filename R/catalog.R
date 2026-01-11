#' Create a STAC Catalog
#'
#' @description
#' Creates a STAC (SpatioTemporal Asset Catalog) Catalog object following the
#' STAC specification version 1.1.0. A Catalog is a top-level organizational
#' structure that groups related Collections and Items, providing a hierarchical
#' structure for organizing geospatial assets.
#'
#' @param id (character, required) Identifier for the Catalog. Must be unique
#'   within the parent catalog if one exists. Should contain only alphanumeric
#'   characters, hyphens, and underscores.
#' @param description (character, required) Detailed multi-line description to
#'   fully explain the Catalog. CommonMark 0.29 syntax may be used for rich text
#'   representation. This field should provide comprehensive information about the
#'   catalog's contents, purpose, and scope.
#' @param title (character, optional) A short descriptive one-line title for the
#'   Catalog. Recommended for human-readable identification. If not provided,
#'   the `id` may be used for display purposes.
#' @param stac_version (character, optional) The STAC version the Catalog
#'   implements. Defaults to `"1.1.0"`. This field is required by the STAC
#'   specification.
#' @param type (character, optional) Must be set to `"Catalog"` for catalogs.
#'   Defaults to `"Catalog"`. For collections, this would be `"Collection"`.
#' @param stac_extensions (character vector, optional) A list of extension
#'   identifiers (URIs) that the Catalog implements. Extensions listed here must
#'   only contain extensions that extend the Catalog specification itself, not
#'   extensions for Items or Collections. Each extension should be a full URI to
#'   the extension's JSON schema. Default is `NULL` (no extensions).
#' @param links (list, optional) An array of Link objects relating this Catalog
#'   to other resources. A `self` link and a `root` link are strongly recommended.
#'   Non-root Catalogs should include a `parent` link. Use helper functions like
#'   `add_link()`, `add_child()`, or `add_item()` to populate this field after
#'   catalog creation. Defaults to an empty list.
#' @param conformsTo (character vector, optional) A list of URIs declaring
#'   conformance to STAC API specifications or other standards. Typically used
#'   when the catalog is served via an API. Introduced in STAC 1.1.0. Default
#'   is `NULL`.
#' @param ... Additional fields to include in the catalog. Any extra named
#'   arguments will be added to the catalog object. This allows for custom
#'   extensions or additional metadata beyond the core specification.
#'
#' @details
#' ## Required Fields
#' The STAC Catalog specification requires the following fields:
#' * `type`: Must be "Catalog"
#' * `stac_version`: STAC specification version (currently "1.1.0")
#' * `id`: Unique identifier for the catalog
#' * `description`: Detailed description of the catalog
#' * `links`: Array of link objects (can be empty initially)
#'
#' ## Recommended Fields
#' * `title`: Short, human-readable title
#'
#' ## Link Relations
#' Catalogs use links to connect to other STAC resources. Common link relation
#' types include:
#' * `root`: URL to the root STAC Catalog or Collection
#' * `self`: Absolute URL to the current catalog file
#' * `parent`: URL to the parent STAC Catalog or Collection
#' * `child`: URL to a child STAC Catalog or Collection
#' * `item`: URL to a STAC Item
#'
#' Use the helper functions `add_self_link()`, `add_root_link()`, `add_parent_link()`,
#' `add_child()`, and `add_item()` to manage links after creating the catalog.
#'
#' ## Extensions
#' STAC extensions provide additional fields and capabilities. When using
#' extensions at the catalog level, reference them in the `stac_extensions`
#' parameter with their full schema URI. Note that most extensions apply to
#' Items or Collections rather than Catalogs.
#'
#' @return An object of class `c("stac_catalog", "list")` containing the catalog
#'   metadata. The object can be converted to JSON using `jsonlite::toJSON()` or
#'   written to disk using `write_stac()`.
#'
#' @seealso
#' * [stac_collection()] for creating STAC Collections
#' * [stac_item()] for creating STAC Items
#' * [add_link()] for adding links to catalogs
#' * [add_child()] for adding child catalogs or collections
#' * [write_stac()] for writing catalogs to the filesystem
#'
#' @references
#' STAC Catalog Specification:
#' \url{https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md}
#'
#' @examples
#' # Create a basic catalog
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "A catalog of satellite imagery for environmental monitoring"
#' )
#'
#' # Create a catalog with all optional fields
#' catalog <- stac_catalog(
#'   id = "north-america-imagery",
#'   title = "North America Satellite Imagery",
#'   description = paste(
#'     "A comprehensive catalog of satellite imagery covering North America",
#'     "from various sensors including Landsat, Sentinel, and commercial providers.",
#'     "Data spans from 2013 to present."
#'   ),
#'   stac_version = "1.1.0"
#' )
#'
#' # Add links to the catalog
#' catalog <- catalog |>
#'   add_self_link("https://example.com/catalog.json") |>
#'   add_root_link("https://example.com/catalog.json")
#'
#' # Add child catalogs
#' landsat_catalog <- stac_catalog(
#'   id = "landsat",
#'   description = "Landsat satellite imagery"
#' )
#'
#' catalog <- add_child(
#'   catalog,
#'   landsat_catalog,
#'   href = "./landsat/catalog.json",
#'   title = "Landsat Imagery"
#' )
#'
#' # Create a catalog with a custom extension
#' catalog_with_version <- stac_catalog(
#'   id = "versioned-catalog",
#'   description = "A catalog with version tracking",
#'   stac_extensions = c(
#'     "https://stac-extensions.github.io/version/v1.2.0/schema.json"
#'   ),
#'   # Custom fields from the version extension
#'   version = "1.0.0",
#'   deprecated = FALSE
#' )
#'
#' # Convert to JSON
#' catalog_json <- jsonlite::toJSON(catalog, auto_unbox = TRUE, pretty = TRUE)
#' cat(catalog_json)
#'
#' @export
stac_catalog <- function(
  id,
  description,
  title = NULL,
  stac_version = "1.1.0",
  type = "Catalog",
  stac_extensions = NULL,
  links = list(),
  conformsTo = NULL,
  ...
) {
  # Build the catalog object
  catalog <- list(
    type = type,
    stac_version = stac_version,
    id = id,
    description = description
  )

  # Add optional fields if provided
  if (!is.null(title)) {
    catalog$title <- title
  }

  if (!is.null(stac_extensions) && length(stac_extensions) > 0) {
    catalog$stac_extensions <- stac_extensions
  }

  if (!is.null(conformsTo) && length(conformsTo) > 0) {
    catalog$conformsTo <- conformsTo
  }

  catalog$links <- links

  # Add any extra fields
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    catalog <- c(catalog, extra_fields)
  }

  structure(
    catalog,
    class = c("stac_catalog", "list")
  )
}

# Create a link object
stac_link <- function(
  rel,
  href,
  type = NULL,
  title = NULL,
  method = NULL,
  headers = NULL,
  body = NULL,
  merge = FALSE
) {
  link <- list(
    rel = rel,
    href = href
  )

  if (!is.null(type)) {
    link$type <- type
  }
  if (!is.null(title)) {
    link$title <- title
  }
  if (!is.null(method)) {
    link$method <- method
  }
  if (!is.null(headers)) {
    link$headers <- headers
  }
  if (!is.null(body)) {
    link$body <- body
  }
  if (merge) {
    link$merge <- merge
  }

  # Remove NULL values
  link[!sapply(link, is.null)]
}

# Add a link to a catalog
add_link <- function(catalog, rel, href, ...) {
  new_link <- stac_link(rel = rel, href = href, ...)
  catalog$links <- c(catalog$links, list(new_link))
  catalog
}

# Add a child catalog/collection
add_child <- function(catalog, child, href = NULL, title = NULL) {
  if (is.null(href)) {
    href = paste0("./", child$id, "/catalog.json")
  }

  catalog <- add_link(
    catalog,
    rel = "child",
    href = href,
    type = "application/json",
    title = title %||% child$title
  )

  catalog
}

# Add an item
add_item <- function(catalog, item, href = NULL) {
  if (is.null(href)) {
    href = paste0("./", item$id, ".json")
  }

  catalog <- add_link(
    catalog,
    rel = "item",
    href = href,
    type = "application/geo+json"
  )

  catalog
}

# Add self link
add_self_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "self",
    href = href,
    type = "application/json"
  )
  catalog
}

# Add root link
add_root_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "root",
    href = href,
    type = "application/json"
  )
  catalog
}

# Add parent link
add_parent_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "parent",
    href = href,
    type = "application/json"
  )
  catalog
}
