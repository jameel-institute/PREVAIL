# Split a Whole Number in Proportion to Weights

Returns whole numbers that sum to \`round(n)\` and are as close as
possible to \`n \* weights / sum(weights)\` (largest remainders). Used
to place seeded infections by age without random sampling, so that the
same inputs always give the same parameters.

## Usage

``` r
apportion_whole(n, weights)
```

## Arguments

- n:

  Total to split.

- weights:

  Non-negative weights.

## Value

Integer-valued numeric vector the same length as \`weights\`.
