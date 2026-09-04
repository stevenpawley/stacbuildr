#' Write a STAC Catalog Structure to Disk
#'
#' @description
#' Writes a complete STAC Catalog structure to the filesystem, including all
#' child catalogs, collections, and items. This function recursively writes the
#' entire catalog tree, creating the necessary directory structure and JSON files.
#' Children and items are automatically retrieved from the catalog's stored objects.
#'
#' @param catalog A STAC Catalog or Collection object created with `stac_catalog()`
#'   or `stac_collection()`.
#' @param path (character, required) Root directory path where the catalog should
#'   be written. Will be created if it doesn't exist.
#' @param catalog_type (character, optional) Type of catalog to create. These
#'   correspond to the three link layouts defined in
#'   [Use of links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links)
#'   in the STAC best-practices document, and to PySTAC's `CatalogType` values.
#'   One of:
#'   * `"self-contained"`: Every structural link is relative and no object
#'     carries a `self` link. Portable — the tree can be moved or archived.
#'   * `"relative"`: A self-contained catalog plus a single absolute `self` link
#'     on the root, identifying where the catalog is published. Requires
#'     `base_url`.
#'   * `"absolute"`: All links and asset hrefs use absolute URLs built from
#'     `base_url`, and every object carries a `self` link. Best for web-served
#'     catalogs. Requires `base_url`.
#'   Default is `"self-contained"`. Note that no catalog type copies or moves
#'   asset files — see Details.
#' @param overwrite (logical, optional) If `TRUE`, overwrites existing files. If
#'   `FALSE`, throws an error if files already exist. Default is `FALSE`.
#' @param pretty (logical, optional) If `TRUE`, writes formatted JSON with
#'   indentation. If `FALSE`, writes compact JSON. Default is `TRUE`.
#' @param base_url (character, optional) Base URL identifying where the catalog
#'   is published, for example `"https://example.com/stac"`. Required when
#'   `catalog_type` is `"relative"` or `"absolute"`; ignored otherwise.
#'
#' @details
#' ## Catalog Types
#'
#' The three types match the link layouts defined in
#' [Use of links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links)
#' in the STAC best-practices document, and map onto PySTAC's
#' `CatalogType$SELF_CONTAINED`, `CatalogType$RELATIVE_PUBLISHED` and
#' `CatalogType$ABSOLUTE_PUBLISHED`:
#'
#' | `catalog_type` | STAC best practices | PySTAC |
#' | --- | --- | --- |
#' | `"self-contained"` | [Self-contained Catalogs](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-catalogs) | `SELF_CONTAINED` |
#' | `"relative"` | [Relative Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#relative-published-catalog) | `RELATIVE_PUBLISHED` |
#' | `"absolute"` | [Absolute Published Catalog](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#absolute-published-catalog) | `ABSOLUTE_PUBLISHED` |
#'
#' **Self-Contained Catalogs:**
#' Links between catalog, collection and item files are written as relative
#' paths. Because a `self` link must be absolute, self-contained catalogs carry
#' no `self` link at all, and any `self` link already present on an object is
#' dropped. Asset hrefs that are absolute local paths are rewritten relative to
#' the directory holding the item JSON; hrefs that are already relative, or that
#' are URLs (anything containing `://`), are left unchanged. This is the
#' portable layout: the written tree can be relocated without rewriting links.
#'
#' **Relative Catalogs:**
#' Identical to a self-contained catalog, except that the root catalog or
#' collection carries one absolute `self` link built from `base_url`, recording
#' where the catalog is published. No other object gets a `self` link. Use this
#' when the catalog is published at a known location but should still be
#' usable after being downloaded.
#'
#' **Absolute Catalogs:**
#' All links use absolute URLs and every object carries a `self` link. Required
#' when the catalog will be served from a web server. Asset hrefs that are
#' already URLs are left unchanged, and relative asset hrefs are resolved
#' against the item's URL. An asset href that is an absolute local filesystem
#' path has no URL equivalent, so it is left unchanged and a warning is raised.
#'
#' ## Assets Are Not Copied
#'
#' `write_stac()` writes JSON only. It never copies, moves, or rewrites asset
#' files, so an asset stored outside `path` stays there and is referenced by a
#' relative path that climbs out of the catalog directory, such as
#' `../../../data/dem.tif`.
#'
#' This is narrower than a
#' [self-contained catalog with assets](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-with-assets),
#' where every referenced file lives inside the catalog directory so the whole
#' tree can be archived or relocated as a unit. A catalog written here is
#' [metadata only](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#self-contained-metadata-only)
#' unless you place the asset files under `path` yourself before calling
#' `write_stac()`; only then is the written catalog portable in that sense.
#'
#' ## Directory Structure
#' The function creates a directory structure based on the catalog hierarchy:
#' ```
#' path/
#'   catalog.json                    # Root catalog
#'   collection1/
#'     collection.json               # Collection
#'     item1/
#'       item1.json                  # Items (each in own subdirectory)
#'     item2/
#'       item2.json
#'   collection2/
#'     collection.json
#'     subcatalog/
#'       catalog.json
#' ```
#'
#' ## Automatic Object Retrieval
#' When you use `add_child()` or `add_item()`, the child catalogs and items are
#' automatically stored as attributes on the parent catalog. The `write_stac()`
#' function retrieves these stored objects and writes them recursively.
#'
#' @return Invisibly returns the path where the catalog was written.
#'
#' @references
#' STAC best practices, [Use of links](https://github.com/radiantearth/stac-spec/blob/master/best-practices.md#use-of-links),
#' which defines the self-contained, relative published and absolute published
#' layouts. See <https://stacspec.org/> for the specification as a whole.
#'
#' @seealso
#' * [write_catalog()] for writing a single catalog/collection file
#' * [write_item()] for writing a single item file
#' * [read_stac()] for reading STAC catalogs from disk
#' * [add_child()] for adding child catalogs with automatic storage
#' * [add_item()] for adding items with automatic storage
#'
#' @examples
#' \dontrun{
#' # Create a catalog structure
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example STAC catalog"
#' )
#'
#' collection <- stac_collection(
#'   id = "landsat-8",
#'   description = "Landsat 8 imagery",
#'   license = "CC0-1.0",
#'   extent = stac_extent(
#'     spatial_bbox = list(c(-180, -90, 180, 90)),
#'     temporal_interval = list(list("2013-04-11T00:00:00Z", NULL))
#'   )
#' )
#'
#' item <- stac_item(
#'   id = "LC08_001",
#'   geometry = my_geometry,
#'   bbox = my_bbox,
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' # Add item to collection (automatically stored)
#' collection <- add_item(collection, item)
#'
#' # Add collection to catalog (automatically stored)
#' catalog <- add_child(catalog, collection)
#'
#' # Write entire structure - children and items are automatically written!
#' write_stac(catalog, "output/stac")
#'
#' # Write as a relative catalog, recording where it is published
#' write_stac(
#'   catalog,
#'   "output/stac",
#'   catalog_type = "relative",
#'   base_url = "https://example.com/stac"
#' )
#'
#' # Write as absolute catalog for web serving
#' write_stac(
#'   catalog,
#'   "output/stac",
#'   catalog_type = "absolute",
#'   base_url = "https://example.com/stac"
#' )
#'
#' # Overwrite existing catalog
#' write_stac(catalog, "output/stac", overwrite = TRUE)
#' }
#'
#' @export
write_stac <- function(
  catalog,
  path,
  catalog_type = c("self-contained", "relative", "absolute"),
  overwrite = FALSE,
  pretty = TRUE,
  base_url = NULL
) {
  if (!inherits(catalog, "stac_catalog")) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  catalog_type <- match.arg(catalog_type)

  # Both absolute and relative catalogs need to know where they are published
  if (catalog_type %in% c("absolute", "relative") && is.null(base_url)) {
    cli::cli_abort(c(
      "{.arg base_url} is required when {.arg catalog_type} is {.val {catalog_type}}.",
      "i" = if (catalog_type == "relative") {
        "A relative catalog carries an absolute self link on its root, which
         needs the published location."
      } else {
        "An absolute catalog builds every link from the published location."
      },
      ">" = "Use {.code catalog_type = \"self-contained\"} for a portable
             catalog with no published location."
    ))
  }

  # Create root directory if it doesn't exist
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  # Write the catalog recursively
  write_catalog_recursive(
    catalog,
    path,
    catalog_type,
    base_url,
    overwrite,
    pretty,
    is_root = TRUE,
    parent_href = NULL
  )

  cli::cli_alert_success("STAC catalog written to {.file {path}}")
  invisible(path)
}


