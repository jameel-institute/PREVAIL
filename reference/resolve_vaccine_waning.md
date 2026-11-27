# Should Vaccine Protection Wane?

Resolves the \`vaccine_waning\` argument of the wrappers. \`"default"\`
switches waning off for measles and uses the vaccine parameter table for
every other disease.

## Usage

``` r
resolve_vaccine_waning(vaccine_waning, disease)
```

## Arguments

- vaccine_waning:

  \`"default"\`, \`"table"\`, \`"none"\`, or a logical.

- disease:

  Disease name.

## Value

Logical.

## Details

The table has one-dose measles protection falling from 93% to 85% after
15 years and to nothing after a further 25. Estimates of the waning of
measles vaccine protection are far slower, about 0.04% a year (Robert et
al., Lancet Public Health 2024). The table's values did not matter while
transmission was switched off from 1980, but with transmission on they
make measles endemic among adults in high-coverage settings.
