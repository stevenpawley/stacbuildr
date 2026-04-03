skip_if_no_pystac <- function() {
  if (!reticulate::py_module_available("pystac"))
    skip("pystac not available for testing")
}
