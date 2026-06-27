#' Generate a Thumbnail PNG from a Terra SpatRaster Object
#'
#' @description
#' Renders a `SpatRaster` object to a PNG image and returns a STAC asset
#' pointing to it. Multi-band rasters with 3 or more bands are rendered as an
#' RGB composite using the first three bands; single-band rasters are rendered
#' as greyscale.
#'
#' @param terra_obj A `SpatRaster` object (from the `terra` package).
#' @param path (character, required) File path for the output PNG.
#' @param width (integer) Image width in pixels. Default is 256.
#' @param height (integer) Image height in pixels. Default is 256.
#' @param title (character, optional) Title for the returned asset.
#' @param ... Additional arguments passed to `terra::plotRGB()` or `terra::plot()`.
#'
#' @return A STAC asset list with `href`, `type = "image/png"`, and
#'   `roles = c("overview")`.
#'
#' @examples
#' \dontrun{
#' library(terra)
#'
#' r <- rast(system.file("ex/logo.tif", package = "terra"))
#' asset <- preview_from_terra(r, path = "thumbnail.png")
#'
#' item <- item_from_terra(r, href = "image.tif",
#'                         datetime = "2023-01-01T00:00:00Z")
#' item <- add_asset(item, key = "thumbnail", asset = asset)
#' }
#'
#' @export
preview_from_terra <- function(terra_obj, path, width = 256, height = 256,
                               title = NULL, ...) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required. Install with: install.packages('terra')")
  }
  if (!inherits(terra_obj, "SpatRaster")) {
    stop("'terra_obj' must be a SpatRaster object")
  }
  if (missing(path) || is.null(path) || nchar(path) == 0) {
    stop("'path' is required and must be a non-empty string")
  }

  grDevices::png(path, width = width, height = height)

  tryCatch({
    n_bands <- terra::nlyr(terra_obj)

    if (n_bands >= 3L) {
      terra::plotRGB(terra_obj[[1:3]], ...)
    } else {
      terra::plot(terra_obj[[1]], axes = FALSE, legend = FALSE, ...)
    }
  }, finally = {
    grDevices::dev.off()
  })

  stac_asset(
    href = normalize_href(path),
    title = title,
    type = "image/png",
    roles = c("overview")
  )
}


#' Generate a Thumbnail PNG from an sf Object
#'
#' @description
#' Renders the geometry of an `sf` object to a PNG image and returns a STAC
#' asset pointing to it.
#'
#' @param sf_obj An `sf` object.
#' @param path (character, required) File path for the output PNG.
#' @param width (integer) Image width in pixels. Default is 256.
#' @param height (integer) Image height in pixels. Default is 256.
#' @param title (character, optional) Title for the returned asset.
#' @param ... Additional arguments passed to `plot()`.
#'
#' @return A STAC asset list with `href`, `type = "image/png"`, and
#'   `roles = c("thumbnail")`.
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' asset <- thumbnail_from_sf(nc, path = "thumbnail.png")
#'
#' item <- item_from_sf(nc, id = "nc", datetime = "2023-01-01T00:00:00Z")
#' item <- add_asset(item, key = "thumbnail", asset = asset)
#' }
#'
#' @export
thumbnail_from_sf <- function(sf_obj, path, width = 256, height = 256,
                              title = NULL, ...) {
  if (!inherits(sf_obj, "sf")) {
    stop("'sf_obj' must be an sf object")
  }
  if (missing(path) || is.null(path) || nchar(path) == 0) {
    stop("'path' is required and must be a non-empty string")
  }

  grDevices::png(path, width = width, height = height)
  tryCatch({
    plot(sf::st_geometry(sf_obj), axes = FALSE, ...)
  }, finally = {
    grDevices::dev.off()
  })

  stac_asset(
    href = normalize_href(path),
    title = title,
    type = "image/png",
    roles = c("thumbnail")
  )
}
