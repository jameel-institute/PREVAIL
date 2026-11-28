# custom_data_process_wrapper

Load, Process, and Optionally Override All Model Input Data

## Usage

``` r
custom_data_process_wrapper(
  iso,
  disease,
  R0,
  cfr_off = TRUE,
  year_start = "",
  year_end = "",
  WHO_seed_switch = TRUE,
  aggregate_age = TRUE,
  new_age_breaks = c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80,
    Inf),
  transmission_history = c("circulating_years", "reported_cases_only"),
  circulation_threshold = 2,
  reporting_fraction = 1,
  coverage_accuracy = 1,
  vaccine_waning = "default",
  coverage_source = c("wuenic", "median"),
  seed_floor = 10,
  dtp_boosters = TRUE,
  booster_since = 1980,
  pertussis_vaccine = c("schedule", "acellular", "whole_cell"),
  custom_migration = NA,
  custom_fertility = NA,
  custom_mortality = NA,
  custom_population = NA,
  custom_contact_matricies = NA,
  custom_routine_vaccination = NA,
  custom_sia_vaccination = NA,
  custom_disease_data = NA,
  custom_vaccination_schedule = NA,
  custom_disease_parameters = NA,
  custom_vaccine_parameters = NA
)
```

## Arguments

- iso:

  A 3-letter ISO country code identifying the country for analysis
  (e.g., "ETH" for Ethiopia).

- disease:

  A character string specifying the disease of interest (e.g.,
  "measles", "diphtheria", "pertussis").

- R0:

  The basic reproduction number while transmission is on (a single
  number).

- cfr_off:

  Logical; Sets the CFR to zero. Used when calculating current
  susceptibility as prior mortality rates will already include disease
  specific mortality.

- year_start:

  Optional numeric value specifying the first year of the simulation
  window. Default ("") uses the earliest available data year.

- year_end:

  Optional numeric value specifying the last year of the simulation
  window. Default ("") uses the latest available data year.

