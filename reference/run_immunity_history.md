# Run the Historical Period and Summarise Present-Day Immunity

Runs the model from the first year of data (1950) to the start of
\`year_end\` for one country and disease, under a stated assumption
about reporting, and returns the state at the end together with
diagnostics that show what the assumption implies.

## Usage

``` r
run_immunity_history(
  iso,
  disease,
  R0,
  transmission_history = c("circulating_years", "reported_cases_only"),
  circulation_threshold = 2,
  reporting_fraction = 1,
  coverage_accuracy = 1,
  vaccine_waning = "default",
  coverage_source = c("wuenic", "median"),
  seed_floor = 10,
  year_end = "",
  seed = 1,
  keep_params = FALSE,
  snapshot_years = NULL,
  ...
)
```

## Arguments

- iso:

  A 3-letter ISO country code.

- disease:

  \`"measles"\`, \`"diphtheria"\` or \`"pertussis"\`.

- R0:

  Basic reproduction number while transmission is on.

- transmission_history, circulation_threshold, reporting_fraction,
  coverage_accuracy, vaccine_waning, coverage_source, seed_floor:

  The historical assumptions; see \[data_load_process_wrapper()\].

- year_end:

  The state returned is that at the start of this year. Default (\`""\`)
  is the current year.

- seed:

  Seed for the model's random number stream. Different seeds give
  different stochastic histories, which mainly sets where in its
  epidemic cycle a setting is at the end.

- keep_params:

  Logical; return the parameter list too? Default \`FALSE\`.

- snapshot_years:

  Years at whose start to record immunity by age (as in \`by_age\`), for
  example the years of several serosurveys, so that one run serves them
  all. Years outside the run are dropped with a warning. Default
  \`NULL\`, none.

- ...:

  Further arguments passed to \[custom_data_process_wrapper()\] (for
  example custom data).

## Value

A list of class \`prevail_immunity_history\` with:

- \`iso\`, \`disease\`, \`R0\`, \`seed\`, \`year_start\`, \`year_end\`:

  What was run. The state is at the start of \`year_end\`.

- \`assumptions\`:

  The historical assumptions used.

- \`summary\`:

  \`reff\` (the effective reproduction number at \`R0\`, see
  \[effective_reproduction_number()\]), \`population\`, \`susceptible\`
  (effective susceptibility), \`vaccinated\` and \`infected\`.

- \`by_age\`:

  Immunity by age group and source; see \[summarise_immunity()\].

- \`infections\`:

  By year: modelled infections (all ages and under five), reported
  cases, the reporting fraction this implies (reported cases over
  modelled infections), seeded infections and whether transmission was
  on.

- \`infections_by_age\`:

  Modelled infections by year (rows, named by year) and age group
  (columns).

- \`snapshots\`:

  Immunity by age at the start of each of \`snapshot_years\`: the
  columns of \`by_age\` with a \`year\` column first, or \`NULL\` if
  none were asked for.

- \`coverage\`:

  By age group and dose: the share of the age group that has had at
  least that many doses at the end of the run (\`achieved\`) against the
  mean reported routine coverage in the years its birth cohorts were due
  the dose (\`reported\`). Campaign doses, the coverage accuracy and,
  where vaccine protection wanes, waning out of a stratum all move
  \`achieved\` away from \`reported\`.

- \`state\`:

  \`S0\`, \`I0\` (exposed and infectious) and \`Rpop0\` (recovered) by
  age group, vaccination stratum and risk group, rounded to whole
  people, ready to start a projection from; and \`compartments\`, the
  six model compartments unrounded.

- \`inputs\`:

  Routine coverage and age group by dose in the final year, the final
  year's vaccination rates, protection and waning by stratum, whether
  the disease is taken to be circulating now, and the age distribution
  of the population.

## Examples

``` r
if (FALSE) { # \dontrun{
h <- run_immunity_history("GBR", "measles", R0 = 15, year_end = 2025)
h$summary$reff
h$by_age
} # }
```