#' Write a Single STAC Catalog or Collection File
#'
#' @description
#' Writes a single STAC Catalog or Collection to a JSON file. Unlike `write_stac()`,
#' this does not recursively write children or items, and does not include the
#' stored child/item objects in the output (only the links).
#'
#' @param catalog A STAC Catalog or Collection object.
#' @param file (character, required) Path to the output JSON file.
#' @param overwrite (logical, optional) If `TRUE`, overwrites existing file.
#'   Default is `FALSE`.
#' @param pretty (logical, optional) If `TRUE`, writes formatted JSON. Default
#'   is `TRUE`.
#'
#' @return Invisibly returns the file path.
#'
#' @examples
#' \dontrun{
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
#' write_catalog(catalog, "catalog.json")
#' }
#'
#' @export
write_catalog <- function(catalog, file, overwrite = FALSE, pretty = TRUE) {
  if (!inherits(catalog, "stac_catalog")) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  if (file.exists(file) && !overwrite) {
    cli::cli_abort(
      "File '{file}' already exists. Use overwrite = TRUE to replace."
    )
  }

  # Create parent directory if needed
  dir_path <- dirname(file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }

  # Remove stored objects before writing (keep only the JSON structure)
  catalog_clean <- strip_stored_objects(catalog)

  # Convert S7 objects to plain list for JSON serialization
  if (inherits(catalog_clean, "S7_object")) {
    catalog_clean <- as.list(catalog_clean)
  }

  # Write JSON — digits = 15 preserves full double precision for numeric
  # fields such as raster scale/offset values (e.g. 2.75e-5)
  json <- jsonlite::toJSON(
    catalog_clean,
    auto_unbox = TRUE,
    pretty     = pretty,
    null       = "null",
    digits     = 15
  )

  writeLines(json, file)
  invisible(file)
}


