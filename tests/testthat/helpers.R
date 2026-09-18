skip_if_no_pystac <- function() {
  testthat::skip_if_not_installed("reticulate")

  # Do not let an optional interoperability test create a managed Python
  # environment. Honour explicit reticulate configuration when one is present.
  if (
    !nzchar(Sys.getenv("RETICULATE_PYTHON")) &&
      !nzchar(Sys.getenv("RETICULATE_USE_MANAGED_VENV"))
  ) {
    withr::local_envvar(RETICULATE_USE_MANAGED_VENV = "false")
  }

  available <- tryCatch(
    suppressWarnings(reticulate::py_module_available("pystac")),
    error = function(e) FALSE
  )
  if (!available) {
    testthat::skip("PySTAC not available for testing")
  }
}
