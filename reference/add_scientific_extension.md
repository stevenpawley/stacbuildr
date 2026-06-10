# Add Scientific Citation Extension to a STAC Item

Adds the Scientific Citation Extension to a STAC Item. This extension
provides fields to indicate from which publication data originates and
how the data itself should be cited or referenced, helping to increase
reproducibility and citability.

Three fields are available, at least one of which must be supplied:

- **`sci:doi`**: The DOI of the dataset itself (e.g.
  `"10.1000/xyz123"`).

- **`sci:citation`**: A recommended human-readable citation string for
  the dataset.

- **`sci:publications`**: A list of related publications created with
  [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md).

When a DOI is provided, a `cite-as` link pointing to the DOI URL is
automatically appended to the item's links list (per RFC 8574).

## Usage

``` r
add_scientific_extension(
  item,
  doi = NULL,
  citation = NULL,
  publications = NULL
)
```

## Arguments

- item:

  A STAC Item object created with
  [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md).

- doi:

  (character, optional) The DOI of the data, e.g. `"10.1000/xyz123"`.
  This must **not** be a full DOI URL — provide only the DOI name. A
  corresponding `cite-as` link will be added automatically.

- citation:

  (character, optional) The recommended human-readable reference
  (citation) to be used by publications citing the data. No specific
  citation style is required, but the citation should contain enough
  information to uniquely identify the publication.

- publications:

  (list, optional) A list of
  [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md)
  objects describing related publications that reference or describe the
  data.

## Value

The modified STAC Item with Scientific Citation extension fields added.

## Details

### Extension Schema URI

`https://stac-extensions.github.io/scientific/v1.0.0/schema.json`

### DOI Format

DOIs should be supplied as bare names such as `"10.1000/xyz123"`, not as
full links (`https://doi.org/10.1000/xyz123`). A `cite-as` link with the
full DOI URL is added to the item links automatically when `doi` is
provided.

### Placement

The scientific fields are placed in the item `properties`. Because
citation information is often shared across all items in a collection,
the STAC specification recommends adding these fields at the Collection
level where possible.

## References

Scientific Citation Extension Specification:
<https://github.com/stac-extensions/scientific>

## See also

- [`scientific_publication()`](https://stevenpawley.github.io/stacbuildr/reference/scientific_publication.md)
  for creating publication objects

- [`stac_item()`](https://stevenpawley.github.io/stacbuildr/reference/stac_item.md)
  for creating STAC Items

## Examples

``` r
item <- stac_item(
  id = "my-dataset",
  geometry = list(
    type = "Polygon",
    coordinates = list(list(
      c(-105.5, 39.5), c(-104.5, 39.5), c(-104.5, 40.5),
      c(-105.5, 40.5), c(-105.5, 39.5)
    ))
  ),
  bbox = c(-105.5, 39.5, -104.5, 40.5),
  datetime = "2023-01-01T00:00:00Z"
)

# Add citation with DOI and a related publication
item <- item |>
  add_scientific_extension(
    doi = "10.1000/xyz123",
    citation = "Smith, J. (2023). My Dataset. Example Repository.",
    publications = list(
      scientific_publication(
        doi = "10.1000/abc456",
        citation = "Smith, J. (2022). Methods paper. Journal of Examples."
      )
    )
  )
```
