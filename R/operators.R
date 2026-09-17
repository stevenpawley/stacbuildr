# Helper operator for NULL coalescing
`%||%` <- function(a, b) {
  if (is.null(a)) {
    b
  } else {
    a
  }
}


# S3 object construction ---------------------------------------------------

# The package models STAC documents as classed lists. Constructors validate
# their declared fields once the complete object exists; mutation helpers and
# writers validate again at their public boundaries.
new_stac_property <- function(
  class = NULL,
  validator = NULL,
  default = NULL,
  setter = NULL
) {
  structure(
    list(
      class = class,
      validator = validator,
      default = default,
      setter = setter
    ),
    class = "stac_property"
  )
}

new_stac_union <- function(...) {
  structure(list(classes = list(...)), class = "stac_union")
}

stac_class_name <- function(x) {
  if (is.function(x)) attr(x, "stac_class") else x
}

stac_value_matches <- function(value, specification) {
  if (is.null(specification) || identical(specification, "any")) return(TRUE)
  if (inherits(specification, "stac_union")) {
    return(any(vapply(
      specification$classes,
      function(candidate) {
        if (is.null(candidate)) is.null(value) else {
          stac_value_matches(value, candidate)
        }
      },
      logical(1)
    )))
  }
  class_name <- stac_class_name(specification)
  switch(
    class_name,
    character = is.character(value),
    numeric = is.numeric(value),
    integer = is.integer(value),
    logical = is.logical(value),
    list = is.list(value),
    inherits(value, class_name)
  )
}

stac_property_spec <- function(x) {
  if (inherits(x, "stac_property")) x else new_stac_property(x)
}

stac_specification_label <- function(specification) {
  if (inherits(specification, "stac_union")) {
    labels <- vapply(
      specification$classes,
      function(x) if (is.null(x)) "NULL" else stac_class_name(x),
      character(1)
    )
    return(paste(labels, collapse = " or "))
  }
  stac_class_name(specification) %||% "valid"
}

validate_stac_properties <- function(object, properties, class_name) {
  for (name in names(properties)) {
    specification <- stac_property_spec(properties[[name]])
    value <- unclass(object)[[name]]
    if (!stac_value_matches(value, specification$class)) {
      expected <- stac_specification_label(specification$class)
      cli::cli_abort("{.field {name}} must be {expected}.")
    }
    if (!is.null(specification$validator)) {
      problem <- specification$validator(value)
      if (is.character(problem) && length(problem) > 0L) {
        cli::cli_abort("{.field {name}} {problem}")
      }
    }
  }
  invisible(object)
}

new_stac_object <- function(base = list(), ...) {
  object <- c(unclass(base), list(...))
  attr(object, "stac_properties") <- attr(base, "stac_properties")
  attr(object, "stac_validators") <- attr(base, "stac_validators")
  object
}

