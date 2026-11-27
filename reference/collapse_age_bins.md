# Collapse Age Bins in a Matrix

This function reduces the number of age bins in a matrix by aggregating
adjacent columns (age groups) into a specified number of broader bins.
Each row is processed independently.

## Usage

``` r
collapse_age_bins(mat, n_bins)
```

## Arguments

- mat:

  A numeric matrix where rows represent observations (e.g., time points
  or locations) and columns represent age groups.

- n_bins:

  An integer specifying the number of broader age bins to collapse into.

## Value

A numeric matrix with the same number of rows as \`mat\` and \`n_bins\`
columns, where each column represents the sum of values from grouped
original age bins.
