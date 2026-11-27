# Convert Long-Format Data Frame to Multi-Dimensional Array

This internal function converts a tidy data frame containing dimension
columns and a \`value\` column into a numeric array. Each row specifies
the value for a particular position in the output array.

## Usage

``` r
df_to_array(df)
```

## Arguments

- df:

  A data frame containing dimension columns named \`dim1\`, \`dim2\`,
  ..., and a \`value\` column.

## Value

A numeric array with shape inferred from the maximum index in each
dimension column.
