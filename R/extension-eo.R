#' Add EO Extension to a STAC Item
#'
#' @description
#' Adds the Electro-Optical (EO) Extension to a STAC Item. EO data is 
#' considered to be data that represents a snapshot of the Earth for a single date 
#' and time. It could consist of multiple spectral bands in any part of the 
#' electromagnetic spectrum.
#'
#' **Important Note on STAC 1.1.0 Changes:**
#' This extension formerly had a field eo:bands, which has been removed in 
#' favor of a general field bands in STAC common metadata. The structure is the 
#' same—it's an array of Band Objects—but fields from the EO extension now have 
#' an `eo:` prefix, while more general fields like `description` have been moved 
#' to common metadata and don't need a prefix.
#'
#' @param item A STAC Item object created with `stac_item()`.
#' @param bands (list, optional) A list of band objects created with `eo_band()`. 
#'   Each band describes the characteristics of a spectral band. If the asset has 
#'   multiple bands, provide a list with one entry per band in order.
#' @param cloud_cover (numeric, optional) Estimate of cloud cover as a 
#'   percentage (0-100). Should only include valid data regions, excluding nodata 
#'   areas. If not available or cannot be calculated, should not be provided.
#' @param snow_cover (numeric, optional) Estimate of snow/ice cover as a percentage 
#'   (0-100) of the entire scene. Should only include valid data regions. If not 
#'   available, should not be provided.
#' @param asset_key (character, optional) If provided, adds the bands to a specific 
#'   asset rather than to the item properties. The cloud_cover and snow_cover 
#'   properties will always be added to item properties (not assets) as they 
#'   typically apply to the entire scene.
#'
#' @details
#' ## Extension Schema URI
#' The EO Extension v1.1.0 schema URI is:
#' `https://stac-extensions.github.io/eo/v1.1.0/schema.json`
#'
#' ## Band Object Fields
#' Each band can contain the following EO-specific fields (all with `eo:` prefix):
#' * `eo:common_name`: Common name of the band (e.g., "red", "green", "blue", "nir")
#' * `eo:center_wavelength`: Center wavelength in micrometers (μm)
#' * `eo:full_width_half_max`: Full width at half maximum (FWHM) in micrometers
#' * `eo:solar_illumination`: Solar illumination at the band's wavelength
#'
#' Plus common metadata fields without prefix:
#' * `name`: Name of the band (e.g., "B01", "B02", "B1", "B5")
#' * `description`: Description of the band
#'
#' ## Common Band Names
#' The EO extension defines standard common names for typical spectral bands:
#' * **Visible**: `"coastal"`, `"blue"`, `"green"`, `"red"`
#' * **Red Edge**: `"rededge"`, `"rededge071"`, `"rededge075"`, `"rededge078"`
#' * **Near Infrared**: `"nir"`, `"nir08"`, `"nir09"`
#' * **Short-wave Infrared**: `"cirrus"`, `"swir16"`, `"swir22"`
#' * **Long-wave Infrared**: `"lwir"`, `"lwir11"`, `"lwir12"`
#' * **Panchromatic**: `"pan"`
#'
#' ## Coverage Percentages
#' It is important to consider only the valid data regions, excluding 
#' any "nodata" areas while calculating both the coverages. Usually, cloud_cover 
#' and snow_cover should be used in Item Properties rather than Item Assets, as an 
#' Item from an electro-optical source is a single snapshot of the Earth, so the 
#' coverages usually apply to all assets.
#'
#' ## Wavelength Units
#' For example, if we were given a band described as (0.4um - 0.5um) the 
#' eo:center_wavelength would be 0.45um and the eo:full_width_half_max would be 
#' 0.1um.
#'
#' ## Recommended Companion Extensions
#' The EO extension is often used with:
#' * **Instrument Fields** (common metadata): platform, instruments, constellation
#' * **View Extension**: For view geometry (off-nadir, azimuth, sun angles)
#' * **Raster Extension**: For data type, nodata, scale/offset
#'
#' @return The modified STAC Item with EO extension fields added.
#'
#' @seealso 
#' * [eo_band()] for creating EO band objects
#' * [add_raster_extension()] for adding raster metadata
#' * [stac_item()] for creating STAC Items
#'
#' @references
#' EO Extension Specification: 
#' \url{https://github.com/stac-extensions/eo}
#'
#' @examples
#' # Create an item
#' item <- stac_item(
#'   id = "LC08_L2SP_001002_20230615",
#'   geometry = my_geometry,
#'   bbox = my_bbox,
#'   datetime = "2023-06-15T10:30:00Z",
#'   properties = list(
#'     platform = "landsat-8",
#'     instruments = c("oli", "tirs")
#'   )
#' )
#'
#' # Add EO extension with cloud cover
#' item <- add_eo_extension(
#'   item,
#'   cloud_cover = 12.5
#' )
#'
#' # Create multispectral bands
#' red_band <- eo_band(
#'   name = "B4",
#'   common_name = "red",
#'   center_wavelength = 0.665,
#'   full_width_half_max = 0.038
#' )
#'
#' green_band <- eo_band(
#'   name = "B3",
#'   common_name = "green",
#'   center_wavelength = 0.560,
#'   full_width_half_max = 0.043
#' )
#'
#' blue_band <- eo_band(
#'   name = "B2",
#'   common_name = "blue",
#'   center_wavelength = 0.490,
#'   full_width_half_max = 0.038
#' )
#'
#' nir_band <- eo_band(
#'   name = "B5",
#'   common_name = "nir",
#'   center_wavelength = 0.865,
#'   full_width_half_max = 0.033
#' )
#'
#' # Add bands to the item
#' item <- item |>
#'   add_asset(
#'     "visual",
#'     href = "https://example.com/LC08_visual.tif",
#'     type = "image/tiff; application=geotiff",
#'     roles = c("data")
#'   ) |>
#'   add_eo_extension(
#'     bands = list(red_band, green_band, blue_band, nir_band),
#'     cloud_cover = 5.2,
#'     asset_key = "visual"
#'   )
#'
#' # Combine EO and Raster extensions
#' combined_band <- eo_band(
#'   name = "B4",
#'   common_name = "red",
#'   center_wavelength = 0.665,
#'   full_width_half_max = 0.038,
#'   description = "Red band (0.64-0.67 μm)"
#' )
#'
#' # Add raster properties to the same band
#' combined_band$nodata <- 0
#' combined_band$data_type <- "uint16"
#' combined_band$`raster:spatial_resolution` <- 30
#' combined_band$`raster:scale` <- 0.0001
#' combined_band$`raster:offset` <- 0
#'
#' item <- item |>
#'   add_eo_extension(bands = list(combined_band)) |>
#'   add_raster_extension(bands = list(combined_band))
#'
#' @export
add_eo_extension <- function(item,
                             bands = NULL,
                             cloud_cover = NULL,
                             snow_cover = NULL,
                             asset_key = NULL) {
  
  if (!inherits(item, "stac_item")) {
    stop("'item' must be a stac_item object")
  }
  
  # Validate percentages
  if (!is.null(cloud_cover)) {
    if (cloud_cover < 0 || cloud_cover > 100) {
      stop("'cloud_cover' must be between 0 and 100")
    }
  }
  
  if (!is.null(snow_cover)) {
    if (snow_cover < 0 || snow_cover > 100) {
      stop("'snow_cover' must be between 0 and 100")
    }
  }
  
  # Add extension to stac_extensions if not already present
  ext_uri <- "https://stac-extensions.github.io/eo/v1.1.0/schema.json"
  
  if (is.null(item$stac_extensions)) {
    item$stac_extensions <- character(0)
  }
  
  if (!ext_uri %in% item$stac_extensions) {
    item$stac_extensions <- c(item$stac_extensions, ext_uri)
  }
  
  # Add coverage properties to item properties (not assets)
  if (!is.null(cloud_cover)) {
    item$properties$`eo:cloud_cover` <- cloud_cover
  }
  
  if (!is.null(snow_cover)) {
    item$properties$`eo:snow_cover` <- snow_cover
  }
  
  # Add bands if provided
  if (!is.null(bands)) {
    if (!is.list(bands)) {
      stop("'bands' must be a list of band objects")
    }
    
    if (!is.null(asset_key)) {
      # Add to specific asset
      if (is.null(item$assets[[asset_key]])) {
        stop(sprintf("Asset '%s' does not exist in item", asset_key))
      }
      
      item$assets[[asset_key]]$bands <- bands
    } else {
      # Add to item properties
      item$properties$bands <- bands
    }
  }
  
  item
}


