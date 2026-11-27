# Log-Likelihood of Serosurvey Data

Binomial (or beta-binomial) log-likelihood of seropositive counts by age
band given modelled seroprevalence.

## Usage

``` r
serosurvey_loglik(n_pos, n_tested, p, overdispersion = 0)
```

## Arguments

- n_pos, n_tested:

  Seropositive and tested counts by age band. Bands with missing counts
  are dropped.

- p:

  Modelled seroprevalence by band (see \[modelled_seroprevalence()\]).

- overdispersion:

  Beta-binomial intra-class correlation in \\0, 1). \`0\` (default) is
  binomial. Use it to allow for survey design effects and model misfit.

## Value

The log-likelihood (a single number).

## Examples

``` r
serosurvey_loglik(n_pos = c(80, 95), n_tested = c(100, 100), p = c(0.8, 0.9))
#> [1] -5.694957
```
