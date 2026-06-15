# Helper operator for NULL coalescing
`%||%` <- function(a, b) {
  if (is.null(a))
    b
  else
    a
}
