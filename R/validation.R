#' Validate a STAC Object
#'
#' @description
#' Validates a STAC Catalog, Collection, or Item against the STAC specification.
#' Checks for required fields, proper structure, and valid values.
#'
#' @param stac_object A STAC object (catalog, collection, or item).
#' @param strict (logical, optional) If TRUE, enforces stricter validation including
#'   recommended fields. Default is FALSE.
#'
#' @return A list with elements:
#'   * `valid`: Logical indicating if the object is valid
#'   * `errors`: Character vector of error messages (empty if valid)
#'   * `warnings`: Character vector of warning messages for missing recommended fields
#'
#' @export
validate_stac <- function(stac_object, strict = FALSE) {
  errors <- character()
  warnings <- character()

  # Validate item/collection/catalog
  result <- switch(
    class(stac_object)[1],
    stac_item = validate_item(stac_object, strict),
    stac_collection = validate_collection(stac_object, strict),
    stac_catalog = validate_catalog(stac_object, strict),
    {
      errors <- "Object must be a stac_catalog, stac_collection, or stac_item"
      return(list(valid = FALSE, errors = errors, warnings = character()))
    }
  )

  result
}


#' Validate STAC Catalog
#'
#' @keywords internal
validate_catalog <- function(catalog, strict = FALSE) {
  errors <- character()
  warnings <- character()

  # Check required fields
  if (is.null(catalog$type) || catalog$type != "Catalog") {
    errors <- c(errors, "Field 'type' must be 'Catalog'")
  }

  if (is.null(catalog$stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(catalog$id) || nchar(catalog$id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  if (is.null(catalog$description) || nchar(catalog$description) == 0) {
    errors <- c(errors, "Field 'description' is required and must be non-empty")
  }

  if (is.null(catalog$links)) {
    errors <- c(errors, "Field 'links' is required (can be empty list)")
  } else if (!is.list(catalog$links)) {
    errors <- c(errors, "Field 'links' must be a list")
  }

  # Validate links
  if (!is.null(catalog$links) && length(catalog$links) > 0) {
    link_errors <- validate_links(catalog$links)
    errors <- c(errors, link_errors)
  }

  # Check recommended fields
  if (strict && is.null(catalog$title)) {
    warnings <- c(warnings, "Field 'title' is recommended")
  }

  # Validate stac_extensions if present
  if (!is.null(catalog$stac_extensions)) {
    if (!is.character(catalog$stac_extensions)) {
      errors <- c(errors, "Field 'stac_extensions' must be an array of strings")
    }
  }

  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}


#' Validate STAC Collection
#'
#' @keywords internal
validate_collection <- function(collection, strict = FALSE) {
  errors <- character()
  warnings <- character()

  # Check required fields
  if (is.null(collection$type) || collection$type != "Collection") {
    errors <- c(errors, "Field 'type' must be 'Collection'")
  }

  if (is.null(collection$stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(collection$id) || nchar(collection$id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  if (is.null(collection$description) || nchar(collection$description) == 0) {
    errors <- c(errors, "Field 'description' is required and must be non-empty")
  }

  if (is.null(collection$license) || nchar(collection$license) == 0) {
    errors <- c(errors, "Field 'license' is required and must be non-empty")
  }

  # Validate extent
  if (is.null(collection$extent)) {
    errors <- c(errors, "Field 'extent' is required")
  } else {
    extent_errors <- validate_extent(collection$extent)
    errors <- c(errors, extent_errors)
  }

  if (is.null(collection$links)) {
    errors <- c(errors, "Field 'links' is required (can be empty array)")
  } else if (!is.list(collection$links)) {
    errors <- c(errors, "Field 'links' must be an array")
  }

  # Validate links
  if (!is.null(collection$links) && length(collection$links) > 0) {
    link_errors <- validate_links(collection$links)
    errors <- c(errors, link_errors)
  }

  # Check recommended fields
  if (strict) {
    if (is.null(collection$title)) {
      warnings <- c(warnings, "Field 'title' is recommended")
    }
    if (is.null(collection$keywords)) {
      warnings <- c(warnings, "Field 'keywords' is recommended")
    }
    if (is.null(collection$providers)) {
      warnings <- c(warnings, "Field 'providers' is recommended")
    }
  }

  # Validate providers if present
  if (!is.null(collection$providers)) {
    provider_errors <- validate_providers(collection$providers)
    errors <- c(errors, provider_errors)
  }

  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}


#' Validate STAC Item
#'
#' @keywords internal
validate_item <- function(item, strict = FALSE) {
  errors <- character()
  warnings <- character()

  # Check required fields
  if (is.null(item$type) || item$type != "Feature") {
    errors <- c(errors, "Field 'type' must be 'Feature'")
  }

  if (is.null(item$stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(item$id) || nchar(item$id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  # Validate geometry and bbox
  if (!is.null(item$geometry)) {
    geom_errors <- validate_geometry(item$geometry)
    errors <- c(errors, geom_errors)

    if (is.null(item$bbox)) {
      errors <- c(errors, "Field 'bbox' is required when geometry is not null")
    } else {
      bbox_errors <- validate_bbox(item$bbox)
      errors <- c(errors, bbox_errors)
    }
  } else {
    if (!is.null(item$bbox)) {
      errors <- c(errors, "Field 'bbox' is prohibited when geometry is null")
    }
  }

  # Validate properties
  if (is.null(item$properties)) {
    errors <- c(errors, "Field 'properties' is required")
  } else {
    prop_errors <- validate_item_properties(item$properties)
    errors <- c(errors, prop_errors)
  }

  if (is.null(item$links)) {
    errors <- c(errors, "Field 'links' is required (can be empty array)")
  } else if (!is.list(item$links)) {
    errors <- c(errors, "Field 'links' must be an array")
  }

  if (is.null(item$assets)) {
    errors <- c(errors, "Field 'assets' is required (can be empty object)")
  } else if (!is.list(item$assets)) {
    errors <- c(errors, "Field 'assets' must be an object")
  }

  # Validate links
  if (!is.null(item$links) && length(item$links) > 0) {
    link_errors <- validate_links(item$links)
    errors <- c(errors, link_errors)
  }

  # Validate assets
  if (!is.null(item$assets) && length(item$assets) > 0) {
    asset_errors <- validate_assets(item$assets)
    errors <- c(errors, asset_errors)
  }

  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}


#' Validate Links
#'
#' @keywords internal
validate_links <- function(links) {
  errors <- character()

  for (i in seq_along(links)) {
    link <- links[[i]]

    if (!is.list(link)) {
      errors <- c(errors, paste0("Link[", i, "] must be a list object"))
    }

    if (is.null(link$rel) || nchar(link$rel) == 0) {
      errors <- c(errors, paste0("Link[", i, "] must have 'rel' field"))
    }

    if (is.null(link$href) || nchar(link$href) == 0) {
      errors <- c(errors, paste0("Link[", i, "] must have 'href' field"))
    }

    # Validate type if present
    if (!is.null(link$type) && !is.character(link$type)) {
      errors <- c(errors, paste0("Link[", i, "] 'type' must be a string"))
    }
  }

  errors
}


#' Validate Assets
#'
#' @keywords internal
validate_assets <- function(assets) {
  errors <- character()

  asset_keys <- names(assets)

  for (key in asset_keys) {
    asset <- assets[[key]]

    if (!is.list(asset)) {
      errors <- c(errors, paste0("Asset '", key, "' must be a list object"))
    }

    if (is.null(asset$href) || nchar(asset$href) == 0) {
      errors <- c(errors, paste0("Asset '", key, "' must have 'href' field"))
    }

    # Validate roles if present
    if (!is.null(asset$roles)) {
      if (!is.character(asset$roles)) {
        errors <- c(errors, paste0("Asset '", key, "' 'roles' must be a character vector"))
      }
    }
  }

  errors
}


#' Validate Extent Object
#'
#' Validates the spatial and temporal extent fields of a STAC Collection.
#' Checks for required bbox and interval fields and ensures proper structure.
#' 
#' @details
#' The extent object must contain two required fields:
#' \itemize{
#'   \item \code{spatial}: Contains a \code{bbox} field with a list of one or more bounding boxes.
#'     Each bounding box must be a numeric vector of length 4 (2D: c(west, south, east, north))
#'     or 6 (3D: c(west, south, min_elevation, east, north, max_elevation)).
#'   \item \code{temporal}: Contains an \code{interval} field with a time interval.
#'     The time interval must be a vector of 2 elements representing start and end times
#'     (as character or NA for open-ended intervals).
#' }
#'
#' @keywords internal
validate_extent <- function(extent) {
  errors <- character()

  if (!is.list(extent)) {
    return("Field 'extent' must be a list object")
  }

  # Check spatial extent
  if (is.null(extent$spatial)) {
    errors <- c(errors, "Field 'extent$spatial' is required")
  } else {
    if (is.null(extent$spatial$bbox)) {
      errors <- c(errors, "Field 'extent$spatial$bbox' is required")
    } else if (!is.list(extent$spatial$bbox)) {
      errors <- c(errors, "Field 'extent$spatial$bbox' must be a list object")
    } else {
      for (i in seq_along(extent$spatial$bbox)) {
        bbox <- extent$spatial$bbox[[i]]
        bbox_errors <- validate_bbox(bbox, prefix = paste0("extent$spatial$bbox[", i, "]"))
        errors <- c(errors, bbox_errors)
      }
    }
  }

  # Check temporal extent
  # intervals is a vector of two POSIXct with one element potentially being NA
  # for open-sided intervals
  if (is.null(extent$temporal)) {
    errors <- c(errors, "Field 'extent$temporal' is required")
  } else {
    if (is.null(extent$temporal$interval)) {
      errors <- c(errors, "Field 'extent$temporal$interval' is required")
    } else if (!is.character(extent$temporal$interval)) {
      errors <- c(errors, "Field 'extent$temporal$interval' must be a character")
      if (length(extent$temporal$interval) != 2) {
        errors <- c(errors, "Field 'extent$spatial$interval' must have length 2")
      }
    }
  }

  errors
}


#' Validate Bounding Box
#'
#' @keywords internal
validate_bbox <- function(bbox, prefix = "bbox") {
  errors <- character()

  if (!is.numeric(bbox)) {
    return(paste0(prefix, " must be numeric"))
  }

  if (!length(bbox) %in% c(4, 6)) {
    errors <- c(errors, paste0(prefix, " must have 4 or 6 elements"))
  } else if (length(bbox) == 4) {
    if (bbox[1] > bbox[3]) {
      errors <- c(errors, paste0(prefix, ": west must be <= east"))
    }
    if (bbox[2] > bbox[4]) {
      errors <- c(errors, paste0(prefix, ": south must be <= north"))
    }
  } else if (length(bbox) == 6) {
    if (bbox[1] > bbox[4]) {
      errors <- c(errors, paste0(prefix, ": west must be <= east"))
    }
    if (bbox[2] > bbox[5]) {
      errors <- c(errors, paste0(prefix, ": south must be <= north"))
    }
    if (bbox[3] > bbox[6]) {
      errors <- c(errors, paste0(prefix, ": min elevation must be <= max elevation"))
    }
  }

  errors
}


#' Validate Geometry
#'
#' @keywords internal
validate_geometry <- function(geometry) {
  errors <- character()

  if (!is.list(geometry)) {
    return("Field 'geometry' must be a GeoJSON geometry object")
  }

  if (is.null(geometry$type)) {
    errors <- c(errors, "Geometry must have a 'type' field")
  } else {
    valid_types <- c("Point", "LineString", "Polygon", "MultiPoint",
                     "MultiLineString", "MultiPolygon", "GeometryCollection")
    if (!geometry$type %in% valid_types) {
      errors <- c(errors, paste0(
        "Geometry type '", geometry$type, "' is not valid. ",
        "Must be one of: ", paste(valid_types, collapse = ", ")
      ))
    }
  }

  if (is.null(geometry$coordinates) &&
      (!is.null(geometry$type) && geometry$type != "GeometryCollection")) {
    errors <- c(errors, "Geometry must have 'coordinates' field")
  }

  errors
}

#' Validate Item Properties
#'
#' @keywords internal
validate_item_properties <- function(properties) {
  errors <- character()

  if (!is.list(properties)) {
    return("Field 'properties' must be an object")
  }

  # Check datetime requirement
  has_datetime <- !is.null(properties$datetime)
  has_start <- !is.null(properties$start_datetime)
  has_end <- !is.null(properties$end_datetime)

  if (!has_datetime && !(has_start && has_end)) {
    errors <- c(errors, paste(
      "Properties must contain 'datetime' or both 'start_datetime' and 'end_datetime'"
    ))
  }

  errors
}

#' Validate Providers
#'
#' @keywords internal
validate_providers <- function(providers) {
  errors <- character()

  if (!is.list(providers)) {
    return("Field 'providers' must be a list")
  }

  for (i in seq_along(providers)) {
    provider <- providers[[i]]

    if (!is.list(provider)) {
      errors <- c(errors, paste0("Provider[", i, "] must be an object"))
      next
    }

    if (is.null(provider$name) || nchar(provider$name) == 0) {
      errors <- c(errors, paste0("Provider[", i, "] must have 'name' field"))
    }

    if (!is.null(provider$roles)) {
      valid_roles <- c("producer", "licensor", "processor", "host")
      if (is.character(provider$roles)) {
        invalid <- setdiff(provider$roles, valid_roles)
        if (length(invalid) > 0) {
          errors <- c(errors, paste0(
            "Provider[", i, "] has invalid roles: ", paste(invalid, collapse = ", ")
          ))
        }
      } else {
        errors <- c(errors, paste0("Provider[", i, "] 'roles' must be an vector of strings"))
      }
    }
  }

  errors
}
