test_that("introductions in more than one year are each made once", {
  p <- cached_params("GBR", "measles", 15)
  events <- data.frame(time = c(0, 365, 730), relative_coverage = 1, R0 = 0, introduced_cases = c(10, 0, 10))
  set.seed(1)
  f <- prepare_future_data(p, events, list(S0 = p$S0, Rpop0 = p$Rpop0))
  per_slice <- apply(f$seeded, 4, sum)
  days_in_force <- diff(c(f$tt_seeded, 3 * 365))
  # 0.1.0 gave 3,660: the second pulse sat in the slice for day 365 and ran until day 730
  expect_equal(sum(per_slice * days_in_force), 20)
  expect_equal(per_slice[match(c(0, 730), f$tt_seeded)], c(10, 10))
  expect_equal(per_slice[match(c(1, 365, 731), f$tt_seeded)], c(0, 0, 0))
})

test_that("the model introduces exactly the cases asked for", {
  skip_if_slow()
  p <- cached_params("GBR", "measles", 15)
  events <- data.frame(time = c(0, 365, 730), relative_coverage = 1, R0 = 0, introduced_cases = c(10, 0, 10))
  set.seed(1)
  f <- prepare_future_data(p, events, list(S0 = p$S0, Rpop0 = p$Rpop0))
  sys <- dust2::dust_system_create(PREVAIL:::transmission_model(), f[setdiff(names(f), c("input_data", "history"))], n_particles = 1, seed = 1)
  dust2::dust_system_set_state_initial(sys)
  index <- dust2::dust_unpack_index(sys)
  new_case <- dust2::dust_system_simulate(sys, 1:(3 * 365), index_state = as.vector(index$new_case))
  expect_equal(sum(new_case), 20)
})

test_that("a single introduction and no introduction still work", {
  p <- cached_params("GBR", "measles", 15)
  one <- prepare_future_data(p, data.frame(time = 0, relative_coverage = 1, R0 = 15, introduced_cases = 5),
                             list(S0 = p$S0, Rpop0 = p$Rpop0))
  expect_equal(apply(one$seeded, 4, sum), c(5, 0))
  none <- prepare_future_data(p, data.frame(time = 0, relative_coverage = 1, R0 = 15, introduced_cases = 0),
                              list(S0 = p$S0, Rpop0 = p$Rpop0))
  expect_equal(sum(none$seeded), 0)
})

test_that("case fatality ratios are converted to daily probabilities", {
  r <- 1 / 8
  d <- PREVAIL:::cfr_to_daily_probability(0.03, r)
  expect_equal(d / (d + r), 0.03)
  expect_equal(PREVAIL:::cfr_to_daily_probability(0, r), 0)
  p <- cached_params("GBR", "measles", 15)
  expect_true(all(p$cfr_normal == 0))
  expect_equal(unique(as.vector(p$cfr_severe_real)), PREVAIL:::cfr_to_daily_probability(0.03, 1 / 8))
  expect_equal(unique(as.vector(p$prop_severe)), 0.2)
})