#' Write a Single STAC Item File
#'
#' @description
#' Writes a single STAC Item to a JSON file.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param file (character, required) Path to the output JSON file.
#' @param overwrite (logical, optional) If `TRUE`, overwrites existing file.
#'   Default is `FALSE`.
#' @param pretty (logical, optional) If `TRUE`, writes formatted JSON. Default
#'   is `TRUE`.
#'
#' @return Invisibly returns the file path.
#'
#' @examples
#' \dontrun{
#' item <- stac_item(
#'   id = "my-item",
#'   geometry = list(type = "Point", coordinates = c(-105, 40)),
#'   bbox = c(-105, 40, -105, 40),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' write_item(item, "items/my-item.json")
#' }
#'
#' @export
write_item <- function(item, file, overwrite = FALSE, pretty = TRUE) {
  if (!inherits(item, "stac_item")) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (file.exists(file) && !overwrite) {
    cli::cli_abort(
      "File '{file}' already exists. Use overwrite = TRUE to replace."
    )
  }

  # Create parent directory if needed
  dir_path <- dirname(file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }

  # The `collection` field and the collection link are co-dependent in the
  # schema; drop or flag a half-specified pair before serialising.
  item <- reconcile_item_collection(item)

  # Remove any stored attributes before writing
  item_clean <- strip_stored_objects(item)

  # Convert S7 objects to plain list for JSON serialization
  if (inherits(item_clean, "S7_object")) {
    item_clean <- as.list(item_clean)
  }

  # Write JSON — digits = 15 preserves full double precision
  json <- jsonlite::toJSON(
    item_clean,
    auto_unbox = TRUE,
    pretty     = pretty,
    null       = "null",
    digits     = 15
  )

  writeLines(json, file)
  invisible(file)
}


