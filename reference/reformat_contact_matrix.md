# Reformat Data.frame into a Contact Matrix

Converts a data.frame of age-band contacts into a numeric matrix for a
specified age range.

## Usage

``` r
reformat_contact_matrix(
  custom_data,
  iso = "custom",
  age_required = 0:100,
  fill_method = "closest",
  value_allocation = "maintain"
)
```

## Arguments

- custom_data:

  A data.frame with columns: 'age_from', 'age_to', and 'value'.

- iso:

  Character string for area/iso3 if missing. Default is "custom".

- age_required:

  Numeric vector specifying ages to include in matrix rows and columns
  (default is 0:100).

- fill_method:

  Method for filling values for missing age combinations. Options:
  'closest' (default), 'none'.

- value_allocation:

  Currently unused, reserved for future expansion (maintain or split
  values across age ranges).

## Value

Numeric matrix representing contact rates (rows = age_from, columns =
age_to).
