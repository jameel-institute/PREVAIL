# Convert Age Break String to Age Group Labels

Converts a semicolon-separated string of numeric age breakpoints into a
character vector of age group labels. For example, the input
\`"0;5;10;...;80;Inf"\` will produce the labels \`"0–4"\`, \`"5–9"\`,
..., \`"80+"\`.

## Usage

``` r
age_breaks_to_labels(age_string)
```

## Arguments

- age_string:

  A single character string of age breakpoints, separated by semicolons.
  Must include at least two breakpoints. The last breakpoint can be
  \`Inf\` to indicate an open-ended upper age group.

## Value

A character vector of formatted age group labels.

## Examples

``` r
age_breaks_to_labels("0;5;10;15;20;25;30;35;40;45;50;55;60;65;70;75;80;Inf")
#>  [1] "0–4"   "5–9"   "10–14" "15–19" "20–24" "25–29" "30–34" "35–39" "40–44"
#> [10] "45–49" "50–54" "55–59" "60–64" "65–69" "70–74" "75–79" "80+"  
# Returns:
# [1] "0–4"   "5–9"   "10–14" "15–19" "20–24" ... "75–79" "80+"
```
