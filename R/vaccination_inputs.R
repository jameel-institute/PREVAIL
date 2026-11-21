#' Convert WHO Schedule Ages to Years
#'
#' Converts the `age_administered` strings of the WHO vaccination schedule (for example `"M9"`, `"W6"`, `"Y1"`,
#' `"Y11-Y12"`, `">=Y65"`) to ages in years. Each element is converted on its own, in its own unit. A range is
#' given the midpoint of its two ends, and a part of a range without a unit letter takes the unit of the other part.
#' `"B"` (birth) is age zero. Ages given relative to an earlier dose (a leading `"+"`) are returned as the offset and
#' flagged in the `relative` attribute, so that the caller can add them to the earlier dose.
#'
#' @param x Character vector of schedule ages.
#'
#' @return Numeric vector of ages in years (`NA` where the string cannot be read), with a logical attribute
#'   `relative`.
#' @keywords internal
parse_schedule_age <- function(x) {
  x <- toupper(trimws(as.character(x)))
  relative <- !is.na(x) & grepl("^\\+", x)
  unit_years <- c(Y = 1, M = 1 / 12, W = 1 / 52, D = 1 / 365)

  one <- function(s) {
    if (is.na(s) || !nzchar(s)) return(NA_real_)
    if (s %in% c("B", "BIRTH")) return(0)
    s <- gsub("^[+<>=]+", "", s)
    parts <- strsplit(s, "-", fixed = TRUE)[[1]]
    parts <- parts[nzchar(parts)]
    if (!length(parts) || length(parts) > 2) return(NA_real_)
    unit <- sub("^([YMWD])?.*$", "\\1", parts)
    num <- suppressWarnings(as.numeric(sub("^[YMWD]", "", parts)))
    if (anyNA(num) || all(unit == "")) return(NA_real_)
    unit[unit == ""] <- unit[unit != ""][1]
    mean(num * unit_years[unit])
  }

  out <- vapply(x, one, numeric(1), USE.NAMES = FALSE)
  attr(out, "relative") <- relative
  out
}

#' Daily Vaccination Probability that Achieves a Target Coverage
#'
#' The model moves people out of an age group at a constant rate (`aging_rate` per day), so the time spent in a
#' group is geometric rather than a fixed number of years. With a daily vaccination probability `p` (applied after
#' ageing on each day, as in the model) the share of a cohort that has been vaccinated by the time it leaves the
#' group is `p / (a + p (1 - a))`. This function inverts that relationship, so that the share vaccinated on leaving
#' the group equals `coverage`:
#' \deqn{p = \frac{a c}{1 - c (1 - a)}}
#' which is close to `a c / (1 - c)`: the ageing rate times the odds of being vaccinated.
#'
#' PREVAIL 0.1.0 used `1 - (1 - c)^(1/365)` spread over the years in the age group, which assumes everyone spends
#' exactly that many years in the group: a reported coverage of 90\% then gave about 70\% in the model and no input
#' could give more than about 82\%.
#'
#' The relationship is exact for a steady flow of people through the age group. Where the number of births is
#' changing quickly the share vaccinated in the model drifts from the target by up to about a percentage point.
#'
#' `coverage_accuracy` multiplies the odds of being vaccinated, to represent true coverage differing from reported
#' coverage: 1 takes the data at face value, 2 halves the unvaccinated share when coverage is high, 0.5 roughly
#' doubles it.
#'
#' @param coverage Target coverage (proportion) on leaving the age group. For second and later doses this is the
#'   coverage among those who have had the previous dose.
#' @param aging_rate Daily probability of ageing out of the model age group in which the dose is given.
#' @param coverage_accuracy Multiplier on the odds of vaccination. Default 1.
#' @param max_coverage Coverage is capped at this value (default 0.99) so that the rate stays finite.
#'
#' @return Daily vaccination probability, between 0 and 1.
#' @keywords internal
coverage_to_daily_rate <- function(coverage, aging_rate, coverage_accuracy = 1, max_coverage = 0.99) {
  c_use <- adjust_coverage_odds(coverage, coverage_accuracy, max_coverage)
  rate <- aging_rate * c_use / (1 - c_use * (1 - aging_rate))
  pmin(pmax(rate, 0), 1)
}

