#' Reformat Parameter Table for Model Input
#'
#' Reformats a parameter table for PREVAIL, standardising column names and units for either disease or vaccine parameters.
#'
#' @param custom_parameters Data frame of custom parameters. For vaccine parameters, the columns are `parameter`
#'   (`"protection"` or `"waning"`), `duration` (`"short"` or `"long"`), `value` and optionally `dose` (a dose of the
#'   default table, for example 3 for the pertussis primary series). A row without a `dose` applies to every dose.
#' @param default_parameters Data frame of the default parameters
#' @param disease Character string, name of the disease.
#' @param type One of \code{"disease"} or \code{"vaccine"}. Controls formatting logic.
#'
#' @return A data frame with reformatted parameters.
#' @importFrom dplyr mutate case_when
#' @export
reformat_parameters <- function(
    custom_parameters,
    default_parameters,
    disease,
    type = c("disease", "vaccine")
) {

  type <- match.arg(type)
  if (type == "vaccine") {
    # Custom rows are named as the default table names them (for example "short_term_protection") and keep their
    # values in `value`, the column the rest of the pipeline reads. (In 0.1.0 the custom values were moved to a
    # column called `mean` and the default rows were renamed, so custom vaccine parameters reached the model as NA.)
    custom <- custom_parameters %>%
      dplyr::mutate(
        type = "custom",
        vaccine = disease,
        disease = disease,
        unit = dplyr::case_when(
          parameter == "waning" ~ "years",
          parameter == "protection" ~ "proportion",
          TRUE ~ NA_character_
        ),
        parameter = paste(duration, "term", parameter, sep = "_")
      )

    # Each custom row replaces the default row for the same parameter and dose, keeping the default row's vaccine
    # name (so that, for example, the whole-cell pertussis rows can still be selected). Without a `dose` it applies to
    # every dose. (Before, custom rows had no dose and removed the default rows for every dose, so the model was given
    # NA.)
    default_parameters <- as.data.frame(default_parameters)
    keys <- unique(default_parameters[, c("vaccine", "dose")])
    custom <- as.data.frame(custom)
    if (!"dose" %in% names(custom)) custom$dose <- NA_real_
    custom <- do.call(rbind, lapply(seq_len(nrow(custom)), function(i) {
      k <- if (is.na(custom$dose[i])) keys else keys[keys$dose == custom$dose[i], , drop = FALSE]
      if (nrow(k) == 0) stop(sprintf("custom vaccine parameter for dose %s: no such dose in the table", custom$dose[i]))
      cbind(custom[rep(i, nrow(k)), setdiff(names(custom), c("vaccine", "dose")), drop = FALSE], k)
    }))
    replaced <- paste(default_parameters$vaccine, default_parameters$dose, default_parameters$parameter) %in%
      paste(custom$vaccine, custom$dose, custom$parameter)
    dplyr::bind_rows(
      custom[, intersect(c(names(default_parameters), "type"), names(custom)), drop = FALSE],
      default_parameters[!replaced, , drop = FALSE] %>% dplyr::mutate(type = "default")
    )

  } else {
    custom_parameters %>%
      dplyr::mutate(type = "custom") %>%
      dplyr::rename(mean = value) %>%
      dplyr::bind_rows(default_parameters %>%
              dplyr::mutate(type = "default")) %>%
      dplyr::mutate(
        disease = disease,
        parameter = dplyr::case_when(
          grepl("incubation", parameter, ignore.case = TRUE) ~ "incubation period",
          grepl("infectious", parameter, ignore.case = TRUE) ~ "infectious period",
          grepl("Reproductive|R0", parameter, ignore.case = TRUE) ~ "reproductive number",
          grepl("waning|immunity", parameter, ignore.case = TRUE) ~ "natural immunity waning",
          TRUE ~ parameter
        )
      ) %>%
      dplyr::mutate(
        mean = case_when(
          unit == "%" ~ mean/100,
          TRUE ~ mean
        ),
        unit = case_when(
          unit == "%" ~ "proportion",
          TRUE ~ unit
        )
      ) %>%
      group_by(parameter) %>%
      filter(!(type == "default" & any(type == "custom"))) %>%
      ungroup()
  }
}
