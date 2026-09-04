# S3 classes with a hand-written print method. These are registered again in
# .onLoad(); see the comment there for why the NAMESPACE directives are not
# enough on their own.
s3_print_classes <- c(
  "classification_bitfield",
  "classification_class",
  "cube_dimension",
  "cube_variable",
  "eo_band",
  "render_object",
  "scientific_publication",
  "table_column"
)

.onLoad <- function(libname, pkgname) {
  S7::methods_register()

  # Assigning an S7 method to an S3 generic ("method(print, cls) <- fn") is a
  # replacement call, so R rewrites it as an assignment to `print` and leaves
  # a binding of that name in this namespace. base:::registerS3methods() then
  # treats `print` as a package-local generic and files the NAMESPACE's
  # S3method(print, *) directives in stacbuildr's own S3 methods table instead
  # of base's, where UseMethod() cannot find them. Registering them again here
  # puts them in base's table so print() dispatches for outside callers.
  ns <- asNamespace(pkgname)
  for (cls in s3_print_classes) {
    registerS3method("print", cls, get(paste0("print.", cls), envir = ns))
  }
}
