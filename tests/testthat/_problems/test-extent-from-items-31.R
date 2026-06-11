# Extracted from test-extent-from-items.R:31

# prequel ----------------------------------------------------------------------
make_item <- function(id, bbox, datetime = NULL, start_datetime = NULL, end_datetime = NULL) {
  stac_item(
    id = id,
    geometry = list(
      type = "Polygon",
      coordinates = list(list(
        c(bbox[1], bbox[2]),
        c(bbox[3], bbox[2]),
        c(bbox[3], bbox[4]),
        c(bbox[1], bbox[4]),
        c(bbox[1], bbox[2])
      ))
    ),
    bbox = bbox,
    datetime = datetime,
    start_datetime = start_datetime,
    end_datetime = end_datetime
  )
}

# test -------------------------------------------------------------------------
item <- make_item("a", c(-10, -10, 10, 10), datetime = "null")
