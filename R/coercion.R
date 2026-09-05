# Turning STAC objects into the shapes R works in: a data frame of items, an
# sf object, and the sf accessors on a single Item.
#
# These are plain S3 methods rather than S7::method() assignments. Assigning to
# an S3 generic through S7 leaves a binding of the generic's name in this
# namespace, which is what the workaround in .onLoad() exists to undo (see
# zzz.R). Registering these the ordinary way avoids the problem rather than
# adding to it.

# One item's properties as a single-row list, with the fields promoted out of
# @properties that every item has.
item_row <- function(item) {
  props <- item@properties %||% list()

  # datetime is the property a reader looks for first, so it leads the
  # properties rather than sitting wherever it happens to be stored.
  lead <- intersect(c("datetime", "start_datetime", "end_datetime"), names(props))

  c(
    list(
      id = item@id,
      collection = item@collection %||% NA_character_
    ),
    props[lead],
    props[setdiff(names(props), lead)]
  )
}

# Bind rows that may not share names, filling the gaps with NA. A column whose
# values are not all length-1 atomics becomes a list column, since STAC
# properties routinely hold vectors (proj:transform) and objects (bands).
rows_to_df <- function(rows) {
  cols <- unique(unlist(lapply(rows, names)))

  out <- lapply(cols, function(nm) {
    vals <- lapply(rows, function(r) if (is.null(r[[nm]])) NA else r[[nm]])
    simple <- all(vapply(
      vals,
      function(v) is.atomic(v) && length(v) == 1L,
      logical(1)
    ))
    if (simple) unlist(vals, use.names = FALSE) else I(vals)
  })

  names(out) <- cols
  structure(
    out,
    class = "data.frame",
    row.names = seq_along(rows)
  )
}

# The items of a catalog, or NULL. Kept in one place so every method below
# treats an empty catalog the same way.
catalog_items <- function(x, resolve, base_path) {
  items <- get_items(x, resolve = resolve, base_path = base_path)
  items <- if (is.null(items)) list() else items

  # A catalog read back from disk carries item links but no Item objects, so
  # without resolve = TRUE it would quietly produce an empty table while
  # length() reports the linked items. Say so rather than return nothing.
  if (length(items) == 0 && !resolve && count_items(x) > 0) {
    cli::cli_warn(c(
      "{.val {count_items(x)}} item{?s} {?is/are} linked but not held in memory.",
      "i" = "A catalog read with {.fn read_stac} stores links, not items.",
      ">" = "Pass {.code resolve = TRUE} to read them from their links."
    ))
  }

  items
}

# An Item's geometry as a length-1 sfc. STAC types an Item's geometry as
# GeoJSON in WGS84, so geojsonsf can read it directly. A null geometry is legal
# for a non-spatial Item and becomes an empty geometrycollection so that the
# column stays the same length as the table.
item_sfc <- function(item) {
  if (is.null(item@geometry)) {
    return(sf::st_sfc(sf::st_geometrycollection(), crs = 4326))
  }
  geojsonsf::geojson_sfc(
    jsonlite::toJSON(item@geometry, auto_unbox = TRUE, digits = 15)
  )
}


#' Number of Items in a STAC Catalog or Collection
#'
#' @description
#' Returns the number of Items linked from a Catalog or Collection, so that a
#' catalog answers `length()` the way a container of Items should. This is the
#' same count as [count_items()], which counts `item` links rather than the
#' Item objects held in memory, so it is correct for a catalog read back from
#' disk as well as one built in the session.
#'
#' Child catalogs are not counted; use `length(get_children(x))` for those.
#'
#' @param x A `stac_catalog` or `stac_collection` object.
#'
#' @return An integer count of linked Items.
#'
#' @examples
#' catalog <- stac_catalog(id = "my-catalog", description = "Example")
#' length(catalog)
#'
#' @export
length.stac_catalog <- function(x) {
  count_items(x)
}


