# Run and Unpack Dust Model Simulation Results

Initializes a Dust model simulation using an \`odin.dust\` model
(compiled with \`transmission_model()\`), runs the simulation using
specified parameters and particle count, and returns the unpacked
results as a long-format \`data.table\` suitable for downstream
analysis.

## Usage

``` r
run_model_unpack_results(params, simulation_length, no_runs = 10)
```

## Arguments

- params:

  A named list of model parameters, which must include:

  - `n_age`: Integer. Number of age groups.

  - `n_vacc`: Integer. Number of vaccination strata.

  - `n_risk`: Integer. Number of risk groups.

  - `tt_migration`: Integer. Number of timepoints with migration changes
    (used for unpacking migration dimension).

  - Other model-specific parameters required by
    \`transmission_model()\`.

- simulation_length:

  Integer. Total length of the simulation in model timesteps. Defines
  the number of steps run.

- no_runs:

  Integer. Number of stochastic particles to simulate (default = 10).
  Higher values yield more stable outputs.

## Value

A \`data.table\` in long format with the following columns:

- `state`: The name of the state variable (e.g., "S", "E", "I", etc.).

- `time`: Model time step (starting at 0).

- `age`, `vaccination`, `risk`: Stratification dimensions.

- `value`: Simulated value for the given state and strata.

- (Optional) `particle`: Particle identifier, if applicable.

## Details

Internally uses:

- \`dust2::dust_system_create()\` to build the Dust model system.

- \`dust2::dust_system_simulate()\` to run the stochastic simulation.

- \`unpack_dust2()\` to reshape model outputs into long-format
  \`data.table\`.

The \`dimension_names\` list passed to \`unpack_dust2()\` includes:

- Age groups: 1 to \`n_age\`

- Vaccination strata: 1 to \`n_vacc\`

- Risk strata: 1 to \`n_risk\`

- Time: from 0 to \`simulation_length\`

- no_migration_changes: derived as \`tt_migration + 1\`

State dimensions unpacked include: \`"S"\`, \`"E"\`, \`"I"\`, \`"R"\`,
\`"Is"\`, \`"Rc"\`, \`"new_case"\`, \`"Reff_age"\`, and
\`"seropositive"\`.

## Examples

``` r
if (FALSE) { # \dontrun{
params <- list(n_age = 17, n_vacc = 3, n_risk = 2, tt_migration = 5, ...)
sim_results <- run_model_unpack_results(params, simulation_length = 365)
} # }
```
