# Generate a Long-Format Data Frame Representing a Multi-Dimensional Array

This internal helper function creates a tidy data frame representing a
multi-dimensional array up to six dimensions. Each row corresponds to a
unique combination of dimension indices. Optionally, specific values can
be overridden using the \`updates\` argument.

## Usage

``` r
generate_array_df(
  dim1,
  dim2 = NULL,
  dim3 = NULL,
  dim4 = NULL,
  dim5 = NULL,
  dim6 = NULL,
  default_value = 0,
  updates = NULL
)
```

## Arguments

- dim1, dim2, dim3, dim4, dim5, dim6:

  Integers specifying the size of each dimension. Only \`dim1\` is
  required. Others may be \`NULL\`.

- default_value:

  Numeric. Default value to assign to each array element (default is 0).

- updates:

  Optional \`data.frame\` with columns \`dim1\`, \`dim2\`, ..., and
  \`value\` to override specific positions.

## Value

A \`data.frame\` with columns \`ID\`, \`dim1\`, ..., and \`value\`,
representing all array coordinates.
