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
#' The rate applies across the whole age group, from its first day. With the default five-year age groups a dose
#' scheduled at 9 months is given at a constant rate from birth to age 5, so the model's infants are as likely to be
#' vaccinated as its four year olds: too many vaccinated infants and too few vaccinated four year olds, with the
#' right coverage on leaving the group. The age structure cannot do better than this; for questions about infants
#' use finer age groups (for example `new_age_breaks = c(0, 1, 2, 5, 10, ...)`).
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
#' The table has two rows of doses per disease (measles 1 and 2; diphtheria 1 and 6; pertussis 3 and 5). For
#' measles each modelled dose uses its own row. For DTP the `dose` tag is the number of doses received when the
#' estimate applies: the first row (diphtheria 1, pertussis 3) is the three-dose primary series and the second
#' (diphtheria 6, pertussis 5) the full schedule including boosters. So the three primary doses (`n_primary`) get the
#' first row and every booster (doses 4 to 6, see [dtp_booster_schedule()]) the second. That overstates protection
#' after one or two primary doses, and after a first booster; values for partial courses belong in the table as their
#' own rows, not in code.
#'
#' @param vaccine_parameters Vaccine parameter table for one disease, with columns `parameter`, `value`, `dose`.
#' @param n_vacc Number of vaccination strata in the model.
#' @param vaccine_waning Logical; if `FALSE` vaccine protection does not wane (both waning rates are zero and
#'   everyone stays in the short-term stratum of their last dose).
#' @param n_primary Number of doses in the primary series (3 for DTP), which take the table's first row while later
#'   doses take its last. `NULL` (measles): each dose takes its own row, or the first row if it has none.
#'
#' @return A list with `protection`, `short_term_waning` and `long_term_waning` (vectors of length `n_vacc`; waning
#'   as daily probabilities) and `table`, a data frame describing each dose.
#' @keywords internal
vaccine_strata_parameters <- function(vaccine_parameters, n_vacc, vaccine_waning = TRUE, n_primary = NULL) {

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
    table_dose <- if (!is.null(n_primary)) {
      if (d <= n_primary) min(table_doses) else max(table_doses)
    } else if (d %in% table_doses) d else min(table_doses)
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

#' DTP Booster Doses from the WHO Schedule
#'
#' Finds the booster doses of diphtheria- or pertussis-containing vaccine in a country's routine schedule, so that the
#' model can give them as doses 4, 5 and 6 after the three-dose primary series.
#'
#' The schedule is the latest one in the data for the country. Every diphtheria-containing product counts (infant
#' combinations, DT, the school-age Td and Tdap boosters), except doses for adults, pregnant women, travellers or
#' catch-up. The first three distinct ages are the primary series, and each later distinct age before 18 years is a
#' booster, up to three. A booster protects against pertussis only if a product given at that age contains pertussis
#' antigen (DTwP, DTaP, Tdap): a school-age Td booster boosts diphtheria but not pertussis.
#'
#' WHO reports booster coverage as the 4th, 5th and 6th diphtheria-containing dose, so the `coverage_dose` of each
#' booster is its rank among the diphtheria boosters (4, 5 or 6), whichever disease is modelled. A booster whose WHO
#' dose has no coverage data for the country is left out (the United States, for example, reports only the 4th), as
#' it would otherwise add strata that nobody enters.
#'
#' @param vaccination_schedule WHO schedule data (all countries or one).
#' @param iso Country code.
#' @param disease `"diphtheria"` or `"pertussis"`.
#' @param routine_vaccination WHO routine coverage data, used to drop boosters without coverage. `NULL` keeps all.
#'
#' @return A data frame with one row per modelled booster: `dose` (4, 5, 6), `age` (years), `pertussis` (logical),
#'   `coverage_dose` and `vaccine_codes`. Zero rows if the schedule has no boosters.
#' @keywords internal
dtp_booster_schedule <- function(vaccination_schedule, iso, disease, routine_vaccination = NULL) {
  none <- data.frame(dose = integer(0), age = numeric(0), pertussis = logical(0), coverage_dose = integer(0),
                     vaccine_codes = character(0))
  s <- as.data.frame(vaccination_schedule)
  if (!all(c("iso3", "year", "vaccine_code", "age_administered") %in% names(s))) return(none)
  s <- s[s$iso3 == iso & !is.na(s$age_administered) & grepl("^(DT|TD|DIP)", s$vaccine_code), , drop = FALSE]
  s <- s[!grepl("ADULT|CATCHUP|PREG|TRAVEL", paste(s$target_pop, s$target_pop_description), ignore.case = TRUE) &
           !grepl("contact", s$age_administered), , drop = FALSE]
  if (nrow(s) == 0) return(none)
  s <- s[s$year == max(s$year), , drop = FALSE]
  s$age_years <- parse_schedule_age(s$age_administered)
  s <- resolve_relative_schedule_ages(s)
  s <- s[!is.na(s$age_years) & s$age_years < 18, , drop = FALSE]
  ages <- sort(unique(round(s$age_years, 3)))
  if (length(ages) <= 3) return(none)

  boosters <- utils::head(ages[-(1:3)], 3)
  out <- data.frame(
    age = boosters,
    pertussis = vapply(boosters, function(a) any(grepl("AP|WP", s$vaccine_code[round(s$age_years, 3) == a])), logical(1)),
    coverage_dose = 3L + seq_along(boosters),
    vaccine_codes = vapply(boosters, function(a) paste(unique(s$vaccine_code[round(s$age_years, 3) == a]), collapse = ";"),
                           character(1))
  )
  if (identical(tolower(disease), "pertussis")) out <- out[out$pertussis, , drop = FALSE]
  rv <- as.data.frame(routine_vaccination)
  if (nrow(rv) && all(c("iso3", "vaccine", "coverage") %in% names(rv))) {
    reported <- unique(rv$vaccine[rv$iso3 == iso & !is.na(rv$coverage) & rv$coverage > 0])
    out <- out[paste0("DIPHCV", out$coverage_dose) %in% reported, , drop = FALSE]
  }
  if (nrow(out) == 0) return(none)
  out$dose <- 3L + seq_len(nrow(out))
  out[, c("dose", "age", "pertussis", "coverage_dose", "vaccine_codes")]
}

#' Coverage of DTP Booster Doses
#'
#' WHO booster coverage (the 4th to 6th diphtheria-containing doses) only starts in 2018. Before the first year with
#' data, each booster's coverage is taken as the same share of DTP3 coverage as in its first years with data (the
#' mean over up to three years), from `booster_since` on, and zero before that. This keeps a booster that was already
#' routine in 2018 for the earlier cohorts that serosurveys sample. Where a booster was introduced recently, set
#' `booster_since` to its introduction year, or give coverage directly with `custom_routine_vaccination`.
#'
#' @param routine_coverage Matrix from [routine_dose_coverage()] (proportions; doses 1 to 3 then the boosters).
#' @param years Model years.
#' @param booster_since First year in which boosters can be given before their coverage data start.
#'
#' @return `routine_coverage` with booster coverage filled in before its data, and no dose above the one before it.
#' @keywords internal
backfill_booster_coverage <- function(routine_coverage, years, booster_since = 1980) {
  last <- attr(routine_coverage, "last_data_year")
  n_doses <- ncol(routine_coverage)
  if (n_doses <= 3) return(routine_coverage)
  for (d in 4:n_doses) {
    with_data <- which(routine_coverage[, d] > 0 & routine_coverage[, 3] > 0)
    if (!length(with_data)) next
    first <- with_data[seq_len(min(3, length(with_data)))]
    share <- mean(routine_coverage[first, d] / routine_coverage[first, 3])
    before <- seq_len(min(with_data) - 1)
    before <- before[years[before] >= booster_since]
    routine_coverage[before, d] <- pmin(share * routine_coverage[before, 3], routine_coverage[before, d - 1])
  }
  for (d in 2:n_doses) routine_coverage[, d] <- pmin(routine_coverage[, d], routine_coverage[, d - 1])
  attr(routine_coverage, "last_data_year") <- last
  routine_coverage
}

#' Whole-Cell or Acellular Pertussis Vaccine
#'
#' Reads the type of pertussis vaccine used for the primary series from a country's latest WHO schedule: whole-cell
#' if any infant DTP product given in the first year of life is whole-cell (DTwP), acellular otherwise. The schedule
#' data are one recent snapshot, so the type found is applied to every year; many high-income countries used
#' whole-cell vaccine before moving to acellular in the 1990s and 2000s.
#'
#' @param vaccination_schedule WHO schedule data.
#' @param iso Country code.
#' @return `"whole_cell"` or `"acellular"`.
#' @keywords internal
pertussis_vaccine_type <- function(vaccination_schedule, iso) {
  s <- as.data.frame(vaccination_schedule)
  if (!all(c("iso3", "year", "vaccine_code", "age_administered") %in% names(s))) return("acellular")
  s <- s[s$iso3 == iso & grepl("^DT", s$vaccine_code), , drop = FALSE]
  if (nrow(s)) s <- s[s$year == max(s$year), , drop = FALSE]
  infant <- s[!is.na(parse_schedule_age(s$age_administered)) & parse_schedule_age(s$age_administered) < 1, , drop = FALSE]
  if (any(grepl("WP", infant$vaccine_code))) "whole_cell" else "acellular"
}

#' Use the Whole-Cell or Acellular Pertussis Rows of the Vaccine Table
#'
#' The vaccine parameter table's pertussis rows tagged `DTP` come from studies of acellular vaccine (Witt et al. 2012,
#' Klein et al. 2012). Rows tagged `DTwP` replace the primary-series rows for whole-cell vaccine. Booster rows are
#' shared. Rows for other vaccines (including custom rows) are left as they are.
#'
#' @param vaccine_parameters Vaccine parameter table for pertussis.
#' @param type `"acellular"` or `"whole_cell"`.
#' @return The table with one set of primary-series rows.
#' @keywords internal
select_pertussis_vaccine <- function(vaccine_parameters, type = c("acellular", "whole_cell")) {
  type <- match.arg(type)
  vp <- as.data.frame(vaccine_parameters)
  wp <- vp$vaccine == "DTwP"
  if (type == "whole_cell" && any(wp)) {
    vp <- vp[!(vp$vaccine == "DTP" & vp$dose %in% vp$dose[wp]), , drop = FALSE]
  } else {
    vp <- vp[!wp, , drop = FALSE]
  }
  vp
}
