# Whole-Cell or Acellular Pertussis Vaccine

Reads the type of pertussis vaccine used for the primary series from a
country's latest WHO schedule: whole-cell if any infant DTP product
given in the first year of life is whole-cell (DTwP), acellular
otherwise. The schedule data are one recent snapshot, so the type found
is applied to every year; many high-income countries used whole-cell
vaccine before moving to acellular in the 1990s and 2000s.

## Usage

``` r
pertussis_vaccine_type(vaccination_schedule, iso)
```

## Arguments

- vaccination_schedule:

  WHO schedule data.

- iso:

  Country code.

## Value

\`"whole_cell"\` or \`"acellular"\`.
