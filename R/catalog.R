#' Create a STAC Catalog
#'
#' @description
#' Creates a STAC (SpatioTemporal Asset Catalog) Catalog object following the
#' STAC specification version 1.1.0. A Catalog is a top-level organizational
#' structure that groups related Collections and Items, providing a hierarchical
#' structure for organizing geospatial assets, making them indexable and
#' discoverable.
#'
#' @param id (character, required) Identifier for the Catalog. Must be unique
#'   within the parent catalog if one exists. Should contain only alphanumeric
#'   characters, hyphens, and underscores. This field is required by the STAC
#'   specification.
#' @param description (character, required) Detailed multi-line description to
#'   fully explain the Catalog. This field should provide comprehensive
#'   information about the catalog's contents, purpose, and scope. This field is
#'   required by the STAC specification.
#' @param title (character, optional) A short descriptive one-line title for the
#'   Catalog. Recommended for human-readable identification.
#' @param stac_version (character, required) The STAC version the Catalog
#'   implements. Defaults to `"1.1.0"`. This field is required by the STAC
#'   specification.
#' @param type (character, optional) Must be set to `"Catalog"` for catalogs.
#'   Defaults to `"Catalog"`. For collections, this would be `"Collection"`.
#'   This field is required by the STAC specification.
#' @param stac_extensions (character vector, optional) A list of extension
#'   URLs that the Catalog implements. Extensions listed here must
#'   only contain extensions that extend the Catalog specification itself, not
#'   extensions for Items or Collections. Each extension should be a full URI to
#'   the extension's JSON schema. Default is `NULL` (no extensions).
#' @param conformsTo (character vector, optional) A list of URIs declaring
#'   conformance to STAC API specifications or other standards. Typically used
#'   when the catalog is served via an API. Introduced in STAC 1.1.0. Default
#'   is `NULL`.
#' @param links (list, optional) Initial list of [stac_link()] objects or plain
#'   link lists. Plain lists are converted to S3 link objects. Links are
#'   typically managed via `add_link()`, `add_child()`, and related helpers.
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
#' Use the helper functions `add_self_link()`, `add_root_link()`,
#' `add_child()`, and `add_item()` to manage links after
#' creating the catalog. A `self` link and a `root` link are strongly
#' recommended. Non-root Catalogs should include a `parent` link.
#'
#' ## Extensions
#' STAC extensions provide additional fields and capabilities. When using
#' extensions at the catalog level, reference them in the `stac_extensions`
#' parameter with their full schema URI. Note that most extensions apply to
#' Items or Collections rather than Catalogs.
#'
#' @return An S3 object of class `stac_catalog` containing the catalog metadata.
#'   Convert to a plain list for JSON serialization with `as.list()`, or write
#'   directly to disk using `write_stac()`.
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
#'     "from various sensors including Landsat, Sentinel, and commercial",
#'     "providers. Data spans from 2013 to present."
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
#' catalog_json <- jsonlite::toJSON(as.list(catalog), auto_unbox = TRUE, pretty = TRUE)
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
  links = list(),
  ...
) {
  # Create list object as precursor to catalog
  object <- list(
    type = type,
    stac_version = stac_version,
    id = id,
    description = description,
    title = title,
    stac_extensions = stac_extensions,
    conformsTo = conformsTo,
    links = normalize_links(links),
    extra_fields = list(...)
  )

  # Validation
  check_single_character(object$id, "id")
  check_single_character(object$description, "description")
  check_single_character(
    object$title,
    "title",
    allow_null = TRUE,
    allow_empty = TRUE
  )
  check_single_character(object$stac_version, "stac_version")
  check_single_character(object$type, "type")
  check_character_vector(
    object$stac_extensions,
    "stac_extensions",
    allow_null = TRUE
  )
  check_character_vector(object$conformsTo, "conformsTo", allow_null = TRUE)
  # Links
  if (!is.list(object[["links"]])) {
    cli::cli_abort("links must be list.")
  }
  if (
    !all(vapply(object[["links"]], inherits, logical(1), what = "stac_link"))
  ) {
    cli::cli_abort(paste("links", "must contain only stac_link objects"))
  }
  # Extra fields
  if (!is.list(object[["extra_fields"]])) {
    cli::cli_abort("extra_fields must be list.")
  }
  # Type
  if (!object$type %in% c("Catalog", "Collection")) {
    cli::cli_abort(sprintf(
      "'type' must be 'Catalog' or 'Collection', got '%s'",
      object$type
    ))
  }

  # Assign class
  class(object) <- c("stac_catalog", "stac_object")
  return(object)
}


