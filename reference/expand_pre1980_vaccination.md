# Expand Pre-1980 Routine Vaccination Coverage

Uses historical assumptions to estimate vaccination coverage prior to
the first observed year. Applies linear interpolation from an assumed
introduction year up to the first observed coverage year.

## Usage

``` r
expand_pre1980_vaccination(
  processed_vaccination,
  vaccination_pre1980,
  disease,
  iso
)
```

## Arguments

- processed_vaccination:

  Routine coverage data (to determine first year and vaccine).

- vaccination_pre1980:

  Data frame of historical vaccine assumptions (intro year, starting
  coverage).

- disease:

  Disease name (lowercase) to match.

- iso:

  3-letter ISO country code.

## Value

A data frame of additional rows to prepend to coverage time series.
