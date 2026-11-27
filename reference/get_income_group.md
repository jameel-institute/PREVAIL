# Assign World Bank Income Group from ISO3 Country Codes

Maps ISO3 country codes to World Bank income group:

- **HIC**: High-Income Countries

- **UMIC**: Upper-Middle-Income Countries

- **LMIC**: Lower-Middle-Income Countries

- **LIC**: Low-Income Countries

## Usage

``` r
get_income_group(iso3cs)
```

## Arguments

- iso3cs:

  Character vector of ISO3 country codes.

## Value

Ordered factor of income group, with levels
`c("HIC", "UMIC", "LMIC", "LIC")`.

## Details

Returns an ordered factor with levels `c("HIC", "UMIC", "LMIC", "LIC")`.
If a code is not found, returns `NA` and issues a warning.

## Examples

``` r
get_income_group(c("KEN", "FRA", "IND", "XXX"))
#> Warning: Unable to get assign the following iso3cs an income group: XXX
#> [1] LMIC HIC  LMIC <NA>
#> Levels: HIC < UMIC < LMIC < LIC
```
