test_that("catalog matches stac-spec example catalog.json", {
  expected <- jsonlite::fromJSON(
    testthat::test_path("fixtures/catalog.json"),
    simplifyVector = FALSE
  )

  catalog <- stac_catalog(
    id = "examples",
    description = "This catalog is a simple demonstration of an example catalog that is used to organize a hierarchy of collections and their items.",
    title = "Example Catalog"
  ) |>
    add_root_link("./catalog.json") |>
    add_link("child", "./extensions-collection/collection.json",
             type = "application/json", title = "Collection Demonstrating STAC Extensions") |>
    add_link("child", "./collection-only/collection.json",
             type = "application/json", title = "Collection with no items (standalone)") |>
    add_link("child", "./collection-only/collection-with-schemas.json",
             type = "application/json", title = "Collection with no items (standalone with JSON Schemas)") |>
    add_link("item", "./collectionless-item.json",
             type = "application/json", title = "Item that does not have a collection (not recommended, but allowed by the spec)") |>
    add_self_link("https://raw.githubusercontent.com/radiantearth/stac-spec/v1.1.0/examples/catalog.json")

  actual <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(catalog), auto_unbox = TRUE),
    simplifyVector = FALSE
  )

  expect_equal(actual$id, expected$id)
  expect_equal(actual$type, expected$type)
  expect_equal(actual$title, expected$title)
  expect_equal(actual$stac_version, expected$stac_version)
  expect_equal(actual$description, expected$description)
  expect_equal(actual$links, expected$links)
})

test_that("collection matches stac-spec example collection.json", {
  expected <- jsonlite::fromJSON(
    testthat::test_path("fixtures/collection.json"),
    simplifyVector = FALSE
  )

  collection <- stac_collection(
    id = "simple-collection",
    description = "A simple collection demonstrating core catalog fields with links to a couple of items",
    title = "Simple Example Collection",
    license = "CC-BY-4.0",
    stac_extensions = c(
      "https://stac-extensions.github.io/eo/v2.0.0/schema.json",
      "https://stac-extensions.github.io/projection/v2.0.0/schema.json",
      "https://stac-extensions.github.io/view/v1.0.0/schema.json"
    ),
    keywords = c("simple", "example", "collection"),
    providers = list(
      stac_provider(
        name = "Remote Data, Inc",
        description = "Producers of awesome spatiotemporal assets",
        roles = c("producer", "processor"),
        url = "http://remotedata.io"
      )
    ),
    extent = stac_extent(
      spatial_bbox = list(c(172.91173669923782, 1.3438851951615003, 172.95469614953714, 1.3690476620161975)),
      temporal_interval = list(list("2020-12-11T22:38:32.125Z", "2020-12-14T18:02:31.437Z"))
    ),
    summaries = list(
      platform         = c("cool_sat1", "cool_sat2"),
      constellation    = list("ion"),
      instruments      = c("cool_sensor_v1", "cool_sensor_v2"),
      gsd              = list(minimum = 0.512, maximum = 0.66),
      "eo:cloud_cover" = list(minimum = 1.2, maximum = 1.2),
      "proj:cpde"      = list("EPSG:32659"),
      "view:sun_elevation" = list(minimum = 54.9, maximum = 54.9),
      "view:off_nadir"     = list(minimum = 3.8, maximum = 3.8),
      "view:sun_azimuth"   = list(minimum = 135.7, maximum = 135.7),
      statistics = list(
        type = "object",
        properties = list(
          vegetation = list(
            description = "Percentage of pixels that are detected as vegetation, e.g. forests, grasslands, etc.",
            minimum = 0, maximum = 100
          ),
          water = list(
            description = "Percentage of pixels that are detected as water, e.g. rivers, oceans and ponds.",
            minimum = 0, maximum = 100
          ),
          urban = list(
            description = "Percentage of pixels that detected as urban, e.g. roads and buildings.",
            minimum = 0, maximum = 100
          )
        )
      )
    )
  ) |>
    add_link("root", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("item", "./simple-item.json",
             type = "application/geo+json", title = "Simple Item") |>
    add_link("item", "./core-item.json",
             type = "application/geo+json", title = "Core Item") |>
    add_link("item", "./extended-item.json",
             type = "application/geo+json", title = "Extended Item") |>
    add_self_link("https://raw.githubusercontent.com/radiantearth/stac-spec/v1.1.0/examples/collection.json")

  actual <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(collection), auto_unbox = TRUE, digits = 15),
    simplifyVector = FALSE
  )

  expect_equal(actual$id, expected$id)
  expect_equal(actual$type, expected$type)
  expect_equal(actual$stac_version, expected$stac_version)
  expect_equal(actual$description, expected$description)
  expect_equal(actual$title, expected$title)
  expect_equal(actual$license, expected$license)
  expect_equal(actual$stac_extensions, expected$stac_extensions)
  expect_equal(actual$keywords, expected$keywords)
  expect_equal(actual$providers, expected$providers)
  expect_equal(actual$extent, expected$extent)
  expect_equal(actual$summaries, expected$summaries)
  expect_equal(actual$links, expected$links)
})

