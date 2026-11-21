#' Process Disease Surveillance Data
#'
#' Filters and subsets disease surveillance data for a specified country, time window, and disease.
#'
#' @param disease_data A `data.frame` or `data.table` of disease records. Must include columns: `iso3`, `year`, `cases`, and optionally `disease_short`.
#' @param iso A 3-letter ISO country code to filter the data by.
#' @param disease A specific disease to filter by. Default is `"All"`, which returns all diseases.
#' @param year_start First year to include (default: first year in data).
#' @param year_end Final year to include (default: last year in data).
#' @param keep_zero Logical; keep years with zero reported cases? The default (`FALSE`) returns years with at least
#'   one case, as in 0.1.0. Zero reports are needed to tell "no cases reported" apart from "no report".
#'
#' @return A filtered `data.table` containing only records for the specified country, time range, and disease.
#'
#' @importFrom data.table setDT
#' @keywords internal
process_prior_cases <- function(
    disease_data,
    iso,
    disease = "All",
    year_start = "",
    year_end = "",
    keep_zero = FALSE
) {
  years <- get_years(disease_data$year, year_start, year_end)

  # copy, so that the package data are not modified by reference
  disease_data <- data.table::as.data.table(disease_data)

  # Filter relevant data
  filtered <- disease_data[
    iso3 == iso &
      year %in% years &
      !is.na(cases) &
      (keep_zero | cases != 0)
  ]

  # Filter by disease name if requested
  if (disease != "All") {
    filtered <- filtered[disease_short == disease]
  }

  return(filtered[])
}
