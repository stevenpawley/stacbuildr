# Helper operator for NULL coalescing
`%||%` <- function(a, b) {
  if (is.null(a))
    b
  else
    a
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
