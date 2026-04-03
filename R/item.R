#' Create a STAC Item
#'
#' @description
#' Creates a STAC (SpatioTemporal Asset Catalog) Item object following the
#' STAC specification version 1.1.0. A STAC Item is a GeoJSON Feature with
#' additional fields that represents an atomic collection of inseparable data
#' and metadata. Items are the core building blocks of STAC catalogs.
#'
#' @param id (character, required) Provider identifier for the Item. The ID
#'   should be unique within the Collection that contains the Item. It's
#'   recommended to use the data provider's existing identification scheme.
#' @param geometry (list, required) Defines the full footprint of the asset
#'   represented by this Item, formatted according to RFC 7946, section 3.1 (for
#'   geometry) or section 3.2 (if no geometry). Must be a valid GeoJSON
#'   geometry object (e.g., Point, Polygon, MultiPolygon) or `NULL` for non-spatial
#'   items. Coordinates should be in WGS 84 (EPSG:4326) as (longitude, latitude)
#'   or (longitude, latitude, elevation).
#' @param bbox (numeric vector, required if geometry is not NULL) Bounding Box
#'   of the asset represented by this Item, formatted according to RFC 7946, section 5.
#'   Must be a numeric vector of either 4 values `c(west, south, east, north)`
#'   for 2D or 6 values `c(west, south, min_elev, east, north, max_elev)` for 3D.
#'   Required when geometry is not NULL, prohibited when geometry is NULL.
#' @param datetime (character, required unless start_datetime and end_datetime
#'   are provided) The searchable date and time of the assets, which
#'   must be in UTC, formatted according to RFC 3339, section 5.6. Use ISO 8601
#'   format: `"2020-01-01T12:00:00Z"`. Can be `NULL` if `start_datetime` and
#'   `end_datetime` are both provided in properties.
#' @param properties (named list, optional) Additional metadata for the Item.
#'   All properties should be named elements. Common properties include `title`,
#'   `description`, `created`, `updated`, `platform`, `instruments`, `gsd`, etc.
#'   The `datetime` property will be automatically added from the `datetime`
#'   parameter. Default is an empty list.
#' @param assets (named list, optional) Dictionary of asset objects that can be
#'   downloaded or accessed. Each asset should be created with `stac_asset()`.
#'   Keys are asset identifiers (e.g., "visual", "thumbnail"). Default is an
#'   empty list.
#' @param links (list, optional) List of link objects to resources and related URLs.
#'   Items are strongly recommended to provide a link to a STAC Collection.
#'   Use `add_link()` or related helper functions to add links after creation.
#'   Default is an empty list.
#' @param stac_version (character, optional) The STAC version the Item implements.
#'   Defaults to `"1.1.0"`.
#' @param type (character, optional) Type of the GeoJSON Object. MUST be set
#'   to "Feature". Defaults to `"Feature"`.
#' @param stac_extensions (character vector, optional) A list of extension
#'   identifiers (URIs) that the Item implements. Common extensions include EO
#'   (Electro-Optical), SAR, projection, and view extensions. Each should be a
#'   full URI to the extension's JSON schema. Default is `NULL`.
#' @param collection (character, optional) The ID of the STAC Collection this
#'   Item references to with the collection relation type in the links array.
#'   This field is required when a `collection` link is present. Usually set
#'   automatically by `add_item()` when adding to a Collection. Default is `NULL`.
#' @param start_datetime (character, optional) Start datetime for Items that
#'   represent a time range. Must be in UTC RFC 3339 format. Only used when
#'   `datetime` is `NULL`.
#' @param end_datetime (character, optional) End datetime for Items that represent
#'   a time range. Must be in UTC RFC 3339 format. Only used when `datetime` is `NULL`.
#' @param ... Additional fields to include in the properties object. These will
#'   be merged with the `properties` parameter.
#'
#' @details
#' ## Required Fields
#' Based on the STAC Item specification, Items require:
#' * `type`: Must be "Feature" (auto-set)
#' * `stac_version`: STAC specification version (default "1.1.0")
#' * `id`: Unique identifier within the collection
#' * `geometry`: GeoJSON geometry or NULL
#' * `bbox`: Bounding box (required if geometry is not NULL)
#' * `properties`: Metadata object (must contain `datetime` or `start_datetime`/`end_datetime`)
#' * `links`: Array of link objects (can be empty)
#' * `assets`: Dictionary of assets (can be empty)
#'
#' ## Properties Object
#' The only required field in properties is `datetime`, but it's recommended
#' to add more fields. Common metadata fields include:
#' * `title`: Short description
#' * `description`: Detailed description
#' * `created`: Creation time
#' * `updated`: Last update time
#' * `platform`: Satellite/platform name
#' * `instruments`: Sensor instruments used
#' * `gsd`: Ground Sample Distance (resolution in meters)
#' * `constellation`: Satellite constellation
#'
#' ## Datetime Handling
#' The datetime property can be `null`, but requires `start_datetime` and
#' `end_datetime` from common metadata to be set. This is useful for Items
#' representing a time range rather than a single point in time.
#'
#' ## Geometry and Bbox
#' * Geometry can be any GeoJSON geometry type (Point, LineString, Polygon, etc.)
#' * Coordinates must be in WGS 84 (longitude, latitude order)
#' * Bbox enables quick spatial indexing and searching
#' * Both geometry and bbox can be NULL for non-spatial items (rare)
#'
#' ## Collection Relationship
#' Items are strongly recommended to provide a link to a STAC Collection.
#' If Items are part of a STAC Collection, the STAC Collection spec requires
#' Items to link back to the Collection. Use `add_item()` with
#' `add_parent_links = TRUE` to properly establish this relationship.
#'
#' @return An S7 object of class `stac_item` containing the Item metadata
#'   formatted as a GeoJSON Feature. Convert to a plain list for JSON
#'   serialization with `as.list()`, or write directly to disk using
#'   `write_item()`.
#'
#' @seealso
#' * [stac_asset()] for creating asset objects
#' * [add_item()] for adding Items to Collections or Catalogs
#' * [stac_collection()] for creating STAC Collections
#' * [add_link()] for adding links to Items
#'
#' @references
#' STAC Item Specification:
#' \url{https://github.com/radiantearth/stac-spec/blob/master/item-spec/item-spec.md}
#'
#' @examples
#' # Basic Item with point geometry
#' item <- stac_item(
#'   id = "observation-001",
#'   geometry = list(
#'     type = "Point",
#'     coordinates = c(-105.0, 40.0)
#'   ),
#'   bbox = c(-105.0, 40.0, -105.0, 40.0),
#'   datetime = "2023-06-15T10:30:00Z"
#' )
#'
#' # Item with polygon geometry and additional properties
#' item <- stac_item(
#'   id = "LC08_L1TP_044034_20230615",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-105.5, 39.5),
#'       c(-104.5, 39.5),
#'       c(-104.5, 40.5),
#'       c(-105.5, 40.5),
#'       c(-105.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-105.5, 39.5, -104.5, 40.5),
#'   datetime = "2023-06-15T17:30:00Z",
#'   properties = list(
#'     title = "Landsat 8 Scene",
#'     platform = "landsat-8",
#'     instruments = c("oli", "tirs"),
#'     gsd = 30,
#'     "eo:cloud_cover" = 5.2
#'   )
#' )
#'
#' # Add assets to the item
#' item <- item |>
#'   add_asset(
#'     key = "visual",
#'     href = "https://example.com/LC08_visual.tif",
#'     title = "True Color Image",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("visual")
#'   ) |>
#'   add_asset(
#'     key = "thumbnail",
#'     href = "https://example.com/LC08_thumb.png",
#'     title = "Thumbnail",
#'     type = "image/png",
#'     roles = c("thumbnail")
#'   )
#'
#' # Item with time range (datetime is NULL)
#' item <- stac_item(
#'   id = "composite-2023-q2",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-180, -90), c(180, -90), c(180, 90), c(-180, 90), c(-180, -90)
#'     ))
#'   ),
#'   bbox = c(-180, -90, 180, 90),
#'   datetime = NULL,
#'   start_datetime = "2023-04-01T00:00:00Z",
#'   end_datetime = "2023-06-30T23:59:59Z",
#'   properties = list(
#'     title = "Q2 2023 Global Composite"
#'   )
#' )
#'
#' # Item with 3D bbox (including elevation)
#' item <- stac_item(
#'   id = "lidar-001",
#'   geometry = list(
#'     type = "Point",
#'     coordinates = c(-105.0, 40.0, 1500)
#'   ),
#'   bbox = c(-105.0, 40.0, 1500, -105.0, 40.0, 1500),
#'   datetime = "2023-06-15T14:00:00Z"
#' )
#'
#' # Non-spatial item (geometry and bbox are NULL)
#' item <- stac_item(
#'   id = "global-report-2023",
#'   geometry = NULL,
#'   bbox = NULL,
#'   datetime = "2023-12-31T23:59:59Z",
#'   properties = list(
#'     title = "Annual Global Climate Report"
#'   )
#' )
#'
#' # Convert to JSON
#' item_json <- jsonlite::toJSON(item, auto_unbox = TRUE, pretty = TRUE)
#' cat(item_json)
#'
#' @export
stac_item <- S7::new_class(
  "stac_item",
  properties = list(
    type = S7::new_property(S7::class_character, default = "Feature"),
    stac_version = S7::new_property(S7::class_character, default = "1.1.0"),
    id = S7::class_character,
    geometry = S7::new_property(
      S7::new_union(S7::class_list, NULL),
      default = NULL
    ),
    bbox = S7::new_property(
      S7::new_union(S7::class_numeric, NULL),
      default = NULL
    ),
    properties = S7::new_property(S7::class_list, default = list()),
    links = S7::new_property(S7::class_list, default = list()),
    assets = S7::new_property(S7::class_list, default = list()),
    stac_extensions = S7::new_property(
      S7::new_union(S7::class_character, NULL),
      default = NULL
    ),
    collection = S7::new_property(
      S7::new_union(S7::class_character, NULL),
      default = NULL
    )
  ),
  constructor = function(
    id,
    geometry,
    bbox = NULL,
    datetime = NULL,
    properties = list(),
    assets = list(),
    links = list(),
    stac_version = "1.1.0",
    type = "Feature",
    stac_extensions = NULL,
    collection = NULL,
    start_datetime = NULL,
    end_datetime = NULL,
    ...
  ) {
    # Resolve datetime: start/end takes precedence if both provided
    if (
      !is.null(datetime) && (!is.null(start_datetime) || !is.null(end_datetime))
    ) {
      warning(
        "Both 'datetime' and 'start_datetime'/'end_datetime' provided. ",
        "Using 'start_datetime' and 'end_datetime'."
      )
      datetime <- NULL
    }

    # Merge datetime into properties
    props <- properties
    if (!is.null(datetime)) {
      props$datetime <- datetime
    } else {
      props$datetime <- NULL
      props$start_datetime <- start_datetime
      props$end_datetime <- end_datetime
    }

    # Merge ... into properties (not top-level, unlike catalog/collection)
    extra_props <- list(...)
    if (length(extra_props) > 0) {
      props <- c(props, extra_props)
    }

    obj <- S7::new_object(
      S7::S7_object(),
      type = type,
      stac_version = stac_version,
      id = id,
      geometry = geometry,
      bbox = bbox,
      properties = props,
      links = links,
      assets = assets,
      stac_extensions = stac_extensions,
      collection = collection
    )
    structure(obj, class = append(class(obj), "stac_item", after = 1L))
  },
  validator = function(self) {
    if (length(self@id) == 0 || nchar(self@id) == 0) {
      return("'id' must be a non-empty string")
    }
    if (self@type != "Feature") {
      return("'type' must be 'Feature'")
    }
    if (!is.null(self@geometry) && is.null(self@bbox)) {
      return("'bbox' is required when 'geometry' is not NULL")
    }
    if (is.null(self@geometry) && !is.null(self@bbox)) {
      return("'bbox' is prohibited when 'geometry' is NULL")
    }
    if (!is.null(self@bbox) && !length(self@bbox) %in% c(4, 6)) {
      return("'bbox' must have length 4 (2D) or 6 (3D)")
    }
    has_datetime <- !is.null(self@properties$datetime)
    has_start <- !is.null(self@properties$start_datetime)
    has_end <- !is.null(self@properties$end_datetime)
    if (!has_datetime && !(has_start && has_end)) {
      return(
        "'properties' must contain 'datetime' or both 'start_datetime' and 'end_datetime'"
      )
    }
    NULL
  }
)

S7::method(as.list, stac_item) <- function(x, ...) {
  out <- list(
    type = x@type,
    stac_version = x@stac_version,
    id = x@id,
    geometry = x@geometry,
    properties = x@properties,
    links = x@links,
    assets = x@assets
  )
  if (!is.null(x@bbox)) {
    out$bbox <- x@bbox
  }
  if (!is.null(x@stac_extensions) && length(x@stac_extensions) > 0) {
    out$stac_extensions <- as.list(x@stac_extensions)
  }
  if (!is.null(x@collection)) {
    out$collection <- x@collection
  }
  out
}