#' Apply a Coverage Accuracy Multiplier to a Coverage
#'
#' Multiplies the odds of a coverage by `coverage_accuracy` and converts back to a proportion.
#'
#' @inheritParams coverage_to_daily_rate
#' @return Adjusted coverage (proportion).
#' @keywords internal
adjust_coverage_odds <- function(coverage, coverage_accuracy = 1, max_coverage = 0.99) {
  c_use <- pmin(pmax(coverage, 0), max_coverage)
  coverage_accuracy * c_use / (1 - c_use + coverage_accuracy * c_use)
}

#' Daily Ageing Probability of Each Model Age Group
#'
#' @param aggregate_age Logical; whether single years of age are aggregated into `new_age_breaks`.
#' @param new_age_breaks Age break points of the aggregated groups.
#'
#' @return Numeric vector (one value per age group when aggregated, otherwise a single value).
#' @keywords internal
model_aging_rate <- function(aggregate_age, new_age_breaks) {
  if (!aggregate_age) return(1 / 365)
  breaks <- new_age_breaks
  breaks[length(breaks)] <- 101
  1 / (365 * diff(breaks))
}

#' Routine Coverage by Dose and Year
#'
#' Turns the processed routine coverage data into one coverage series per modelled dose, covering every model year.
#'
#' * Coverage is zero before the first year with data, interpolated linearly across gaps, and carried forward after
#'   the last year with data.
#' * A dose with no data that sits between two doses with data is given the mean of its neighbours. WUENIC reports
#'   DTP1 and DTP3 only, so this is how the second DTP dose gets a coverage (in 0.1.0 it had none, and nobody in the
#'   model could progress beyond one dose).
#' * Doses beyond the number the model represents (for example the fourth, fifth and sixth diphtheria doses) are
#'   dropped: the model has no strata for them.
#' * Coverage of a dose is not allowed to exceed coverage of the dose before it.
#'
#' @param vaccination_data Processed routine vaccination data with columns `year`, `dose_order` and `coverage`.
#' @param n_doses Number of doses the model represents.
#' @param years Model years.
#' @param percent Logical; is `coverage` in percent (WHO data) rather than a proportion (custom data)?
#'
#' @return A matrix of coverage proportions with one row per year and one column per dose. The attribute
#'   `interpolated_doses` lists doses whose coverage was taken from neighbouring doses and `last_data_year` gives
#'   the last year with data for each dose.
#' @keywords internal
routine_dose_coverage <- function(vaccination_data, n_doses, years, percent = TRUE) {

  out <- matrix(0, nrow = length(years), ncol = n_doses, dimnames = list(years, paste0("dose", seq_len(n_doses))))
  has_data <- rep(FALSE, n_doses)
  last_data_year <- rep(NA_integer_, n_doses)

  df <- as.data.frame(vaccination_data)
  if (nrow(df) > 0 && "vaccine_description" %in% names(df)) {
    df <- df[!grepl("birth|neonatal|pregnant|maternal", df$vaccine_description, ignore.case = TRUE), , drop = FALSE]
  }
  if (nrow(df) > 0) {
    df <- df[!is.na(df$coverage) & !is.na(df$dose_order) & df$dose_order >= 1 & df$dose_order <= n_doses, , drop = FALSE]
  }

  for (d in seq_len(n_doses)) {
    sub <- df[df$dose_order == d, , drop = FALSE]
    if (nrow(sub) == 0) next
    by_year <- tapply(sub$coverage, sub$year, max)
    yr <- as.numeric(names(by_year))
    val <- as.numeric(by_year) / if (percent) 100 else 1
    series <- if (length(yr) == 1) {
      rep(val, length(years))
    } else {
      stats::approx(yr, val, xout = years, method = "linear", rule = 2, ties = "ordered")$y
    }
    series[years < min(yr)] <- 0
    out[, d] <- pmin(pmax(series, 0), 1)
    has_data[d] <- TRUE
    last_data_year[d] <- max(yr)
  }

  interpolated <- integer(0)
  for (d in seq_len(n_doses)) {
    if (has_data[d] || d == 1 || d == n_doses) next
    lower <- max(which(has_data & seq_len(n_doses) < d), -Inf)
    upper <- min(which(has_data & seq_len(n_doses) > d), Inf)
    if (is.finite(lower) && is.finite(upper)) {
      weight <- (d - lower) / (upper - lower)
      out[, d] <- (1 - weight) * out[, lower] + weight * pmin(out[, upper], out[, lower])
      interpolated <- c(interpolated, d)
    }
  }

  if (n_doses > 1) {
    for (d in 2:n_doses) out[, d] <- pmin(out[, d], out[, d - 1])
  }

  attr(out, "interpolated_doses") <- interpolated
  attr(out, "last_data_year") <- last_data_year
  out
}

