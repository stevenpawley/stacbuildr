# Registry of the STAC extensions bundled with stacbuildr --------------------
#
# One authoritative table mapping each extension's short name (the path
# segment in its stac-extensions.github.io schema URI) to the schema version
# this package targets and whether the extension is still experimental. The
# add_*_extension() functions declare their schema via add_stac_extension(),
# which reads this table, so a version bump or an experimental flag is a
# one-line change here instead of an edit in each extension file.
#
# tools/check-extensions.R (run by a scheduled GitHub workflow) also reads
# this table to detect upstream releases and open update PRs.

# @keywords internal
stac_extension_registry <- list(
  classification = list(version = "v2.0.0", experimental = FALSE),
  datacube       = list(version = "v2.3.0", experimental = FALSE),
  eo             = list(version = "v2.0.0", experimental = FALSE),
  pointcloud     = list(version = "v2.0.0", experimental = FALSE),
  projection     = list(version = "v2.0.0", experimental = FALSE),
  raster         = list(version = "v2.0.0", experimental = FALSE),
  render         = list(version = "v2.0.0", experimental = FALSE),
  scientific     = list(version = "v1.0.0", experimental = FALSE),
  table          = list(version = "v1.2.0", experimental = FALSE),
  vector         = list(version = "v0.1.0", experimental = TRUE)
)


# Look up one registry entry, aborting on an unknown name so that a typo in
# an add_*_extension() call fails loudly instead of writing a wrong URI.
#
# @keywords internal
stac_extension_entry <- function(name) {
  entry <- stac_extension_registry[[name]]
  if (is.null(entry)) {
    cli::cli_abort(c(
      "Unknown stacbuildr extension: {.val {name}}.",
      i = "Known extensions: {.val {names(stac_extension_registry)}}."
    ))
  }
  return(entry)
}


# TRUE when the named extension is experimental (pre-1.0), meaning its
# schema may change upstream between releases.
#
# @keywords internal
stac_extension_is_experimental <- function(name) {
  return(isTRUE(stac_extension_entry(name)$experimental))
}


# Schema URI for a bundled extension. Precedence: an explicit `version`
# argument, then the `stacbuildr.extension_versions` option (a named
# character vector, e.g. c(vector = "v0.2.0")), then the registry default.
#
# @keywords internal
extension_schema_uri <- function(name, version = NULL) {
  entry <- stac_extension_entry(name)

  if (is.null(version)) {
    overrides <- getOption("stacbuildr.extension_versions", default = character())
    if (is.list(overrides)) {
      overrides <- unlist(overrides, use.names = TRUE)
    }
    hit <- overrides[name]
    if (!is.null(hit) && length(hit) == 1L && !is.na(hit) && nzchar(hit)) {
      version <- hit
    }
  }

  version <- version %||% entry$version
  return(paste0(
    "https://stac-extensions.github.io/",
    name,
    "/",
    version,
    "/schema.json"
  ))
}


# Declare a bundled extension on a STAC object: appends its schema URI to
# `stac_extensions` (at most once). Works on items and collections alike,
# since both carry the field. This is the single replacement for the
# per-file hardcoded URI blocks in every add_*_extension() function.
#
# @keywords internal
add_stac_extension <- function(x, name, version = NULL) {
  uri <- extension_schema_uri(name, version)
  if (is.null(x$stac_extensions)) {
    x$stac_extensions <- character(0)
  }
  if (!uri %in% x$stac_extensions) {
    x$stac_extensions <- c(x$stac_extensions, uri)
  }
  return(x)
}
