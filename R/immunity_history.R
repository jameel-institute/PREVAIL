#' Effective Reproduction Number from a Model State
#'
#' Computes the effective reproduction number as the dominant eigenvalue of the next-generation matrix implied by
#' the model's force of infection.
#'
#' In the model someone of age `j` and vaccination stratum `w` infects, over their infectious period,
#' \deqn{R_0 (1 - m_w) C_{ij} S_{iv} (1 - m_v) / N_j}
#' people of age `i` and stratum `v`, where `m` is vaccine protection (which reduces both susceptibility and
#' infectiousness), `C` the contact matrix, `S` the susceptible population and `N_j` the population of age group
#' `j`. Collapsing over strata, the reproduction number is the dominant eigenvalue of
#' \deqn{M_{ij} = R_0 C_{ij} e_j, \quad e_j = \sum_v S_{jv} (1 - m_v)^2 / N_j.}
#' (Up to 0.2.0 the model divided by `N_i` instead, which gives a similar matrix with the same eigenvalue.)
#' Maternal antibodies reduce the susceptibility of the youngest age groups by `maternal`, which multiplies `e_j`.
#'
#' The model itself does not output a reproduction number. Up to 0.2.0 it had a `Reff` output, the unweighted mean
#' over age groups of the row sums of a related matrix, which is not a reproduction number (it read about 0.5 where
#' measles is endemic).
#'
#' @param S Susceptible population by age group and vaccination stratum (a matrix, or an array with a third
#'   dimension for risk groups, which is summed over).
#' @param N Total population by age group.
#' @param protection Vaccine protection by age group and vaccination stratum (the model's
#'   `age_vaccination_beta_modifier`), with the same dimensions as `S`, or a vector with one value per stratum.
#' @param contact_matrix The model's contact matrix.
#' @param R0 Basic reproduction number.
#' @param maternal Reduction in susceptibility from maternal antibodies by age group (a single number or one value
#'   per age group; see [maternal_protection()]). Default 0.
#'
#' @return The effective reproduction number (a single number).
#'
#' @examples
#' # a fully susceptible, unvaccinated population has an effective reproduction number of R0
#' C <- matrix(1 / 3, 3, 3)
#' effective_reproduction_number(S = matrix(100, 3, 1), N = rep(100, 3), protection = 0,
#'                               contact_matrix = C, R0 = 15)
#' @export
effective_reproduction_number <- function(S, N, protection, contact_matrix, R0, maternal = 0) {
  S <- collapse_risk(S)
  n_age <- nrow(S)
  n_vacc <- ncol(S)
  if (length(protection) == 1) {
    protection <- matrix(protection, n_age, n_vacc)
  } else if (is.null(dim(protection))) {
    if (length(protection) != n_vacc) stop("protection must have one value per vaccination stratum")
    protection <- matrix(protection, n_age, n_vacc, byrow = TRUE)
  } else {
    protection <- collapse_risk(protection, mean)
  }
  if (!all(dim(protection) == dim(S))) stop("S and protection must have the same dimensions")
  if (length(N) != n_age || nrow(contact_matrix) != n_age || ncol(contact_matrix) != n_age) {
    stop("N and contact_matrix must match the number of age groups in S")
  }

  e <- ifelse(N > 0, rowSums(S * (1 - protection)^2) / N, 0) * (1 - rep_len(maternal, n_age))
  M <- R0 * sweep(contact_matrix, 2, e, "*")
  if (all(M == 0)) return(0)
  max(Re(eigen(M, only.values = TRUE)$values))
}

#' Maternal Protection of Infants in a Model State
#'
#' The reduction in susceptibility the model applies to age groups up to `age_maternal_protection_ends`:
#' `protection_weight_vacc` times the share of women of reproductive age who are vaccinated and never infected, plus
#' `protection_weight_rec` times the share ever infected (capped at 1).
#'
#' @param state A list of arrays `S`, `E`, `I`, `R`, `Is` and `Rc` (age by stratum by risk group).
#' @param params The parameter list the state was produced with.
#'
#' @return Reduction in susceptibility by age group.
#' @keywords internal
maternal_protection <- function(state, params) {
  n_age <- params$n_age
  rw <- matrix(params$repro_weight, nrow = n_age)
  rw <- rw[, ncol(rw)]
  mums <- seq_len(n_age) >= params$repro_low & seq_len(n_age) <= params$repro_high
  by_age <- function(x, strata = TRUE) sum((rowSums(collapse_risk(x)[, strata, drop = FALSE]) * rw)[mums])
  n_vacc <- dim(state$S)[2]
  vaccinated <- if (n_vacc > 1) by_age(state$S, -1) + by_age(state$E, -1) else 0
  natural <- by_age(state$I) + by_age(state$R) + by_age(state$Is) + by_age(state$Rc)
  all <- by_age(state$S) + by_age(state$E) + natural
  if (all <= 0) return(rep(0, n_age))
  m <- min(max(params$protection_weight_vacc * vaccinated / all + params$protection_weight_rec * natural / all, 0), 1)
  ifelse(seq_len(n_age) <= params$age_maternal_protection_ends, m, 0)
}

