# WHO Supplementary Immunization Activities (SIA) Vaccination Data

A dataset containing details of Supplementary Immunization Activities
(SIAs) compiled by the World Health Organization (WHO). This data
records vaccine campaign activities, coverage, and targeted cohorts for
various diseases across countries.

## Usage

``` r
WHO_vaccination_sia
```

## Format

A data frame with the following columns:

- `d_v_a_id`:

  Numeric. Vaccine identifier code.

- `country`:

  Character. ISO 3-letter country code.

- `year`:

  Numeric. Year when the vaccination activity occurred.

- `age`:

  Numeric. Targeted age group for vaccination.

- `fvps`:

  Numeric. Number of fully vaccinated persons.

- `cohort`:

  Numeric. Total population cohort targeted for vaccination.

- `coverage`:

  Numeric. Vaccination coverage as a proportion of the targeted cohort.

- `source`:

  Character. Source of vaccination data (e.g., SIA).

- `disease`:

  Character. Name of the targeted disease.

- `vaccine`:

  Character. Vaccine used in the campaign.

- `activity`:

  Character. Type of vaccination activity (e.g., campaign, catch-up).

## Source

World Health Organization (WHO) SIA database.

## Examples

``` r
head(WHO_vaccination_sia)
#>   d_v_a_id country year age     fvps   cohort    coverage source disease
#> 1        5     IND 2012   1 74840.30 25328535 0.002954782    sia      je
#> 2        5     IND 2012   2 74981.56 25376345 0.002954782    sia      je
#> 3        5     IND 2012   3 74685.04 25275990 0.002954782    sia      je
#> 4        5     IND 2012   4 74678.17 25273667 0.002954782    sia      je
#> 5        5     IND 2012   5 74835.44 25326891 0.002954782    sia      je
#> 6        5     IND 2012   6 75597.88 25584928 0.002954782    sia      je
#>   vaccine activity
#> 1      je campaign
#> 2      je campaign
#> 3      je campaign
#> 4      je campaign
#> 5      je campaign
#> 6      je campaign
```
