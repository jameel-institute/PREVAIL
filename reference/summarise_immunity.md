# Summarise the Immunity of a Model State

Summarises who is susceptible and who is immune, and why, in a model
state.

## Usage

``` r
summarise_immunity(state, params, R0)
```

## Arguments

- state:

  A list of arrays \`S\`, \`E\`, \`I\`, \`R\`, \`Is\` and \`Rc\` (age by
  stratum by risk group), as returned by \`dust2::dust_unpack_state()\`.

- params:

  The parameter list the state was produced with (for the contact matrix
  and vaccine protection).

- R0:

  Basic reproduction number to use for the effective reproduction
  number.

## Value

A list with \`reff\` (see \[effective_reproduction_number()\]),
\`population\`, \`susceptible\` (effective susceptibility as a share of
the population), \`vaccinated\` (share in any vaccinated stratum),
\`infected\` (number currently infected) and \`by_age\`, a data frame
with the shares above for each age group.

## Details

Everyone falls into one of four groups, which sum to one within each age
group:

- \`susceptible_unvaccinated\`:

  Never infected and unvaccinated (or protection fully waned).

- \`susceptible_vaccinated\`:

  Never infected, vaccinated but not protected: the share \`1 - m\` of
  those in a vaccinated stratum with protection \`m\`.

- \`immune_vaccine\`:

  Never infected and protected by vaccination: the share \`m\` of those
  in a vaccinated stratum.

- \`immune_infection\`:

  Infected now or in the past (whether or not vaccinated).

\`susceptible\` is the sum of the first two (effective susceptibility).
