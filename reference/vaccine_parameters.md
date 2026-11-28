# Vaccine Efficacy and Duration Parameters

Dose-specific efficacy and duration estimates for measles, diphtheria,
and pertussis.

## Usage

``` r
vaccine_parameters
```

## Format

A data frame with columns: - vaccine: Vaccine name (\`DTwP\`: whole-cell
pertussis primary series) - disease: Disease name - parameter: Parameter
name - value: Value of parameter - unit: Unit of measurement - dose:
Dose number

## Source

Literature estimates from peer-reviewed sources

## Details

For diphtheria and pertussis, \`dose\` is the number of doses received
when the estimate applies: the first row (diphtheria 1, pertussis 3) is
the three-dose primary series and the second (diphtheria 6, pertussis 5)
the full schedule with boosters, used for booster doses (see
\[vaccine_strata_parameters()\]). The pertussis rows tagged \`DTP\` come
from studies of acellular vaccine. The rows tagged \`DTwP\` are the
primary series of whole-cell vaccine, used where the country's schedule
is whole-cell (see \[select_pertussis_vaccine()\]): the same protection
as acellular (WHO position paper 2015) with the waning durations doubled
(acellular priming roughly doubled the odds of pertussis against
whole-cell priming, Schwartz et al. 2016; vaccine immunity lasts 4 to 12
years, Wendelboe et al. 2005). These whole-cell values are provisional,
meant to be estimated by fitting to serosurveys. Sources are in the
second sheet of \`inst/extdata/data-raw/vaccine_protection.xlsx\`.
