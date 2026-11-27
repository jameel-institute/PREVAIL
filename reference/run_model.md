# Run Dust Model Simulation

Initializes a dust model system using the provided parameters, runs the
simulation over a defined time period with a specified number of
stochastic particles, and returns the simulated system.

## Usage

``` r
run_model(params, simulation_length = 1000, no_runs = 10)
```

## Arguments

- params:

  A named list of model parameters, including initial conditions, rates,
  and dimensions.

- simulation_length:

  Integer. The number of time steps to simulate (default is 1000). Time
  starts at 0.

- no_runs:

  Integer. Number of stochastic particles (simulations) to run in
  parallel (default is 10).

## Value

A \`dust_system\` object containing the full system state and particle
trajectories. Use \`unpack_dust2()\` or similar functions to extract
outputs.
