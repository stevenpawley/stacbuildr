#' Add an Item to a STAC Catalog or Collection
#'
#' @description
#' Adds a STAC Item to a Catalog or Collection by creating the appropriate link 
#' relationship. This function modifies the catalog/collection object to include 
#' an `"item"` link pointing to the Item. Optionally, it can also modify the Item 
#' to include links back to the parent (`"parent"`, `"collection"`, and `"root"`).
#'
#' @param catalog A STAC Catalog or Collection object (created with 
#'   `stac_catalog()` or `stac_collection()`).
#' @param item A STAC Item object (created with `stac_item()`). Can also be a 
#'   list of Items to add multiple items at once.
#' @param href (character, optional) The relative or absolute path where the 
#'   Item JSON file will be located. If `NULL` (default), generates a path 
#'   based on the item's ID: `"./items/{item$id}.json"`. Can be a vector of 
#'   paths when `item` is a list.
#' @param add_parent_links (logical, optional) If `TRUE`, modifies the Item(s) 
#'   to include reciprocal links back to the parent catalog. Adds `"parent"` and 
#'   `"root"` links. If the parent is a Collection, also adds a `"collection"` 
#'   link. Default is `FALSE` to avoid modifying the original Item object.
#' @param parent_href (character, optional) The href for the parent catalog/collection. 
#'   Only used if `add_parent_links = TRUE`. If not provided and a `"self"` link 
#'   exists in the catalog, uses that; otherwise uses a placeholder.
#' @param root_href (character, optional) The href for the root catalog. Only used 
#'   if `add_parent_links = TRUE`. If not provided, attempts to use the catalog's 
#'   `"root"` link or defaults to `parent_href`.
#'
#' @details
#' ## Link Relations
#' This function creates an `"item"` link in the catalog that points to the Item. 
#' Based on the STAC specification, Items are strongly 
#' recommended to provide a link to a STAC Collection, so when adding 
#' Items to a Collection, consider setting `add_parent_links = TRUE`.
#' 
#' When `add_parent_links = TRUE`:
#' * Adds `"parent"` link to the Item pointing to the catalog/collection
#' * Adds `"root"` link to the Item pointing to the root catalog
#' * If parent is a Collection, adds `"collection"` link and sets the `collection` 
#'   property in the Item (required when collection link is present)
#'
#' ## Multiple Items
#' You can add multiple items at once by passing a list of Item objects. In this 
#' case, `href` should be either:
#' * `NULL` to auto-generate paths for all items
#' * A vector of the same length as the number of items
#'
#' ## Item Requirements
#' Based on the STAC Item specification, each 
#' Item must have the following fields:
#' * `type`: "Feature"
#' * `stac_version`: e.g., "1.1.0"
#' * `id`: Unique identifier within the collection
#' * `geometry`: GeoJSON geometry or null
#' * `bbox`: Bounding box (required if geometry is not null)
#' * `properties`: Object with metadata (must include `datetime`)
#' * `links`: Array of links
#' * `assets`: Object describing available data files
#'
#' @return The modified catalog/collection object with the Item link(s) added. 
#'   If `add_parent_links = TRUE`, also returns the Item(s) with updated links 
#'   as an attribute named `"items"` (accessible via `attr(result, "items")`).
#'
#' @seealso 
#' * [stac_item()] for creating STAC Items
#' * [stac_catalog()] for creating STAC Catalogs
#' * [stac_collection()] for creating STAC Collections
#' * [add_link()] for adding links to STAC objects
#' * [add_child()] for adding child catalogs/collections
#'
#' @examples
#' # Create a collection
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
#' # Create an item
#' item <- stac_item(
#'   id = "LC08_L1TP_001001_20200101_20200101_01_T1",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-180, -90), c(180, -90), c(180, 90), c(-180, 90), c(-180, -90)
#'     ))
#'   ),
#'   bbox = c(-180, -90, 180, 90),
#'   datetime = "2020-01-01T00:00:00Z",
#'   properties = list()
#' )
#'
#' # Add the item to the collection (simple)
#' collection <- add_item(collection, item)
#'
#' # Add the item with parent links
#' collection <- add_item(
#'   collection, 
#'   item,
#'   add_parent_links = TRUE,
#'   parent_href = "./collection.json",
#'   root_href = "../catalog.json"
#' )
#'
#' # Add multiple items
#' items <- list(item1, item2, item3)
#' collection <- add_item(collection, items)
#'
#' # Add multiple items with custom hrefs
#' collection <- add_item(
#'   collection,
#'   items,
#'   href = c("./2020/item1.json", "./2020/item2.json", "./2020/item3.json")
#' )
#'
#' @export
add_item <- function(catalog,
                    item,
                    href = NULL,
                    add_parent_links = FALSE,
                    parent_href = NULL,
                    root_href = NULL) {
  
  # Validate catalog
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  # Handle single item vs list of items
  is_list_of_items <- is.list(item) && 
                      !inherits(item, "stac_item") &&
                      all(sapply(item, inherits, "stac_item"))
  
  if (is_list_of_items) {
    items_list <- item
    n_items <- length(items_list)
  } else if (inherits(item, "stac_item")) {
    items_list <- list(item)
    n_items <- 1
  } else {
    stop("'item' must be a stac_item object or a list of stac_item objects")
  }
  
  # Validate href if provided
  if (!is.null(href)) {
    if (length(href) != n_items) {
      stop(sprintf(
        "'href' must be NULL or have length %d (same as number of items)",
        n_items
      ))
    }
  } else {
    # Auto-generate hrefs
    href <- vapply(items_list, function(it) {
      paste0("./items/", it$id, ".json")
    }, character(1))
  }
  
  # Determine if catalog is a Collection
  is_collection <- inherits(catalog, "stac_collection")
  
  # Get parent and root hrefs for backlinks
  if (add_parent_links) {
    if (is.null(parent_href)) {
      # Try to find self link
      self_link <- find_link(catalog, "self")
      parent_href <- if (!is.null(self_link)) {
        self_link$href
      } else {
        "./catalog.json"  # Placeholder
      }
    }
    
    if (is.null(root_href)) {
      # Try to find root link
      root_link <- find_link(catalog, "root")
      root_href <- if (!is.null(root_link)) {
        root_link$href
      } else {
        parent_href  # Use parent as root if no root link
      }
    }
  }
  
  # Process each item
  updated_items <- list()
  
  for (i in seq_along(items_list)) {
    current_item <- items_list[[i]]
    current_href <- href[i]
    
    # Add item link to catalog
    catalog <- add_link(
      catalog,
      rel = "item",
      href = current_href,
      type = "application/geo+json",
      title = current_item$properties$title
    )
    
    # Add parent links to item if requested
    if (add_parent_links) {
      # Add parent link
      current_item <- add_link(
        current_item,
        rel = "parent",
        href = parent_href,
        type = "application/json"
      )
      
      # Add root link
      current_item <- add_link(
        current_item,
        rel = "root",
        href = root_href,
        type = "application/json"
      )
      
      # If parent is a collection, add collection link and property
      if (is_collection) {
        current_item <- add_link(
          current_item,
          rel = "collection",
          href = parent_href,
          type = "application/json"
        )
        
        # Set collection property (required when collection link present)
        current_item$collection <- catalog$id
      }
    }
    
    updated_items[[i]] <- current_item
  }
  
  # Store items in catalog for later retrieval (e.g., by write_stac)
  stored_items <- attr(catalog, "stac_items")
  if (is.null(stored_items)) {
    stored_items <- list()
  }
  
  # Add new items to stored items
  if (add_parent_links && length(updated_items) > 0) {
    stored_items <- c(stored_items, updated_items)
  } else {
    stored_items <- c(stored_items, items_list)
  }
  
  attr(catalog, "stac_items") <- stored_items
  
  catalog
}


