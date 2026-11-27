# Maternal Protection of Infants in a Model State

The reduction in susceptibility the model applies to age groups up to
\`age_maternal_protection_ends\`: \`protection_weight_vacc\` times the
share of women of reproductive age who are vaccinated and never
infected, plus \`protection_weight_rec\` times the share ever infected
(capped at 1).

## Usage

``` r
maternal_protection(state, params)
```

## Arguments

- state:

  A list of arrays \`S\`, \`E\`, \`I\`, \`R\`, \`Is\` and \`Rc\` (age by
  stratum by risk group).

- params:

  The parameter list the state was produced with.

## Value

Reduction in susceptibility by age group.
