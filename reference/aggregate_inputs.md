# Aggregate or Default Model Inputs by Age Structure

This helper function performs optional aggregation of model inputs into
a new age structure. It returns both the default unaggregated inputs and
the aggregated inputs (if requested).

## Usage

``` r
aggregate_inputs(preprocessed, cv_params, new_age_breaks, aggregate_age)
```

## Arguments

- preprocessed:

  A list from prepare_model_inputs() including demographic data.

- cv_params:

  Output from case_vaccine_to_param().

- new_age_breaks:

  Numeric vector of age breakpoints.

- aggregate_age:

  Logical. If TRUE, aggregates into new_age_breaks.

## Value

A list with two elements:

- default_inputs: Model inputs without age aggregation.

- inputs: Aggregated model inputs (if aggregate_age is TRUE), else same
  as default.
