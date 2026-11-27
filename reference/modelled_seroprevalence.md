# Modelled Seroprevalence for Serosurvey Age Bands

Converts immunity by model age group from \[run_immunity_history()\]
into the share expected to test seropositive in each age band of a
serosurvey taken at the end of the run.

## Usage

``` r
modelled_seroprevalence(
  history,
  age_min,
  age_max = NA,
  sensitivity = 1,
  specificity = 1,
  vaccine_seropositive = 1,
  maternal = FALSE
)
```

## Arguments

- history:

  Output of \[run_immunity_history()\] with \`year_end\` the survey year
  (for \`maternal = TRUE\` it needs \`keep_params = TRUE\`).

- age_min, age_max:

  Lower and upper age of each band in years, with the upper limit
  inclusive as surveys report it (\`5\` and \`9\` for "5-9 years"); use
  \`NA\` for an open top band. Fractional ages are allowed (months /
  12).

- sensitivity, specificity:

  Assay sensitivity and specificity. Default 1.

- vaccine_seropositive:

  Share of vaccine-protected people who test positive. Default 1.

- maternal:

  Logical; count maternal antibody in infants as seropositive? Default
  \`FALSE\`.

## Value

Numeric vector of expected seropositive shares, one per band.

## Details

The true seropositive share in a model age group is \$\$p =
\textrm{immune\\infection} + v \cdot \textrm{immune\\vaccine} + m \cdot
\textrm{susceptible}\$\$ where \`v\` (\`vaccine_seropositive\`) is the
share of vaccine-protected people who still have detectable antibody and
\`m\` is maternal protection (only when \`maternal = TRUE\`), counted as
antibody among those not otherwise immune. Model age groups are weighted
by population and by how much of each group the band covers, taking ages
to be spread evenly within a group. The test then gives \$\$p\_{obs} =
\textrm{sensitivity} \cdot p + (1 - \textrm{specificity}) (1 - p).\$\$

## Examples

``` r
h <- list(by_age = data.frame(population = c(100, 100), immune_infection = c(0.1, 0.5),
                              immune_vaccine = c(0.6, 0.4), susceptible = c(0.3, 0.1)),
          age_breaks = "0;5;Inf")
modelled_seroprevalence(h, age_min = c(0, 2), age_max = c(4, 9))
#> [1] 0.700 0.825
```
