# Convert Long-Format Updates into an Array

This internal wrapper function generates a tidy grid using
\`generate_array_df()\` and reshapes it into an array using
\`df_to_array()\`. It simplifies the pipeline for transforming partial
long-format input into a structured array.

## Usage

``` r
array_from_df(...)
```

## Arguments

- ...:

  Arguments passed to \`generate_array_df()\` (including \`updates\`,
  \`dim1\`, \`dim2\`, etc.).

## Value

A multi-dimensional array constructed from the provided dimensions and
update values.
