test_that("single-character checks distinguish scalars from vectors", {
  expect_invisible(check_single_character("value", "x"))
  expect_invisible(check_single_character(NULL, "x", allow_null = TRUE))
  expect_invisible(
    check_single_character("", "x", allow_empty = TRUE)
  )

  expect_error(
    check_single_character(c("a", "b"), "x"),
    "single character value"
  )
  expect_error(
    check_single_character(NA_character_, "x"),
    "must not be missing"
  )
  expect_error(check_single_character("", "x"), "non-empty string")
  expect_error(check_single_character(NULL, "x"), "single character value")
})


test_that("character-vector checks handle NULL, empty vectors, and missingness", {
  expect_invisible(check_character_vector(c("a", "b"), "x"))
  expect_invisible(check_character_vector(character(), "x"))
  expect_invisible(check_character_vector(NULL, "x", allow_null = TRUE))

  expect_error(check_character_vector(1:2, "x"), "character vector")
  expect_error(check_character_vector(c("a", NA_character_), "x"), "missing")
  expect_error(
    check_character_vector(character(), "x", allow_empty = FALSE),
    "at least one value"
  )
})


test_that("flag checks require one non-missing logical value", {
  expect_invisible(check_flag(TRUE, "x"))
  expect_invisible(check_flag(NULL, "x", allow_null = TRUE))

  expect_error(check_flag(c(TRUE, FALSE), "x"), "TRUE or FALSE")
  expect_error(check_flag(NA, "x"), "TRUE or FALSE")
  expect_error(check_flag(1, "x"), "TRUE or FALSE")
})


test_that("core constructors use the common checks", {
  expect_error(
    stac_catalog(c("a", "b"), "description"),
    "single character value"
  )
  expect_error(
    stac_item(
      id = c("a", "b"),
      geometry = NULL,
      datetime = "2024-01-01T00:00:00Z"
    ),
    "single character value"
  )
  expect_error(
    stac_asset("asset.tif", title = c("a", "b")),
    "single character value"
  )
  expect_error(
    stac_link("self", "catalog.json", merge = c(TRUE, FALSE)),
    "TRUE or FALSE"
  )
})
