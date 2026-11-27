# Fit Transmission Model Using PMCMC

Runs a particle MCMC fit of the PREVAIL transmission model using
pre-generated parameters and a serosurvey dataset. This function
performs a PMCMC run using the dust2 engine for likelihood evaluation
and the monty framework for inference. The function does not run
simulation post-fitting — instead, it returns everything needed for
follow-up analysis or second-stage fitting.

## Usage

``` r
fit_transmission_model(
  parameters,
  serodata,
  prior,
  stochastic = F,
  fitted_parameters = c("reporting_rate", "R0_modifier"),
  initial = NULL,
  domain = matrix(c(0, 2, 0, 2), nrow = 2, byrow = T),
  vcv = diag(0.1, length(fitted_parameters)),
  n_steps = 1000,
  n_chains = 1,
  n_particles = 1
)
```

## Arguments

- parameters:

  A named list of model parameters, as produced by
  [`custom_data_process_wrapper`](https://jameel-institute.github.io/PREVAIL/reference/custom_data_process_wrapper.md).

- serodata:

  A data.frame with columns `time` and `serosurvey`, where `serosurvey`
  is a list-column containing numeric vectors of observed seropositivity
  by age.

- prior:

  A prior distribution object created using
  [`monty_dsl`](https://mrc-ide.github.io/monty/reference/monty_dsl.html).

- stochastic:

  TRUE or FALSE. Determines whether to run the transmission_model() as
  stochastic or deterministic. By default uses FALSE to increase speed.

- fitted_parameters:

  Character vector of parameter names to fit (e.g.,
  `c("reporting_rate", "R0_modifier")`).

- initial:

  A named list of initial parameter values, or `NULL` to default all to
  1.

- domain:

  A matrix with two rows (lower and upper) and columns named for each
  fitted parameter. Defines parameter bounds.

- vcv:

  A variance-covariance matrix for the random walk proposal. Should be
  square with dimensions equal to number of parameters.

- n_steps:

  Integer. Number of MCMC steps to perform (default = 1000).

- n_chains:

  Integer. Number of independent MCMC chains (default = 1).

- n_particles:

  Integer. Number of particles used in the particle filter (default =
  1).

## Value

A named list containing:

- samples:

  The output from
  [`monty_sample`](https://mrc-ide.github.io/monty/reference/monty_sample.html),
  including sampled parameters and log-likelihoods.

- posterior:

  The final posterior object used for inference.

- summarised_draws:

  Summary statistics (e.g., mean, median, quantiles) for each parameter
  from the posterior samples.

- all_states:

  The full simulated state trajectories from the model for both base and
  fitted parameter sets.

- plots:

  A list of ggplot2 objects including trace plots, log-likelihood plot,
  combined trace-loglik plot, and seropositivity plot: `trace`,
  `loglik`, `combined`, `sero`.

## Examples

``` r
if (FALSE) { # \dontrun{
params <- PREVAIL::custom_data_process_wrapper(iso = "KEN", disease = "measles", R0 = 15)
serodata <- data.frame(time = 2500, serosurvey = I(list(rep(0.85, 17))))
prior <- monty::monty_dsl({
  reporting_rate ~ Normal(mean = 1, sd = 5)
  R0_modifier ~ Normal(mean = 1, sd = 1)
})
fit <- fit_transmission_model(parameters = params, serodata = serodata, prior = prior)
fit$plots$combined
} # }
```