#' Recursively Write Catalog Structure
#'
#' @description
#' Internal function to recursively write a catalog and all its children and items.
#' Retrieves stored child and item objects and writes them to the appropriate locations.
#'
#' @keywords internal
write_catalog_recursive <- function(
  catalog,
  path,
  catalog_type,
  base_url,
  overwrite,
  pretty,
  is_root = FALSE,
  parent_href = NULL,
  root_href = NULL,
  depth = 0L,
  root_file = NULL
) {
  catalog_file <- if (inherits(catalog, "stac_collection")) "collection.json" else "catalog.json"

  # For the root, establish root_href and the root filename once, then thread
  # both down through the children. Relative root hrefs are rebuilt at each
  # level from the nesting depth so they stay correct beyond one level.
  if (is_root) {
    root_file <- catalog_file
    root_href <- if (catalog_type == "absolute") {
      paste0(base_url, "/", catalog_file)
    } else {
      paste0("./", catalog_file)
    }
  } else if (catalog_type != "absolute") {
    root_href <- paste0(strrep("../", depth), root_file)
  }

  # Update catalog links
  catalog <- update_catalog_links(
    catalog,
    path,
    catalog_type,
    base_url,
    is_root,
    parent_href,
    root_href
  )

  # Get stored children and items
  stored_children <- attr(catalog, "stac_children")
  stored_items <- attr(catalog, "stac_items")

  # Write children recursively
  if (!is.null(stored_children) && length(stored_children) > 0) {
    for (child_id in names(stored_children)) {
      child <- stored_children[[child_id]]
      child_path <- file.path(path, child_id)

      # Create child directory
      if (!dir.exists(child_path)) {
        dir.create(child_path, recursive = TRUE)
      }

      # Calculate child base_url for absolute catalogs
      child_base_url <- NULL
      if (catalog_type == "absolute" && !is.null(base_url)) {
        child_base_url <- paste0(base_url, "/", child_id)
      }

      # Calculate parent href for child
      if (catalog_type == "absolute") {
        child_parent_href <- paste0(base_url, "/", catalog_file)
      } else {
        child_parent_href <- paste0("../", catalog_file)
      }

      # Recursively write child
      write_catalog_recursive(
        child,
        child_path,
        catalog_type,
        child_base_url,
        overwrite,
        pretty,
        is_root = FALSE,
        parent_href = child_parent_href,
        root_href = root_href,
        depth = depth + 1L,
        root_file = root_file
      )
    }
  }

  # Write items — each item gets its own subdirectory: {id}/{id}.json
  if (!is.null(stored_items) && length(stored_items) > 0) {
    for (item in stored_items) {
      item_dir <- file.path(path, item@id)
      if (!dir.exists(item_dir)) {
        dir.create(item_dir, recursive = TRUE)
      }
      item_file <- file.path(item_dir, paste0(item@id, ".json"))

      # Items live one level below the catalog dir, so relative hrefs from
      # inside the item dir are one level deeper than the catalog.
      if (catalog_type == "absolute") {
        item_base_url <- paste0(base_url, "/", item@id)
        item <- update_item_links(
          item,
          paste0(item_base_url, "/", item@id, ".json"),
          paste0(base_url, "/", catalog_file),
          root_href,
          parent_is_collection = inherits(catalog, "stac_collection")
        )
      } else {
        # Self-contained and relative catalogs carry no item self links; only
        # the root of a relative catalog gets one, and it must be absolute.
        item <- update_item_links(
          item,
          NULL,
          paste0("../", catalog_file),
          paste0(strrep("../", depth + 1L), root_file),
          parent_is_collection = inherits(catalog, "stac_collection")
        )
      }

      if (catalog_type == "absolute") {
        item <- absolutize_asset_hrefs(item, item_base_url)
      } else {
        item <- relativize_asset_hrefs(item, item_dir)
      }
      write_item(item, item_file, overwrite = overwrite, pretty = pretty)
    }
  }

  # Write the catalog file itself
  catalog_filepath <- file.path(path, catalog_file)
  write_catalog(
    catalog,
    catalog_filepath,
    overwrite = overwrite,
    pretty = pretty
  )

  invisible(path)
}


