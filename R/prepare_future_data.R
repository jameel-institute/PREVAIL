#' Prepare Future Scenario Parameters for Transmission Model
#'
#' This function generates an updated parameter list for projecting future scenarios in a transmission model.
#' It modifies the vaccination coverage, R0 values, and seeding of new cases based on a user-specified set
#' of future events. It also resets migration, birth, and death inputs to their final known values.
#'
#' @param params A named list of model parameters as used in the core transmission model.
#' @param future_events A `data.frame` specifying future event timepoints and modifications. Must contain:
#'   \itemize{
#'     \item \code{time}: Future time (numeric).
#'     \item \code{relative_coverage}: Multiplicative modifier to vaccination coverage. Applied to coverage, not
#'       to the daily rate: see [scale_vaccination_rates()].
#'     \item \code{R0}: Basic reproduction number for each future timepoint.
#'     \item \code{introduced_cases}: Number of seed infections to introduce at each timepoint (once, on the day
#'       of the event).
#'   }
#' @param current_susceptibility A named list with updated `S0`, `Rpop0` values reflecting the final simulation state.
#'
#' @return A modified version of the `params` list ready to run forward simulations under future scenarios.
#' @importFrom abind abind
#' @importFrom data.table last
#' @importFrom stats rbinom
#' @export
prepare_future_data <- function(params, future_events, current_susceptibility) {

  ## --- Initialize ---
  new_params <- params
  n_future <- nrow(future_events)
  future_event_tt <- future_events$time
  new_params$input_data$year_start <- if(new_params$input_data$year_end == "") 2024 else new_params$input_data$year_end

  # Re-establish CFR
  new_params$cfr_normal <- new_params$cfr_normal_real
  new_params$cfr_severe <- new_params$cfr_severe_real

  ## --- Extend Vaccination Coverage ---
  prior_vacc <- params$vaccination_coverage

  final_vacc <- {
    idx <- max(which(sapply(seq_len(dim(params$vaccination_coverage)[4]),
                            function(i) !all(params$vaccination_coverage[,,,i] == 0))))
    params$vaccination_coverage[,,,idx, drop = TRUE]
  }

  dim(final_vacc) <- c(dim(prior_vacc)[1:3], 1)

  vacc_array <- abind::abind(
    replicate(n = n_future, expr = final_vacc, simplify = FALSE),
    along = 4
  )

  for (i in seq_len(n_future)) {
    vacc_array[, , , i] <- scale_vaccination_rates(
      rates = array(final_vacc, dim = dim(prior_vacc)[1:3]),
      aging_rate = as.numeric(params$aging_rate),
      relative_coverage = future_events$relative_coverage[i]
    )
  }

  new_params$vaccination_coverage <- vacc_array
  new_params$tt_vaccination_coverage <- future_event_tt
  new_params$no_vacc_changes <- n_future

  ## --- Update R0 ---
  new_params$R0 <- future_events$R0
  new_params$tt_R0 <- future_event_tt
  new_params$no_R0_changes <- n_future

  ## --- Disable Migration ---
  new_params$tt_migration <- 0
  new_params$no_migration_changes <- 1

  final_mig <- {
    idx <- max(which(sapply(seq_len(dim(params$migration_in_number)[4]),
                            function(i) !all(params$migration_in_number[,,,i] == 0))))
               params$migration_in_number[,,,idx, drop = TRUE]
  }

  final_mig[] <- 0
  dim(final_mig) <- c(dim(params$migration_in_number)[1:3], 1)
  new_params$migration_in_number <- final_mig

  final_mig_dist <- params$migration_distribution_values %>%
    as.data.frame() %>%
    dplyr::select(where(~ !all(. == 0))) %>%
    dplyr::pull(dplyr::last_col())
  final_mig_dist[] <- 0
  dim(final_mig_dist) <- c(dim(params$migration_distribution_values)[1], 1)
  new_params$migration_distribution_values <- final_mig_dist

  ## --- Lock Birth and Death Rates to Final Values ---
  final_birth <- params$crude_birth %>%
    as.data.frame() %>%
    dplyr::select(where(~ !all(. == 0))) %>%
    dplyr::pull(dplyr::last_col())
  dim(final_birth) <- c(dim(params$crude_birth)[1], 1)

  final_death <- {
    idx <- max(which(sapply(seq_len(dim(params$crude_death)[3]),
                            function(i) !all(params$crude_death[,,i] == 0))))
    params$crude_death[,,idx, drop = TRUE]
  }
  dim(final_death) <- c(dim(params$crude_death)[1:2], 1)

  new_params$crude_birth <- final_birth
  new_params$crude_death <- final_death
  new_params$tt_birth_changes <- 0
  new_params$no_birth_changes <- 1
  new_params$tt_death_changes <- 0
  new_params$no_death_changes <- 1

  ## --- Seed Future Infections by Population Weight ---
  final_pop <- params$population %>%
    as.data.frame() %>%
    dplyr::select(where(~ !all(. == 0))) %>%
    dplyr::pull(dplyr::last_col())

  pop_weights <- final_pop / sum(final_pop)

  seed_df <- Reduce(rbind, lapply(seq_len(n_future), function(i) {
    n_cases <- future_events$introduced_cases[i]
    if (n_cases == 0) return(data.frame(dim1 = 1, dim2 = 1, dim3 = 1, dim4 = i, value = 0))
    sampled_ages <- sample(seq_along(pop_weights), n_cases, prob = pop_weights, replace = TRUE)
    data.frame(dim1 = sampled_ages, dim2 = 1, dim3 = 1, dim4 = i, value = 1) %>%
      group_by(dim1, dim2, dim3, dim4) %>%
      summarise(value = sum(value), .groups = "drop")
  }))

  # Introductions are a one-day pulse at the time of their event: the seeds go in the slice that starts at the
  # event's time and the slice that starts the day after is empty (unless another event introduces cases then).
  # In 0.1.0 the seeds were indexed by event number rather than by position in tt_seeded, so with introductions in
  # more than one year they landed in the wrong slice and could be applied every day until the next event.
  seeding_events <- which(future_events$introduced_cases != 0)
  new_params$tt_seeded <- unique(sort(c(0, future_events$time[seeding_events], future_events$time[seeding_events] + 1, future_events$time)))
  new_params$no_seeded_changes <- length(new_params$tt_seeded)

  new_params$seeded <- generate_array_df(
    dim1 = params$n_age,
    dim2 = params$n_vacc,
    dim3 = params$n_risk,
    dim4 = new_params$no_seeded_changes,
    updates = seed_df %>%
      dplyr::filter(value != 0) %>%
      mutate(dim4 = match(future_events$time[dim4], new_params$tt_seeded)) %>%
      group_by(dim1, dim2, dim3, dim4) %>%
      summarise(value = sum(value), .groups = "drop")
  ) %>% df_to_array()

  new_params$repro_weight <- params$repro_weight %>%
    as.data.frame() %>%
    dplyr::select(where(~ !all(. == 0))) %>%
    dplyr::pull(dplyr::last_col())
  dim(new_params$repro_weight) <- c(params$n_age, 1)

    ## --- Set Updated Initial Conditions ---
  new_params$S0 <- current_susceptibility$S0
  new_params$Rpop0 <- current_susceptibility$Rpop0
  new_params$I0[] <- 0

  ## --- Return Future Scenario Parameters ---
  return(new_params)
}

