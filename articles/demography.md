# Customising demography

## Introduction

This vignette introduces how demographic processes are represented and
customized in the PREVAIL model.

Demography is a critical foundation for infectious disease models like
PREVAIL because the underlying population structure directly shapes both
current immunity profiles and future epidemic projections. Age
distribution, birth rates, death rates, and migration all influence how
susceptible, immune, and at-risk populations evolve over time. Just as
importantly, demographic structure determines the configuration of
contact matrices, which define how different age groups interact and
transmit infection within the population. Accurately capturing these
dynamics allows the model to reflect realistic patterns of immunity
buildup, population turnover, and the flow of infection between groups.
This is especially important for long-term projections or settings with
rapid demographic change, where shifts in both population structure and
contact patterns can substantially alter the risk of outbreaks and the
effectiveness of interventions.

While the model has built in data to handle each of these aspects, if
the user has their own data we can flexibly integrate this into the
model design. This hopefully allows the user to end up with better
estimates of population level immunity, and the impact of different
scenarios. We explain how users can define and modify the age structure
(from single-year to multi-year age groups), specify age-specific or
overall rates for migration, deaths, and births, and contact matricies.
Each of these have substantial implications for simulation outputs. By
the end of this section, you will be able to flexibly adapt demographic
assumptions—such as age groupings, population movement, and vital
rates—to match your data sources or scenario needs, ensuring that model
results accurately reflect your setting of interest.

## 1. Prepare your custom data

Firstly we need to load our required packages, we’re using the
**pacman** package here, which will also install these packages if
missing.

``` r

#If pacman is not already present, install
if(!require("pacman")) install.packages("pacman")

#Install missing packages, and load 
pacman::p_load(
  PREVAIL,
  tidyverse
)
```

To use our own custom data, we need to make sure that it is in the
format required. This will depend on whether it is a parameter that is
age *independent* (`migration`) or age *dependent* (`fertility`,
`mortality`, `population`).

For parameters that are age *independent*, we only require a data.frame
with two columns, `year` and `value`.

``` r

custom_migration_df <- data.frame(
  year = 1950:2023,
  value = sample(x = -5:5, size = 74, replace = TRUE)
)

head(custom_migration_df)
#>   year value
#> 1 1950     1
#> 2 1951    -1
#> 3 1952     0
#> 4 1953    -2
#> 5 1954     0
#> 6 1955     3
```

For parameters that are age *dependent*, we can also include a column
called `age` for age specific values. However, if this information is
missing, then we can auto-fill it later.

``` r

custom_mortality_df <- expand.grid(
  year = 1950:2023,
  age = 0:100
) %>%
  dplyr::group_by(year, age) %>%
  dplyr::mutate(value = sample(0:5, size = 1))

head(custom_mortality_df)
#> # A tibble: 6 × 3
#> # Groups:   year, age [6]
#>    year   age value
#>   <int> <int> <int>
#> 1  1950     0     3
#> 2  1951     0     2
#> 3  1952     0     2
#> 4  1953     0     4
#> 5  1954     0     0
#> 6  1955     0     2
```

This information is expanded within the function
[`custom_data_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md),
which is what we use to incorporate our custom data. This function is
very similar to
[`data_load_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/data_load_process_wrapper.md)
but allows us to customise datasets used, rather than only allowing the
defaults.

#### Reformatting demographic data

Inside of the function
[`custom_data_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md)
is the function
[`reformat_demographic_data()`](https://jameel-institute.github.io/PREVAIL/reference/reformat_demographic_data.md)
which checks our custom data, re-formats, and expands it to the format
expected by the functions that prepare our data and run our model.

The function,
[`reformat_demographic_data()`](https://jameel-institute.github.io/PREVAIL/reference/reformat_demographic_data.md)
has several different approaches to how it deals with missing data,
which in
[`custom_data_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md)
are dependent on the specific dataset it is trying to format. Generally,
it will fill in missing data that is required for the model by using the
closest year and age available. Where no age data is present, it will
use the year value across each age group (no age dependence), and where
no year data is available it will use the closest years values.

This auto-fill applies if we have limited data on years, and limited
data on ages. For example, if we only had data on years 1970 to 2015,
and ages 20-50, then we would still be able to include this.

