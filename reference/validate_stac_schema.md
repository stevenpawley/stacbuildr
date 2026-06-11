# Validate a STAC Object Against the Official JSON Schema

Validates a STAC Catalog, Collection, or Item against the official STAC
JSON Schemas hosted at `schemas.stacspec.org`, using the
[jsonvalidate](https://CRAN.R-project.org/package=jsonvalidate) package.
Unlike
[`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md),
which applies hand-written structural checks, this function performs
authoritative validation against the exact schema that defines the
specification.

When `validate_extensions = TRUE` (the default), each URI listed in the
object's `stac_extensions` field is also used as a JSON Schema and
validated against in turn, so extension-level fields are checked as
well.

## Usage

``` r
validate_stac_schema(stac_object, validate_extensions = TRUE)
```

## Arguments

- stac_object:

  A STAC object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md),
  [`stac_collection()`](https://stevenpawley.github.io/stacbuildr/reference/stac_collection.md),
  or
  [`stac_catalog()`](https://stevenpawley.github.io/stacbuildr/reference/stac_catalog.md).

- validate_extensions:

  (logical) If `TRUE` (the default), validate the serialised object
  against every JSON Schema URI declared in the object's
  `stac_extensions` field in addition to the core STAC schema.

## Value

A named list with elements `valid`, `errors`, and `warnings`.

## Details

### Requirements

The `jsonvalidate` package must be installed:

    install.packages("jsonvalidate")

### Network Access

Schema files are fetched over the network at validation time — both the
core STAC schema and any extension schemas. Internet access is required.
Validation will fail with an informative error message if a schema URL
cannot be reached.

### Schema URLs

The core schema URL is derived from the object type and its
`stac_version` field, following the pattern:
`https://schemas.stacspec.org/v{stac_version}/{type}-spec/json-schema/{type}.json`

### Return Value

Returns the same structure as
[`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md):

- `valid` — `TRUE` if no schema errors were found.

- `errors` — character vector of error messages, one per violation.
  Extension errors are prefixed with the extension schema URI.

- `warnings` — always an empty character vector (reserved for future
  use).

## References

Official STAC JSON Schemas: <https://schemas.stacspec.org>

## See also

[`validate_stac()`](https://stevenpawley.github.io/stacbuildr/reference/validate_stac.md)
for fast, offline structural checks.

## Examples

``` r
item <- stac_item(
  id       = "my-item",
  geometry = list(type = "Point", coordinates = c(-105, 40)),
  bbox     = c(-105, 40, -105, 40),
  datetime = "2023-01-01T00:00:00Z"
)

if (FALSE) { # \dontrun{
result <- validate_stac_schema(item)
result$valid
result$errors
} # }
```
