# Age at Which Each Routine Dose is Given

Looks up the scheduled age of each modelled dose in each model year from
a schedule returned by \[filter_vaccine_schedule()\]. The schedule in
force is the latest one dated on or before the year, or the earliest one
if all are later. Where several products are scheduled for the same dose
the youngest age is used. A dose with no schedule entry takes the age of
the previous dose (one year of age for a first dose).

## Usage

``` r
routine_dose_ages(schedule, n_doses, years)
```

## Arguments

- schedule:

  Output of \[filter_vaccine_schedule()\].

- n_doses:

  Number of doses the model represents.

- years:

  Model years.

## Value

A matrix of ages in years, one row per year and one column per dose.
