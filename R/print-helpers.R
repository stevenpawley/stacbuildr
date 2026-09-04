# Internal helpers shared by the print methods for catalogs, collections and
# items.
#
# Colour and box-drawing characters come from cli, which degrades gracefully:
# the `cli::col_*()` / `cli::style_*()` functions return their input unchanged
# when the console has no ANSI support (log files, `R CMD check`, knitr), and
# `stac_sym()` falls back to ASCII when the output is not UTF-8. The plain-text
# layout is therefore identical with and without styling.

# Layout -----------------------------------------------------------------

# Width of the label column. Scalar fields are indented by two spaces and
# sections by an arrow plus a space, so both put the ":" in the same column.
stac_label_width <- 12L

stac_pad <- function(label, width = stac_label_width) {
  formatC(label, width = width, flag = "-")
}

# Symbols ----------------------------------------------------------------

stac_sym <- function(name) {
  utf8 <- cli::is_utf8_output()
  syms <- if (utf8) {
    c(
      collapsed = "\u25b8",
      expanded  = "\u25be",
      branch    = "\u251c\u2500",
      last      = "\u2514\u2500",
      info      = cli::symbol$info,
      ellipsis  = "\u2026"
    )
  } else {
    c(
      collapsed = ">",
      expanded  = "v",
      branch    = "|-",
      last      = "`-",
      info      = "i",
      ellipsis  = "..."
    )
  }
  unname(syms[[name]])
}

# Styles -----------------------------------------------------------------

stac_style_type  <- function(x) cli::style_bold(cli::col_cyan(x))
stac_style_id    <- function(x) cli::style_bold(cli::col_green(x))
stac_style_label <- function(x) cli::col_silver(x)
stac_style_count <- function(x) cli::col_yellow(x)
stac_style_key   <- function(x) cli::col_magenta(x)
stac_style_url   <- function(x) cli::col_blue(x)
stac_style_muted <- function(x) cli::col_silver(x)
stac_style_arrow <- function(x) cli::col_blue(x)
stac_style_value <- function(x) x

# Value formatting -------------------------------------------------------

# Space left on the line for a value that starts at column `indent`. cli
# reports the console width, falling back to the `width` option when the
# output is not a terminal.
stac_avail <- function(indent) {
  max(20L, cli::console_width() - as.integer(indent))
}

stac_truncate <- function(x, width = stac_avail(17L)) {
  x <- paste(x, collapse = " ")
  if (nchar(x) <= width) {
    return(x)
  }
  # The ellipsis is one character in UTF-8 but three ("...") in ASCII.
  ellipsis <- stac_sym("ellipsis")
  paste0(substr(x, 1, max(0L, width - nchar(ellipsis))), ellipsis)
}

# Compact one-line rendering of an arbitrary field value (used for item
# properties and collection summaries, which can hold anything).
stac_fmt_value <- function(x, width = stac_avail(20L)) {
  if (is.null(x)) {
    return("NULL")
  }
  if (is.list(x)) {
    if (!is.null(names(x))) {
      return(stac_truncate(
        sprintf("{%s}", paste(names(x), collapse = ", ")), width
      ))
    }
    if (all(vapply(x, function(el) is.atomic(el) && length(el) == 1L, logical(1)))) {
      return(stac_truncate(
        sprintf("[%s]", paste(unlist(x), collapse = ", ")), width
      ))
    }
    # Extension fields are usually arrays of objects (eo:bands,
    # classification:classes, table:columns, ...). Label them by the name of
    # each object where there is one, and by a count otherwise.
    labels <- stac_object_labels(x)
    if (!is.null(labels)) {
      return(stac_truncate(sprintf("[%s]", paste(labels, collapse = ", ")), width))
    }
    return(sprintf(
      "<%d %s>", length(x), if (length(x) == 1L) "item" else "items"
    ))
  }
  if (length(x) > 1L) {
    return(stac_truncate(sprintf("[%s]", paste(x, collapse = ", ")), width))
  }
  stac_truncate(as.character(x), width)
}

# Label each element of an array of objects, e.g. the band names in
# `eo:bands` or the class names in `classification:classes`. Returns NULL when
# the elements carry no obvious label.
stac_object_labels <- function(x) {
  for (field in c("name", "common_name", "value", "data_type")) {
    labels <- lapply(x, function(el) {
      if (is.list(el) || (!is.null(names(el)))) el[[field]] else NULL
    })
    if (all(vapply(labels, function(l) length(l) == 1L && is.atomic(l), logical(1)))) {
      return(as.character(unlist(labels)))
    }
  }
  NULL
}

# Expansion --------------------------------------------------------------

