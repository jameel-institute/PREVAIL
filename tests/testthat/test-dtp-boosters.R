toy_schedule <- function(codes, ages, iso = "XXX") {
  data.frame(iso3 = iso, year = 2023, vaccine_code = codes, schedulerounds = seq_along(codes),
             target_pop = NA, target_pop_description = "General/routine", age_administered = ages)
}

test_that("boosters are the scheduled ages after the primary series, and only pertussis-containing ones count for pertussis", {
  s <- toy_schedule(c("DTAPIPV", "DTAPIPV", "DTAPIPV", "DTAPIPV", "TDIPV_S"), c("W8", "W12", "W16", "Y3-Y4", "Y14"))
  d <- PREVAIL:::dtp_booster_schedule(s, "XXX", "diphtheria")
  expect_equal(d$dose, 4:5)
  expect_equal(d$age, c(3.5, 14))
  expect_equal(d$pertussis, c(TRUE, FALSE))
  expect_equal(d$coverage_dose, 4:5)

  p <- PREVAIL:::dtp_booster_schedule(s, "XXX", "pertussis")
  expect_equal(p$dose, 4L)
  expect_equal(p$coverage_dose, 4L)

  # a school-age Tdap after a Td still takes the third booster's coverage
  s2 <- toy_schedule(c("DTWP", "DTWP", "DTWP", "TD_S", "TDAP_S"), c("W6", "W10", "W14", "Y6", "Y12"))
  p2 <- PREVAIL:::dtp_booster_schedule(s2, "XXX", "pertussis")
  expect_equal(p2$dose, 4L)
  expect_equal(p2$coverage_dose, 5L)
})

test_that("boosters without WHO coverage data and adult doses are left out", {
  s <- toy_schedule(c("DTAP", "DTAP", "DTAP", "DTAP", "TDAP_S", "TD_S"), c("M2", "M4", "M6", "M15", "Y11", "Y25"))
  routine <- data.frame(iso3 = "XXX", vaccine = c("DIPHCV4", "DIPHCV5"), coverage = c(90, NA))
  d <- PREVAIL:::dtp_booster_schedule(s, "XXX", "diphtheria", routine)
  expect_equal(d$age, 1.25)
  expect_equal(nrow(PREVAIL:::dtp_booster_schedule(s[1:3, ], "XXX", "diphtheria")), 0)
})

test_that("booster coverage before its data is the same share of DTP3, from booster_since", {
  years <- 1995:2020
  cov <- cbind(dose1 = 0.95, dose2 = 0.9, dose3 = 0.85, dose4 = ifelse(years >= 2018, 0.68, 0))
  out <- PREVAIL:::backfill_booster_coverage(cov, years, booster_since = 2000)
  expect_equal(unname(out[years %in% 2000:2017, 4]), rep(0.68, 18))
  expect_equal(unname(out[years < 2000, 4]), rep(0, 5))
  expect_equal(out[years >= 2018, ], cov[years >= 2018, ])
})

test_that("boosters take the table's booster row and the primary doses its first row", {
  vp <- PREVAIL::vaccine_parameters[PREVAIL::vaccine_parameters$disease == "diphtheria", ]
  s <- PREVAIL:::vaccine_strata_parameters(vp, 11, vaccine_waning = TRUE, n_primary = 3)
  expect_equal(s$table$table_dose, c(1, 1, 1, 6, 6))
  expect_equal(s$protection, c(0, rep(c(0.5, 0.97), 3), rep(c(0.8, 0.99), 2)))
})

test_that("whole-cell pertussis uses its own primary-series rows and shares the booster row", {
  vp <- PREVAIL::vaccine_parameters[PREVAIL::vaccine_parameters$disease == "pertussis", ]
  wp <- PREVAIL:::select_pertussis_vaccine(vp, "whole_cell")
  ap <- PREVAIL:::select_pertussis_vaccine(vp, "acellular")
  expect_equal(unique(wp$vaccine[wp$dose == 3]), "DTwP")
  expect_equal(unique(ap$vaccine), "DTP")
  expect_equal(wp[wp$dose == 5, ], ap[ap$dose == 5, ])
  sw <- PREVAIL:::vaccine_strata_parameters(wp, 9, vaccine_waning = TRUE, n_primary = 3)
  sa <- PREVAIL:::vaccine_strata_parameters(ap, 9, vaccine_waning = TRUE, n_primary = 3)
  # same protection, slower waning after a whole-cell primary series
  expect_equal(sw$protection, sa$protection)
  expect_true(all(sw$short_term_waning[c(3, 5, 7)] < sa$short_term_waning[c(3, 5, 7)]))
  expect_equal(sw$short_term_waning[9], sa$short_term_waning[9])

  expect_equal(PREVAIL:::pertussis_vaccine_type(toy_schedule(rep("DTWPHIBHEPB", 3), c("W6", "W10", "W14")), "XXX"),
               "whole_cell")
  expect_equal(PREVAIL:::pertussis_vaccine_type(toy_schedule(rep("DTAPHIBIPV", 3), c("M2", "M4", "M6")), "XXX"),
               "acellular")
})

test_that("the United Kingdom gets its pre-school and teenage boosters, and pertussis only the pre-school one", {
  d <- cached_params("GBR", "diphtheria", default_R0[["diphtheria"]])
  p <- cached_params("GBR", "pertussis", default_R0[["pertussis"]])
  expect_equal(d$n_vacc, 11)
  expect_equal(p$n_vacc, 9)
  expect_equal(p$input_data$pertussis_vaccine, "acellular")
  rc <- d$history$routine_coverage
  # boosters are given before their coverage data start in 2018, and a reported 0 is not taken at face value
  expect_gt(rc["2000", "dose4"], 0.5)
  expect_gt(rc["2023", "dose5"], 0.5)
  expect_true(all(rc[, "dose5"] <= rc[, "dose4"]))

  off <- cached_params("GBR", "diphtheria", default_R0[["diphtheria"]], dtp_boosters = FALSE)
  expect_equal(off$n_vacc, 7)
})
