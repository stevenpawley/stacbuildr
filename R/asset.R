#' Create a STAC Asset
#'
#' @description
#' Creates an asset object for use in STAC Items. Assets are the actual data 
#' files or resources associated with an Item (e.g., imagery files, metadata 
#' documents, thumbnails).
#'
#' @param href (character, required) URI to the asset object. Can be relative 
#'   or absolute. Examples: `"./data/image.tif"`, `"https://example.com/image.tif"`.
#' @param title (character, optional) Displayed title for the asset.
#' @param description (character, optional) Description of the asset.
#' @param type (character, optional) Media type of the asset. Examples: 
#'   `"image/tiff; application=geotiff"`, `"image/png"`, `"application/json"`. 
#'   See \url{https://www.iana.org/assignments/media-types/media-types.xhtml}.
#' @param roles (character vector, optional) Semantic roles of the asset. Common 
#'   values include: `"thumbnail"`, `"overview"`, `"data"`, `"metadata"`, 
#'   `"visual"`, `"composite"`.
#' @param ... Additional fields for the asset. This allows for extension-specific 
#'   properties like `"eo:bands"`, `"raster:bands"`, `"proj:shape"`, etc.
#'
#' @return A list representing a STAC asset object.
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
#'
#' # Asset with extension properties
#' asset <- stac_asset(
#'   href = "./data/multispectral.tif",
#'   type = "image/tiff; application=geotiff; profile=cloud-optimized",
#'   roles = c("data"),
#'   "eo:bands" = list(
#'     list(name = "B1", common_name = "red", center_wavelength = 0.665),
#'     list(name = "B2", common_name = "green", center_wavelength = 0.560),
#'     list(name = "B3", common_name = "blue", center_wavelength = 0.490)
#'   ),
#'   "raster:bands" = list(
#'     list(data_type = "uint16", scale = 0.0001, offset = 0)
#'   )
#' )
#'
#' @export
stac_asset <- function(href,
                      title = NULL,
                      description = NULL,
                      type = NULL,
                      roles = NULL,
                      ...) {
  
  if (missing(href) || is.null(href) || nchar(href) == 0) {
    stop("'href' is required and must be a non-empty string")
  }
  
  asset <- list(href = href)
  
  if (!is.null(title)) asset$title <- title
  if (!is.null(description)) asset$description <- description
  if (!is.null(type)) asset$type <- type
  if (!is.null(roles)) asset$roles <- roles
  
  # Add extension fields
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    asset <- c(asset, extra_fields)
  }
  
  asset
}


#' Add an Asset to a STAC Item
#'
#' @description
#' Adds an asset to a STAC Item's assets dictionary.
#'
#' @param item A STAC Item object.
#' @param key (character, required) The asset identifier/key (e.g., "visual", 
#'   "thumbnail", "B4"). Must be unique within the Item's assets.
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
add_asset <- function(item,
                     key,
                     href,
                     title = NULL,
                     description = NULL,
                     type = NULL,
                     roles = NULL,
                     ...) {
  
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }
  
  if (missing(key) || is.null(key) || nchar(key) == 0) {
    stop("'key' is required and must be a non-empty string")
  }
  
  asset <- stac_asset(
    href = href,
    title = title,
    description = description,
    type = type,
    roles = roles,
    ...
  )
  
  if (is.null(item$assets)) {
    item$assets <- list()
  }
  
  item$assets[[key]] <- asset
  
  item
}