#' Age at Which Each Routine Dose is Given
#'
#' Looks up the scheduled age of each modelled dose in each model year from a schedule returned by
#' [filter_vaccine_schedule()]. The schedule in force is the latest one dated on or before the year, or the
#' earliest one if all are later. Where several products are scheduled for the same dose the youngest age is used.
#' A dose with no schedule entry takes the age of the previous dose (one year of age for a first dose).
#'
#' @param schedule Output of [filter_vaccine_schedule()].
#' @param n_doses Number of doses the model represents.
#' @param years Model years.
#'
#' @return A matrix of ages in years, one row per year and one column per dose.
#' @keywords internal
routine_dose_ages <- function(schedule, n_doses, years) {
  out <- matrix(NA_real_, nrow = length(years), ncol = n_doses, dimnames = list(years, paste0("dose", seq_len(n_doses))))
  schedule <- as.data.frame(schedule)
  schedule <- schedule[!is.na(schedule$age_years), , drop = FALSE]
  schedule_years <- sort(unique(schedule$year))

  for (sy in schedule_years) {
    rows <- if (sy == min(schedule_years)) years < sy | years >= sy else years >= sy
    this <- schedule[schedule$year == sy, , drop = FALSE]
    for (d in seq_len(n_doses)) {
      ages <- this$age_years[this$schedulerounds == d]
      if (length(ages)) out[rows, d] <- min(ages)
    }
  }

  for (d in seq_len(n_doses)) {
    missing <- is.na(out[, d])
    if (any(missing)) out[missing, d] <- if (d == 1) 1 else out[missing, d - 1]
  }
  out
}

