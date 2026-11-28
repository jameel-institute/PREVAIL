# DTP Booster Doses from the WHO Schedule

Finds the booster doses of diphtheria- or pertussis-containing vaccine
in a country's routine schedule, so that the model can give them as
doses 4, 5 and 6 after the three-dose primary series.

## Usage

``` r
dtp_booster_schedule(
  vaccination_schedule,
  iso,
  disease,
  routine_vaccination = NULL
)
```

## Arguments

- vaccination_schedule:

  WHO schedule data (all countries or one).

- iso:

  Country code.

- disease:

  \`"diphtheria"\` or \`"pertussis"\`.

- routine_vaccination:

  WHO routine coverage data, used to drop boosters without coverage.
  \`NULL\` keeps all.

## Value

A data frame with one row per modelled booster: \`dose\` (4, 5, 6),
\`age\` (years), \`pertussis\` (logical), \`coverage_dose\` and
\`vaccine_codes\`. Zero rows if the schedule has no boosters.

## Details

The schedule is the latest one in the data for the country. Every
diphtheria-containing product counts (infant combinations, DT, the
school-age Td and Tdap boosters), except doses for adults, pregnant
women, travellers or catch-up. The first three distinct ages are the
primary series, and each later distinct age before 18 years is a
booster, up to three. A booster protects against pertussis only if a
product given at that age contains pertussis antigen (DTwP, DTaP, Tdap):
a school-age Td booster boosts diphtheria but not pertussis.

WHO reports booster coverage as the 4th, 5th and 6th
diphtheria-containing dose, so the \`coverage_dose\` of each booster is
its rank among the diphtheria boosters (4, 5 or 6), whichever disease is
modelled. A booster whose WHO dose has no coverage data for the country
is left out (the United States, for example, reports only the 4th), as
it would otherwise add strata that nobody enters.
