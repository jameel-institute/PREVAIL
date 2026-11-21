# Small runs of the model itself, from a real parameter set with transmission and seeding changed as needed.
run_states <- function(params, days, seed = 1) {
  sys <- dust2::dust_system_create(PREVAIL:::transmission_model(), params, n_particles = 1, seed = seed)
  dust2::dust_system_set_state_initial(sys)
  dust2::dust_system_run_to_time(sys, days)
  dust2::dust_unpack_state(sys, dust2::dust_system_state(sys))
}

no_seeding <- function(p) {
  p$seeded[] <- 0
  p
}

test_that("infections clear to zero once transmission stops", {
  p <- no_seeding(cached_params("PSE", "measles", 15))
  p$R0 <- 0
  p$tt_R0 <- 0
  p$no_R0_changes <- 1
  p$I0[, 1, 1] <- 50
  s <- run_states(p, 365)
  # ageing and vaccination move whole people, so nobody is left part-way through an infection
  expect_equal(sum(s$E) + sum(s$I) + sum(s$Is), 0)
  expect_true(all(s$R == round(s$R)))
})

test_that("the force of infection uses the prevalence in the contacted age group", {
  p <- no_seeding(cached_params("PSE", "measles", 15))
  p$vaccination_coverage[] <- 0
  p$age_vaccination_beta_modifier[] <- 0
  p$migration_in_number[] <- 0
  # everyone susceptible, and the same share infectious in every age group
  N <- rowSums(p$S0[, , 1])
  p$S0[] <- 0
  p$S0[, 1, 1] <- N
  p$I0[] <- 0
  p$I0[, 1, 1] <- round(N / 1000)
  sys <- dust2::dust_system_create(PREVAIL:::transmission_model(), p, n_particles = 1, deterministic = TRUE)
  dust2::dust_system_set_state_initial(sys)
  dust2::dust_system_run_to_time(sys, 1)
  s <- dust2::dust_unpack_state(sys, dust2::dust_system_state(sys))
  # with uniform prevalence every age group faces the same force of infection
  attack <- s$E[, 1, 1] / N
  expect_lt(diff(range(attack)) / mean(attack), 0.02)
})

test_that("long-term vaccine protection wanes to unvaccinated in every compartment", {
  p <- no_seeding(cached_params("PSE", "measles", 15, vaccine_waning = "table"))
  p$vaccination_coverage[] <- 0
  p$R0[] <- 0
  N <- rowSums(p$S0[, , 1])
  p$S0[] <- 0
  p$S0[, 4, 1] <- N  # everyone in the long-term stratum of dose 2
  sys <- dust2::dust_system_create(PREVAIL:::transmission_model(), p, n_particles = 1, deterministic = TRUE)
  dust2::dust_system_set_state_initial(sys)
  dust2::dust_system_run_to_time(sys, 30)
  s <- dust2::dust_unpack_state(sys, dust2::dust_system_state(sys))
  expect_gt(sum(s$S[-1, 1, 1]), 0)
  # not back to the short-term stratum of dose 1, which has more protection than where they came from
  expect_equal(sum(s$S[, 3, 1]), 0)
})

test_that("maternal antibodies protect infants", {
  p <- no_seeding(cached_params("PSE", "measles", 15))
  p$vaccination_coverage[] <- 0
  p$age_vaccination_beta_modifier[] <- 0
  p$migration_in_number[] <- 0
  N <- rowSums(p$S0[, , 1])
  # children susceptible, everyone of reproductive age (and older) immune from past infection
  adults <- seq_len(p$n_age) >= p$repro_low
  p$S0[] <- 0
  p$S0[!adults, 1, 1] <- N[!adults]
  p$Rpop0[] <- 0
  p$Rpop0[adults, 1, 1] <- N[adults]
  p$I0[] <- 0
  p$I0[!adults, 1, 1] <- 100
  infant_infections <- function(weight_rec) {
    p$protection_weight_rec <- weight_rec
    p$protection_weight_vacc <- 0
    sys <- dust2::dust_system_create(PREVAIL:::transmission_model(), p, n_particles = 1, deterministic = TRUE)
    dust2::dust_system_set_state_initial(sys)
    dust2::dust_system_run_to_time(sys, 1)
    s <- dust2::dust_unpack_state(sys, dust2::dust_system_state(sys))
    c(infants = sum(s$E[1, , ]), older = sum(s$E[2, , ]))
  }
  none <- infant_infections(0)
  half <- infant_infections(0.5)
  # all mothers immune, half protection: infants' risk halves and nobody else's changes
  expect_equal(half[["infants"]] / none[["infants"]], 0.5, tolerance = 1e-6)
  expect_equal(half[["older"]], none[["older"]])
})