#' Update Catalog Links for Filesystem Structure
#'
#' @description
#' Internal function to update links in a catalog to match the filesystem structure.
#'
#' @keywords internal
update_catalog_links <- function(
  catalog,
  path,
  catalog_type,
  base_url = NULL,
  is_root = FALSE,
  parent_href = NULL,
  root_href = NULL
) {
  # Determine the catalog filename
  if (inherits(catalog, "stac_collection")) {
    catalog_file <- "collection.json"
  } else {
    catalog_file <- "catalog.json"
  }

  # Build the self link. A self link must be absolute, so self-contained
  # catalogs get none at all and relative catalogs get one on the root only.
  self_href <- if (catalog_type == "absolute" || (catalog_type == "relative" && is_root)) {
    paste0(base_url, "/", catalog_file)
  } else {
    NULL
  }

  # Remove any existing self link and add the updated one
  catalog@links <- Filter(function(x) x$rel != "self", catalog@links)
  if (!is.null(self_href)) {
    catalog <- add_self_link(catalog, self_href)
  }

  # Add root link — root_href is computed by the caller from the nesting depth
  catalog@links <- Filter(function(x) x$rel != "root", catalog@links)
  catalog <- add_root_link(catalog, root_href)

  # Add parent link for non-root catalogs
  if (!is_root && !is.null(parent_href)) {
    catalog@links <- Filter(function(x) x$rel != "parent", catalog@links)
    catalog <- add_parent_link(catalog, parent_href)
  }

  # Update child links based on stored children
  stored_children <- attr(catalog, "stac_children")
  if (!is.null(stored_children) && length(stored_children) > 0) {
    # Remove existing child links
    catalog@links <- Filter(function(x) x$rel != "child", catalog@links)

    # Add updated child links
    for (child_id in names(stored_children)) {
      child <- stored_children[[child_id]]

      if (inherits(child, "stac_collection")) {
        child_file <- "collection.json"
      } else {
        child_file <- "catalog.json"
      }

      if (catalog_type == "absolute") {
        child_href <- paste0(base_url, "/", child_id, "/", child_file)
      } else {
        child_href <- paste0("./", child_id, "/", child_file)
      }

      catalog <- add_link(
        catalog,
        rel = "child",
        href = child_href,
        type = "application/json",
        title = child@title
      )
    }
  }

  # Update item links based on stored items
  stored_items <- attr(catalog, "stac_items")
  if (!is.null(stored_items) && length(stored_items) > 0) {
    # Remove existing item links
    catalog@links <- Filter(function(x) x$rel != "item", catalog@links)

    # Add updated item links
    for (item in stored_items) {
      if (catalog_type == "absolute") {
        item_href <- paste0(base_url, "/", item@id, "/", item@id, ".json")
      } else {
        item_href <- paste0("./", item@id, "/", item@id, ".json")
      }

      catalog <- add_link(
        catalog,
        rel = "item",
        href = item_href,
        type = "application/geo+json",
        title = item@properties$title
      )
    }
  }

  catalog
}


#' Update Item Links
#'
#' @description
#' Internal function to update links in an item.
#'
#' @keywords internal
update_item_links <- function(item, self_href, parent_href, root_href,
                              parent_is_collection = FALSE) {
  # Update self link. `self_href` is NULL for self-contained and relative
  # catalogs, where items carry no self link because it would have to be
  # absolute.
  item@links <- Filter(function(x) x$rel != "self", item@links)
  if (!is.null(self_href)) {
    item <- add_link(
      item,
      rel = "self",
      href = self_href,
      type = "application/geo+json"
    )
  }

  # Update parent link
  if (!is.null(parent_href)) {
    item@links <- Filter(function(x) x$rel != "parent", item@links)
    item <- add_link(
      item,
      rel = "parent",
      href = parent_href,
      type = "application/json"
    )

    # Only add collection link when parent is actually a collection
    item@links <- Filter(function(x) x$rel != "collection", item@links)
    if (parent_is_collection) {
      item <- add_link(
        item,
        rel = "collection",
        href = parent_href,
        type = "application/json"
      )
    }
  }

  # Update root link
  if (!is.null(root_href)) {
    item@links <- Filter(function(x) x$rel != "root", item@links)
    item <- add_link(
      item,
      rel = "root",
      href = root_href,
      type = "application/json"
    )
  }

  item
}


# Reconcile an Item's `collection` field with its `collection` link.
#
# The Item schema ties the two together: a link with rel = "collection"
# requires the `collection` field, and with no such link the field is not
# allowed at all. add_item() keeps the pair in step when the parent is a
# Collection, but an item built by hand, or one carrying a `collection` id
# that was added to a plain Catalog, can reach the writer with only one half
# present. Both halves are checked here because every item is written through
# write_item(), whether on its own or as part of a tree.
#
# @keywords internal
reconcile_item_collection <- function(item) {
  has_link <- any(vapply(
    item@links,
    function(link) identical(link$rel, "collection"),
    logical(1)
  ))
  has_field <- !is.null(item@collection)

  if (has_field && !has_link) {
    cli::cli_warn(c(
      "Item {.val {item@id}} sets {.field collection} to {.val {item@collection}} but has no {.val collection} link.",
      "i" = "The Item schema does not allow the field without the link, so it has been dropped from the output.",
      ">" = "Keep the reference by adding the link: {.code add_link(item, \"collection\", href)}."
    ))
    item@collection <- NULL
  } else if (has_link && !has_field) {
    cli::cli_warn(c(
      "Item {.val {item@id}} has a {.val collection} link but no {.field collection} field.",
      "i" = "The Item schema requires the field whenever the link is present, so the written item will not validate.",
      ">" = "Set it with {.code stac_item(..., collection = <id>)}."
    ))
  }

  item
}


