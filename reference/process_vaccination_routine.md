# Process Routine Vaccination Coverage Data

Filters and processes routine immunization data for a specified country,
time range, and optionally vaccine type. Aggregates records by year,
antigen, and antigen description, summarising key indicators such as
median coverage.

## Usage

``` r
process_vaccination_routine(
  vaccination_data,
  iso,
  vaccine = "All",
  year_start = "",
  year_end = "",
  coverage_source = c("wuenic", "median")
)
```

## Arguments

- vaccination_data:

  A \`data.frame\` or \`data.table\` with columns including \`ISO3\`,
  \`YEAR\`, \`COVERAGE\`, \`ANTIGEN\`, \`ANTIGEN_DESCRIPTION\`,
  \`Disease\`, \`target_number\`, and \`doses\`.

- iso:

  A 3-letter ISO country code to filter the data by.

- vaccine:

  A specific vaccine name or substring to filter by (default is
  \`"All"\`, which returns all vaccines).

- year_start:

  First year to include (default: earliest year in data).

- year_end:

  Final year to include (default: latest year in data).

- coverage_source:

  \`"wuenic"\` (default) uses the WHO/UNICEF estimate of national
  immunisation coverage for a vaccine and year where there is one, and
  the median of the administrative and official figures otherwise.
  \`"median"\` takes the median of all three, as 0.1.0 did (which in
  practice follows the administrative figure whenever the administrative
  and official figures agree).

## Value

A \`data.table\` with columns \`year\`, \`vaccine\`,
\`vaccine_description\`, \`dose_order\`, and median \`coverage\` (and
\`age\` where the input has one).
