# Sign an Azure Blob Storage href using Azure AD authentication.

Generates a short-lived user delegation SAS token via a managed identity
(or any other Azure AD credential accepted by `AzureStor`). Reads the
storage endpoint and container from environment variables so that
nothing is hardcoded. Suitable for passing directly as the `sign_fn`
argument of
[`stac_api_router()`](https://stevenpawley.github.io/stacbuildr/reference/stac_api_router.md).

## Usage

``` r
sign_azure_ad(href, expiry_seconds = 3600L)
```

## Arguments

- href:

  Unsigned Azure Blob Storage URL.

- expiry_seconds:

  Lifetime of the signed URL in seconds (default 3600).

## Value

A signed URL string with a SAS token appended.

## Details

Required environment variables:

- `AZURE_STORAGE_ENDPOINT` — full blob service URL, e.g.
  `"https://myaccount.blob.core.windows.net/"`.

- `AZURE_STORAGE_CONTAINER` — container name, e.g. `"stac"`.