#' Vaccine Protection and Waning by Vaccination Stratum
#'
#' Assigns the protection and waning values of the vaccine parameter table to the model's vaccination strata.
#'
#' The model has one unvaccinated stratum (1) and two strata per dose. Dose `d` is given into its short-term
#' stratum (index `2d + 1`), which wanes at `short_term_waning` into its long-term stratum (index `2d`), which in
#' turn wanes at `long_term_waning` to unvaccinated.
#' So short-term protection belongs on the odd strata and long-term protection on the even strata.
#'
#' In 0.1.0 the two were swapped, the row of the table was chosen by comparing the stratum index (not the dose) with
#' the table's `dose`, so that both measles doses used the second-dose row and one pertussis stratum was given the
#' sum of two rows (a protection of 1.75), and a single waning rate (the slowest in the table) was used for every
#' stratum.
#'
#' The table has two rows of doses per disease (measles 1 and 2; diphtheria 1 and 6; pertussis 3 and 5) while the
#' model has two measles doses and three DTP doses. Each modelled dose uses its own row if there is one and the
#' first row otherwise. For measles that is simply dose 1 and dose 2. For DTP the `dose` tag is the number of doses
#' received when the estimate applies: the first row (diphtheria 1, pertussis 3) is the three-dose primary series and
#' the second (diphtheria 6, pertussis 5) the full schedule including boosters, which the model does not represent.
#' So all three DTP doses get the primary-series row. That overstates protection after one or two doses; values for
#' partial courses belong in the table as their own rows (with `dose` 1 and 2), not in code.
#'
#' @param vaccine_parameters Vaccine parameter table for one disease, with columns `parameter`, `value`, `dose`.
#' @param n_vacc Number of vaccination strata in the model.
#' @param vaccine_waning Logical; if `FALSE` vaccine protection does not wane (both waning rates are zero and
#'   everyone stays in the short-term stratum of their last dose).
#'
#' @return A list with `protection`, `short_term_waning` and `long_term_waning` (vectors of length `n_vacc`; waning
#'   as daily probabilities) and `table`, a data frame describing each dose.
#' @keywords internal
vaccine_strata_parameters <- function(vaccine_parameters, n_vacc, vaccine_waning = TRUE) {

  n_doses <- (n_vacc - 1) / 2
  protection <- short_w <- long_w <- rep(0, n_vacc)
  if (n_doses < 1) {
    return(list(protection = protection, short_term_waning = short_w, long_term_waning = long_w, table = data.frame()))
  }

  vp <- as.data.frame(vaccine_parameters)
  table_doses <- sort(unique(vp$dose))
  get <- function(dose, parameter) {
    v <- vp$value[vp$dose == dose & vp$parameter == parameter]
    if (length(v) == 0) stop(sprintf("Vaccine parameter '%s' missing for dose %s", parameter, dose))
    v[1]
  }

  rows <- lapply(seq_len(n_doses), function(d) {
    table_dose <- if (d %in% table_doses) d else min(table_doses)
    data.frame(
      dose = d,
      table_dose = table_dose,
      short_stratum = 2 * d + 1,
      long_stratum = 2 * d,
      short_term_protection = get(table_dose, "short_term_protection"),
      long_term_protection = get(table_dose, "long_term_protection"),
      short_term_waning_years = if (vaccine_waning) get(table_dose, "short_term_waning") else NA_real_,
      long_term_waning_years = if (vaccine_waning) get(table_dose, "long_term_waning") else NA_real_
    )
  })
  tab <- do.call(rbind, rows)

  protection[tab$short_stratum] <- tab$short_term_protection
  protection[tab$long_stratum] <- tab$long_term_protection
  if (vaccine_waning) {
    short_w[tab$short_stratum] <- 1 / (tab$short_term_waning_years * 365)
    long_w[tab$long_stratum] <- 1 / (tab$long_term_waning_years * 365)
  }

  if (any(protection < 0 | protection > 1)) stop("Vaccine protection must be between 0 and 1")

  list(protection = protection, short_term_waning = short_w, long_term_waning = long_w, table = tab)
}

#' Should Vaccine Protection Wane?
#'
#' Resolves the `vaccine_waning` argument of the wrappers. `"default"` switches waning off for measles and uses the
#' vaccine parameter table for every other disease.
#'
#' The table has one-dose measles protection falling from 93\% to 85\% after 15 years and to nothing after a further
#' 25. Estimates of the waning of measles vaccine protection are far slower, about 0.04\% a year (Robert et al.,
#' Lancet Public Health 2024). The table's values did not matter while transmission was switched off from 1980,
#' but with transmission on they make measles endemic among adults in high-coverage settings.
#'
#' @param vaccine_waning `"default"`, `"table"`, `"none"`, or a logical.
#' @param disease Disease name.
#' @return Logical.
#' @keywords internal
resolve_vaccine_waning <- function(vaccine_waning, disease) {
  if (is.logical(vaccine_waning) && length(vaccine_waning) == 1 && !is.na(vaccine_waning)) return(vaccine_waning)
  vaccine_waning <- match.arg(vaccine_waning, c("default", "table", "none"))
  switch(vaccine_waning,
         default = !identical(tolower(disease), "measles"),
         table = TRUE,
         none = FALSE)
}

