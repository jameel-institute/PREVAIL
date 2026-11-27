# Plot PMCMC Fitting Results: Parameter Traces and Log-Likelihood

Produces a two-panel plot showing the trace of fitted parameters and the
log-likelihood over PMCMC iterations. Designed for diagnostics of
convergence and mixing.

## Usage

``` r
plot_fitting_results(long_trace)
```

## Arguments

- long_trace:

  A data.frame in long format with columns `iteration`, `parameter`, and
  `value`, typically output from a PREVAIL PMCMC run.

## Value

A combined `ggplot2` object (via `patchwork`) showing:

- Parameter trace plot for all fitted parameters

- Log-likelihood trace plot