#' Coerce a STAC Catalog, Collection or Item to a Data Frame
#'
#' @description
#' Returns one row per Item, with `id` and `collection` followed by a column for
#' every field in the Items' `properties`. Items need not share the same
#' properties: a field missing from an Item is `NA` in its row.
#'
#' A property whose values are not all length-1 atomics becomes a list column,
#' since STAC properties routinely hold vectors (`proj:transform`) and objects
#' (`bands`). Use [st_as_sf()][sf::st_as_sf] instead to get the same table with
#' the Item footprints attached as a geometry column.
#'
#' @param x A `stac_catalog`, `stac_collection` or `stac_item` object.
#' @param row.names,optional Ignored, for compatibility with the generic.
#' @param ... Ignored.
#' @param resolve (logical) When the Items are not held in memory — as after
#'   [read_stac()] — read each one from its `item` link. Default `FALSE`.
#' @param base_path (character) Directory that relative item hrefs are resolved
#'   against when `resolve = TRUE`. Default `"."`.
#'
#' @return A data frame with one row per Item. A catalog with no Items gives a
#'   zero-row data frame; if it has `item` links but no Items in memory, a
#'   warning points at `resolve = TRUE`.
#'
#' @examples
#' item <- stac_item(
#'   id = "scene-1",
#'   geometry = list(type = "Point", coordinates = c(-114, 51)),
#'   bbox = c(-114, 51, -114, 51),
#'   datetime = "2024-06-01T00:00:00Z",
#'   properties = list(`eo:cloud_cover` = 7.5)
#' )
#'
#' as.data.frame(item)
#'
#' collection <- stac_collection(
#'   id = "scenes",
#'   description = "Example",
#'   license = "CC-BY-4.0",
#'   extent = stac_extent(
#'     spatial_bbox = list(c(-115, 50, -113, 52)),
#'     temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
#'   )
#' )
#' collection <- add_item(collection, item)
#'
#' df <- as.data.frame(collection)
#' df[df$`eo:cloud_cover` < 20, c("id", "datetime")]
#'
#' @export
as.data.frame.stac_catalog <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  resolve = FALSE,
  base_path = "."
) {
  items <- catalog_items(x, resolve, base_path)

  if (length(items) == 0) {
    return(data.frame(
      id = character(0),
      collection = character(0),
      stringsAsFactors = FALSE
    ))
  }

  rows_to_df(lapply(items, item_row))
}

#' @rdname as.data.frame.stac_catalog
#' @export
as.data.frame.stac_item <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...
) {
  rows_to_df(list(item_row(x)))
}


#' Coerce a STAC Catalog, Collection or Item to an sf Object
#'
#' @description
#' Returns the table that [as.data.frame()][as.data.frame.stac_catalog] gives,
#' with the Item footprints attached as a geometry column. This is the shape
#' most spatial work in R wants: filter on properties, plot the footprints, join
#' against other layers.
#'
#' STAC types an Item's `geometry` as GeoJSON in WGS84 whatever projection the
#' underlying data uses, so the result is always in EPSG:4326. The native CRS,
#' when an Item records one, is in its `proj:code` property — see
#' [add_projection_extension()].
#'
#' An Item with a null geometry, which STAC allows for non-spatial data, gets an
#' empty geometry rather than being dropped.
#'
#' @param x A `stac_catalog`, `stac_collection` or `stac_item` object.
#' @param ... Ignored.
#' @param resolve (logical) When the Items are not held in memory — as after
#'   [read_stac()] — read each one from its `item` link. Default `FALSE`.
#' @param base_path (character) Directory that relative item hrefs are resolved
#'   against when `resolve = TRUE`. Default `"."`.
#'
#' @return An `sf` object with one row per Item, in EPSG:4326.
#'
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' item <- stac_item(
#'   id = "scene-1",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-114, 51), c(-113, 51), c(-113, 52), c(-114, 52), c(-114, 51)
#'     ))
#'   ),
#'   bbox = c(-114, 51, -113, 52),
#'   datetime = "2024-06-01T00:00:00Z",
#'   properties = list(`eo:cloud_cover` = 7.5)
#' )
#'
#' scenes <- sf::st_as_sf(item)
#' sf::st_bbox(scenes)
#'
#' @exportS3Method sf::st_as_sf
st_as_sf.stac_catalog <- function(x, ..., resolve = FALSE, base_path = ".") {
  items <- catalog_items(x, resolve, base_path)

  if (length(items) == 0) {
    return(sf::st_sf(
      id = character(0),
      collection = character(0),
      geometry = sf::st_sfc(crs = 4326),
      stringsAsFactors = FALSE
    ))
  }

  df <- rows_to_df(lapply(items, item_row))
  geometry <- do.call(c, lapply(items, item_sfc))
  sf::st_sf(df, geometry = geometry)
}

#' @rdname st_as_sf.stac_catalog
#' @exportS3Method sf::st_as_sf
st_as_sf.stac_item <- function(x, ...) {
  sf::st_sf(rows_to_df(list(item_row(x))), geometry = item_sfc(x))
}


