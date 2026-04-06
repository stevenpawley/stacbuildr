# Create a STAC link object

Creates a link object following the STAC specification. Links are used
to connect STAC resources (catalogs, collections, and items) and
establish relationships between them.

## Usage

``` r
stac_link(
  rel,
  href,
  type = NULL,
  title = NULL,
  method = NULL,
  headers = NULL,
  body = NULL,
  merge = FALSE
)
```

## Arguments

- rel:

  (character, required) The link relation type. Common values include
  `"self"`, `"root"`, `"parent"`, `"child"`, `"item"`, `"collection"`,
  `"license"`, `"derived_from"`, and `"via"`. See the STAC specification
  for a complete list of relation types.

- href:

  (character, required) The URL or path to the linked resource. Can be
  absolute or relative.

- type:

  (character, optional) The media type of the linked resource. Common
  values include `"application/json"`, `"application/geo+json"`, and
  `"text/html"`. Default is `NULL`.

- title:

  (character, optional) A human-readable title for the link. Default is
  `NULL`.

- method:

  (character, optional) The HTTP method to use when following the link
  (e.g., `"GET"`, `"POST"`). Default is `NULL`.

- headers:

  (list or named vector, optional) HTTP headers to include when
  following the link. Default is `NULL`.

- body:

  (list, optional) The HTTP body to include when following the link
  (typically used with POST requests). Default is `NULL`.

- merge:

  (logical, optional) Whether to merge the link body with the current
  resource when following the link. Default is `FALSE`.

## Value

A list representing a STAC link object with NULL values removed.

## References

STAC Link Object specification:
<https://github.com/radiantearth/stac-spec/blob/master/catalog-spec/catalog-spec.md#link-object>

## See also

- [`add_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_link.md)
  for adding links to STAC objects

- [`add_self_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_self_link.md),
  [`add_root_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_root_link.md),
  [`add_parent_link()`](https://stevenpawley.github.io/stacbuildr/reference/add_parent_link.md)
  for convenience functions
