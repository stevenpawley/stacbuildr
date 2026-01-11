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
#' @param catalog_type (character, optional) Type of catalog to create. One of:
#'   * `"self-contained"`: All links use relative paths within the catalog structure. 
#'     Best for portability and publishing.
#'   * `"relative"`: Links use relative paths but may reference external resources.
#'   * `"absolute"`: All links use absolute URLs. Best for web-served catalogs.
#'   Default is `"self-contained"`.
#' @param overwrite (logical, optional) If `TRUE`, overwrites existing files. If 
#'   `FALSE`, throws an error if files already exist. Default is `FALSE`.
#' @param pretty (logical, optional) If `TRUE`, writes formatted JSON with 
#'   indentation. If `FALSE`, writes compact JSON. Default is `TRUE`.
#' @param base_url (character, optional) Base URL for absolute links when 
#'   `catalog_type = "absolute"`. For example, `"https://example.com/stac"`. 
#'   Required when using absolute catalog type.
#'
#' @details
#' ## Catalog Types
#' 
#' **Self-Contained Catalogs:**
#' All links use relative paths and all referenced resources are within the 
#' catalog directory structure. This is the most portable option and recommended 
#' for sharing or archiving catalogs.
#' 
#' **Relative Catalogs:**
#' Links use relative paths but may reference resources outside the catalog tree. 
#' Useful when integrating with existing file structures.
#' 
#' **Absolute Catalogs:**
#' All links use absolute URLs. Required when the catalog will be served from a 
#' web server. Requires `base_url` to be specified.
#'
#' ## Directory Structure
#' The function creates a directory structure based on the catalog hierarchy:
#' ```
#' path/
#'   catalog.json                    # Root catalog
#'   collection1/
#'     collection.json               # Collection
#'     items/
#'       item1.json                  # Items
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
#'     temporal_interval = list(c("2013-04-11T00:00:00Z", NULL))
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
write_stac <- function(catalog,
                      path,
                      catalog_type = c("self-contained", "relative", "absolute"),
                      overwrite = FALSE,
                      pretty = TRUE,
                      base_url = NULL) {
  
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  catalog_type <- match.arg(catalog_type)
  
  # Validate base_url requirement for absolute catalogs
  if (catalog_type == "absolute" && is.null(base_url)) {
    stop("'base_url' is required when catalog_type is 'absolute'")
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
  
  message(sprintf("STAC catalog written to: %s", path))
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
write_catalog <- function(catalog,
                         file,
                         overwrite = FALSE,
                         pretty = TRUE) {
  
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  if (file.exists(file) && !overwrite) {
    stop(sprintf("File '%s' already exists. Use overwrite = TRUE to replace.", file))
  }
  
  # Create parent directory if needed
  dir_path <- dirname(file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  
  # Remove stored objects before writing (keep only the JSON structure)
  catalog_clean <- strip_stored_objects(catalog)
  
  # Write JSON
  json <- jsonlite::toJSON(
    catalog_clean,
    auto_unbox = TRUE,
    pretty = pretty,
    null = "null"
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
write_item <- function(item,
                      file,
                      overwrite = FALSE,
                      pretty = TRUE) {
  
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }
  
  if (file.exists(file) && !overwrite) {
    stop(sprintf("File '%s' already exists. Use overwrite = TRUE to replace.", file))
  }
  
  # Create parent directory if needed
  dir_path <- dirname(file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  
  # Remove any stored attributes before writing
  item_clean <- strip_stored_objects(item)
  
  # Write JSON
  json <- jsonlite::toJSON(
    item_clean,
    auto_unbox = TRUE,
    pretty = pretty,
    null = "null"
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
write_catalog_recursive <- function(catalog,
                                   path,
                                   catalog_type,
                                   base_url,
                                   overwrite,
                                   pretty,
                                   is_root = FALSE,
                                   parent_href = NULL) {
  
  # Determine the catalog filename
  if (inherits(catalog, "stac_collection")) {
    catalog_file <- "collection.json"
  } else {
    catalog_file <- "catalog.json"
  }
  
  # Update catalog links
  catalog <- update_catalog_links(
    catalog,
    path,
    catalog_type,
    base_url,
    is_root,
    parent_href
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
        parent_href = child_parent_href
      )
    }
  }
  
  # Write items
  if (!is.null(stored_items) && length(stored_items) > 0) {
    items_dir <- file.path(path, "items")
    if (!dir.exists(items_dir)) {
      dir.create(items_dir, recursive = TRUE)
    }
    
    for (item in stored_items) {
      item_file <- file.path(items_dir, paste0(item$id, ".json"))
      
      # Update item links if needed
      if (catalog_type == "absolute") {
        item <- update_item_links(
          item,
          paste0(base_url, "/items/", item$id, ".json"),
          paste0(base_url, "/", catalog_file),
          if (is_root) paste0(base_url, "/", catalog_file) else NULL
        )
      } else {
        item <- update_item_links(
          item,
          paste0("./items/", item$id, ".json"),
          paste0("./", catalog_file),
          if (is_root) paste0("./", catalog_file) else "../catalog.json"
        )
      }
      
      write_item(item, item_file, overwrite = overwrite, pretty = pretty)
    }
  }
  
  # Write the catalog file itself
  catalog_filepath <- file.path(path, catalog_file)
  write_catalog(catalog, catalog_filepath, overwrite = overwrite, pretty = pretty)
  
  invisible(path)
}


#' Update Catalog Links for Filesystem Structure
#'
#' @description
#' Internal function to update links in a catalog to match the filesystem structure.
#'
#' @keywords internal
update_catalog_links <- function(catalog,
                                 path,
                                 catalog_type,
                                 base_url = NULL,
                                 is_root = FALSE,
                                 parent_href = NULL) {
  
  # Determine the catalog filename
  if (inherits(catalog, "stac_collection")) {
    catalog_file <- "collection.json"
  } else {
    catalog_file <- "catalog.json"
  }
  
  # Build self link
  if (catalog_type == "absolute") {
    self_href <- paste0(base_url, "/", catalog_file)
  } else {
    self_href <- paste0("./", catalog_file)
  }
  
  # Remove existing self link and add updated one
  catalog$links <- Filter(function(x) x$rel != "self", catalog$links)
  catalog <- add_self_link(catalog, self_href)
  
  # Add root link
  if (is_root) {
    catalog$links <- Filter(function(x) x$rel != "root", catalog$links)
    catalog <- add_root_link(catalog, self_href)
  } else {
    # For non-root catalogs, root points to the root
    if (catalog_type == "absolute") {
      # Get base_url without trailing path
      root_href <- sub("/[^/]+$", "/catalog.json", base_url)
    } else {
      # Calculate relative path to root (this assumes single-level nesting)
      root_href <- "../catalog.json"
    }
    catalog$links <- Filter(function(x) x$rel != "root", catalog$links)
    catalog <- add_root_link(catalog, root_href)
    
    # Add parent link
    if (!is.null(parent_href)) {
      catalog$links <- Filter(function(x) x$rel != "parent", catalog$links)
      catalog <- add_parent_link(catalog, parent_href)
    }
  }
  
  # Update child links based on stored children
  stored_children <- attr(catalog, "stac_children")
  if (!is.null(stored_children) && length(stored_children) > 0) {
    # Remove existing child links
    catalog$links <- Filter(function(x) x$rel != "child", catalog$links)
    
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
        title = child$title
      )
    }
  }
  
  # Update item links based on stored items
  stored_items <- attr(catalog, "stac_items")
  if (!is.null(stored_items) && length(stored_items) > 0) {
    # Remove existing item links
    catalog$links <- Filter(function(x) x$rel != "item", catalog$links)
    
    # Add updated item links
    for (item in stored_items) {
      if (catalog_type == "absolute") {
        item_href <- paste0(base_url, "/items/", item$id, ".json")
      } else {
        item_href <- paste0("./items/", item$id, ".json")
      }
      
      catalog <- add_link(
        catalog,
        rel = "item",
        href = item_href,
        type = "application/geo+json",
        title = item$properties$title
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
update_item_links <- function(item, self_href, parent_href, root_href) {
  
  # Update self link
  item$links <- Filter(function(x) x$rel != "self", item$links)
  item <- add_link(item, rel = "self", href = self_href, type = "application/geo+json")
  
  # Update parent link
  if (!is.null(parent_href)) {
    item$links <- Filter(function(x) x$rel != "parent", item$links)
    item <- add_link(item, rel = "parent", href = parent_href, type = "application/json")
    
    # If parent is a collection, also update collection link
    item$links <- Filter(function(x) x$rel != "collection", item$links)
    item <- add_link(item, rel = "collection", href = parent_href, type = "application/json")
  }
  
  # Update root link
  if (!is.null(root_href)) {
    item$links <- Filter(function(x) x$rel != "root", item$links)
    item <- add_link(item, rel = "root", href = root_href, type = "application/json")
  }
  
  item
}


#' Strip Stored Objects from STAC Object
#'
#' @description
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
#' Reads a STAC Catalog, Collection, or Item from a JSON file.
#'
#' @param file (character, required) Path to the STAC JSON file.
#'
#' @return A STAC object (catalog, collection, or item) with the appropriate class.
#'
#' @examples
#' \dontrun{
#' catalog <- read_stac("path/to/catalog.json")
#' item <- read_stac("path/to/item.json")
#' }
#'
#' @export
read_stac <- function(file) {
  
  if (!file.exists(file)) {
    stop(sprintf("File not found: %s", file))
  }
  
  # Read JSON
  stac_obj <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  
  # Determine type and assign appropriate class
  if (stac_obj$type == "Catalog") {
    class(stac_obj) <- c("stac_catalog", "list")
  } else if (stac_obj$type == "Collection") {
    class(stac_obj) <- c("stac_collection", "stac_catalog", "list")
  } else if (stac_obj$type == "Feature") {
    class(stac_obj) <- c("stac_item", "list")
  } else {
    warning(sprintf("Unknown STAC type: %s", stac_obj$type))
    class(stac_obj) <- "list"
  }
  
  stac_obj
}


#' Get Stored Children from Catalog
#'
#' @description
#' Retrieves the stored child catalogs/collections from a catalog object.
#'
#' @param catalog A STAC Catalog or Collection object.
#'
#' @return A named list of child catalogs/collections, or NULL if none exist.
#'
#' @examples
#' \dontrun{
#' children <- get_children(catalog)
#' names(children)  # Get IDs of child catalogs
#' }
#'
#' @export
get_children <- function(catalog) {
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  attr(catalog, "stac_children")
}


#' Get Stored Items from Catalog or Collection
#'
#' @description
#' Retrieves the stored items from a catalog or collection object.
#'
#' @param catalog A STAC Catalog or Collection object.
#'
#' @return A list of items, or NULL if none exist.
#'
#' @examples
#' \dontrun{
#' items <- get_items(collection)
#' length(items)  # Number of items
#' }
#'
#' @export
get_items <- function(catalog) {
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  attr(catalog, "stac_items")
}