#' Create an EO Band Object
#'
#' @description
#' Creates a band object for use with the Electro-Optical (EO) Extension. 
#' Describes the characteristics of a spectral band including wavelength 
#' information and common names.
#'
#' @param name (character, optional) Name of the band as given by the data provider 
#'   (e.g., "B01", "B02", "B1", "B5", "QA").
#' @param common_name (character, optional) Common name of the band. Should be 
#'   one of the standard names if applicable: "coastal", "blue", "green", "red", 
#'   "rededge", "rededge071", "rededge075", "rededge078", "nir", "nir08", "nir09", 
#'   "cirrus", "swir16", "swir22", "lwir", "lwir11", "lwir12", "pan".
#' @param description (character, optional) Description to fully explain the band. 
#'   CommonMark 0.29 syntax may be used for rich text representation.
#' @param center_wavelength (numeric, optional) Center wavelength of the band in 
#'   micrometers (μm). For example, the red band might be 0.665.
#' @param full_width_half_max (numeric, optional) Full width at half maximum 
#'   (FWHM) of the band, in micrometers (μm). This is the width of the band as 
#'   measured at half the maximum transmission.
#' @param solar_illumination (numeric, optional) Solar illumination value for the 
#'   band, as measured at the top of atmosphere. Used in atmospheric correction 
#'   and radiometric calibration.
#' @param ... Additional fields for the band object. Can include fields from other 
#'   extensions like raster fields (`nodata`, `data_type`, `raster:scale`, etc.).
#'
#' @return A list representing an EO band object.
#'
#' @details
#' ## Common Names
#' The use of `common_name` is recommended when the band corresponds to a standard 
#' spectral region. This enables interoperability across different sensors and 
#' platforms. For custom or non-standard bands, use the `name` field with a 
#' descriptive `description`.
#'
#' ## Wavelength Specification
#' Wavelengths should be specified in micrometers (μm). For example:
#' * Blue: ~0.49 μm (490 nm)
#' * Green: ~0.56 μm (560 nm)
#' * Red: ~0.66 μm (660 nm)
#' * NIR: ~0.86 μm (860 nm)
#'
#' ## Combining with Raster Extension
#' EO bands can be combined with raster metadata by adding raster fields to the 
#' same band object. Common raster fields include `nodata`, `data_type`, 
#' `raster:scale`, `raster:offset`, `raster:spatial_resolution`.
#'
#' @examples
#' # Simple band with common name
#' band <- eo_band(
#'   name = "B4",
#'   common_name = "red"
#' )
#'
#' # Band with full wavelength specification
#' band <- eo_band(
#'   name = "B8",
#'   common_name = "nir",
#'   center_wavelength = 0.865,
#'   full_width_half_max = 0.033,
#'   description = "Near Infrared band (0.85-0.88 μm)"
#' )
#'
#' # Band with solar illumination
#' band <- eo_band(
#'   name = "B2",
#'   common_name = "blue",
#'   center_wavelength = 0.490,
#'   full_width_half_max = 0.065,
#'   solar_illumination = 1959.66
#' )
#'
#' # Combine with raster metadata
#' band <- eo_band(
#'   name = "B4",
#'   common_name = "red",
#'   center_wavelength = 0.665,
#'   full_width_half_max = 0.038,
#'   # Raster fields (no prefix for common fields)
#'   nodata = 0,
#'   data_type = "uint16",
#'   # Raster-specific fields (with prefix)
#'   "raster:spatial_resolution" = 30,
#'   "raster:scale" = 0.0001,
#'   "raster:offset" = 0
#' )
#'
#' @export
eo_band <- function(name = NULL,
                   common_name = NULL,
                   description = NULL,
                   center_wavelength = NULL,
                   full_width_half_max = NULL,
                   solar_illumination = NULL,
                   ...) {
  
  band <- list()
  
  # Common metadata fields (no prefix)
  if (!is.null(name)) band$name <- name
  if (!is.null(description)) band$description <- description
  
  # Validate common_name
  if (!is.null(common_name)) {
    valid_common_names <- c(
      "coastal", "blue", "green", "red",
      "rededge", "rededge071", "rededge075", "rededge078",
      "nir", "nir08", "nir09",
      "cirrus", "swir16", "swir22",
      "lwir", "lwir11", "lwir12",
      "pan"
    )
    
    if (!common_name %in% valid_common_names) {
      warning(sprintf(
        "'%s' is not a standard common_name. Standard names: %s",
        common_name,
        paste(valid_common_names, collapse = ", ")
      ))
    }
    
    band$`eo:common_name` <- common_name
  }
  
  # EO-specific fields (eo: prefix)
  if (!is.null(center_wavelength)) {
    band$`eo:center_wavelength` <- center_wavelength
  }
  
  if (!is.null(full_width_half_max)) {
    band$`eo:full_width_half_max` <- full_width_half_max
  }
  
  if (!is.null(solar_illumination)) {
    band$`eo:solar_illumination` <- solar_illumination
  }
  
  # Add any extra fields (e.g., from raster extension)
  extra_fields <- list(...)
  if (length(extra_fields) > 0) {
    band <- c(band, extra_fields)
  }
  
  band
}


