# Carry the Last Year of a Yearly Dataset Forward

Restricts a data frame with a \`year\` column to \`years\` and, where
\`years\` runs past the last year with data, repeats the last year's
rows for each later year. PREVAIL's demographic inputs (UN WPP) end in
2023; without this the model had no births, deaths or migration from
2024 onwards.

## Usage

``` r
carry_forward_years(df, years)
```

## Arguments

- df:

  A data frame with a \`year\` column.

- years:

  The years required.

## Value

\`df\` restricted to \`years\`, extended to the last of \`years\` if
needed, ordered by year.