#' Sum (or Average) an Array over its Risk Dimension
#'
#' @param x A matrix (age by stratum) or an array (age by stratum by risk group).
#' @param f Function applied over the risk dimension.
#' @return A matrix (age by stratum).
#' @keywords internal
collapse_risk <- function(x, f = sum) {
  if (length(dim(x)) == 3) {
    out <- apply(x, c(1, 2), f)
    dim(out) <- dim(x)[1:2]
    out
  } else if (length(dim(x)) == 2) {
    x
  } else {
    stop("Expected a matrix (age by stratum) or an array (age by stratum by risk group)")
  }
}

#' Summarise the Immunity of a Model State
#'
#' Summarises who is susceptible and who is immune, and why, in a model state.
#'
#' Everyone falls into one of four groups, which sum to one within each age group:
#' \describe{
#'   \item{`susceptible_unvaccinated`}{Never infected and unvaccinated (or protection fully waned).}
#'   \item{`susceptible_vaccinated`}{Never infected, vaccinated but not protected: the share `1 - m` of those in a
#'   vaccinated stratum with protection `m`.}
#'   \item{`immune_vaccine`}{Never infected and protected by vaccination: the share `m` of those in a vaccinated
#'   stratum.}
#'   \item{`immune_infection`}{Infected now or in the past (whether or not vaccinated).}
#' }
#' `susceptible` is the sum of the first two (effective susceptibility).
#'
#' @param state A list of arrays `S`, `E`, `I`, `R`, `Is` and `Rc` (age by stratum by risk group), as returned by
#'   `dust2::dust_unpack_state()`.
#' @param params The parameter list the state was produced with (for the contact matrix and vaccine protection).
#' @param R0 Basic reproduction number to use for the effective reproduction number.
#'
#' @return A list with `reff` (see [effective_reproduction_number()]), `population`, `susceptible` (effective
#'   susceptibility as a share of the population), `vaccinated` (share in any vaccinated stratum), `infected`
#'   (number currently infected) and `by_age`, a data frame with the shares above for each age group.
#' @export
summarise_immunity <- function(state, params, R0) {
  S <- collapse_risk(state$S)
  infected <- collapse_risk(state$E) + collapse_risk(state$I) + collapse_risk(state$Is)
  recovered <- collapse_risk(state$R) + collapse_risk(state$Rc)
  protection <- collapse_risk(params$age_vaccination_beta_modifier, mean)
  total <- S + infected + recovered
  N <- rowSums(total)
  share <- function(x) ifelse(N > 0, x / N, 0)

  n_vacc <- ncol(S)
  vaccinated_strata <- setdiff(seq_len(n_vacc), 1)
  susceptible_unvaccinated <- S[, 1]
  susceptible_vaccinated <- rowSums(S[, vaccinated_strata, drop = FALSE] * (1 - protection[, vaccinated_strata, drop = FALSE]))
  immune_vaccine <- rowSums(S[, vaccinated_strata, drop = FALSE] * protection[, vaccinated_strata, drop = FALSE])
  immune_infection <- rowSums(infected + recovered)

  age_labels <- if (!is.null(params$input_data$age_breaks) && nrow(S) > 1) {
    labs <- tryCatch(age_breaks_to_labels(params$input_data$age_breaks), error = function(e) NULL)
    if (length(labs) == nrow(S)) labs else as.character(seq_len(nrow(S)))
  } else {
    as.character(seq_len(nrow(S)))
  }

  by_age <- data.frame(
    age_group = seq_len(nrow(S)),
    age = age_labels,
    population = N,
    susceptible = share(susceptible_unvaccinated + susceptible_vaccinated),
    susceptible_unvaccinated = share(susceptible_unvaccinated),
    susceptible_vaccinated = share(susceptible_vaccinated),
    immune_vaccine = share(immune_vaccine),
    immune_infection = share(immune_infection),
    vaccinated = share(rowSums(total[, vaccinated_strata, drop = FALSE])),
    stringsAsFactors = FALSE
  )

  list(
    reff = effective_reproduction_number(S, N, protection, params$contact_matrix, R0, maternal_protection(state, params)),
    population = sum(N),
    susceptible = sum(susceptible_unvaccinated + susceptible_vaccinated) / sum(N),
    vaccinated = sum(total[, vaccinated_strata, drop = FALSE]) / sum(N),
    infected = sum(infected),
    by_age = by_age
  )
}

