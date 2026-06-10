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

  # Validate item/collection/catalog (use inherits() to handle S7 qualified class names)
  if (inherits(stac_object, "stac_item")) {
    validate_item(stac_object, strict)
  } else if (inherits(stac_object, "stac_collection")) {
    validate_collection(stac_object, strict)
  } else if (inherits(stac_object, "stac_catalog")) {
    validate_catalog(stac_object, strict)
  } else {
    list(
      valid = FALSE,
      errors = "Object must be a stac_catalog, stac_collection, or stac_item",
      warnings = character()
    )
  }
}


#' Validate STAC Catalog
#'
#' @keywords internal
validate_catalog <- function(catalog, strict = FALSE) {
  errors <- character()
  warnings <- character()

  # Check required fields
  if (is.null(catalog@type) || catalog@type != "Catalog") {
    errors <- c(errors, "Field 'type' must be 'Catalog'")
  }

  if (is.null(catalog@stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(catalog@id) || nchar(catalog@id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  if (is.null(catalog@description) || nchar(catalog@description) == 0) {
    errors <- c(errors, "Field 'description' is required and must be non-empty")
  }

  if (is.null(catalog@links)) {
    errors <- c(errors, "Field 'links' is required (can be empty list)")
  } else if (!is.list(catalog@links)) {
    errors <- c(errors, "Field 'links' must be a list")
  }

  # Validate links
  if (!is.null(catalog@links) && length(catalog@links) > 0) {
    link_errors <- validate_links(catalog@links)
    errors <- c(errors, link_errors)
  }

  # Check recommended fields
  if (strict && is.null(catalog@title)) {
    warnings <- c(warnings, "Field 'title' is recommended")
  }

  # Validate stac_extensions if present
  if (!is.null(catalog@stac_extensions)) {
    if (!is.character(catalog@stac_extensions)) {
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
  if (is.null(collection@type) || collection@type != "Collection") {
    errors <- c(errors, "Field 'type' must be 'Collection'")
  }

  if (is.null(collection@stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(collection@id) || nchar(collection@id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  if (is.null(collection@description) || nchar(collection@description) == 0) {
    errors <- c(errors, "Field 'description' is required and must be non-empty")
  }

  if (is.null(collection@license) || nchar(collection@license) == 0) {
    errors <- c(errors, "Field 'license' is required and must be non-empty")
  }

  # Validate extent
  if (is.null(collection@extent)) {
    errors <- c(errors, "Field 'extent' is required")
  } else {
    extent_errors <- validate_extent(collection@extent)
    errors <- c(errors, extent_errors)
  }

  if (is.null(collection@links)) {
    errors <- c(errors, "Field 'links' is required (can be empty array)")
  } else if (!is.list(collection@links)) {
    errors <- c(errors, "Field 'links' must be an array")
  }

  # Validate links
  if (!is.null(collection@links) && length(collection@links) > 0) {
    link_errors <- validate_links(collection@links)
    errors <- c(errors, link_errors)
  }

  # Check recommended fields
  if (strict) {
    if (is.null(collection@title)) {
      warnings <- c(warnings, "Field 'title' is recommended")
    }
    if (is.null(collection@keywords)) {
      warnings <- c(warnings, "Field 'keywords' is recommended")
    }
    if (is.null(collection@providers)) {
      warnings <- c(warnings, "Field 'providers' is recommended")
    }
  }

  # Validate providers if present
  if (!is.null(collection@providers)) {
    provider_errors <- validate_providers(collection@providers)
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
  if (is.null(item@type) || item@type != "Feature") {
    errors <- c(errors, "Field 'type' must be 'Feature'")
  }

  if (is.null(item@stac_version)) {
    errors <- c(errors, "Field 'stac_version' is required")
  }

  if (is.null(item@id) || nchar(item@id) == 0) {
    errors <- c(errors, "Field 'id' is required and must be non-empty")
  }

  # Validate geometry and bbox
  if (!is.null(item@geometry)) {
    geom_errors <- validate_geometry(item@geometry)
    errors <- c(errors, geom_errors)

    if (is.null(item@bbox)) {
      errors <- c(errors, "Field 'bbox' is required when geometry is not null")
    } else {
      bbox_errors <- validate_bbox(item@bbox)
      errors <- c(errors, bbox_errors)
    }
  } else {
    if (!is.null(item@bbox)) {
      errors <- c(errors, "Field 'bbox' is prohibited when geometry is null")
    }
  }

  # Validate properties
  if (is.null(item@properties)) {
    errors <- c(errors, "Field 'properties' is required")
  } else {
    prop_errors <- validate_item_properties(item@properties)
    errors <- c(errors, prop_errors)
  }

  if (is.null(item@links)) {
    errors <- c(errors, "Field 'links' is required (can be empty array)")
  } else if (!is.list(item@links)) {
    errors <- c(errors, "Field 'links' must be an array")
  }

  if (is.null(item@assets)) {
    errors <- c(errors, "Field 'assets' is required (can be empty object)")
  } else if (!is.list(item@assets)) {
    errors <- c(errors, "Field 'assets' must be an object")
  }

  # Validate links
  if (!is.null(item@links) && length(item@links) > 0) {
    link_errors <- validate_links(item@links)
    errors <- c(errors, link_errors)
  }

  # Validate assets
  if (!is.null(item@assets) && length(item@assets) > 0) {
    asset_errors <- validate_assets(item@assets)
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

    # Validate roles if present (accept character vector or list of strings)
    if (!is.null(asset$roles)) {
      roles_ok <- is.character(asset$roles) ||
        (is.list(asset$roles) && all(vapply(asset$roles, is.character, logical(1))))
      if (!roles_ok) {
        errors <- c(
          errors,
          paste0("Asset '", key, "' 'roles' must be a character vector or list of strings")
        )
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

  # Convert S7 Extent objects to plain list for validation
  if (inherits(extent, "S7_object")) {
    extent <- as.list(extent)
  }

  if (!is.list(extent)) {
    return("Field 'extent' must be a list object")
  }

  # Check spatial extent
  if (is.null(extent$spatial)) {
    errors <- c(errors, "Field 'extent$spatial' is required")
  } else {
    spatial <- if (inherits(extent$spatial, "S7_object")) {
      as.list(extent$spatial)
    } else {
      extent$spatial
    }
    if (is.null(spatial$bbox)) {
      errors <- c(errors, "Field 'extent$spatial$bbox' is required")
    } else if (!is.list(spatial$bbox)) {
      errors <- c(errors, "Field 'extent$spatial$bbox' must be a list object")
    } else {
      for (i in seq_along(spatial$bbox)) {
        bbox <- spatial$bbox[[i]]
        bbox_errors <- validate_bbox(
          bbox,
          prefix = paste0("extent$spatial$bbox[", i, "]")
        )
        errors <- c(errors, bbox_errors)
      }
    }
  }

  # Check temporal extent — interval is a list of list(start, end) pairs
  if (is.null(extent$temporal)) {
    errors <- c(errors, "Field 'extent$temporal' is required")
  } else {
    temporal <- if (inherits(extent$temporal, "S7_object")) {
      as.list(extent$temporal)
    } else {
      extent$temporal
    }
    if (is.null(temporal$interval)) {
      errors <- c(errors, "Field 'extent$temporal$interval' is required")
    } else if (!is.list(temporal$interval)) {
      errors <- c(
        errors,
        "Field 'extent$temporal$interval' must be a list of intervals"
      )
    } else {
      for (i in seq_along(temporal$interval)) {
        iv <- temporal$interval[[i]]
        if (length(iv) != 2) {
          errors <- c(
            errors,
            sprintf(
              "extent$temporal$interval[[%d]] must have exactly 2 elements",
              i
            )
          )
        }
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
      errors <- c(
        errors,
        paste0(prefix, ": min elevation must be <= max elevation")
      )
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
    valid_types <- c(
      "Point",
      "LineString",
      "Polygon",
      "MultiPoint",
      "MultiLineString",
      "MultiPolygon",
      "GeometryCollection"
    )
    if (!geometry$type %in% valid_types) {
      errors <- c(
        errors,
        paste0(
          "Geometry type '",
          geometry$type,
          "' is not valid. ",
          "Must be one of: ",
          paste(valid_types, collapse = ", ")
        )
      )
    }
  }

  if (
    is.null(geometry$coordinates) &&
      (!is.null(geometry$type) && geometry$type != "GeometryCollection")
  ) {
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
    errors <- c(
      errors,
      paste(
        "Properties must contain 'datetime' or both 'start_datetime' and 'end_datetime'"
      )
    )
  }

  errors
}

#' Validate a STAC Object Against the Official JSON Schema
#'
#' @description
#' Validates a STAC Catalog, Collection, or Item against the official STAC
#' JSON Schemas hosted at `schemas.stacspec.org`, using the
#' [jsonvalidate](https://CRAN.R-project.org/package=jsonvalidate) package.
#' Unlike [validate_stac()], which applies hand-written structural checks,
#' this function performs authoritative validation against the exact schema
#' that defines the specification.
#'
#' When `validate_extensions = TRUE` (the default), each URI listed in the
#' object's `stac_extensions` field is also used as a JSON Schema and
#' validated against in turn, so extension-level fields are checked as well.
#'
#' @param stac_object A STAC object created with [stac_item()],
#'   [stac_collection()], or [stac_catalog()].
#' @param validate_extensions (logical) If `TRUE` (the default), validate the
#'   serialised object against every JSON Schema URI declared in the object's
#'   `stac_extensions` field in addition to the core STAC schema.
#'
#' @details
#' ## Requirements
#' The `jsonvalidate` package must be installed:
#' ```r
#' install.packages("jsonvalidate")
#' ```
#'
#' ## Network Access
#' Schema files are fetched over the network at validation time — both the
#' core STAC schema and any extension schemas. Internet access is required.
#' Validation will fail with an informative error message if a schema URL
#' cannot be reached.
#'
#' ## Schema URLs
#' The core schema URL is derived from the object type and its `stac_version`
#' field, following the pattern:
#' `https://schemas.stacspec.org/v{stac_version}/{type}-spec/json-schema/{type}.json`
#'
#' ## Return Value
#' Returns the same structure as [validate_stac()]:
#' * `valid` — `TRUE` if no schema errors were found.
#' * `errors` — character vector of error messages, one per violation.
#'   Extension errors are prefixed with the extension schema URI.
#' * `warnings` — always an empty character vector (reserved for future use).
#'
#' @return A named list with elements `valid`, `errors`, and `warnings`.
#'
#' @seealso [validate_stac()] for fast, offline structural checks.
#'
#' @references
#' Official STAC JSON Schemas: \url{https://schemas.stacspec.org}
#'
#' @examples
#' item <- stac_item(
#'   id       = "my-item",
#'   geometry = list(type = "Point", coordinates = c(-105, 40)),
#'   bbox     = c(-105, 40, -105, 40),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' \dontrun{
#' result <- validate_stac_schema(item)
#' result$valid
#' result$errors
#' }
#'
#' @export
validate_stac_schema <- function(stac_object, validate_extensions = TRUE) {
  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    stop(
      "Package 'jsonvalidate' is required for schema validation. ",
      "Install with: install.packages('jsonvalidate')"
    )
  }

  if (!inherits(stac_object, c("stac_item", "stac_catalog"))) {
    return(list(
      valid    = FALSE,
      errors   = "Object must be a stac_catalog, stac_collection, or stac_item",
      warnings = character()
    ))
  }

  json         <- stac_object_to_json_string(stac_object)
  stac_version <- stac_object@stac_version %||% "1.0.0"
  core_url     <- stac_core_schema_url(stac_object, stac_version)

  errors <- run_schema_validation(json, core_url)

  ext_errors <- character()
  if (validate_extensions) {
    ext_uris <- tryCatch(stac_object@stac_extensions, error = function(e) NULL)
    for (ext_uri in ext_uris) {
      errs <- run_schema_validation(json, ext_uri)
      if (length(errs) > 0) {
        ext_errors <- c(ext_errors, sprintf("[%s] %s", ext_uri, errs))
      }
    }
  }

  all_errors <- c(errors, ext_errors)

  list(
    valid    = length(all_errors) == 0,
    errors   = all_errors,
    warnings = character()
  )
}


# Serialise a STAC S7 object to a JSON string, mirroring the write_* pattern.
#
# @keywords internal
stac_object_to_json_string <- function(stac_object) {
  obj <- strip_stored_objects(stac_object)
  if (inherits(obj, "S7_object")) {
    obj <- as.list(obj)
  }
  jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null")
}


# Build the official schemas.stacspec.org URL for the given object type and
# stac_version string (e.g. "1.0.0", "1.1.0").
#
# @keywords internal
stac_core_schema_url <- function(stac_object, stac_version) {
  base <- paste0("https://schemas.stacspec.org/v", stac_version)
  if (inherits(stac_object, "stac_item")) {
    paste0(base, "/item-spec/json-schema/item.json")
  } else if (inherits(stac_object, "stac_collection")) {
    paste0(base, "/collection-spec/json-schema/collection.json")
  } else {
    paste0(base, "/catalog-spec/json-schema/catalog.json")
  }
}


# Validate a JSON string against a single JSON Schema URL via jsonvalidate.
#
# jsonvalidate (ajv/V8) cannot make HTTP requests, so we download the schema
# and all its $ref dependencies to a session-level cache directory, rewriting
# cross-schema refs to their local cache filenames.  The cached file path is
# then passed to json_validate() so that read_schema_filename() can resolve
# the local dependency chain.
#
# Returns a character vector of formatted error messages (empty when valid).
#
# @keywords internal
run_schema_validation <- function(json, schema_url) {
  tryCatch({
    local_path <- bundle_schema_url(schema_url)

    result <- jsonvalidate::json_validate(
      json,
      local_path,
      verbose = TRUE,
      greedy  = TRUE,
      engine  = "ajv"
    )

    if (isTRUE(result)) {
      return(character())
    }

    errs <- attr(result, "errors")
    if (is.null(errs) || nrow(errs) == 0) {
      return("Schema validation failed (no details available)")
    }

    # Column name changed between jsonvalidate versions: dataPath -> instancePath
    path_col <- if ("instancePath" %in% names(errs)) "instancePath" else "dataPath"
    paths    <- errs[[path_col]]

    msgs <- ifelse(
      nchar(paths) > 0,
      paste0(paths, ": ", errs$message),
      errs$message
    )
    unique(msgs)

  }, error = function(e) {
    paste0("Could not fetch or parse schema '", schema_url, "': ", conditionMessage(e))
  })
}


# Recursively download a JSON Schema URL and all its $ref dependencies into a
# session-level flat cache directory.  Remote $ref entries in each schema are
# rewritten to point to the corresponding cached filename so that
# read_schema_filename() can resolve the full dependency chain locally.
#
# Returns the local file path of the main (entry) schema.
#
# @keywords internal
bundle_schema_url <- function(schema_url) {
  cache_dir <- file.path(tempdir(), "stacbuildr_schema_cache")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

  # Per-call visited guard to break reference cycles
  visited <- new.env(hash = TRUE, parent = emptyenv())

  bundle_one <- function(url) {
    local_path <- url_to_cached_schema_path(url, cache_dir)

    # Already cached from a previous call this session
    if (file.exists(local_path)) return(local_path)
    # Cycle guard (shouldn't happen in valid schemas, but be safe)
    if (exists(url, envir = visited)) return(local_path)
    assign(url, TRUE, envir = visited)

    txt <- tryCatch({
      con <- url(url, open = "r")
      on.exit(close(con), add = TRUE)
      paste(readLines(con, warn = FALSE), collapse = "\n")
    }, error = function(e) {
      stop(sprintf("Failed to download schema '%s': %s", url, conditionMessage(e)))
    })

    parsed    <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
    this_base <- sub("[^/]*$", "", url)   # trailing-slash base URL directory

    if (!is.null(parsed)) {
      for (ref in find_schema_refs(parsed)) {
        if (grepl("^#", ref)) next   # fragment-only ref stays as-is

        abs_url   <- if (grepl("^https?://", ref)) ref else paste0(this_base, ref)
        ref_local <- bundle_one(abs_url)

        # Rewrite this $ref in the text to the cached flat filename
        txt <- gsub(
          paste0('"', ref, '"'),
          paste0('"', basename(ref_local), '"'),
          txt, fixed = TRUE
        )
      }
    }

    writeLines(txt, local_path)
    local_path
  }

  bundle_one(schema_url)
}


# Convert a schema URL to a safe flat filename in cache_dir.
#
# @keywords internal
url_to_cached_schema_path <- function(url, cache_dir) {
  safe <- gsub("^https?://", "", url)
  safe <- gsub("[^A-Za-z0-9._-]", "_", safe)
  file.path(cache_dir, safe)
}


# Recursively collect all "$ref" values from a parsed JSON schema list.
#
# @keywords internal
find_schema_refs <- function(x) {
  if (!is.list(x)) return(character())
  refs <- character()
  if (!is.null(x[["$ref"]])) refs <- x[["$ref"]]
  for (child in x) refs <- c(refs, find_schema_refs(child))
  unique(refs)
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
          errors <- c(
            errors,
            paste0(
              "Provider[",
              i,
              "] has invalid roles: ",
              paste(invalid, collapse = ", ")
            )
          )
        }
      } else {
        errors <- c(
          errors,
          paste0("Provider[", i, "] 'roles' must be an vector of strings")
        )
      }
    }
  }

  errors
}
