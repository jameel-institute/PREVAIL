# Prepare Model Inputs for an Infectious Disease Transmission Model

This wrapper function prepares demographic, case, and vaccination data
for use in an age-, vaccination-, and risk-structured infectious disease
model. It processes each input type using internal helper functions and
returns a fully structured list.

## Usage

``` r
prepare_model_inputs(
  migration,
  fertility,
  mortality,
  population_all,
  population_female,
  iso,
  disease_data,
  disease,
  vaccination_data_routine,
  vaccination_data_sia,
  vaccine,
  contact_matricies,
  year_start = "",
  year_end = "",
  n_age = 1,
  n_risk = 1,
  coverage_source = "wuenic",
  boosters = NULL
)
```

## Arguments

- migration:

  A data frame of net migration rates by year and country.

- fertility:

  A data frame of fertility rates by age and year.

- mortality:

  A data frame of mortality counts by age and year.

- population_all:

  A data frame of total population counts by age and year.

- population_female:

  A data frame of female population counts by age and year.

- iso:

  A 3-letter ISO country code for filtering the data.

- disease_data:

  A data frame of WHO-reported disease cases across countries and years.

- disease:

  A string indicating the disease of interest (e.g., "measles").

- vaccination_data_routine:

  Routine immunization data including coverage, population, antigen,
  etc.

- vaccination_data_sia:

  Supplementary immunization activity (SIA) coverage data.

- vaccine:

  A string specifying the vaccine of interest.

- contact_matricies:

  A named list of contact matrices by ISO code.

- year_start:

  First year to include (default: from migration data).

- year_end:

  Final year to include (default: from migration data).

- n_age:

  Number of age groups in the model.

- n_risk:

  Number of risk groups in the model.

- coverage_source:

  Passed to \[process_vaccination_routine()\].

- boosters:

  DTP booster doses to model, from \[dtp_booster_schedule()\] (\`NULL\`
  or zero rows for none). Each adds a dose after the primary series,
  with its coverage from the WHO booster dose given in
  \`coverage_dose\`.

## Value

A named list containing:

- processed_demographic_data:

  Output from \`process_demography()\`.

- processed_case_data:

  Filtered disease case data (years with at least one reported case).

- processed_case_reports:

  As \`processed_case_data\` but keeping years with zero reported cases.

- processed_vaccination_data:

  Cleaned and summarized routine vaccination data.

- processed_vaccination_sia:

  Filtered SIA data for the specified vaccine.

- demographic_plots:

  (Placeholder) Plot object to visualize processed inputs.

## Details

This function calls internal processing utilities:
\`process_demography()\`, \`process_prior_cases()\`,
\`process_vaccination_routine()\`, \`process_vaccination_sia()\`.
