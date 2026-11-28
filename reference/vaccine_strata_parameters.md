# Vaccine Protection and Waning by Vaccination Stratum

Assigns the protection and waning values of the vaccine parameter table
to the model's vaccination strata.

## Usage

``` r
vaccine_strata_parameters(
  vaccine_parameters,
  n_vacc,
  vaccine_waning = TRUE,
  n_primary = NULL
)
```

## Arguments

- vaccine_parameters:

  Vaccine parameter table for one disease, with columns \`parameter\`,
  \`value\`, \`dose\`.

- n_vacc:

  Number of vaccination strata in the model.

- vaccine_waning:

  Logical; if \`FALSE\` vaccine protection does not wane (both waning
  rates are zero and everyone stays in the short-term stratum of their
  last dose).

- n_primary:

  Number of doses in the primary series (3 for DTP), which take the
  table's first row while later doses take its last. \`NULL\` (measles):
  each dose takes its own row, or the first row if it has none.

## Value

A list with \`protection\`, \`short_term_waning\` and
\`long_term_waning\` (vectors of length \`n_vacc\`; waning as daily
probabilities) and \`table\`, a data frame describing each dose.

## Details

The model has one unvaccinated stratum (1) and two strata per dose. Dose
\`d\` is given into its short-term stratum (index \`2d + 1\`), which
wanes at \`short_term_waning\` into its long-term stratum (index
\`2d\`), which in turn wanes at \`long_term_waning\` to unvaccinated. So
short-term protection belongs on the odd strata and long-term protection
on the even strata.

In 0.1.0 the two were swapped, the row of the table was chosen by
comparing the stratum index (not the dose) with the table's \`dose\`, so
that both measles doses used the second-dose row and one pertussis
stratum was given the sum of two rows (a protection of 1.75), and a
single waning rate (the slowest in the table) was used for every
stratum.

The table has two rows of doses per disease (measles 1 and 2; diphtheria
1 and 6; pertussis 3 and 5). For measles each modelled dose uses its own
row. For DTP the \`dose\` tag is the number of doses received when the
estimate applies: the first row (diphtheria 1, pertussis 3) is the
three-dose primary series and the second (diphtheria 6, pertussis 5) the
full schedule including boosters. So the three primary doses
(\`n_primary\`) get the first row and every booster (doses 4 to 6, see
\[dtp_booster_schedule()\]) the second. That overstates protection after
one or two primary doses, and after a first booster; values for partial
courses belong in the table as their own rows, not in code.
