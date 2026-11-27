# Compare Two Inputs Using Population Weights or Sum

Computes population-weighted averages or total sums for two input
objects and compares them.

## Usage

``` r
compare_weighted_inputs(
  default_input,
  default_weight,
  adapted_input,
  adapted_weight,
  method = "weighted"
)
```

## Arguments

- default_input:

  A data frame or matrix containing the baseline input values.

- default_weight:

  A data frame or matrix of weights (e.g., N0) corresponding to
  \`default_input\`.

- adapted_input:

  A data frame or matrix containing the transformed input values (e.g.,
  aggregated).

- adapted_weight:

  A data frame or matrix of weights corresponding to \`adapted_input\`.

- method:

  Either "weighted" (default) or "sum".

## Value

A list containing summary statistics for each input comparison.
