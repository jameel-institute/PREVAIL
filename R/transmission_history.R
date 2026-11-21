#' Transmission and Seeding over the Historical Period
#'
#' Builds the time-varying basic reproduction number and the seeded infections for a historical run, under a stated
#' assumption about how reported cases relate to true infections.
#'
#' @section Reporting assumptions:
#' WHO case reports badly under-count infections in most settings, but how badly is not known. Until reporting
#' fractions are estimated (for example from seroprevalence surveys) the history has to be run under an assumption,
#' chosen with `transmission_history`:
#'
#' \describe{
#'   \item{`"circulating_years"`}{Reported cases are taken as evidence of whether the disease was circulating, not of
#'   how many infections there were. Transmission is on (at `R0`) in every year with at least
#'   `circulation_threshold` reported cases per million people, and in every year before reporting starts; it is off
#'   in years with fewer. A year with no report keeps the status of the year before. Pertussis is treated as
#'   circulating in every year, because it circulates everywhere whether or not it is reported. Reported cases
#'   (divided by `reporting_fraction`), and never fewer than `seed_floor` infections, are introduced on the first day
#'   of each year so that infection can return after fade-out. The number of infections is whatever the model implies.
#'   With `circulation_threshold = 0` transmission is on throughout (what `WHO_seed_switch = FALSE` meant in 0.1.0).}
#'   \item{`"reported_cases_only"`}{Case reporting and reported vaccination are taken as complete. Transmission runs
#'   at `R0` until the first year with a reported case and is switched off from then on; after that the only
#'   infections are the reported cases (divided by `reporting_fraction`), introduced on the first day of each year.
#'   This is the assumption PREVAIL 0.1.0 made, with `reporting_fraction = 1`.}
#' }
#'
#' Seeded infections enter the exposed compartment, placed across ages and vaccination strata in proportion to the
#' effective number of susceptibles on the day.
#'
#' `reporting_fraction` is where an estimated reporting level slots in: seeded infections are the reported cases
#' divided by it. It can be a single number or a vector named by year (years without a name take the value of the
#' nearest named year).
#'
#' @param case_reports Data frame of WHO case reports for one country and disease, with columns `year` and `cases`.
#'   Years with zero reported cases should be included; missing reports can be `NA` or absent.
#' @param population Matrix of population (thousands) by year (rows, in the order of `years`) and single year of
#'   age (columns).
#' @param years Model years.
#' @param R0 Basic reproduction number while transmission is on.
#' @param disease Disease name.
#' @param transmission_history The reporting assumption (see above).
#' @param circulation_threshold Reported cases per million people per year at or above which the disease is taken
#'   to be circulating. Default 2.
#' @param reporting_fraction Share of infections that are reported (default 1).
#' @param seed_floor Minimum number of infections introduced each year under `"circulating_years"` (default 10).
#'
#' @return A list with `R0` and `tt_R0` (days), `seed_data` (long format, by single year of age), `tt_seeded`
#'   (days), and `summary`, a data frame by year of reported cases, seeded infections and whether transmission was
#'   on.
#' @keywords internal
build_transmission_history <- function(case_reports, population, years, R0, disease,
                                       transmission_history = c("circulating_years", "reported_cases_only"),
                                       circulation_threshold = 2, reporting_fraction = 1, seed_floor = 10) {

  transmission_history <- match.arg(transmission_history)
  n_years <- length(years)
  if (length(R0) != 1 || !is.finite(R0) || R0 < 0) stop("R0 must be a single non-negative number")

  reported <- rep(NA_real_, n_years)
  if (!is.null(case_reports) && nrow(case_reports) > 0) {
    cr <- as.data.frame(case_reports)
    cr <- cr[!is.na(cr$cases) & cr$year %in% years, , drop = FALSE]
    if (nrow(cr) > 0) {
      by_year <- tapply(cr$cases, cr$year, sum)
      reported[match(as.numeric(names(by_year)), years)] <- as.numeric(by_year)
    }
  }
  fraction <- expand_reporting_fraction(reporting_fraction, years)
  infections_reported <- ifelse(is.na(reported), 0, round(reported / fraction))

  pop_rows <- pmin(seq_len(n_years), nrow(population))
  pop_total <- unname(rowSums(population)[pop_rows]) * 1000

  if (transmission_history == "reported_cases_only") {

    first_case <- which(!is.na(reported) & reported > 0)
    first_report <- which(!is.na(reported))
    off_index <- if (length(first_case)) first_case[1] else if (length(first_report)) first_report[1] else NA
    on <- if (is.na(off_index)) rep(TRUE, n_years) else seq_len(n_years) < off_index
    if (is.na(off_index)) {
      warning("No case reports found: transmission is left on for the whole period under 'reported_cases_only'")
      R0_out <- R0
      tt_R0 <- 0
    } else {
      R0_out <- c(R0, 0)
      tt_R0 <- c(0, max(1, (off_index - 1) * 365))
    }
    seeds <- infections_reported
    # one infection a day in the youngest age group until transmission is switched off, as in 0.1.0
    initial_daily_seed <- 1

  } else {

    if (tolower(disease) %in% always_circulating_diseases()) {
      on <- rep(TRUE, n_years)
    } else {
      on <- logical(n_years)
      status <- TRUE
      for (y in seq_len(n_years)) {
        if (!is.na(reported[y])) status <- reported[y] >= circulation_threshold * pop_total[y] / 1e6
        on[y] <- status
      }
    }
    R0_out <- ifelse(on, R0, 0)
    tt_R0 <- (seq_len(n_years) - 1) * 365
    seeds <- pmax(seed_floor, infections_reported)
    initial_daily_seed <- 0
  }

  # Seeded infections: a one-day pulse on the first day of the year, placed by age in proportion to the population.
  # Only the total matters to the model, which places them on susceptibles (see the seeding block in the odin code)
  n_single_age <- ncol(population)
  none <- rep(0, n_single_age)
  times <- 0
  by_age <- list(c(initial_daily_seed, none[-1]))
  if (initial_daily_seed > 0 && !any(seeds > 0) && !is.na(off_index)) {
    times <- c(times, max(1, (off_index - 1) * 365))
    by_age <- c(by_age, list(none))
  }
  for (y in which(seeds > 0)) {
    times <- c(times, (y - 1) * 365, (y - 1) * 365 + 1)
    by_age <- c(by_age, list(apportion_whole(seeds[y], population[pop_rows[y], ])), list(none))
  }
  # a pulse on day 0 replaces the initial slice
  keep <- !duplicated(times, fromLast = TRUE)
  times <- times[keep]
  by_age <- by_age[keep]
  ord <- order(times)
  tt_seeded <- times[ord]
  slices <- lapply(seq_along(ord), function(k) {
    v <- by_age[[ord[k]]]
    pos <- which(v > 0)
    if (length(pos)) {
      data.frame(dim1 = pos, dim2 = 1, dim3 = 1, dim4 = k, value = v[pos])
    } else {
      data.frame(dim1 = 1, dim2 = 1, dim3 = 1, dim4 = k, value = 0)
    }
  })

  list(
    R0 = R0_out,
    tt_R0 = tt_R0,
    seed_data = do.call(rbind, slices),
    tt_seeded = tt_seeded,
    summary = data.frame(
      year = years,
      reported_cases = reported,
      reporting_fraction = fraction,
      seeded_infections = seeds,
      transmission_on = on,
      population = pop_total
    )
  )
}

