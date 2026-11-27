# Combine Two ggplot2 Plots with Consistent Style, Geom, and Axis Expansion

This function overlays two ggplot2 plots of the same type (e.g., line,
point, bar) into a single plot, preserving the original geoms used in
each layer (e.g., lines and points together). It automatically extracts
aesthetic mappings, axis expansions (including custom \`expand\` or
limits), and theming from the first plot. It also combines legends using
a \`SourceGroup\` that distinguishes both the type and origin of the
data.

## Usage

``` r
combine_ggplot(plot1, plot2, plot_names = c("Plot 1", "Plot 2"))
```

## Arguments

- plot1:

  A `ggplot` object. Style, axis expansions, and theme are taken from
  this plot.

- plot2:

  A second `ggplot` object to overlay on the first.

- plot_names:

  Optional character vector of length 2, naming the sources (defaults to
  `c("Plot 1", "Plot 2")`).

## Value

A combined `ggplot` object with geoms, groups, and axis settings from
both plots.
