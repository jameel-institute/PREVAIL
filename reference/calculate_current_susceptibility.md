# Calculate Final Susceptibility and Recovered States

Extracts the final timepoint values for each compartment and converts
them into arrays suitable for model initialisation. This function
produces the initial susceptible and recovered populations from the
output of a model run.

## Usage

``` r
calculate_current_susceptibility(model_run)
```

## Arguments

- model_run:

  A long-format \`data.frame\` or \`data.table\` of model output
  including columns \`time\`, \`state\`, \`age\`, \`vaccination\`,
  \`risk\`, and \`value\`.

## Value

A named list with:

- S0:

  An array of susceptible individuals by age, vaccination, and risk
  group.

- Rpop0:

  An array of recovered individuals (all non-susceptible states) by age,
  vaccination, and risk group.
