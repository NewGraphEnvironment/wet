# #243's rule (scripts/runoff_products_rule.R), registered before
# scripts/runoff_products_compare.R or any product value existed. scripts/ is
# not shipped, so these run under devtools::test() only.
rp_env <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "runoff_products_rule.R"), envir = e)
  e
}

test_that("rp_error is modelled over observed, in %", {
  e <- rp_env()
  expect_equal(e$rp_error(c(120, 80, 100), c(100, 100, 100)), c(20, -20, 0))
  expect_error(e$rp_error(1, 0))
  expect_error(e$rp_error(1:2, 1))
})

test_that("rp_verdict reaches each branch", {
  e <- rp_env()
  bal_in <- c(-5, 0, 5, 2, -3)       # median 0
  bal_out <- c(40, 45, 50, 55, 60)   # median 50
  expect_equal(e$rp_verdict(c(40, 45, 50, 55, 60), bal_in), "theirs")
  expect_equal(e$rp_verdict(c(-40, -45, -50, -55, -60), bal_in), "theirs")
  expect_equal(e$rp_verdict(bal_in, bal_out), "ours")
  expect_equal(e$rp_verdict(-bal_out, bal_out), "unresolved")     # +50 against -50
  expect_equal(e$rp_verdict(c(52, 55, 60, 65, 70), bal_out), "not material")  # both off, 10 apart
  expect_equal(e$rp_verdict(c(-19, -18, -18, -17, -19), c(19, 18, 18, 17, 19)),
               "not material")      # 36 points apart, both inside
  expect_equal(e$rp_verdict(c(40, 45, 50, 55), bal_in[1:4]), "too few")
  expect_equal(e$rp_verdict(c(40, 45, 50, 55), bal_in[1:4], check_n = FALSE), "theirs")
})

test_that("the boundaries: exactly 20 % is within, exactly 20 points is not material", {
  e <- rp_env()
  zero <- rep(0, 5)
  # product at exactly +20 %: within, so both inside
  expect_equal(e$rp_verdict(rep(20, 5), rep(-10, 5)), "not material")
  # 30 points apart, product just outside: theirs
  expect_equal(e$rp_verdict(rep(20.5, 5), rep(-9.5, 5)), "theirs")
  # exactly 20 points apart, product outside and balance inside: not material
  expect_equal(e$rp_verdict(rep(30, 5), rep(10, 5)), "not material")
  expect_equal(e$rp_verdict(rep(30.01, 5), rep(10, 5)), "theirs")
  expect_equal(e$rp_verdict(rep(-30.01, 5), rep(-10, 5)), "theirs")
  expect_equal(e$rp_verdict(rep(21, 5), zero), "theirs")
  expect_equal(e$rp_verdict(zero, rep(21, 5)), "ours")
})

test_that("the period test turns a theirs into unresolved (period) only when the ratio brings it inside", {
  e <- rp_env()
  p <- c(40, 45, 50, 55, 60)
  b <- rep(0, 5)
  expect_equal(e$rp_verdict(p, b, err_period = p - 35), "unresolved (period)")   # median 15
  expect_equal(e$rp_verdict(p, b, err_period = p - 20), "theirs")                # median 30
  expect_equal(e$rp_verdict(p, b, err_period = NA), "theirs (period untested)")
  # applies to theirs only
  expect_equal(e$rp_verdict(b, p, err_period = b), "ours")
  expect_equal(e$rp_verdict(-p, p, err_period = rep(0, 5)), "unresolved")
})

test_that("rp_judge marks a verdict one left-out gauge changes as unstable", {
  e <- rp_env()
  b <- rep(0, 5)
  expect_equal(e$rp_judge(c(40, 45, 50, 55, 60), b), "theirs")
  # median 22 with all five; leaving out 25 brings it to 20, exactly the cut
  x <- c(10, 18, 22, 25, 30)
  expect_equal(e$rp_verdict(x, b), "theirs")
  expect_equal(e$rp_judge(x, b), "unstable (theirs)")
  expect_equal(e$rp_judge(c(40, 45), b[1:2]), "too few")
  expect_equal(e$rp_judge(c(40, 45), b[1:2], check_n = FALSE), "theirs")
  # the period values are left out with their gauge
  expect_equal(e$rp_judge(c(40, 45, 50, 55, 60), b, err_period = c(0, 5, 10, 15, 50)),
               "unresolved (period)")
  expect_equal(e$rp_judge(c(40, 45, 50, 55, 60), b, err_period = NA), "theirs (period untested)")
})

test_that("rp_period_ratio needs rp_period_min gauges", {
  e <- rp_env()
  expect_equal(e$rp_period_ratio(c(1.1, 0.9, 1.2)), 1.1)
  expect_true(is.na(e$rp_period_ratio(c(1.1, 0.9))))
  expect_true(is.na(e$rp_period_ratio(c(1.1, NA, 0.9))))
  expect_error(e$rp_period_ratio(c(1, 2, -1)))
})
