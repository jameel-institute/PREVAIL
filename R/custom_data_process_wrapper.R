#' custom_data_process_wrapper
#'
#' Load, Process, and Optionally Override All Model Input Data
#'
#' This wrapper function loads internal datasets and processes them into structured model input
#' parameters for a specified country, disease, and vaccine. Compared to \code{data_load_process_wrapper},
#' this function allows users to override any internal demographic, vaccination, or disease dataset
#' with a custom data frame provided through the \code{custom_*} arguments. All data are formatted
#' appropriately for use in the dynamic transmission model within PREVAIL.
#'
#' Any \code{custom_*} argument can be used to override the corresponding internal dataset
#' with a user-supplied data frame. If provided (not NA), these inputs are reformatted as needed
#' and replace the matching internal dataset for this model run.
#'
#' @param iso A 3-letter ISO country code identifying the country for analysis (e.g., "ETH" for Ethiopia).
#' @param disease A character string specifying the disease of interest (e.g., "measles", "diphtheria", "pertussis").
#' @param R0 The basic reproduction number while transmission is on (a single number).
#' @param cfr_off Logical; Sets the CFR to zero. Used when calculating current susceptibility as prior mortality rates will already include disease specific mortality.
#' @param year_start Optional numeric value specifying the first year of the simulation window. Default ("") uses the earliest available data year.
#' @param year_end Optional numeric value specifying the last year of the simulation window. Default ("") uses the latest available data year.
#' @param WHO_seed_switch Retained for compatibility. `FALSE` is the same as `transmission_history = "endemic"`.
#' @param aggregate_age Logical; aggregate data from single-year age groups into custom intervals (default TRUE).
#' @param new_age_breaks Numeric vector; breakpoints for age group aggregation. Default is c(0, 5, ..., Inf).
#' @param transmission_history The assumption about how reported cases relate to true infections over the
#'   historical period: `"circulating_years"` (default), `"reported_cases_only"` (the assumption 0.1.0 made: case
#'   reporting is complete) or `"endemic"`. See the section below.
#' @param circulation_threshold Under `"circulating_years"`, the reported cases per million people per year at or
#'   above which the disease is taken to be circulating. Default 2.
#' @param reporting_fraction Share of infections that are reported, used to scale the seeded infections (reported
#'   cases divided by this). A single number, or a vector named by year. Default 1.
#' @param coverage_accuracy Multiplier on the odds of being vaccinated, to represent true coverage differing from
#'   reported coverage. 1 (default) takes reported coverage at face value; 2 halves the unvaccinated share when
#'   coverage is high; 0.5 roughly doubles it.
#' @param vaccine_waning `"default"` (no waning of measles vaccine protection; the vaccine parameter table for other
#'   diseases), `"table"` (the table for every disease, as in 0.1.0) or `"none"`. See [resolve_vaccine_waning()].
#' @param coverage_source `"wuenic"` (default) or `"median"`; see [process_vaccination_routine()].
#' @param seed_floor Minimum number of infections introduced each year under `"circulating_years"` and `"endemic"`.
#'   Default 10.
#'
#' @param custom_migration Optional. Data frame to override default migration data.
#' @param custom_fertility Optional. Data frame to override default fertility data.
#' @param custom_mortality Optional. Data frame to override default mortality data.
#' @param custom_population Optional. Data frame to override default population (total) data.
#' @param custom_contact_matricies Optional. Data frame to override default contact matrix data.
#' @param custom_routine_vaccination Optional. Data frame to override default routine vaccination data.
#' @param custom_sia_vaccination Optional. Data frame to override default SIA vaccination data.
#' @param custom_disease_data Optional. Data frame to override default disease surveillance data.
#' @param custom_vaccination_schedule Optional. Data frame to override default vaccination schedule.
#' @param custom_disease_parameters Optional. Data frame to override default disease parameter values.
#' @param custom_vaccine_parameters Optional. Data frame to override default vaccine parameter values.
#'
#' @return A named list containing structured parameters ready for use in the PREVAIL dynamic transmission model.
#'
#' @details
#' If any \code{custom_*} argument is provided, it replaces the corresponding PREVAIL internal dataset for that run.
#' Demographic custom data is reformatted with \code{\link{reformat_demographic_data}} before use.
#'
#' Demographic data (UN WPP) end before the present day; the last year with data is carried forward to `year_end`.
#' Routine coverage is likewise carried forward from its last year with data.
#'
#' The returned list also carries `history`, which is not used by the model: the reporting assumption, reported
#' cases, seeded infections and transmission status by year, routine coverage and scheduled age by dose and year,
#' and the protection and waning assigned to each vaccination stratum.
#'
#' @inheritSection build_transmission_history Reporting assumptions
#'
#' @export