#' Run the Historical Period and Summarise Present-Day Immunity
#'
#' Runs the model from the first year of data (1950) to the start of `year_end` for one country and disease, under
#' a stated assumption about reporting, and returns the state at the end together with diagnostics that show what
#' the assumption implies.
#'
#' @param iso A 3-letter ISO country code.
#' @param disease `"measles"`, `"diphtheria"` or `"pertussis"`.
#' @param R0 Basic reproduction number while transmission is on.
#' @param transmission_history,circulation_threshold,reporting_fraction,coverage_accuracy,vaccine_waning,coverage_source,seed_floor
#'   The historical assumptions; see [data_load_process_wrapper()].
#' @param year_end The state returned is that at the start of this year. Default (`""`) is the current year.
#' @param seed Seed for the model's random number stream. Different seeds give different stochastic histories,
#'   which mainly sets where in its epidemic cycle a setting is at the end.
#' @param keep_params Logical; return the parameter list too? Default `FALSE`.
#' @param ... Further arguments passed to [custom_data_process_wrapper()] (for example custom data).
#'
#' @return A list of class `prevail_immunity_history` with:
#' \describe{
#'   \item{`iso`, `disease`, `R0`, `seed`, `year_start`, `year_end`}{What was run. The state is at the start of
#'   `year_end`.}
#'   \item{`assumptions`}{The historical assumptions used.}
#'   \item{`summary`}{`reff` (the effective reproduction number at `R0`, see [effective_reproduction_number()]),
#'   `population`, `susceptible` (effective susceptibility), `vaccinated` and `infected`.}
#'   \item{`by_age`}{Immunity by age group and source; see [summarise_immunity()].}
#'   \item{`infections`}{By year: modelled infections (all ages and under five), reported cases, the reporting
#'   fraction this implies (reported cases over modelled infections), seeded infections and whether transmission was
#'   on.}
#'   \item{`coverage`}{By age group and dose: the share of the age group that has had at least that many doses at
#'   the end of the run (`achieved`) against the mean reported routine coverage in the years its birth cohorts were
#'   due the dose (`reported`). Campaign doses, the coverage accuracy and, where vaccine protection wanes, waning
#'   out of a stratum all move `achieved` away from `reported`.}
#'   \item{`state`}{`S0`, `I0` (exposed and infectious) and `Rpop0` (recovered) by age group, vaccination stratum
#'   and risk group, rounded to whole people, ready to start a projection from; and `compartments`, the six model
#'   compartments unrounded.}
#'   \item{`inputs`}{Routine coverage and age group by dose in the final year, the final year's vaccination rates,
#'   protection and waning by stratum, whether the disease is taken to be circulating now, and the age distribution
#'   of the population.}
#' }
#'
#' @examples
#' \dontrun{
#' h <- run_immunity_history("GBR", "measles", R0 = 15, year_end = 2025)
#' h$summary$reff
#' h$by_age
#' }
#' @export
run_immunity_history <- function(iso, disease, R0,
                                 transmission_history = c("circulating_years", "reported_cases_only"),
                                 circulation_threshold = 2,
                                 reporting_fraction = 1,
                                 coverage_accuracy = 1,
                                 vaccine_waning = "default",
                                 coverage_source = c("wuenic", "median"),
                                 seed_floor = 10,
                                 year_end = "",
                                 seed = 1,
                                 keep_params = FALSE,
                                 ...) {

  transmission_history <- match.arg(transmission_history)
  coverage_source <- match.arg(coverage_source)

  params <- custom_data_process_wrapper(
    iso = iso, disease = disease, R0 = R0, cfr_off = TRUE, year_end = year_end,
    transmission_history = transmission_history, circulation_threshold = circulation_threshold,
    reporting_fraction = reporting_fraction, coverage_accuracy = coverage_accuracy,
    vaccine_waning = vaccine_waning, coverage_source = coverage_source, seed_floor = seed_floor, ...
  )

  year_start <- params$input_data$year_start
  year_end <- params$input_data$year_end
  n_years <- year_end - year_start
  if (n_years < 1) stop("year_end must be after year_start")

  sys <- dust2::dust_system_create(transmission_model(), params, n_particles = 1, seed = seed)
  dust2::dust_system_set_state_initial(sys)
  index <- dust2::dust_unpack_index(sys)
  n_age <- params$n_age
  first_age_group <- as.vector(index$new_case[1, , ])

  infections <- numeric(n_years)
  infections_first_age_group <- numeric(n_years)
  for (y in seq_len(n_years)) {
    days <- ((y - 1) * 365 + 1):(y * 365)
    new_case <- dust2::dust_system_simulate(sys, days, index_state = as.vector(index$new_case))
    by_state <- rowSums(new_case)
    infections[y] <- sum(by_state)
    infections_first_age_group[y] <- sum(by_state[match(first_age_group, as.vector(index$new_case))])
  }

  state <- dust2::dust_unpack_state(sys, dust2::dust_system_state(sys))
  compartments <- lapply(state[c("S", "E", "I", "R", "Is", "Rc")], function(x) {
    array(x, dim = c(params$n_age, params$n_vacc, params$n_risk))
  })
  immunity <- summarise_immunity(compartments, params, R0)

  history <- params$history$transmission[seq_len(n_years), , drop = FALSE]
  infections_df <- data.frame(
    year = history$year,
    infections = infections,
    infections_first_age_group = infections_first_age_group,
    reported_cases = history$reported_cases,
    implied_reporting = ifelse(infections > 0, history$reported_cases / infections, NA_real_),
    seeded_infections = history$seeded_infections,
    transmission_on = history$transmission_on
  )

  final_year <- n_years
  routine_latest <- params$history$routine_coverage[final_year, ]
  aging <- model_aging_rate(params$input_data$aggregate_age, as.numeric(strsplit(params$input_data$age_breaks, ";")[[1]]))
  dose_age_group <- vapply(params$history$dose_ages[final_year, ], function(a) {
    if (params$input_data$aggregate_age) {
      breaks <- as.numeric(strsplit(params$input_data$age_breaks, ";")[[1]])
      breaks[length(breaks)] <- Inf
      findInterval(min(a, 100), breaks)
    } else {
      min(floor(a), 100) + 1
    }
  }, numeric(1))
  on <- history$transmission_on
  pop_by_age <- immunity$by_age$population

  out <- list(
    iso = iso,
    disease = disease,
    R0 = R0,
    seed = seed,
    year_start = year_start,
    year_end = year_end,
    assumptions = list(
      transmission_history = params$input_data$transmission_history,
      circulation_threshold = circulation_threshold,
      reporting_fraction = reporting_fraction,
      coverage_accuracy = coverage_accuracy,
      vaccine_waning = params$input_data$vaccine_waning,
      coverage_source = coverage_source,
      seed_floor = seed_floor,
      demography_last_year = params$input_data$demography_last_year
    ),
    dims = list(n_age = params$n_age, n_vacc = params$n_vacc, n_risk = params$n_risk),
    age_breaks = params$input_data$age_breaks,
    summary = immunity[c("reff", "population", "susceptible", "vaccinated", "infected")],
    by_age = immunity$by_age,
    infections = infections_df,
    coverage = cohort_coverage(compartments, params),
    state = list(
      S0 = round(compartments$S),
      I0 = round(compartments$E + compartments$I + compartments$Is),
      Rpop0 = round(compartments$R + compartments$Rc),
      compartments = compartments
    ),
    inputs = list(
      routine_coverage = unname(routine_latest),
      routine_coverage_year = min(year_end - 1, max(attr(params$history$routine_coverage, "last_data_year"), na.rm = TRUE)),
      dose_age_group = unname(dose_age_group),
      vaccination_rates = params$vaccination_coverage[, , , final_year, drop = TRUE],
      vaccine_strata = params$history$vaccine_strata,
      circulating_now = on[n_years],
      last_circulating_year = if (any(on)) max(history$year[on]) else NA,
      age_distribution = pop_by_age / sum(pop_by_age),
      contact_matrix = params$contact_matrix,
      protection = collapse_risk(params$age_vaccination_beta_modifier, mean)
    )
  )
  if (keep_params) out$params <- params
  class(out) <- "prevail_immunity_history"
  out
}

