#' Modelled Seroprevalence for Serosurvey Age Bands
#'
#' Converts immunity by model age group from [run_immunity_history()] into the share expected to test seropositive
#' in each age band of a serosurvey taken at the end of the run.
#'
#' The true seropositive share in a model age group is
#' \deqn{p = \textrm{immune\_infection} + v \cdot \textrm{immune\_vaccine} + m \cdot \textrm{susceptible}}
#' where `v` (`vaccine_seropositive`) is the share of vaccine-protected people who still have detectable antibody
#' and `m` is maternal protection (only when `maternal = TRUE`), counted as antibody among those not otherwise
#' immune. Model age groups are weighted by population and by how much of each group the band covers, taking ages
#' to be spread evenly within a group. The test then gives
#' \deqn{p_{obs} = \textrm{sensitivity} \cdot p + (1 - \textrm{specificity}) (1 - p).}
#'
#' @param history Output of [run_immunity_history()] with `year_end` the survey year (for `maternal = TRUE` it
#'   needs `keep_params = TRUE`).
#' @param age_min,age_max Lower and upper age of each band in years, with the upper limit inclusive as surveys
#'   report it (`5` and `9` for "5-9 years"); use `NA` for an open top band. Fractional ages are allowed (months / 12).
#' @param sensitivity,specificity Assay sensitivity and specificity. Default 1.
#' @param vaccine_seropositive Share of vaccine-protected people who test positive. Default 1.
#' @param maternal Logical; count maternal antibody in infants as seropositive? Default `FALSE`.
#'
#' @return Numeric vector of expected seropositive shares, one per band.
#' @examples
#' h <- list(by_age = data.frame(population = c(100, 100), immune_infection = c(0.1, 0.5),
#'                               immune_vaccine = c(0.6, 0.4), susceptible = c(0.3, 0.1)),
#'           age_breaks = "0;5;Inf")
#' modelled_seroprevalence(h, age_min = c(0, 2), age_max = c(4, 9))
#' @export
modelled_seroprevalence <- function(history, age_min, age_max = NA, sensitivity = 1, specificity = 1,
                                    vaccine_seropositive = 1, maternal = FALSE) {
  by_age <- history$by_age
  n_age <- nrow(by_age)
  breaks <- as.numeric(strsplit(history$age_breaks, ";", fixed = TRUE)[[1]])
  if (length(breaks) == n_age + 1) {
    lower <- breaks[-length(breaks)]
    upper <- breaks[-1]
  } else {
    # single-year model: group i holds age i - 1, the last group everyone older
    lower <- seq_len(n_age) - 1
    upper <- c(seq_len(n_age - 1), Inf)
  }
  upper[length(upper)] <- Inf

  p <- by_age$immune_infection + vaccine_seropositive * by_age$immune_vaccine
  if (maternal) {
    if (is.null(history$params)) stop("maternal = TRUE needs run_immunity_history(keep_params = TRUE)")
    p <- p + maternal_protection(history$state$compartments, history$params) * by_age$susceptible
  }
  p <- pmin(pmax(p, 0), 1)

  age_max <- rep_len(age_max, length(age_min))
  band_upper <- ifelse(is.na(age_max), Inf, age_max + ifelse(age_max == floor(age_max), 1, 0))
  vapply(seq_along(age_min), function(b) {
    top <- pmin(upper, band_upper[b])
    bottom <- pmax(lower, age_min[b])
    width <- ifelse(is.finite(upper), upper - lower, 1)
    covered <- ifelse(is.finite(upper), pmax(top - bottom, 0) / width, as.numeric(bottom < band_upper[b]))
    w <- covered * by_age$population
    if (sum(w) <= 0) return(NA_real_)
    true <- sum(w * p) / sum(w)
    sensitivity * true + (1 - specificity) * (1 - true)
  }, numeric(1))
}

#' Log-Likelihood of Serosurvey Data
#'
#' Binomial (or beta-binomial) log-likelihood of seropositive counts by age band given modelled seroprevalence.
#'
#' @param n_pos,n_tested Seropositive and tested counts by age band. Bands with missing counts are dropped.
#' @param p Modelled seroprevalence by band (see [modelled_seroprevalence()]).
#' @param overdispersion Beta-binomial intra-class correlation in \[0, 1). `0` (default) is binomial. Use it to
#'   allow for survey design effects and model misfit.
#'
#' @return The log-likelihood (a single number).
#' @examples
#' serosurvey_loglik(n_pos = c(80, 95), n_tested = c(100, 100), p = c(0.8, 0.9))
#' @export
serosurvey_loglik <- function(n_pos, n_tested, p, overdispersion = 0) {
  keep <- !is.na(n_pos) & !is.na(n_tested) & !is.na(p) & n_tested > 0
  n_pos <- round(n_pos[keep])
  n_tested <- round(n_tested[keep])
  p <- pmin(pmax(p[keep], 1e-6), 1 - 1e-6)
  if (overdispersion <= 0) return(sum(stats::dbinom(n_pos, n_tested, p, log = TRUE)))
  if (overdispersion >= 1) stop("overdispersion must be below 1")
  # beta-binomial with mean p and intra-class correlation rho: a = p (1 - rho) / rho, b = (1 - p) (1 - rho) / rho
  k <- (1 - overdispersion) / overdispersion
  a <- p * k
  b <- (1 - p) * k
  sum(lchoose(n_tested, n_pos) + lbeta(n_pos + a, n_tested - n_pos + b) - lbeta(a, b))
}
