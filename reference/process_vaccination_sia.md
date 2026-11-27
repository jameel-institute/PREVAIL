# Process Supplementary Immunization Activity (SIA) Data

Filters and processes SIA vaccination data for a specified country, time
range, and vaccine.

## Usage

``` r
process_vaccination_sia(
  vaccination_data,
  iso,
  vaccine = "All",
  year_start = "",
  year_end = ""
)
```

## Arguments

- vaccination_data:

  A \`data.frame\` or \`data.table\` containing SIA records. Must
  include columns \`area\`, \`year\`, \`coverage\`, and \`vaccine\`.

- iso:

  A 3-letter ISO country code to filter the data by (matched against the
  \`area\` column).

- vaccine:

  A specific vaccine name or substring to filter by (default is
  \`"All"\` which returns all vaccines).

- year_start:

  First year to include (default: earliest year in data).

- year_end:

  Final year to include (default: latest year in data).

## Value

A filtered \`data.table\` with records matching the selected country,
vaccine, and time period.