#' Should a print section be expanded?
#'
#' @param expand `NULL` (fall back to the `stacbuildr.print.expand` option),
#'   `TRUE` / `FALSE`, or a character vector of section names.
#' @param section Name of the section being printed.
#' @noRd
stac_expanded <- function(expand, section) {
  if (is.null(expand)) {
    expand <- getOption("stacbuildr.print.expand", FALSE)
  }
  if (is.logical(expand)) {
    return(isTRUE(expand[[1]]))
  }
  if (is.character(expand)) {
    return("all" %in% expand || section %in% expand)
  }
  FALSE
}

# Printing primitives ----------------------------------------------------

stac_print_header <- function(type) {
  cat(stac_style_type(sprintf("<STAC %s>", type)), "\n", sep = "")
}

# A plain "label : value" line, with the value trimmed to fit the console.
stac_print_field <- function(label, value, style = stac_style_value) {
  cat(sprintf(
    "  %s : %s\n",
    stac_style_label(stac_pad(label)),
    style(stac_truncate(value, stac_avail(17L)))
  ))
}

#' Print one collapsible section
#'
#' Prints a header line prefixed with an arrow, then either a short inline
#' summary (collapsed) or one indented line per element (expanded).
#'
#' @param label Section name, also the key used by `expand`.
#' @param n Number of elements in the section.
#' @param summary Short single-line preview shown when collapsed.
#' @param lines Character vector of detail lines shown when expanded, or a
#'   function returning one (only called when the section is expanded).
#' @param expanded Whether to show `lines`.
#' @return Invisibly, `TRUE` if a non-empty section was left collapsed.
#' @noRd
stac_print_section <- function(label,
                               n,
                               summary = NULL,
                               lines = NULL,
                               expanded = FALSE) {
  expanded <- expanded && n > 0L
  arrow <- if (n == 0L) {
    " "
  } else if (expanded) {
    stac_style_arrow(stac_sym("expanded"))
  } else {
    stac_style_arrow(stac_sym("collapsed"))
  }

  cat(sprintf(
    "  %s %s : %s%s\n",
    arrow,
    stac_style_label(stac_pad(label, stac_label_width - 2L)),
    stac_style_count(n),
    if (!expanded && !is.null(summary) && n > 0L) {
      paste0(" ", stac_style_muted(summary))
    } else {
      ""
    }
  ))

  if (expanded) {
    if (is.function(lines)) {
      lines <- lines()
    }
    stac_print_branches(lines)
  }

  invisible(!expanded && n > 0L)
}

# Indented tree branches under an expanded section. Each element of `lines` is
# one entry; an entry may itself be a character vector, in which case the extra
# elements are printed as continuation lines under the branch.
stac_print_branches <- function(lines) {
  n <- length(lines)
  if (n == 0L) {
    return(invisible(NULL))
  }
  vert <- if (cli::is_utf8_output()) "\u2502 " else "| "
  for (i in seq_len(n)) {
    last <- i == n
    tip <- if (last) stac_sym("last") else stac_sym("branch")
    entry <- lines[[i]]
    cat(sprintf("      %s %s\n", stac_style_muted(tip), entry[[1]]))
    if (length(entry) > 1L) {
      cont <- stac_style_muted(if (last) "  " else vert)
      for (extra in entry[-1]) {
        cat(sprintf("      %s   %s\n", cont, extra))
      }
    }
  }
  invisible(NULL)
}

# Footer telling the user how to open the collapsed sections.
stac_print_hint <- function(n_collapsed) {
  if (n_collapsed == 0L || !isTRUE(getOption("stacbuildr.print.hint", TRUE))) {
    return(invisible(NULL))
  }
  cat(stac_style_muted(sprintf(
    "  %s %d collapsed section%s - use print(x, expand = TRUE) to show\n",
    stac_sym("info"),
    n_collapsed,
    if (n_collapsed == 1L) "" else "s"
  )))
  invisible(NULL)
}

# Section content --------------------------------------------------------

# One entry line: a styled label followed by muted detail, truncated to fit
# the console. Truncation happens before styling so ANSI codes stay intact.
stac_entry <- function(label,
                       label_width,
                       detail = "",
                       style = stac_style_key,
                       indent = 9L) {
  line <- style(stac_pad(label, label_width))
  if (nzchar(detail)) {
    line <- paste0(line, " ", stac_style_muted(
      stac_truncate(detail, stac_avail(indent + label_width + 1L))
    ))
  }
  line
}

