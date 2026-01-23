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
    bbox = S7::new_property(class_list, default = list())
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
    }
  }
)

# TemporalExtent class
TemporalExtent <- S7::new_class(
  "TemporalExtent",
  properties = list(
    interval = class_list
  ),
  validator = function(self) {
    if (length(self@interval) == 0) {
      return("TemporalExtent must contain at least one interval")
    }
    
    for (i in seq_along(self@interval)) {
      interval <- self@interval[[i]]
      if (length(interval) != 2) {
        return(sprintf("Interval[%d] must have exactly 2 elements (start, end)", i))
      }
      # Could add more validation for datetime formats
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
    type = class_character,
    coordinates = S7::class_any  # varies by geometry type
  ),
  validator = function(self) {
    valid_types <- c("Point", "LineString", "Polygon", "MultiPoint",
                     "MultiLineString", "MultiPolygon", "GeometryCollection")
    
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

# Methods to support serialization ot JSON
method(as.list, SpatialExtent) <- function(x, ...) {
  list(bbox = x@bbox)
}

method(as.list, TemporalExtent) <- function(x, ...) {
  list(interval = x@interval)
}

method(as.list, Extent) <- function(x, ...) {
  list(
    spatial = as.list(x@spatial),
    temporal = as.list(x@temporal)
  )
}
