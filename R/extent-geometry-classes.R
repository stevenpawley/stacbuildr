# RFC 3339 datetime validation helper.
# Returns TRUE if x is a single non-NA character string in the format
# required by the STAC spec (UTC "Z" suffix or explicit ±HH:MM offset).
# Used by TemporalExtent and stac_item validators.
is_rfc3339 <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    return(FALSE)
  }
  return(grepl(
    "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})$",
    x,
    perl = TRUE
  ))
}


# Bbox class with validation
Bbox <- function(coordinates = NULL) {
  object <- list(coordinates = coordinates)
  if (!is.numeric(object[["coordinates"]])) {
    cli::cli_abort("coordinates must be numeric.")
  }
  coords <- object$coordinates
  if (!length(coords) %in% c(4, 6)) {
    cli::cli_abort("Bbox must have 4 or 6 coordinates")
  }
  if (length(coords) == 4) {
    if (coords[2] > coords[4]) {
      cli::cli_abort("South coordinate must be <= north coordinate")
    }
  } else if (length(coords) == 6) {
    if (coords[2] > coords[5]) {
      cli::cli_abort("South coordinate must be <= north coordinate")
    }
    if (coords[3] > coords[6]) {
      cli::cli_abort("Min elevation must be <= max elevation")
    }
  }
  class(object) <- c("Bbox", "stac_object")
  return(object)
}

# SpatialExtent class
SpatialExtent <- function(bbox = list()) {
  object <- list(bbox = bbox)
  if (!is.list(object[["bbox"]])) {
    cli::cli_abort("bbox must be list.")
  }
  if (length(object$bbox) == 0) {
    cli::cli_abort("SpatialExtent must contain at least one bbox")
  }
  for (i in seq_along(object$bbox)) {
    bbox <- object$bbox[[i]]
    if (!is.numeric(bbox)) {
      cli::cli_abort(sprintf("Bbox[%d] must be numeric", i))
    }
    if (!length(bbox) %in% c(4, 6)) {
      cli::cli_abort(sprintf("Bbox[%d] must have 4 or 6 elements", i))
    }
    if (length(bbox) == 4) {
      if (bbox[1] < -180 || bbox[1] > 180) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: west (%g) must be in [-180, 180]",
          i,
          bbox[1]
        ))
      }
      if (bbox[3] < -180 || bbox[3] > 180) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: east (%g) must be in [-180, 180]",
          i,
          bbox[3]
        ))
      }
      if (bbox[2] < -90 || bbox[2] > 90) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: south (%g) must be in [-90, 90]",
          i,
          bbox[2]
        ))
      }
      if (bbox[4] < -90 || bbox[4] > 90) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: north (%g) must be in [-90, 90]",
          i,
          bbox[4]
        ))
      }
      if (bbox[2] > bbox[4]) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: south (%g) must be <= north (%g)",
          i,
          bbox[2],
          bbox[4]
        ))
      }
    } else {
      if (bbox[1] < -180 || bbox[1] > 180) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: west (%g) must be in [-180, 180]",
          i,
          bbox[1]
        ))
      }
      if (bbox[4] < -180 || bbox[4] > 180) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: east (%g) must be in [-180, 180]",
          i,
          bbox[4]
        ))
      }
      if (bbox[2] < -90 || bbox[2] > 90) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: south (%g) must be in [-90, 90]",
          i,
          bbox[2]
        ))
      }
      if (bbox[5] < -90 || bbox[5] > 90) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: north (%g) must be in [-90, 90]",
          i,
          bbox[5]
        ))
      }
      if (bbox[2] > bbox[5]) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: south (%g) must be <= north (%g)",
          i,
          bbox[2],
          bbox[5]
        ))
      }
      if (bbox[3] > bbox[6]) {
        cli::cli_abort(sprintf(
          "Bbox[%d]: min elevation (%g) must be <= max elevation (%g)",
          i,
          bbox[3],
          bbox[6]
        ))
      }
    }
  }
  class(object) <- c("SpatialExtent", "stac_object")
  return(object)
}

# TemporalExtent class
TemporalExtent <- function(interval = NULL) {
  object <- list(interval = interval)
  if (!is.list(object[["interval"]])) {
    cli::cli_abort("interval must be list.")
  }
  if (length(object$interval) == 0) {
    cli::cli_abort("TemporalExtent must contain at least one interval")
  }
  for (i in seq_along(object$interval)) {
    interval <- object$interval[[i]]
    if (length(interval) != 2) {
      cli::cli_abort(sprintf(
        "Interval[%d] must have exactly 2 elements (start, end)",
        i
      ))
    }
    start_val <- interval[[1]]
    end_val <- interval[[2]]
    if (!is.null(start_val) && !is_rfc3339(start_val)) {
      cli::cli_abort(sprintf(
        "Interval[%d] start is not a valid RFC 3339 datetime: '%s'",
        i,
        start_val
      ))
    }
    if (!is.null(end_val) && !is_rfc3339(end_val)) {
      cli::cli_abort(sprintf(
        "Interval[%d] end is not a valid RFC 3339 datetime: '%s'",
        i,
        end_val
      ))
    }
    if (!is.null(start_val) && !is.null(end_val) && end_val < start_val) {
      cli::cli_abort(sprintf(
        "Interval[%d]: end ('%s') must be >= start ('%s')",
        i,
        end_val,
        start_val
      ))
    }
  }
  class(object) <- c("TemporalExtent", "stac_object")
  return(object)
}