new_stac_class <- function(
  class_name,
  parent = NULL,
  properties = list(),
  constructor = NULL,
  validator = NULL
) {
  parent_classes <- if (is.null(parent)) {
    "stac_object"
  } else {
    c(stac_class_name(parent), attr(parent, "stac_parent_classes"))
  }

  automatic_constructor <- is.null(constructor)
  if (automatic_constructor) {
    constructor <- function(...) {
      values <- list(...)
      supplied_names <- names(values) %||% rep("", length(values))
      unnamed <- which(!nzchar(supplied_names))
      available <- setdiff(
        names(properties),
        supplied_names[nzchar(supplied_names)]
      )
      if (length(unnamed) > length(available)) {
        cli::cli_abort("Too many positional arguments for {.fn {class_name}}.")
      }
      supplied_names[unnamed] <- available[seq_along(unnamed)]
      names(values) <- supplied_names
      values
    }
  }

  constructor_function <- constructor
  property_definitions <- properties
  object_validator <- validator

  class_constructor <- function(...) {
    call <- as.list(match.call(expand.dots = TRUE))[-1]
    values <- lapply(call, eval, envir = parent.frame())
    object <- do.call(constructor_function, values)
    inherited_properties <- attr(object, "stac_properties") %||% list()
    inherited_validators <- attr(object, "stac_validators") %||% list()
    for (name in setdiff(names(property_definitions), names(object))) {
      default <- stac_property_spec(property_definitions[[name]])$default
      object[[name]] <- if (is.language(default)) eval(default) else default
    }
    for (name in intersect(names(property_definitions), names(object))) {
      setter <- stac_property_spec(property_definitions[[name]])$setter
      if (!is.null(setter)) object <- setter(object, object[[name]])
    }
    class(object) <- unique(c(class_name, parent_classes))
    validate_stac_properties(object, property_definitions, class_name)
    if (!is.null(object_validator)) {
      problem <- do.call(object_validator, list(object))
      if (is.character(problem) && length(problem) > 0L) {
        cli::cli_abort(problem)
      }
    }
    attr(object, "stac_properties") <- c(
      inherited_properties,
      property_definitions
    )
    attr(object, "stac_validators") <- c(
      inherited_validators,
      if (is.null(object_validator)) list() else list(object_validator)
    )
    object
  }
  if (automatic_constructor) {
    public_formals <- lapply(property_definitions, function(property) {
      stac_property_spec(property)$default
    })
    formals(class_constructor) <- as.pairlist(public_formals)
  } else {
    formals(class_constructor) <- formals(constructor)
  }
  attr(class_constructor, "stac_class") <- class_name
  attr(class_constructor, "stac_parent_classes") <- parent_classes
  class_constructor
}

stac_inherits <- function(x, class) {
  inherits(x, stac_class_name(class))
}

validate_stac_object <- function(x) {
  properties <- attr(x, "stac_properties") %||% list()
  if (length(properties) > 0L) {
    validate_stac_properties(x, properties, class(x)[[1]])
  }
  for (validator in attr(x, "stac_validators") %||% list()) {
    problem <- validator(x)
    if (is.character(problem) && length(problem) > 0L) cli::cli_abort(problem)
  }
  invisible(x)
}

# Keep base R's structural display focused on user-facing fields. The private
# validation specifications include functions and recursive class metadata that
# are useful to assignment methods but not to readers inspecting an object.
#' @exportS3Method
str.stac_object <- function(object, ...) {
  fields <- unclass(object)
  attributes(fields) <- list(names = names(fields))
  utils::str(fields, ...)
  invisible(object)
}

#' @export
`$<-.stac_object` <- function(x, name, value) {
  object_class <- class(x)
  properties <- attr(x, "stac_properties") %||% list()
  validators <- attr(x, "stac_validators") %||% list()
  y <- unclass(x)
  specification <- properties[[name]]
  if (!is.null(specification)) {
    setter <- stac_property_spec(specification)$setter
    if (!is.null(setter)) y <- setter(y, value) else y[[name]] <- value
  } else {
    y[[name]] <- value
  }
  class(y) <- object_class
  attr(y, "stac_properties") <- properties
  attr(y, "stac_validators") <- validators
  validate_stac_object(y)
  y
}

#' @export
`[[<-.stac_object` <- function(x, i, value) {
  if (is.character(i) && length(i) == 1L) {
    return(`$<-.stac_object`(x, i, value))
  }
  y <- unclass(x)
  y[[i]] <- value
  class(y) <- class(x)
  attr(y, "stac_properties") <- attr(x, "stac_properties")
  attr(y, "stac_validators") <- attr(x, "stac_validators")
  validate_stac_object(y)
  y
}


