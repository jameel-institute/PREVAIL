#' Process Routine Vaccination Coverage Data
#'
#' Filters and processes routine immunization data for a specified country, time range, and optionally vaccine type.
#' Aggregates records by year, antigen, and antigen description, summarising key indicators such as median coverage.
#'
#' @param vaccination_data A `data.frame` or `data.table` with columns including `ISO3`, `YEAR`, `COVERAGE`, `ANTIGEN`,
#' `ANTIGEN_DESCRIPTION`, `Disease`, `target_number`, and `doses`.
#' @param iso A 3-letter ISO country code to filter the data by.
#' @param vaccine A specific vaccine name or substring to filter by (default is `"All"`, which returns all vaccines).
#' @param year_start First year to include (default: earliest year in data).
#' @param year_end Final year to include (default: latest year in data).
#' @param coverage_source `"wuenic"` (default) uses the WHO/UNICEF estimate of national immunisation coverage for a
#'   vaccine and year where there is one, and the median of the administrative and official figures otherwise.
#'   `"median"` takes the median of all three, as 0.1.0 did (which in practice follows the administrative figure
#'   whenever the administrative and official figures agree).
#'
#' @return A `data.table` with columns `year`, `vaccine`, `vaccine_description`, `dose_order`, and median `coverage`
#'   (and `age` where the input has one).
#'
#' @importFrom data.table setDT setnames
#' @keywords internal
process_vaccination_routine <- function(
    vaccination_data,
    iso,
    vaccine = "All",
    year_start = "",
    year_end = "",
    coverage_source = c("wuenic", "median")
) {
  coverage_source <- match.arg(coverage_source)

  # copy, so that the package data are not modified by reference
  vaccination_data <- data.table::as.data.table(vaccination_data)

  # Standardize column names
  data.table::setnames(vaccination_data, tolower(gsub("[^[:alnum:]]+", "_", names(vaccination_data))))

  # Standardize variable name to match expectations
  data.table::setnames(vaccination_data, old = "vaccine", new = "vaccination_name", skip_absent = TRUE)

  years <- get_years(vaccination_data$year, year_start, year_end)

  # Filter by ISO3 and year, ensure coverage is non-missing
  filtered <- vaccination_data[
    iso3 == iso & year %in% years & !is.na(coverage)
  ]

  # Optional vaccine string match (vaccine or disease)
  if (vaccine != "All") {
    filtered <- filtered[
      grepl(vaccine, vaccine_description, ignore.case = TRUE) |
        grepl(vaccine, disease, ignore.case = TRUE)
    ]
  }

  # Infer dose_order if not already present
  filtered[
    grepl("4th", vaccine_description, ignore.case = TRUE), dose_order := 4
  ][
    grepl("5th", vaccine_description, ignore.case = TRUE), dose_order := 5
  ][
    grepl("6th", vaccine_description, ignore.case = TRUE), dose_order := 6
  ]

  # Where a WHO/UNICEF estimate (WUENIC) exists for a vaccine and year, use it in preference to administrative and
  # official figures
  if (coverage_source == "wuenic" && "coverage_category" %in% names(filtered) && nrow(filtered) > 0) {
    filtered[, has_wuenic := any(coverage_category == "WUENIC"), by = .(year, vaccination_name)]
    filtered <- filtered[!has_wuenic | coverage_category == "WUENIC"]
    filtered[, has_wuenic := NULL]
  }

  # Aggregate: median coverage by year and vaccine descriptors (and age, where custom data give one)
  by_cols <- intersect(c("year", "vaccination_name", "vaccine_description", "dose_order", "age"), names(filtered))
  result <- filtered[
    ,
    .(coverage = median(coverage, na.rm = TRUE)),
    by = by_cols
  ][
    order(year)
  ]

  data.table::setnames(result, "vaccination_name", "vaccine")

  return(result[])
}
