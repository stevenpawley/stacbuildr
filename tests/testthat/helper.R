skip_if_no_pystac <- function() {
  skip_if_not_installed("reticulate")

  venv_path <- file.path(
    tryCatch(rprojroot::find_root(rprojroot::is_r_package), error = function(e) "."),
    ".venv"
  )
  if (!dir.exists(venv_path)) {
    skip("pystac virtualenv not found at .venv")
  }

  reticulate::use_virtualenv(venv_path, required = FALSE)

  if (!reticulate::py_module_available("pystac")) {
    skip("pystac module not available in .venv")
  }
}
