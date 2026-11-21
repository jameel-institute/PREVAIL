test_that("protection is a proportion and short-term is at least long-term, for every disease", {
  for (disease in c("measles", "diphtheria", "pertussis")) {
    vp <- PREVAIL::vaccine_parameters[PREVAIL::vaccine_parameters$disease == disease, ]
    n_vacc <- if (disease == "measles") 5 else 7
    s <- PREVAIL:::vaccine_strata_parameters(vp, n_vacc, vaccine_waning = TRUE)
    expect_true(all(s$protection >= 0 & s$protection <= 1), info = disease)
    expect_equal(s$protection[1], 0)
    for (d in seq_len((n_vacc - 1) / 2)) {
      expect_gte(s$protection[2 * d + 1], s$protection[2 * d])
    }
    # short-term strata (odd) wane at the short-term rate, long-term strata (even) at the long-term rate
    expect_true(all(s$short_term_waning[seq(3, n_vacc, 2)] > 0))
    expect_true(all(s$short_term_waning[c(1, seq(2, n_vacc, 2))] == 0))
    expect_true(all(s$long_term_waning[seq(2, n_vacc, 2)] > 0))
    expect_true(all(s$long_term_waning[seq(1, n_vacc, 2)] == 0))
  }
})

test_that("each measles dose uses its own row of the table", {
  vp <- PREVAIL::vaccine_parameters[PREVAIL::vaccine_parameters$disease == "measles", ]
  s <- PREVAIL:::vaccine_strata_parameters(vp, 5, vaccine_waning = TRUE)
  expect_equal(s$protection, c(0, 0.85, 0.93, 0.90, 0.97))
  expect_equal(1 / (s$short_term_waning[c(3, 5)] * 365), c(15, 25))
  expect_equal(1 / (s$long_term_waning[c(2, 4)] * 365), c(25, 75))
})

test_that("protection in the packaged parameters is in [0, 1] with short >= long", {
  for (disease in c("measles", "diphtheria", "pertussis")) {
    p <- cached_params("SDN", disease, default_R0[[disease]])
    m <- p$age_vaccination_beta_modifier
    expect_true(all(m >= 0 & m <= 1), info = disease)
    for (d in seq_len((p$n_vacc - 1) / 2)) {
      expect_true(all(m[, 2 * d + 1, ] >= m[, 2 * d, ]), info = disease)
    }
  }
})

test_that("measles vaccine protection does not wane by default, and the table is one argument away", {
  expect_false(PREVAIL:::resolve_vaccine_waning("default", "measles"))
  expect_true(PREVAIL:::resolve_vaccine_waning("default", "pertussis"))
  expect_true(PREVAIL:::resolve_vaccine_waning("table", "measles"))
  expect_false(PREVAIL:::resolve_vaccine_waning("none", "diphtheria"))

  p <- cached_params("GBR", "measles", 15)
  expect_true(all(p$short_term_waning == 0) && all(p$long_term_waning == 0))
  q <- cached_params("GBR", "measles", 15, vaccine_waning = "table")
  expect_equal(as.numeric(1 / (q$short_term_waning[c(3, 5)] * 365)), c(15, 25))
  d <- cached_params("GBR", "diphtheria", 3)
  expect_true(all(d$short_term_waning[c(3, 5, 7)] > 0))
})

test_that("the final DTP dose uses the last row of the table and earlier doses the first", {
  for (disease in c("diphtheria", "pertussis")) {
    vp <- PREVAIL::vaccine_parameters[PREVAIL::vaccine_parameters$disease == disease, ]
    s <- PREVAIL:::vaccine_strata_parameters(vp, 7, vaccine_waning = TRUE)
    rows <- sort(unique(vp$dose))
    expect_equal(s$table$table_dose, c(rows[1], rows[1], rows[2]), info = disease)
    first <- vp$value[vp$dose == rows[1] & vp$parameter == "short_term_protection"]
    last <- vp$value[vp$dose == rows[2] & vp$parameter == "short_term_protection"]
    expect_equal(s$protection[c(3, 5, 7)], c(first, first, last), info = disease)
  }
})

test_that("custom vaccine parameters reach the model", {
  custom <- expand.grid(parameter = c("waning", "protection"), duration = c("short", "long"), dose = c(1, 2),
                        stringsAsFactors = FALSE)
  custom <- custom[order(custom$parameter, custom$duration, custom$dose), ]
  # long protection (doses 1, 2), short protection, long waning, short waning
  custom$value <- c(0.5, 0.7, 0.8, 0.95, 50, 75, 10, 25)
  p <- custom_data_process_wrapper("GBR", "measles", R0 = 15, year_end = 2025,
                                   custom_vaccine_parameters = custom, vaccine_waning = "table")
  expect_equal(p$age_vaccination_beta_modifier[1, , 1], c(0, 0.5, 0.8, 0.7, 0.95))
  expect_equal(as.numeric(1 / (p$short_term_waning[c(3, 5)] * 365)), c(10, 25))
  expect_equal(as.numeric(1 / (p$long_term_waning[c(2, 4)] * 365)), c(50, 75))
})

test_that("a custom schedule sets the age of each dose", {
  schedule <- data.frame(year = c(1980, 2020, 1980, 2020), dose = c(1, 1, 2, 2), age = c("M12", "Y15", "Y6", "Y60"))
  p <- custom_data_process_wrapper("GBR", "measles", R0 = 15, year_end = 2025, custom_vaccination_schedule = schedule)
  expect_equal(unname(p$history$dose_ages["2010", ]), c(1, 6))
  expect_equal(unname(p$history$dose_ages["2021", ]), c(15, 60))
  y2010 <- which(rownames(p$history$dose_ages) == "2010")
  # second dose given to those with one dose, in the 5-9 group
  expect_gt(p$vaccination_coverage[2, 3, 1, y2010], 0)
  expect_equal(p$vaccination_coverage[1, 3, 1, y2010], 0)
})
