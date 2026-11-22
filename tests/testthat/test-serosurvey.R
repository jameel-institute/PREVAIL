fake_history <- function() {
  list(by_age = data.frame(population = c(100, 300, 600), immune_infection = c(0.1, 0.5, 0.9),
                           immune_vaccine = c(0.6, 0.4, 0), susceptible = c(0.3, 0.1, 0.1)),
       age_breaks = "0;5;10;Inf")
}

test_that("a band matching a model age group returns that group's immunity", {
  h <- fake_history()
  expect_equal(modelled_seroprevalence(h, 0, 4), 0.7)
  expect_equal(modelled_seroprevalence(h, 5, 9), 0.9)
  expect_equal(modelled_seroprevalence(h, 10, NA), 0.9)
})

test_that("bands spanning groups are weighted by population and coverage", {
  h <- fake_history()
  # 0-9 covers both groups fully: (100 * 0.7 + 300 * 0.9) / 400
  expect_equal(modelled_seroprevalence(h, 0, 9), (70 + 270) / 400)
  # 3-6 covers 2/5 of the first group and 2/5 of the second
  w <- c(100, 300) * 2 / 5
  expect_equal(modelled_seroprevalence(h, 3, 6), sum(w * c(0.7, 0.9)) / sum(w))
  # months: 6-11 months sits inside the 0-4 group
  expect_equal(modelled_seroprevalence(h, 0.5, 11 / 12), 0.7)
})

test_that("assay error and vaccine seropositivity move the expected share", {
  h <- fake_history()
  expect_equal(modelled_seroprevalence(h, 0, 4, sensitivity = 0.9, specificity = 0.95), 0.9 * 0.7 + 0.05 * 0.3)
  expect_equal(modelled_seroprevalence(h, 0, 4, vaccine_seropositive = 0.5), 0.1 + 0.3)
})

test_that("single-year models use one group per year of age", {
  h <- list(by_age = data.frame(population = rep(10, 101), immune_infection = seq(0, 1, length.out = 101),
                                immune_vaccine = 0, susceptible = 0),
            age_breaks = paste(1:101, collapse = ";"))
  expect_equal(modelled_seroprevalence(h, 2, 2), 0.02)
  expect_equal(modelled_seroprevalence(h, 2, 3), 0.025)
})

test_that("the log-likelihood is binomial by default and beta-binomial with overdispersion", {
  expect_equal(serosurvey_loglik(c(8, 9), c(10, 10), c(0.8, 0.9)),
               dbinom(8, 10, 0.8, log = TRUE) + dbinom(9, 10, 0.9, log = TRUE))
  expect_equal(serosurvey_loglik(c(8, NA), c(10, 10), c(0.8, 0.9)), dbinom(8, 10, 0.8, log = TRUE))
  # overdispersion flattens the likelihood, so a poor fit is penalised less
  expect_gt(serosurvey_loglik(50, 100, 0.9, overdispersion = 0.1), serosurvey_loglik(50, 100, 0.9))
  # and tends to the binomial as it goes to zero
  expect_equal(serosurvey_loglik(8, 10, 0.8, overdispersion = 1e-8), dbinom(8, 10, 0.8, log = TRUE), tolerance = 1e-4)
})
