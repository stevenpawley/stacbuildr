stocked_catalog <- function(n = 3, type = c("catalog", "collection")) {
  type <- match.arg(type)
  cat_obj <- if (type == "catalog") {
    stac_catalog(id = "c", description = "Example")
  } else {
    stac_collection(
      id = "c",
      description = "Example",
      license = "CC-BY-4.0",
      extent = stac_extent(
        spatial_bbox = list(c(-1, -1, 1, 1)),
        temporal_interval = list(list("2024-01-01T00:00:00Z", NULL))
      )
    )
  }
  for (i in seq_len(n)) {
    cat_obj <- add_item(cat_obj, stac_item(
      id = sprintf("item%d", i),
      geometry = list(type = "Point", coordinates = c(0, 0)),
      bbox = c(0, 0, 0, 0),
      datetime = "2024-01-01T00:00:00Z"
    ))
  }
  cat_obj
}

stored_ids <- function(x) {
  vapply(get_items(x) %||% list(), function(it) it@id, character(1))
}

test_that("remove_item drops the item by id", {
  out <- remove_item(stocked_catalog(3), item_id = "item2")

  expect_equal(count_items(out), 2L)
  expect_equal(stored_ids(out), c("item1", "item3"))
})

test_that("remove_item drops several ids at once", {
  out <- remove_item(stocked_catalog(3), item_id = c("item1", "item3"))

  expect_equal(count_items(out), 1L)
  expect_equal(stored_ids(out), "item2")
})

test_that("remove_item drops by href", {
  coll <- stocked_catalog(3)
  href <- Filter(function(l) l$rel == "item", coll@links)[[2]]$href

  out <- remove_item(coll, href = href)
  expect_equal(count_items(out), 2L)
  expect_equal(stored_ids(out), c("item1", "item3"))
})

test_that("remove_item with all = TRUE clears every item", {
  out <- remove_item(stocked_catalog(3), all = TRUE)

  expect_equal(count_items(out), 0L)
  expect_length(get_items(out), 0L)
})

test_that("remove_item keeps non-item links", {
  coll <- add_root_link(stocked_catalog(2), "https://example.com/catalog.json")
  out <- remove_item(coll, all = TRUE)

  rels <- vapply(out@links, function(l) l$rel, character(1))
  expect_true("root" %in% rels)
  expect_false("item" %in% rels)
})

test_that("remove_item leaves an unmatched id alone", {
  out <- remove_item(stocked_catalog(3), item_id = "not-here")

  expect_equal(count_items(out), 3L)
  expect_length(stored_ids(out), 3L)
})

test_that("remove_item keeps links and stored items in step", {
  # A removed item that stayed in the "stac_items" attribute would be written
  # back out by write_stac(), which rebuilds item links from it.
  out <- remove_item(stocked_catalog(3), item_id = "item2")

  expect_equal(length(out), count_items(out))
  expect_equal(length(out), length(get_items(out)))
  expect_equal(nrow(as.data.frame(out)), 2L)
  expect_error(out[["item2"]], "No item with id")
})

test_that("a removed item is not written to disk", {
  out <- remove_item(stocked_catalog(3), item_id = "item2")
  dir <- withr::local_tempdir()
  suppressMessages(write_stac(out, dir))

  written <- basename(list.files(dir, recursive = TRUE))
  expect_setequal(written, c("catalog.json", "item1.json", "item3.json"))

  links <- jsonlite::fromJSON(
    file.path(dir, "catalog.json"),
    simplifyVector = FALSE
  )$links
  item_links <- Filter(function(l) l$rel == "item", links)
  expect_length(item_links, 2L)
})

test_that("remove_item works on a Collection as well as a Catalog", {
  out <- remove_item(stocked_catalog(3, "collection"), item_id = "item2")

  expect_equal(count_items(out), 2L)
  expect_equal(stored_ids(out), c("item1", "item3"))
})

test_that("remove_item requires something to remove", {
  expect_error(remove_item(stocked_catalog(1)), "Must specify")
})

test_that("remove_item rejects a non-catalog", {
  expect_error(remove_item(list(id = "x"), all = TRUE), "must be a stac_catalog")
})

test_that("remove_item on an empty catalog is a no-op", {
  empty <- stac_catalog(id = "c", description = "Example")

  expect_equal(count_items(remove_item(empty, all = TRUE)), 0L)
  expect_equal(count_items(remove_item(empty, item_id = "nope")), 0L)
})
