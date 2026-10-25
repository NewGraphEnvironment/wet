ext_stations <- function(ids = c("D1", "D2", "T")) {
  data.frame(station_number = ids, lon = c(-126.6, -127.8, -126.5, -125.9)[seq_along(ids)],
             lat = c(54.4, 55.1, 54.3, 54.0)[seq_along(ids)],
             drainage_area_gross_km2 = c(2300, 900, 360, 5000)[seq_along(ids)])
}

ext_x <- function(d1, d2, ty, tv, variable = "q_mean") {
  yrs <- seq_along(d1) + 1960L
  data.frame(station_number = rep(c("D1", "D2", "T"), c(length(d1), length(d2), length(ty))),
             variable = variable, period = "migration", year = c(yrs, seq_along(d2) + 1960L, ty),
             value = c(d1, d2, tv))
}

test_that("ols recovers an exact log-linear relation and its years", {
  set.seed(2)
  d1 <- exp(rnorm(40, 3, 0.4))
  d2 <- exp(rnorm(40, 3, 0.4))
  ty <- 1971:1975
  x <- ext_x(d1, d2, ty, 0.5 * d1[ty - 1960]^1.2)
  e <- wet_window_extend(x, ext_stations(), "T", method = "ols")
  ex <- e[e$source == "extended", ]
  expect_equal(nrow(ex), 35)
  expect_equal(ex$value, 0.5 * d1[ex$year - 1960]^1.2)
  expect_equal(unique(ex$donor), "D1")
  # an exact fit has a zero-width interval
  expect_equal(ex$lower, ex$value)
  expect_equal(attr(e, "donors")[["q_mean|migration"]], c("D1", "D2"))
})

test_that("move1 keeps the target's variance where ols shrinks it", {
  set.seed(3)
  d1 <- exp(rnorm(40, 3, 0.5))
  d2 <- exp(rnorm(40, 3, 0.5))
  ty <- 1961:1980
  tv <- exp(0.2 + 0.8 * log(d1[ty - 1960]) + rnorm(20, 0, 0.3))
  x <- ext_x(d1, d2, ty, tv)
  sd_ext <- function(m) {
    e <- wet_window_extend(x, ext_stations(), "T", method = m)
    stats::sd(log(e$value[e$source == "extended"]))
  }
  sd_obs <- stats::sd(log(tv))
  sd_don <- stats::sd(log(d1[setdiff(1:40, ty - 1960)]))
  r <- stats::cor(log(d1[ty - 1960]), log(tv))
  # the ratio of the extended to the donor's SD is |r| sd_y / sd_x for ols and sd_y / sd_x for move1
  sx <- stats::sd(log(d1[ty - 1960]))
  expect_equal(sd_ext("move1") / sd_don, sd_obs / sx)
  expect_equal(sd_ext("ols") / sd_don, abs(r) * sd_obs / sx)
  expect_lt(sd_ext("ols"), sd_ext("move1"))
})

test_that("ratio is a ratio of means, not a mean of ratios", {
  d1 <- c(1, 10, 100, rep(20, 7))
  d2 <- rep(5, 10)
  x <- ext_x(d1, d2, 1961:1963, c(2, 10, 50))
  e <- wet_window_extend(x, ext_stations(), "T", method = "ratio")
  r_means <- mean(c(2, 10, 50)) / mean(c(1, 10, 100))
  r_ratios <- mean(c(2, 10, 50) / c(1, 10, 100))
  expect_false(isTRUE(all.equal(r_means, r_ratios)))
  expect_equal(e$value[e$year == 1964], 20 * r_means)
})

test_that("fewer than 3 years in the target or in common is refused", {
  d1 <- exp(rnorm(20, 3))
  x <- ext_x(d1, d1, 1961:1962, c(3, 4))
  expect_error(wet_window_extend(x, ext_stations(), "T"), "at least 3 are needed")
  # a donor with only two of the target's three years cannot be in the chain
  x <- ext_x(d1[1:2], d1[1:2], 1961:1963, c(3, 4, 5))
  expect_error(wet_window_extend(x, ext_stations(), "T"), "no donor has q_mean")
})

