# In tests/testthat/helper.R
skip_if_no_pystac <- function() {
  skip_if_not_installed("reticulate")
  
  if (!reticulate::virtualenv_exists("pystac")) {
    skip("pystac virtualenv not available")
  }
  
  reticulate::use_virtualenv("pystac")
  
  if (!reticulate::py_module_available("pystac")) {
    skip("pystac module not available in virtualenv")
  }
}

# Then in your tests:
skip_if_no_pystac()