# Named list of assets -> one entry per asset, each spanning two lines (the
# key with its media type and roles, then the href).
stac_asset_lines <- function(assets) {
  key_width <- max(nchar(names(assets)), 0L)
  unname(lapply(names(assets), function(key) {
    asset <- assets[[key]]
    roles <- unlist(asset$roles)
    detail <- paste(c(
      asset$type,
      if (length(roles) > 0) sprintf("[%s]", paste(roles, collapse = ", "))
    ), collapse = " ")
    c(
      stac_entry(key, key_width, detail),
      stac_style_url(stac_truncate(asset$href %||% "", stac_avail(11L))),
      # Extension fields attached to the asset (eo:bands, raster:bands,
      # classification:classes, table:storage_options, ...)
      stac_field_lines(
        asset[!names(asset) %in% stac_asset_core_fields],
        indent = 11L
      )
    )
  }))
}

# Asset fields defined by the STAC core spec; anything else is an extension.
stac_asset_core_fields <- c("href", "title", "description", "type", "roles")

stac_link_lines <- function(links) {
  vapply(links, function(link) {
    paste0(
      stac_style_key(stac_pad(link$rel %||% "", 10L)),
      " ",
      stac_style_url(stac_truncate(link$href %||% "", stac_avail(20L)))
    )
  }, character(1), USE.NAMES = FALSE)
}

# Short name of an extension, e.g. "eo" for
# "https://stac-extensions.github.io/eo/v1.1.0/schema.json".
stac_extension_names <- function(extensions) {
  vapply(extensions, function(ext) {
    parts <- strsplit(sub("^https?://", "", ext), "/", fixed = TRUE)[[1]]
    parts <- parts[nzchar(parts)]
    if (length(parts) >= 2L) parts[[2]] else ext
  }, character(1), USE.NAMES = FALSE)
}

# Version of an extension, e.g. "v1.1.0" for
# "https://stac-extensions.github.io/eo/v1.1.0/schema.json".
stac_extension_versions <- function(extensions) {
  vapply(extensions, function(ext) {
    parts <- strsplit(sub("^https?://", "", ext), "/", fixed = TRUE)[[1]]
    parts <- parts[nzchar(parts)]
    if (length(parts) >= 3L && grepl("^v?[0-9]", parts[[3]])) parts[[3]] else ""
  }, character(1), USE.NAMES = FALSE)
}

stac_extension_lines <- function(extensions) {
  names_ <- stac_extension_names(extensions)
  versions <- stac_extension_versions(extensions)
  name_width <- max(nchar(names_), 0L)
  vapply(seq_along(extensions), function(i) {
    # Fall back to the full URI for anything that does not follow the
    # stac-extensions.github.io layout.
    if (!nzchar(versions[[i]])) {
      return(stac_style_url(stac_truncate(extensions[[i]], stac_avail(9L))))
    }
    stac_entry(names_[[i]], name_width, versions[[i]])
  }, character(1), USE.NAMES = FALSE)
}

stac_child_lines <- function(children) {
  id_width <- max(nchar(names(children)), 0L)
  vapply(names(children), function(id) {
    child <- children[[id]]
    stac_entry(
      id,
      id_width,
      paste(c(child@type, child@title), collapse = " "),
      style = stac_style_id
    )
  }, character(1), USE.NAMES = FALSE)
}

stac_item_lines <- function(items) {
  id_width <- max(nchar(vapply(items, function(i) i@id, character(1))), 0L)
  vapply(items, function(item) {
    dt <- item@properties$datetime %||% item@properties$start_datetime
    stac_entry(item@id, id_width, dt %||% "", style = stac_style_id)
  }, character(1), USE.NAMES = FALSE)
}

# Named list of arbitrary fields (item properties, collection summaries).
stac_field_lines <- function(x, width = 10L, indent = 9L) {
  key_width <- max(width, nchar(names(x)))
  value_width <- stac_avail(indent + key_width + 1L)
  vapply(names(x), function(key) {
    paste0(
      stac_style_key(stac_pad(key, key_width)),
      " ",
      stac_fmt_value(x[[key]], value_width)
    )
  }, character(1), USE.NAMES = FALSE)
}

stac_provider_lines <- function(providers) {
  names_ <- vapply(providers, function(p) p$name %||% "<unnamed>", character(1))
  name_width <- max(nchar(names_), 0L)
  vapply(providers, function(p) {
    roles <- unlist(p$roles)
    stac_entry(
      p$name %||% "<unnamed>",
      name_width,
      if (length(roles) > 0) sprintf("[%s]", paste(roles, collapse = ", ")) else ""
    )
  }, character(1), USE.NAMES = FALSE)
}

# Short inline previews shown when a section is collapsed.
stac_preview <- function(x, width = NULL) {
  if (length(x) == 0L) {
    return(NULL)
  }
  # The preview follows "  <arrow> <label> : <count> " on the header line.
  width <- width %||% stac_avail(19L + nchar(as.character(length(x))))
  stac_truncate(sprintf("[%s]", paste(x, collapse = ", ")), width)
}