# Mark a value as a JSON array.
#
# The writers serialise with jsonlite's auto_unbox = TRUE, which collapses a
# length-1 atomic vector to a JSON scalar. That is right for the many STAC
# fields that are single values, but wrong for the ones the spec types as
# arrays: a collection with one keyword would emit "keywords": "dem" where the
# schema demands ["dem"]. Wrapping in a list forces the array form regardless
# of length, since auto_unbox never unboxes a list.
#
# NULL passes through so callers can use it on optional fields without
# guarding, and a value that is already a list is left alone.
#
# @keywords internal
as_json_array <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.list(x)) {
    return(x)
  }
  as.list(x)
}


# STAC Common Metadata fields that the spec types as JSON arrays. These may
# appear on Item properties and on Asset objects, so both normalise them
# through as_json_array() to stop a single value collapsing to a scalar.
# Taken from basics.json (keywords, roles), instrument.json (instruments),
# provider.json (providers) and bands.json (bands) in the item spec.
#
# @keywords internal
stac_common_array_fields <- c(
  "keywords",
  "roles",
  "instruments",
  "providers",
  "bands"
)

# Coerce every known array-typed Common Metadata field in a named list.
#
# @keywords internal
normalize_common_arrays <- function(x) {
  for (field in intersect(names(x), stac_common_array_fields)) {
    x[[field]] <- as_json_array(x[[field]])
  }
  x
}

# Recursively reduce S3 metadata objects to their JSON-ready list forms.
# Named and unnamed lists retain their shape; atomic values pass through.
stac_json_value <- function(x) {
  if (inherits(x, "stac_object")) {
    x <- as.list(x)
  }
  if (is.list(x)) {
    return(lapply(x, stac_json_value))
  }
  x
}

compact_nulls <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}


# Attach band objects to an Item's properties or to one of its assets.
#
# STAC 1.1 replaced the per-extension `eo:bands` and `raster:bands` arrays with
# a single common `bands` array, whose objects carry prefixed fields from every
# extension that describes them. add_eo_extension() and add_raster_extension()
# therefore write to the same place, so bands already present are merged with
# the incoming ones field by field rather than overwritten. Merging only makes
# sense when both arrays describe the same bands, so a list of a different
# length replaces what was there.
#
# @keywords internal
set_bands <- function(item, bands, asset_key = NULL) {
  if (!is.null(asset_key)) {
    if (is.null(item$assets[[asset_key]])) {
      cli::cli_abort("Asset '{asset_key}' does not exist in item")
    }
    item$assets[[asset_key]]$extra_fields[["bands"]] <- merge_bands(
      item$assets[[asset_key]]$extra_fields[["bands"]],
      bands
    )
  } else {
    item$properties[["bands"]] <- merge_bands(
      item$properties[["bands"]],
      bands
    )
  }

  item
}

# @keywords internal
merge_bands <- function(existing, bands) {
  if (is.null(existing) || length(existing) != length(bands)) {
    return(bands)
  }

  Map(
    function(old, new) {
      old <- stac_json_value(old)
      new <- stac_json_value(new)
      old[names(new)] <- new
      old
    },
    existing,
    bands
  )
}


# Guard against two children or two items in the same catalog sharing an id.
#
# write_stac() derives each output path from the object's id, so a repeated id
# means the second object overwrites the first file while both links survive,
# leaving a catalog whose links point twice at a single file. Catching it where
# the object is added keeps the error next to the mistake rather than
# surfacing it as silent data loss at write time.
#
# @keywords internal
check_duplicate_ids <- function(new_ids, existing_ids, what) {
  clashes <- intersect(new_ids, existing_ids)
  repeats <- unique(new_ids[duplicated(new_ids)])
  duplicates <- unique(c(clashes, repeats))

  if (length(duplicates) > 0) {
    cli::cli_abort(c(
      "Cannot add {what} with a duplicate id: {.val {duplicates}}.",
      "i" = "write_stac() names each file after the id, so the second would
             overwrite the first while both links remained.",
      ">" = "Use a unique id, or drop the duplicate."
    ))
  }

  invisible(NULL)
}
