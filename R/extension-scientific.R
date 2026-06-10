#' Add Scientific Citation Extension to a STAC Item
#'
#' @description
#' Adds the Scientific Citation Extension to a STAC Item. This extension
#' provides fields to indicate from which publication data originates and how
#' the data itself should be cited or referenced, helping to increase
#' reproducibility and citability.
#'
#' Three fields are available, at least one of which must be supplied:
#'
#' * **`sci:doi`**: The DOI of the dataset itself (e.g. `"10.1000/xyz123"`).
#' * **`sci:citation`**: A recommended human-readable citation string for the
#'   dataset.
#' * **`sci:publications`**: A list of related publications created with
#'   [scientific_publication()].
#'
#' When a DOI is provided, a `cite-as` link pointing to the DOI URL is
#' automatically appended to the item's links list (per RFC 8574).
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param doi (character, optional) The DOI of the data, e.g.
#'   `"10.1000/xyz123"`. This must **not** be a full DOI URL — provide only the
#'   DOI name. A corresponding `cite-as` link will be added automatically.
#' @param citation (character, optional) The recommended human-readable
#'   reference (citation) to be used by publications citing the data. No
#'   specific citation style is required, but the citation should contain
#'   enough information to uniquely identify the publication.
#' @param publications (list, optional) A list of [scientific_publication()]
#'   objects describing related publications that reference or describe the
#'   data.
#'
#' @details
#' ## Extension Schema URI
#' `https://stac-extensions.github.io/scientific/v1.0.0/schema.json`
#'
#' ## DOI Format
#' DOIs should be supplied as bare names such as `"10.1000/xyz123"`, not as
#' full links (`https://doi.org/10.1000/xyz123`). A `cite-as` link with the
#' full DOI URL is added to the item links automatically when `doi` is
#' provided.
#'
#' ## Placement
#' The scientific fields are placed in the item `properties`. Because citation
#' information is often shared across all items in a collection, the STAC
#' specification recommends adding these fields at the Collection level where
#' possible.
#'
#' @return The modified STAC Item with Scientific Citation extension fields
#'   added.
#'
#' @seealso
#' * [scientific_publication()] for creating publication objects
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' Scientific Citation Extension Specification:
#' \url{https://github.com/stac-extensions/scientific}
#'
#' @examples
#' item <- stac_item(
#'   id = "my-dataset",
#'   geometry = list(
#'     type = "Polygon",
#'     coordinates = list(list(
#'       c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
#'       c(-105.5, 40.5), c(-105.5, 39.5)
#'     ))
#'   ),
#'   bbox = c(-105.5, 39.5, -104.5, 40.5),
#'   datetime = "2023-01-01T00:00:00Z"
#' )
#'
#' # Add citation with DOI and a related publication
#' item <- item |>
#'   add_scientific_extension(
#'     doi = "10.1000/xyz123",
#'     citation = "Smith, J. (2023). My Dataset. Example Repository.",
#'     publications = list(
#'       scientific_publication(
#'         doi = "10.1000/abc456",
#'         citation = "Smith, J. (2022). Methods paper. Journal of Examples."
#'       )
#'     )
#'   )
#'
#' @export
add_scientific_extension <- function(
  item,
  doi = NULL,
  citation = NULL,
  publications = NULL
) {
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }

  if (is.null(doi) && is.null(citation) && is.null(publications)) {
    stop("At least one of 'doi', 'citation', or 'publications' must be provided")
  }

  if (!is.null(doi)) {
    if (!is.character(doi) || length(doi) != 1) {
      stop("'doi' must be a single character string")
    }
    if (grepl("^https?://", doi)) {
      stop("'doi' must be a DOI name (e.g. '10.1000/xyz123'), not a URL")
    }
  }

  if (!is.null(citation)) {
    if (!is.character(citation) || length(citation) != 1) {
      stop("'citation' must be a single character string")
    }
  }

  if (!is.null(publications)) {
    if (!is.list(publications) || length(publications) == 0) {
      stop("'publications' must be a non-empty list of scientific_publication objects")
    }
    not_pub <- !vapply(publications, inherits, logical(1), "scientific_publication")
    if (any(not_pub)) {
      stop("All elements of 'publications' must be scientific_publication objects")
    }
  }

  ext_uri <- "https://stac-extensions.github.io/scientific/v1.0.0/schema.json"

  if (is.null(item@stac_extensions)) {
    item@stac_extensions <- character(0)
  }

  if (!ext_uri %in% item@stac_extensions) {
    item@stac_extensions <- c(item@stac_extensions, ext_uri)
  }

  if (!is.null(doi)) {
    item@properties$`sci:doi` <- doi

    # Add cite-as link per RFC 8574
    doi_link <- list(
      rel  = "cite-as",
      href = paste0("https://doi.org/", doi)
    )
    if (is.null(item@links)) {
      item@links <- list()
    }
    # Only add if the link is not already present
    existing_hrefs <- vapply(item@links, function(l) l$href %||% "", character(1))
    if (!doi_link$href %in% existing_hrefs) {
      item@links <- c(item@links, list(doi_link))
    }
  }

  if (!is.null(citation)) {
    item@properties$`sci:citation` <- citation
  }

  if (!is.null(publications)) {
    item@properties$`sci:publications` <- publications
  }

  item
}


