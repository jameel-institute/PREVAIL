#' Expand Pre-1980 Routine Vaccination Coverage
#'
#' Uses historical assumptions to estimate vaccination coverage prior to the first observed year.
#' Applies linear interpolation from an assumed introduction year up to the first observed coverage year.
#'
#' @param processed_vaccination Routine coverage data (to determine first year and vaccine).
#' @param vaccination_pre1980 Data frame of historical vaccine assumptions (intro year, starting coverage).
#' @param disease Disease name (lowercase) to match.
#' @param iso 3-letter ISO country code.
#'
#' @return A data frame of additional rows to prepend to coverage time series.
#' @importFrom data.table as.data.table setDT setnames rbindlist copy data.table
#' @keywords internal
expand_pre1980_vaccination <- function(processed_vaccination, vaccination_pre1980, disease, iso) {
  # Ensure input is data.table
  vac_pre1980_sub <- data.table::as.data.table(vaccination_pre1980)
  data.table::setDT(vac_pre1980_sub)

  vac_pre1980_sub[, rowname := .I]  # preserve row identity
  vac_pre1980_sub[, income_group := paste0(paste0(substr(unlist(strsplit(income_group, " |-")), 1, 1), collapse = ""), "C"),
                  by = rowname]

  setnames(vac_pre1980_sub, "disease", "disease_n")

  vac_pre1980_sub <- vac_pre1980_sub[
    tolower(disease_n) == disease &
      who_region == paste0(get_WHO_region(iso), "O") &
      income_group == as.character(get_income_group(iso))
  ]

  if (nrow(vac_pre1980_sub) == 0 || nrow(processed_vaccination) == 0) return(processed_vaccination)

  # Remove special populations
  processed_vaccination <- processed_vaccination[!grepl("birth|neonatal|pregnant|maternal",
                                                        processed_vaccination$vaccine_description, ignore.case = TRUE), ]

  first_year_vac <- processed_vaccination[processed_vaccination$year == min(processed_vaccination$year), ]

  year_diff <- min(first_year_vac$year) - vac_pre1980_sub$introduction_year
  if (year_diff <= 0) return(processed_vaccination)

  # Precompute interpolation
  vac_prop <- lapply(first_year_vac$coverage, function(e) {
    seq(
      from = vac_pre1980_sub$starting_coverage_percent,
      to = max(vac_pre1980_sub$starting_coverage_percent, e),
      length.out = 6
    )
  })

  # Efficient row expansion
  pre_1980 <- rbindlist(lapply(seq_len(year_diff), function(x) {
    rbindlist(lapply(seq_len(nrow(first_year_vac)), function(k) {
      row <- copy(first_year_vac[k])
      row$year <- vac_pre1980_sub$introduction_year + (x - 1)
      row$coverage <- vac_prop[[k]][min(x, length(vac_prop[[k]]))]
      row
    }))
  }))

  data.table::rbindlist(list(pre_1980, processed_vaccination))
}



