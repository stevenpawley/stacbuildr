# Write a Single STAC Item File

Writes a single STAC Item to a JSON file.

## Usage

``` r
write_item(item, file, overwrite = FALSE, pretty = TRUE)
```

## Arguments

- item:

  A STAC Item object created with [`stac_item()`](stac_item.md).

- file:

  (character, required) Path to the output JSON file.

- overwrite:

  (logical, optional) If `TRUE`, overwrites existing file. Default is
  `FALSE`.

- pretty:

  (logical, optional) If `TRUE`, writes formatted JSON. Default is
  `TRUE`.

## Value

Invisibly returns the file path.

## Examples

``` r
if (FALSE) { # \dontrun{
item <- stac_item(
  id = "my-item",
  geometry = list(type = "Point", coordinates = c(-105, 40)),
  bbox = c(-105, 40, -105, 40),
  datetime = "2023-01-01T00:00:00Z"
)

write_item(item, "items/my-item.json")
} # }
```