# Extent class combining spatial and temporal
Extent <- function(spatial = NULL, temporal = NULL) {
  object <- list(spatial = spatial, temporal = temporal)
  if (!inherits(object[["spatial"]], "SpatialExtent")) {
    cli::cli_abort("spatial must be SpatialExtent.")
  }
  if (!inherits(object[["temporal"]], "TemporalExtent")) {
    cli::cli_abort("temporal must be TemporalExtent.")
  }
  class(object) <- c("Extent", "stac_object")
  return(object)
}

#' Create a GeoJSON Geometry
#'
#' @description
#' Creates an S3 representation of a GeoJSON geometry. Plain GeoJSON lists are
#' accepted by [stac_item()] and converted automatically, so this constructor is
#' mainly useful when building or inspecting geometries directly.
#'
#' @param type A GeoJSON geometry type.
#' @param coordinates Coordinates for every geometry type except
#'   `"GeometryCollection"`.
#' @param geometries A list of geometries for `"GeometryCollection"`. Plain
#'   GeoJSON geometry lists are converted recursively.
#'
#' @return A `stac_geometry` S3 object. Access its fields with `$`, for example
#'   `geometry$type` and `geometry$coordinates`.
#'
#' @examples
#' geometry <- stac_geometry("Point", coordinates = c(-105, 40))
#' geometry$type
#' geometry$coordinates
#'
#' @export
stac_geometry <- function(type, coordinates = NULL, geometries = list()) {
  if (identical(type, "GeometryCollection")) {
    geometries <- lapply(geometries, as_stac_geometry)
  }
  object <- list(
    type = type,
    coordinates = coordinates,
    geometries = geometries
  )
  if (!is.character(object[["type"]])) {
    cli::cli_abort("type must be character.")
  }
  if (!is.list(object[["geometries"]])) {
    cli::cli_abort("geometries must be list.")
  }
  valid_types <- c(
    "Point",
    "LineString",
    "Polygon",
    "MultiPoint",
    "MultiLineString",
    "MultiPolygon",
    "GeometryCollection"
  )
  if (!object$type %in% valid_types) {
    cli::cli_abort(sprintf(
      "Geometry type '%s' is not valid. Must be one of: %s",
      object$type,
      paste(valid_types, collapse = ", ")
    ))
  }
  if (object$type == "GeometryCollection") {
    if (!is.null(object$coordinates)) {
      cli::cli_abort("GeometryCollection must not have coordinates")
    }
    if (
      !all(vapply(
        object$geometries,
        inherits,
        logical(1),
        what = "stac_geometry"
      ))
    ) {
      cli::cli_abort(
        "GeometryCollection must contain only stac_geometry objects"
      )
    }
  } else if (is.null(object$coordinates)) {
    cli::cli_abort(
      "Geometry must have coordinates unless type is GeometryCollection"
    )
  }
  class(object) <- c("stac_geometry", "stac_object")
  return(object)
}

# Normalize plain GeoJSON lists at public object boundaries.
as_stac_geometry <- function(x) {
  if (is.null(x) || inherits(x, "stac_geometry")) {
    return(x)
  }
  if (!is.list(x)) {
    cli::cli_abort(c(
      "'geometry' must be a stac_geometry or a GeoJSON geometry list.",
      i = "Use stac_geometry() to build one."
    ))
  }
  if (is.null(x[["type"]])) {
    cli::cli_abort("'geometry' must have a 'type' field.")
  }
  return(stac_geometry(
    type = x[["type"]],
    coordinates = x[["coordinates"]],
    geometries = x[["geometries"]] %||%
      list()
  ))
}

# Print methods -----------------------------------------------------------

# Format one bbox as "[w, s, e, n]", or with the elevation pair for a 3D bbox.
stac_format_bbox <- function(bbox) {
  if (length(bbox) == 6L) {
    return(sprintf(
      "[%g, %g, %g, %g] elev [%g, %g]",
      bbox[1],
      bbox[2],
      bbox[4],
      bbox[5],
      bbox[3],
      bbox[6]
    ))
  }
  return(sprintf(
    "[%s]",
    paste(
      vapply(
        bbox,
        function(v) {
          return(sprintf("%g", v))
        },
        character(1)
      ),
      collapse = ", "
    )
  ))
}

