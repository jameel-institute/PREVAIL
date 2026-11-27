# Unpack Dust Model State Data

Extracts and unpacks state data from a dust model object, handling both
compartmental and non-compartmental states. Compartmental states are
unpacked via \`process_obj()\` and include time and stratifier
dimensions; non-compartmental states (e.g., derived metrics) are
returned as flat records.

## Usage

``` r
unpack_dust2(
  model_system,
  model_object,
  dimension_names,
  which_state_dimensions
)
```

## Arguments

- model_system:

  A \`dust2\` system object with packing info and particle count.

- model_object:

  A model output object returned from \`dust2::dust_system_simulate()\`.

- dimension_names:

  A named list of dimension label vectors (e.g., \`time\`, \`age\`,
  \`vaccination\`, etc.).

- which_state_dimensions:

  A named list mapping state names to dimension label sets.

## Value

A \`data.table\` with unpacked model output, including \`value\`,
\`state\`, \`time\`, and relevant stratifiers.
