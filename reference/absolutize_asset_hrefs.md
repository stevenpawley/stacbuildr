# Absolutize relative asset hrefs against an item's base URL

Absolute published catalogs require absolute asset hrefs. Hrefs that are
already URLs are left alone; relative hrefs are resolved against
`item_base_url`; absolute local filesystem paths cannot be mapped to a
URL and are left unchanged with a warning.

## Usage

``` r
absolutize_asset_hrefs(item, item_base_url)
```
