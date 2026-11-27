# Apply a Coverage Accuracy Multiplier to a Coverage

Multiplies the odds of a coverage by \`coverage_accuracy\` and converts
back to a proportion.

## Usage

``` r
adjust_coverage_odds(coverage, coverage_accuracy = 1, max_coverage = 0.99)
```

## Arguments

- coverage:

  Target coverage (proportion) on leaving the age group. For second and
  later doses this is the coverage among those who have had the previous
  dose.

- coverage_accuracy:

  Multiplier on the odds of vaccination. Default 1.

- max_coverage:

  Coverage is capped at this value (default 0.99) so that the rate stays
  finite.

## Value

Adjusted coverage (proportion).
