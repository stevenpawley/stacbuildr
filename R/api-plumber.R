# Plumber-based STAC API router.
# Creates an OGC API – Features / STAC API 1.0 compliant plumber router backed
# by the PostgreSQL database set up with stac_db_setup().

#' Create a plumber router serving a minimal STAC API
#'
#' Returns a [plumber::Plumber] router pre-wired with the following endpoints:
#'
#' | Method | Path | Description |
#' |--------|------|-------------|
#' | GET | `/` | Landing page (root catalog) |
#' | GET | `/conformance` | Conformance classes |
#' | GET | `/collections` | List all collections |
#' | GET | `/collections/{collectionId}` | Single collection |
#' | GET | `/collections/{collectionId}/items` | Items in a collection |
#' | GET | `/collections/{collectionId}/items/{itemId}` | Single item |
#' | GET | `/search` | Search items (GET form) |
#' | POST | `/search` | Search items (POST / JSON body) |
#'
#' **Search parameters** (GET query string or POST JSON body):
#' * `bbox` — comma-separated `west,south,east,north` (GET) or array (POST)
#' * `datetime` — ISO 8601 value or range `start/end`; use `..` for open end
#' * `collections` — collection ID(s) to filter
#' * `ids` — item ID(s) to filter
#' * `limit` — max results per page (default 10, max 10 000)
#' * `offset` — zero-based page offset (default 0)
#' * `properties` — (POST only) JSON object for property equality matching,
#'   supporting any item property including extension fields such as
#'   `"eo:cloud_cover"`, `"sci:doi"`, `"classification:classes"`, etc.
#'
#' @param con A DBI connection.
#' @param base_url Base URL of the API (no trailing slash). Used in link hrefs.
#' @param title Human-readable API title.
#' @param description API description.
#' @param sign_assets Logical. When `TRUE`, asset hrefs in every item response
#'   are automatically signed with a short-lived SAS token before being
#'   returned. Requires `AzureStor` and the `AZURE_STORAGE_ENDPOINT` and
#'   `AZURE_STORAGE_CONTAINER` environment variables to be set. Default
#'   `FALSE`.
#' @return A [plumber::Plumber] router object.
#' @export
stac_api_router <- function(
  con,
  base_url = "http://localhost:8000",
  title = "STAC API",
  description = "A minimal STAC API served by stacbuildr",
  sign_assets = FALSE
) {
  # Check that optional package is installed
  if (!requireNamespace("plumber", quietly = TRUE)) {
    stop(
      "Package 'plumber' is required. Install with: install.packages('plumber')"
    )
  }

  # Custom serializer (how results are returned back to the client)
  # JSON is default but for STAC API compliance we are altering the
  # defaults to unwrap single element R vectors and provide explicit
  # nulls
  pr <- plumber::pr() |>
    plumber::pr_set_serializer(
      plumber::serializer_json(auto_unbox = TRUE, null = "null", na = "null")
    )

  # CORS — must be first so OPTIONS pre-flight bypasses auth
  # Only needed if the API is accessed from other JS web pages
  # Not needed if accessed from R/Python scripts
  pr <- plumber::pr_filter(pr, "cors", function(req, res) {
    res$setHeader("Access-Control-Allow-Origin", "*")
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    res$setHeader(
      "Access-Control-Allow-Headers",
      "Content-Type, Accept, Authorization"
    )
    if (identical(req$REQUEST_METHOD, "OPTIONS")) {
      res$status <- 200L
      return(list())
    }
    plumber::forward()
  })

  # Inject standard STAC navigation links and optionally sign asset hrefs
  prepare_item <- function(item) {
    item <- .inject_item_links(item, base_url)
    if (sign_assets) item <- .sign_item_assets(item)
    item
  }

  # STAC API spec requires the following `rel` types:
  # - self and root: required by OGC API Features on every response
  # - conformance: required by OGC API Features so clients can find /conformance
  # - data: required by OGC API Features to point to /collections
  # - search (×2): required by the STAC API Item Search spec, one per supported method

  # GET /
    pr <- plumber::pr_get(pr, "/", function(req, res) {
      list(
        type = "Catalog",
        stac_version = "1.1.0",
        id = "stac-api",
        title = title,
        description = description,
        conformsTo = .stac_conformance_uris(),
        links = list(
          .link("self", base_url, "application/json"),
          .link("root", base_url, "application/json"),
          .link("conformance", paste0(base_url, "/conformance"), "application/json"),
          .link("data", paste0(base_url, "/collections"), "application/json"),
          .link("search", paste0(base_url, "/search"), "application/geo+json", method = "GET"),
          .link("search", paste0(base_url, "/search"), "application/geo+json", method = "POST")
        )
      )
    })

  # GET /conformance
  pr <- plumber::pr_get(pr, "/conformance", function(req, res) {
    list(conformsTo = .stac_conformance_uris())
  })

  # GET /collections
  pr <- plumber::pr_get(pr, "/collections", function(req, res) {
    collections <- .db_get_all_collections(con)
    collections <- lapply(collections, function(col) {
      cid <- col$id
      col$links <- .merge_links(
        col$links,
        list(
          .link("self", paste0(base_url, "/collections/", cid), "application/json"),
          .link("root", base_url, "application/json"),
          .link("items", paste0(base_url, "/collections/", cid, "/items"), "application/geo+json")
        )
      )
      col
    })
    list(
      collections = collections,
      links = list(
        .link("self", paste0(base_url, "/collections"), "application/json"),
        .link("root", base_url, "application/json")
      )
    )
  })

  # GET /collections/{collectionId}
  pr <- plumber::pr_get(
    pr,
    "/collections/<collectionId>",
    function(req, res, collectionId) {
      col <- .db_get_collection(con, collectionId)
      if (is.null(col)) {
        return(.not_found(res, "Collection not found"))
      }
      col$links <- .merge_links(
        col$links,
        list(
          .link(
            "self",
            paste0(base_url, "/collections/", collectionId),
            "application/json"
          ),
          .link("root", base_url, "application/json"),
          .link(
            "items",
            paste0(base_url, "/collections/", collectionId, "/items"),
            "application/geo+json"
          )
        )
      )
      col
    }
  )

  # GET /collections/{collectionId}/items
  pr <- plumber::pr_get(
    pr,
    "/collections/<collectionId>/items",
    function(
      req,
      res,
      collectionId,
      bbox = "",
      datetime = "",
      limit = 10L,
      offset = 0L
    ) {
      if (is.null(.db_get_collection(con, collectionId))) {
        return(.not_found(res, "Collection not found"))
      }

      limit <- min(as.integer(limit), 10000L)
      offset <- max(as.integer(offset), 0L)
      bbox <- if (nzchar(bbox)) bbox else NULL
      datetime <- if (nzchar(datetime)) datetime else NULL

      bbox_parsed <- tryCatch(.parse_bbox_param(bbox), error = function(e) {
        res$status <- 400L
        stop(e$message)
      })
      dt <- .parse_datetime_param(datetime)

      result <- .db_search_items(
        con,
        bbox = bbox_parsed,
        dt_start = dt$start,
        dt_end = dt$end,
        single_dt = dt$single_dt,
        collections = collectionId,
        limit = limit,
        offset = offset
      )

      .feature_collection(
        features = lapply(result$items, prepare_item),
        matched = result$matched,
        returned = length(result$items),
        links = .pagination_links(
          base_url = paste0(base_url, "/collections/", collectionId, "/items"),
          offset = offset,
          limit = limit,
          matched = result$matched,
          extra_query = .query_string(bbox = bbox, datetime = datetime)
        )
      )
    }
  )

  # GET /collections/{collectionId}/items/{itemId}
  pr <- plumber::pr_get(
    pr,
    "/collections/<collectionId>/items/<itemId>",
    function(req, res, collectionId, itemId) {
      item <- .db_get_item(con, collectionId, itemId)
      if (is.null(item)) {
        return(.not_found(res, "Item not found"))
      }
      prepare_item(item)
    }
  )

  # GET /search
  pr <- plumber::pr_get(
    pr,
    "/search",
    function(
      req,
      res,
      bbox = "",
      datetime = "",
      collections = "",
      ids = "",
      limit = 10L,
      offset = 0L
    ) {
      limit <- min(as.integer(limit), 10000L)
      offset <- max(as.integer(offset), 0L)
      bbox <- if (nzchar(bbox)) bbox else NULL
      datetime <- if (nzchar(datetime)) datetime else NULL

      collections <- .split_param(collections)
      ids <- .split_param(ids)

      bbox_parsed <- tryCatch(.parse_bbox_param(bbox), error = function(e) {
        res$status <- 400L
        stop(e$message)
      })
      dt <- .parse_datetime_param(datetime)

      result <- .db_search_items(
        con,
        bbox = bbox_parsed,
        dt_start = dt$start,
        dt_end = dt$end,
        single_dt = dt$single_dt,
        collections = collections,
        ids = ids,
        limit = limit,
        offset = offset
      )

      .feature_collection(
        features = lapply(result$items, prepare_item),
        matched = result$matched,
        returned = length(result$items),
        links = .pagination_links(
          base_url = paste0(base_url, "/search"),
          offset = offset,
          limit = limit,
          matched = result$matched,
          extra_query = .query_string(
            bbox = bbox,
            datetime = datetime,
            collections = if (!is.null(collections)) {
              paste(collections, collapse = ",")
            } else {
              NULL
            },
            ids = if (!is.null(ids)) paste(ids, collapse = ",") else NULL
          )
        )
      )
    }
  )

  # POST /search
  pr <- plumber::pr_post(
    pr,
    "/search",
    function(req, res) {
      body <- req$body %||% list()

      bbox_raw <- body$bbox
      bbox_parsed <- if (!is.null(bbox_raw)) {
        b <- tryCatch(as.numeric(unlist(bbox_raw)), error = function(e) {
          res$status <- 400L
          stop("'bbox' must be a JSON array of four numbers")
        })
        if (length(b) != 4L) {
          res$status <- 400L
          return(.error_body(400L, "'bbox' must have exactly four elements"))
        }
        b
      } else {
        NULL
      }

      datetime <- body$datetime %||% NULL
      collections <- .as_char_vec(body$collections)
      ids <- .as_char_vec(body$ids)
      limit <- min(as.integer(body$limit %||% 10L), 10000L)
      offset <- max(as.integer(body$offset %||% 0L), 0L)
      properties <- body$properties %||% NULL

      dt <- .parse_datetime_param(datetime)

      result <- .db_search_items(
        con,
        bbox = bbox_parsed,
        dt_start = dt$start,
        dt_end = dt$end,
        single_dt = dt$single_dt,
        collections = collections,
        ids = ids,
        properties = properties,
        limit = limit,
        offset = offset
      )

      .feature_collection(
        features = lapply(result$items, prepare_item),
        matched = result$matched,
        returned = length(result$items),
        links = .pagination_links(
          base_url = paste0(base_url, "/search"),
          offset = offset,
          limit = limit,
          matched = result$matched
        )
      )
    },
    parsers = "json"
  )

  # ---- GET /sign ----
  pr <- plumber::pr_get(pr, "/sign", function(req, res, href = "") {
    if (!nzchar(href)) {
      res$status <- 400L
      return(.error_body(400L, "Missing required query parameter: href"))
    }
    signed <- tryCatch(
      .sign_azure_href(href),
      error = function(e) {
        res$status <- 500L
        .error_body(500L, conditionMessage(e))
      }
    )
    if (is.list(signed)) return(signed)   # error body already set
    list(href = signed)
  })

  pr
}

