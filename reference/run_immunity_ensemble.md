# Run an Ensemble of Histories

Runs \[run_immunity_history()\] for every combination of the basic
reproduction numbers, coverage accuracies and seeds given, so that the
uncertainty in present-day immunity can be carried into projections.
Each combination is one "world".

## Usage

``` r
run_immunity_ensemble(
  iso,
  disease,
  R0,
  coverage_accuracy = 1,
  seeds = 1,
  R0_weights = NULL,
  accuracy_weights = NULL,
  cores = 1,
  ...
)
```

## Arguments

- iso, disease:

  Country and disease.

- R0:

  Vector of basic reproduction numbers.

- coverage_accuracy:

  Vector of coverage accuracies (multipliers on the odds of
  vaccination).

- seeds:

  Vector of seeds.

- R0_weights, accuracy_weights:

  Optional weights for the values of \`R0\` and \`coverage_accuracy\`
  (in the same order). Equal weights by default. The weight of a world
  is the product of the two, shared equally among seeds.

- cores:

  Number of worlds to run in parallel (uses \`parallel::mclapply()\`;
  not available on Windows).

- ...:

  Further arguments passed to \[run_immunity_history()\], for example
  \`transmission_history\` or \`year_end\`.

## Value

A list of class \`prevail_immunity_ensemble\` with \`worlds\` (a list of
\`prevail_immunity_history\` objects, each with a \`weight\`), \`grid\`
(a data frame of \`R0\`, \`coverage_accuracy\`, \`seed\`, \`weight\` and
each world's summary) and \`diagnostics\` (weighted summaries across
worlds; see \[write_immunity_json()\] for what they hold).

## Examples

``` r
if (FALSE) { # \dontrun{
ens <- run_immunity_ensemble("GBR", "measles", R0 = c(12, 15, 18), coverage_accuracy = c(0.5, 1, 2),
                             seeds = 1:2, year_end = 2025)
write_immunity_json(ens, "GBR_measles.json")
} # }
```
