# PREVAIL 0.2.0

This version rebuilds how the historical inputs (1950 to the present day) are made, so that the starting immunity
PREVAIL produces can be used directly, and fixes several problems in the model equations (below).

* OJ Watson is now the maintainer; Arran Hamlet stays as an author and the package's original creator. Added the
  MIT `LICENSE` file that DESCRIPTION already referred to.

## The reporting assumption is now an explicit option

* New argument `transmission_history` in `data_load_process_wrapper()` and `custom_data_process_wrapper()`:
  * `"circulating_years"` (the new default): transmission is on in every year with at least `circulation_threshold`
    (default 2) reported cases per million people, and before reporting starts; off otherwise. Pertussis is treated
    as circulating every year.
  * `"reported_cases_only"`: case reporting is taken to be complete. Transmission is switched off at the first
    reported case and only reported cases are seeded. This is what 0.1.0 did.
* `circulation_threshold = 0` keeps transmission on throughout. `WHO_seed_switch` is deprecated: `FALSE` now means
  this, with a warning.
* New argument `reporting_fraction` (default 1): seeded infections are the reported cases divided by it. This is
  where an estimated reporting level can slot in later.
* New argument `coverage_accuracy` (default 1): a multiplier on the odds of being vaccinated.
* New argument `vaccine_waning`: `"default"` switches waning of measles vaccine protection off and uses the vaccine
  parameter table for other diseases; `"table"` gives the 0.1.0 behaviour; `"none"` switches it off.
* New argument `coverage_source`: `"wuenic"` (default) uses the WHO/UNICEF estimate where there is one; `"median"`
  takes the median of the administrative, official and WUENIC figures as 0.1.0 did.
* `R0` must now be a single number.

## Fixes

* Dose ages from the WHO schedule are converted row by row. Before, every dose got the median of the whole column
  read in its own unit (the United Kingdom's first measles dose was given at 20 years).
* Coverage is converted to a daily rate that gives the reported coverage by the time a cohort leaves the age group.
  Before, 90% reported gave about 70% in the model and nothing could exceed about 82%.
* The second DTP dose has a coverage (interpolated between DTP1 and DTP3). Before, its rate was zero and nobody
  could have more than one dose.
* Vaccine protection is assigned to the right strata (short-term on odd strata, long-term on even), each dose uses
  its own row of the table and each stratum its own waning rate. Before, one pertussis stratum had a protection of
  1.75.
* Births, deaths and migration are carried forward after the last UN WPP year (2023). Before, they were zero.
* `prepare_future_data()`: introductions in more than one year are each made once (10, 0, 10 gave 3,660), and
  `relative_coverage` now scales coverage rather than the daily rate.
* Supplementary immunisation activities are indexed by year correctly (a clash with routine years made some
  settings, such as Sudan measles, fail), can give a further dose to people already vaccinated, and diphtheria and
  pertussis campaigns are no longer dropped.
* A vaccine introduced before 1950 is treated as introduced in 1950 rather than ignored until 1980.
* `data_load_process_wrapper()` now calls `custom_data_process_wrapper()`. The two had drifted: the former divided
  maternal protection and the proportion severe by 100 and did not set the case fatality ratios used in
  projections.
* Case fatality ratios are converted to daily probabilities of death, and the proportion of severe cases with
  complications uses its own row of the disease parameter table.
* Custom vaccine parameters reach the model (they arrived as `NA`).
* All three DTP doses use the primary-series row of the vaccine table (diphtheria `dose` 1, pertussis `dose` 3).
  The second row (diphtheria 6, pertussis 5) is protection after the full schedule with boosters, which the model
  does not represent. Doses 1 and 2 therefore get primary-series protection, which overstates it; partial-course
  values belong in the table as their own rows.
* Seeded cases are placed by age in proportion to the population without random sampling, so the same inputs give
  the same parameters.
* Windows binaries removed from `src/`.

## Model equations

* The model no longer outputs `Reff`. It was the unweighted mean of the age groups' row sums of a next-generation
  matrix, not a reproduction number, and the most expensive calculation in each step. Use
  `effective_reproduction_number()` on the model state.

## New functions

* `effective_reproduction_number()`: the dominant eigenvalue of the next-generation matrix. The model's `Reff`
  output is not a reproduction number and should not be used as one.
* `summarise_immunity()`: susceptibility and immunity by age and source from a model state.
* `run_immunity_history()`: runs the historical period for a country and disease and returns the present-day state
  with diagnostics (R today, susceptibility by age, immunity by source, modelled infections against reported cases,
  achieved against reported coverage).
* `run_immunity_ensemble()` and `write_immunity_json()`: the same over a grid of R0, coverage accuracy and seeds,
  written as JSON.

## Tests

* The package now has tests (`tests/testthat`). Set `PREVAIL_SKIP_SLOW_TESTS=true` to skip those that run the model
  over the whole historical period.
