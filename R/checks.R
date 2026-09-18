# Common argument checks ---------------------------------------------------

# These helpers keep constructor validation consistent and, in particular,
# distinguish a single character value from a character vector. They return
# their input invisibly so callers can use them either as statements or inline.

check_single_character <- function(
  x,
  arg,
  allow_null = FALSE,
  allow_na = FALSE,
  allow_empty = FALSE
) {
  if (is.null(x) && allow_null) {
    return(invisible(x))
  }

  if (!is.character(x) || length(x) != 1L) {
    cli::cli_abort(
      "{.arg {arg}} must be {if (allow_null) 'NULL or ' else ''}a single character value."
    )
  }
  if (!allow_na && is.na(x)) {
    cli::cli_abort("{.arg {arg}} must not be missing.")
  }
  if (!allow_empty && !is.na(x) && !nzchar(x)) {
    cli::cli_abort("{.arg {arg}} must be a single non-empty string.")
  }

  invisible(x)
}


check_character_vector <- function(
  x,
  arg,
  allow_null = FALSE,
  allow_na = FALSE,
  allow_empty = TRUE
) {
  if (is.null(x) && allow_null) {
    return(invisible(x))
  }

  if (!is.character(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be {if (allow_null) 'NULL or ' else ''}a character vector."
    )
  }
  if (!allow_empty && length(x) == 0L) {
    cli::cli_abort("{.arg {arg}} must contain at least one value.")
  }
  if (!allow_na && anyNA(x)) {
    cli::cli_abort("{.arg {arg}} must not contain missing values.")
  }

  invisible(x)
}


check_flag <- function(x, arg, allow_null = FALSE) {
  if (is.null(x) && allow_null) {
    return(invisible(x))
  }

  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be {if (allow_null) 'NULL or ' else ''}TRUE or FALSE."
    )
  }

  invisible(x)
}


check_named_list <- function(
  x,
  arg,
  allow_null = FALSE,
  allow_empty = TRUE
) {
  if (is.null(x) && allow_null) {
    return(invisible(x))
  }

  if (!is.list(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be {if (allow_null) 'NULL or ' else ''}a named list."
    )
  }
  if (length(x) == 0L) {
    if (!allow_empty) {
      cli::cli_abort("{.arg {arg}} must contain at least one named element.")
    }
    return(invisible(x))
  }

  element_names <- names(x)
  if (
    is.null(element_names) ||
      length(element_names) != length(x) ||
      anyNA(element_names) ||
      any(!nzchar(element_names))
  ) {
    cli::cli_abort(
      "{.arg {arg}} must have a non-empty name for every element."
    )
  }

  duplicated_names <- unique(element_names[duplicated(element_names)])
  if (length(duplicated_names) > 0L) {
    cli::cli_abort(c(
      "{.arg {arg}} must have unique names.",
      x = "Duplicated {?name/names}: {.val {duplicated_names}}."
    ))
  }

  invisible(x)
}