#' sf Accessors for a STAC Item
#'
#' @description
#' A STAC Item is a GeoJSON Feature, so the `sf` accessors work on it directly.
#'
#' * `st_geometry()` returns the Item's footprint as a length-1 `sfc`.
#' * `st_bbox()` returns its bounding box from the Item's `bbox` field. A STAC
#'   Item must carry one whenever it has a geometry, so the empty bbox comes
#'   back only for a non-spatial Item with neither.
#' * `st_crs()` returns EPSG:4326. An Item's `geometry` and `bbox` are WGS84 by
#'   specification whatever projection the underlying data uses; the native CRS,
#'   when recorded, is in the `proj:code` property.
#'
#' @param x A `stac_item` object.
#' @param obj A `stac_item` object.
#' @param ... Ignored.
#'
#' @return `st_geometry()` an `sfc`; `st_bbox()` a `bbox`; `st_crs()` a `crs`.
#'
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' item <- stac_item(
#'   id = "scene-1",
#'   geometry = list(type = "Point", coordinates = c(-114, 51)),
#'   bbox = c(-114, 51, -114, 51),
#'   datetime = "2024-06-01T00:00:00Z"
#' )
#'
#' sf::st_geometry(item)
#' sf::st_bbox(item)
#' sf::st_crs(item)$epsg
#'
#' @name stac_item_sf_accessors
NULL

#' @rdname stac_item_sf_accessors
#' @exportS3Method sf::st_geometry
st_geometry.stac_item <- function(obj, ...) {
  item_sfc(obj)
}

#' @rdname stac_item_sf_accessors
#' @exportS3Method sf::st_bbox
st_bbox.stac_item <- function(obj, ...) {
  if (!is.null(obj@bbox) && length(obj@bbox) >= 4) {
    # A 3D STAC bbox is (xmin, ymin, zmin, xmax, ymax, zmax); sf's bbox is 2D,
    # so the elevation pair is dropped.
    b <- if (length(obj@bbox) == 6L) obj@bbox[c(1, 2, 4, 5)] else obj@bbox[1:4]
    return(sf::st_bbox(
      stats::setNames(
        as.numeric(b),
        c("xmin", "ymin", "xmax", "ymax")
      ),
      crs = sf::st_crs(4326)
    ))
  }
  sf::st_bbox(item_sfc(obj))
}

#' @rdname stac_item_sf_accessors
#' @exportS3Method sf::st_crs
st_crs.stac_item <- function(x, ...) {
  sf::st_crs(4326)
}


#' Extract Items from a STAC Catalog or Collection
#'
#' @description
#' Treats a Catalog or Collection as the container of Items that `length()`
#' reports, so Items can be pulled out by position or by `id`.
#'
#' * `x[i]` returns a list of Items.
#' * `x[[i]]` returns a single Item.
#'
#' Both accept a character index, matched against Item `id`s. Subsetting reads
#' the Items held in memory; it does not follow `item` links to disk, so it
#' returns nothing for a catalog read back with [read_stac()]. Use
#' [get_items()] with `resolve = TRUE` for that.
#'
#' @param x A `stac_catalog` or `stac_collection` object.
#' @param i Item positions, or Item `id`s as a character vector.
#'
#' @return `[` a list of `stac_item` objects; `[[` a single `stac_item`.
#'
#' @examples
#' collection <- stac_collection(
#'   id = "scenes",
#'   description = "Example",
#'   license = "CC-BY-4.0",
#'   extent = stac_extent(
#'     spatial_bbox = list(c(-115, 50, -113, 52)),
#'     temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
#'   )
#' )
#' collection <- add_item(collection, stac_item(
#'   id = "scene-1",
#'   geometry = list(type = "Point", coordinates = c(-114, 51)),
#'   bbox = c(-114, 51, -114, 51),
#'   datetime = "2024-06-01T00:00:00Z"
#' ))
#'
#' collection[["scene-1"]]@id
#' length(collection[1])
#'
#' @export
`[.stac_catalog` <- function(x, i) {
  items <- catalog_items(x, resolve = FALSE, base_path = ".")
  items[stac_item_index(items, i, multiple = TRUE)]
}

#' @rdname sub-.stac_catalog
#' @export
`[[.stac_catalog` <- function(x, i) {
  items <- catalog_items(x, resolve = FALSE, base_path = ".")
  idx <- stac_item_index(items, i, multiple = FALSE)
  items[[idx]]
}

# Resolve a subsetting index against a list of Items, allowing ids as well as
# positions. Kept separate so `[` and `[[` reject a bad id the same way.
stac_item_index <- function(items, i, multiple) {
  if (!is.character(i)) {
    return(i)
  }

  ids <- vapply(items, function(it) it@id, character(1))
  idx <- match(i, ids)

  if (anyNA(idx)) {
    cli::cli_abort(c(
      "No item with id {.val {i[is.na(idx)]}}.",
      "i" = if (length(ids) > 0) {
        "Available ids: {.val {ids}}."
      } else {
        "This catalog holds no items in memory; see {.fn get_items}."
      }
    ))
  }

  if (!multiple && length(idx) != 1L) {
    cli::cli_abort("Subscript must select exactly one item.")
  }

  idx
}
