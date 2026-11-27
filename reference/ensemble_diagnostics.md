# Summaries across the Worlds of an Ensemble

Summaries across the Worlds of an Ensemble

## Usage

``` r
ensemble_diagnostics(worlds, recent_years = 10, history_years = 25)
```

## Arguments

- worlds:

  List of \`prevail_immunity_history\` objects, each with a \`weight\`.

- recent_years:

  Number of final years over which infections and reported cases are
  averaged.

- history_years:

  Number of final years for which the yearly series are returned.

## Value

A list; see the \`diagnostics\` element described in
\[write_immunity_json()\].
