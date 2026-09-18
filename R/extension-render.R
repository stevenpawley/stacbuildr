# render extension ----

#' Create a STAC Render Object
#'
#' @description
#' Creates a render object for use with the STAC Render Extension. A render
#' object describes how one or more assets should be visualized (e.g. in a
#' web map or dynamic tile server).
#'
#' @param assets (character, required) Asset keys referencing the assets that
#'   are used to make the rendering. These must be local asset keys defined
#'   in the same STAC Item.
#' @param title (character, optional) Title of the rendering.
#' @param rescale (list, optional) A list of numeric vectors, each of length 2,
#'   giving the minimum and maximum range per band. For example,
#'   `list(c(0, 10000), c(0, 10000), c(0, 10000))` for an RGB composite.
#' @param nodata (numeric or character, optional) Nodata value to use for the
#'   referenced assets.
#' @param colormap_name (character, optional) Named color map to apply to a
#'   raster band (e.g. `"ylgn"`, `"rainbow"`).
#' @param colormap (list, optional) A custom color map JSON definition.
#' @param color_formula (character, optional) Color formula to apply to a
#'   raster band (see TiTiler documentation for examples).
#' @param resampling (character, optional) GDAL resampling algorithm to apply
#'   to the referenced assets (e.g. `"nearest"`, `"bilinear"`, `"average"`).
#' @param expression (character, optional) Band arithmetic formula to apply to
#'   the referenced assets (e.g. `"(B5-B4)/(B5+B4)"`).
#' @param minmax_zoom (numeric, optional) Zoom level range applicable for the
#'   visualization, as a length-2 numeric vector `c(min_zoom, max_zoom)`.
#' @param bidx (numeric, optional) Band indexes to use for rendering.
#' @param ... Additional fields allowed by the open-ended Render Object schema.
#'
#' @return A `render_object` S3 object. Access fields with `$`.
#'
#' @details
#' ## Render Object Fields
#' The Render Extension defines the following standard fields inside each
#' render object:
#' * `assets`: Required. Asset keys used for rendering.
#' * `title`: Optional human-readable title.
#' * `rescale`: Optional per-band min/max ranges.
#' * `nodata`: Optional nodata value.
#' * `colormap_name`: Optional named color map.
#' * `colormap`: Optional custom color map definition.
#' * `color_formula`: Optional color formula.
#' * `resampling`: Optional resampling method.
#' * `expression`: Optional band arithmetic expression.
#' * `minmax_zoom`: Optional zoom level range.
#' * `bidx`: Optional band indexes.
#'
#' Additional fields may be supplied via `...`.
#'
#' @examples
#' rgb_render <- render_object(
#'   assets = c("B4", "B3", "B2"),
#'   title = "True Color",
#'   rescale = list(c(0, 10000), c(0, 10000), c(0, 10000)),
#'   resampling = "bilinear"
#' )
#'
#' ndvi_render <- render_object(
#'   assets = c("B5", "B4"),
#'   title = "NDVI",
#'   expression = "(B5-B4)/(B5+B4)",
#'   rescale = list(c(-1, 1)),
#'   colormap_name = "ylgn",
#'   resampling = "average"
#' )
#'
#' @export
render_object <- function(
  assets,
  title = NULL,
  rescale = NULL,
  nodata = NULL,
  colormap_name = NULL,
  colormap = NULL,
  color_formula = NULL,
  resampling = NULL,
  expression = NULL,
  minmax_zoom = NULL,
  bidx = NULL,
  ...
) {
  if (missing(assets)) {
    cli::cli_abort("'assets' is required")
  }
  object <- list(
    assets = assets,
    title = title,
    rescale = rescale,
    nodata = nodata,
    colormap_name = colormap_name,
    colormap = colormap,
    color_formula = color_formula,
    resampling = resampling,
    expression = expression,
    minmax_zoom = minmax_zoom,
    bidx = if (is.null(bidx)) NULL else unlist(bidx, use.names = FALSE),
    extra_fields = list(...)
  )
  if (!is.character(object[["assets"]])) {
    cli::cli_abort("assets must be character.")
  }
  if (length(object[["assets"]]) == 0L) {
    cli::cli_abort(paste("assets", "must be a non-empty character vector"))
  }
  if (
    !is.null(object[["title"]]) &&
      (!is.character(object[["title"]]) || length(object[["title"]]) != 1L)
  ) {
    cli::cli_abort(paste("title", "must be a single character string"))
  }
  if (
    !is.null(object[["rescale"]]) &&
      (!is.list(object[["rescale"]]) || length(object[["rescale"]]) == 0L)
  ) {
    cli::cli_abort(paste(
      "rescale",
      "must be a non-empty list of numeric vectors"
    ))
  }
  if (
    !is.null(object[["rescale"]]) &&
      !all(vapply(
        object[["rescale"]],
        function(x) {
          return(is.numeric(x) && length(x) == 2L)
        },
        logical(1)
      ))
  ) {
    cli::cli_abort(paste(
      "rescale",
      "must contain only numeric vectors of length 2"
    ))
  }
  if (
    !is.null(object[["minmax_zoom"]]) &&
      (!is.numeric(object[["minmax_zoom"]]) ||
        length(object[["minmax_zoom"]]) != 2L)
  ) {
    cli::cli_abort(paste("minmax_zoom", "must be a numeric vector of length 2"))
  }
  if (!is.list(object[["extra_fields"]])) {
    cli::cli_abort("extra_fields must be list.")
  }
  class(object) <- c("render_object", "stac_object")
  return(object)
}

