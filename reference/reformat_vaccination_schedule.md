# Reformat Vaccination Schedule Data

Adds required columns and renames fields for a custom vaccination
schedule, formatting for PREVAIL model input.

## Usage

``` r
reformat_vaccination_schedule(custom_data, disease = "custom", iso = "custom")
```

## Arguments

- custom_data:

  Data frame of custom vaccination schedule (must include columns `age`
  and `dose`).

- disease:

  Character string, name of the disease (default: "custom").

- iso:

  Character string, 3-letter ISO code (default: "custom").

## Value

A data frame with required columns and standardised names for model
input.
