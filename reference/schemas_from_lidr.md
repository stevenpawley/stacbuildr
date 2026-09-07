# Build Point Cloud Schema Objects from a LAS Header

Derives the `pc:schemas` dimension list for a LAS/LAZ file from its
point data record format, plus any additional dimensions declared in the
file's Extra Bytes variable length record.

## Usage

``` r
schemas_from_lidr(header)
```

## Arguments

- header:

  A `LASheader` object from
  [`lidR::readLASheader()`](https://rdrr.io/pkg/lidR/man/readLASheader.html),
  or a `LAS` object (its header is used).

## Value

A list of
[`pc_schema()`](https://stevenpawley.github.io/stacbuildr/reference/pc_schema.md)
objects, or `NULL` if the point data record format is not recognised.

## Details

Only the header is read, so this is fast even for very large files.
Sizes follow the whole-byte, unpacked convention described in
[`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md).

## See also

[`item_from_lidr()`](https://stevenpawley.github.io/stacbuildr/reference/item_from_lidr.md),
[`add_pointcloud_extension()`](https://stevenpawley.github.io/stacbuildr/reference/add_pointcloud_extension.md)

## Examples

``` r
if (FALSE) { # \dontrun{
header <- lidR::readLASheader("points.laz")
schemas_from_lidr(header)
} # }
```
