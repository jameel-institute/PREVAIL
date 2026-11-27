# Project Matrix to Symmetric Doubly Stochastic Form

Applies iterative Sinkhorn-Knopp projection to create a symmetric,
doubly stochastic matrix.

## Usage

``` r
project_to_symmetric_doubly_stochastic(mat, max_iter = 1000, tol = 1e-08)
```

## Arguments

- mat:

  A non-negative square matrix.

- max_iter:

  Maximum iterations (default = 1000).

- tol:

  Convergence tolerance (default = 1e-8).

## Value

A symmetric, doubly stochastic matrix of the same dimensions as \`mat\`.
