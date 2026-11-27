# Routine Coverage by Dose and Year

Turns the processed routine coverage data into one coverage series per
modelled dose, covering every model year.

## Usage

``` r
routine_dose_coverage(vaccination_data, n_doses, years, percent = TRUE)
```

## Arguments

- vaccination_data:

  Processed routine vaccination data with columns \`year\`,
  \`dose_order\` and \`coverage\`.

- n_doses:

  Number of doses the model represents.

- years:

  Model years.

- percent:

  Logical; is \`coverage\` in percent (WHO data) rather than a
  proportion (custom data)?

## Value

A matrix of coverage proportions with one row per year and one column
per dose. The attribute \`interpolated_doses\` lists doses whose
coverage was taken from neighbouring doses and \`last_data_year\` gives
the last year with data for each dose.

## Details

\* Coverage is zero before the first year with data, interpolated
linearly across gaps, and carried forward after the last year with data.
\* A dose with no data that sits between two doses with data is given
the mean of its neighbours. WUENIC reports DTP1 and DTP3 only, so this
is how the second DTP dose gets a coverage (in 0.1.0 it had none, and
nobody in the model could progress beyond one dose). \* Doses beyond the
number the model represents (for example the fourth, fifth and sixth
diphtheria doses) are dropped: the model has no strata for them. \*
Coverage of a dose is not allowed to exceed coverage of the dose before
it.
