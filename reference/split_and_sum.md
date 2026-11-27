# Split a Vector into Bins and Sum Each Bin

This function divides a numeric vector into approximately equal-sized
groups (bins), then computes the sum of values within each bin.

## Usage

``` r
split_and_sum(vec, n_bins)
```

## Arguments

- vec:

  A numeric vector to be grouped and summed.

- n_bins:

  An integer specifying the number of bins to split the vector into.

## Value

A numeric vector of length \`n_bins\` (or fewer if \`vec\` has fewer
elements), where each element is the sum of values in a bin.
