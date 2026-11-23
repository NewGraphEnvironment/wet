# The small-basin diagnosis's verdicts (#176), as pure functions: numbers in, a verdict out.
# Sourced by scripts/wb_small_basin.R, whose header registers the rule these implement, and
# tested by tests/testthat/test-wb_small_basin_rule.R. Needs nothing.
#
# Registered in a commit of its own, with that header, before the script computed any check.

sb_min_n <- 5            # a class with fewer gauges on either side is printed, marked and not read
sb_contrast_pts <- 10    # check A: adjusted small-minus-larger median error, points
sb_general_share <- 2 / 3
sb_median_pts <- 5       # check B: the small gauges' median corrected error within +/- this, %
sb_gain_pts <- 3.0       # check B: the small gauges' mean absolute % error falls by at least this
sb_cost_pts <- 1.0       # check B: the larger gauges' mean absolute % error rises by no more (#47, #83)

# Check A's reading. `splits` is a named list, one data frame per split (zone, elevation tercile,
# aridity tercile) with columns `class`, `n_small`, `n_large` and `contrast` (adjusted median
# error at small gauges minus that at larger ones, points). A class is readable when both sides
# hold at least sb_min_n gauges. The contrast is "general" when, in every split, at least two
# thirds of the readable classes reach +sb_contrast_pts; otherwise "concentrated", naming the
# readable classes below it. A split with no readable class makes the reading "unreadable".
sb_reading_contrast <- function(splits) {
  if (!is.list(splits) || !length(splits) || is.null(names(splits)) || any(!nzchar(names(splits)))) {
    stop("splits must be a named, non-empty list of data frames", call. = FALSE)
  }
  per <- lapply(names(splits), function(k) {
    d <- splits[[k]]
    if (!all(c("class", "n_small", "n_large", "contrast") %in% names(d))) {
      stop("split ", k, " needs class, n_small, n_large and contrast", call. = FALSE)
    }
    ok <- !is.na(d$n_small) & !is.na(d$n_large) & d$n_small >= sb_min_n & d$n_large >= sb_min_n
    if (any(ok & !is.finite(d$contrast))) stop("split ", k, " has a readable class with no contrast", call. = FALSE)
    hit <- ok & d$contrast >= sb_contrast_pts
    data.frame(split = k, readable = sum(ok), reach = sum(hit),
               share = if (any(ok)) sum(hit) / sum(ok) else NA_real_,
               below = paste(d$class[ok & !hit], collapse = ", "))
  })
  per <- do.call(rbind, per)
  reading <- if (any(per$readable == 0)) {
    "unreadable"
  } else if (all(per$share >= sb_general_share)) {
    "general"
  } else {
    "concentrated"
  }
  list(reading = reading, per = per)
}

# Check B's verdict. `med_small`: the small gauges' median corrected error (%), with its 90 %
# fold-blocked bootstrap interval `ci` (two numbers); `mae_small` and `mae_large`: mean absolute
# % error at the small and the larger gauges, each c(base, corrected). Tests 2 and 3 decide alone
# when either fails; otherwise an interval that crosses -sb_median_pts or +sb_median_pts reads
# "undecided", and test 1 decides the rest. A bound exactly on +/- sb_median_pts is inside.
sb_verdict_traits <- function(med_small, ci, mae_small, mae_large) {
  x <- c(med_small, ci, mae_small, mae_large)
  if (length(med_small) != 1L || length(ci) != 2L || length(mae_small) != 2L || length(mae_large) != 2L ||
      !all(is.finite(x))) {
    stop("check B needs a finite median, a two-number interval and two pairs of MAEs", call. = FALSE)
  }
  if (ci[1] > ci[2]) stop("the interval's lower bound is above its upper bound", call. = FALSE)
  tests <- c(median = abs(med_small) <= sb_median_pts,
             gain = mae_small[1] - mae_small[2] >= sb_gain_pts,
             cost = mae_large[2] - mae_large[1] <= sb_cost_pts)
  crosses <- (ci[1] < -sb_median_pts && ci[2] >= -sb_median_pts) ||
    (ci[1] <= sb_median_pts && ci[2] > sb_median_pts)
  verdict <- if (!tests[["gain"]] || !tests[["cost"]]) {
    "not explained"
  } else if (crosses) {
    "undecided"
  } else if (tests[["median"]]) {
    "traits explain the small-basin error"
  } else {
    "not explained"
  }
  list(verdict = verdict, tests = tests, crosses = crosses)
}

# The attribution of the raw small-minus-larger contrast, from check C's verdict (#45's rule on
# the small class): a term only where the rule names it with its corroboration.
sb_attribution <- function(c_verdict) {
  if (length(c_verdict) != 1L || is.na(c_verdict) || !nzchar(c_verdict)) {
    stop("check C's verdict must be one string", call. = FALSE)
  }
  switch(c_verdict,
         "P side (ours)" = "ours, P",
         "AET side (ours)" = "ours, AET",
         "P side, shared (ours and theirs)" = "ours and theirs, P",
         paste0("unresolved (check C: ", c_verdict, ")"))
}