#' Strip Stored Objects from STAC Object
#'
#' Compute a relative path from a directory to a target file
#'
#' @param target Absolute path to the target file.
#' @param from_dir Absolute path to the directory to compute relative to.
#' @return A relative path string, or `target` unchanged if it is a URL or
#'   already relative.
#'
#' @keywords internal
make_relative_href <- function(target, from_dir) {
  if (is.null(target) || grepl("://", target, fixed = TRUE) || !startsWith(target, "/")) {
    return(target)
  }

  target   <- normalizePath(target,   mustWork = FALSE)
  from_dir <- normalizePath(from_dir, mustWork = FALSE)

  target_parts <- Filter(nchar, strsplit(target,   "/")[[1]])
  from_parts   <- Filter(nchar, strsplit(from_dir, "/")[[1]])

  n <- min(length(target_parts), length(from_parts))
  common_len <- 0L
  for (i in seq_len(n)) {
    if (target_parts[i] == from_parts[i]) common_len <- i else break
  }

  up    <- rep("..", length(from_parts) - common_len)
  down  <- tail(target_parts, length(target_parts) - common_len)
  parts <- c(up, down)
  if (length(parts) == 0) "." else paste(parts, collapse = "/")
}


#' Join a relative path onto a base URL
#'
#' Appends `rel` to `base`, collapsing any `.` and `..` segments so the result
#' is a clean absolute URL.
#'
#' @param base Absolute base URL, for example `"https://example.com/stac/item"`.
#' @param rel Relative path, for example `"../data/dem.tif"`.
#' @return An absolute URL string.
#'
#' @keywords internal
url_join <- function(base, rel) {
  matched <- regmatches(
    base,
    regexec("^([a-zA-Z][a-zA-Z0-9+.-]*://[^/]*)(/.*)?$", base)
  )[[1]]

  if (length(matched) == 3) {
    prefix <- matched[2]
    path <- matched[3]
  } else {
    prefix <- ""
    path <- base
  }

  segments <- Filter(
    nzchar,
    strsplit(paste0(path, "/", rel), "/", fixed = TRUE)[[1]]
  )

  resolved <- character(0)
  for (segment in segments) {
    if (segment == ".") {
      next
    } else if (segment == "..") {
      if (length(resolved) > 0) resolved <- resolved[-length(resolved)]
    } else {
      resolved <- c(resolved, segment)
    }
  }

  paste0(prefix, "/", paste(resolved, collapse = "/"))
}


#' Absolutize relative asset hrefs against an item's base URL
#'
#' Absolute published catalogs require absolute asset hrefs. Hrefs that are
#' already URLs are left alone; relative hrefs are resolved against
#' `item_base_url`; absolute local filesystem paths cannot be mapped to a URL
#' and are left unchanged with a warning.
#'
#' @keywords internal
absolutize_asset_hrefs <- function(item, item_base_url) {
  if (is.null(item@assets) || length(item@assets) == 0) return(item)

  unresolved <- character(0)

  item@assets <- lapply(item@assets, function(a) {
    if (is.null(a$href)) return(a)
    if (grepl("://", a$href, fixed = TRUE)) return(a)

    if (startsWith(a$href, "/")) {
      unresolved <<- c(unresolved, a$href)
      return(a)
    }

    a$href <- url_join(item_base_url, a$href)
    a
  })

  if (length(unresolved) > 0) {
    cli::cli_warn(c(
      "Item {.val {item@id}} has local asset paths that cannot be made absolute.",
      "i" = "An absolute catalog requires absolute asset hrefs, but a local
             filesystem path has no URL equivalent.",
      "x" = "Left unchanged: {.file {unresolved}}",
      ">" = "Give these assets URL hrefs, or paths relative to the item
             directory, before writing an absolute catalog."
    ))
  }

  item
}


#' Relativize absolute local asset hrefs against an item directory
#'
#' @keywords internal
relativize_asset_hrefs <- function(item, item_dir) {
  if (is.null(item@assets) || length(item@assets) == 0) return(item)
  item@assets <- lapply(item@assets, function(a) {
    if (!is.null(a$href)) a$href <- make_relative_href(a$href, item_dir)
    a
  })
  item
}


