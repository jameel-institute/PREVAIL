# Update Contact Matrix to Match Age Vector

Updates a raw contact matrix (with 5-year age intervals) to match a
specified age vector. Assigns contact rates by nearest-neighbor matching
between raw age bins and target age values.

## Usage

``` r
update_contact_matrix(contact_matrix_raw, age_vector)
```

## Arguments

- contact_matrix_raw:

  A square matrix of contact rates, indexed by 5-year age groups.

- age_vector:

  A numeric vector of target age values to which the matrix should be
  updated.

## Value

A square matrix of contact rates with dimensions matching
\`age_vector\`.