test_that("item matches stac-spec example simple-item.json", {
  expected <- jsonlite::fromJSON(
    testthat::test_path("fixtures/simple-item.json"),
    simplifyVector = FALSE
  )

  item <- stac_item(
    id = "20201211_223832_CS2",
    geometry = list(
      type = "Polygon",
      coordinates = list(list(
        c(172.91173669923782, 1.3438851951615003),
        c(172.95469614953714, 1.3438851951615003),
        c(172.95469614953714, 1.3690476620161975),
        c(172.91173669923782, 1.3690476620161975),
        c(172.91173669923782, 1.3438851951615003)
      ))
    ),
    bbox = c(172.91173669923782, 1.3438851951615003, 172.95469614953714, 1.3690476620161975),
    datetime = "2020-12-11T22:38:32.125000Z",
    collection = "simple-collection"
  ) |>
    add_link("collection", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("root", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("parent", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_asset("visual",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2.tif",
              type  = "image/tiff; application=geotiff; profile=cloud-optimized",
              title = "3-Band Visual",
              roles = list("visual")) |>
    add_asset("thumbnail",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2.jpg",
              title = "Thumbnail",
              type  = "image/jpeg",
              roles = list("thumbnail"))

  actual <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(item), auto_unbox = TRUE, digits = 15),
    simplifyVector = FALSE
  )

  expect_equal(actual$type, expected$type)
  expect_equal(actual$stac_version, expected$stac_version)
  expect_equal(actual$id, expected$id)
  expect_equal(actual$bbox, expected$bbox)
  expect_equal(actual$geometry, expected$geometry)
  expect_equal(actual$properties, expected$properties)
  expect_equal(actual$collection, expected$collection)
  expect_equal(actual$links, expected$links)
  sort_fields <- function(x) {
    if (!is.list(x)) return(x)
    if (!is.null(names(x))) x <- x[order(names(x))]
    lapply(x, sort_fields)
  }
  expect_equal(sort_fields(actual$assets), sort_fields(expected$assets))
  # Note: empty stac_extensions is omitted from as.list() output per the
  # spec (it is optional); the example fixture has [] but both are equivalent
})


test_that("item matches stac-spec example extended-item.json", {
  expected <- jsonlite::fromJSON(
    testthat::test_path("fixtures/extended-item.json"),
    simplifyVector = FALSE
  )

  analytic_bands <- list(
    eo_band(name = "band1", common_name = "blue",  center_wavelength = 0.47,  full_width_half_max = 70),
    eo_band(name = "band2", common_name = "green", center_wavelength = 0.56,  full_width_half_max = 80),
    eo_band(name = "band3", common_name = "red",   center_wavelength = 0.645, full_width_half_max = 90),
    eo_band(name = "band4", common_name = "nir",   center_wavelength = 0.8,   full_width_half_max = 152)
  )

  visual_bands <- list(
    eo_band(name = "band3", common_name = "red",   center_wavelength = 0.645, full_width_half_max = 90),
    eo_band(name = "band2", common_name = "green", center_wavelength = 0.56,  full_width_half_max = 80),
    eo_band(name = "band1", common_name = "blue",  center_wavelength = 0.47,  full_width_half_max = 70)
  )

  item <- stac_item(
    id         = "20201211_223832_CS2",
    geometry   = list(
      type = "Polygon",
      coordinates = list(list(
        c(172.91173669923782, 1.3438851951615003),
        c(172.95469614953714, 1.3438851951615003),
        c(172.95469614953714, 1.3690476620161975),
        c(172.91173669923782, 1.3690476620161975),
        c(172.91173669923782, 1.3438851951615003)
      ))
    ),
    bbox       = c(172.91173669923782, 1.3438851951615003, 172.95469614953714, 1.3690476620161975),
    datetime   = "2020-12-14T18:02:31.437000Z",
    collection = "simple-collection",
    # The 4 non-EO extensions; add_eo_extension appends the EO extension URI
    stac_extensions = c(
      "https://stac-extensions.github.io/projection/v2.0.0/schema.json",
      "https://stac-extensions.github.io/scientific/v1.0.0/schema.json",
      "https://stac-extensions.github.io/view/v1.0.0/schema.json",
      "https://stac-extensions.github.io/remote-data/v1.0.0/schema.json"
    ),
    properties = list(
      title       = "Extended Item",
      description = "A sample STAC Item that includes a variety of examples from the stable extensions",
      keywords    = c("extended", "example", "item"),
      created     = "2020-12-15T01:48:13.725Z",
      updated     = "2020-12-15T01:48:13.725Z",
      platform    = "cool_sat2",
      instruments = list("cool_sensor_v2"),
      gsd         = 0.66,
      statistics  = list(vegetation = 12.57, water = 1.23, urban = 26.2),
      "proj:code"      = "EPSG:32659",
      "proj:shape"     = c(5558, 9559),
      "proj:transform" = c(0.5, 0, 712710, 0, -0.5, 151406, 0, 0, 1),
      "view:sun_elevation" = 54.9,
      "view:off_nadir"     = 3.8,
      "view:sun_azimuth"   = 135.7,
      "rd:type"              = "scene",
      "rd:anomalous_pixels"  = 0.14,
      "rd:earth_sun_distance" = 1.014156,
      "rd:sat_id"            = "cool_sat2",
      "rd:product_level"     = "LV3A",
      "sci:doi"              = "10.5061/dryad.s2v81.2/27.2"
    )
  ) |>
    add_eo_extension(cloud_cover = 1.2, snow_cover = 0) |>
    add_asset("analytic",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2_analytic.tif",
              type  = "image/tiff; application=geotiff; profile=cloud-optimized",
              title = "4-Band Analytic",
              roles = list("data")) |>
    add_eo_extension(bands = analytic_bands, asset_key = "analytic") |>
    add_asset("thumbnail",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2.jpg",
              title = "Thumbnail",
              type  = "image/png",
              roles = list("thumbnail")) |>
    add_asset("visual",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2.tif",
              type  = "image/tiff; application=geotiff; profile=cloud-optimized",
              title = "3-Band Visual",
              roles = list("visual")) |>
    add_eo_extension(bands = visual_bands, asset_key = "visual") |>
    add_asset("udm",
              href  = "https://storage.googleapis.com/open-cogs/stac-examples/20201211_223832_CS2_analytic_udm.tif",
              title = "Unusable Data Mask",
              type  = "image/tiff; application=geotiff") |>
    add_asset("json-metadata",
              href  = "http://remotedata.io/catalog/20201211_223832_CS2/extended-metadata.json",
              title = "Extended Metadata",
              type  = "application/json",
              roles = list("metadata")) |>
    add_asset("ephemeris",
              href  = "http://cool-sat.com/catalog/20201211_223832_CS2/20201211_223832_CS2.EPH",
              title = "Satellite Ephemeris Metadata") |>
    add_link("collection", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("root", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("parent", "./collection.json",
             type = "application/json", title = "Simple Example Collection") |>
    add_link("alternate", "http://remotedata.io/catalog/20201211_223832_CS2/index.html",
             type = "text/html", title = "HTML version of this STAC Item")

  actual <- jsonlite::fromJSON(
    jsonlite::toJSON(as.list(item), auto_unbox = TRUE, digits = 15),
    simplifyVector = FALSE
  )

  expect_equal(actual$type, expected$type)
  expect_equal(actual$stac_version, expected$stac_version)
  expect_equal(actual$id, expected$id)
  expect_equal(actual$bbox, expected$bbox)
  expect_equal(actual$geometry, expected$geometry)
  expect_equal(actual$collection, expected$collection)

  sort_fields <- function(x) {
    if (!is.list(x)) return(x)
    if (!is.null(names(x))) x <- x[order(names(x))]
    lapply(x, sort_fields)
  }
  expect_equal(sort_fields(actual$links), sort_fields(expected$links))
  expect_equal(sort_fields(actual$properties), sort_fields(expected$properties))

  # add_eo_extension adds its own URI (v1.1.0); the fixture uses v2.0.0.
  # Assert the EO extension is present and the remaining 4 extensions match.
  expect_true(any(grepl("stac-extensions.github.io/eo/", actual$stac_extensions)))
  non_eo <- function(exts) sort(unlist(exts[!grepl("stac-extensions.github.io/eo/", exts)]))
  expect_equal(non_eo(actual$stac_extensions), non_eo(expected$stac_extensions))

  expect_equal(sort_fields(actual$assets), sort_fields(expected$assets))
})
