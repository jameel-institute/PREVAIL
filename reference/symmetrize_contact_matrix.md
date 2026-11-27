# Symmetrize a Contact Matrix Using Population Weights

Computes a symmetric matrix from an asymmetric contact matrix using the
population-weighted average: \$\$C^\text{sym}\_{i,j} = (n_i C\_{i,j} +
n_j C\_{j,i}) / (n_i + n_j)\$\$

## Usage

``` r
symmetrize_contact_matrix(C, pop)
```

## Arguments

- C:

  A square matrix of contact rates.

- pop:

  A numeric vector of population sizes corresponding to the rows/columns
  of \`C\`.

## Value

A symmetric square matrix of the same dimensions as \`C\`.
