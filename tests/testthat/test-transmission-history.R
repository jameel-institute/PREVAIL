population <- matrix(1000 / 101, nrow = 6, ncol = 101)  # one million people each year (thousands by single age)
years <- 2000:2005

test_that("circulating years follow the reported cases per million", {
  reports <- data.frame(year = c(2001, 2002, 2004, 2005), cases = c(5, 1, 0, 2))
  h <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 15, disease = "measles",
                                            transmission_history = "circulating_years")
  # on before reporting starts; on at >= 2 per million; a year with no report keeps the previous status
  expect_equal(h$summary$transmission_on, c(TRUE, TRUE, FALSE, FALSE, FALSE, TRUE))
  expect_equal(h$R0, c(15, 15, 0, 0, 0, 15))
  expect_equal(h$tt_R0, (0:5) * 365)
  # reported cases are introduced each year, never fewer than the floor
  expect_equal(h$summary$seeded_infections, rep(10, 6))
  h2 <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 15, disease = "measles",
                                             circulation_threshold = 6)
  expect_equal(h2$summary$transmission_on, c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE))
})

test_that("pertussis is treated as circulating every year", {
  reports <- data.frame(year = years, cases = 0)
  h <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 12, disease = "pertussis")
  expect_true(all(h$summary$transmission_on))
  expect_true(all(h$R0 == 12))
})

test_that("reported cases only: transmission stops at the first reported case and only reported cases are seeded", {
  reports <- data.frame(year = c(2002, 2003, 2004, 2005), cases = c(100, 0, 40, NA))
  h <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 15, disease = "measles",
                                            transmission_history = "reported_cases_only")
  expect_equal(h$R0, c(15, 0))
  expect_equal(h$tt_R0, c(0, 2 * 365))
  expect_equal(h$summary$seeded_infections, c(0, 0, 100, 0, 40, 0))
  # pulses last one day
  expect_equal(h$tt_seeded, c(0, 730, 731, 1460, 1461))
  per_slice <- tapply(h$seed_data$value, h$seed_data$dim4, sum)
  expect_equal(as.numeric(per_slice), c(1, 100, 0, 40, 0))
})

test_that("a reporting fraction scales the seeded infections", {
  reports <- data.frame(year = years, cases = c(100, 100, 100, 100, 100, 100))
  h <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 15, disease = "measles",
                                            transmission_history = "reported_cases_only", reporting_fraction = 0.1)
  expect_equal(h$summary$seeded_infections, rep(1000, 6))
  by_year <- c("2000" = 1, "2003" = 0.5)
  h2 <- PREVAIL:::build_transmission_history(reports, population, years, R0 = 15, disease = "measles",
                                             transmission_history = "reported_cases_only", reporting_fraction = by_year)
  expect_equal(h2$summary$seeded_infections, c(100, 100, 200, 200, 200, 200))
  expect_error(PREVAIL:::expand_reporting_fraction(0, years))
  expect_error(PREVAIL:::expand_reporting_fraction(1.5, years))
})

test_that("seeds are placed by age in whole numbers that add up", {
  out <- PREVAIL:::apportion_whole(10, c(1, 1, 1))
  expect_equal(sum(out), 10)
  expect_true(all(out == round(out)))
  expect_equal(PREVAIL:::apportion_whole(0, c(1, 2)), c(0, 0))
  expect_equal(PREVAIL:::apportion_whole(7, c(0, 1)), c(0, 7))
})

test_that("the original assumption is reproduced for the United Kingdom", {
  p <- cached_params("GBR", "measles", 15, transmission_history = "reported_cases_only")
  expect_equal(p$R0, c(15, 0))
  expect_equal(p$tt_R0, c(0, 30 * 365))  # first WHO-reported case: 1980
  reported <- PREVAIL::WHO_disease_reports
  reported <- reported[reported$iso3 == "GBR" & reported$disease_short == "measles" & !is.na(reported$cases) & reported$year < 2025, ]
  pulses <- apply(p$seeded, 4, sum)
  expect_equal(sum(pulses[-1]), sum(reported$cases))
  expect_equal(p$input_data$transmission_history, "reported_cases_only")
})

test_that("the default follows the years the disease was circulating", {
  p <- cached_params("GBR", "measles", 15)
  expect_equal(p$input_data$transmission_history, "circulating_years")
  on <- p$history$transmission$transmission_on
  expect_equal(length(p$R0), 76)
  expect_true(all(on[p$history$transmission$year < 1980]))
  expect_equal(p$R0, ifelse(on, 15, 0))
  # 2021: two reported cases in the United Kingdom
  expect_false(on[p$history$transmission$year == 2021])
})

test_that("WHO_seed_switch = FALSE still means transmission throughout, with a warning", {
  expect_warning(p <- data_load_process_wrapper("PSE", "measles", R0 = 15, year_end = 2025, WHO_seed_switch = FALSE),
                 "deprecated")
  expect_true(all(p$R0 == 15))
  expect_equal(p$input_data$transmission_history, "circulating_years")
  expect_equal(p$input_data$circulation_threshold, 0)
  expect_error(data_load_process_wrapper("PSE", "measles", R0 = 15, transmission_history = "endemic"))
})
