# Aggregate Age Structure of a Model Output Object

Aggregates a long-format data frame with an age dimension (dim1) into
custom age groups. Supports sum, mean, weighted.mean, and rate-based
aggregation with optional plotting check.

## Usage

``` r
aggregate_age_structure(
  obj,
  age_breaks,
  method = c("sum", "mean", "weighted.mean", "rate"),
  weights = NULL,
  time_var = "dim4",
  tol = 1e-06
)
```

## Arguments

- obj:

  A data frame with at least the columns dim1 and value. If using
  time-varying weights, must also include a time column (default: dim4).

- age_breaks:

  A numeric vector of breakpoints defining age bands (e.g. c(0, 1, 5,
  ..., Inf)).

- method:

  One of "sum", "mean", "weighted.mean", or "rate". "rate" returns
  population-weighted rate while preserving total events.

- weights:

  A numeric vector or data frame of population weights, required for
  "rate" and "weighted.mean".

- time_var:

  The name of the time column. Default is "dim4".

- tol:

  Numerical tolerance for preservation check. Default is 1e-6.

## Value

A data frame with aggregated dim1 values. If method = "rate", a plot is
attached as an attribute.
