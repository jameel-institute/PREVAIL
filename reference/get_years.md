# Generate a Sequence of Years from a Vector and Optional Start/End Bounds

This helper function returns a sequence of years based on a full vector
of years (\`yrs\`) and optional start and end bounds. If either
\`start\` or \`end\` is an empty string, the minimum or maximum value in
\`yrs\` is used, respectively.

## Usage

``` r
get_years(yrs, start, end)
```

## Arguments

- yrs:

  A numeric vector of years from which to derive default start or end
  values.

- start:

  A numeric or character value specifying the start year. If \`""\`, the
  minimum year in \`yrs\` is used.

- end:

  A numeric or character value specifying the end year. If \`""\`, the
  maximum year in \`yrs\` is used.

## Value

A numeric vector of consecutive years from \`start\` to \`end\`
(inclusive).