#' Create Standard Landsat 8/9 OLI Bands
#'
#' @description
#' Helper function to create standard band definitions for Landsat 8 and 9 
#' Operational Land Imager (OLI) sensors.
#'
#' @param include_thermal (logical, optional) If TRUE, includes TIRS thermal 
#'   bands (B10, B11). Default is FALSE (OLI bands only).
#'
#' @return A list of EO band objects representing Landsat OLI/TIRS bands.
#'
#' @examples
#' bands <- landsat_oli_bands()
#' 
#' item <- item |>
#'   add_eo_extension(bands = bands)
#'
#' @export
landsat_oli_bands <- function(include_thermal = FALSE) {
  
  bands <- list(
    eo_band(
      name = "B1",
      common_name = "coastal",
      center_wavelength = 0.44,
      full_width_half_max = 0.02
    ),
    eo_band(
      name = "B2",
      common_name = "blue",
      center_wavelength = 0.48,
      full_width_half_max = 0.06
    ),
    eo_band(
      name = "B3",
      common_name = "green",
      center_wavelength = 0.56,
      full_width_half_max = 0.06
    ),
    eo_band(
      name = "B4",
      common_name = "red",
      center_wavelength = 0.655,
      full_width_half_max = 0.04
    ),
    eo_band(
      name = "B5",
      common_name = "nir",
      center_wavelength = 0.865,
      full_width_half_max = 0.03
    ),
    eo_band(
      name = "B6",
      common_name = "swir16",
      center_wavelength = 1.61,
      full_width_half_max = 0.08
    ),
    eo_band(
      name = "B7",
      common_name = "swir22",
      center_wavelength = 2.2,
      full_width_half_max = 0.18
    ),
    eo_band(
      name = "B8",
      common_name = "pan",
      center_wavelength = 0.59,
      full_width_half_max = 0.18
    ),
    eo_band(
      name = "B9",
      common_name = "cirrus",
      center_wavelength = 1.37,
      full_width_half_max = 0.02
    )
  )
  
  if (include_thermal) {
    bands <- c(bands, list(
      eo_band(
        name = "B10",
        common_name = "lwir11",
        center_wavelength = 10.9,
        full_width_half_max = 0.8
      ),
      eo_band(
        name = "B11",
        common_name = "lwir12",
        center_wavelength = 12.0,
        full_width_half_max = 1.0
      )
    ))
  }
  
  bands
}


