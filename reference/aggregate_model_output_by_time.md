# Aggregate Model Output by Time Units (State-Specific Aggregation)

Converts model \`time\` into calendar dates from a reference start date,
and aggregates values to a target time unit (e.g., weekly, monthly,
yearly), grouped by all other variables. Aggregation is determined based
on the value of the \`state\` column: - Stocks (S, E, I, R, Is, Rc,
total_pop): take last value - Flows (new_case): sum - Rates (Reff,
Reff_age): mean

## Usage

``` r
aggregate_model_output_by_time(
  df,
  timestep = "day",
  target_unit = "week",
  start_date = "2000-01-01"
)
```

## Arguments

- df:

  A data.frame or data.table with \`time\`, \`value\`, \`state\`, and
  other stratifiers.

- timestep:

  Character. One of "day", "week", "month", or "year". Time step used in
  the model.

- target_unit:

  Character. One of "week", "month", or "year". Unit to aggregate into.

- start_date:

  A string date (e.g. "2020-01-01") indicating the model time origin.

## Value

A data.table with time-aggregated results.
