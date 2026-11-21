test_that("the effective reproduction number is R0 in a fully susceptible population", {
  set.seed(1)
  C <- matrix(runif(16), 4, 4)
  C <- PREVAIL:::project_to_symmetric_doubly_stochastic(C)
  N <- c(100, 300, 50, 20)
  S <- cbind(N, 0, 0)
  expect_equal(effective_reproduction_number(S, N, protection = c(0, 0.85, 0.93), contact_matrix = C, R0 = 15), 15)
})

test_that("uniform immunity scales the reproduction number", {
  C <- PREVAIL:::project_to_symmetric_doubly_stochastic(matrix(c(4, 1, 1, 1, 3, 1, 1, 1, 2), 3, 3))
  N <- c(100, 200, 300)
  expect_equal(effective_reproduction_number(cbind(0.2 * N), N, 0, C, 10), 2)
  # everyone vaccinated with protection m: susceptibility and infectiousness both fall by (1 - m)
  S <- cbind(0, N)
  expect_equal(effective_reproduction_number(S, N, c(0, 0.5), C, 12), 12 * 0.25)
})

test_that("it is the dominant eigenvalue of the next-generation matrix, not a mean of row sums", {
  C <- PREVAIL:::project_to_symmetric_doubly_stochastic(matrix(c(10, 1, 1, 1), 2, 2))
  N <- c(100, 100)
  S <- cbind(c(100, 0))  # children all susceptible, adults all immune
  r <- effective_reproduction_number(S, N, 0, C, 10)
  expect_equal(r, 10 * C[1, 1])
  # the model's own Reff output is the unweighted mean of the age groups' row sums: sum(e_i * C[i, ]) / n_age
  expect_false(isTRUE(all.equal(r, 10 * mean(c(1, 0) * rowSums(C)))))
})

test_that("arrays with a risk dimension are accepted", {
  C <- matrix(0.5, 2, 2)
  S <- array(c(10, 20, 0, 0), dim = c(2, 2, 1))
  m <- array(c(0, 0, 0.9, 0.9), dim = c(2, 2, 1))
  expect_equal(effective_reproduction_number(S, c(10, 20), m, C, 4), 4)
  expect_error(effective_reproduction_number(S, c(10, 20, 30), m, C, 4))
})

test_that("immunity shares add up", {
  skip_if_slow()
  h <- cached_history("GBR", "measles", 15, transmission_history = "reported_cases_only")
  shares <- with(h$by_age, susceptible_unvaccinated + susceptible_vaccinated + immune_vaccine + immune_infection)
  expect_equal(shares, rep(1, nrow(h$by_age)), tolerance = 1e-8)
  expect_equal(h$by_age$susceptible, h$by_age$susceptible_unvaccinated + h$by_age$susceptible_vaccinated)
  expect_true(h$summary$reff > 0 && h$summary$reff < 15)
})
