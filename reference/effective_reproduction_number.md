# Effective Reproduction Number from a Model State

Computes the effective reproduction number as the dominant eigenvalue of
the next-generation matrix implied by the model's force of infection.

## Usage

``` r
effective_reproduction_number(
  S,
  N,
  protection,
  contact_matrix,
  R0,
  maternal = 0
)
```

## Arguments

- S:

  Susceptible population by age group and vaccination stratum (a matrix,
  or an array with a third dimension for risk groups, which is summed
  over).

- N:

  Total population by age group.

- protection:

  Vaccine protection by age group and vaccination stratum (the model's
  \`age_vaccination_beta_modifier\`), with the same dimensions as \`S\`,
  or a vector with one value per stratum.

- contact_matrix:

  The model's contact matrix.

- R0:

  Basic reproduction number.

- maternal:

  Reduction in susceptibility from maternal antibodies by age group (a
  single number or one value per age group; see
  \[maternal_protection()\]). Default 0.

## Value

The effective reproduction number (a single number).

## Details

In the model someone of age \`j\` and vaccination stratum \`w\` infects,
over their infectious period, \$\$R_0 (1 - m_w) C\_{ij} S\_{iv} (1 -
m_v) / N_j\$\$ people of age \`i\` and stratum \`v\`, where \`m\` is
vaccine protection (which reduces both susceptibility and
infectiousness), \`C\` the contact matrix, \`S\` the susceptible
population and \`N_j\` the population of age group \`j\`. Collapsing
over strata, the reproduction number is the dominant eigenvalue of
\$\$M\_{ij} = R_0 C\_{ij} e_j, \quad e_j = \sum_v S\_{jv} (1 - m_v)^2 /
N_j.\$\$ (Up to 0.2.0 the model divided by \`N_i\` instead, which gives
a similar matrix with the same eigenvalue.) Maternal antibodies reduce
the susceptibility of the youngest age groups by \`maternal\`, which
multiplies \`e_j\`.

The model itself does not output a reproduction number. Up to 0.2.0 it
had a \`Reff\` output, the unweighted mean over age groups of the row
sums of a related matrix, which is not a reproduction number (it read
about 0.5 where measles is endemic).

## Examples

``` r
# a fully susceptible, unvaccinated population has an effective reproduction number of R0
C <- matrix(1 / 3, 3, 3)
effective_reproduction_number(S = matrix(100, 3, 1), N = rep(100, 3), protection = 0,
                              contact_matrix = C, R0 = 15)
#> [1] 15
```
