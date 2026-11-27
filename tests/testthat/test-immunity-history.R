test_that("measles has a reproduction number near one where it is endemic", {
  skip_if_slow()
  # Democratic Republic of the Congo and Chad: measles reported above the threshold every recent year
  for (iso in c("COD", "TCD")) {
    h <- cached_history(iso, "measles", 15)
    expect_true(h$inputs$circulating_now, info = iso)
    expect_gt(h$summary$reff, 0.85)
    expect_lt(h$summary$reff, 1.2)
  }
})

test_that("reported cases alone leave far more people susceptible", {
  skip_if_slow()
  circulating <- cached_history("COD", "measles", 15)
  reported <- cached_history("COD", "measles", 15, transmission_history = "reported_cases_only")
  expect_gt(reported$summary$reff, 3)
  expect_gt(reported$summary$susceptible, 2 * circulating$summary$susceptible)
  # under complete reporting modelled infections are the reported cases (placed with binomial draws, so up to
  # sampling noise)
  recent <- tail(reported$infections, 10)
  recent <- recent[!is.na(recent$reported_cases), ]
  expect_true(all(abs(recent$infections - recent$reported_cases) <= 3 * sqrt(recent$reported_cases) + 5))
  # and the circulating-years history implies that only a few percent of infections are reported
  implied <- sum(tail(circulating$infections$reported_cases, 10), na.rm = TRUE) / sum(tail(circulating$infections$infections, 10))
  expect_lt(implied, 0.2)
})

test_that("the history returns a state a projection can start from", {
  skip_if_slow()
  h <- cached_history("COD", "measles", 15)
  expect_s3_class(h, "prevail_immunity_history")
  expect_equal(dim(h$state$S0), c(17, 5, 1))
  expect_equal(h$state$S0, round(h$state$S0))
  total <- sum(h$state$S0) + sum(h$state$I0) + sum(h$state$Rpop0)
  expect_equal(total, h$summary$population, tolerance = 1e-4)
  expect_equal(h$year_end, 2025)
  expect_equal(nrow(h$infections), 75)
  expect_equal(sum(h$inputs$age_distribution), 1)
  # population at the start of 2025 within 10% of UN WPP's for 2023 carried forward
  wpp <- PREVAIL::UN_WPP_population_total
  wpp <- wpp[wpp$iso3 == "COD" & wpp$year == 2023, ]
  wpp_total <- 1000 * sum(as.numeric(unlist(wpp[, paste0("x", 0:100)])))
  expect_equal(h$summary$population / wpp_total, 1, tolerance = 0.1)
})

test_that("the same seed gives the same history", {
  skip_if_slow()
  a <- run_immunity_history("PSE", "measles", R0 = 15, year_end = 2025, seed = 3)
  b <- run_immunity_history("PSE", "measles", R0 = 15, year_end = 2025, seed = 3)
  expect_equal(a$state$S0, b$state$S0)
  expect_equal(a$summary$reff, b$summary$reff)
})

test_that("an ensemble can be written as JSON and read back", {
  skip_if_slow()
  ens <- run_immunity_ensemble("PSE", "measles", R0 = c(12, 18), coverage_accuracy = c(0.5, 2), seeds = 1,
                               R0_weights = c(1, 3), year_end = 2025)
  expect_s3_class(ens, "prevail_immunity_ensemble")
  expect_equal(nrow(ens$grid), 4)
  expect_equal(sum(ens$grid$weight), 1)
  expect_equal(ens$grid$weight[ens$grid$R0 == 18][1] / ens$grid$weight[ens$grid$R0 == 12][1], 3)
  # more accurate (higher) coverage leaves fewer susceptible
  s <- ens$grid
  expect_lt(s$susceptible[s$R0 == 12 & s$coverage_accuracy == 2], s$susceptible[s$R0 == 12 & s$coverage_accuracy == 0.5])

  file <- tempfile(fileext = ".json")
  write_immunity_json(ens, file)
  json <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  expect_equal(json$schema_version, 1)
  expect_equal(json$iso, "PSE")
  expect_equal(json$year_start, 2025)
  expect_equal(json$assumptions$transmission_history, "circulating_years")
  expect_length(json$worlds, 4)
  n <- json$dims$n_age * json$dims$n_vacc
  for (w in json$worlds) {
    expect_length(w$S0, n)
    expect_length(w$I0, n)
    expect_length(w$Rpop0, n)
  }
  expect_equal(sum(vapply(json$worlds, function(w) w$w, numeric(1))), 1, tolerance = 1e-5)
  expect_equal(unlist(json$worlds[[1]]$S0), as.vector(ens$worlds[[1]]$state$S0))
  expect_length(json$routine$rates, n)
  expect_length(json$contact_matrix, json$dims$n_age^2)
  expect_length(json$vaccine, 2)
  expect_null(json$vaccine[[1]]$short$years)
  expect_true(all(c("reff", "p_reff_above_1", "by_age", "history", "coverage_by_cohort", "implied_reporting") %in% names(json$diagnostics)))
  expect_length(json$diagnostics$history$year, 25)

  # a single history can be written too
  single <- write_immunity_json(ens$worlds[[1]])
  expect_length(jsonlite::fromJSON(single, simplifyVector = FALSE)$worlds, 1)
})

test_that("snapshots record immunity by age in earlier years of the same run", {
  skip_if_slow()
  expect_warning(
    h <- run_immunity_history("GBR", "measles", R0 = 15, year_end = 2000, seed = 2,
                              snapshot_years = c(2000, 1980, 2030, 1990)),
    "2030"
  )
  expect_equal(unique(h$snapshots$year), c(1980, 1990, 2000))
  expect_equal(names(h$snapshots), c("year", names(h$by_age)))
  # the snapshot at the end of the run is the run's own immunity by age
  final <- h$snapshots[h$snapshots$year == 2000, -1]
  rownames(final) <- NULL
  expect_equal(final, h$by_age)
  # and an earlier snapshot is close to the end of a run stopped in that year (where coverage data start before it;
  # inputs such as back-filled coverage depend a little on year_end, so the two are not identical)
  short <- run_immunity_history("GBR", "measles", R0 = 15, year_end = 1990, seed = 2)
  earlier <- h$snapshots[h$snapshots$year == 1990, -1]
  rownames(earlier) <- NULL
  expect_equal(earlier$immune_infection, short$by_age$immune_infection, tolerance = 0.01)
  expect_null(short$snapshots)

  # infections by age sum to the yearly totals
  expect_equal(dim(h$infections_by_age), c(nrow(h$infections), h$dims$n_age))
  expect_equal(rownames(h$infections_by_age), as.character(h$infections$year))
  expect_equal(unname(rowSums(h$infections_by_age)), h$infections$infections)
  expect_equal(unname(h$infections_by_age[, 1]), h$infections$infections_first_age_group)
})