#' Find a Link by Relation Type
#'
#' @description
#' Helper function to find a link with a specific relation type in a STAC object.
#'
#' @param stac_object A STAC Catalog, Collection, or Item object.
#' @param rel The link relation type to find (e.g., "self", "root", "parent").
#'
#' @return The first link object with the matching rel type, or NULL if not found.
#'
#' @keywords internal
find_link <- function(stac_object, rel) {
  if (!is.list(stac_object$links) || length(stac_object$links) == 0) {
    return(NULL)
  }
  
  for (link in stac_object$links) {
    if (!is.null(link$rel) && link$rel == rel) {
      return(link)
    }
  }
  
  NULL
}


#' Remove Items from a STAC Catalog or Collection
#'
#' @description
#' Removes Item link(s) from a Catalog or Collection. Can remove by Item ID, 
#' href, or remove all items.
#'
#' @param catalog A STAC Catalog or Collection object.
#' @param item_id (character, optional) ID(s) of the item(s) to remove. The 
#'   function will attempt to match these IDs from the href (e.g., if href is 
#'   "./items/my-item.json", it will match item_id "my-item").
#' @param href (character, optional) Specific href(s) to remove.
#' @param all (logical, optional) If `TRUE`, removes all item links. Default is 
#'   `FALSE`. Use with caution.
#'
#' @return The modified catalog/collection object with Item link(s) removed.
#'
#' @examples
#' # Remove specific item by ID
#' catalog <- remove_item(catalog, item_id = "my-item-001")
#'
#' # Remove multiple items
#' catalog <- remove_item(catalog, item_id = c("item1", "item2"))
#'
#' # Remove by href
#' catalog <- remove_item(catalog, href = "./items/my-item.json")
#'
#' # Remove all items
#' catalog <- remove_item(catalog, all = TRUE)
#'
#' @export
remove_item <- function(catalog, item_id = NULL, href = NULL, all = FALSE) {
  
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  if (!all && is.null(item_id) && is.null(href)) {
    stop("Must specify 'item_id', 'href', or set 'all = TRUE'")
  }
  
  if (all) {
    # Remove all item links
    catalog$links <- Filter(function(link) link$rel != "item", catalog$links)
    return(catalog)
  }
  
  # Build a filter function
  should_keep <- function(link) {
    if (link$rel != "item") {
      return(TRUE)  # Keep non-item links
    }
    
    # Check href match
    if (!is.null(href) && link$href %in% href) {
      return(FALSE)
    }
    
    # Check item_id match (extract from href)
    if (!is.null(item_id)) {
      # Extract potential ID from href (e.g., "./items/my-item.json" -> "my-item")
      extracted_id <- sub("\\.json$", "", basename(link$href))
      if (extracted_id %in% item_id) {
        return(FALSE)
      }
    }
    
    TRUE
  }
  
  catalog$links <- Filter(should_keep, catalog$links)
  catalog
}


