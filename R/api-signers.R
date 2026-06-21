#' Sign an Azure Blob Storage href using Azure AD authentication.
#'
#' Generates a short-lived user delegation SAS token via a managed identity (or
#' any other Azure AD credential accepted by `AzureStor`). Reads the storage
#' endpoint and container from environment variables so that nothing is
#' hardcoded. Suitable for passing directly as the `sign_fn` argument of
#' [stac_api_router()].
#'
#' Required environment variables:
#' * `AZURE_STORAGE_ENDPOINT` — full blob service URL, e.g.
#'   `"https://myaccount.blob.core.windows.net/"`.
#' * `AZURE_STORAGE_CONTAINER` — container name, e.g. `"stac"`.
#'
#' @param href Unsigned Azure Blob Storage URL.
#' @param expiry_seconds Lifetime of the signed URL in seconds (default 3600).
#' @return A signed URL string with a SAS token appended.
#' @export
sign_azure_ad <- function(href, expiry_seconds = 3600L) {
  if (!requireNamespace("AzureStor", quietly = TRUE)) {
    stop("Package 'AzureStor' is required for asset signing.")
  }

  endpoint  <- Sys.getenv("AZURE_STORAGE_ENDPOINT", "")
  container <- Sys.getenv("AZURE_STORAGE_CONTAINER", "")

  if (!nzchar(endpoint)) {
    stop("AZURE_STORAGE_ENDPOINT environment variable is not set.")
  }
  if (!nzchar(container)) {
    stop("AZURE_STORAGE_CONTAINER environment variable is not set.")
  }

  # Strip endpoint + container prefix to get the blob path
  prefix <- paste0(sub("/+$", "", endpoint), "/", container, "/")
  if (!startsWith(href, prefix)) {
    stop(sprintf("href does not belong to container '%s': %s", container, href))
  }
  blob_path <- substring(href, nchar(prefix) + 1L)

  expiry_time <- Sys.time() + expiry_seconds

  token <- AzureStor::get_managed_token("https://storage.azure.com/")
  endp  <- AzureStor::storage_endpoint(endpoint, token = token)

  # User delegation key is scoped to the SAS lifetime
  userkey <- AzureStor::get_user_delegation_key(endp, expiry = expiry_time)

  AzureStor::get_user_delegation_sas(
    account       = endp,
    key           = userkey,
    resource      = blob_path,
    expiry        = expiry_time,
    permissions   = "r",
    resource_type = "b"
  )
}