#' Sign all asset hrefs in a STAC Item list.
#'
#' Applies [.sign_azure_href()] to every asset href. Unsigned hrefs that do
#' not belong to the configured Azure container (e.g. external URLs) are left
#' unchanged. Signing failures emit a warning and leave the href unchanged
#' rather than failing the whole request.
#'
#' @param item A STAC Item as a plain list (as returned from the database).
#' @return The item with signed asset hrefs.
#' @noRd
.sign_item_assets <- function(item) {
  if (is.null(item$assets) || length(item$assets) == 0) return(item)
  item$assets <- lapply(item$assets, function(a) {
    if (!is.null(a$href)) {
      a$href <- tryCatch(
        .sign_azure_href(a$href),
        error = function(e) {
          warning("Asset signing failed for '", a$href, "': ", conditionMessage(e))
          a$href
        }
      )
    }
    a
  })
  item
}

#' Sign an Azure Blob Storage href with a short-lived user delegation SAS token.
#'
#' Reads the storage endpoint and container from environment variables so that
#' nothing is hardcoded. Obtains a managed identity token at call time and uses
#' it to generate a user delegation SAS — no storage account key is required.
#'
#' Required environment variables:
#' * `AZURE_STORAGE_ENDPOINT` — full blob service URL, e.g.
#'   `"https://myaccount.blob.core.windows.net/"`.
#' * `AZURE_STORAGE_CONTAINER` — container name, e.g. `"stac"`.
#'
#' @param href Unsigned Azure Blob Storage URL.
#' @param expiry_seconds Lifetime of the signed URL in seconds (default 3600).
#' @return A signed URL string with a SAS token appended.
#' @noRd
.sign_azure_href <- function(href, expiry_seconds = 3600L) {
  if (!requireNamespace("AzureStor", quietly = TRUE)) {
    stop("Package 'AzureStor' is required for asset signing.")
  }

  endpoint  <- Sys.getenv("AZURE_STORAGE_ENDPOINT", "")
  container <- Sys.getenv("AZURE_STORAGE_CONTAINER", "")

  if (!nzchar(endpoint)) {
    stop("AZURE_STORAGE_ENDPOINT environment variable is not set.")
  }
  if (!nzchar(container)) {
    stop("AZURE_STORAGE_CONTAINER environment variable is not set.")
  }

  # Strip endpoint + container prefix to get the blob path
  prefix <- paste0(sub("/+$", "", endpoint), "/", container, "/")
  if (!startsWith(href, prefix)) {
    stop(sprintf("href does not belong to container '%s': %s", container, href))
  }
  blob_path <- substring(href, nchar(prefix) + 1L)

  expiry_time <- Sys.time() + expiry_seconds

  token <- AzureStor::get_managed_token("https://storage.azure.com/")
  endp  <- AzureStor::storage_endpoint(endpoint, token = token)

  # User delegation key is scoped to the SAS lifetime
  userkey <- AzureStor::get_user_delegation_key(endp, expiry = expiry_time)

  AzureStor::get_user_delegation_sas(
    account       = endp,
    key           = userkey,
    resource      = blob_path,
    expiry        = expiry_time,
    permissions   = "r",
    resource_type = "b"
  )
}

