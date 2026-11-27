# Filter Routine Vaccination Schedule for a Country and Vaccine

Filters a WHO vaccination schedule data frame to extract age-specific
routine vaccination rounds for a specific vaccine and country.

## Usage

``` r
filter_vaccine_schedule(vaccination_schedule, vaccination_type, iso)
```

## Arguments

- vaccination_schedule:

  A data frame of WHO vaccination schedules.

- vaccination_type:

  A character string to match against \`vaccine_description\`.

- iso:

  A 3-letter ISO country code.

## Value

A filtered and arranged \`data.frame\` with an added \`age_years\`
column. Rows whose age cannot be read are dropped.

## Details

The age of each dose is converted to years row by row (see
\[parse_schedule_age()\]). In 0.1.0 the conversion was not row-wise:
every dose was given the median over the whole column, read in its own
unit, so for example the United Kingdom's first measles dose ("Y1") was
placed in adulthood.
