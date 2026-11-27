# Package Parameters for Transmission Model

This function prepares and formats input parameters for an age-,
vaccination-, and risk-structured infectious disease transmission model.
It handles user-specified arrays or default values and returns a
validated, formatted list ready for simulation.

## Usage

``` r
param_packager(
  n_age,
  n_vacc,
  n_risk,
  S0,
  I0 = 0,
  Rpop0 = 0,
  contact_matrix = NULL,
  incubation_rate,
  recovery_rate,
  severe_recovery_rate = NULL,
  prop_severe = 0,
  prop_complications = 0,
  natural_immunity_waning = 0,
  vaccination_coverage,
  tt_vaccination_coverage,
  age_vaccination_beta_modifier = 0,
  short_term_waning = 0,
  long_term_waning = 0,
  R0,
  tt_R0,
  seeded,
  tt_seeded,
  aging_rate,
  simp_birth_death = 0,
  tt_birth_changes,
  tt_death_changes,
  crude_birth,
  crude_death,
  protection_weight_vacc = 0,
  protection_weight_rec = 0,
  age_maternal_protection_ends = 1,
  repro_low = 1,
  repro_high = NULL,
  tt_migration = 0,
  migration_in_number = 0,
  migration_distribution_values = 0,
  migration_represent_current_pop = 0,
  cfr_normal = 0,
  cfr_severe = 0,
  cfr_normal_real = 0,
  cfr_severe_real = 0,
  population,
  female_population,
  repro_weight
)
```

## Arguments

- n_age:

  Number of age groups

- n_vacc:

  Number of vaccination strata

- n_risk:

  Number of risk groups

- S0:

  Initial susceptible population (array or scalar)

- I0:

  Initial infections (array or scalar)

- Rpop0:

  Initial recovered population (array or scalar)

- contact_matrix:

  Contact matrix by age

- incubation_rate:

  Incubation rate (1/duration)

- recovery_rate:

  Recovery rate for mild cases

- severe_recovery_rate:

  Recovery rate for severe cases

- prop_severe:

  Proportion of cases that are severe

- prop_complications:

  Proportion of severe cases with complications

- natural_immunity_waning:

  Waning rate of natural immunity

- vaccination_coverage:

  Array or DF of vaccination coverage

- tt_vaccination_coverage:

  Time points for vaccination coverage

- age_vaccination_beta_modifier:

  Transmission modifier by age/vaccination

- short_term_waning:

  Short-term waning rate by vaccine stratum

- long_term_waning:

  Long-term waning rate by vaccine stratum

- R0:

  Time-varying basic reproduction number

- tt_R0:

  Time points at which R0 changes

- seeded:

  Array or DF of seeded infections

- tt_seeded:

  Time points for seeding

- aging_rate:

  Aging rates between age groups

- simp_birth_death:

  Flag to simplify births and deaths (0/1)

- tt_birth_changes:

  Time points for birth rate changes

- tt_death_changes:

  Time points for death rate changes

- crude_birth:

  Birth rates (array or DF)

- crude_death:

  Death rates (array or DF)

- protection_weight_vacc:

  Weight of maternal protection (vaccine-derived)

- protection_weight_rec:

  Weight of maternal protection (natural infection)

- age_maternal_protection_ends:

  Age at which maternal protection ends

- repro_low:

  Lower bound of reproductive age

- repro_high:

  Upper bound of reproductive age

- tt_migration:

  Time points for migration events

- migration_in_number:

  Number of migrants

- migration_distribution_values:

  Migration destination distribution

- migration_represent_current_pop:

  If 1, distribution reflects current population

- cfr_normal:

  Case fatality rate for normal cases

- cfr_severe:

  Case fatality rate for severe cases

## Value

A named list of structured model inputs
