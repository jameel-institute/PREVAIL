test_that("the last year of a dataset is carried forward", {
  df <- data.frame(iso3 = "XXX", year = 2020:2023, x0 = 1:4)
  out <- PREVAIL:::carry_forward_years(df, 2021:2026)
  expect_equal(out$year, 2021:2026)
  expect_equal(out$x0, c(2, 3, 4, 4, 4, 4))
})

test_that("births, deaths, migration and fertile-age weights are present in the final years", {
  for (iso in c("GBR", "SDN", "PSE")) {
    p <- cached_params(iso, "measles", 15)
    n <- unname(dim(p$crude_birth)[2])
    expect_equal(n, 2025 - 1950 + 1)
    expect_equal(p$input_data$demography_last_year, 2023)
    for (k in (n - 2):n) {
      expect_gt(sum(p$crude_birth[, k]), 0)
      expect_gt(sum(p$crude_death[, , k]), 0)
      expect_gt(sum(p$repro_weight[, k]), 0)
      expect_gt(sum(p$population[, k]), 0)
    }
    expect_equal(p$crude_birth[, n], p$crude_birth[, n - 2])
    expect_equal(p$migration_in_number[, , , n], p$migration_in_number[, , , n - 2])
  }
})

test_that("the wrappers leave the package data alone", {
  cached_params("GBR", "measles", 15)
  expect_true("vaccine" %in% names(PREVAIL::WHO_vaccination_routine))
  expect_true("vaccine" %in% names(PREVAIL::VIMC_vaccination_sia))
})

test_that("the population grows through the final years of a run", {
  skip_if_slow()
  h <- cached_history("SDN", "measles", 15, transmission_history = "reported_cases_only")
  # Sudan's under fives are about 15% of the population; with no births in the last year they fell well short
  under5 <- h$by_age$population[1] / sum(h$by_age$population)
  expect_gt(under5, 0.13)
})
