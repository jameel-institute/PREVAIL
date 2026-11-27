# Reformat Custom Case Data for Model Input

Adds required columns to custom case data to align with internal
formatting expectations for disease modeling.

## Usage

``` r
reformat_cases(custom_data, iso, disease)
```

## Arguments

- custom_data:

  A data frame of user-supplied case data.

- iso:

  Character string; the 3-letter ISO country code (e.g., "ETH").

- disease:

  Character string; the disease name (e.g., "measles").

## Value

A data frame with standardized columns: `iso3`, `name`, `disease_short`,
and `disease_description`.

## Examples

``` r
reformat_cases(data.frame(year = 2000:2002, value = c(100, 120, 80)), "KEN", "measles")
#>   year value iso3 name disease_short disease_description
#> 1 2000   100  KEN  KEN       measles             measles
#> 2 2001   120  KEN  KEN       measles             measles
#> 3 2002    80  KEN  KEN       measles             measles
```