#' Build the Vaccination Rate Array
#'
#' Converts routine coverage by dose and supplementary immunisation activity (SIA) coverage into the daily
#' vaccination probabilities the model uses, indexed by age group, the stratum people are vaccinated out of, risk
#' group and year.
#'
#' Routine doses are given in the model age group that contains the scheduled age, at the rate that makes the share
#' vaccinated on leaving that group equal to the reported coverage (see [coverage_to_daily_rate()]). Dose 1 moves
#' people out of the unvaccinated stratum. Dose `d > 1` moves people out of both strata of dose `d - 1`, at the rate
#' that reproduces the coverage of dose `d` among those who have had dose `d - 1`.
#'
#' An SIA is applied in its year at the rate that reaches its coverage within the year, in every stratum that can
#' still receive a dose. Its coverage by single year of age is averaged over the model age group, weighted by
#' population, before it is converted to a rate.
#'
#' @param routine_coverage Matrix from [routine_dose_coverage()].
#' @param dose_ages Matrix from [routine_dose_ages()].
#' @param sia Data frame of SIA coverage with columns `year`, `age` (single years) and `coverage` (proportion), or
#'   `NULL`.
#' @param years Model years.
#' @param n_vacc Number of vaccination strata.
#' @param population Matrix of population by year (rows) and single year of age (columns, 0 to 100).
#' @param aggregate_age,new_age_breaks Age structure of the model.
#' @param coverage_accuracy Multiplier on the odds of vaccination.
#'
#' @return A data frame with columns `dim1` (age group), `dim2` (stratum left), `dim3`, `dim4` (year index), `year`
#'   and `value` (daily probability), holding non-zero entries only.
#' @keywords internal
build_vaccination_rates <- function(routine_coverage, dose_ages, sia, years, n_vacc, population,
                                    aggregate_age, new_age_breaks, coverage_accuracy = 1) {

  n_doses <- ncol(routine_coverage)
  aging <- model_aging_rate(aggregate_age, new_age_breaks)
  if (aggregate_age) {
    breaks <- new_age_breaks
    breaks[length(breaks)] <- Inf
    group_of_age <- function(age) findInterval(pmin(age, 100), breaks)
    n_age <- length(breaks) - 1
  } else {
    group_of_age <- function(age) pmin(floor(age), 100) + 1
    n_age <- 101
    aging <- rep(aging, n_age)
  }

  rate <- array(0, dim = c(n_age, n_vacc, length(years)))

  # Routine doses
  for (d in seq_len(n_doses)) {
    cov_d <- routine_coverage[, d]
    conditional <- if (d == 1) cov_d else ifelse(routine_coverage[, d - 1] > 0, pmin(cov_d / routine_coverage[, d - 1], 1), 0)
    strata <- if (d == 1) 1 else c(2 * d - 2, 2 * d - 1)
    for (y in which(conditional > 0)) {
      g <- group_of_age(dose_ages[y, d])
      rate[g, strata, y] <- coverage_to_daily_rate(conditional[y], aging[g], coverage_accuracy)
    }
  }

  # Supplementary immunisation activities
  if (!is.null(sia) && nrow(sia) > 0) {
    sia <- as.data.frame(sia)
    sia <- sia[!is.na(sia$coverage) & sia$coverage > 0 & sia$year %in% years & sia$age >= 0, , drop = FALSE]
    eligible <- seq_len(max(n_vacc - 2, 1))
    for (yr in unique(sia$year)) {
      y <- match(yr, years)
      this <- sia[sia$year == yr, , drop = FALSE]
      by_age <- rep(0, 101)
      cov_age <- tapply(this$coverage, pmin(this$age, 100), max)
      by_age[as.integer(names(cov_age)) + 1] <- adjust_coverage_odds(as.numeric(cov_age), coverage_accuracy)
      pop <- population[min(y, nrow(population)), ]
      groups <- group_of_age(0:100)
      coverage_group <- tapply(by_age * pop, groups, sum) / pmax(tapply(pop, groups, sum), 1e-12)
      daily_group <- 1 - (1 - pmin(coverage_group, 0.99))^(1 / 365)
      for (g in as.integer(names(daily_group))[daily_group > 0]) {
        rate[g, eligible, y] <- 1 - (1 - rate[g, eligible, y]) * (1 - daily_group[[as.character(g)]])
      }
    }
  }

  idx <- which(rate > 0, arr.ind = TRUE)
  data.frame(
    dim1 = idx[, 1],
    dim2 = idx[, 2],
    dim3 = rep(1, nrow(idx)),
    dim4 = idx[, 3],
    year = years[idx[, 3]],
    value = rate[idx]
  )
}
