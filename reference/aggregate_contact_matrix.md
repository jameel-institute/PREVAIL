# aggregate_contact_matrix

Aggregate and Rescale a Square Contact Matrix

## Usage

``` r
aggregate_contact_matrix(mat, age_breaks, population, symmetric = TRUE)
```

## Arguments

- mat:

  A square numeric matrix of contact rates (e.g., 101 x 101 for ages
  0–100).

- age_breaks:

  Numeric vector of lower age boundaries for groups (e.g.,
  `c(0, 5, 10, ..., Inf)`).

- population:

  A data frame with columns `time`, `age` (integer, 1-based), and
  `value` (population count).

- symmetric:

  Logical; if `TRUE`, enforces reciprocity between age groups (default:
  `TRUE`).

## Value

A square numeric matrix of dimension `length(age_breaks) - 1`, with sum
preserved.

## Details

Aggregates a square contact matrix to custom age groups using
population-weighted means, then rescales the result to preserve the
total sum of the original matrix.

The function first computes the mean population per single-year age
across time, assigns each age to a group defined by `age_breaks`, and
aggregates the contact matrix using population-weighted averages. It
then rescales the aggregated matrix so that the total sum is equal to
that of the original matrix. Optionally, it enforces symmetry
(reciprocity) using population group weights.