# Format one interval as "start / end", with ".." for an open end.
stac_format_interval <- function(interval) {
  ends <- vapply(
    interval,
    function(v) {
      return(
        if (is.null(v) || length(v) == 0L || is.na(v)) ".." else as.character(v)
      )
    },
    character(1)
  )
  return(paste(ends, collapse = " / "))
}

#'
#' @exportS3Method
print.Bbox <- function(x, ...) {
  stac_print_header("Bbox")
  stac_print_list_fields(list(
    dimensions = if (length(x$coordinates) == 6L) "3D" else "2D",
    coordinates = stac_format_bbox(x$coordinates)
  ))
  return(invisible(x))
}

#'
#' @exportS3Method
print.SpatialExtent <- function(x, ..., expand = NULL) {
  stac_print_header("Spatial Extent")
  collapsed <- stac_print_section(
    "bbox",
    length(x$bbox),
    summary = if (length(x$bbox) > 0) stac_format_bbox(x$bbox[[1]]),
    lines = function() {
      return(vapply(x$bbox, stac_format_bbox, character(1)))
    },
    expanded = stac_expanded(expand, "bbox")
  )
  stac_print_hint(sum(collapsed))
  return(invisible(x))
}

#'
#' @exportS3Method
print.TemporalExtent <- function(x, ..., expand = NULL) {
  stac_print_header("Temporal Extent")
  collapsed <- stac_print_section(
    "interval",
    length(x$interval),
    summary = if (length(x$interval) > 0) stac_format_interval(x$interval[[1]]),
    lines = function() {
      return(vapply(x$interval, stac_format_interval, character(1)))
    },
    expanded = stac_expanded(expand, "interval")
  )
  stac_print_hint(sum(collapsed))
  return(invisible(x))
}

#'
#' @exportS3Method
print.Extent <- function(x, ...) {
  stac_print_header("STAC Extent")

  bboxes <- x$spatial$bbox
  intervals <- x$temporal$interval

  # The first bbox and interval are the overall extent; any others are the
  # more precise sub-regions and sub-periods the spec allows.
  stac_print_list_fields(list(
    bbox = if (length(bboxes) > 0) stac_format_bbox(bboxes[[1]]),
    datetime = if (length(intervals) > 0) stac_format_interval(intervals[[1]])
  ))

  if (length(bboxes) > 1L) {
    stac_print_field(
      "sub-regions",
      stac_fmt_value(length(bboxes) - 1L),
      stac_style_count
    )
  }
  if (length(intervals) > 1L) {
    stac_print_field(
      "sub-periods",
      stac_fmt_value(length(intervals) - 1L),
      stac_style_count
    )
  }

  return(invisible(x))
}

#'
#' @exportS3Method
print.stac_geometry <- function(x, ...) {
  stac_print_header("Geometry")
  value <- if (x$type == "GeometryCollection") {
    sprintf("%d geometries", length(x$geometries))
  } else {
    stac_geometry_summary(x$coordinates)
  }
  stac_print_list_fields(
    list(
      type = x$type,
      coordinates = value
    ),
    styles = list(type = stac_style_key)
  )
  return(invisible(x))
}

# GeoJSON coordinates nest differently per geometry type, so report the
# position count rather than trying to render them.
stac_geometry_summary <- function(coords) {
  if (is.null(coords)) {
    return(NULL)
  }
  if (is.numeric(coords) && !is.list(coords)) {
    return(sprintf("[%s]", paste(sprintf("%g", coords), collapse = ", ")))
  }
  n <- length(unlist(coords)) %/% 2L
  return(sprintf("%d position%s", n, if (n == 1L) "" else "s"))
}


# Methods to support serialization to JSON
#'
#' @exportS3Method
as.list.SpatialExtent <- function(x, ...) {
  return(list(bbox = x$bbox))
}

#'
#' @exportS3Method
as.list.TemporalExtent <- function(x, ...) {
  # Strip names so each interval serialises as a JSON array, not an object.
  # list(start = "...", end = "...") would otherwise become {"start":...}.
  return(list(interval = lapply(x$interval, unname)))
}

#'
#' @exportS3Method
as.list.Extent <- function(x, ...) {
  return(list(
    spatial = as.list(x$spatial),
    temporal = as.list(x$temporal)
  ))
}

#'
#' @exportS3Method
as.list.stac_geometry <- function(x, ...) {
  if (x$type == "GeometryCollection") {
    return(list(
      type = x$type,
      geometries = lapply(x$geometries, as.list)
    ))
  }
  return(list(type = x$type, coordinates = x$coordinates))
}
