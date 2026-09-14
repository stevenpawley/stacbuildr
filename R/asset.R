#' Create a STAC Asset
#'
#' @description
#' Creates an asset object for use in STAC Items. Assets are the actual data
#' files or resources associated with an Item (e.g., imagery files, metadata
#' documents, thumbnails).
#'
#' @param href (character, required) URI to the asset object. Can be relative or
#'   absolute. Examples: `"./data/image.tif"`,
#'   `"https://example.com/image.tif"`.
#' @param title (character, optional) Displayed title for the asset.
#' @param description (character, optional) Description of the asset.
#' @param type (character, optional) Media type of the asset. Examples:
#'   `"image/tiff; application=geotiff"`, `"image/png"`, `"application/json"`.
#'   See \url{https://www.iana.org/assignments/media-types/media-types.xhtml}.
#' @param roles (character vector, optional) Semantic roles of the asset. Common
#'   values include: `"thumbnail"`, `"overview"`, `"data"`, `"metadata"`,
#'   `"visual"`, `"composite"`.
#' @param ... Additional fields for the asset. This allows for common
#'   metadata such as `"bands"` and extension-specific properties like
#'   `"proj:shape"`, etc.
#'
#' @return An S7 asset. Access core fields with `asset@href` and arbitrary
#'   metadata with `asset@extra_fields`.
#'
#' @details
#' `roles` is a character vector in memory and a JSON array when serialized.
#' Assets retain their S7 class when attached to Items or Collections and when
#' restored with [read_stac()]. The assets dictionary remains a named list:
#' use `item@assets[["data"]]@href` to access an asset's URL.
#' Use `as.list(asset)` to obtain the JSON-ready representation.
#'
#' @examples
#' # Simple asset
#' asset <- stac_asset(
#'   href = "https://example.com/image.tif",
#'   title = "RGB Image",
#'   type = "image/tiff; application=geotiff"
#' )
#'
#' # Asset with roles
#' asset <- stac_asset(
#'   href = "./data/LC08_B4.tif",
#'   title = "Band 4 - Red",
#'   type = "image/tiff; application=geotiff",
#'   roles = c("data", "reflectance")
#' )
#' asset@href
#' asset@roles
#'
#' # Asset with extension properties
#' asset <- stac_asset(
#'   href = "./data/multispectral.tif",
#'   type = "image/tiff; application=geotiff; profile=cloud-optimized",
#'   roles = c("data"),
#'   bands = list(
#'     list(name = "B1", "eo:common_name" = "red",
#'          "eo:center_wavelength" = 0.665, data_type = "uint16"),
#'     list(name = "B2", "eo:common_name" = "green",
#'          "eo:center_wavelength" = 0.560, data_type = "uint16"),
#'     list(name = "B3", "eo:common_name" = "blue",
#'          "eo:center_wavelength" = 0.490, data_type = "uint16")
#'   )
#' )
#'
#' @export
stac_asset <- S7::new_class(
  "stac_asset",
  properties = list(
    href = S7::new_property(S7::class_character, validator = function(value) {
      if (length(value) != 1L || is.na(value) || !nzchar(value)) {
        "'href' must be a non-empty string"
      }
    }),
    title = S7::new_union(S7::class_character, NULL),
    description = S7::new_union(S7::class_character, NULL),
    type = S7::new_union(S7::class_character, NULL),
    roles = S7::new_union(S7::class_character, NULL),
    extra_fields = S7::new_property(S7::class_list, default = list())
  ),
  constructor = function(
    href,
    title = NULL,
    description = NULL,
    type = NULL,
    roles = NULL,
    ...
  ) {
    if (is.list(roles)) {
      roles <- unlist(roles, use.names = FALSE)
    }
    S7::new_object(
      S7::S7_object(),
      href = href,
      title = title,
      description = description,
      type = type,
      roles = roles,
      extra_fields = normalize_common_arrays(list(...))
    )
  }
)

S7::method(as.list, stac_asset) <- function(x, ...) {
  out <- list(href = x@href)
  for (field in c("title", "description", "type", "roles")) {
    value <- S7::prop(x, field)
    if (!is.null(value)) out[[field]] <- value
  }
  normalize_common_arrays(c(out, x@extra_fields))
}

