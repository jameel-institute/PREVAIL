# Prepare Future Scenario Parameters for Transmission Model

This function generates an updated parameter list for projecting future
scenarios in a transmission model. It modifies the vaccination coverage,
R0 values, and seeding of new cases based on a user-specified set of
future events. It also resets migration, birth, and death inputs to
their final known values.

## Usage

``` r
prepare_future_data(params, future_events, current_susceptibility)
```

## Arguments

- params:

  A named list of model parameters as used in the core transmission
  model.

- future_events:

  A \`data.frame\` specifying future event timepoints and modifications.
  Must contain:

  - `time`: Future time (numeric).

  - `relative_coverage`: Multiplicative modifier to vaccination
    coverage. Applied to coverage, not to the daily rate: see
    \[scale_vaccination_rates()\].

  - `R0`: Basic reproduction number for each future timepoint.

  - `introduced_cases`: Number of seed infections to introduce at each
    timepoint (once, on the day of the event).

- current_susceptibility:

  A named list with updated \`S0\`, \`Rpop0\` values reflecting the
  final simulation state.

## Value

A modified version of the \`params\` list ready to run forward
simulations under future scenarios.
