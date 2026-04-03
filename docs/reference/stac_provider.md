# Create a STAC Provider Object

Helper function to create a properly formatted provider object for STAC
Collections.

## Usage

``` r
stac_provider(name, description = NULL, roles = NULL, url = NULL)
```

## Arguments

- name:

  (character, required) The name of the organization or individual.

- description:

  (character, optional) Description of the provider.

- roles:

  (character vector, optional) Roles of the provider. Common values:
  "producer", "licensor", "processor", "host".

- url:

  (character, optional) Homepage URL for the provider.

## Value

A list representing a STAC Provider.

## Examples

``` r
provider <- stac_provider(
  name = "USGS",
  description = "United States Geological Survey",
  roles = c("producer", "licensor", "host"),
  url = "https://www.usgs.gov"
)
```