#' @exportS3Method
as.list.stac_catalog <- function(x, ...) {
  out <- list(
    type = x$type,
    stac_version = x$stac_version,
    id = x$id,
    description = x$description
  )
  if (!is.null(x$title)) {
    out$title <- x$title
  }
  if (
    !is.null(x$stac_extensions) &&
      length(x$stac_extensions) > 0
  ) {
    out$stac_extensions <- as.list(x$stac_extensions)
  }
  if (!is.null(x$conformsTo) && length(x$conformsTo) > 0) {
    out$conformsTo <- as_json_array(x$conformsTo)
  }
  out$links <- stac_json_value(x$links)
  if (length(x$extra_fields) > 0) {
    out <- c(out, x$extra_fields)
  }
  return(out)
}

#' Print a STAC Catalog
#'
#' @param x A `stac_catalog` object.
#' @param ... Ignored.
#' @param expand Controls the collapsible sections (marked with an arrow).
#'   Use `TRUE` to expand all of them, `FALSE` (the default) to collapse all, or
#'   a character vector of section names to expand only those, e.g.
#'   `c("links", "children")`. Defaults to the `stacbuildr.print.expand` option.
#' @noRd
#'
#' @exportS3Method
print.stac_catalog <- function(x, ..., expand = NULL) {
  stac_print_header(paste("STAC", x$type))
  stac_print_field("id", x$id, stac_style_id)

  if (!is.null(x$title)) {
    stac_print_field("title", x$title)
  }

  stac_print_field("stac_version", x$stac_version, stac_style_muted)
  stac_print_field("description", stac_truncate(x$description))

  extensions <- x$stac_extensions %||% character(0)
  children <- attr(x, "stac_children") %||% list()
  items <- attr(x, "stac_items") %||% list()

  collapsed <- c(
    if (length(extensions) > 0) {
      stac_print_section(
        "extensions",
        length(extensions),
        summary = stac_preview(stac_extension_names(extensions)),
        lines = function() {
          return(stac_extension_lines(extensions))
        },
        expanded = stac_expanded(expand, "extensions")
      )
    },
    stac_print_section(
      "links",
      length(x$links),
      summary = stac_preview(vapply(
        x$links,
        function(l) {
          return(l$rel)
        },
        character(1)
      )),
      lines = function() {
        return(stac_link_lines(x$links))
      },
      expanded = stac_expanded(expand, "links")
    ),
    stac_print_section(
      "children",
      length(children),
      summary = stac_preview(names(children)),
      lines = function() {
        return(stac_child_lines(children))
      },
      expanded = stac_expanded(expand, "children")
    ),
    if (length(items) > 0) {
      stac_print_section(
        "items",
        length(items),
        summary = stac_preview(vapply(
          items,
          function(i) {
            return(i$id)
          },
          character(1)
        )),
        lines = function() {
          return(stac_item_lines(items))
        },
        expanded = stac_expanded(expand, "items")
      )
    }
  )

  stac_print_hint(sum(collapsed))

  return(invisible(x))
}


