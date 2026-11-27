# Convert a Case Fatality Ratio to a Daily Probability of Death

The model draws deaths among the infectious each day with probability
\`cfr\` on top of background mortality, and recoveries each day with
probability \`recovery_rate\`. For the share of cases who die to equal a
case fatality ratio \`cfr\`, the daily probability has to be
\`recovery_rate \* cfr / (1 - cfr)\`.

## Usage

``` r
cfr_to_daily_probability(cfr, recovery_rate)
```

## Arguments

- cfr:

  Case fatality ratio (proportion of cases who die).

- recovery_rate:

  Daily probability of recovery.

## Value

Daily probability of death while infectious.