#' Count Items in a STAC Catalog or Collection
#'
#' @description
#' Counts the number of Item links in a Catalog or Collection.
#'
#' @param catalog A STAC Catalog or Collection object.
#'
#' @return Integer count of item links.
#'
#' @examples
#' n <- count_items(catalog)
#' cat("Catalog contains", n, "items\n")
#'
#' @export
count_items <- function(catalog) {
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  if (is.null(catalog$links) || length(catalog$links) == 0) {
    return(0L)
  }
  
  sum(vapply(catalog$links, function(link) {
    !is.null(link$rel) && link$rel == "item"
  }, logical(1)))
}


#' Get All Item Links from a STAC Catalog or Collection
#'
#' @description
#' Retrieves all Item links from a Catalog or Collection.
#'
#' @param catalog A STAC Catalog or Collection object.
#' @param as_dataframe (logical, optional) If `TRUE`, returns results as a 
#'   data.frame. Default is `FALSE` (returns list).
#'
#' @return A list of link objects (or data.frame if `as_dataframe = TRUE`) 
#'   containing all item links.
#'
#' @examples
#' # Get as list
#' item_links <- get_item_links(catalog)
#'
#' # Get as data.frame
#' item_df <- get_item_links(catalog, as_dataframe = TRUE)
#' print(item_df)
#'
#' @export
get_item_links <- function(catalog, as_dataframe = FALSE) {
  if (!inherits(catalog, "stac_catalog")) {
    stop("'catalog' must be a stac_catalog or stac_collection object")
  }
  
  if (is.null(catalog$links) || length(catalog$links) == 0) {
    return(if (as_dataframe) data.frame() else list())
  }
  
  item_links <- Filter(function(link) {
    !is.null(link$rel) && link$rel == "item"
  }, catalog$links)
  
  if (as_dataframe && length(item_links) > 0) {
    data.frame(
      href = vapply(item_links, function(x) x$href, character(1)),
      type = vapply(item_links, function(x) x$type %||% NA_character_, character(1)),
      title = vapply(item_links, function(x) x$title %||% NA_character_, character(1)),
      stringsAsFactors = FALSE
    )
  } else {
    item_links
  }
}


# Helper operator for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a