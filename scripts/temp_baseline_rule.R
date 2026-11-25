# The whole-station temperature baseline's rule (#213), as pure functions: scores in, a verdict
# out. Sourced by scripts/temp_baseline.R, whose header registers the rule these implement, and
# tested by tests/testthat/test-temp_baseline_rule.R. Needs nothing.
#
# Registered in a commit of its own, with that header, before the script computed any real score.
# The thresholds are the owner's (2026-11-25).

tb_close <- 50      # degC-days: the baseline is close when within this of the benchmark
tb_displace <- 10   # degC-days: a trait candidate replaces the population mean when at least this better
tb_pools <- c("blocked", "leakfree")
tb_null <- "mean"
tb_trait <- c("regression", "donor")   # in tie order: the first wins a tie
tb_digits <- 1      # the report's precision; two leak-free scores equal at it are a tie

# `scores`: one row per candidate and pool, with `candidate`, `pool` (tb_pools) and `gsdd_mae`,
# the rule's statistic: the mean over held-out stations of each station's mean absolute GSDD
# error over its truth years, degC-days. It must hold tb_null and both tb_trait candidates in
# both pools; any other candidate (network kriging, #223) is reported beside the baseline and
# never becomes it. `benchmark`: the same statistic for each station run on its own parameters.
#
# The baseline is tb_null unless a trait candidate beats it by at least tb_displace in both
# pools. When both do, the one with the lower leak-free score is the baseline, and tb_trait's
# first on a tie at tb_digits. The baseline is close when its score is within tb_close of the
# benchmark's in both pools; within it in one pool only is reported as that, and is not close.
# A difference exactly on a threshold counts: 10 displaces, 50 is close.
tb_verdict <- function(scores, benchmark) {
  if (!is.data.frame(scores) || !all(c("candidate", "pool", "gsdd_mae") %in% names(scores))) {
    stop("scores needs candidate, pool and gsdd_mae", call. = FALSE)
  }
  if (length(benchmark) != 1L || !is.finite(benchmark) || benchmark < 0) {
    stop("the benchmark must be one finite score", call. = FALSE)
  }
  if (!nrow(scores) || anyNA(scores$candidate) || anyNA(scores$pool)) {
    stop("scores has no rows, or a row with no candidate or pool", call. = FALSE)
  }
  if (!all(scores$pool %in% tb_pools)) stop("pool must be one of: ", paste(tb_pools, collapse = ", "), call. = FALSE)
  if (anyDuplicated(scores[c("candidate", "pool")])) stop("a candidate has two scores in one pool", call. = FALSE)
  if (!all(is.finite(scores$gsdd_mae)) || any(scores$gsdd_mae < 0)) {
    stop("every score must be finite and not negative", call. = FALSE)
  }
  cand <- unique(as.character(scores$candidate))
  s <- matrix(NA_real_, length(cand), length(tb_pools), dimnames = list(cand, tb_pools))
  s[cbind(as.character(scores$candidate), as.character(scores$pool))] <- scores$gsdd_mae
  need <- c(tb_null, tb_trait)
  if (!all(need %in% cand) || anyNA(s[need, ])) {
    stop("scores must hold ", paste(need, collapse = ", "), " in both pools", call. = FALSE)
  }
  if (anyNA(s)) stop("a candidate is scored in one pool only: ", paste(cand[rowSums(is.na(s)) > 0], collapse = ", "),
                     call. = FALSE)

  gain <- matrix(s[tb_null, ], length(tb_trait), length(tb_pools), byrow = TRUE,
                 dimnames = list(tb_trait, tb_pools)) - s[tb_trait, , drop = FALSE]
  beats <- rowSums(gain >= tb_displace) == length(tb_pools)
  baseline <- if (!any(beats)) {
    tb_null
  } else {
    won <- tb_trait[beats]
    lf <- round(s[won, "leakfree"], tb_digits)
    won[order(lf, match(won, tb_trait))][1]
  }
  gap <- s[, tb_pools, drop = FALSE] - benchmark
  within <- gap[baseline, ] <= tb_close
  close <- if (all(within)) {
    "close"
  } else if (any(within)) {
    paste0("not close (within ", tb_close, " in the ", names(within)[within], " pool only)")
  } else {
    "not close"
  }
  list(baseline = baseline, beats = beats, gain = gain, close = close, is_close = all(within),
       gap = gap, rel_gap = if (benchmark > 0) gap / benchmark else gap * NA_real_,
       other = setdiff(cand, need), text = tb_verdict_text(baseline, beats, gain, close, gap, benchmark))
}

# The verdict in the rule's own words, for the report.
tb_verdict_text <- function(baseline, beats, gain, close, gap, benchmark) {
  f <- function(x) formatC(x, format = "f", digits = tb_digits)
  pct <- function(x) {
    if (benchmark > 0) sprintf(" (%s %%)", formatC(100 * x / benchmark, format = "f", digits = 0)) else ""
  }
  per <- vapply(rownames(gain), function(k) {
    sprintf("  %s beats the population mean by %s (blocked) and %s (leak-free) degC-days: %s", k,
            f(gain[k, "blocked"]), f(gain[k, "leakfree"]),
            if (beats[[k]]) "displaces it" else sprintf("does not displace it (needs %d in both)", tb_displace))
  }, character(1), USE.NAMES = FALSE)
  c(sprintf("Baseline: %s", if (baseline == tb_null) "the population mean" else baseline), per,
    sprintf("Gap from the baseline to the own-parameter benchmark (%s degC-days): %s blocked%s, %s leak-free%s",
            f(benchmark), f(gap[baseline, "blocked"]), pct(gap[baseline, "blocked"]),
            f(gap[baseline, "leakfree"]), pct(gap[baseline, "leakfree"])),
    sprintf("Close (within %d degC-days in both pools): %s", tb_close, close))
}
