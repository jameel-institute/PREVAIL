# Convert WHO Schedule Ages to Years

Converts the \`age_administered\` strings of the WHO vaccination
schedule (for example \`"M9"\`, \`"W6"\`, \`"Y1"\`, \`"Y11-Y12"\`,
\`"\>=Y65"\`) to ages in years. Each element is converted on its own, in
its own unit. A range is given the midpoint of its two ends, and a part
of a range without a unit letter takes the unit of the other part.
\`"B"\` (birth) is age zero. Ages given relative to an earlier dose (a
leading \`"+"\`) are returned as the offset and flagged in the
\`relative\` attribute, so that the caller can add them to the earlier
dose.

## Usage

``` r
parse_schedule_age(x)
```

## Arguments

- x:

  Character vector of schedule ages.

## Value

Numeric vector of ages in years (\`NA\` where the string cannot be
read), with a logical attribute \`relative\`.