#' Diseases Treated as Circulating Every Year
#'
#' Under `transmission_history = "circulating_years"` these diseases have transmission on in every year whatever is
#' reported.
#'
#' @return Character vector of disease names.
#' @keywords internal
always_circulating_diseases <- function() {
  "pertussis"
}

#' Expand a Reporting Fraction to One Value per Year
#'
#' @param reporting_fraction A single number, or a numeric vector named by year.
#' @param years Model years.
#'
#' @return Numeric vector with one value per year.
#' @keywords internal
expand_reporting_fraction <- function(reporting_fraction, years) {
  if (!is.numeric(reporting_fraction) || anyNA(reporting_fraction) ||
      any(reporting_fraction <= 0) || any(reporting_fraction > 1)) {
    stop("reporting_fraction must be greater than 0 and no more than 1")
  }
  if (length(reporting_fraction) == 1 && is.null(names(reporting_fraction))) {
    return(rep(reporting_fraction, length(years)))
  }
  named_years <- suppressWarnings(as.numeric(names(reporting_fraction)))
  if (is.null(names(reporting_fraction)) || anyNA(named_years)) {
    stop("reporting_fraction must be a single number or a vector named by year")
  }
  vapply(years, function(y) reporting_fraction[[which.min(abs(named_years - y))]], numeric(1))
}

#' Split a Whole Number in Proportion to Weights
#'
#' Returns whole numbers that sum to `round(n)` and are as close as possible to `n * weights / sum(weights)`
#' (largest remainders). Used to place seeded infections by age without random sampling, so that the same inputs
#' always give the same parameters.
#'
#' @param n Total to split.
#' @param weights Non-negative weights.
#'
#' @return Integer-valued numeric vector the same length as `weights`.
#' @keywords internal
apportion_whole <- function(n, weights) {
  n <- round(n)
  weights <- as.numeric(weights)
  if (n <= 0 || sum(weights) <= 0) return(rep(0, length(weights)))
  raw <- n * weights / sum(weights)
  out <- floor(raw)
  left <- n - sum(out)
  if (left > 0) {
    add <- order(raw - out, decreasing = TRUE)[seq_len(left)]
    out[add] <- out[add] + 1
  }
  out
}
