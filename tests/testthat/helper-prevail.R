# Parameter sets are slow enough to build (about a second each) that tests share them.
.cache <- new.env()

cached_params <- function(iso, disease, R0, ...) {
  key <- paste(iso, disease, R0, paste(names(list(...)), unlist(list(...)), collapse = "_"))
  if (is.null(.cache[[key]])) {
    .cache[[key]] <- data_load_process_wrapper(iso = iso, disease = disease, R0 = R0, year_end = 2025, ...)
  }
  .cache[[key]]
}

cached_history <- function(iso, disease, R0, ...) {
  key <- paste("history", iso, disease, R0, paste(names(list(...)), unlist(list(...)), collapse = "_"))
  if (is.null(.cache[[key]])) {
    .cache[[key]] <- run_immunity_history(iso, disease, R0 = R0, year_end = 2025, ...)
  }
  .cache[[key]]
}

# Tests that run the model over the whole historical period take a few seconds each. Set
# PREVAIL_SKIP_SLOW_TESTS=true to skip them.
skip_if_slow <- function() {
  testthat::skip_on_cran()
  testthat::skip_if(identical(tolower(Sys.getenv("PREVAIL_SKIP_SLOW_TESTS")), "true"), "slow tests skipped")
}

default_R0 <- c(measles = 15, diphtheria = 3, pertussis = 12)
