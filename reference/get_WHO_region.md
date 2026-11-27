# Assign WHO Region to ISO3 Country Codes

Maps ISO3 country codes to their corresponding WHO region code:

- **AFR**: Africa

- **AMR**: Americas

- **SEAR**: South-East Asia

- **EUR**: Europe

- **EMR**: Eastern Mediterranean

- **WPR**: Western Pacific

## Usage

``` r
get_WHO_region(iso3cs)
```

## Arguments

- iso3cs:

  Character vector of ISO3 country codes.

## Value

Character vector of WHO region codes (AFR, AMR, SEAR, EUR, EMR, WPR, or
NA).

## Details

If a code is not found, returns `NA` and issues a warning.

## Examples

``` r
get_WHO_region(c("KEN", "FRA", "IND", "XYZ"))
#> Warning: Unable to get assign the following iso3cs a WHO region: XYZ
#> [1] "AFR"  "EUR"  "SEAR" NA    
```
