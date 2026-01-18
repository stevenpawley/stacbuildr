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
#' A `self` link and a `root` link are strongly recommended.
#' Non-root Catalogs should include a `parent` link.
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

  catalog$links <- list()

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


#' Create a STAC link object
#'
#' @description
#' Creates a link object following the STAC specification. Links are used to
#' connect STAC resources (catalogs, collections, and items) and establish
#' relationships between them.
#'
#' @param rel (character, required) The link relation type. Common values include
#'   `"self"`, `"root"`, `"parent"`, `"child"`, `"item"`, `"collection"`,
#'   `"license"`, `"derived_from"`, and `"via"`. See the STAC specification
#'   for a complete list of relation types.
#' @param href (character, required) The URL or path to the linked resource.
#'   Can be absolute or relative.
#' @param type (character, optional) The media type of the linked resource.
#'   Common values include `"application/json"`, `"application/geo+json"`,
#'   and `"text/html"`. Default is `NULL`.
#' @param title (character, optional) A human-readable title for the link.
#'   Default is `NULL`.
#' @param method (character, optional) The HTTP method to use when following
#'   the link (e.g., `"GET"`, `"POST"`). Default is `NULL`.
#' @param headers (list or named vector, optional) HTTP headers to include
#'   when following the link. Default is `NULL`.
#' @param body (list, optional) The HTTP body to include when following the
#'   link (typically used with POST requests). Default is `NULL`.
#' @param merge (logical, optional) Whether to merge the link body with the
#'   current resource when following the link. Default is `FALSE`.
#'
#' @return A list representing a STAC link object with NULL values removed.
#'
#' @seealso
#' * [add_link()] for adding links to STAC objects
#' * [add_self_link()], [add_root_link()], [add_parent_link()] for convenience functions
#'
#' @references
#' STAC Link Object specification:
#' \url{https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md#link-object}
#'
#' @examples
#' # Create a simple link
#' link <- stac_link(
#'   rel = "self",
#'   href = "https://example.com/catalog.json"
#' )
#'
#' # Create a link with additional properties
#' link <- stac_link(
#'   rel = "child",
#'   href = "./child-catalog.json",
#'   type = "application/json",
#'   title = "Child Catalog"
#' )
#'
#' # Create a link with HTTP method and headers
#' link <- stac_link(
#'   rel = "search",
#'   href = "https://api.example.com/search",
#'   method = "POST",
#'   headers = list("Content-Type" = "application/json"),
#'   body = list(limit = 10)
#' )
#'
#' @keywords internal
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


#' Add a link to a STAC catalog
#'
#' @description
#' Adds a link object to a STAC Catalog, Collection, or Item. Links are used
#' to connect STAC resources and provide relationships between catalogs, collections,
#' and items.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param rel (character, required) The link relation type. Common values include
#'   `"self"`, `"root"`, `"parent"`, `"child"`, and `"item"`. See the STAC
#'   specification for a full list of relation types.
#' @param href (character, required) The URL or path to the linked resource.
#'   Can be absolute or relative.
#' @param ... Additional link properties passed to `stac_link()`, such as `type`,
#'   `title`, `method`, `headers`, `body`, or `merge`.
#'
#' @return The modified catalog object with the new link added.
#'
#' @seealso
#' * [add_self_link()] for adding a self link
#' * [add_root_link()] for adding a root link
#' * [add_parent_link()] for adding a parent link
#' * [add_child()] for adding a child catalog or collection
#'
#' @examples
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
#' # Add a self link
#' catalog <- add_link(
#'   catalog,
#'   rel = "self",
#'   href = "https://example.com/catalog.json",
#'   type = "application/json"
#' )
#'
#' # Add a related link with a title
#' catalog <- add_link(
#'   catalog,
#'   rel = "related",
#'   href = "https://example.com/metadata.html",
#'   type = "text/html",
#'   title = "Additional metadata"
#' )
#'
#' @export
add_link <- function(catalog, rel, href, ...) {
  new_link <- stac_link(rel = rel, href = href, ...)
  catalog$links <- c(catalog$links, list(new_link))
  catalog
}


