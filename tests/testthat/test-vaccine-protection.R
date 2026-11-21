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
