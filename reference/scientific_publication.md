# Create a Scientific Publication Object

Creates a publication object for use with the Scientific Citation
Extension. Each object represents a scholarly publication that
references or describes the dataset, identified by a DOI and/or a
human-readable citation string.

## Usage

``` r
scientific_publication(doi = NULL, citation = NULL)
```

## Arguments

- doi:

  (character, optional) The DOI of the publication, e.g.
  `"10.1000/abc456"`. This must **not** be a full DOI URL. At least one
  of `doi` or `citation` must be provided.

- citation:

  (character, optional) Human-readable citation of the publication. No
  specific style is required, but it should contain enough information
  to uniquely identify the publication. At least one of `doi` or
  `citation` must be provided.

## Value

A named list of class `"scientific_publication"`.

## Examples

``` r
# Publication with both DOI and citation
pub <- scientific_publication(
  doi = "10.1000/abc456",
  citation = "Smith, J. (2022). Methods for dataset X. Journal of Examples, 1(1)."
)

# Publication with only a citation (no DOI)
pub <- scientific_publication(
  citation = "Jones, A. (2020). Background study. Conference Proceedings."
)
```
