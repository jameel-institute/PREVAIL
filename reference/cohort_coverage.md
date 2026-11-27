# Achieved Against Reported Coverage by Cohort

For each age group at the end of a historical run, compares the share
who have had at least each dose with the reported routine coverage of
that dose in the years the age group's birth cohorts were due it.

## Usage

``` r
cohort_coverage(compartments, params)
```

## Arguments

- compartments:

  List of the six model compartments (age by stratum by risk group).

- params:

  Parameter list from the wrappers (with its \`history\` element).

## Value

A data frame with columns \`age_group\`, \`age\`, \`dose\`, \`achieved\`
and \`reported\`.