#' STAC API conformance class URIs.
#'
#' Returns the list of OGC and STAC conformance class URIs declared by this
#' API. These are included in the landing page (`conformsTo`) and the
#' `/conformance` endpoint so that clients can discover which capabilities
#' (core, item search, OGC Features, GeoJSON) are supported.
#'
#' @return A character list of conformance class URI strings.
#' @noRd
.stac_conformance_uris <- function() {
  list(
    "https://api.stacspec.org/v1.0.0/core",
    "https://api.stacspec.org/v1.0.0/item-search",
    "https://api.stacspec.org/v1.0.0/item-search#fields",
    "https://api.stacspec.org/v1.0.0/ogcapi-features",
    "http://www.opengis.net/spec/ogcapi-features-1/1.0/conf/core",
    "http://www.opengis.net/spec/ogcapi-features-1/1.0/conf/oas30",
    "http://www.opengis.net/spec/ogcapi-features-1/1.0/conf/geojson"
  )
}

#' Build a STAC link object.
#'
#' A STAC link object expresses a typed relationship between the current
#' resource and another URL. Every STAC object (Catalog, Collection, Item)
#' carries a `links` array of these objects, allowing clients to navigate the
#' API by following link relations rather than constructing URLs themselves
#' (HATEOAS). Common `rel` values include `"self"`, `"root"`, `"parent"`,
#' `"collection"`, `"items"`, and `"search"`.
#'
#' @param rel Link relation type (e.g. `"self"`, `"root"`, `"items"`).
#' @param href Target URL.
#' @param type Optional media type of the linked resource (e.g.
#'   `"application/json"`, `"application/geo+json"`).
#' @param method Optional HTTP method (e.g. `"GET"`, `"POST"`); used to
#'   distinguish multiple links with the same `rel` but different methods.
#' @return A named list representing a single STAC link object.
#' @noRd
.link <- function(rel, href, type = NULL, method = NULL) {
  lnk <- list(rel = rel, href = href)
  if (!is.null(type)) {
    lnk$type <- type
  }
  if (!is.null(method)) {
    lnk$method <- method
  }
  lnk
}

