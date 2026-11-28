# Reformat Parameter Table for Model Input

Reformats a parameter table for PREVAIL, standardising column names and
units for either disease or vaccine parameters.

## Usage

``` r
reformat_parameters(
  custom_parameters,
  default_parameters,
  disease,
  type = c("disease", "vaccine")
)
```

## Arguments

- custom_parameters:

  Data frame of custom parameters. For vaccine parameters, the columns
  are \`parameter\` (\`"protection"\` or \`"waning"\`), \`duration\`
  (\`"short"\` or \`"long"\`), \`value\` and optionally \`dose\` (a dose
  of the default table, for example 3 for the pertussis primary series).
  A row without a \`dose\` applies to every dose.

- default_parameters:

  Data frame of the default parameters

- disease:

  Character string, name of the disease.

- type:

  One of `"disease"` or `"vaccine"`. Controls formatting logic.

## Value

A data frame with reformatted parameters.
