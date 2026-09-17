#' Add an Item to a STAC Catalog or Collection
#'
#' @description
#' Adds one or more STAC Items to a Catalog or Collection. An `"item"` link is
#' added immediately, and the complete Item is retained internally so that
#' [write_stac()] can write it as part of the catalog tree.
#'
#' @param catalog A STAC Catalog or Collection object (created with
#'   `stac_catalog()` or `stac_collection()`).
#' @param item A STAC Item object (created with `stac_item()`). Can also be a
#'   list of Items to add multiple items at once.
#' @param href (character, optional) Href for each Item link. If `NULL`, uses
#'   `"./{item$id}/{item$id}.json"`. Supply one href per Item. [write_stac()]
#'   regenerates these hrefs for its output layout and `catalog_type`.
#' @param add_parent_links (logical, optional) If `TRUE`, add `"parent"` and
#'   `"root"` links to each retained Item. Items added to a Collection also get
#'   a `"collection"` link and `collection` field. Default is `FALSE`.
#' @param parent_href (character, optional) The href for the parent catalog/collection.
#'   Only used if `add_parent_links = TRUE`. If not provided and a `"self"` link
#'   exists in the catalog, uses that; otherwise uses a placeholder.
#' @param root_href (character, optional) The href for the root catalog. Only used
#'   if `add_parent_links = TRUE`. If not provided, attempts to use the catalog's
#'   `"root"` link or defaults to `parent_href`.
#'
#' @details
#' A Catalog's `links` property contains links to Items, not the Items
#' themselves. Complete Items are retained in the internal `"stac_items"`
#' attribute, which is excluded from Catalog JSON. Use [get_items()] to retrieve
#' them. See `vignette("stac-catalog")` for the full writing model.
#'
#' @return The modified catalog/collection object with the Item link(s) added
#'   and the complete Item object(s) retained internally for [write_stac()].
#'
#' @seealso
#' * [stac_item()] for creating STAC Items
#' * [add_link()] for adding links to STAC objects
#' * [add_child()] for adding child catalogs/collections
#'
#' @examples
#' catalog <- stac_catalog(id = "example", description = "Example catalog")
#' item <- stac_item(
#'   id = "item-1",
#'   geometry = NULL,
#'   bbox = NULL,
#'   datetime = "2020-01-01T00:00:00Z"
#' )
#'
#' catalog <- add_item(catalog, item)
#' get_item_links(catalog)
#' get_items(catalog)
#'
#' @export
add_item <- function(
  catalog,
  item,
  href = NULL,
  add_parent_links = FALSE,
  parent_href = NULL,
  root_href = NULL
) {
  # Validate catalog
  if (!stac_inherits(catalog, stac_catalog)) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  # Handle single item vs list of items
  is_list_of_items <- is.list(item) &&
    !stac_inherits(item, stac_item) &&
    all(vapply(item, stac_inherits, logical(1), class = stac_item))

  if (is_list_of_items) {
    items_list <- item
    n_items <- length(items_list)
  } else if (stac_inherits(item, stac_item)) {
    items_list <- list(item)
    n_items <- 1
  } else {
    cli::cli_abort(
      "'item' must be a stac_item object or a list of stac_item objects"
    )
  }

  check_duplicate_ids(
    new_ids = vapply(items_list, function(it) it$id, character(1)),
    existing_ids = vapply(
      attr(catalog, "stac_items") %||% list(),
      function(it) it$id,
      character(1)
    ),
    what = "an item"
  )

  # Validate href if provided
  if (!is.null(href)) {
    if (length(href) != n_items) {
      cli::cli_abort(
        "'href' must be NULL or have length {n_items} (same as number of items)"
      )
    }
  } else {
    # Auto-generate hrefs (each item lives in its own subdirectory)
    href <- vapply(
      items_list,
      function(it) {
        paste0("./", it$id, "/", it$id, ".json")
      },
      character(1)
    )
  }

  # Determine if catalog is a Collection
  is_collection <- stac_inherits(catalog, stac_collection)

  # Get parent and root hrefs for backlinks
  if (add_parent_links) {
    if (is.null(parent_href)) {
      # Try to find self link
      self_link <- find_link(catalog, "self")
      parent_href <- if (!is.null(self_link)) {
        self_link$href
      } else {
        "./catalog.json" # Placeholder
      }
    }

    if (is.null(root_href)) {
      # Try to find root link
      root_link <- find_link(catalog, "root")
      root_href <- if (!is.null(root_link)) {
        root_link$href
      } else {
        parent_href # Use parent as root if no root link
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
      title = current_item$properties[["title"]]
    )

    # Always set top-level collection field when parent is a collection
    # (STAC 1.1 requires this whenever a collection link is present)
    if (is_collection) {
      current_item$collection <- catalog$id
    }

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

      # If parent is a collection, add collection link
      if (is_collection) {
        current_item <- add_link(
          current_item,
          rel = "collection",
          href = parent_href,
          type = "application/json"
        )
      }
    }

    updated_items[[i]] <- current_item
  }

  # Store items in catalog for later retrieval (e.g., by write_stac)
  stored_items <- attr(catalog, "stac_items")
  if (is.null(stored_items)) {
    stored_items <- list()
  }

  stored_items <- c(stored_items, updated_items)

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
#' @noRd
find_link <- function(stac_object, rel) {
  links <- stac_object$links
  if (!is.list(links) || length(links) == 0) {
    return(NULL)
  }

  for (link in links) {
    if (link$rel == rel) {
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
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
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
  if (!stac_inherits(catalog, stac_catalog)) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  if (!all && is.null(item_id) && is.null(href)) {
    cli::cli_abort("Must specify 'item_id', 'href', or set 'all = TRUE'")
  }

  if (all) {
    catalog$links <- Filter(function(link) link$rel != "item", catalog$links)
    return(drop_stored_items(catalog, keep = character(0)))
  }

  # Build a filter function
  should_keep <- function(link) {
    if (link$rel != "item") {
      return(TRUE) # Keep non-item links
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

  removed <- vapply(
    Filter(function(l) !should_keep(l), catalog$links),
    stac_id_from_link,
    character(1)
  )

  catalog$links <- Filter(should_keep, catalog$links)

  stored <- attr(catalog, "stac_items") %||% list()
  keep <- setdiff(vapply(stored, function(it) it$id, character(1)), removed)
  drop_stored_items(catalog, keep = keep)
}

# The id an item link points at, taken from the href the same way should_keep()
# matches on it.
#
# @keywords internal
stac_id_from_link <- function(link) {
  sub("\\.json$", "", basename(link$href))
}

# Keep only the stored Items whose ids are in `keep`.
#
# remove_item() drops item links, but write_stac() rebuilds those links from
# the items held in the "stac_items" attribute. Dropping the link alone would
# therefore be undone on write, leaving the removed item both linked and
# written to disk, so the stored copy has to go with it.
#
# @keywords internal
drop_stored_items <- function(catalog, keep) {
  stored <- attr(catalog, "stac_items")
  if (is.null(stored)) {
    return(catalog)
  }

  ids <- vapply(stored, function(it) it$id, character(1))
  attr(catalog, "stac_items") <- stored[ids %in% keep]
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
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#' n <- count_items(catalog)
#' cat("Catalog contains", n, "items\n")
#'
#' @export
count_items <- function(catalog) {
  if (!stac_inherits(catalog, stac_catalog)) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  if (is.null(catalog$links) || length(catalog$links) == 0) {
    return(0L)
  }

  sum(vapply(
    catalog$links,
    function(link) {
      link$rel == "item"
    },
    logical(1)
  ))
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
#' catalog <- stac_catalog(
#'   id = "my-catalog",
#'   description = "Example catalog"
#' )
#'
#' # Get as list
#' item_links <- get_item_links(catalog)
#'
#' # Get as data.frame
#' item_df <- get_item_links(catalog, as_dataframe = TRUE)
#' print(item_df)
#'
#' @export
get_item_links <- function(catalog, as_dataframe = FALSE) {
  if (!stac_inherits(catalog, stac_catalog)) {
    cli::cli_abort(
      "'catalog' must be a stac_catalog or stac_collection object"
    )
  }

  if (is.null(catalog$links) || length(catalog$links) == 0) {
    return(if (as_dataframe) data.frame() else list())
  }

  item_links <- Filter(
    function(link) {
      link$rel == "item"
    },
    catalog$links
  )

  if (as_dataframe && length(item_links) > 0) {
    data.frame(
      href = vapply(item_links, function(x) x$href, character(1)),
      type = vapply(
        item_links,
        function(x) x$type %||% NA_character_,
        character(1)
      ),
      title = vapply(
        item_links,
        function(x) x$title %||% NA_character_,
        character(1)
      ),
      stringsAsFactors = FALSE
    )
  } else {
    item_links
  }
}