#' Format Case and Vaccination Parameters for Model Input (Including Pre-1980)
#'
#' Wrapper function that prepares all time-varying parameters for use in an age-, vaccine-,
#' and risk-structured infectious disease model, including extrapolated vaccination coverage
#' prior to 1980 if available.
#'
#' @param demog_data Output list from `process_demography()`.
#' @param processed_vaccination Data frame of routine vaccine coverage.
#' @param processed_vaccination_sia Data frame of SIA coverage.
#' @param processed_case WHO case reports processed for the country of interest (years with cases).
#' @param vaccination_schedule Full WHO vaccine schedule data frame.
#' @param vaccination_pre1980 Data frame of historical vaccination introduction assumptions.
#' @param vaccine_parameters Data frame of vaccination parameters.
#' @param disease_parameters Data frame of disease parameters.
#' @param custom_routine_vaccination Data frame or NA indicating custom routine vaccination.
#' @param custom_sia_vaccination Data frame or NA indicating custom sia vaccination.
#' @param disease Disease name. If `NULL` it is taken from the case data.
#' @param R0 Basic reproduction number while transmission is on.
#' @param processed_case_reports WHO case reports including years with zero cases. Defaults to `processed_case`.
#' @param transmission_history,circulation_threshold,reporting_fraction,seed_floor Passed to
#'   [build_transmission_history()].
#' @param coverage_accuracy Multiplier on the odds of vaccination (see [coverage_to_daily_rate()]).
#' @param vaccine_waning Passed to [resolve_vaccine_waning()].
#'
#' @return A named list of parameters including the routine coverage and dose ages, SIA coverage, protection and
#'   waning by stratum, the time-varying R0 and the seeding inputs.
#'
#' @importFrom data.table data.table setDT rbindlist
#' @importFrom stats setNames
#' @keywords internal
case_vaccine_to_param <- function(
    demog_data,
    processed_vaccination,
    processed_vaccination_sia,
    processed_case,
    vaccination_schedule,
    vaccination_pre1980,
    vaccine_parameters,
    disease_parameters,
    custom_routine_vaccination = NA,
    custom_sia_vaccination = NA,
    disease = NULL,
    R0 = 1,
    processed_case_reports = processed_case,
    transmission_history = "circulating_years",
    circulation_threshold = 2,
    reporting_fraction = 1,
    seed_floor = 10,
    coverage_accuracy = 1,
    vaccine_waning = "default"
) {

  iso <- demog_data$input_data$iso
  n_age <- demog_data$input_data$n_age
  n_vacc <- demog_data$input_data$n_vacc
  n_doses <- (n_vacc - 1) / 2
  years <- demog_data$input_data$year_start:demog_data$input_data$year_end
  if (is.null(disease)) disease <- tolower(unique(processed_case$disease_description)[1])
  custom_routine <- !all(is.na(custom_routine_vaccination))

  # Use data.table for combined extraction
  vaccination_sources <- c(
    disease,
    processed_case$disease_description,
    processed_vaccination_sia$vaccination_name,
    processed_vaccination_sia$disease,
    processed_vaccination$vaccine,
    processed_vaccination$vaccine_description
  )

  vaccination_type <- paste(unique(stats::na.omit(vaccination_sources)), collapse = "|")

  if (grepl("Diphtheria|Pertussis", vaccination_type, ignore.case = TRUE)) {
    vaccination_type <- paste0(vaccination_type, "|DTPCV1|DTPCV3|DTaP|DT|DTwP")
  }

  # Expand routine coverage pre-1980
  if (!custom_routine) {
    processed_vaccination <- expand_pre1980_vaccination(
      data.table::as.data.table(processed_vaccination),
      # an introduction before the model starts counts as an introduction in its first year (in 0.1.0 such rows
      # were dropped, leaving coverage at zero until the first WHO estimate in 1980)
      vaccination_pre1980 %>%
        dplyr::mutate(introduction_year = pmax(introduction_year, demog_data$input_data$year_start)) %>%
        subset(introduction_year <= demog_data$input_data$year_end),
      disease = disease,
      iso = iso
    )
  }

  # ---- Routine coverage and age by dose ----
  schedule <- filter_vaccine_schedule(vaccination_schedule, vaccination_type, iso)
  routine_coverage <- routine_dose_coverage(processed_vaccination, n_doses, years, percent = !custom_routine)
  dose_ages <- routine_dose_ages(schedule, n_doses, years)

  # custom routine data give the age of each dose directly
  if (custom_routine && "age" %in% names(processed_vaccination)) {
    pv <- as.data.frame(processed_vaccination)
    for (d in seq_len(n_doses)) {
      ages_d <- suppressWarnings(as.numeric(pv$age[pv$dose_order == d]))
      if (length(ages_d) && any(!is.na(ages_d))) dose_ages[, d] <- min(ages_d, na.rm = TRUE)
    }
  }

  # ---- Supplementary immunisation activities ----
  sia <- if (nrow(processed_vaccination_sia) > 0) {
    as.data.frame(processed_vaccination_sia)[, c("year", "age", "coverage")]
  } else {
    NULL
  }

  # ---- Protection and waning by stratum ----
  strata <- vaccine_strata_parameters(
    vaccine_parameters = vaccine_parameters,
    n_vacc = n_vacc,
    vaccine_waning = resolve_vaccine_waning(vaccine_waning, disease)
  )

  age_vaccination_beta_modifier <- base::expand.grid(
    dim1 = seq_len(n_age),
    dim2 = seq_len(n_vacc)[-1],
    dim3 = 1
  )
  age_vaccination_beta_modifier$value <- strata$protection[age_vaccination_beta_modifier$dim2]

  # ---- Natural Immunity Waning ----
  nat_waning <- disease_parameters %>%
    dplyr::filter(grepl("natural immunity", parameter)) %>%
    dplyr::mutate(mean = gsub("lifelong", 0, mean)) %>%
    dplyr::pull(mean) %>%
    tidyr::replace_na(0) %>%
    base::gsub("NA", 0, .) %>%
    base::as.numeric() * 365

  # ---- Transmission and seeding ----
  history <- build_transmission_history(
    case_reports = processed_case_reports,
    population = demog_data$population_data,
    years = years,
    R0 = R0,
    disease = disease,
    transmission_history = transmission_history,
    circulation_threshold = circulation_threshold,
    reporting_fraction = reporting_fraction,
    seed_floor = seed_floor
  )

  list(
    tt_vaccination = seq_along(years) - 1,
    routine_coverage = routine_coverage,
    dose_ages = dose_ages,
    sia = sia,
    coverage_accuracy = coverage_accuracy,
    vaccine_strata = strata,
    tt_seeded = history$tt_seeded,
    nat_waning = nat_waning,
    age_vaccination_beta_modifier = age_vaccination_beta_modifier,
    seed_data = history$seed_data,
    R0 = history$R0,
    tt_R0 = history$tt_R0,
    transmission_history = transmission_history,
    transmission_summary = history$summary
  )
}
