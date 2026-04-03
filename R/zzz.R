pystac <- NULL

.onLoad <- function(libname, pkgname) {
  S7::methods_register()

  pystac <<- reticulate::import("pystac", delay_load = TRUE)
}
