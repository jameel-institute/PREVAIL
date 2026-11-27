#' Prepare Model Inputs for an Infectious Disease Transmission Model
#'
#' This wrapper function prepares demographic, case, and vaccination data for use in an
#' age-, vaccination-, and risk-structured infectious disease model.
#' It processes each input type using internal helper functions and returns a fully structured list.
#'
#' @param migration A data frame of net migration rates by year and country.
#' @param fertility A data frame of fertility rates by age and year.
#' @param mortality A data frame of mortality counts by age and year.
#' @param population_all A data frame of total population counts by age and year.
#' @param population_female A data frame of female population counts by age and year.
#' @param iso A 3-letter ISO country code for filtering the data.
#' @param disease_data A data frame of WHO-reported disease cases across countries and years.
#' @param disease A string indicating the disease of interest (e.g., "measles").
#' @param vaccination_data_routine Routine immunization data including coverage, population, antigen, etc.
#' @param vaccination_data_sia Supplementary immunization activity (SIA) coverage data.
#' @param vaccine A string specifying the vaccine of interest.
#' @param contact_matricies A named list of contact matrices by ISO code.
#' @param year_start First year to include (default: from migration data).
#' @param year_end Final year to include (default: from migration data).
#' @param n_age Number of age groups in the model.
#' @param n_risk Number of risk groups in the model.
#' @param coverage_source Passed to [process_vaccination_routine()].
#' @param boosters DTP booster doses to model, from [dtp_booster_schedule()] (`NULL` or zero rows for none). Each
#'   adds a dose after the primary series, with its coverage from the WHO booster dose given in `coverage_dose`.
#'
#' @return A named list containing:
#' \describe{
#'   \item{processed_demographic_data}{Output from `process_demography()`.}
#'   \item{processed_case_data}{Filtered disease case data (years with at least one reported case).}
#'   \item{processed_case_reports}{As `processed_case_data` but keeping years with zero reported cases.}
#'   \item{processed_vaccination_data}{Cleaned and summarized routine vaccination data.}
#'   \item{processed_vaccination_sia}{Filtered SIA data for the specified vaccine.}
#'   \item{demographic_plots}{(Placeholder) Plot object to visualize processed inputs.}
#' }
#'
#' @details
#' This function calls internal processing utilities: `process_demography()`,
#' `process_prior_cases()`, `process_vaccination_routine()`, `process_vaccination_sia()`.
#'
#' @keywords internal
#' @importFrom dplyr filter
prepare_model_inputs <- function(
  migration,
  fertility,
  mortality,
  population_all,
  population_female,
  iso,
  disease_data,
  disease,
  vaccination_data_routine,
  vaccination_data_sia,
  vaccine,
  contact_matricies,
  year_start = "",
  year_end = "",
  n_age = 1,
  n_risk = 1,
  coverage_source = "wuenic",
  boosters = NULL
) {

  #Establish the number of vaccines
  number_of_vaccines <- switch(
    disease,
    "measles"    = 2,
    "diphtheria" = 3,
    "pertussis"  = 3,
    0
  )
  n_boosters <- if (is.null(boosters)) 0 else nrow(boosters)
  number_of_vaccines <- number_of_vaccines + n_boosters

  # Step 1: Process demographic data
  demographic <- process_demography(
    migration = migration,
    fertility = fertility,
    mortality = mortality,
    population_all = population_all,
    population_female = population_female,
    contact_matricies = contact_matricies,
    iso = iso,
    year_start = year_start,
    year_end = year_end,
    number_of_vaccines = number_of_vaccines,
    n_risk = n_risk,
    n_age = 101
  )

  # Filter external inputs to final model year
  vaccination_data_routine <- vaccination_data_routine %>%
    filter(year <= demographic$input_data$year_end)

  disease_data <- disease_data %>%
    filter(year <= demographic$input_data$year_end)

  # Step 2: Process disease data
  cases <- process_prior_cases(
    disease_data = disease_data,
    iso = demographic$input_data$iso,
    disease = disease,
    year_start = demographic$input_data$year_start,
    year_end = demographic$input_data$year_end
  )

  case_reports <- process_prior_cases(
    disease_data = disease_data,
    iso = demographic$input_data$iso,
    disease = disease,
    year_start = demographic$input_data$year_start,
    year_end = demographic$input_data$year_end,
    keep_zero = TRUE
  )

  # Step 3: Routine vaccination data
  routine <- process_vaccination_routine(
    vaccination_data = vaccination_data_routine,
    iso = demographic$input_data$iso,
    vaccine = vaccine,
    year_start = demographic$input_data$year_start,
    year_end = demographic$input_data$year_end,
    coverage_source = coverage_source
  )

  # DTP boosters: WHO reports their coverage as the 4th to 6th diphtheria-containing dose (whichever disease is
  # modelled). Each modelled booster takes the coverage of the WHO dose given in `coverage_dose`. A coverage of exactly
  # zero for a scheduled booster is a missing report, not a booster nobody received (the United Kingdom's official
  # figure for its teenage booster is 0 in 2022 and 2023, after 83 to 87%), so it is dropped and the last reported
  # coverage carried forward.
  if (n_boosters > 0) {
    booster_routine <- process_vaccination_routine(
      vaccination_data = vaccination_data_routine,
      iso = demographic$input_data$iso,
      vaccine = "Diphtheria-containing vaccine, [456]th",
      year_start = demographic$input_data$year_start,
      year_end = demographic$input_data$year_end,
      coverage_source = coverage_source
    )
    booster_routine <- booster_routine[booster_routine$dose_order %in% boosters$coverage_dose & booster_routine$coverage > 0, ]
    booster_routine$dose_order <- boosters$dose[match(booster_routine$dose_order, boosters$coverage_dose)]
    routine <- rbind(routine[is.na(routine$dose_order) | routine$dose_order <= 3, ], booster_routine, fill = TRUE)
  }

  # Step 4: SIA vaccination data
  sia <- process_vaccination_sia(
    vaccination_data = vaccination_data_sia,
    iso = demographic$input_data$iso,
    vaccine = vaccine,
    year_start = demographic$input_data$year_start,
    year_end = demographic$input_data$year_end
  )

  # Step 5: Compile output
  list(
    processed_demographic_data = demographic,
    processed_case_data = cases,
    processed_case_reports = case_reports,
    processed_vaccination_data = routine,
    processed_vaccination_sia = sia
  )
}
