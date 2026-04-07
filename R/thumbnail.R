#' Generate a Thumbnail PNG from a Stars Raster Object
#'
#' @description
#' Renders a `stars` raster object to a PNG image and returns a STAC asset
#' pointing to it. Multi-band rasters with 3 or more bands are rendered as an
#' RGB composite using the first three bands; single-band rasters are rendered
#' as greyscale.
#'
#' @param stars_obj A `stars` object.
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
#' library(stars)
#'
#' r <- read_stars(system.file("tif/L7_ETMs.tif", package = "stars"))
#' asset <- thumbnail_from_raster(r, path = "thumbnail.png")
#'
#' item <- item_from_raster(r, href = "image.tif", datetime = "2023-01-01T00:00:00Z")
#' item <- add_asset(item, key = "thumbnail", asset = asset)
#' }
#'
#' @export
thumbnail_from_raster <- function(stars_obj, path, width = 256, height = 256,
                                  title = NULL, ...) {
  if (!requireNamespace("stars", quietly = TRUE)) {
    stop("Package 'stars' is required. Install with: install.packages('stars')")
  }
  if (!inherits(stars_obj, "stars")) {
    stop("'stars_obj' must be a stars object")
  }
  if (missing(path) || is.null(path) || nchar(path) == 0) {
    stop("'path' is required and must be a non-empty string")
  }

  grDevices::png(path, width = width, height = height)
  tryCatch({
    dims <- dim(stars_obj)
    has_band_dim <- length(dims) >= 3
    n_bands <- if (has_band_dim) dims[3L] else 1L

    if (has_band_dim && n_bands >= 3L) {
      plot(stars_obj[, , , 1:3], rgb = 1:3, axes = FALSE, key.pos = NULL,
           main = "", ...)
    } else if (has_band_dim && n_bands > 1L) {
      plot(stars_obj[, , , 1L], axes = FALSE, key.pos = NULL, main = "", ...)
    } else {
      plot(stars_obj, axes = FALSE, key.pos = NULL, main = "", ...)
    }
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