custom_data_process_wrapper <- function(
    iso,
    disease,
    R0,
    cfr_off = TRUE,
    year_start = "",
    year_end = "",
    WHO_seed_switch = TRUE,
    aggregate_age = TRUE,
    new_age_breaks = c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, Inf),
    transmission_history = c("circulating_years", "reported_cases_only", "endemic"),
    circulation_threshold = 2,
    reporting_fraction = 1,
    coverage_accuracy = 1,
    vaccine_waning = "default",
    coverage_source = c("wuenic", "median"),
    seed_floor = 10,
    custom_migration = NA,
    custom_fertility = NA,
    custom_mortality = NA,
    custom_population = NA,
    custom_contact_matricies = NA,
    custom_routine_vaccination = NA,
    custom_sia_vaccination = NA,
    custom_disease_data = NA,
    custom_vaccination_schedule = NA,
    custom_disease_parameters = NA,
    custom_vaccine_parameters = NA
) {

  transmission_history <- match.arg(transmission_history)
  coverage_source <- match.arg(coverage_source)
  if (!isTRUE(WHO_seed_switch)) transmission_history <- "endemic"
  if (length(R0) != 1) stop("R0 must be a single number; its changes over time are set by transmission_history")
  if (length(coverage_accuracy) != 1 || !is.finite(coverage_accuracy) || coverage_accuracy <= 0) {
    stop("coverage_accuracy must be a single positive number")
  }

  # ---- Load Package Data ----
  datasets <- list(
    migration              = PREVAIL::UN_WPP_migration,
    fertility              = PREVAIL::UN_WPP_fertility,
    mortality              = PREVAIL::UN_WPP_mortality,
    population_all         = PREVAIL::UN_WPP_population_total,
    population_female      = PREVAIL::UN_WPP_population_female,
    contact_matricies      = PREVAIL::contact_matricies,
    routine_vaccination    = PREVAIL::WHO_vaccination_routine,
    sia_vaccination        = PREVAIL::VIMC_vaccination_sia,
    disease_data           = PREVAIL::WHO_disease_reports,
    vaccination_schedule   = PREVAIL::WHO_vaccination_schedule,
    pre1980                = PREVAIL::vaccination_pre1980,
    disease_parameters     = PREVAIL::disease_parameters %>% dplyr::filter(tolower(disease) == !!disease),
    vaccine_parameters     = PREVAIL::vaccine_parameters %>% dplyr::filter(disease == !!disease)
  )

  #Get years
  years_all <- get_years(1950:lubridate::year(base::Sys.Date()), start = year_start, end = year_end)

  # ---- Override with Custom Inputs if Provided ----
  if (all(!is.na(custom_migration)))            datasets$migration            <- reformat_demographic_data(custom_data = custom_migration, age_required = NA, iso = iso, years = years_all, fill_method = "closest", value_allocation = "maintain")
  if (all(!is.na(custom_fertility)))            datasets$fertility            <- reformat_demographic_data(custom_data = custom_fertility, age_required = 15:49, iso = iso, years = years_all, fill_method = "closest", value_allocation = "maintain")
  if (all(!is.na(custom_mortality)))            datasets$mortality            <- reformat_demographic_data(custom_data = custom_mortality, age_required = 0:100, iso = iso, years = years_all, fill_method = "closest", value_allocation = "maintain")
  if (all(!is.na(custom_population)))           datasets$population_all       <- reformat_demographic_data(custom_data = custom_population, age_required = 0:100, iso = iso, years = years_all, fill_method = "closest", value_allocation = "split")
  if (all(!is.na(custom_contact_matricies)))    datasets$contact_matricies    <- reformat_contact_matrix(custom_data = custom_contact_matricies, iso = iso, age_required = 0:100, fill_method = "closest", value_allocation = "maintain")
  if (all(!is.na(custom_routine_vaccination)))  datasets$routine_vaccination  <- reformat_vaccination(custom_data = custom_routine_vaccination, iso = iso, disease = disease)
  if (all(!is.na(custom_sia_vaccination)))      datasets$sia_vaccination      <- reformat_vaccination(custom_data = custom_sia_vaccination, iso = iso, disease = disease)
  if (all(!is.na(custom_disease_data)))         datasets$disease_data         <- reformat_cases(custom_data = custom_disease_data, iso = iso, disease = disease)
  if (all(!is.na(custom_vaccination_schedule))) datasets$vaccination_schedule <- reformat_vaccination_schedule(custom_vaccination_schedule, iso = iso, disease = disease)
  if (all(!is.na(custom_disease_parameters)))   datasets$disease_parameters   <- reformat_parameters(default_parameters = datasets$disease_parameters, custom_parameters = custom_disease_parameters, disease = disease, type = "disease")
  if (all(!is.na(custom_vaccine_parameters)))   datasets$vaccine_parameters   <- reformat_parameters(default_parameters = datasets$vaccine_parameters, custom_parameters = custom_vaccine_parameters, disease = disease, type = "vaccine")

  # ---- Prepare Inputs ----
  preprocessed <- prepare_model_inputs(
    iso = iso,
    disease = disease,
    vaccine = disease,
    n_age = 101,
    migration = datasets$migration,
    fertility = datasets$fertility,
    mortality = datasets$mortality,
    population_all = datasets$population_all,
    population_female = datasets$population_female,
    contact_matricies = datasets$contact_matricies,
    disease_data = datasets$disease_data,
    vaccination_data_routine = datasets$routine_vaccination,
    vaccination_data_sia = datasets$sia_vaccination,
    year_start = year_start, year_end = year_end,
    coverage_source = coverage_source
  )

  # ---- Generate Parameters from Case and Vaccine Data ----
  cv_params <- case_vaccine_to_param(
    demog_data = preprocessed$processed_demographic_data,
    processed_vaccination = preprocessed$processed_vaccination_data,
    processed_vaccination_sia = preprocessed$processed_vaccination_sia,
    processed_case = preprocessed$processed_case_data,
    vaccination_schedule = datasets$vaccination_schedule %>% dplyr::filter(iso3 == iso),
    vaccination_pre1980 = datasets$pre1980,
    vaccine_parameters = datasets$vaccine_parameters,
    disease_parameters = datasets$disease_parameters,
    WHO_seed_switch = WHO_seed_switch,
    custom_routine_vaccination = custom_routine_vaccination,
    custom_sia_vaccination = custom_sia_vaccination,
    disease = disease,
    R0 = R0,
    processed_case_reports = preprocessed$processed_case_reports,
    transmission_history = transmission_history,
    circulation_threshold = circulation_threshold,
    reporting_fraction = reporting_fraction,
    seed_floor = seed_floor,
    coverage_accuracy = coverage_accuracy,
    vaccine_waning = vaccine_waning
  )

  disease_value <- function(name) {
    datasets$disease_parameters %>% subset(parameter == name) %>% dplyr::pull(mean) %>% as.numeric()
  }
  recovery_rate <- 1 / disease_value("infectious period")
  # The model applies the case fatality parameters as a daily probability of death while infectious. Convert the
  # case fatality ratios so that the share of cases who die equals the ratio (in 0.1.0 the ratio itself was used
  # as the daily probability).
  cfr_normal_daily <- cfr_to_daily_probability(disease_value("cfr for standard cases"), recovery_rate)
  cfr_severe_daily <- cfr_to_daily_probability(disease_value("cfr for severe cases"), recovery_rate)

  # ---- Time Scaling and Change Points ----
  times <- list(
    mig  = base::sort(base::floor(preprocessed$processed_demographic_data$tt_migration * 365)),
    vac  = base::sort(base::floor(cv_params$tt_vaccination * 365)),
    seed = base::sort(base::floor(cv_params$tt_seeded))
  )

  # ---- Optional Aggregation to New Age Structure ----
  aggregated_inputs <- aggregate_inputs(
    preprocessed = preprocessed,
    cv_params = cv_params,
    new_age_breaks = new_age_breaks,
    aggregate_age = aggregate_age
  )

  inputs <- aggregated_inputs$inputs
  default_inputs <- aggregated_inputs$default_inputs

  #Update aging and calculation of reproduction parameters
  aging_reproduction <- calc_aging_and_repro(
    aggregate_age = aggregate_age,
    new_age_breaks = new_age_breaks,
    inputs = inputs,
    default_inputs = default_inputs,
    disease_param = datasets$disease_parameters
  )

  # ---- Return Packaged Parameters ----
  packed_params <- param_packager(

    #Population parameters
    n_age                        = length(unique(inputs$age_beta_mod$dim1)),
    n_vacc                       = preprocessed$processed_demographic_data$input_data$n_vacc,
    n_risk                       = preprocessed$processed_demographic_data$input_data$n_risk,
    population                   = inputs$population,
    female_population            = inputs$female_population,
    repro_weight = aging_reproduction$repro_weight,
    contact_matrix               = inputs$contact_matrix,
    S0                           = inputs$N0,
    Rpop0                        = 0,
    I0                           = 0,
    repro_low                    = aging_reproduction$repro_low,
    repro_high                   = aging_reproduction$repro_high,
    age_maternal_protection_ends = aging_reproduction$maternal_prot_end,

    #Demographic changes
    crude_birth                  = inputs$crude_birth,
    crude_death                  = inputs$crude_death,
    aging_rate                   = aging_reproduction$aging_rate,
    migration_in_number          = inputs$mig_in,
    migration_distribution_values = inputs$mig_dist,
    migration_represent_current_pop = 1,

    #Vaccination parameters
    vaccination_coverage         = inputs$vacc_cov,
    short_term_waning            = data.frame(dim1 = seq_along(cv_params$vaccine_strata$short_term_waning), value = cv_params$vaccine_strata$short_term_waning),
    long_term_waning             = data.frame(dim1 = seq_along(cv_params$vaccine_strata$long_term_waning), value = cv_params$vaccine_strata$long_term_waning),
    age_vaccination_beta_modifier = inputs$age_beta_mod,
    protection_weight_vacc       = disease_value("maternal protection (vaccine)") * aging_reproduction$maternal_prot_weight,
    protection_weight_rec        = disease_value("maternal protection (infection)") * aging_reproduction$maternal_prot_weight,

    #Disease parameters
    incubation_rate              = 1 / disease_value("incubation period"),
    recovery_rate                = recovery_rate,
    severe_recovery_rate         = recovery_rate,
    prop_severe                  = disease_value("proportion severe (hospitalized)"),
    prop_complications           = disease_value("proportion severe with complications"),
    natural_immunity_waning      = if (cv_params$nat_waning == 0) 0 else 1 / cv_params$nat_waning,
    R0                           = cv_params$R0,
    cfr_normal                   = if (isTRUE(cfr_off)) 0 else cfr_normal_daily,
    cfr_severe                   = if (isTRUE(cfr_off)) 0 else cfr_severe_daily,
    cfr_normal_real              = cfr_normal_daily,
    cfr_severe_real              = cfr_severe_daily,

    #Time parameters
    tt_R0                        = cv_params$tt_R0,
    tt_birth_changes             = times$mig,
    tt_death_changes             = times$mig,
    tt_migration                 = times$mig,
    tt_vaccination_coverage      = times$vac,
    tt_seeded                    = times$seed,

    #Cases
    seeded                       = inputs$seeded
  )

  # Attach input metadata
  packed_params$input_data <- data.frame(
    iso              = iso,
    disease          = disease,
    R0               = R0,
    year_start       = preprocessed$processed_demographic_data$input_data$year_start,
    year_end         = preprocessed$processed_demographic_data$input_data$year_end,
    WHO_seed_switch  = WHO_seed_switch,
    aggregate_age    = aggregate_age,
    age_breaks       = if (aggregate_age) {
      paste(new_age_breaks, collapse = ";")
    } else {
      paste(seq(1, 101), collapse = ";")
    },
    transmission_history = cv_params$transmission_history,
    circulation_threshold = circulation_threshold,
    coverage_accuracy = coverage_accuracy,
    vaccine_waning   = resolve_vaccine_waning(vaccine_waning, disease),
    coverage_source  = coverage_source,
    demography_last_year = preprocessed$processed_demographic_data$input_data$demography_last_year
  )

  # Not used by the model: what went into the historical inputs, for diagnostics
  packed_params$history <- list(
    transmission = cv_params$transmission_summary,
    routine_coverage = cv_params$routine_coverage,
    dose_ages = cv_params$dose_ages,
    vaccine_strata = cv_params$vaccine_strata$table
  )

  packed_params

}

#' Convert a Case Fatality Ratio to a Daily Probability of Death
#'
#' The model draws deaths among the infectious each day with probability `cfr` on top of background mortality, and
#' recoveries each day with probability `recovery_rate`. For the share of cases who die to equal a case fatality
#' ratio `cfr`, the daily probability has to be `recovery_rate * cfr / (1 - cfr)`.
#'
#' @param cfr Case fatality ratio (proportion of cases who die).
#' @param recovery_rate Daily probability of recovery.
#'
#' @return Daily probability of death while infectious.
#' @keywords internal
cfr_to_daily_probability <- function(cfr, recovery_rate) {
  cfr <- pmin(pmax(cfr, 0), 0.999)
  recovery_rate * cfr / (1 - cfr)
}
