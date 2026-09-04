# RFC 3339 datetime validation helper.
# Returns TRUE if x is a single non-NA character string in the format
# required by the STAC spec (UTC "Z" suffix or explicit ±HH:MM offset).
# Used by TemporalExtent and stac_item validators.
is_rfc3339 <- function(x) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) return(FALSE)
  grepl(
    "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})$",
    x,
    perl = TRUE
  )
}


# Bbox class with validation
Bbox <- S7::new_class(
  "Bbox",
  properties = list(
    coordinates = S7::class_numeric
  ),
  validator = function(self) {
    coords <- self@coordinates

    if (!length(coords) %in% c(4, 6)) {
      return("Bbox must have 4 or 6 coordinates")
    }

    # Longitudes are deliberately not ordered. A bbox that crosses the
    # antimeridian has a west value greater than its east value: RFC 7946
    # section 5.2 gives [177.0, -20.0, -178.0, -16.0] for the Fiji archipelago
    # as the canonical example. Latitudes and elevations have no such wrap and
    # must stay ordered.
    if (length(coords) == 4) {
      if (coords[2] > coords[4]) {
        return("South coordinate must be <= north coordinate")
      }
    } else if (length(coords) == 6) {
      if (coords[2] > coords[5]) {
        return("South coordinate must be <= north coordinate")
      }
      if (coords[3] > coords[6]) {
        return("Min elevation must be <= max elevation")
      }
    }
  }
)

# SpatialExtent class
SpatialExtent <- S7::new_class(
  "SpatialExtent",
  properties = list(
    bbox = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@bbox) == 0) {
      return("SpatialExtent must contain at least one bbox")
    }

    # Validate each bbox. Longitudes are range-checked but not ordered: a bbox
    # crossing the antimeridian has west > east (RFC 7946 section 5.2).
    for (i in seq_along(self@bbox)) {
      bbox <- self@bbox[[i]]
      if (!is.numeric(bbox)) {
        return(sprintf("Bbox[%d] must be numeric", i))
      }
      if (!length(bbox) %in% c(4, 6)) {
        return(sprintf("Bbox[%d] must have 4 or 6 elements", i))
      }
      if (length(bbox) == 4) {
        if (bbox[1] < -180 || bbox[1] > 180) {
          return(sprintf("Bbox[%d]: west (%g) must be in [-180, 180]", i, bbox[1]))
        }
        if (bbox[3] < -180 || bbox[3] > 180) {
          return(sprintf("Bbox[%d]: east (%g) must be in [-180, 180]", i, bbox[3]))
        }
        if (bbox[2] < -90 || bbox[2] > 90) {
          return(sprintf("Bbox[%d]: south (%g) must be in [-90, 90]", i, bbox[2]))
        }
        if (bbox[4] < -90 || bbox[4] > 90) {
          return(sprintf("Bbox[%d]: north (%g) must be in [-90, 90]", i, bbox[4]))
        }
        if (bbox[2] > bbox[4]) {
          return(sprintf("Bbox[%d]: south (%g) must be <= north (%g)", i, bbox[2], bbox[4]))
        }
      } else {
        if (bbox[1] < -180 || bbox[1] > 180) {
          return(sprintf("Bbox[%d]: west (%g) must be in [-180, 180]", i, bbox[1]))
        }
        if (bbox[4] < -180 || bbox[4] > 180) {
          return(sprintf("Bbox[%d]: east (%g) must be in [-180, 180]", i, bbox[4]))
        }
        if (bbox[2] < -90 || bbox[2] > 90) {
          return(sprintf("Bbox[%d]: south (%g) must be in [-90, 90]", i, bbox[2]))
        }
        if (bbox[5] < -90 || bbox[5] > 90) {
          return(sprintf("Bbox[%d]: north (%g) must be in [-90, 90]", i, bbox[5]))
        }
        if (bbox[2] > bbox[5]) {
          return(sprintf("Bbox[%d]: south (%g) must be <= north (%g)", i, bbox[2], bbox[5]))
        }
        if (bbox[3] > bbox[6]) {
          return(sprintf("Bbox[%d]: min elevation (%g) must be <= max elevation (%g)", i, bbox[3], bbox[6]))
        }
      }
    }
  }
)

# TemporalExtent class
TemporalExtent <- S7::new_class(
  "TemporalExtent",
  properties = list(
    interval = S7::class_list
  ),
  validator = function(self) {
    if (length(self@interval) == 0) {
      return("TemporalExtent must contain at least one interval")
    }

    for (i in seq_along(self@interval)) {
      interval <- self@interval[[i]]
      if (length(interval) != 2) {
        return(sprintf(
          "Interval[%d] must have exactly 2 elements (start, end)",
          i
        ))
      }

      start_val <- interval[[1]]
      end_val   <- interval[[2]]

      # Each non-NULL endpoint must be a valid RFC 3339 datetime string
      if (!is.null(start_val) && !is_rfc3339(start_val)) {
        return(sprintf(
          "Interval[%d] start is not a valid RFC 3339 datetime: '%s'",
          i, start_val
        ))
      }
      if (!is.null(end_val) && !is_rfc3339(end_val)) {
        return(sprintf(
          "Interval[%d] end is not a valid RFC 3339 datetime: '%s'",
          i, end_val
        ))
      }

      # For closed intervals (both endpoints present), end must be >= start.
      # ISO 8601 / RFC 3339 strings sort lexicographically when in UTC.
      if (!is.null(start_val) && !is.null(end_val) && end_val < start_val) {
        return(sprintf(
          "Interval[%d]: end ('%s') must be >= start ('%s')",
          i, end_val, start_val
        ))
      }
    }
  }
)

