# Generate Summary Plots and Susceptibility Profiles

This function processes model output and generates: 1. A time-series
plot of selected states (weekly only). 2. A stacked bar chart of
age-specific susceptibility profiles (annual only). 3. A line chart of
vaccination coverage over time. 4. A long-format \`data.table\` with
stratified susceptibility proportions. 5. A cumulative case time-series
plot.

## Usage

``` r
summary_plots(model_run, params)
```

## Arguments

- model_run:

  A \`data.frame\` or \`data.table\` in long format, including columns
  \`time\`, \`state\`, \`value\`, \`age\`, \`risk\`, \`vaccination\`,
  and \`run\`.

- params:

  A named list of model input parameters, including: -
  \`input_data\$year_start\`: Start year of the simulation ("" uses
  1950). - \`input_data\$age_breaks\`: Age breakpoints as a
  semicolon-separated string.

## Value

A named list containing:

- select_state_plot:

  A \`ggplot2\` object: time-series plot of selected model states by
  week.

- susceptibility_plot:

  A \`ggplot2\` object: latest year’s age-specific susceptibility
  profile.

- vaccination_coverage_plot:

  A \`ggplot2\` object: line chart showing population-level vaccine
  coverage over time.

- cumulative_case_plot:

  A \`ggplot2\` object: cumulative case counts with uncertainty ribbons.

- susceptibility_data:

  A \`data.table\`: weekly susceptibility proportions by status and
  time.