#' Add a child catalog or collection
#'
#' @description
#' Adds a child STAC Catalog or Collection to a parent catalog by creating a
#' link with relation type `"child"`. The child resource can be another catalog
#' or a collection.
#'
#' @param catalog A STAC catalog or collection object to add the child to.
#' @param child A STAC catalog or collection object to add as a child.
#' @param href (character, optional) The URL or path to the child resource.
#'   If `NULL` (default), automatically generates a path using the pattern
#'   `"./<child_id>/catalog.json"`.
#' @param title (character, optional) A title for the link. If `NULL`, uses
#'   the child's `title` field if available.
#'
#' @return The modified parent catalog object with the child link added.
#'
#' @seealso
#' * [add_link()] for adding arbitrary links
#' * [add_item()] for adding STAC Items
#' * [stac_catalog()] for creating catalogs
#' * [stac_collection()] for creating collections
#'
#' @examples
#' parent <- stac_catalog(
#'   id = "parent-catalog",
#'   description = "Parent catalog"
#' )
#'
#' child <- stac_catalog(
#'   id = "child-catalog",
#'   title = "Child Catalog",
#'   description = "A child catalog"
#' )
#'
#' # Add child with automatic href generation
#' parent <- add_child(parent, child)
#'
#' # Add child with custom href and title
#' parent <- add_child(
#'   parent,
#'   child,
#'   href = "./children/custom-catalog.json",
#'   title = "Custom Child"
#' )
#'
#' @export
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


#' Add a self link to a STAC catalog
#'
#' @description
#' Adds a self link to a STAC Catalog, Collection, or Item. A self link provides
#' the absolute URL to the current resource and is strongly recommended by the
#' STAC specification.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param href (character, required) The absolute URL to the current resource.
#'
#' @return The modified catalog object with the self link added.
#'
#' @seealso
#' * [add_root_link()] for adding a root link
#' * [add_parent_link()] for adding a parent link
#' * [add_link()] for adding arbitrary links
#'
#' @examples
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
#' catalog <- add_self_link(catalog, "https://example.com/catalog.json")
#'
#' @export
add_self_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "self",
    href = href,
    type = "application/json"
  )
  catalog
}


#' Add a root link to a STAC catalog
#'
#' @description
#' Adds a root link to a STAC Catalog, Collection, or Item. A root link provides
#' the URL to the root catalog of the STAC hierarchy and is strongly recommended
#' by the STAC specification.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param href (character, required) The URL to the root catalog. Can be absolute
#'   or relative.
#'
#' @return The modified catalog object with the root link added.
#'
#' @seealso
#' * [add_self_link()] for adding a self link
#' * [add_parent_link()] for adding a parent link
#' * [add_link()] for adding arbitrary links
#'
#' @examples
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
#' catalog <- add_root_link(catalog, "https://example.com/catalog.json")
#'
#' @export
add_root_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "root",
    href = href,
    type = "application/json"
  )
  catalog
}


#' Add a parent link to a STAC catalog
#'
#' @description
#' Adds a parent link to a STAC Catalog, Collection, or Item. A parent link provides
#' the URL to the parent catalog or collection in the STAC hierarchy. Non-root
#' catalogs should include a parent link.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param href (character, required) The URL to the parent catalog or collection.
#'   Can be absolute or relative.
#'
#' @return The modified catalog object with the parent link added.
#'
#' @seealso
#' * [add_self_link()] for adding a self link
#' * [add_root_link()] for adding a root link
#' * [add_link()] for adding arbitrary links
#'
#' @examples
#' catalog <- stac_catalog(
#'   id = "child-catalog",
#'   description = "A child catalog"
#' )
#'
#' catalog <- add_parent_link(catalog, "../parent/catalog.json")
#'
#' @export
add_parent_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "parent",
    href = href,
    type = "application/json"
  )
  catalog
}
