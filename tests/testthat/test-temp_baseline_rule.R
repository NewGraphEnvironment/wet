# The whole-station temperature baseline's rule (#213, scripts/temp_baseline_rule.R). scripts/
# is not in the installed package, so these run from the source tree only.
local_tb_rule <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "temp_baseline_rule.R"), envir = e)
  e
}
# scores for mean, regression and donor, each c(blocked, leakfree)
tb_scores <- function(mean, regression, donor, ...) {
  x <- list(mean = mean, regression = regression, donor = donor, ...)
  data.frame(candidate = rep(names(x), each = 2), pool = rep(c("blocked", "leakfree"), length(x)),
             gsdd_mae = unlist(x, use.names = FALSE))
}

test_that("the thresholds are the registered ones", {
  r <- local_tb_rule()
  expect_identical(r$tb_close, 50)
  expect_identical(r$tb_displace, 10)
  expect_identical(r$tb_pools, c("blocked", "leakfree"))
  expect_identical(r$tb_trait, c("regression", "donor"))
})

test_that("the population mean is the baseline unless a trait candidate beats it by 10 in both pools", {
  r <- local_tb_rule()
  # nobody reaches 10
  v <- r$tb_verdict(tb_scores(c(200, 200), c(191, 180), c(195, 195)), 100)
  expect_equal(v$baseline, "mean")
  expect_equal(unname(v$beats), c(FALSE, FALSE))
  # 10 in one pool only does not displace, in either order
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(150, 190.5), c(200, 200)), 100)$baseline, "mean")
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(190.5, 150), c(200, 200)), 100)$baseline, "mean")
  # exactly 10 in both displaces
  v <- r$tb_verdict(tb_scores(c(200, 200), c(190, 190), c(195, 195)), 100)
  expect_equal(v$baseline, "regression")
  expect_equal(v$beats, c(regression = TRUE, donor = FALSE))
  expect_equal(v$gain["regression", ], c(blocked = 10, leakfree = 10))
  # the donor alone
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(195, 150), c(180, 185)), 100)$baseline, "donor")
})

test_that("when both displace, the lower leak-free score wins and regression takes a tie", {
  r <- local_tb_rule()
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(150, 160), c(120, 159)), 100)$baseline, "donor")
  # the blocked score does not pick between them
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(180, 150), c(120, 151)), 100)$baseline, "regression")
  # equal at the report's one decimal is a tie, which regression takes
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(150, 160.04), c(120, 159.96)), 100)$baseline, "regression")
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(150, 160.1), c(120, 160.0)), 100)$baseline, "donor")
})

test_that("close needs the baseline within 50 of the benchmark in both pools", {
  r <- local_tb_rule()
  v <- r$tb_verdict(tb_scores(c(150, 150), c(149, 149), c(149, 149)), 100)
  expect_equal(v$baseline, "mean")
  expect_true(v$is_close)
  expect_equal(v$close, "close")
  expect_equal(v$gap["mean", ], c(blocked = 50, leakfree = 50))
  expect_equal(v$rel_gap["mean", ], c(blocked = 0.5, leakfree = 0.5))
  # just outside in one pool
  v <- r$tb_verdict(tb_scores(c(150, 150.5), c(149, 149), c(149, 149)), 100)
  expect_false(v$is_close)
  expect_match(v$close, "not close \\(within 50 in the blocked pool only\\)")
  v <- r$tb_verdict(tb_scores(c(151, 149), c(149, 149), c(149, 149)), 100)
  expect_match(v$close, "leakfree pool only")
  # outside in both
  v <- r$tb_verdict(tb_scores(c(151, 160), c(149, 149), c(149, 149)), 100)
  expect_equal(v$close, "not close")
  # it is the baseline's gap that is read, not the best candidate's
  v <- r$tb_verdict(tb_scores(c(160, 160), c(151, 100), c(155, 155)), 100)
  expect_equal(v$baseline, "mean")
  expect_false(v$is_close)
  v <- r$tb_verdict(tb_scores(c(170, 170), c(150, 150), c(165, 165)), 100)
  expect_equal(v$baseline, "regression")
  expect_true(v$is_close)
})

test_that("a later candidate is reported beside the baseline and never becomes it", {
  r <- local_tb_rule()
  v <- r$tb_verdict(tb_scores(c(200, 200), c(195, 195), c(195, 195), kriging = c(100, 100)), 100)
  expect_equal(v$baseline, "mean")
  expect_equal(v$other, "kriging")
  expect_equal(v$gap["kriging", ], c(blocked = 0, leakfree = 0))
  expect_false(v$is_close)
})

test_that("the verdict's words carry the baseline, each candidate's gain and the gap", {
  r <- local_tb_rule()
  v <- r$tb_verdict(tb_scores(c(200, 200), c(180, 185), c(195, 150)), 120)
  expect_equal(v$text[1], "Baseline: regression")
  expect_equal(v$text[2], paste("  regression beats the population mean by 20.0 (blocked) and 15.0 (leak-free)",
                                "degC-days: displaces it"))
  expect_equal(v$text[3], paste("  donor beats the population mean by 5.0 (blocked) and 50.0 (leak-free)",
                                "degC-days: does not displace it (needs 10 in both)"))
  expect_match(v$text[4], "\\(120.0 degC-days\\): 60.0 blocked \\(50 %\\), 65.0 leak-free \\(54 %\\)")
  expect_equal(v$text[5], "Close (within 50 degC-days in both pools): not close")
  expect_equal(r$tb_verdict(tb_scores(c(200, 200), c(199, 199), c(199, 199)), 100)$text[1],
               "Baseline: the population mean")
})

test_that("incomplete or malformed scores are refused", {
  r <- local_tb_rule()
  ok <- tb_scores(c(200, 200), c(190, 190), c(195, 195))
  expect_error(r$tb_verdict(ok[ok$pool == "blocked", ], 100), "in both pools")
  expect_error(r$tb_verdict(ok[ok$candidate != "donor", ], 100), "in both pools")
  expect_error(r$tb_verdict(ok[0, ], 100), "no rows")
  expect_error(r$tb_verdict(ok[c("candidate", "pool")], 100), "needs candidate, pool and gsdd_mae")
  expect_error(r$tb_verdict(rbind(ok, ok[1, ]), 100), "two scores in one pool")
  bad <- ok
  bad$pool[1] <- "loo"
  expect_error(r$tb_verdict(bad, 100), "pool must be one of")
  bad <- ok
  bad$gsdd_mae[2] <- NA
  expect_error(r$tb_verdict(bad, 100), "finite")
  expect_error(r$tb_verdict(ok, NA_real_), "benchmark")
  expect_error(r$tb_verdict(ok, c(1, 2)), "benchmark")
  # a later candidate scored in one pool only
  extra <- rbind(ok, data.frame(candidate = "kriging", pool = "blocked", gsdd_mae = 100))
  expect_error(r$tb_verdict(extra, 100), "one pool only: kriging")
})
