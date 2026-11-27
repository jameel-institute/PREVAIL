test_that("schedule ages are converted one by one, each in its own unit", {
  x <- c("Y1", "M40", "W8", "D30", "M9", "Y11-Y12", "M12-M23", ">=Y65", "B", "1st contact", NA)
  expect_equal(
    as.numeric(PREVAIL:::parse_schedule_age(x)),
    c(1, 40 / 12, 8 / 52, 30 / 365, 0.75, 11.5, 17.5 / 12, 65, 0, NA, NA)
  )
})

test_that("a range with one unit letter uses it for both ends", {
  expect_equal(as.numeric(PREVAIL:::parse_schedule_age("M9-12")), 10.5 / 12)
})

test_that("ages relative to the previous dose are added to it", {
  schedule <- data.frame(
    iso3 = "XXX", year = 2024, vaccine_code = "DTP", vaccine_description = "DTP vaccine", schedulerounds = 1:3,
    target_pop = NA, target_pop_description = "General/routine", age_administered = c("M2", "+M2", "+M2")
  )
  out <- PREVAIL:::filter_vaccine_schedule(schedule, "DTP", "XXX")
  expect_equal(out$age_years[order(out$schedulerounds)], c(2, 4, 6) / 12)
})

test_that("measles doses are scheduled in early childhood in GBR, SDN and PSE", {
  expected <- list(GBR = c(1, 40 / 12), SDN = c(9, 18) / 12, PSE = c(12, 18) / 12)
  for (iso in names(expected)) {
    schedule <- PREVAIL:::filter_vaccine_schedule(PREVAIL::WHO_vaccination_schedule, "measles", iso)
    ages <- PREVAIL:::routine_dose_ages(schedule, n_doses = 2, years = 2020:2025)
    expect_equal(unname(ages[nrow(ages), ]), expected[[iso]], info = iso)
  }
})

test_that("the first measles dose is given to under fives in the model", {
  for (iso in c("GBR", "SDN", "PSE")) {
    p <- cached_params(iso, "measles", 15)
    dose1_rate_by_age <- apply(p$vaccination_coverage[, 1, 1, ], 1, max)
    # routine first doses are in the first age group; campaigns can reach older ages, at lower rates
    expect_gt(dose1_rate_by_age[1], 0)
    expect_equal(which.max(dose1_rate_by_age), 1, info = iso)
    routine_only_year <- which(rownames(p$history$routine_coverage) == "2024")
    expect_true(all(p$vaccination_coverage[-1, 1, 1, routine_only_year] == 0), info = iso)
  }
})

test_that("DTP primary doses are scheduled in infancy and boosters later", {
  for (iso in c("GBR", "SDN", "PSE")) {
    p <- cached_params(iso, "diphtheria", 3)
    ages <- p$history$dose_ages[nrow(p$history$dose_ages), ]
    expect_true(all(ages[1:3] < 1), info = iso)
    expect_true(all(ages[-(1:3)] >= 1), info = iso)
  }
})
