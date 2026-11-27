#' data_load_process_wrapper
#'
#' Load and Process All Model Input Data
#'
#' This wrapper function loads internal datasets and processes them into structured model input
#' parameters for a specified country, disease, and vaccine. It integrates demographic, vaccination,
#' and disease data, formatting them appropriately for use in the dynamic transmission model within PREVAIL.
#'
#' @param iso A 3-letter ISO country code identifying the country for analysis (e.g., "ETH" for Ethiopia).
#' @param disease A character string specifying the disease of interest (e.g., "measles", "diphtheria", "pertussis").
#' @param R0 The basic reproduction number while transmission is on (a single number).
#' @param cfr_off Logical; Sets the CFR to zero. Used when calculating current susceptibility as prior mortality rates will already include disease specific mortality.
#' @param year_start Optional numeric value specifying the first year of the simulation window. Default ("") uses the earliest available data year.
#' @param year_end Optional numeric value specifying the last year of the simulation window. Default ("") uses the latest available data year.
#' @param WHO_seed_switch Deprecated. `FALSE` is now `transmission_history = "circulating_years"` with
#'   `circulation_threshold = 0` (transmission on throughout).
#' @param aggregate_age Logical indicating whether to aggregate data from single-year age groups into custom age intervals (default is `TRUE`).
#' @param new_age_breaks Numeric vector specifying the breakpoints used to aggregate single-year age groups into broader age bands. Default is `c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, Inf)`.
#'
#' @inheritParams custom_data_process_wrapper
#'
#' @return A named list containing structured parameters ready for use in the PREVAIL dynamic transmission model.
#'
#' @details
#' This is [custom_data_process_wrapper()] with no custom data, so the two cannot drift apart. See that function
#' for the details of the historical assumptions.
#'
#' @inheritSection build_transmission_history Reporting assumptions
#'
#' @export

data_load_process_wrapper <- function(
    iso,
    disease,
    R0,
    cfr_off = TRUE,
    year_start = "",
    year_end = "",
    WHO_seed_switch = TRUE,
    aggregate_age = TRUE,
    new_age_breaks = c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, Inf),
    transmission_history = c("circulating_years", "reported_cases_only"),
    circulation_threshold = 2,
    reporting_fraction = 1,
    coverage_accuracy = 1,
    vaccine_waning = "default",
    coverage_source = c("wuenic", "median"),
    seed_floor = 10,
    dtp_boosters = TRUE,
    booster_since = 1980,
    pertussis_vaccine = c("schedule", "acellular", "whole_cell")
) {

  custom_data_process_wrapper(
    iso = iso,
    disease = disease,
    R0 = R0,
    cfr_off = cfr_off,
    year_start = year_start,
    year_end = year_end,
    WHO_seed_switch = WHO_seed_switch,
    aggregate_age = aggregate_age,
    new_age_breaks = new_age_breaks,
    transmission_history = match.arg(transmission_history),
    circulation_threshold = circulation_threshold,
    reporting_fraction = reporting_fraction,
    coverage_accuracy = coverage_accuracy,
    vaccine_waning = vaccine_waning,
    coverage_source = match.arg(coverage_source),
    seed_floor = seed_floor,
    dtp_boosters = dtp_boosters,
    booster_since = booster_since,
    pertussis_vaccine = match.arg(pertussis_vaccine)
  )

}
