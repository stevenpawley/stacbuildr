#' Add the Projection Extension to a STAC Item
#'
#' @description
#' Adds the Projection Extension to a STAC Item, recording the coordinate
#' reference system and grid geometry of the source data.
#'
#' STAC requires an Item's `geometry` and `bbox` to be WGS84 longitude/latitude,
#' whatever projection the data is actually stored in. The Projection Extension
#' carries the native CRS alongside it, so a client can locate a pixel or read a
#' window without opening the file:
#'
#' * **`proj:code`**: The CRS as an `AUTHORITY:CODE` string, e.g. `"EPSG:32612"`.
#' * **`proj:wkt2`**: The CRS as a WKT2 string, for CRSs with no authority code.
#' * **`proj:projjson`**: The CRS as a PROJJSON object.
#' * **`proj:geometry`** / **`proj:bbox`**: Footprint in the native CRS.
#' * **`proj:shape`**: Raster dimensions as `c(rows, columns)`.
#' * **`proj:transform`**: The affine transform from pixel to CRS coordinates.
#' * **`proj:centroid`**: Centroid as WGS84 latitude and longitude.
#'
#' [item_from_terra()] and [item_from_lidr()] call this function for you.
#' Use it directly when building an Item by hand, or when attaching projection
#' metadata to an Item created with [item_from_sf()].
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param code (character, optional) The CRS as an `AUTHORITY:CODE` string, e.g.
#'   `"EPSG:32612"` or `"OGC:CRS84"`. This field replaced the deprecated
#'   `proj:epsg` in v2.0.0 of the extension, so a bare EPSG number must be
#'   prefixed with its authority.
#' @param wkt2 (character, optional) The CRS as a WKT2 string. Use this for a
#'   CRS with no authority code, or alongside `code` for clients that prefer a
#'   full definition.
#' @param projjson (list, optional) The CRS as a PROJJSON object, supplied as a
#'   named list.
#' @param geometry (list, optional) A GeoJSON geometry giving the footprint in
#'   the native CRS, as a named list with `type` and `coordinates`. Unlike the
#'   Item's own `geometry`, this is *not* reprojected to WGS84.
#' @param bbox (numeric, optional) Bounding box in the native CRS: four values
#'   (`xmin, ymin, xmax, ymax`) for 2D data, or six
#'   (`xmin, ymin, zmin, xmax, ymax, zmax`) for 3D data such as a point cloud.
#' @param centroid (optional) The centroid in WGS84, as a named numeric vector
#'   or list with `lat` and `lon` elements.
#' @param shape (numeric, optional) Raster dimensions as `c(rows, columns)` —
#'   height first, then width.
#' @param transform (numeric, optional) The affine transform mapping pixel
#'   coordinates to CRS coordinates. Six values in the order
#'   `c(xscale, rowrot, xmin, colrot, yscale, ymax)`, optionally followed by the
#'   bottom row `c(0, 0, 1)` for nine in total. `yscale` is normally negative
#'   for a north-up raster.
#' @param asset_key (character, optional) Key of an asset in the Item. When
#'   supplied, the fields are written to that asset rather than to the Item's
#'   properties. Use this when assets in one Item are in different projections
#'   or at different resolutions.
#'
#' @details
#' ## Extension Schema URI
#' `https://stac-extensions.github.io/projection/v2.0.0/schema.json`
#'
#' ## Item or asset placement
#' Every field may sit on the Item's properties or on an individual asset. Put
#' them on the Item when all its assets share a projection, and on assets when
#' they do not — a common case being a Sentinel-2 scene whose 10 m, 20 m and
#' 60 m bands share a CRS but differ in `proj:shape` and `proj:transform`.
#'
#' @return The modified STAC Item with projection metadata attached.
#'
#' @seealso [item_from_terra()] and [item_from_lidr()], which add these fields
#'   automatically from a raster or point cloud.
#'
#' @examples
#' item <- stac_item(
#'   id = "utm-scene",
#'   geometry = list(type = "Point", coordinates = c(-113.5, 51.0)),
#'   bbox = c(-113.5, 51.0, -113.5, 51.0),
#'   datetime = "2024-06-01T00:00:00Z"
#' )
#'
#' # A projected raster: CRS, grid shape and affine transform
#' item <- add_projection_extension(
#'   item,
#'   code = "EPSG:32612",
#'   shape = c(5558, 9559),
#'   transform = c(30, 0, 712710, 0, -30, 5654790),
#'   bbox = c(712710, 5487090, 999480, 5654790)
#' )
#'
#' item@properties$`proj:code`
#'
#' # Per-asset placement, for assets at different resolutions
#' item <- add_asset(
#'   item,
#'   key = "swir",
#'   href = "https://example.com/swir.tif",
#'   type = "image/tiff; application=geotiff"
#' )
#' item <- add_projection_extension(
#'   item,
#'   shape = c(2779, 4780),
#'   transform = c(60, 0, 712710, 0, -60, 5654790),
#'   asset_key = "swir"
#' )
#'
#' @export
add_projection_extension <- function(
  item,
  code = NULL,
  wkt2 = NULL,
  projjson = NULL,
  geometry = NULL,
  bbox = NULL,
  centroid = NULL,
  shape = NULL,
  transform = NULL,
  asset_key = NULL
) {
  if (!inherits(item, "stac_item")) {
    cli::cli_abort("'item' must be a stac_item object")
  }

  supplied <- list(
    code = code,
    wkt2 = wkt2,
    projjson = projjson,
    geometry = geometry,
    bbox = bbox,
    centroid = centroid,
    shape = shape,
    transform = transform
  )
  supplied <- Filter(Negate(is.null), supplied)

  if (length(supplied) == 0) {
    cli::cli_abort(c(
      "At least one projection field must be provided.",
      "i" = "Supply one or more of {.arg code}, {.arg wkt2}, {.arg projjson},
             {.arg geometry}, {.arg bbox}, {.arg centroid}, {.arg shape} or
             {.arg transform}."
    ))
  }

  if (!is.null(code)) {
    if (!is.character(code) || length(code) != 1 || !nzchar(code)) {
      cli::cli_abort("'code' must be a single non-empty character string")
    }
    # v2.0.0 replaced the bare-integer `proj:epsg` with an authority-qualified
    # `proj:code`, so a lone number is the mistake to expect here.
    if (!grepl("^[A-Za-z][A-Za-z0-9_-]*:[A-Za-z0-9_-]+$", code)) {
      cli::cli_abort(c(
        "'code' must be an {.val AUTHORITY:CODE} string, not {.val {code}}.",
        "i" = "{.field proj:code} replaced the deprecated {.field proj:epsg} in
               v2.0.0 of the extension, so the authority is required.",
        ">" = "Use {.val EPSG:{code}} for an EPSG code, or {.val OGC:CRS84} for
               WGS84 longitude/latitude."
      ))
    }
  }

  if (!is.null(wkt2)) {
    if (!is.character(wkt2) || length(wkt2) != 1 || !nzchar(wkt2)) {
      cli::cli_abort("'wkt2' must be a single non-empty character string")
    }
  }

  if (!is.null(projjson)) {
    if (!is.list(projjson) || length(projjson) == 0) {
      cli::cli_abort("'projjson' must be a non-empty list")
    }
  }

  if (!is.null(geometry)) {
    if (!is.list(geometry) || is.null(geometry$type)) {
      cli::cli_abort(c(
        "'geometry' must be a GeoJSON geometry list with a 'type' field.",
        "i" = "For example: {.code list(type = \"Polygon\", coordinates = ...)}."
      ))
    }
  }

  if (!is.null(bbox)) {
    if (!is.numeric(bbox) || !length(bbox) %in% c(4L, 6L)) {
      cli::cli_abort(c(
        "'bbox' must be a numeric vector of length 4 or 6.",
        "i" = "Use 4 values for 2D data (xmin, ymin, xmax, ymax) and 6 for 3D
               (xmin, ymin, zmin, xmax, ymax, zmax)."
      ))
    }
    if (anyNA(bbox)) {
      cli::cli_abort("'bbox' must not contain missing values")
    }
  }

  if (!is.null(centroid)) {
    centroid <- as.list(centroid)
    if (!all(c("lat", "lon") %in% names(centroid))) {
      cli::cli_abort(c(
        "'centroid' must have 'lat' and 'lon' elements.",
        "i" = "For example: {.code c(lat = 51.05, lon = -114.07)}."
      ))
    }
    centroid <- list(
      lat = as.numeric(centroid$lat),
      lon = as.numeric(centroid$lon)
    )
    if (anyNA(unlist(centroid))) {
      cli::cli_abort("'centroid' values must be numeric")
    }
    if (abs(centroid$lat) > 90 || abs(centroid$lon) > 180) {
      cli::cli_abort(c(
        "'centroid' must be in WGS84 degrees.",
        "i" = "'lat' must be within [-90, 90] and 'lon' within [-180, 180]."
      ))
    }
  }

  if (!is.null(shape)) {
    if (!is.numeric(shape) || length(shape) != 2 || anyNA(shape)) {
      cli::cli_abort("'shape' must be a numeric vector of length 2")
    }
    if (any(shape <= 0) || any(shape != round(shape))) {
      cli::cli_abort(c(
        "'shape' must be two positive whole numbers.",
        "i" = "The order is {.code c(rows, columns)}: height first."
      ))
    }
  }

  if (!is.null(transform)) {
    if (!is.numeric(transform) || !length(transform) %in% c(6L, 9L)) {
      cli::cli_abort(c(
        "'transform' must be a numeric vector of length 6 or 9.",
        "i" = "The first six values are
               {.code c(xscale, rowrot, xmin, colrot, yscale, ymax)}; the
               remaining three are the constant bottom row
               {.code c(0, 0, 1)}."
      ))
    }
    if (anyNA(transform)) {
      cli::cli_abort("'transform' must not contain missing values")
    }
  }

  if (!is.null(asset_key)) {
    if (!is.character(asset_key) || length(asset_key) != 1) {
      cli::cli_abort("'asset_key' must be a single character string")
    }
    if (is.null(item@assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }
  }

  ext_uri <- "https://stac-extensions.github.io/projection/v2.0.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  # The numeric fields are JSON arrays, and terra hands back named vectors
  # (an extent carries xmin/ymin/xmax/ymax names), so names are dropped here
  # rather than left to the writer to ignore.
  fields <- list()
  if (!is.null(code)) fields$`proj:code` <- code
  if (!is.null(wkt2)) fields$`proj:wkt2` <- wkt2
  if (!is.null(projjson)) fields$`proj:projjson` <- projjson
  if (!is.null(geometry)) fields$`proj:geometry` <- geometry
  if (!is.null(bbox)) fields$`proj:bbox` <- unname(bbox)
  if (!is.null(centroid)) fields$`proj:centroid` <- centroid
  if (!is.null(shape)) fields$`proj:shape` <- unname(shape)
  if (!is.null(transform)) fields$`proj:transform` <- unname(transform)

  if (is.null(asset_key)) {
    for (field_name in names(fields)) {
      item@properties[[field_name]] <- fields[[field_name]]
    }
  } else {
    for (field_name in names(fields)) {
      item@assets[[asset_key]][[field_name]] <- fields[[field_name]]
    }
  }

  item
}
