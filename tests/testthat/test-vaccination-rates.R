test_that("the daily rate gives the target coverage on leaving the age group", {
  a <- 1 / (5 * 365)
  for (target in c(0.3, 0.62, 0.9, 0.99)) {
    p <- PREVAIL:::coverage_to_daily_rate(target, a)
    # a cohort entering unvaccinated, in the model's order: vaccination applies from the day of arrival, and each
    # day after that a share a leaves and then a share p of the rest is vaccinated
    unvaccinated <- 1 - p
    left_unvaccinated <- 0
    for (day in 1:(365 * 200)) {
      left_unvaccinated <- left_unvaccinated + unvaccinated * a
      unvaccinated <- unvaccinated * (1 - a) * (1 - p)
    }
    expect_equal(1 - left_unvaccinated, target, tolerance = 1e-6)
  }
})

test_that("the 0.1.0 conversion could not reach high coverage", {
  a <- 1 / (5 * 365)
  old_rate <- function(coverage) -log(1 - coverage) / (5 * 365)
  achieved <- function(p) p / (a + p * (1 - a))
  expect_lt(achieved(old_rate(0.9)), 0.71)
  expect_lt(achieved(old_rate(0.999)), 0.88)
  expect_equal(achieved(PREVAIL:::coverage_to_daily_rate(0.9, a)), 0.9)
})

test_that("coverage accuracy multiplies the odds of vaccination", {
  expect_equal(PREVAIL:::adjust_coverage_odds(0.5, 2), 2 / 3)
  expect_equal(PREVAIL:::adjust_coverage_odds(0.9, 1), 0.9)
  a <- 1 / (5 * 365)
  achieved <- function(p) p / (a + p * (1 - a))
  expect_equal(achieved(PREVAIL:::coverage_to_daily_rate(0.9, a, coverage_accuracy = 2)), 18 / 19)
  expect_equal(achieved(PREVAIL:::coverage_to_daily_rate(0.9, a, coverage_accuracy = 0.5)), 4.5 / 5.5)
})

test_that("coverage of a missing middle dose is taken from its neighbours", {
  data <- data.frame(
    year = rep(2000:2004, 2), dose_order = rep(c(1, 3), each = 5),
    coverage = c(rep(90, 5), rep(70, 5)), vaccine_description = "DTP-containing vaccine"
  )
  out <- PREVAIL:::routine_dose_coverage(data, n_doses = 3, years = 1998:2006)
  expect_equal(attr(out, "interpolated_doses"), 2)
  expect_equal(unname(out["2002", ]), c(0.9, 0.8, 0.7))
  expect_equal(unname(out["1999", ]), c(0, 0, 0))
  # carried forward after the last year with data
  expect_equal(unname(out["2006", ]), c(0.9, 0.8, 0.7))
})

test_that("a later dose never has higher coverage than the one before", {
  data <- data.frame(year = rep(2000:2001, 2), dose_order = rep(1:2, each = 2), coverage = c(60, 60, 80, 50),
                     vaccine_description = "Measles-containing vaccine")
  out <- PREVAIL:::routine_dose_coverage(data, n_doses = 2, years = 2000:2001)
  expect_true(all(out[, 2] <= out[, 1]))
})

test_that("every dose has a rate wherever its coverage is above zero", {
  for (disease in c("measles", "diphtheria", "pertussis")) {
    for (iso in c("GBR", "SDN", "PSE")) {
      p <- cached_params(iso, disease, default_R0[[disease]])
      coverage <- p$history$routine_coverage
      for (d in seq_len(ncol(coverage))) {
        strata <- if (d == 1) 1 else c(2 * d - 2, 2 * d - 1)
        for (j in strata) {
          max_rate <- apply(p$vaccination_coverage[, j, 1, , drop = FALSE], 4, max)
          expect_true(all(max_rate[coverage[, d] > 0] > 0), info = paste(iso, disease, "dose", d, "stratum", j))
        }
      }
    }
  }
})

test_that("the second DTP dose is given (it had no rate in 0.1.0)", {
  p <- cached_params("SDN", "diphtheria", 3)
  final <- dim(p$vaccination_coverage)[4]
  expect_gt(p$vaccination_coverage[1, 2, 1, final], 0)
  expect_gt(p$vaccination_coverage[1, 3, 1, final], 0)
  # nothing is vaccinated out of the last dose's strata
  expect_true(all(p$vaccination_coverage[, 6:7, , ] == 0))
})

test_that("coverage read back from a model run matches the coverage put in", {
  skip_if_slow()
  routine <- rbind(
    data.frame(year = 1950:2025, age = 1, dose = 1, coverage = 0.9),
    data.frame(year = 1950:2025, age = 1, dose = 2, coverage = 0.8)
  )
  no_campaigns <- data.frame(year = 2000, age = 1, dose = 1, coverage = 0)
  h <- run_immunity_history(
    "GBR", "measles", R0 = 0, circulation_threshold = 0, seed_floor = 0, year_end = 2025,
    custom_routine_vaccination = routine, custom_sia_vaccination = no_campaigns
  )
  cov <- h$coverage
  school_age <- cov$age_group %in% 2:6
  expect_equal(cov$achieved[school_age & cov$dose == 1], rep(0.9, 5), tolerance = 0.015)
  expect_equal(cov$achieved[school_age & cov$dose == 2], rep(0.8, 5), tolerance = 0.02)
  expect_equal(cov$reported[school_age & cov$dose == 1], rep(0.9, 5))
})

test_that("coverage read back from a historical run is close to reported coverage", {
  skip_if_slow()
  h <- cached_history("GBR", "measles", 15, transmission_history = "reported_cases_only")
  cov <- h$coverage[h$coverage$age_group %in% 2:3 & h$coverage$dose == 1, ]
  expect_true(all(abs(cov$achieved - cov$reported) < 0.03))
  # under fives are vaccinated at all (none were in 0.1.0, where the first UK dose was given to adults)
  expect_gt(h$by_age$vaccinated[1], 0.8)
})

test_that("a campaign reaches the stated share of the age group within its year", {
  population <- matrix(1, nrow = 3, ncol = 101)
  rates <- PREVAIL:::build_vaccination_rates(
    routine_coverage = matrix(0, 3, 2), dose_ages = matrix(1, 3, 2),
    sia = data.frame(year = 2001, age = 0:4, coverage = 0.5), years = 2000:2002, n_vacc = 5,
    population = population, aggregate_age = TRUE, new_age_breaks = c(0, 5, 10, Inf)
  )
  expect_equal(unique(rates$year), 2001)
  expect_equal(sort(unique(rates$dim2)), 1:3)
  expect_equal(unique(rates$dim1), 1)
  expect_equal(1 - (1 - rates$value[1])^365, 0.5)
})

test_that("relative coverage scales coverage, not the daily rate", {
  a <- rep(1 / (5 * 365), 3)
  rates <- array(0, dim = c(3, 5, 1))
  rates[1, 1, 1] <- PREVAIL:::coverage_to_daily_rate(0.9, a[1])
  rates[1, 2:3, 1] <- PREVAIL:::coverage_to_daily_rate(0.8, a[1])
  half <- PREVAIL:::scale_vaccination_rates(rates, a, 0.5)
  expect_equal(half[1, 1, 1] / (a[1] + half[1, 1, 1] * (1 - a[1])), 0.45)
  expect_equal(half[1, 2:3, 1], rates[1, 2:3, 1])
  expect_true(all(PREVAIL:::scale_vaccination_rates(rates, a, 0) == 0))
  expect_equal(PREVAIL:::scale_vaccination_rates(rates, a, 1), rates)
})
