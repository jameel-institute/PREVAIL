# Resolve Schedule Ages Given Relative to an Earlier Dose

Some schedule ages are intervals since the previous dose (for example
\`"+M1"\`). Within a schedule year, product and target population these
are added to the age of the preceding round. If the preceding round has
no age the result is \`NA\`.

## Usage

``` r
resolve_relative_schedule_ages(schedule)
```

## Arguments

- schedule:

  A schedule with \`age_years\` from \[parse_schedule_age()\] and
  columns \`year\`, \`vaccine_code\`, \`target_pop\` and
  \`schedulerounds\`.

## Value

The schedule with relative ages replaced by absolute ages.