#'
#' @exportS3Method
as.list.render_object <- function(x, ...) {
  fields <- compact_nulls(list(
    assets = as_json_array(x$assets),
    title = x$title,
    rescale = x$rescale,
    nodata = x$nodata,
    colormap_name = x$colormap_name,
    colormap = x$colormap,
    color_formula = x$color_formula,
    resampling = x$resampling,
    expression = x$expression,
    minmax_zoom = x$minmax_zoom,
    bidx = if (is.null(x$bidx)) NULL else as_json_array(x$bidx)
  ))
  return(c(fields, x$extra_fields))
}


#' Add Render Extension to a STAC Item or Collection
#'
#' @description
#' Adds the STAC Render extension to a STAC Item or Collection. The Render
#' extension provides rendering hints that tell consumers how to visualize
#' the item's assets (e.g. on a web map).
#'
#' @param item A STAC Item (`stac_item`) or Collection (`stac_collection`)
#'   object.
#' @param renders (named list, required) A named list of render objects
#'   created with [render_object()]. Names are used as render keys and must
#'   be unique.
#'
#' @details
#' ## Extension Schema URI
#' The Render Extension v2.0.0 schema URI is:
#' `https://stac-extensions.github.io/render/v2.0.0/schema.json`
#'
#' ## Field Placement
#' * For **Items**, `renders` is placed in `properties`.
#' * For **Collections**, `renders` is placed at the top level of the
#'   Collection object.
#'
#' ## Render Keys
#' Each render object is stored under a unique key inside `renders`.
#' Common keys include `"thumbnail"`, `"true_color"`, `"ndvi"`, etc.
#'
#' @return The modified STAC Item or Collection with Render extension fields
#'   added.
#'
#' @seealso
#' * [render_object()] for creating render objects
#' * [stac_item()] for creating STAC Items
#' * [stac_collection()] for creating STAC Collections
#'
#' @references
#' Render Extension Specification:
#' \url{https://github.com/stac-extensions/render}
#'
#' @examples
#' item <- stac_item(
#'   id = "LC08_L1TP_044033_20210305",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-122.5, 39.5), c(-120.5, 39.5), c(-120.5, 40.5),
#'       c(-122.5, 40.5), c(-122.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-122.5, 39.5, -120.5, 40.5),
#'   datetime = "2021-03-05T18:45:37Z"
#' ) |>
#'   add_asset(
#'     key = "B4",
#'     href = "https://example.com/B4.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_asset(
#'     key = "B3",
#'     href = "https://example.com/B3.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_asset(
#'     key = "B2",
#'     href = "https://example.com/B2.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   )
#'
#' item <- item |>
#'   add_render_extension(renders = list(
#'     true_color = render_object(
#'       assets = c("B4", "B3", "B2"),
#'       title = "True Color",
#'       rescale = list(c(0, 10000), c(0, 10000), c(0, 10000)),
#'       resampling = "bilinear"
#'     )
#'   ))
#'
#' @export
add_render_extension <- function(item, renders) {
  if (!inherits(item, "stac_item") && !inherits(item, "stac_collection")) {
    cli::cli_abort("'item' must be a stac_item or stac_collection object")
  }
  renders <- validate_render_named_list(renders)
  ext_uri <- "https://stac-extensions.github.io/render/v2.0.0/schema.json"
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  merge_renders <- function(existing) {
    existing[names(renders)] <- renders
    return(existing)
  }
  if (inherits(item, "stac_item")) {
    item$properties[["renders"]] <- merge_renders(
      item$properties[["renders"]] %||% list()
    )
  } else {
    item$extra_fields[["renders"]] <- merge_renders(
      item$extra_fields[["renders"]] %||% list()
    )
  }
  return(item)
}


#' @noRd
validate_render_named_list <- function(x) {
  if (!is.list(x) || length(x) == 0) {
    cli::cli_abort("'renders' must be a non-empty named list")
  }
  nms <- names(x)
  if (is.null(nms) || any(nms == "") || any(is.na(nms))) {
    cli::cli_abort("'renders' must be a fully named list")
  }
  if (any(duplicated(nms))) {
    cli::cli_abort("'renders' must not contain duplicate names")
  }
  not_cls <- !vapply(x, inherits, logical(1), "render_object")
  if (any(not_cls)) {
    cli::cli_abort("All elements of 'renders' must be render_object objects")
  }
  return(x)
}


#' Print method for render_object objects
#'
#' @param x A render_object object.
#' @param ... Additional arguments (ignored).
#'
#' @noRd
#'
#' @exportS3Method
print.render_object <- function(x, ...) {
  stac_print_header("Render Object")
  fields <- c(
    compact_nulls(list(
      assets = x$assets,
      title = x$title,
      rescale = x$rescale,
      nodata = x$nodata,
      colormap_name = x$colormap_name,
      colormap = x$colormap,
      color_formula = x$color_formula,
      resampling = x$resampling,
      expression = x$expression,
      minmax_zoom = x$minmax_zoom,
      bidx = x$bidx
    )),
    x$extra_fields
  )
  stac_print_list_fields(fields, styles = list(assets = stac_style_key))
  return(invisible(x))
}