#' Create a Scientific Publication Object
#'
#' @description
#' Creates a publication object for use with the Scientific Citation Extension.
#' Each object represents a scholarly publication that references or describes
#' the dataset, identified by a DOI and/or a human-readable citation string.
#'
#' @param doi (character, optional) The DOI of the publication, e.g.
#'   `"10.1000/abc456"`. This must **not** be a full DOI URL. At least one of
#'   `doi` or `citation` must be provided.
#' @param citation (character, optional) Human-readable citation of the
#'   publication. No specific style is required, but it should contain enough
#'   information to uniquely identify the publication. At least one of `doi` or
#'   `citation` must be provided.
#'
#' @return A named list of class `"scientific_publication"`.
#'
#' @examples
#' # Publication with both DOI and citation
#' pub <- scientific_publication(
#'   doi = "10.1000/abc456",
#'   citation = "Smith, J. (2022). Methods for dataset X. Journal of Examples, 1(1)."
#' )
#'
#' # Publication with only a citation (no DOI)
#' pub <- scientific_publication(
#'   citation = "Jones, A. (2020). Background study. Conference Proceedings."
#' )
#'
#' @export
scientific_publication <- function(doi = NULL, citation = NULL) {
  if (is.null(doi) && is.null(citation)) {
    stop("At least one of 'doi' or 'citation' must be provided")
  }

  if (!is.null(doi)) {
    if (!is.character(doi) || length(doi) != 1) {
      stop("'doi' must be a single character string")
    }
    if (grepl("^https?://", doi)) {
      stop("'doi' must be a DOI name (e.g. '10.1000/abc456'), not a URL")
    }
  }

  if (!is.null(citation)) {
    if (!is.character(citation) || length(citation) != 1) {
      stop("'citation' must be a single character string")
    }
  }

  pub <- list()
  if (!is.null(doi))      pub$doi      <- doi
  if (!is.null(citation)) pub$citation <- citation

  class(pub) <- c("scientific_publication", "list")
  pub
}


#' Print method for scientific_publication objects
#'
#' @param x A scientific_publication object.
#' @param ... Additional arguments (ignored).
#'
#' @export
print.scientific_publication <- function(x, ...) {
  cat("Scientific Publication:\n")
  if (!is.null(x$doi))      cat("  DOI:     ", x$doi, "\n", sep = "")
  if (!is.null(x$citation)) cat("  Citation:", x$citation, "\n")
  invisible(x)
}