# Extent class combining spatial and temporal
Extent <- S7::new_class(
  "Extent",
  properties = list(
    spatial = SpatialExtent,
    temporal = TemporalExtent
  )
)

# Geometry class
Geometry <- S7::new_class(
  "Geometry",
  properties = list(
    type = S7::class_character,
    coordinates = S7::class_any # varies by geometry type
  ),
  validator = function(self) {
    valid_types <- c(
      "Point",
      "LineString",
      "Polygon",
      "MultiPoint",
      "MultiLineString",
      "MultiPolygon",
      "GeometryCollection"
    )

    if (!self@type %in% valid_types) {
      return(sprintf(
        "Geometry type '%s' is not valid. Must be one of: %s",
        self@type,
        paste(valid_types, collapse = ", ")
      ))
    }

    if (is.null(self@coordinates) && self@type != "GeometryCollection") {
      return("Geometry must have coordinates unless type is GeometryCollection")
    }
  }
)

# Print methods -----------------------------------------------------------

# Format one bbox as "[w, s, e, n]", or with the elevation pair for a 3D bbox.
stac_format_bbox <- function(bbox) {
  if (length(bbox) == 6L) {
    return(sprintf(
      "[%g, %g, %g, %g] elev [%g, %g]",
      bbox[1], bbox[2], bbox[4], bbox[5], bbox[3], bbox[6]
    ))
  }
  sprintf("[%s]", paste(vapply(bbox, function(v) sprintf("%g", v), character(1)),
                        collapse = ", "))
}

# Format one interval as "start / end", with ".." for an open end.
stac_format_interval <- function(interval) {
  ends <- vapply(interval, function(v) {
    if (is.null(v) || length(v) == 0L || is.na(v)) ".." else as.character(v)
  }, character(1))
  paste(ends, collapse = " / ")
}

S7::method(print, Bbox) <- function(x, ...) {
  stac_print_header("Bbox")
  stac_print_list_fields(list(
    dimensions = if (length(x@coordinates) == 6L) "3D" else "2D",
    coordinates = stac_format_bbox(x@coordinates)
  ))
  invisible(x)
}

S7::method(print, SpatialExtent) <- function(x, ..., expand = NULL) {
  stac_print_header("Spatial Extent")
  collapsed <- stac_print_section(
    "bbox",
    length(x@bbox),
    summary = if (length(x@bbox) > 0) stac_format_bbox(x@bbox[[1]]),
    lines = function() vapply(x@bbox, stac_format_bbox, character(1)),
    expanded = stac_expanded(expand, "bbox")
  )
  stac_print_hint(sum(collapsed))
  invisible(x)
}

S7::method(print, TemporalExtent) <- function(x, ..., expand = NULL) {
  stac_print_header("Temporal Extent")
  collapsed <- stac_print_section(
    "interval",
    length(x@interval),
    summary = if (length(x@interval) > 0) stac_format_interval(x@interval[[1]]),
    lines = function() vapply(x@interval, stac_format_interval, character(1)),
    expanded = stac_expanded(expand, "interval")
  )
  stac_print_hint(sum(collapsed))
  invisible(x)
}

S7::method(print, Extent) <- function(x, ...) {
  stac_print_header("STAC Extent")

  bboxes <- x@spatial@bbox
  intervals <- x@temporal@interval

  # The first bbox and interval are the overall extent; any others are the
  # more precise sub-regions and sub-periods the spec allows.
  stac_print_list_fields(list(
    bbox = if (length(bboxes) > 0) stac_format_bbox(bboxes[[1]]),
    datetime = if (length(intervals) > 0) stac_format_interval(intervals[[1]])
  ))

  if (length(bboxes) > 1L) {
    stac_print_field(
      "sub-regions", stac_fmt_value(length(bboxes) - 1L), stac_style_count
    )
  }
  if (length(intervals) > 1L) {
    stac_print_field(
      "sub-periods", stac_fmt_value(length(intervals) - 1L), stac_style_count
    )
  }

  invisible(x)
}

S7::method(print, Geometry) <- function(x, ...) {
  stac_print_header("Geometry")
  stac_print_list_fields(
    list(
      type = x@type,
      coordinates = stac_geometry_summary(x@coordinates)
    ),
    styles = list(type = stac_style_key)
  )
  invisible(x)
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
  sprintf("%d position%s", n, if (n == 1L) "" else "s")
}


# Methods to support serialization to JSON
S7::method(as.list, SpatialExtent) <- function(x, ...) {
  list(bbox = x@bbox)
}

S7::method(as.list, TemporalExtent) <- function(x, ...) {
  # Strip names so each interval serialises as a JSON array, not an object.
  # list(start = "...", end = "...") would otherwise become {"start":...}.
  list(interval = lapply(x@interval, unname))
}

S7::method(as.list, Extent) <- function(x, ...) {
  list(
    spatial = as.list(x@spatial),
    temporal = as.list(x@temporal)
  )
}
