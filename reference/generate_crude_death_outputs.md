# Generate Aggregated Crude Death Output

Computes aggregated crude death counts and rates across new age bands
from preprocessed demographic data. The function joins crude death rates
to population weights, aggregates by new age groups, and compares total
deaths before and after aggregation for consistency checking. Includes a
diagnostic plot.

## Usage

``` r
generate_crude_death_outputs(preprocessed, weight_reformatted, age_breaks)
```

## Arguments

- preprocessed:

  A list-like object containing demographic model inputs, with a
  component \`processed_demographic_data\$crude_death\`.

- weight_reformatted:

  A data.frame or tibble with columns \`time\`, \`age\`, and \`value\`
  providing population weights, usually long-format population data.

- age_breaks:

  Numeric vector of age group cut points (e.g., \`c(0, 5, 10, 15, 20,
  ..., 80, 100)\`).

## Value

Invisibly returns \`TRUE\` if total deaths are preserved after
aggregation. Also produces a diagnostic line plot (deaths by time,
original vs. aggregated).
