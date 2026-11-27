# Reformat Custom Vaccination Data for Model Input

Adds required columns to a user-supplied vaccination data frame for
routine vaccination coverage, standardizing column names and values for
use within the PREVAIL package.

## Usage

``` r
reformat_vaccination(custom_data, iso, disease)
```

## Arguments

- custom_data:

  A data.frame or tibble containing at minimum a year and value column.

- iso:

  Three-letter ISO country code.

- disease:

  Disease or vaccine name (character).

## Value

A tibble with required columns: iso3, area, disease,
vaccine_description, vaccination_name.
