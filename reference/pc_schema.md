# Create a Point Cloud Schema Object

Creates a Schema object for the `pc:schemas` field of the Point Cloud
Extension. Each object describes one dimension (channel) of the point
cloud: its name, its size in whole bytes, and how its bytes are
interpreted.

## Usage

``` r
pc_schema(name, size, type)
```

## Arguments

- name:

  (character) **Required.** The name of the dimension, e.g. `"X"`,
  `"Intensity"`, or `"Classification"`.

- size:

  (integer) **Required.** The size of the dimension in whole bytes. Must
  be a whole number greater than 0.

- type:

  (character) **Required.** The dimension type. One of `"floating"`,
  `"unsigned"`, or `"signed"`.

## Value

A `pc_schema` object (a list with a print method).

## Details

Only whole-byte sizes are representable. Bit-packed LAS fields such as
`ReturnNumber` are conventionally reported as the unpacked one-byte
dimension a reader materialises, which is what
[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md)
does.

## See also

[`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md),
[`pc_statistic()`](https://stevenpawley.github.io/stacbuildr/reference/pc_statistic.md)

## Examples

``` r
pc_schema("X", size = 8, type = "floating")
#> <Point Cloud Schema>
#>   name         : X
#>   size         : 8 bytes
#>   type         : floating
pc_schema("Intensity", size = 2, type = "unsigned")
#> <Point Cloud Schema>
#>   name         : Intensity
#>   size         : 2 bytes
#>   type         : unsigned
```
