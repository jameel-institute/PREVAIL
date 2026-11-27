# Process Dust Model Data

Transforms a multi-dimensional dust model output array into a
long-format data.table, assigning appropriate names to dimensions and
unpacking by particle if needed.

## Usage

``` r
process_obj(
  this_obj,
  present_dimensions,
  colnames,
  time_length,
  x,
  model_system,
  dimension_names,
  dust_state
)
```

## Arguments

- this_obj:

  The model output array to process.

- present_dimensions:

  Character vector of dimension labels for this state (e.g., \`c("age",
  "vaccination", "risk", "time")\`).

- colnames:

  Column names for the output data table.

- time_length:

  Length of the time dimension.

- x:

  Index of the current state in the model.

- model_system:

  The model system object containing metadata like number of particles.

- dimension_names:

  Named list of dimension label values for each dimension.

- dust_state:

  List of all unpacked model state arrays.

## Value

A list of two \`data.table\`s: the full stratified long-format output
and a reduced time-by-state (and optionally run) aggregation.
