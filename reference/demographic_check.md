# Compare Model Population to Population Reference Estimates

This function compares the population from the model output
(\`model_run\`) to UN World Population Prospects (reference population)
data. It returns:

## Usage

``` r
demographic_check(reference_population, model_run, age_breaks)
```

## Arguments

- reference_population:

  A matrix or data frame of reference population data, where each column
  is a year and each row is an age group. Values should be in thousands.
  Typically from
  [`data_load_process_wrapper`](https://jameel-institute.github.io/PREVAIL/reference/data_load_process_wrapper.md).

- model_run:

  A data frame of stratified model output, including \`time\`, \`age\`,
  \`state\`, \`value\`, \`vaccination\`, and \`risk\`. Typically from
  [`summary_plots`](https://jameel-institute.github.io/PREVAIL/reference/summary_plots.md).

- age_breaks:

  A numeric vector of age group breakpoints (e.g., \`c(0, 5, 10, ...,
  80, Inf)\`).

## Value

A named list with:

- population_plot:

  A \`ggplot\` object comparing total population by year.

- age_breakdown_plot:

  A \`ggplot\` object comparing age distribution in the final year.

## Details

1\. A line plot comparing total population over time. 2. A bar plot
comparing the age distribution in the final year.

## See also

[`age_breaks_to_labels`](https://jameel-institute.github.io/PREVAIL/reference/age_breaks_to_labels.md)
for converting age breaks to labels.
