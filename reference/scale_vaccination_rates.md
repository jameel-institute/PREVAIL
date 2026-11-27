# Scale Vaccination Rates by a Relative Coverage

Changes a set of daily vaccination probabilities so that first-dose
coverage is multiplied by \`relative_coverage\`. The first-dose rate of
each age group is converted back to the coverage it gives (the share
vaccinated on leaving the age group), the coverage is scaled, and the
result is converted to a rate again (see \[coverage_to_daily_rate()\]).
Rates of later doses are rates among those who have had the previous
dose, so they are left as they are: coverage of every dose then scales
by \`relative_coverage\`. A relative coverage of zero stops all
vaccination.

## Usage

``` r
scale_vaccination_rates(
  rates,
  aging_rate,
  relative_coverage,
  max_coverage = 0.99
)
```

## Arguments

- rates:

  Daily vaccination probabilities by age group, stratum left and risk
  group.

- aging_rate:

  Daily ageing probability by age group.

- relative_coverage:

  Multiplier on coverage.

- max_coverage:

  Cap on coverage (default 0.99).

## Value

An array like \`rates\`.