#' Create Standard Sentinel-2 MSI Bands
#'
#' @description
#' Helper function to create standard band definitions for Sentinel-2 
#' MultiSpectral Instrument (MSI) sensors.
#'
#' @return A list of EO band objects representing Sentinel-2 MSI bands.
#'
#' @examples
#' bands <- sentinel2_msi_bands()
#' 
#' item <- item |>
#'   add_eo_extension(bands = bands)
#'
#' @export
sentinel2_msi_bands <- function() {
  
  list(
    eo_band(
      name = "B01",
      common_name = "coastal",
      center_wavelength = 0.443,
      full_width_half_max = 0.027
    ),
    eo_band(
      name = "B02",
      common_name = "blue",
      center_wavelength = 0.490,
      full_width_half_max = 0.098
    ),
    eo_band(
      name = "B03",
      common_name = "green",
      center_wavelength = 0.560,
      full_width_half_max = 0.045
    ),
    eo_band(
      name = "B04",
      common_name = "red",
      center_wavelength = 0.665,
      full_width_half_max = 0.038
    ),
    eo_band(
      name = "B05",
      common_name = "rededge071",
      center_wavelength = 0.705,
      full_width_half_max = 0.019
    ),
    eo_band(
      name = "B06",
      common_name = "rededge075",
      center_wavelength = 0.740,
      full_width_half_max = 0.018
    ),
    eo_band(
      name = "B07",
      common_name = "rededge078",
      center_wavelength = 0.783,
      full_width_half_max = 0.028
    ),
    eo_band(
      name = "B08",
      common_name = "nir",
      center_wavelength = 0.842,
      full_width_half_max = 0.145
    ),
    eo_band(
      name = "B8A",
      common_name = "nir08",
      center_wavelength = 0.865,
      full_width_half_max = 0.033
    ),
    eo_band(
      name = "B09",
      common_name = "nir09",
      center_wavelength = 0.945,
      full_width_half_max = 0.026
    ),
    eo_band(
      name = "B10",
      common_name = "cirrus",
      center_wavelength = 1.3735,
      full_width_half_max = 0.075
    ),
    eo_band(
      name = "B11",
      common_name = "swir16",
      center_wavelength = 1.610,
      full_width_half_max = 0.143
    ),
    eo_band(
      name = "B12",
      common_name = "swir22",
      center_wavelength = 2.190,
      full_width_half_max = 0.242
    )
  )
}


#' Print method for EO band objects
#'
#' @param x An EO band object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.eo_band <- function(x, ...) {
  cat("EO Band:\n")
  
  if (!is.null(x$name)) {
    cat("  Name:", x$name, "\n")
  }
  
  if (!is.null(x$`eo:common_name`)) {
    cat("  Common Name:", x$`eo:common_name`, "\n")
  }
  
  if (!is.null(x$description)) {
    cat("  Description:", x$description, "\n")
  }
  
  if (!is.null(x$`eo:center_wavelength`)) {
    cat("  Center Wavelength:", x$`eo:center_wavelength`, "μm\n")
  }
  
  if (!is.null(x$`eo:full_width_half_max`)) {
    cat("  FWHM:", x$`eo:full_width_half_max`, "μm\n")
  }
  
  if (!is.null(x$`eo:solar_illumination`)) {
    cat("  Solar Illumination:", x$`eo:solar_illumination`, "\n")
  }
  
  # Show raster fields if present
  if (!is.null(x$data_type)) {
    cat("  Data Type:", x$data_type, "\n")
  }
  
  if (!is.null(x$`raster:spatial_resolution`)) {
    cat("  Spatial Resolution:", x$`raster:spatial_resolution`, "m\n")
  }
  
  invisible(x)
}
