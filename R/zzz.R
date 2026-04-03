pystac <- NULL

.onLoad <- function(libname, pkgname) {
  S7::methods_register()

  # S7 classes in packages have qualified names (e.g. "buildstac::stac_catalog").
  # S3 dispatch for $ constructs the method name from the class string, so
  # $.stac_catalog is never found for class "buildstac::stac_catalog".
  # Explicitly register $ and $<- for the qualified class names.
  ns <- asNamespace(pkgname)

  for (cls in c("stac_catalog", "stac_item")) {
    qualified <- paste0(pkgname, "::", cls)
    registerS3method(
      "$",
      qualified,
      get(paste0("$.", cls), envir = ns),
      envir = ns
    )
    registerS3method(
      "$<-",
      qualified,
      get(paste0("$<-.", cls), envir = ns),
      envir = ns
    )
  }


  pystac <<- reticulate::import("pystac", delay_load = TRUE)
}