#' Create a STAC link object
#'
#' @description
#' Creates a link object following the STAC specification. Links are used to
#' connect STAC resources (catalogs, collections, and items) and establish
#' relationships between them.
#'
#' @param rel (character, required) The link relation type. Common values
#'   include `"self"`, `"root"`, `"parent"`, `"child"`, `"item"`,
#'   `"collection"`, `"license"`, `"derived_from"`, and `"via"`. See the STAC
#'   specification for a complete list of relation types.
#' @param href (character, required) The URL or path to the linked resource. Can
#'   be absolute or relative.
#' @param type (character, optional) The media type of the linked resource.
#'   Common values include `"application/json"`, `"application/geo+json"`, and
#'   `"text/html"`. Default is `NULL`.
#' @param title (character, optional) A human-readable title for the link.
#'   Default is `NULL`.
#' @param method (character, optional) The HTTP method to use when following the
#'   link (e.g., `"GET"`, `"POST"`). Default is `NULL`.
#' @param headers (list or named vector, optional) HTTP headers to include when
#'   following the link. Default is `NULL`.
#' @param body (list, optional) The HTTP body to include when following the link
#'   (typically used with POST requests). Default is `NULL`.
#' @param merge (logical, optional) Whether to merge the link body with the
#'   current resource when following the link. Default is `FALSE`.
#' @param ... Additional link fields retained in `link$extra_fields` and
#'   included during JSON serialization.
#'
#' @return A `stac_link` S3 object. Access fields with `$`, for example
#'   `link$rel` and `link$href`.
#'
#' @seealso
#' * [add_link()] for adding links to STAC objects
#' * [add_self_link()], [add_root_link()] for convenience functions
#'
#' @references
#' STAC Link Object specification:
#' \url{https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md#link-object}
#'
#' @examples
#' link <- stac_link("self", "https://example.com/catalog.json")
#' link$rel
#' link$href
#'
#' @export
stac_link <- function(
  rel,
  href,
  type = NULL,
  title = NULL,
  method = NULL,
  headers = NULL,
  body = NULL,
  merge = FALSE,
  ...
) {
  object <- list(
    rel = rel,
    href = href,
    type = type,
    title = title,
    method = method,
    headers = headers,
    body = body,
    merge = merge,
    extra_fields = list(...)
  )
  # Validation
  check_single_character(object$rel, "rel")
  check_single_character(object$href, "href")
  check_single_character(
    object$type,
    "type",
    allow_null = TRUE,
    allow_empty = TRUE
  )
  check_single_character(
    object$title,
    "title",
    allow_null = TRUE,
    allow_empty = TRUE
  )
  check_single_character(
    object$method,
    "method",
    allow_null = TRUE,
    allow_empty = TRUE
  )
  check_flag(object$merge, "merge")
  # Additional unstructured fields
  if (!is.list(object[["extra_fields"]])) {
    cli::cli_abort("extra_fields must be list.")
  }

  # Assign class
  class(object) <- c("stac_link", "stac_object")
  return(object)
}


#' @exportS3Method
as.list.stac_link <- function(x, ...) {
  out <- list(rel = x$rel, href = x$href)
  for (field in c("type", "title", "method", "headers", "body")) {
    value <- x[[field]]
    if (!is.null(value)) out[[field]] <- value
  }
  if (isTRUE(x$merge)) {
    out[["merge"]] <- TRUE
  }
  return(c(out, x$extra_fields))
}


#' Coerce an object to a STAC link
#'
#' Converts an object to a [stac_link] object. If `x` is already a
#' `stac_link`, it is returned unchanged. Otherwise, `x` must be a list
#' containing at least `rel` and `href` fields, which are passed to
#' [stac_link()] along with any other fields present.
#'
#' @param x An object to coerce. Either a `stac_link` object or a list with
#'   `rel` and `href` fields, as accepted by [stac_link()].
#'
#' @return A `stac_link` object.
#'
#' @noRd
as_stac_link <- function(x) {
  if (inherits(x, "stac_link")) {
    return(x)
  }
  if (!is.list(x) || is.null(x[["rel"]]) || is.null(x[["href"]])) {
    cli::cli_abort(c(
      "Each link must be a stac_link or a list with 'rel' and 'href' fields.",
      i = "Use stac_link() to build one."
    ))
  }
  return(do.call(stac_link, x))
}


normalize_links <- function(x) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.list(x)) {
    cli::cli_abort("'links' must be a list of link objects.")
  }
  return(lapply(x, as_stac_link))
}


