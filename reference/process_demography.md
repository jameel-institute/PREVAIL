# Prepare Demographic Inputs for a Transmission Model

This function processes raw demographic data—covering migration,
fertility, mortality, population counts, and age-specific contact
matrices—into a structured format suitable for use in an age-,
vaccination-, and risk-structured infectious disease transmission model.

## Usage

``` r
process_demography(
  migration,
  fertility,
  mortality,
  population_all,
  population_female,
  contact_matricies,
  iso,
  year_start = "",
  year_end = "",
  n_age = 1,
  number_of_vaccines = 0,
  n_risk = 1
)
```

## Arguments

- migration:

  A data frame with net migration rates by year and country.

- fertility:

  A data frame with fertility rates by single year of age (15–49) and
  year.

- mortality:

  A data frame with mortality counts by single year of age (0–100) and
  year.

- population_all:

  A data frame of total population counts by single year of age (0–100)
  and year.

- population_female:

  A data frame of female population counts by single year of age (15–49)
  and year.

- contact_matricies:

  A named list of 16x16 contact matrices by country ISO3 code.

- iso:

  A three-letter ISO country code.

- year_start:

  First year to include.

- year_end:

  Final year to include.

- n_age:

  Number of collapsed age bins to use in the model.

- number_of_vaccines:

  Number of vaccine doses considered.

- n_risk:

  Number of risk strata in the model.

## Value

A named list of processed demographic inputs.

## Details

The function uses tidyverse conventions and assumes consistent naming of
age columns (e.g., \`x0\` to \`x100\` for all population counts).
