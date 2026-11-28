# Coverage of DTP Booster Doses

WHO booster coverage (the 4th to 6th diphtheria-containing doses) only
starts in 2018. Before the first year with data, each booster's coverage
is taken as the same share of DTP3 coverage as in its first years with
data (the mean over up to three years), from \`booster_since\` on, and
zero before that. This keeps a booster that was already routine in 2018
for the earlier cohorts that serosurveys sample. Where a booster was
introduced recently, set \`booster_since\` to its introduction year, or
give coverage directly with \`custom_routine_vaccination\`.

## Usage

``` r
backfill_booster_coverage(routine_coverage, years, booster_since = 1980)
```

## Arguments

- routine_coverage:

  Matrix from \[routine_dose_coverage()\] (proportions; doses 1 to 3
  then the boosters).

- years:

  Model years.

- booster_since:

  First year in which boosters can be given before their coverage data
  start.

## Value

\`routine_coverage\` with booster coverage filled in before its data,
and no dose above the one before it.