#' Add a link to a STAC catalog
#'
#' @description
#' Adds a link object to a STAC Catalog, Collection, or Item. Links are used to
#' connect STAC resources and provide relationships between catalogs,
#' collections, and items.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param rel (character, required) The link relation type. Common values
#'   include `"self"`, `"root"`, `"parent"`, `"child"`, and `"item"`. See the
#'   STAC specification for a full list of relation types.
#' @param href (character, required) The URL or path to the linked resource.
#'   Can be absolute or relative.
#' @param ... Additional link properties passed to `stac_link()`, such as
#'   `type`, `title`, `method`, `headers`, `body`, or `merge`.
#'
#' @return The modified catalog object with the new link added.
#'
#' @seealso
#' * [add_self_link()] for adding a self link
#' * [add_root_link()] for adding a root link
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
  return(catalog)
}


#' Add a child catalog or collection
#'
#' @description
#' Adds a child STAC Catalog or Collection to a parent. A `"child"` link is
#' added immediately, and the complete child is retained internally so that
#' [write_stac()] can write it as part of the catalog tree.
#'
#' @param catalog A STAC catalog or collection object to add the child to.
#' @param child A STAC catalog or collection object to add as a child.
#' @param href (character, optional) The URL or path to the child resource.
#'   If `NULL`, uses `"./<child_id>/catalog.json"` for a Catalog or
#'   `"./<child_id>/collection.json"` for a Collection. [write_stac()]
#'   regenerates this href for its output layout and `catalog_type`.
#' @param title (character, optional) A title for the link. If `NULL`, uses
#'   the child's `title` field if available.
#'
#' @return The modified parent with the child link added and the complete child
#'   retained internally for [write_stac()].
#'
#' @seealso
#' * [add_link()] for adding arbitrary links
#' * [add_item()] for adding STAC Items
#' * See `vignette("stac-catalog")` for the recursive writing model
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
#' parent <- add_child(parent, child)
#'
#' @export
add_child <- function(catalog, child, href = NULL, title = NULL) {
  if (!inherits(child, "stac_catalog")) {
    cli::cli_abort("'child' must be a stac_catalog or stac_collection object")
  }
  check_duplicate_ids(
    new_ids = child$id,
    existing_ids = names(
      attr(catalog, "stac_children") %||%
        list()
    ),
    what = "a child"
  )
  if (is.null(href)) {
    if (inherits(child, "stac_collection")) {
      href <- paste0("./", child$id, "/collection.json")
    } else {
      href <- paste0("./", child$id, "/catalog.json")
    }
  }
  catalog <- add_link(
    catalog,
    rel = "child",
    href = href,
    type = "application/json",
    title = title %||%
      child$title
  )
  stored_children <- attr(catalog, "stac_children")
  if (is.null(stored_children)) {
    stored_children <- list()
  }
  stored_children[[child$id]] <- child
  attr(catalog, "stac_children") <- stored_children
  return(catalog)
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
  return(catalog)
}


#' Add a root link to a STAC catalog
#'
#' @description
#' Adds a root link to a STAC Catalog, Collection, or Item. A root link provides
#' the URL to the root catalog of the STAC hierarchy and is strongly recommended
#' by the STAC specification.
#'
#' @param catalog A STAC catalog, collection, or item object.
#' @param href (character, required) The URL to the root catalog. Can be
#'   absolute or relative.
#'
#' @return The modified catalog object with the root link added.
#'
#' @seealso
#' * [add_self_link()] for adding a self link
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
  return(catalog)
}


#' Add a parent link to a STAC catalog
#'
#' @description
#' Adds a parent link to a STAC Catalog, Collection, or Item. A parent link
#' provides the URL to the parent catalog or collection in the STAC hierarchy.
#' Non-root catalogs should include a parent link.
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
#' @noRd
add_parent_link <- function(catalog, href) {
  catalog <- add_link(
    catalog,
    rel = "parent",
    href = href,
    type = "application/json"
  )
  return(catalog)
}