#' Scale Vaccination Rates by a Relative Coverage
#'
#' Changes a set of daily vaccination probabilities so that first-dose coverage is multiplied by
#' `relative_coverage`. The first-dose rate of each age group is converted back to the coverage it gives (the share
#' vaccinated on leaving the age group), the coverage is scaled, and the result is converted to a rate again (see
#' [coverage_to_daily_rate()]). Rates of later doses are rates among those who have had the previous dose, so they
#' are left as they are: coverage of every dose then scales by `relative_coverage`. A relative coverage of zero
#' stops all vaccination.
#'
#' @param rates Daily vaccination probabilities by age group, stratum left and risk group.
#' @param aging_rate Daily ageing probability by age group.
#' @param relative_coverage Multiplier on coverage.
#' @param max_coverage Cap on coverage (default 0.99).
#'
#' @return An array like `rates`.
#' @keywords internal
scale_vaccination_rates <- function(rates, aging_rate, relative_coverage, max_coverage = 0.99) {
  if (relative_coverage <= 0) {
    rates[] <- 0
    return(rates)
  }
  if (relative_coverage == 1) return(rates)
  a <- rep_len(aging_rate, dim(rates)[1])
  for (k in seq_len(dim(rates)[3])) {
    p <- rates[, 1, k]
    coverage <- ifelse(p > 0, p / (a + p * (1 - a)), 0)
    rates[, 1, k] <- ifelse(p > 0, coverage_to_daily_rate(pmin(coverage * relative_coverage, max_coverage), a), 0)
  }
  rates
}