``` r

custom_mortality <- expand.grid(
  year = 1970:2015,
  age = 20:50
) %>%
  dplyr::group_by(year, age) %>%
  dplyr::mutate(value = sample(0:5, size = 1))

head(custom_mortality)
#> # A tibble: 6 × 3
#> # Groups:   year, age [6]
#>    year   age value
#>   <int> <int> <int>
#> 1  1970    20     5
#> 2  1971    20     5
#> 3  1972    20     5
#> 4  1973    20     0
#> 5  1974    20     1
#> 6  1975    20     2
```

This will also work if you have a range of ages, separated by `-`.

``` r

custom_mortality <- expand.grid(
  year = 1970:2015,
  age = c("20-29", "30-59", "60-100")
) %>%
  dplyr::group_by(year, age) %>%
  dplyr::mutate(value = sample(0:5, size = 1))

head(custom_mortality)
#> # A tibble: 6 × 3
#> # Groups:   year, age [6]
#>    year age   value
#>   <int> <fct> <int>
#> 1  1970 20-29     5
#> 2  1971 20-29     1
#> 3  1972 20-29     2
#> 4  1973 20-29     3
#> 5  1974 20-29     5
#> 6  1975 20-29     4
```

Ages that are not present in the data, but required by the model (those
0-100) will take the values of the nearest age and year.

#### Contact matricies

Contact matricies require a slightly different formatting. They are time
independent in our model, are so do not require a `year` column.
However, they require an `age_from`, `age_to`, and `value` column.

The same logic around auto-filling missing years, and the inclusion of
ranges “-” and how it fills in the values as described previously
applies.

``` r

custom_contact <- expand.grid(
  age_from = c("15-30", "31-50", "50+"),
  age_to = c("15-30", "31-50", "50+")
) %>%
  group_by(age_from, age_to) %>%
  mutate(
    value = pmax(rnorm(1, mean = 3, sd = 1), 0)
  )

head(custom_contact)
#> # A tibble: 6 × 3
#> # Groups:   age_from, age_to [6]
#>   age_from age_to value
#>   <fct>    <fct>  <dbl>
#> 1 15-30    15-30   3.57
#> 2 31-50    15-30   4.19
#> 3 50+      15-30   1.93
#> 4 15-30    31-50   2.47
#> 5 31-50    31-50   3.36
#> 6 50+      31-50   2.97
```

Values are normalized during the parameter smoothing process.

## 2. Customising our demographic parameters

Here we use
[`custom_data_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md)
instead of
[`data_load_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/data_load_process_wrapper.md).
However, the approach is generally the same, as it takes all of the
arguments used in
[`data_load_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/data_load_process_wrapper.md),
and a few others, all of which have a default value of `NA` (which tells
the model to use the inbuilt data).

- custom_migration
- custom_fertility
- custom_mortality
- custom_population
- custom_contact_matricies
- custom_routine_vaccination
- custom_sia_vaccination
- custom_disease_data
- custom_vaccination_schedule
- custom_disease_parameters
- custom_vaccine_parameters

Here we will be focusing on the demographic inputs:

- custom_migration
- custom_fertility
- custom_mortality
- custom_population
- custom_contact_matricies

#### Running the function

To run the model with custom data, you add in your custom data.frame at
the appropriate point. So to run the model with our custom_mortality
data.frame, we would fill in our initial arguments as usual, and then
specify `custom_mortality = custom_mortality_df`.

``` r

custom_params <- custom_data_process_wrapper(
    iso = "GBR",
    disease = "measles",
    R0 = 15,
    custom_mortality = custom_mortality_df
)
```

and if we wanted to run the model with our custom mortality and
migration it would be:

``` r

custom_params <- custom_data_process_wrapper(
    iso = "GBR",
    disease = "measles",
    R0 = 15,
    custom_mortality = custom_mortality_df,
    custom_migration = custom_migration_df
)
```

This provides our custom parameters for use in `model_run()`.

*Note: This function is slower than
[`data_load_process_wrapper()`](https://jameel-institute.github.io/PREVAIL/reference/data_load_process_wrapper.md),
so allow for a longer when running it, especially when you have multiple
custom datasets.*

## 3. Running the model with custom parameters

As described in the vignette, Getting Started with PREVAIL, to run the
model we then just have to supply the parameters required.

``` r

custom_model_run <- run_model_unpack_results(
  params = custom_params,
  no_runs = 1,
  simulation_length = 500
)
```

From this, you can then run the additional plotting functions, extract
current susceptibility and look at onward scenarios as previously
described.
