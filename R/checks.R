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
