# Five donors on a line east of the target, equal drainage area, so distance
# order is D1 < D2 < ... ; the target's modelled series and each donor's
# chosen so their correlations are known.
dw_case <- function(n_years = 40) {
  st <- data.frame(station_number = c("T", paste0("D", 1:5)), lon = -127 + c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
                   lat = 54, drainage_area_gross_km2 = 100)
  space <- wet_station_space(st)
  yrs <- 1951:(1950 + n_years)
  set.seed(1)
  base <- rnorm(n_years)
  noise <- matrix(rnorm(n_years * 5), n_years)
  # D1 unrelated, D2 opposite, D3 close, D4 identical, D5 moderate
  sig <- cbind(noise[, 1], -base, base + 0.3 * noise[, 3], base, base + noise[, 5])
  m <- data.frame(station_number = rep(c("T", paste0("D", 1:5)), each = n_years), year = rep(yrs, 6),
                  value = exp(c(base, sig)))
  list(space = space, donors = paste0("D", 1:5), m = m)
}

test_that("distance is wet_donor_mean()'s weighting, with no r", {
  x <- dw_case()
  w <- wet_donor_weights(x$space, "T", x$donors, 3, "distance")
  ref <- drop(wet_donor_mean(x$space["T", , drop = FALSE], x$space[x$donors, ], diag(5), 3))
  expect_identical(unname(w$weight), ref)
  expect_true(all(is.na(w$r)))
  expect_false(w$fallback)
})

test_that("covariance scales the k nearest's weights by max(r, 0)", {
  x <- dw_case()
  w <- wet_donor_weights(x$space, "T", x$donors, 3, "covariance", x$m)
  d <- wet_donor_weights(x$space, "T", x$donors, 3, "distance")
  expect_equal(w$weight[["D2"]], 0)  # r < 0
  expect_true(w$r[["D2"]] < -0.9)
  expect_equal(w$weight[["D3"]], d$weight[["D3"]] * w$r[["D3"]])
  expect_equal(w$weight[c("D4", "D5")], c(D4 = 0, D5 = 0))  # not among the 3 nearest
  expect_true(all(is.na(w$r[c("D4", "D5")])))
})

test_that("covariance_pick takes the highest r among the nearest, weighted by r alone", {
  x <- dw_case()
  w <- wet_donor_weights(x$space, "T", x$donors, 2, "covariance_pick", x$m)
  expect_identical(names(which(w$weight > 0)), c("D3", "D4"))
  expect_equal(w$weight[["D4"]], 1)
  expect_equal(w$weight[["D3"]], w$r[["D3"]])
  # n_pick limits the search to the nearest
  w3 <- wet_donor_weights(x$space, "T", x$donors, 2, "covariance_pick", x$m, n_pick = 3)
  expect_identical(w3$weight[["D4"]], 0)
  expect_true(w3$weight[["D3"]] > 0)
  # a tie in r goes to the nearer
  m <- x$m
  m$value[m$station_number == "D5"] <- m$value[m$station_number == "D4"]
  wt <- wet_donor_weights(x$space, "T", x$donors, 1, "covariance_pick", m)
  expect_identical(names(which(wt$weight > 0)), "D4")
})

test_that("an r on too few years, or undefined, counts as 0", {
  x <- dw_case(n_years = 29)
  w <- wet_donor_weights(x$space, "T", x$donors, 5, "covariance", x$m)
  expect_true(all(w$r == 0))
  x <- dw_case()
  m <- x$m
  m$value[m$station_number == "D3"] <- 2  # constant: r is NA
  w <- wet_donor_weights(x$space, "T", x$donors, 5, "covariance", m)
  expect_identical(w$r[["D3"]], 0)
  # a value <= 0 is dropped from a log statistic, and a cov_day series is used as days
  m$value[m$station_number == "D4" & m$year < 1956] <- 0
  w <- wet_donor_weights(x$space, "T", x$donors, 5, "covariance", m)
  expect_equal(w$r[["D4"]], 1)
  expect_lt(wet_donor_weights(x$space, "T", x$donors, 5, "covariance", m, days = TRUE)$r[["D4"]], 0.99)
  # dropping 11 years leaves 29 in common, under the 30 an r needs
  m$value[m$station_number == "D4" & m$year < 1962] <- 0
  expect_identical(wet_donor_weights(x$space, "T", x$donors, 5, "covariance", m)$r[["D4"]], 0)
})

test_that("where every chosen donor weighs 0 it falls back to distance, flagged", {
  x <- dw_case()
  m <- x$m
  m$value[m$station_number != "T"] <- 1 / m$value[m$station_number == "T"]  # every r = -1
  d <- wet_donor_weights(x$space, "T", x$donors, 3, "distance")
  for (meth in c("covariance", "covariance_pick")) {
    w <- wet_donor_weights(x$space, "T", x$donors, 3, meth, m)
    expect_true(w$fallback)
    expect_identical(w$weight, d$weight)
  }
})

test_that("a target or donor missing from modelled is refused", {
  x <- dw_case()
  expect_error(wet_donor_weights(x$space, "T", x$donors, 3, "covariance", x$m[x$m$station_number != "D2", ]),
               "no rows for: D2")
  expect_error(wet_donor_weights(x$space, "T", x$donors, 3, "covariance_pick", x$m[x$m$station_number != "T", ]),
               "no rows for: T")
})
