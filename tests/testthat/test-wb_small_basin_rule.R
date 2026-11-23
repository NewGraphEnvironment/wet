# The small-basin diagnosis's verdicts (#176, scripts/wb_small_basin_rule.R). scripts/ is not in
# the installed package, so these run from the source tree only.
local_rule <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "wb_small_basin_rule.R"), envir = e)
  e
}
split_of <- function(contrast, n_small = 5, n_large = 5) {
  data.frame(class = paste0("c", seq_along(contrast)), n_small = n_small, n_large = n_large,
             contrast = contrast)
}

test_that("check A reads general only when two thirds of each split's readable classes reach +10", {
  r <- local_rule()
  # exactly +10 reaches; exactly two thirds is enough
  x <- r$sb_reading_contrast(list(zone = split_of(c(10, 12, 9.99)), elev = split_of(c(10, 10, 10))))
  expect_equal(x$reading, "general")
  expect_equal(x$per$share, c(2 / 3, 1))
  expect_equal(x$per$below, c("c3", ""))
  # one split under two thirds makes it concentrated, naming the classes below
  x <- r$sb_reading_contrast(list(zone = split_of(c(10, 9.99, 9.99)), elev = split_of(c(20, 20, 20))))
  expect_equal(x$reading, "concentrated")
  expect_equal(x$per$below[1], "c2, c3")
})

test_that("check A ignores classes with fewer than 5 gauges on either side", {
  r <- local_rule()
  d <- split_of(c(20, 20, -30, -30), n_small = c(5, 5, 4, 9), n_large = c(5, 5, 9, 4))
  x <- r$sb_reading_contrast(list(zone = d))
  expect_equal(x$per$readable, 2)
  expect_equal(x$reading, "general")
  # an unreadable class may have no contrast; a readable one may not
  d$contrast[3] <- NA
  expect_equal(r$sb_reading_contrast(list(zone = d))$reading, "general")
  d$contrast[1] <- NA
  expect_error(r$sb_reading_contrast(list(zone = d)), "readable class with no contrast")
  # a split with no readable class is unreadable, not general
  x <- r$sb_reading_contrast(list(zone = split_of(c(20, 20)), elev = split_of(c(20, 20), n_small = 4)))
  expect_equal(x$reading, "unreadable")
  # NA counts are not readable
  x <- r$sb_reading_contrast(list(zone = split_of(c(20, 20), n_small = c(NA, 5))))
  expect_equal(x$per$readable, 1)
})

test_that("check A refuses malformed splits", {
  r <- local_rule()
  expect_error(r$sb_reading_contrast(list()), "named, non-empty")
  expect_error(r$sb_reading_contrast(list(split_of(20))), "named, non-empty")
  expect_error(r$sb_reading_contrast(list(zone = data.frame(class = "a"))), "needs class")
})

test_that("check B passes only when all three tests hold, the boundaries inside", {
  r <- local_rule()
  pass <- r$sb_verdict_traits(5, c(-5, 5), c(20, 17), c(15, 16))
  expect_equal(pass$verdict, "traits explain the small-basin error")
  expect_true(all(pass$tests))
  expect_false(pass$crosses)
  expect_equal(r$sb_verdict_traits(-5, c(-5, 4), c(20, 17), c(15, 16))$verdict,
               "traits explain the small-basin error")
  # just outside each threshold
  expect_equal(r$sb_verdict_traits(5.01, c(5.01, 6), c(20, 17), c(15, 16))$verdict, "not explained")
  expect_equal(r$sb_verdict_traits(0, c(-1, 1), c(20, 17.01), c(15, 16))$verdict, "not explained")
  expect_equal(r$sb_verdict_traits(0, c(-1, 1), c(20, 17), c(15, 16.01))$verdict, "not explained")
})

test_that("check B is undecided when the interval crosses +/-5, unless tests 2 or 3 fail", {
  r <- local_rule()
  x <- r$sb_verdict_traits(4, c(2, 5.5), c(20, 10), c(15, 15))
  expect_equal(x$verdict, "undecided")
  expect_true(x$crosses)
  expect_equal(r$sb_verdict_traits(-4, c(-5.5, -2), c(20, 10), c(15, 15))$verdict, "undecided")
  # a median outside with an interval reaching inside is undecided too
  expect_equal(r$sb_verdict_traits(6, c(4, 8), c(20, 10), c(15, 15))$verdict, "undecided")
  # an interval wholly outside decides
  expect_equal(r$sb_verdict_traits(8, c(5.01, 11), c(20, 10), c(15, 15))$verdict, "not explained")
  # a failed gain or cost decides whatever the interval
  expect_equal(r$sb_verdict_traits(4, c(2, 5.5), c(20, 18), c(15, 15))$verdict, "not explained")
  expect_equal(r$sb_verdict_traits(4, c(2, 5.5), c(20, 10), c(15, 17))$verdict, "not explained")
})

test_that("check B refuses missing or malformed numbers", {
  r <- local_rule()
  expect_error(r$sb_verdict_traits(NA, c(-1, 1), c(20, 10), c(15, 15)), "finite")
  expect_error(r$sb_verdict_traits(0, c(-1, NaN), c(20, 10), c(15, 15)), "finite")
  expect_error(r$sb_verdict_traits(0, 1, c(20, 10), c(15, 15)), "two-number interval")
  expect_error(r$sb_verdict_traits(0, c(-1, 1), c(20, 10), numeric(0)), "two pairs")
  expect_error(r$sb_verdict_traits(0, c(1, -1), c(20, 10), c(15, 15)), "lower bound")
})

test_that("the attribution names a term only where check C names it", {
  r <- local_rule()
  expect_equal(r$sb_attribution("P side (ours)"), "ours, P")
  expect_equal(r$sb_attribution("AET side (ours)"), "ours, AET")
  expect_equal(r$sb_attribution("P side, shared (ours and theirs)"), "ours and theirs, P")
  expect_equal(r$sb_attribution("no material gap"), "unresolved (check C: no material gap)")
  expect_equal(r$sb_attribution("unresolved: P by decomposition, not corroborated"),
               "unresolved (check C: unresolved: P by decomposition, not corroborated)")
  expect_error(r$sb_attribution(NA_character_), "one string")
  expect_error(r$sb_attribution(c("a", "b")), "one string")
  expect_error(r$sb_attribution(""), "one string")
})
