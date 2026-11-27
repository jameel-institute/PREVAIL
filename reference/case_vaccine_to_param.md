# Format Case and Vaccination Parameters for Model Input (Including Pre-1980)

Wrapper function that prepares all time-varying parameters for use in an
age-, vaccine-, and risk-structured infectious disease model, including
extrapolated vaccination coverage prior to 1980 if available.

## Usage

``` r
case_vaccine_to_param(
  demog_data,
  processed_vaccination,
  processed_vaccination_sia,
  processed_case,
  vaccination_schedule,
  vaccination_pre1980,
  vaccine_parameters,
  disease_parameters,
  custom_routine_vaccination = NA,
  custom_sia_vaccination = NA,
  disease = NULL,
  R0 = 1,
  processed_case_reports = processed_case,
  transmission_history = "circulating_years",
  circulation_threshold = 2,
  reporting_fraction = 1,
  seed_floor = 10,
  coverage_accuracy = 1,
  vaccine_waning = "default"
)
```

## Arguments

- demog_data:

  Output list from \`process_demography()\`.

- processed_vaccination:

  Data frame of routine vaccine coverage.

- processed_vaccination_sia:

  Data frame of SIA coverage.

- processed_case:

  WHO case reports processed for the country of interest (years with
  cases).

- vaccination_schedule:

  Full WHO vaccine schedule data frame.

- vaccination_pre1980:

  Data frame of historical vaccination introduction assumptions.

- vaccine_parameters:

  Data frame of vaccination parameters.

- disease_parameters:

  Data frame of disease parameters.

- custom_routine_vaccination:

  Data frame or NA indicating custom routine vaccination.

- custom_sia_vaccination:

  Data frame or NA indicating custom sia vaccination.

- disease:

  Disease name. If \`NULL\` it is taken from the case data.

- R0:

  Basic reproduction number while transmission is on.

- processed_case_reports:

  WHO case reports including years with zero cases. Defaults to
  \`processed_case\`.

- transmission_history, circulation_threshold, reporting_fraction,
  seed_floor:

  Passed to \[build_transmission_history()\].

- coverage_accuracy:

  Multiplier on the odds of vaccination (see
  \[coverage_to_daily_rate()\]).

- vaccine_waning:

  Passed to \[resolve_vaccine_waning()\].

## Value

A named list of parameters including the routine coverage and dose ages,
SIA coverage, protection and waning by stratum, the time-varying R0 and
the seeding inputs.