#' Achieved Against Reported Coverage by Cohort
#'
#' For each age group at the end of a historical run, compares the share who have had at least each dose with the
#' reported routine coverage of that dose in the years the age group's birth cohorts were due it.
#'
#' @param compartments List of the six model compartments (age by stratum by risk group).
#' @param params Parameter list from the wrappers (with its `history` element).
#'
#' @return A data frame with columns `age_group`, `age`, `dose`, `achieved` and `reported`.
#' @keywords internal
cohort_coverage <- function(compartments, params) {
  total <- Reduce(`+`, lapply(compartments, collapse_risk))
  N <- rowSums(total)
  n_age <- nrow(total)
  n_vacc <- ncol(total)
  n_doses <- (n_vacc - 1) / 2
  years <- as.numeric(rownames(params$history$routine_coverage))
  year_end <- params$input_data$year_end
  aggregate_age <- params$input_data$aggregate_age
  breaks <- as.numeric(strsplit(params$input_data$age_breaks, ";")[[1]])
  labels <- if (aggregate_age) age_breaks_to_labels(params$input_data$age_breaks) else as.character(0:100)

  rows <- list()
  for (d in seq_len(n_doses)) {
    achieved <- ifelse(N > 0, rowSums(total[, (2 * d):n_vacc, drop = FALSE]) / N, 0)
    for (g in seq_len(n_age)) {
      ages <- if (aggregate_age) {
        lo <- breaks[g]
        hi <- min(breaks[g + 1] - 1, 100)
        lo:hi
      } else {
        g - 1
      }
      birth_years <- year_end - 1 - ages
      dose_age <- params$history$dose_ages[nrow(params$history$dose_ages), d]
      due_years <- birth_years + max(1, ceiling(dose_age))
      # only cohorts that are past the age at which the dose is given, and were due it within the model period
      due <- due_years[due_years %in% years & due_years < year_end & ages >= max(1, ceiling(dose_age))]
      reported <- if (length(due) == length(ages)) mean(params$history$routine_coverage[match(due, years), d]) else NA_real_
      rows[[length(rows) + 1]] <- data.frame(
        age_group = g, age = labels[g], dose = d, achieved = achieved[g], reported = reported,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

#' Run an Ensemble of Histories
#'
#' Runs [run_immunity_history()] for every combination of the basic reproduction numbers, coverage accuracies and
#' seeds given, so that the uncertainty in present-day immunity can be carried into projections. Each combination
#' is one "world".
#'
#' @param iso,disease Country and disease.
#' @param R0 Vector of basic reproduction numbers.
#' @param coverage_accuracy Vector of coverage accuracies (multipliers on the odds of vaccination).
#' @param seeds Vector of seeds.
#' @param R0_weights,accuracy_weights Optional weights for the values of `R0` and `coverage_accuracy` (in the same
#'   order). Equal weights by default. The weight of a world is the product of the two, shared equally among seeds.
#' @param cores Number of worlds to run in parallel (uses `parallel::mclapply()`; not available on Windows).
#' @param ... Further arguments passed to [run_immunity_history()], for example `transmission_history` or
#'   `year_end`.
#'
#' @return A list of class `prevail_immunity_ensemble` with `worlds` (a list of `prevail_immunity_history` objects,
#'   each with a `weight`), `grid` (a data frame of `R0`, `coverage_accuracy`, `seed`, `weight` and each world's
#'   summary) and `diagnostics` (weighted summaries across worlds; see [write_immunity_json()] for what they hold).
#'
#' @examples
#' \dontrun{
#' ens <- run_immunity_ensemble("GBR", "measles", R0 = c(12, 15, 18), coverage_accuracy = c(0.5, 1, 2),
#'                              seeds = 1:2, year_end = 2025)
#' write_immunity_json(ens, "GBR_measles.json")
#' }
#' @export
run_immunity_ensemble <- function(iso, disease, R0, coverage_accuracy = 1, seeds = 1,
                                  R0_weights = NULL, accuracy_weights = NULL, cores = 1, ...) {

  if (is.null(R0_weights)) R0_weights <- rep(1, length(R0))
  if (is.null(accuracy_weights)) accuracy_weights <- rep(1, length(coverage_accuracy))
  if (length(R0_weights) != length(R0) || length(accuracy_weights) != length(coverage_accuracy)) {
    stop("R0_weights and accuracy_weights must match the lengths of R0 and coverage_accuracy")
  }

  grid <- expand.grid(seed = seeds, coverage_accuracy = coverage_accuracy, R0 = R0, KEEP.OUT.ATTRS = FALSE)
  grid$weight <- R0_weights[match(grid$R0, R0)] * accuracy_weights[match(grid$coverage_accuracy, coverage_accuracy)]
  grid$weight <- grid$weight / sum(grid$weight)
  grid <- grid[, c("R0", "coverage_accuracy", "seed", "weight")]

  run_one <- function(i) {
    world <- run_immunity_history(
      iso = iso, disease = disease, R0 = grid$R0[i], coverage_accuracy = grid$coverage_accuracy[i],
      seed = grid$seed[i], ...
    )
    world$weight <- grid$weight[i]
    world
  }
  worlds <- if (cores > 1 && .Platform$OS.type != "windows") {
    parallel::mclapply(seq_len(nrow(grid)), run_one, mc.cores = cores)
  } else {
    lapply(seq_len(nrow(grid)), run_one)
  }
  failed <- vapply(worlds, inherits, logical(1), what = "try-error")
  if (any(failed)) stop("A historical run failed: ", as.character(worlds[[which(failed)[1]]]))

  grid$reff <- vapply(worlds, function(w) w$summary$reff, numeric(1))
  grid$susceptible <- vapply(worlds, function(w) w$summary$susceptible, numeric(1))
  grid$vaccinated <- vapply(worlds, function(w) w$summary$vaccinated, numeric(1))
  grid$population <- vapply(worlds, function(w) w$summary$population, numeric(1))
  grid$infected <- vapply(worlds, function(w) w$summary$infected, numeric(1))

  out <- list(
    iso = iso,
    disease = disease,
    worlds = worlds,
    grid = grid,
    diagnostics = ensemble_diagnostics(worlds)
  )
  class(out) <- "prevail_immunity_ensemble"
  out
}

#' Weighted Quantile
#'
#' @param x Values.
#' @param w Weights.
#' @param q Quantile (between 0 and 1).
#' @return The smallest value at which the cumulative weight reaches `q` of the total.
#' @keywords internal
weighted_quantile <- function(x, w, q) {
  keep <- !is.na(x)
  x <- x[keep]
  w <- w[keep]
  if (!length(x)) return(NA_real_)
  ord <- order(x)
  cum <- cumsum(w[ord]) / sum(w)
  x[ord][which(cum >= q - 1e-12)[1]]
}

#' Summaries across the Worlds of an Ensemble
#'
#' @param worlds List of `prevail_immunity_history` objects, each with a `weight`.
#' @param recent_years Number of final years over which infections and reported cases are averaged.
#' @param history_years Number of final years for which the yearly series are returned.
#'
#' @return A list; see the `diagnostics` element described in [write_immunity_json()].
#' @keywords internal
ensemble_diagnostics <- function(worlds, recent_years = 10, history_years = 25) {
  w <- vapply(worlds, function(x) if (is.null(x$weight)) 1 else x$weight, numeric(1))
  w <- w / sum(w)
  wq <- function(x, q) weighted_quantile(x, w, q)
  wmean_cols <- function(m) as.vector(m %*% w)

  reff <- vapply(worlds, function(x) x$summary$reff, numeric(1))
  susc <- vapply(worlds, function(x) x$summary$susceptible, numeric(1))
  first <- worlds[[1]]
  by_age_cols <- c("susceptible", "susceptible_unvaccinated", "susceptible_vaccinated", "immune_vaccine",
                   "immune_infection", "vaccinated")
  by_age <- data.frame(age_group = first$by_age$age_group, age = first$by_age$age, stringsAsFactors = FALSE)
  for (col in by_age_cols) by_age[[col]] <- wmean_cols(vapply(worlds, function(x) x$by_age[[col]], numeric(nrow(first$by_age))))

  inf <- first$infections
  n <- nrow(inf)
  keep <- seq(max(1, n - history_years + 1), n)
  recent <- seq(max(1, n - recent_years + 1), n)
  inf_matrix <- vapply(worlds, function(x) x$infections$infections, numeric(n))
  dim(inf_matrix) <- c(n, length(worlds))
  inf_recent <- colMeans(inf_matrix[recent, , drop = FALSE])
  reported_recent <- inf$reported_cases[recent]
  reported_mean <- if (all(is.na(reported_recent))) NA_real_ else mean(reported_recent, na.rm = TRUE)

  coverage <- first$coverage[, c("age_group", "age", "dose", "reported")]
  coverage$achieved <- wmean_cols(vapply(worlds, function(x) x$coverage$achieved, numeric(nrow(first$coverage))))

  r0_values <- sort(unique(vapply(worlds, function(x) x$R0, numeric(1))))
  by_R0 <- lapply(r0_values, function(r) {
    sel <- vapply(worlds, function(x) x$R0 == r, logical(1))
    list(R0 = r, reff = weighted_quantile(reff[sel], w[sel], 0.5), susceptible = weighted_quantile(susc[sel], w[sel], 0.5))
  })

  list(
    n_worlds = length(worlds),
    reff = list(lo = wq(reff, 0.025), q1 = wq(reff, 0.25), med = wq(reff, 0.5), q3 = wq(reff, 0.75), hi = wq(reff, 0.975)),
    p_reff_above_1 = sum(w[reff > 1]),
    susceptible = list(lo = wq(susc, 0.025), med = wq(susc, 0.5), hi = wq(susc, 0.975)),
    by_age = by_age,
    infections_per_year = list(lo = wq(inf_recent, 0.025), med = wq(inf_recent, 0.5), hi = wq(inf_recent, 0.975)),
    reported_per_year = reported_mean,
    implied_reporting = if (is.na(reported_mean)) NULL else list(
      lo = reported_mean / max(1, wq(inf_recent, 0.975)),
      med = reported_mean / max(1, wq(inf_recent, 0.5)),
      hi = reported_mean / max(1, wq(inf_recent, 0.025))
    ),
    history = list(
      year = inf$year[keep],
      reported_cases = inf$reported_cases[keep],
      transmission_on = inf$transmission_on[keep],
      infections_med = apply(inf_matrix[keep, , drop = FALSE], 1, wq, q = 0.5),
      infections_lo = apply(inf_matrix[keep, , drop = FALSE], 1, wq, q = 0.025),
      infections_hi = apply(inf_matrix[keep, , drop = FALSE], 1, wq, q = 0.975)
    ),
    coverage_by_cohort = coverage,
    by_R0 = by_R0
  )
}

#' Write Present-Day Immunity as JSON
#'
#' Writes the result of [run_immunity_history()] or [run_immunity_ensemble()] as a JSON file that a website (or
#' anything else) can start projections from, without rebuilding PREVAIL's inputs.
#'
#' @section Schema:
#' All indices are 1-based. Arrays over age group and vaccination stratum are flattened in column-major order
#' (age group varies fastest), so element `i + n_age * (j - 1)` is age group `i`, stratum `j`. Stratum 1 is
#' unvaccinated; dose `d` has a long-term stratum `2d` and a short-term stratum `2d + 1`.
#'
#' \describe{
#'   \item{`schema_version`, `prevail_version`, `generated`}{Version of this schema (1), of PREVAIL, and the date.}
#'   \item{`iso`, `disease`}{Country and disease.}
#'   \item{`year_start`}{The year the state refers to (its first day): where a projection starts.}
#'   \item{`history_year_start`}{First year of the historical run.}
#'   \item{`dims`}{`n_age`, `n_vacc`, `n_risk`.}
#'   \item{`age_breaks`}{Lower bounds of the age groups, separated by semicolons, ending in `Inf`.}
#'   \item{`assumptions`}{`transmission_history`, `circulation_threshold`, `reporting_fraction`, `vaccine_waning`,
#'   `coverage_source`, `seed_floor`, `demography_last_year` (demography is carried forward from this year).}
#'   \item{`routine`}{`coverage`: reported routine coverage by dose in the final year (carried forward from
#'   `year`); `dose_age_group`: the age group each dose is given in; `rates`: the final year's daily vaccination
#'   probabilities by age group and the stratum people leave (flattened), at a coverage accuracy of 1.}
#'   \item{`circulating`}{`now`: is the disease taken to be circulating in the final year; `last_year`: the last
#'   year it was; `threshold_per_million`.}
#'   \item{`vaccine`}{For each dose: `dose`, and for `short` and `long`: `stratum`, `protection`, and `years` (mean
#'   time before waning, `null` if protection does not wane).}
#'   \item{`protection`}{Vaccine protection by age group and stratum (flattened).}
#'   \item{`contact_matrix`}{The contact matrix (flattened, `n_age` by `n_age`).}
#'   \item{`age_distribution`}{Share of the population in each age group (for placing introductions by age).}
#'   \item{`worlds`}{One entry per historical run: `R0`, `accuracy` (coverage accuracy), `seed`, `w` (weight;
#'   weights sum to 1), `reff` (effective reproduction number at `R0`), `susc` (effective susceptibility), `vacc`
#'   (share in a vaccinated stratum), `population`, `infected`, and the state `S0`, `I0` (exposed and infectious)
#'   and `Rpop0` (recovered), each flattened and in whole people.}
#'   \item{`diagnostics`}{Across worlds (weighted): `n_worlds`; `reff` (`lo`, `q1`, `med`, `q3`, `hi`: 2.5\%, 25\%,
#'   50\%, 75\% and 97.5\% quantiles); `p_reff_above_1`; `susceptible` (`lo`, `med`, `hi`); `by_age` (mean shares
#'   by age group: `susceptible`, `susceptible_unvaccinated`, `susceptible_vaccinated`, `immune_vaccine`,
#'   `immune_infection`, `vaccinated`; see [summarise_immunity()]); `infections_per_year` (mean of the final ten
#'   years: `lo`, `med`, `hi`); `reported_per_year`; `implied_reporting` (reported cases over modelled
#'   infections); `history` (final 25 years: `year`, `reported_cases`, `transmission_on`, `infections_med`,
#'   `infections_lo`, `infections_hi`); `coverage_by_cohort` (`age_group`, `age`, `dose`, `achieved`, `reported`);
#'   `by_R0` (median `reff` and `susceptible` for each `R0`).}
#' }
#'
#' @param x A `prevail_immunity_history` or `prevail_immunity_ensemble` object.
#' @param file Path of the JSON file to write. If `NULL` the JSON is returned as a string instead.
#' @param digits Significant digits for non-integer numbers. Default 6.
#' @param pretty Logical; indent the JSON? Default `FALSE`.
#'
#' @return The list that was written (invisibly), or the JSON string if `file` is `NULL`.
#' @export
write_immunity_json <- function(x, file = NULL, digits = 6, pretty = FALSE) {

  if (inherits(x, "prevail_immunity_history")) {
    if (is.null(x$weight)) x$weight <- 1
    x <- structure(list(iso = x$iso, disease = x$disease, worlds = list(x), diagnostics = ensemble_diagnostics(list(x))),
                   class = "prevail_immunity_ensemble")
  }
  if (!inherits(x, "prevail_immunity_ensemble")) {
    stop("x must come from run_immunity_history() or run_immunity_ensemble()")
  }

  first <- x$worlds[[1]]
  flat <- function(a) I(as.numeric(as.vector(a)))
  weights <- vapply(x$worlds, function(w) w$weight, numeric(1))
  weights <- weights / sum(weights)

  # the final year's rates at a coverage accuracy of 1 (the world with accuracy nearest 1)
  accuracy <- vapply(x$worlds, function(w) w$assumptions$coverage_accuracy, numeric(1))
  reference <- x$worlds[[which.min(abs(log(accuracy)))]]

  strata <- first$inputs$vaccine_strata
  null_if_na <- function(v) if (is.na(v)) NULL else v
  vaccine <- lapply(seq_len(nrow(strata)), function(i) {
    list(
      dose = strata$dose[i],
      short = list(stratum = strata$short_stratum[i], protection = strata$short_term_protection[i],
                   years = null_if_na(strata$short_term_waning_years[i])),
      long = list(stratum = strata$long_stratum[i], protection = strata$long_term_protection[i],
                  years = null_if_na(strata$long_term_waning_years[i]))
    )
  })

  out <- list(
    schema_version = 1,
    prevail_version = as.character(utils::packageVersion("PREVAIL")),
    generated = as.character(Sys.Date()),
    iso = x$iso,
    disease = x$disease,
    year_start = first$year_end,
    history_year_start = first$year_start,
    dims = first$dims,
    age_breaks = first$age_breaks,
    assumptions = first$assumptions[c("transmission_history", "circulation_threshold", "reporting_fraction",
                                      "vaccine_waning", "coverage_source", "seed_floor", "demography_last_year")],
    routine = list(
      coverage = I(first$inputs$routine_coverage),
      year = first$inputs$routine_coverage_year,
      dose_age_group = I(first$inputs$dose_age_group),
      rates = flat(reference$inputs$vaccination_rates)
    ),
    circulating = list(
      now = first$inputs$circulating_now,
      last_year = null_if_na(first$inputs$last_circulating_year),
      threshold_per_million = first$assumptions$circulation_threshold
    ),
    vaccine = vaccine,
    protection = flat(first$inputs$protection),
    contact_matrix = flat(first$inputs$contact_matrix),
    age_distribution = I(first$inputs$age_distribution),
    worlds = lapply(seq_along(x$worlds), function(i) {
      w <- x$worlds[[i]]
      list(
        R0 = w$R0,
        accuracy = w$assumptions$coverage_accuracy,
        seed = w$seed,
        w = weights[i],
        reff = w$summary$reff,
        susc = w$summary$susceptible,
        vacc = w$summary$vaccinated,
        population = round(w$summary$population),
        infected = round(w$summary$infected),
        S0 = flat(w$state$S0),
        I0 = flat(w$state$I0),
        Rpop0 = flat(w$state$Rpop0)
      )
    }),
    diagnostics = x$diagnostics
  )
  out$assumptions$reporting_fraction <- I(unname(out$assumptions$reporting_fraction))

  json <- jsonlite::toJSON(out, auto_unbox = TRUE, digits = I(digits), null = "null", na = "null",
                           dataframe = "columns", pretty = pretty)
  if (is.null(file)) return(json)
  writeLines(json, file)
  invisible(out)
}
