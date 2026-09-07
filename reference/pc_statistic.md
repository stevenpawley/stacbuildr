# Create a Point Cloud Statistics Object

Creates a Stats object for the `pc:statistics` field of the Point Cloud
Extension, giving statistics for one dimension (channel) of the point
cloud.

## Usage

``` r
pc_statistic(
  name,
  position = NULL,
  average = NULL,
  count = NULL,
  maximum = NULL,
  minimum = NULL,
  stddev = NULL,
  variance = NULL
)
```

## Arguments

- name:

  (character) **Required.** The name of the channel, matching the
  corresponding
  [`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md)
  `name`.

- position:

  (integer, optional) The zero-based position of the channel within
  `pc:schemas`.

- average:

  (numeric, optional) The average of the channel.

- count:

  (integer, optional) The number of elements in the channel.

- maximum:

  (numeric, optional) The maximum value of the channel.

- minimum:

  (numeric, optional) The minimum value of the channel.

- stddev:

  (numeric, optional) The standard deviation of the channel.

- variance:

  (numeric, optional) The variance of the channel.

## Value

A `pc_statistic` object (a list with a print method).

## Details

The specification requires the channel name and at least one statistic,
so supplying `name` alone is an error.

## See also

[`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md),
[`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md)

## Examples

``` r
pc_statistic("Z", position = 2, minimum = 406.14, maximum = 615.26)
#> <Point Cloud Statistics>
#>   name         : Z
#>   position     : 2
#>   maximum      : 615.26
#>   minimum      : 406.14
```
