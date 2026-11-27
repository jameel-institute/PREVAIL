# Write Present-Day Immunity as JSON

Writes the result of \[run_immunity_history()\] or
\[run_immunity_ensemble()\] as a JSON file that a website (or anything
else) can start projections from, without rebuilding PREVAIL's inputs.

## Usage

``` r
write_immunity_json(x, file = NULL, digits = 6, pretty = FALSE)
```

## Arguments

- x:

  A \`prevail_immunity_history\` or \`prevail_immunity_ensemble\`
  object.

- file:

  Path of the JSON file to write. If \`NULL\` the JSON is returned as a
  string instead.

- digits:

  Significant digits for non-integer numbers. Default 6.

- pretty:

  Logical; indent the JSON? Default \`FALSE\`.

## Value

The list that was written (invisibly), or the JSON string if \`file\` is
\`NULL\`.

## Schema

All indices are 1-based. Arrays over age group and vaccination stratum
are flattened in column-major order (age group varies fastest), so
element \`i + n_age \* (j - 1)\` is age group \`i\`, stratum \`j\`.
Stratum 1 is unvaccinated; dose \`d\` has a long-term stratum \`2d\` and
a short-term stratum \`2d + 1\`.

- \`schema_version\`, \`prevail_version\`, \`generated\`:

  Version of this schema (1), of PREVAIL, and the date.

- \`iso\`, \`disease\`:

  Country and disease.

- \`year_start\`:

  The year the state refers to (its first day): where a projection
  starts.

- \`history_year_start\`:

  First year of the historical run.

- \`dims\`:

  \`n_age\`, \`n_vacc\`, \`n_risk\`.

- \`age_breaks\`:

  Lower bounds of the age groups, separated by semicolons, ending in
  \`Inf\`.

- \`assumptions\`:

  \`transmission_history\`, \`circulation_threshold\`,
  \`reporting_fraction\`, \`vaccine_waning\`, \`coverage_source\`,
  \`seed_floor\`, \`demography_last_year\` (demography is carried
  forward from this year).

- \`routine\`:

  \`coverage\`: reported routine coverage by dose in the final year
  (carried forward from \`year\`); \`dose_age_group\`: the age group
  each dose is given in; \`rates\`: the final year's daily vaccination
  probabilities by age group and the stratum people leave (flattened),
  at a coverage accuracy of 1.

- \`circulating\`:

  \`now\`: is the disease taken to be circulating in the final year;
  \`last_year\`: the last year it was; \`threshold_per_million\`.

- \`vaccine\`:

  For each dose: \`dose\`, and for \`short\` and \`long\`: \`stratum\`,
  \`protection\`, and \`years\` (mean time before waning, \`null\` if
  protection does not wane).

- \`protection\`:

  Vaccine protection by age group and stratum (flattened).

- \`contact_matrix\`:

  The contact matrix (flattened, \`n_age\` by \`n_age\`).

- \`age_distribution\`:

  Share of the population in each age group (for placing introductions
  by age).

- \`worlds\`:

  One entry per historical run: \`R0\`, \`accuracy\` (coverage
  accuracy), \`seed\`, \`w\` (weight; weights sum to 1), \`reff\`
  (effective reproduction number at \`R0\`), \`susc\` (effective
  susceptibility), \`vacc\` (share in a vaccinated stratum),
  \`population\`, \`infected\`, and the state \`S0\`, \`I0\` (exposed
  and infectious) and \`Rpop0\` (recovered), each flattened and in whole
  people.

- \`diagnostics\`:

  Across worlds (weighted): \`n_worlds\`; \`reff\` (\`lo\`, \`q1\`,
  \`med\`, \`q3\`, \`hi\`: 2.5%, 25%, 50%, 75% and 97.5% quantiles);
  \`p_reff_above_1\`; \`susceptible\` (\`lo\`, \`med\`, \`hi\`);
  \`by_age\` (mean shares by age group: \`susceptible\`,
  \`susceptible_unvaccinated\`, \`susceptible_vaccinated\`,
  \`immune_vaccine\`, \`immune_infection\`, \`vaccinated\`; see
  \[summarise_immunity()\]); \`infections_per_year\` (mean of the final
  ten years: \`lo\`, \`med\`, \`hi\`); \`reported_per_year\`;
  \`implied_reporting\` (reported cases over modelled infections);
  \`history\` (final 25 years: \`year\`, \`reported_cases\`,
  \`transmission_on\`, \`infections_med\`, \`infections_lo\`,
  \`infections_hi\`); \`coverage_by_cohort\` (\`age_group\`, \`age\`,
  \`dose\`, \`achieved\`, \`reported\`); \`by_R0\` (median \`reff\` and
  \`susceptible\` for each \`R0\`).
