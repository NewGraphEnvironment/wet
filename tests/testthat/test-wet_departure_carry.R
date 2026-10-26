carry_stations <- function() {
  data.frame(station_number = c("D1", "D2", "D3", "T"), lon = c(-126.6, -127.8, -125.9, -126.5),
             lat = c(54.4, 55.1, 54.0, 54.3), drainage_area_gross_km2 = c(2300, 900, 5000, 360))
}

carry_x <- function(vals, yrs = 1975:2000, variable = "q_mean") {
  do.call(rbind, lapply(names(vals), function(s) {
    data.frame(station_number = s, variable = variable, period = "migration", year = yrs, value = vals[[s]])
  }))
}

# the weights wet_donor_mean() gives the donors, from the same predictor space
carry_weights <- function(st, target, don, k) {
  sp <- wet:::wet_station_space(st)
  w <- drop(wet:::wet_donor_mean(sp[target, , drop = FALSE], sp[don, , drop = FALSE], diag(length(don)), k))
  stats::setNames(w, don)
}

test_that("each donor departs from its own baseline mean, in logs", {
  yrs <- 1975:2000
  f <- ifelse(yrs == 1990, 2, 1)
  x <- carry_x(list(D1 = 10 * f, D2 = 500 * f, D3 = 3 * f), yrs)
  a <- wet_departure_carry(x, carry_stations(), "T", k = 3)
  b <- 1 + 1 / sum(yrs %in% 1981:2010)  # baseline mean relative to a normal year
  expect_equal(a$anomaly[a$year == 1990], log(2 / b))
  expect_equal(a$anomaly[a$year == 1985], log(1 / b))
  expect_equal(a$n_donors, rep(3L, length(yrs)))
})

test_that("a year with only some donors renormalises the weights over those present", {
  set.seed(11)
  yrs <- 1975:2000
  v <- list(D1 = exp(rnorm(26, 2, 0.3)), D2 = exp(rnorm(26, 4, 0.3)), D3 = exp(rnorm(26, 1, 0.3)))
  x <- carry_x(v, yrs)
  x <- x[!(x$station_number == "D2" & x$year == 1995), ]
  st <- carry_stations()
  a <- wet_departure_carry(x, st, "T", k = 3)
  w <- carry_weights(st, "T", c("D1", "D2", "D3"), 3)
  dep <- function(s, y) {
    d <- x[x$station_number == s, ]
    log(d$value[d$year == y] / mean(d$value[d$year %in% 1981:2010]))
  }
  w13 <- w[c("D1", "D3")] / sum(w[c("D1", "D3")])
  expect_equal(a$anomaly[a$year == 1995], sum(w13 * c(dep("D1", 1995), dep("D3", 1995))))
  expect_equal(a$n_donors[a$year == 1995], 2L)
  expect_equal(a$anomaly[a$year == 1996], sum(w * c(dep("D1", 1996), dep("D2", 1996), dep("D3", 1996))))
  expect_false(grepl("D2", a$donors[a$year == 1995]))
})

test_that("a year no donor has is not returned", {
  yrs <- 1975:2000
  x <- carry_x(list(D1 = rep(5, 26), D2 = rep(7, 26)), yrs)
  x <- x[x$year != 1977, ]
  a <- wet_departure_carry(x, carry_stations(), "T", k = 2)
  expect_false(1977 %in% a$year)
  expect_equal(nrow(a), 25)
})

test_that("a target without its own baseline gets an anomaly and no value", {
  yrs <- 1975:2000
  f <- ifelse(yrs == 1990, 1.5, 1)
  x <- carry_x(list(D1 = 10 * f, D2 = 50 * f), yrs)
  x <- rbind(x, data.frame(station_number = "T", variable = "q_mean", period = "migration",
                           year = 1975:1979, value = 4))
  a <- wet_departure_carry(x, carry_stations(), "T", k = 2)
  expect_true(all(is.na(a$value)))
  expect_false(anyNA(a$anomaly))
  # with a baseline of its own, value is its baseline mean carried by the anomaly
  x2 <- rbind(x[x$station_number != "T", ],
              data.frame(station_number = "T", variable = "q_mean", period = "migration", year = 1981:1992,
                         value = 4 * f[yrs %in% 1981:1992]))
  a2 <- wet_departure_carry(x2, carry_stations(), "T", k = 2)
  tm <- mean(4 * f[yrs %in% 1981:1992])
  expect_equal(a2$value, tm * exp(a2$anomaly))
})

test_that("a donor with fewer than 10 baseline years is refused", {
  x <- carry_x(list(D1 = rep(5, 26), D2 = rep(7, 26)))
  x <- x[!(x$station_number == "D2" & x$year %in% 1981:1998), ]
  expect_error(wet_departure_carry(x, carry_stations(), "T", k = 2), "donor D2 has 2 baseline years")
  # one that is not among the k chosen is no obstacle
  w <- carry_weights(carry_stations(), "T", c("D1", "D2"), 2)
  far <- names(which.min(w))
  near <- setdiff(c("D1", "D2"), far)
  x <- carry_x(list(D1 = rep(5, 26), D2 = rep(7, 26)))
  x <- x[!(x$station_number == far & x$year %in% 1981:1998), ]
  expect_no_error(a <- wet_departure_carry(x, carry_stations(), "T", k = 1))
  expect_true(all(startsWith(a$donors, near)))
})

