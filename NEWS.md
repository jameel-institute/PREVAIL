# PREVAIL 0.2.0.9000

Additions for fitting diphtheria and pertussis serosurveys.

* New `modelled_seroprevalence()`: the share of a serosurvey age band expected to test seropositive, from the
  immunity by age of `run_immunity_history()`, allowing for assay sensitivity and specificity, vaccine-protected
  people without detectable antibody and maternal antibody in infants.
* New `serosurvey_loglik()`: binomial or beta-binomial log-likelihood of seropositive counts by age band. Together
  these are what fitting `reporting_fraction` and `coverage_accuracy` to serosurveys needs.
* `run_immunity_history()` has a new argument `snapshot_years`, and returns immunity by age at the start of each of
  those years (`snapshots`), so that one run serves every serosurvey in a country. It also returns modelled
  infections by year and age group (`infections_by_age`).
* DTP booster doses. Diphtheria and pertussis now give the booster doses in the country's latest WHO schedule as
  doses 4 to 6 after the primary series (`dtp_boosters = TRUE`, the default; `FALSE` gives the primary series only,
  as in 0.2.0). Each booster adds two vaccination strata, so the odin model is unchanged.
  * Boosters are the scheduled ages after the first three, before age 18 (adult, pregnancy, travel and catch-up doses
    are excluded). For pertussis only boosters with pertussis antigen count (DTwP, DTaP, Tdap), not Td or DT.
  * Coverage is the WHO 4th to 6th diphtheria-containing dose. These data start in 2018, so before then each
    booster's coverage is the same share of DTP3 as in its first years of data, from `booster_since` (default 1980).
    A booster with no coverage data is left out (the United States reports only the 4th dose), and a reported
    coverage of exactly 0 is treated as missing (the United Kingdom's teenage booster is 0 in 2022 and 2023).
  * Boosters use the full-schedule row of the vaccine table (diphtheria 6, pertussis 5).
  * In the 13 JICVP settings (state at the start of 2025), diphtheria R falls where the schedule has boosters: United
    Kingdom 1.90 to 1.78, Palestine 1.68 to 1.45, Guatemala 1.83 to 1.73; effective susceptibility among 20 to 59
    year olds falls by 1 to 23 points. Six settings have no boosters in their WHO schedule and are unchanged.
    Diphtheria R is still above 1 in most settings, which is for the serosurvey fits to resolve.
* Whole-cell pertussis vaccine. The pertussis rows of the vaccine table are from studies of acellular vaccine. New
  rows tagged `DTwP` give a whole-cell primary series the same protection and twice the waning durations (8 and 16
  years against 4 and 8); sources are in `vaccine_protection.xlsx` and `?vaccine_parameters`. These are provisional,
  meant to be estimated. New argument `pertussis_vaccine`: `"schedule"` (default) takes the type from the country's
  WHO schedule, which is one recent snapshot, so the type is applied to every year. Pertussis R stays at 1 (it is
  taken to circulate every year); infections in 2015 to 2024 fall by 2 to 7% in the 13 settings.
* Natural immunity and vaccine waning can be varied for fitting with the existing `custom_disease_parameters`
  (`natural immunity waning period`) and `custom_vaccine_parameters`, both passed through `run_immunity_history()`.

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
  values belong in the table as their own rows. Boosters are not modelled: they need their own strata (with the
  booster row's values) rather than a different mapping.
* Seeded cases are placed by age in proportion to the population without random sampling, so the same inputs give
  the same parameters.
* Windows binaries removed from `src/`.
* Documented that routine doses are given at a constant rate across the whole age group they fall in, so with
  five-year age groups an infant dose is given from birth to age 5 (`?coverage_to_daily_rate`).
* The pkgdown site and repository links point at jameel-institute (`https://jameel-institute.github.io/PREVAIL/`).

## Model equations

* The model no longer outputs `Reff`. It was the unweighted mean of the age groups' row sums of a next-generation
  matrix, not a reproduction number, and the most expensive calculation in each step. Use
  `effective_reproduction_number()` on the model state.
* Ageing is drawn from a binomial distribution and vaccination is stochastic by default (`stochastic_vaccination =
  1`), so whole people move. Before, ageing moved a fixed fraction of each compartment and parts of people were left
  in E and I that could never recover (the binomial draws truncate them).
* The force of infection on age group `i` uses the infectious share of each contacted age group `j`
  (`sum_j C[i, j] I_j / N_j`). The contact matrix is a per-person mixing matrix (rows sum to one), but the model
  divided by the population of the susceptible's own age group (`N_i`), so small age groups (the elderly) faced a
  force of infection several times too high and large ones too low. The reproduction number is unchanged (the two
  next-generation matrices have the same eigenvalue); who gets infected is not.
* Susceptibles in the long-term stratum of a dose wane to unvaccinated, as the other compartments already did and
  as the model's comments describe. Before, S alone went from the long-term stratum of dose `d` to the short-term
  stratum of dose `d - 1`, which has more protection (measles 93% after 90%). This only matters where vaccine
  protection wanes (diphtheria and pertussis by default).
* Maternal protection works. It was applied to the infectiousness of infants rather than their susceptibility, and
  the share of mothers vaccinated or immune was read at the infant age group (always zero), so it did nothing. It
  now reduces the force of infection on age groups up to `age_maternal_protection_ends` by
  `protection_weight_vacc` times the share of women of reproductive age vaccinated and never infected, plus
  `protection_weight_rec` times the share ever infected. For measles in five-year age groups that is up to about
  15% off the 0-4s' force of infection (protection to 9 months, so 15% of the age group).
  `effective_reproduction_number()` takes the same reduction (`maternal`), and `summarise_immunity()` passes it in.
* Seeded infections go into E (so they take the severe/non-severe split) rather than straight into I, and are placed
  across ages and vaccination strata in proportion to effective susceptibles on the day, rather than in the
  unvaccinated stratum of each age group in proportion to population and capped at who was there. Under
  `"reported_cases_only"` many reported cases could not be placed before (355,000 of the United Kingdom's in the
  1980s). `new_case` counts
  seeded infections when they become infectious, like any other infection. The placement is a binomial draw for
  each age group and stratum (odin has no multinomial), so the number seeded is exact on average and in a
  deterministic run, and within sampling noise in any one stochastic run.

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