#' Merge two lists of STAC link objects, avoiding duplicates.
#'
#' Appends links from `new_links` to `existing`, skipping any link whose
#' `rel` and `href` combination already appears in `existing`. This preserves
#' links stored on an item or collection in the database while injecting
#' standard navigation links without creating duplicates.
#'
#' @param existing A list of existing link objects, or `NULL`.
#' @param new_links A list of link objects to append.
#' @return A combined list of link objects with no duplicate `rel`/`href` pairs.
#' @noRd
.merge_links <- function(existing, new_links) {
  existing <- existing %||% list()
  keys <- vapply(existing, function(l) paste0(l$rel, "|", l$href), character(1))
  for (lnk in new_links) {
    key <- paste0(lnk$rel, "|", lnk$href)
    if (!key %in% keys) {
      existing <- c(existing, list(lnk))
      keys <- c(keys, key)
    }
  }
  existing
}

#' Build a STAC GeoJSON FeatureCollection response.
#'
#' Wraps a list of STAC Item feature objects into a GeoJSON FeatureCollection
#' with pagination metadata. `numberMatched` is the total number of items
#' satisfying the query (before pagination); `numberReturned` is the count in
#' this page. The `context` field repeats these counts for compatibility with
#' the STAC API Context extension.
#'
#' @param features A list of GeoJSON Feature objects (STAC Items).
#' @param matched Total number of items matching the query.
#' @param returned Number of items in this response page.
#' @param links A list of STAC link objects for pagination (`self`, `next`,
#'   `prev`).
#' @return A named list representing a GeoJSON FeatureCollection.
#' @noRd
.feature_collection <- function(features, matched, returned, links = list()) {
  list(
    type = "FeatureCollection",
    features = features,
    numberMatched = matched,
    numberReturned = returned,
    context = list(returned = returned, matched = matched),
    links = links
  )
}

