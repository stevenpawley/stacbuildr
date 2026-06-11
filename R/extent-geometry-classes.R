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

    if (length(coords) == 4) {
      if (coords[1] > coords[3]) {
        return("West coordinate must be <= east coordinate")
      }
      if (coords[2] > coords[4]) {
        return("South coordinate must be <= north coordinate")
      }
    } else if (length(coords) == 6) {
      if (coords[1] > coords[4]) {
        return("West coordinate must be <= east coordinate")
      }
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

    # Validate each bbox
    for (i in seq_along(self@bbox)) {
      bbox <- self@bbox[[i]]
      if (!is.numeric(bbox)) {
        return(sprintf("Bbox[%d] must be numeric", i))
      }
      if (!length(bbox) %in% c(4, 6)) {
        return(sprintf("Bbox[%d] must have 4 or 6 elements", i))
      }
      if (length(bbox) == 4) {
        if (bbox[1] > bbox[3]) {
          return(sprintf("Bbox[%d]: west (%g) must be <= east (%g)", i, bbox[1], bbox[3]))
        }
        if (bbox[2] > bbox[4]) {
          return(sprintf("Bbox[%d]: south (%g) must be <= north (%g)", i, bbox[2], bbox[4]))
        }
      } else {
        if (bbox[1] > bbox[4]) {
          return(sprintf("Bbox[%d]: west (%g) must be <= east (%g)", i, bbox[1], bbox[4]))
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
