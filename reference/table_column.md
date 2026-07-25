# Create a Table Column Object

Creates a column object for use with the Table Extension. Describes a
single column of a tabular dataset, such as a GeoParquet file.

## Usage

``` r
table_column(name, description = NULL, type = NULL, ...)
```

## Arguments

- name:

  (character, required) The column name.

- description:

  (character, optional) Detailed description of the column. CommonMark
  0.29 syntax may be used for rich text representation.

- type:

  (character, optional) Data type of the column. If the underlying file
  format has a type system (e.g. Parquet), it is recommended to use
  those type names (e.g. `"int64"`, `"double"`, `"string"`, `"bool"`,
  `"binary"`).

- ...:

  Additional fields for the column object.

## Value

A named list of class `"table_column"`.

## Examples

``` r
# A geometry column
col <- table_column(
  name = "geometry",
  type = "binary",
  description = "Point geometry stored as WKB"
)

# A simple attribute column
col <- table_column(name = "elevation", type = "double")
```
