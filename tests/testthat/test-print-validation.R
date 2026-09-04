mk_result <- function(errors = character(), warnings = character(), valid = NULL) {
  structure(
    list(
      valid = valid %||% (length(errors) == 0),
      errors = errors,
      warnings = warnings
    ),
    class = c("stac_validation", "list")
  )
}

test_that("validators return a classed result that still behaves as a list", {
  item <- stac_item(
    id = "i",
    geometry = list(type = "Point", coordinates = c(0, 0)),
    bbox = c(0, 0, 0, 0),
    datetime = "2023-01-01T00:00:00Z"
  )
  res <- validate_stac(item)

  expect_s3_class(res, "stac_validation")
  expect_true(is.list(res))
  expect_named(res, c("valid", "errors", "warnings"))
  expect_true(res$valid)
  expect_type(res$errors, "character")
  expect_type(res$warnings, "character")

  # the non-STAC branch is classed too
  expect_s3_class(validate_stac(list(a = 1)), "stac_validation")
})

test_that("a valid result prints a tick", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(mk_result()))

  expect_identical(out[[1]], "<STAC Validation>")
  expect_true(any(grepl("v valid", out, fixed = TRUE)))
})

test_that("errors print as a numbered list", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(mk_result(errors = c("first problem", "second problem"))))

  expect_true(any(grepl("x 2 errors", out, fixed = TRUE)))
  expect_true(any(grepl("1. first problem", out, fixed = TRUE)))
  expect_true(any(grepl("2. second problem", out, fixed = TRUE)))
  expect_false(any(grepl("valid", out, fixed = TRUE)))
})

test_that("the issue count is singular for one issue", {
  local_reproducible_output(unicode = FALSE)
  out <- capture.output(print(mk_result(errors = "only problem")))

  expect_true(any(grepl("x 1 error", out, fixed = TRUE)))
  expect_false(any(grepl("1 errors", out, fixed = TRUE)))
})

test_that("warnings are reported whether or not the object is valid", {
  local_reproducible_output(unicode = FALSE)

  out <- capture.output(print(mk_result(warnings = "a caution")))
  expect_true(any(grepl("v valid", out, fixed = TRUE)))
  expect_true(any(grepl("i 1 warning", out, fixed = TRUE)))
  expect_true(any(grepl("1. a caution", out, fixed = TRUE)))

  out <- capture.output(print(mk_result(errors = "a problem", warnings = "a caution")))
  expect_true(any(grepl("x 1 error", out, fixed = TRUE)))
  expect_true(any(grepl("i 1 warning", out, fixed = TRUE)))
})

test_that("long issues are truncated to the console width", {
  local_reproducible_output(unicode = FALSE)
  withr::local_options(cli.width = 60)

  out <- capture.output(print(mk_result(errors = strrep("problem ", 40))))
  expect_true(all(nchar(out) <= 60))
})

test_that("print returns the result invisibly", {
  local_reproducible_output(unicode = FALSE)
  expect_output(res <- withVisible(print(mk_result())))
  expect_false(res$visible)
})