# Normalize legacy lists and parsed JSON at object boundaries.
as_stac_asset <- function(x) {
  if (S7::S7_inherits(x, stac_asset)) {
    return(x)
  }
  if (!is.list(x) || is.null(x$href)) {
    cli::cli_abort(c(
      "'asset' must be a stac_asset or a list with an 'href' field",
      "i" = "Use stac_asset() to build one."
    ))
  }
  if (!is.null(x$roles)) {
    x$roles <- unlist(x$roles, use.names = FALSE)
  }
  do.call(stac_asset, x)
}

normalize_assets <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  lapply(x, as_stac_asset)
}


#' Print method for STAC assets
#'
#' @param x A STAC asset object created with [stac_asset()].
#' @param ... Additional arguments (ignored).
#' @param expand Controls the collapsible extension-field section. `TRUE`
#'   expands it, `FALSE` (the default) collapses it, or give the section name
#'   `"fields"`. Defaults to the `stacbuildr.print.expand` option.
#'
#' @return `x`, invisibly.
#'
#' @noRd
S7::method(print, stac_asset) <- function(x, ..., expand = NULL) {
  stac_print_header("STAC Asset")
  stac_print_field("href", x@href, stac_style_url)

  if (!is.null(x@title)) {
    stac_print_field("title", x@title)
  }
  if (!is.null(x@type)) {
    stac_print_field("type", x@type, stac_style_key)
  }
  if (!is.null(x@roles)) {
    stac_print_field(
      "roles",
      sprintf(
        "[%s]",
        paste(x@roles, collapse = ", ")
      )
    )
  }
  if (!is.null(x@description)) {
    stac_print_field("description", x@description)
  }

  fields <- x@extra_fields
  collapsed <- if (length(fields) > 0) {
    stac_print_section(
      "fields",
      length(fields),
      summary = stac_preview(names(fields)),
      lines = function() stac_field_lines(fields),
      expanded = stac_expanded(expand, "fields")
    )
  } else {
    FALSE
  }

  stac_print_hint(sum(collapsed))

  invisible(x)
}


#' Add an Asset to a STAC Item
#'
#' @description
#' Adds an asset to a STAC Item's assets dictionary.
#'
#' @param item A STAC Item object.
#' @param key (character, required) The asset identifier/key (e.g., "visual",
#'   "thumbnail", "B4"). Must be unique within the Item's assets.
#' @param asset An optional asset object previously created using `stac_asset()`.
#'   Alternatively, the asset can be created from the `add_asset` arguments.
#' @param href (character, required) URI to the asset object.
#' @param title (character, optional) Displayed title for the asset.
#' @param description (character, optional) Description of the asset.
#' @param type (character, optional) Media type of the asset.
#' @param roles (character vector, optional) Semantic roles of the asset.
#' @param ... Additional asset fields (extension properties).
#'
#' @return The modified Item object with the asset added.
#'
#' @examples
#' item <- stac_item(
#'   id = "my-item",
#'   geometry = list(type = "Point", coordinates = c(-105, 40)),
#'   bbox = c(-105, 40, -105, 40),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' item <- add_asset(
#'   item,
#'   key = "visual",
#'   href = "https://example.com/visual.tif",
#'   title = "True Color Image",
#'   type = "image/tiff; application=geotiff",
#'   roles = c("visual")
#' )
#'
#' @export
add_asset <- function(
  item,
  key,
  asset = NULL,
  href = NULL,
  title = NULL,
  description = NULL,
  type = NULL,
  roles = NULL,
  ...
) {
  if (!S7::S7_inherits(item, stac_item)) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  if (missing(key) || is.null(key) || nchar(key) == 0) {
    cli::cli_abort("'key' is required and must be a non-empty string")
  }

  # If an asset object is provided, validate it
  if (!is.null(asset)) {
    asset <- as_stac_asset(asset)
  } else {
    # Alternatively, create an asset from the provided fields
    asset <- stac_asset(
      href = href,
      title = title,
      description = description,
      type = type,
      roles = roles,
      ...
    )
  }

  # Initialize the assets list if it doesn't exist in the item
  if (is.null(item@assets)) {
    item@assets <- list()
  }

  # Assign the asset to the specified key in the item's assets
  item@assets[[key]] <- asset

  return(item)
}