#' Internal function to remove stored child/item objects before writing to JSON.
#' This ensures only the standard STAC fields are written to the file.
#'
#' @keywords internal
strip_stored_objects <- function(stac_obj) {
  # Remove stac_children and stac_items attributes
  attr(stac_obj, "stac_children") <- NULL
  attr(stac_obj, "stac_items") <- NULL
  stac_obj
}


#' Read a STAC Catalog from Disk
#'
#' @description
#' Reads a STAC Catalog, Collection, or Item from a JSON file and returns the
#' corresponding S7 object (`stac_catalog`, `stac_collection`, or `stac_item`).
#' The returned object is fully usable with all package functions, completing
#' the write/read round-trip.
#'
#' @param file (character, required) Path to the STAC JSON file.
#'
#' @return An S7 object of class `stac_catalog`, `stac_collection`, or
#'   `stac_item`, depending on the `type` field in the JSON.
#'
#' @examples
#' \dontrun{
#' catalog <- read_stac("path/to/catalog.json")
#' item    <- read_stac("path/to/item.json")
#' }
#'
#' @export
read_stac <- function(file) {
  if (!file.exists(file)) {
    cli::cli_abort("File not found: {file}")
  }

  parsed <- jsonlite::fromJSON(file, simplifyVector = FALSE)

  if (is.null(parsed$type)) {
    cli::cli_abort("Invalid STAC file: missing 'type' field")
  }

  switch(parsed$type,
    "Feature"    = parse_stac_item(parsed),
    "Catalog"    = parse_stac_catalog(parsed),
    "Collection" = parse_stac_collection(parsed),
    {
      cli::cli_warn("Unknown STAC type: {parsed$type}")
      parsed
    }
  )
}


#' Reconstruct a stac_item S7 Object from a Parsed JSON List
#'
#' @keywords internal
parse_stac_item <- function(parsed) {
  props <- parsed$properties %||% list()

  # Extract datetime fields; constructor re-adds them to properties
  dt       <- props$datetime
  start_dt <- props$start_datetime
  end_dt   <- props$end_datetime
  props$datetime        <- NULL
  props$start_datetime  <- NULL
  props$end_datetime    <- NULL

  stac_item(
    id              = parsed$id,
    geometry        = parsed$geometry,
    bbox            = if (!is.null(parsed$bbox)) unlist(parsed$bbox) else NULL,
    datetime        = dt,
    start_datetime  = start_dt,
    end_datetime    = end_dt,
    properties      = props,
    assets          = parsed$assets %||% list(),
    links           = parsed$links  %||% list(),
    stac_version    = parsed$stac_version %||% "1.1.0",
    stac_extensions = if (!is.null(parsed$stac_extensions))
                        unlist(parsed$stac_extensions) else NULL,
    collection      = parsed$collection
  )
}


#' Reconstruct a stac_catalog S7 Object from a Parsed JSON List
#'
#' @keywords internal
parse_stac_catalog <- function(parsed) {
  known <- c("type", "stac_version", "id", "description", "title",
             "stac_extensions", "conformsTo", "links")
  extra <- parsed[setdiff(names(parsed), known)]

  catalog <- do.call(stac_catalog, c(
    list(
      id              = parsed$id,
      description     = parsed$description,
      title           = parsed$title,
      stac_version    = parsed$stac_version %||% "1.1.0",
      stac_extensions = if (!is.null(parsed$stac_extensions))
                          unlist(parsed$stac_extensions) else NULL,
      conformsTo      = if (!is.null(parsed$conformsTo))
                          unlist(parsed$conformsTo) else NULL
    ),
    extra
  ))

  catalog@links <- parsed$links %||% list()
  catalog
}


