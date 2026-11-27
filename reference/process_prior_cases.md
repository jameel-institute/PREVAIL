# Process Disease Surveillance Data

Filters and subsets disease surveillance data for a specified country,
time window, and disease.

## Usage

``` r
process_prior_cases(
  disease_data,
  iso,
  disease = "All",
  year_start = "",
  year_end = "",
  keep_zero = FALSE
)
```

## Arguments

- disease_data:

  A \`data.frame\` or \`data.table\` of disease records. Must include
  columns: \`iso3\`, \`year\`, \`cases\`, and optionally
  \`disease_short\`.

- iso:

  A 3-letter ISO country code to filter the data by.

- disease:

  A specific disease to filter by. Default is \`"All"\`, which returns
  all diseases.

- year_start:

  First year to include (default: first year in data).

- year_end:

  Final year to include (default: last year in data).

- keep_zero:

  Logical; keep years with zero reported cases? The default (\`FALSE\`)
  returns years with at least one case, as in 0.1.0. Zero reports are
  needed to tell "no cases reported" apart from "no report".

## Value

A filtered \`data.table\` containing only records for the specified
country, time range, and disease.