- WHO_seed_switch:

  Deprecated. \`FALSE\` (transmission throughout, as in 0.1.0) is now
  \`transmission_history = "circulating_years"\` with
  \`circulation_threshold = 0\`, and gives a warning.

- aggregate_age:

  Logical; aggregate data from single-year age groups into custom
  intervals (default TRUE).

- new_age_breaks:

  Numeric vector; breakpoints for age group aggregation. Default is c(0,
  5, ..., Inf).

- transmission_history:

  The assumption about how reported cases relate to true infections over
  the historical period: \`"circulating_years"\` (default),
  \`"reported_cases_only"\` (the assumption 0.1.0 made: case reporting
  is complete). See the section below.

- circulation_threshold:

  Under \`"circulating_years"\`, the reported cases per million people
  per year at or above which the disease is taken to be circulating.
  Default 2; 0 keeps transmission on throughout.

- reporting_fraction:

  Share of infections that are reported, used to scale the seeded
  infections (reported cases divided by this). A single number, or a
  vector named by year. Default 1.

- coverage_accuracy:

  Multiplier on the odds of being vaccinated, to represent true coverage
  differing from reported coverage. 1 (default) takes reported coverage
  at face value; 2 halves the unvaccinated share when coverage is high;
  0.5 roughly doubles it.

- vaccine_waning:

  \`"default"\` (no waning of measles vaccine protection; the vaccine
  parameter table for other diseases), \`"table"\` (the table for every
  disease, as in 0.1.0) or \`"none"\`. See \[resolve_vaccine_waning()\].

- coverage_source:

  \`"wuenic"\` (default) or \`"median"\`; see
  \[process_vaccination_routine()\].

- seed_floor:

  Minimum number of infections introduced each year under
  \`"circulating_years"\`. Default 10.

- dtp_boosters:

  Logical; for diphtheria and pertussis, give the booster doses in the
  country's WHO schedule as doses 4 to 6 (default \`TRUE\`). See
  \[dtp_booster_schedule()\]. \`FALSE\` gives the three-dose primary
  series only, as in 0.2.0.

- booster_since:

  First year boosters are given before their coverage data start in 2018
  (default 1980). See \[backfill_booster_coverage()\].

- pertussis_vaccine:

  \`"schedule"\` (default: whole-cell or acellular as in the country's
  WHO schedule, see \[pertussis_vaccine_type()\]), \`"acellular"\` or
  \`"whole_cell"\`. Sets which primary-series row of the vaccine
  parameter table pertussis uses.

- custom_migration:

  Optional. Data frame to override default migration data.

- custom_fertility:

  Optional. Data frame to override default fertility data.

- custom_mortality:

  Optional. Data frame to override default mortality data.

- custom_population:

  Optional. Data frame to override default population (total) data.

- custom_contact_matricies:

  Optional. Data frame to override default contact matrix data.

- custom_routine_vaccination:

  Optional. Data frame to override default routine vaccination data.

- custom_sia_vaccination:

  Optional. Data frame to override default SIA vaccination data.

- custom_disease_data:

  Optional. Data frame to override default disease surveillance data.

- custom_vaccination_schedule:

  Optional. Data frame to override default vaccination schedule.

- custom_disease_parameters:

  Optional. Data frame to override default disease parameter values.

- custom_vaccine_parameters:

  Optional. Data frame to override default vaccine parameter values.

## Value

A named list containing structured parameters ready for use in the
PREVAIL dynamic transmission model.

## Details

This wrapper function loads internal datasets and processes them into
structured model input parameters for a specified country, disease, and
vaccine. Compared to `data_load_process_wrapper`, this function allows
users to override any internal demographic, vaccination, or disease
dataset with a custom data frame provided through the `custom_*`
arguments. All data are formatted appropriately for use in the dynamic
transmission model within PREVAIL.

Any `custom_*` argument can be used to override the corresponding
internal dataset with a user-supplied data frame. If provided (not NA),
these inputs are reformatted as needed and replace the matching internal
dataset for this model run.

If any `custom_*` argument is provided, it replaces the corresponding
PREVAIL internal dataset for that run. Demographic custom data is
reformatted with
[`reformat_demographic_data`](https://jameel-institute.github.io/PREVAIL/reference/reformat_demographic_data.md)
before use.

Demographic data (UN WPP) end before the present day; the last year with
data is carried forward to \`year_end\`. Routine coverage is likewise
carried forward from its last year with data.

The returned list also carries \`history\`, which is not used by the
model: the reporting assumption, reported cases, seeded infections and
transmission status by year, routine coverage and scheduled age by dose
and year, and the protection and waning assigned to each vaccination
stratum.

## Reporting assumptions

WHO case reports badly under-count infections in most settings, but how
badly is not known. Until reporting fractions are estimated (for example
from seroprevalence surveys) the history has to be run under an
assumption, chosen with \`transmission_history\`:

- \`"circulating_years"\`:

  Reported cases are taken as evidence of whether the disease was
  circulating, not of how many infections there were. Transmission is on
  (at \`R0\`) in every year with at least \`circulation_threshold\`
  reported cases per million people, and in every year before reporting
  starts; it is off in years with fewer. A year with no report keeps the
  status of the year before. Pertussis is treated as circulating in
  every year, because it circulates everywhere whether or not it is
  reported. Reported cases (divided by \`reporting_fraction\`), and
  never fewer than \`seed_floor\` infections, are introduced on the
  first day of each year so that infection can return after fade-out.
  The number of infections is whatever the model implies. With
  \`circulation_threshold = 0\` transmission is on throughout (what
  \`WHO_seed_switch = FALSE\` meant in 0.1.0).

- \`"reported_cases_only"\`:

  Case reporting and reported vaccination are taken as complete.
  Transmission runs at \`R0\` until the first year with a reported case
  and is switched off from then on; after that the only infections are
  the reported cases (divided by \`reporting_fraction\`), introduced on
  the first day of each year. This is the assumption PREVAIL 0.1.0 made,
  with \`reporting_fraction = 1\`.

Seeded infections enter the exposed compartment, placed across ages and
vaccination strata in proportion to the effective number of susceptibles
on the day.

\`reporting_fraction\` is where an estimated reporting level slots in:
seeded infections are the reported cases divided by it. It can be a
single number or a vector named by year (years without a name take the
value of the nearest named year).