test_that("percent of normal is 100 (exp(anomaly) - 1), and cov_day departs in days", {
  set.seed(12)
  x <- carry_x(list(D1 = exp(rnorm(26, 2, 0.4)), D2 = exp(rnorm(26, 3, 0.4))))
  a <- wet_departure_carry(x, carry_stations(), "T", k = 2)
  expect_equal(a$pct_normal, 100 * (exp(a$anomaly) - 1))
  yrs <- 1975:2000
  x <- carry_x(list(D1 = 40 + (yrs == 1990) * 6, D2 = 30 + (yrs == 1990) * 6), yrs, "q_cov_day")
  a <- wet_departure_carry(x, carry_stations(), "T", k = 2)
  expect_equal(a$anomaly[a$year == 1990], 6 - 6 / 20)  # 20 baseline years in 1981-2000
  expect_true(all(is.na(a$pct_normal)))
})

test_that("the donors' weights are wet_donor_mean()'s and sum to 1 each year", {
  set.seed(13)
  x <- carry_x(list(D1 = exp(rnorm(26)), D2 = exp(rnorm(26)), D3 = exp(rnorm(26))))
  st <- carry_stations()
  a <- wet_departure_carry(x, st, "T", k = 3)
  parse_w <- function(s) {
    p <- strsplit(strsplit(s, " ")[[1]], ":")
    stats::setNames(as.numeric(vapply(p, `[`, "", 2)), vapply(p, `[`, "", 1))
  }
  w <- parse_w(a$donors[1])
  expect_equal(sum(w), 1, tolerance = 1e-3)
  expect_equal(w[c("D1", "D2", "D3")], carry_weights(st, "T", c("D1", "D2", "D3"), 3), tolerance = 1e-3)
})

test_that("the covariance options weight donors by how their modelled years move with the target's", {
  yrs <- 1951:2000
  set.seed(3)
  sig <- rnorm(length(yrs))
  # observed: a wet 1990, twice normal at D1 and D2 and three times at D3
  f <- function(k) ifelse(yrs == 1990, k, 1)
  x <- carry_x(list(D1 = 10 * f(2), D2 = 500 * f(2), D3 = 3 * f(3)), yrs)
  # modelled: D1 and the target move together, D2 against, D3 unrelated
  m <- carry_x(list(T = exp(sig), D1 = exp(sig + 0.1 * rnorm(length(yrs))), D2 = exp(-sig),
                    D3 = exp(rnorm(length(yrs)))), yrs)
  a <- wet_departure_carry(x, carry_stations(), "T", k = 3, weights = "covariance", modelled = m)
  expect_identical(unique(a$weighting), "covariance")
  expect_match(a$donors[1], "^D1:[0-9.]+:0\\.9[0-9]{2}")
  expect_false(grepl("D2:", a$donors[1]))
  w <- wet:::wet_donor_weights(wet:::wet_station_space(carry_stations()), "T", c("D1", "D2", "D3"), 3,
                               "covariance", m[m$period == "migration", c("station_number", "year", "value")])
  expect_identical(w$weight[["D2"]], 0)
  dep <- c(D1 = log(2 / (1 + 1 / 20)), D2 = log(2 / (1 + 1 / 20)), D3 = log(3 / (1 + 2 / 20)))
  expect_equal(a$anomaly[a$year == 1990], sum(w$weight * dep) / sum(w$weight))
  # the default keeps the shipped output: no r in donors, no weighting column
  d <- wet_departure_carry(x, carry_stations(), "T", k = 3)
  expect_false("weighting" %in% names(d))
  expect_match(d$donors[1], "^[A-Z0-9]+:[0-9.]+( [A-Z0-9]+:[0-9.]+)*$")
  # every modelled donor against the target: fall back to distance, said so
  m2 <- carry_x(list(T = exp(sig), D1 = exp(-sig), D2 = exp(-sig), D3 = exp(-sig)), yrs)
  b <- wet_departure_carry(x, carry_stations(), "T", k = 3, weights = "covariance_pick", modelled = m2)
  expect_identical(unique(b$weighting), "distance")
  expect_equal(b$anomaly, d$anomaly)
})

test_that("modelled is required by, and only by, the covariance options", {
  x <- carry_x(list(D1 = rep(10, 26), D2 = rep(5, 26)))
  m <- carry_x(list(T = exp(1:26 / 10), D1 = exp(1:26 / 10)))
  expect_error(wet_departure_carry(x, carry_stations(), "T", weights = "covariance"), "needs `modelled`")
  expect_error(wet_departure_carry(x, carry_stations(), "T", modelled = m), "only by the covariance")
  expect_error(wet_departure_carry(x, carry_stations(), "T", k = 2, weights = "covariance", modelled = m),
               "no rows for: D2")
  expect_error(wet_departure_carry(x, carry_stations(), "T", weights = "covariance", modelled = rbind(m, m)),
               "more than one value")
})