test_that("a donor missing one of the target's years is not chosen, even when nearest", {
  set.seed(4)
  d1 <- exp(rnorm(40, 3, 0.3))
  d2 <- exp(rnorm(40, 3, 0.3))
  d1[12] <- NA
  x <- ext_x(d1, d2, 1971:1975, exp(rnorm(5, 2, 0.3)))
  x <- x[!is.na(x$value), ]
  e <- wet_window_extend(x, ext_stations(), "T")
  expect_equal(attr(e, "donors")[["q_mean|migration"]], "D2")
  expect_equal(unique(e$donor[e$source == "extended"]), "D2")
})

test_that("a year the nearest donor lacks comes from the next in the chain", {
  set.seed(5)
  d1 <- exp(rnorm(40, 3, 0.3))
  d2 <- exp(rnorm(40, 3, 0.3))
  x <- ext_x(d1, d2, 1971:1975, exp(rnorm(5, 2, 0.3)))
  x <- x[!(x$station_number == "D1" & x$year < 1966), ]
  e <- wet_window_extend(x, ext_stations(), "T")
  expect_equal(e$donor[e$year < 1966], rep("D2", 5))
  expect_equal(unique(e$donor[e$year >= 1966 & e$source == "extended"]), "D1")
  # k = 1 keeps only the nearest, so its missing years stay missing
  e1 <- wet_window_extend(x, ext_stations(), "T", k = 1)
  expect_false(any(e1$year < 1966))
})

test_that("an observed year is returned as observed, not extended", {
  set.seed(6)
  d1 <- exp(rnorm(40, 3, 0.3))
  ty <- c(1971, 1972, 1975, 1980)
  tv <- exp(rnorm(4, 2, 0.3))
  x <- ext_x(d1, d1 * 1.1, ty, tv)
  e <- wet_window_extend(x, ext_stations(), "T", method = "move1")
  o <- e[e$year %in% ty, ]
  expect_equal(o$source, rep("observed", 4))
  expect_equal(o$value, tv)
  expect_true(all(is.na(o$donor)))
  expect_equal(sum(duplicated(e$year)), 0)
})

test_that("the ols interval's half-width doubles when the residual SD doubles", {
  set.seed(7)
  d1 <- exp(rnorm(40, 3, 0.4))
  ty <- 1961:1970
  noise <- rnorm(10)
  noise <- noise - stats::fitted(stats::lm(noise ~ log(d1[ty - 1960])))
  half <- function(m) {
    x <- ext_x(d1, d1, ty, exp(1 + log(d1[ty - 1960]) + m * 0.1 * noise))
    x <- x[!(x$station_number == "D2"), ]
    e <- wet_window_extend(x, ext_stations(c("D1", "D2", "T")), "T")
    ex <- e[e$source == "extended", ]
    log(ex$upper) - log(ex$value)
  }
  expect_equal(half(2), 2 * half(1))
})

test_that("move1 and ratio take their bounds from resid, or none", {
  set.seed(8)
  d1 <- exp(rnorm(30, 3, 0.3))
  x <- ext_x(d1, d1, 1961:1965, exp(rnorm(5, 2, 0.3)))
  e0 <- wet_window_extend(x, ext_stations(), "T", method = "ratio")
  expect_true(all(is.na(e0$lower[e0$source == "extended"])))
  res <- seq(-0.5, 0.5, length.out = 101)
  e <- wet_window_extend(x, ext_stations(), "T", method = "ratio", resid = res)
  ex <- e[e$source == "extended", ]
  expect_equal(log(ex$upper / ex$value), rep(0.45, nrow(ex)))
  expect_equal(log(ex$lower / ex$value), rep(-0.45, nrow(ex)))
})

test_that("cov_day is related in days, and a value <= 0 leaves a log fit", {
  d1 <- c(30, 40, 50, 35, 45, 38, 42)
  x <- ext_x(d1, d1 + 1, 1961:1963, c(32, 42, 52), variable = "q_cov_day")
  e <- wet_window_extend(x, ext_stations(), "T", method = "ols")
  expect_equal(e$value[e$year == 1964], 37)
  d2 <- exp(rnorm(10, 2))
  x <- ext_x(c(0, d2[-1]), d2, 1961:1964, c(0, 2, 3, 4))
  e <- wet_window_extend(x, ext_stations(), "T")
  expect_false(1961 %in% e$year[e$source == "observed"])
  expect_equal(attr(e, "dropped"), 2L)
})

test_that("a station absent from the station table is refused", {
  d1 <- exp(rnorm(10, 2))
  x <- ext_x(d1, d1, 1961:1963, c(1, 2, 3))
  expect_error(wet_window_extend(x, ext_stations()[1:2, ], "T"), "no row for: T")
})