#' Build pagination links for a STAC search or items response.
#'
#' Constructs the `self`, `next`, and `prev` link objects used in a
#' FeatureCollection response. `next` is omitted when the current page reaches
#' the end of results (`offset + limit >= matched`); `prev` is omitted on the
#' first page (`offset == 0`).
#'
#' @param base_url Base URL of the endpoint (no query string).
#' @param offset Zero-based index of the first item on the current page.
#' @param limit Maximum number of items per page.
#' @param matched Total number of items matching the query.
#' @param extra_query Optional pre-encoded query string fragment (without
#'   leading `?` or `&`) for additional filter parameters such as `bbox` or
#'   `datetime`.
#' @return A list of STAC link objects.
#' @noRd
.pagination_links <- function(
  base_url,
  offset,
  limit,
  matched,
  extra_query = ""
) {
  sep <- if (nzchar(extra_query)) "&" else "?"
  links <- list(
    .link(
      "self",
      paste0(base_url, "?limit=", limit, "&offset=", offset, sep, extra_query),
      "application/geo+json"
    )
  )
  if (offset + limit < matched) {
    links <- c(
      links,
      list(.link(
        "next",
        paste0(
          base_url,
          "?limit=",
          limit,
          "&offset=",
          offset + limit,
          sep,
          extra_query
        ),
        "application/geo+json"
      ))
    )
  }
  if (offset > 0L) {
    links <- c(
      links,
      list(.link(
        "prev",
        paste0(
          base_url,
          "?limit=",
          limit,
          "&offset=",
          max(0L, offset - limit),
          sep,
          extra_query
        ),
        "application/geo+json"
      ))
    )
  }
  links
}