#' Reconstruct a stac_collection S7 Object from a Parsed JSON List
#'
#' @keywords internal
parse_stac_collection <- function(parsed) {
  known <- c("type", "stac_version", "id", "description", "title",
             "stac_extensions", "conformsTo", "links",
             "license", "extent", "keywords", "providers", "summaries", "assets")
  extra <- parsed[setdiff(names(parsed), known)]

  # Reconstruct extent: bbox arrays come back as lists and need unlist()
  extent_list <- list(
    spatial  = list(
      bbox = lapply(parsed$extent$spatial$bbox, unlist)
    ),
    temporal = list(
      interval = parsed$extent$temporal$interval
    )
  )

  collection <- do.call(stac_collection, c(
    list(
      id              = parsed$id,
      description     = parsed$description,
      license         = parsed$license,
      extent          = extent_list,
      title           = parsed$title,
      stac_version    = parsed$stac_version %||% "1.1.0",
      stac_extensions = if (!is.null(parsed$stac_extensions))
                          unlist(parsed$stac_extensions) else NULL,
      keywords        = if (!is.null(parsed$keywords))
                          unlist(parsed$keywords) else NULL,
      providers       = parsed$providers,
      summaries       = parsed$summaries,
      assets          = parsed$assets,
      conformsTo      = if (!is.null(parsed$conformsTo))
                          unlist(parsed$conformsTo) else NULL
    ),
    extra
  ))

  collection@links <- parsed$links %||% list()
  collection
}


#' Get Stored Children from Catalog
#'
#' @description
#' Retrieves the stored child catalogs/collections from a catalog object.
#' When children are not in memory (e.g. after `read_stac()`), set
#' `resolve = TRUE` to follow the `child` links and load them from disk.
#'
#' @param catalog A STAC Catalog or Collection object.
#' @param resolve (logical) If `TRUE` and no children are stored in memory,
#'   follow the `child` links and read each one from disk. Relative hrefs are
#'   resolved against `base_path`. Default is `FALSE`.
#' @param base_path (character) Directory used to resolve relative hrefs when
#'   `resolve = TRUE`. Defaults to the working directory.
#'
#' @return A named list of child catalogs/collections, or NULL if none exist.
#'
#' @examples
#' \dontrun{
#' # In-memory children
#' children <- get_children(catalog)
#'
#' # After read_stac(), follow links from disk
#' catalog <- read_stac("path/to/catalog.json")
#' children <- get_children(catalog, resolve = TRUE, base_path = "path/to")
#' names(children)
#' }
#'
#' @export
get_children <- function(catalog, resolve = FALSE, base_path = ".") {
  if (!inherits(catalog, "stac_catalog")) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  stored <- attr(catalog, "stac_children")
  if (!is.null(stored) || !resolve) return(stored)

  child_links <- Filter(
    function(link) !is.null(link$rel) && link$rel == "child",
    catalog@links
  )

  if (length(child_links) == 0) return(NULL)

  children <- lapply(child_links, function(link) {
    href <- link$href
    # Resolve relative hrefs against base_path
    if (!grepl("^https?://", href) && !startsWith(href, "/")) {
      href <- file.path(base_path, href)
    }
    read_stac(href)
  })

  # Name by child id
  ids <- vapply(children, function(x) x@id, character(1))
  stats::setNames(children, ids)
}


#' Get Stored Items from Catalog or Collection
#'
#' @description
#' Retrieves the stored items from a catalog or collection object.
#' When items are not in memory (e.g. after `read_stac()`), set
#' `resolve = TRUE` to follow the `item` links and load them from disk.
#'
#' @param catalog A STAC Catalog or Collection object.
#' @param resolve (logical) If `TRUE` and no items are stored in memory,
#'   follow the `item` links and read each one from disk. Relative hrefs are
#'   resolved against `base_path`. Default is `FALSE`.
#' @param base_path (character) Directory used to resolve relative hrefs when
#'   `resolve = TRUE`. Defaults to the working directory.
#'
#' @return A list of items, or NULL if none exist.
#'
#' @examples
#' \dontrun{
#' # In-memory items
#' items <- get_items(collection)
#'
#' # After read_stac(), follow links from disk
#' collection <- read_stac("path/to/collection.json")
#' items <- get_items(collection, resolve = TRUE, base_path = "path/to")
#' length(items)
#' }
#'
#' @export
get_items <- function(catalog, resolve = FALSE, base_path = ".") {
  if (!inherits(catalog, "stac_catalog")) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  stored <- attr(catalog, "stac_items")
  if (!is.null(stored) || !resolve) return(stored)

  item_links <- Filter(
    function(link) !is.null(link$rel) && link$rel == "item",
    catalog@links
  )

  if (length(item_links) == 0) return(NULL)

  lapply(item_links, function(link) {
    href <- link$href
    if (!grepl("^https?://", href) && !startsWith(href, "/")) {
      href <- file.path(base_path, href)
    }
    read_stac(href)
  })
}
