# Calculate Aging Rates, Reproductive Parameters, and Maternal Protection

Computes aging rates, reproductive age group indices, reproductive
weights for birth assignments, and maternal protection end parameters
for both single-year and aggregated age bands.

## Usage

``` r
calc_aging_and_repro(
  aggregate_age,
  new_age_breaks,
  inputs,
  default_inputs,
  disease_param
)
```

## Arguments

- aggregate_age:

  Logical; if \`TRUE\`, ages are aggregated into \`new_age_breaks\`.

- new_age_breaks:

  Numeric vector specifying the breakpoints for aggregated age groups.

- inputs:

  List containing demographic inputs: - \`N0\`: Initial population
  structure (must contain \`dim1\`). - \`crude_death\`: Crude death
  rates (must contain \`dim3\`).

- default_inputs:

  List containing default population data: - \`population\`: Data.frame
  with columns \`dim1\`, \`dim2\`, and \`value\`.

- disease_param:

  Data.frame containing disease-specific parameters, including maternal
  protection duration.

## Value

A list containing: - \`aging_rate\`: Numeric vector of aging rates (per
day). - \`repro_low\`: Integer index of the lowest reproductive age
group. - \`repro_high\`: Integer index of the highest reproductive age
group. - \`repro_weight\`: Data.frame (\`dim1\`, \`dim2\`, \`value\`) of
reproductive weights per age group. - \`maternal_prot_end\`: Integer
index indicating age group at which maternal protection ends. -
\`maternal_prot_weight\`: Numeric proportion reflecting partial maternal
protection coverage within the final age group.

## Details

Reproductive ages are defined as 15–49 years inclusive. When ages are
aggregated, the function calculates overlapping proportions of these age
bands with the reproductive window. Maternal protection duration is
dynamically assigned to the appropriate age group based on provided
parameters.