#' Inject standard navigation links into a STAC Item.
#'
#' Adds `self`, `root`, `collection`, and `parent` links to an item using
#' `.merge_links()` so that any links already stored on the item are preserved.
#'
#' @param item A STAC Item list (must have `$id` and `$collection` fields).
#' @param base_url Base URL of the API (no trailing slash).
#' @return The item with navigation links added to `$links`.
#' @noRd
.inject_item_links <- function(item, base_url) {
  cid <- item$collection
  iid <- item$id
  item$links <- .merge_links(
    item$links,
    list(
      .link(
        "self",
        paste0(base_url, "/collections/", cid, "/items/", iid),
        "application/geo+json"
      ),
      .link("root", base_url, "application/json"),
      .link(
        "collection",
        paste0(base_url, "/collections/", cid),
        "application/json"
      ),
      .link(
        "parent",
        paste0(base_url, "/collections/", cid),
        "application/json"
      )
    )
  )
  item
}

#' Set a 404 response and return an error body.
#'
#' @param res A plumber response object.
#' @param msg Human-readable description of what was not found.
#' @return A named list error body.
#' @noRd
.not_found <- function(res, msg) {
  res$status <- 404L
  .error_body(404L, msg)
}

#' Build a standard API error response body.
#'
#' @param code Integer HTTP status code.
#' @param description Human-readable error message.
#' @return A named list with `code` and `description` fields.
#' @noRd
.error_body <- function(code, description) {
  list(code = code, description = description)
}

#' Build a URL query string from named arguments.
#'
#' Encodes non-NULL, non-empty named arguments as a `key=value` query string
#' fragment (without a leading `?`). Values are percent-encoded via
#' [utils::URLencode()].
#'
#' @param ... Named character values. `NULL` and zero-length strings are
#'   silently dropped.
#' @return A single string of the form `"key1=val1&key2=val2"`, or `""`
#'   if all arguments are dropped.
#' @noRd
.query_string <- function(...) {
  args <- Filter(function(v) !is.null(v) && nzchar(v), list(...))
  if (length(args) == 0) {
    return("")
  }
  paste(
    mapply(
      function(k, v) {
        paste0(k, "=", utils::URLencode(as.character(v), reserved = TRUE))
      },
      names(args),
      args
    ),
    collapse = "&"
  )
}

#' Split a comma-separated query parameter into a character vector.
#'
#' Handles the two forms a repeated parameter can arrive in from Plumber:
#' a single comma-separated string (GET query string) or a character vector
#' of length > 1 (repeated keys). Returns `NULL` for absent or empty values.
#'
#' @param x A character scalar or vector, or `NULL`.
#' @return A character vector, or `NULL` if the input is absent or blank.
#' @noRd
.split_param <- function(x) {
  if (is.null(x) || (length(x) == 1 && !nzchar(x))) {
    return(NULL)
  }
  if (length(x) > 1) {
    return(as.character(x))
  }
  unlist(strsplit(x, ",", fixed = TRUE))
}

#' Coerce a JSON array field to a character vector.
#'
#' When a JSON array is parsed from a POST body it arrives as a list.
#' This function flattens and coerces it to a character vector, returning
#' `NULL` for absent or empty inputs.
#'
#' @param x A list, character vector, or `NULL`.
#' @return A character vector, or `NULL` if the result would be empty.
#' @noRd
.as_char_vec <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  v <- as.character(unlist(x))
  if (length(v) == 0) NULL else v
}
