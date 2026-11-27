# Country and Territory ISO3 Codes

A reference dataset of countries and territories used within the PREVAIL
package. This dataset links human-readable location names (e.g.,
"Kenya", "Occupied Palestinian Territory") to their corresponding ISO3
codes (e.g., "KEN", "PSE").

## Usage

``` r
PREVAIL_locations
```

## Format

A data frame with two columns:

- location:

  A character vector containing country or territory names in English.

- iso:

  A 3-letter ISO 3166-1 alpha-3 code as a character vector.

## Source

Internal compilation for use within the PREVAIL framework

## Details

This is typically used for mapping model inputs, internal datasets, and
plotting functions to the correct country code format.

## Examples

``` r
head(PREVAIL_locations)
#>   location iso
#> 1  Burundi BDI
#> 2  Comoros COM
#> 3 Djibouti DJI
#> 4  Eritrea ERI
#> 5 Ethiopia ETH
#> 6    Kenya KEN
PREVAIL_locations[PREVAIL_locations$iso == "KEN", ]
#>   location iso
#> 6    Kenya KEN
```
