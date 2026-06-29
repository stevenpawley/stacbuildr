#' Sign an Azure Blob Storage href using Azure AD authentication.
#'
#' Generates a short-lived user delegation SAS token via a managed identity (or
#' any other Azure AD credential accepted by `AzureStor`). Suitable for passing
#' directly as the `sign_fn` argument of [stac_api_router()].
#'
#' @param href Unsigned Azure Blob Storage URL.
#' @param endpoint Full blob service URL, e.g.
#'   `"https://myaccount.blob.core.windows.net/"`. Defaults to the
#'   `AZURE_STORAGE_ENDPOINT` environment variable.
#' @param expiry_seconds Lifetime of the signed URL in seconds (default 3600).
#' @return A signed URL string with a SAS token appended.
#' @export
sign_azure_ad <- function(
  href,
  endpoint = Sys.getenv("AZURE_STORAGE_ENDPOINT"),
  expiry_seconds = 3600L
) {
  if (!requireNamespace("AzureStor", quietly = TRUE)) {
    stop("Package 'AzureStor' is required for asset signing.")
  }
  if (!requireNamespace("AzureAuth", quietly = TRUE)) {
    stop("Package 'AzureAuth' is required for asset signing.")
  }
  if (!nzchar(endpoint)) {
    stop("'endpoint' is empty. Set AZURE_STORAGE_ENDPOINT or pass it directly.")
  }

  # Normalise double slashes that can appear in href (but preserve ://)
  href <- gsub("://", "\001", href, fixed = TRUE)
  href <- gsub("//+", "/", href)
  href <- gsub("\001", "://", href, fixed = TRUE)

  start_time  <- Sys.time() - 300
  expiry_time <- Sys.time() + expiry_seconds

  token <- AzureAuth::get_managed_token("https://storage.azure.com/")
  endp  <- AzureStor::storage_endpoint(endpoint, token = token)

  userkey <- AzureStor::get_user_delegation_key(
    endp,
    start  = start_time,
    expiry = expiry_time
  )

  # Strip the endpoint prefix to get container/blobpath
  blob_path <- sub(
    paste0("^", sub("/+$", "", endpoint), "/*"),
    "",
    href
  )
  blob_path <- gsub("//+", "/", blob_path)

  sas_token <- AzureStor::get_user_delegation_sas(
    account       = endp,
    key           = userkey,
    resource      = blob_path,
    expiry        = expiry_time,
    permissions   = "r",
    resource_type = "b"
  )

  paste0(href, "?", sas_token)
}
