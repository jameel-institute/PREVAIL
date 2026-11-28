# Use the Whole-Cell or Acellular Pertussis Rows of the Vaccine Table

The vaccine parameter table's pertussis rows tagged \`DTP\` come from
studies of acellular vaccine (Witt et al. 2012, Klein et al. 2012). Rows
tagged \`DTwP\` replace the primary-series rows for whole-cell vaccine.
Booster rows are shared. Rows for other vaccines (including custom rows)
are left as they are.

## Usage

``` r
select_pertussis_vaccine(
  vaccine_parameters,
  type = c("acellular", "whole_cell")
)
```

## Arguments

- vaccine_parameters:

  Vaccine parameter table for pertussis.

- type:

  \`"acellular"\` or \`"whole_cell"\`.

## Value

The table with one set of primary-series rows.
