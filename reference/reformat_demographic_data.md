# Reformat Demographic Data to Model Structure

Expands, standardizes, and fills demographic data for use in the PREVAIL
transmission model. Handles age expansion, year grid completion, and
flexible missing data imputation (mean, median, or nearest neighbor).

## Usage

``` r
reformat_demographic_data(
  custom_data,
  age_required = NA,
  years = NULL,
  iso = "custom",
  value_allocation = c("maintain", "split"),
  fill_method = c("none", "closest", "mean", "median")
)
```

## Arguments

- custom_data:

  A data frame containing demographic data. Must include `year` and
  `value`. Optionally includes `age`, `area`, and `iso3`.

- age_required:

  Vector of required ages. If `NA`, age expansion is skipped.

- years:

  Vector of years to ensure are present (default: unique years in data).

- iso:

  Character string for area/iso3 if missing. Default is "custom".

- value_allocation:

  For group age ranges: `"maintain"` (default, keep value per group), or
  `"split"` (divide value evenly across ages).

- fill_method:

  Method for filling missing values: `"none"` (leave as NA), `"closest"`
  (fill by nearest year/age, or nearest year for unstratified), `"mean"`
  (fill by group-year mean), or `"median"` (by group-year median).
  Default is "none".

## Value

A tidy data frame: wide format if age present, else long format.

## Examples

``` r
df <- data.frame(year = 2000:2002, value = c(100, 110, 120))
reformat_demographic_data(df, age_required = 0:4, years = 2000:2005, fill_method = "closest")
#> # A tibble: 6 × 8
#>   area   iso3    year    x0    x1    x2    x3    x4
#>   <chr>  <chr>  <int> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 custom custom  2000   100   100   100   100   100
#> 2 custom custom  2001   110   110   110   110   110
#> 3 custom custom  2002   120   120   120   120   120
#> 4 custom custom  2003   120   120   120   120   120
#> 5 custom custom  2004   120   120   120   120   120
#> 6 custom custom  2005   120   120   120   120   120
```
