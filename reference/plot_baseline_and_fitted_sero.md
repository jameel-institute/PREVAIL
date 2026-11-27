# Plot Model Seropositivity: Baseline vs Fitted vs Data

Simulates the model using provided parameters and compares baseline and
fitted outputs for seropositivity against observed data. Returns a
faceted ggplot by age group.

## Usage

``` r
plot_baseline_and_fitted_sero(
  param_list,
  compare_data = serodata,
  n_particles = n_particles,
  n_groups = 2
)
```

## Arguments

- param_list:

  A named list of model parameters, as produced by
  [`custom_data_process_wrapper`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md).

- compare_data:

  A data.frame of serological observations with columns: `time`
  (numeric) and `serosurvey` (list-column of numeric vectors by age).
  Default is `serodata`.

- n_particles:

  Number of particles to use in the dust system (default uses
  \`n_particles\` from calling environment).

- n_groups:

  Number of particle groups for simulation (default 2: baseline and
  fitted).

## Value

A `ggplot2` object showing seropositivity over time by age group, with
model baseline, fitted, and observed data overlaid.
