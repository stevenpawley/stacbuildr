# --- scientific_publication() ---

test_that("scientific_publication creates an object with both doi and citation", {
  pub <- scientific_publication(
    doi      = "10.1000/abc456",
    citation = "Smith, J. (2022). My Paper. Journal of Examples."
  )

  expect_equal(pub$doi, "10.1000/abc456")
  expect_equal(pub$citation, "Smith, J. (2022). My Paper. Journal of Examples.")
  expect_s3_class(pub, "scientific_publication")
})

test_that("scientific_publication creates an object with only doi", {
  pub <- scientific_publication(doi = "10.1000/abc456")

  expect_equal(pub$doi, "10.1000/abc456")
  expect_null(pub$citation)
  expect_s3_class(pub, "scientific_publication")
})

test_that("scientific_publication creates an object with only citation", {
  pub <- scientific_publication(citation = "Jones, A. (2020). Background Study.")

  expect_equal(pub$citation, "Jones, A. (2020). Background Study.")
  expect_null(pub$doi)
  expect_s3_class(pub, "scientific_publication")
})

test_that("scientific_publication errors when neither doi nor citation is provided", {
  expect_error(
    scientific_publication(),
    "At least one of 'doi' or 'citation'"
  )
})

test_that("scientific_publication errors when doi is a URL", {
  expect_error(
    scientific_publication(doi = "https://doi.org/10.1000/abc456"),
    "not a URL"
  )
  expect_error(
    scientific_publication(doi = "http://doi.org/10.1000/abc456"),
    "not a URL"
  )
})

test_that("scientific_publication errors when doi is not a single string", {
  expect_error(
    scientific_publication(doi = c("10.1000/a", "10.1000/b")),
    "single character string"
  )
  expect_error(
    scientific_publication(doi = 123),
    "single character string"
  )
})

test_that("scientific_publication errors when citation is not a single string", {
  expect_error(
    scientific_publication(citation = c("a", "b")),
    "single character string"
  )
})


# --- add_scientific_extension() ---

make_item <- function() {
  stac_item(
    id       = "test-scientific",
    geometry = list(type = "Point", coordinates = c(-105, 40)),
    bbox     = c(-105, 40, -105, 40),
    datetime = "2023-06-15T00:00:00Z"
  )
}

test_that("add_scientific_extension errors on non-item input", {
  expect_error(
    add_scientific_extension("not_an_item", doi = "10.1000/xyz"),
    "'item' must be a stac_item"
  )
})

test_that("add_scientific_extension errors when all fields are NULL", {
  expect_error(
    add_scientific_extension(make_item()),
    "At least one of 'doi', 'citation', or 'publications'"
  )
})

test_that("add_scientific_extension errors when doi is a URL", {
  expect_error(
    add_scientific_extension(make_item(), doi = "https://doi.org/10.1000/xyz"),
    "not a URL"
  )
})

test_that("add_scientific_extension errors when doi is not a single string", {
  expect_error(
    add_scientific_extension(make_item(), doi = c("10.1000/a", "10.1000/b")),
    "single character string"
  )
})

test_that("add_scientific_extension errors when citation is not a single string", {
  expect_error(
    add_scientific_extension(make_item(), citation = c("a", "b")),
    "single character string"
  )
})

test_that("add_scientific_extension errors when publications is an empty list", {
  expect_error(
    add_scientific_extension(make_item(), publications = list()),
    "non-empty list"
  )
})

test_that("add_scientific_extension errors when publications contains non-publication objects", {
  expect_error(
    add_scientific_extension(make_item(), publications = list("not a pub")),
    "scientific_publication objects"
  )
})

test_that("add_scientific_extension adds schema URI to stac_extensions", {
  item <- add_scientific_extension(make_item(), doi = "10.1000/xyz123")

  expect_true(
    "https://stac-extensions.github.io/scientific/v1.0.0/schema.json"
    %in% item@stac_extensions
  )
})

test_that("add_scientific_extension does not duplicate schema URI", {
  item <- make_item() |>
    add_scientific_extension(doi = "10.1000/xyz123") |>
    add_scientific_extension(citation = "Smith (2023).")

  n_sci_uris <- sum(grepl("scientific", item@stac_extensions))
  expect_equal(n_sci_uris, 1L)
})

test_that("add_scientific_extension writes sci:doi to item properties", {
  item <- add_scientific_extension(make_item(), doi = "10.1000/xyz123")

  expect_equal(item@properties$`sci:doi`, "10.1000/xyz123")
})

test_that("add_scientific_extension writes sci:citation to item properties", {
  item <- add_scientific_extension(
    make_item(),
    citation = "Smith, J. (2023). My Dataset."
  )

  expect_equal(item@properties$`sci:citation`, "Smith, J. (2023). My Dataset.")
})

test_that("add_scientific_extension writes sci:publications to item properties", {
  pubs <- list(
    scientific_publication(doi = "10.1000/a", citation = "Pub A."),
    scientific_publication(citation = "Pub B.")
  )
  item <- add_scientific_extension(make_item(), publications = pubs)

  expect_length(item@properties$`sci:publications`, 2)
  expect_equal(item@properties$`sci:publications`[[1]]$doi, "10.1000/a")
  expect_equal(item@properties$`sci:publications`[[2]]$citation, "Pub B.")
})

test_that("add_scientific_extension appends a cite-as link when doi is provided", {
  item <- add_scientific_extension(make_item(), doi = "10.1000/xyz123")

  link_rels <- vapply(item@links, `[[`, character(1), "rel")
  expect_true("cite-as" %in% link_rels)
})

test_that("add_scientific_extension cite-as link has the correct DOI URL", {
  item <- add_scientific_extension(make_item(), doi = "10.1000/xyz123")

  cite_as_links <- Filter(function(l) l$rel == "cite-as", item@links)
  expect_length(cite_as_links, 1)
  expect_equal(cite_as_links[[1]]$href, "https://doi.org/10.1000/xyz123")
})

test_that("add_scientific_extension does not duplicate cite-as link on repeated calls", {
  item <- make_item() |>
    add_scientific_extension(doi = "10.1000/xyz123") |>
    add_scientific_extension(doi = "10.1000/xyz123")

  cite_as_count <- sum(vapply(item@links, function(l) l$rel == "cite-as", logical(1)))
  expect_equal(cite_as_count, 1L)
})

test_that("add_scientific_extension does not add cite-as link when no doi is given", {
  item <- add_scientific_extension(make_item(), citation = "Smith (2023).")

  link_rels <- vapply(item@links, `[[`, character(1), "rel")
  expect_false("cite-as" %in% link_rels)
})

test_that("add_scientific_extension can set all three fields at once", {
  pubs <- list(scientific_publication(doi = "10.1000/ref"))
  item <- add_scientific_extension(
    make_item(),
    doi          = "10.1000/xyz123",
    citation     = "Smith (2023). Dataset.",
    publications = pubs
  )

  expect_equal(item@properties$`sci:doi`, "10.1000/xyz123")
  expect_equal(item@properties$`sci:citation`, "Smith (2023). Dataset.")
  expect_length(item@properties$`sci:publications`, 1)

  cite_as_links <- Filter(function(l) l$rel == "cite-as", item@links)
  expect_length(cite_as_links, 1)
})
