m <- wet:::wet_doy_month()
n <- wet:::wet_doy_days()
month_sums <- function(w) t(apply(w, 1, function(r) tapply(r, m, sum)))

# gauges whose freshet timing within the year moves with elevation
shape_gauges <- function(n_g = 12, seed = 1) {
  set.seed(seed)
  # elevation sets the shape; the other predictors are independent of it, so a
  # basis regression on all five has full rank
  d <- data.frame(elev = seq(300, 2000, length.out = n_g), e_km = stats::runif(n_g, 0, 800),
                  n_km = stats::runif(n_g, 0, 1200), snowmelt_doy_50 = stats::runif(n_g, 60, 200),
                  swe_max = stats::runif(n_g, 50, 2000))
  q <- t(sapply(d$elev, function(e) stats::dnorm(1:365, 110 + e / 40, 25) + 2e-3))
  list(d = d, q = q, w = wet:::wet_shape_within(q))
}

test_that("within-month weights sum to 1 per month, and an all-zero month falls back to flat", {
  g <- shape_gauges()
  expect_equal(unname(month_sums(g$w)), matrix(1, nrow(g$w), 12))
  expect_false(any(attr(g$w, "flat")))
  x <- g$q
  x[1, m == 2] <- 0
  w <- wet:::wet_shape_within(x)
  expect_equal(unname(w[1, m == 2]), rep(1 / 28, 28))
  expect_true(attr(w, "flat")[1, 2])
  expect_equal(sum(attr(w, "flat")), 1L)
  # a vector is one watershed
  expect_equal(dim(wet:::wet_shape_within(x[1, ])), c(1L, 365L))
  expect_error(wet:::wet_shape_within(x[, 1:10]), "365")
  x[2, 5] <- NA
  expect_error(wet:::wet_shape_within(x), "NA")
})

test_that("flat is 1 / days, and wet_shape_daily() keeps every monthly mean for every candidate", {
  g <- shape_gauges()
  q_month <- t(sapply(seq_len(nrow(g$q)), function(i) tapply(g$q[i, ], m, mean)))
  flat <- wet_shape_flat(nrow(g$q))
  expect_equal(dim(flat), c(nrow(g$q), 365L))
  expect_equal(flat[1, ], unname(1 / n[m]))
  cands <- list(flat = flat, spline = wet_shape_spline(q_month), within = g$w)
  for (nm in names(cands)) {
    daily <- wet_shape_daily(q_month, cands[[nm]])
    expect_equal(dim(daily), c(nrow(q_month), 365L))
    expect_equal(unname(t(apply(daily, 1, function(r) tapply(r, m, mean)))), unname(q_month), tolerance = 1e-12,
                 info = nm)
  }
  # the observed weights give back the observed days exactly
  expect_equal(wet_shape_daily(q_month, g$w), unname(g$q))
  # a single watershed as vectors
  expect_equal(dim(wet_shape_daily(q_month[1, ], g$w[1, ])), c(1L, 365L))
  # weights that do not sum to 1 are refused, as are mismatched rows
  expect_error(wet_shape_daily(q_month, g$w * 1.01), "sum to 1")
  expect_error(wet_shape_daily(q_month[1:2, ], g$w), "one row")
  expect_error(wet_shape_daily(q_month[, 1:11], g$w), "12")
})

test_that("the spline is continuous across the new year, monotone where the months are, and floors at 0", {
  q <- c(2, 2, 3, 8, 20, 15, 6, 3, 2, 3, 3, 2)
  w <- wet_shape_spline(q)
  expect_equal(dim(w), c(1L, 365L))
  expect_equal(unname(month_sums(w)), matrix(1, 1, 12))
  daily <- wet_shape_daily(q, w)[1, ]
  # periodic: the step across 31 December / 1 January is no larger than the steps within the year
  expect_lt(abs(daily[365] - daily[1]), max(abs(diff(daily))))
  # rising into the May peak within April, falling within July
  expect_true(all(diff(daily[m == 4]) > 0))
  expect_true(all(diff(daily[m == 7]) < 0))
  expect_false(any(attr(w, "flat")))
  # where the spline undershoots below 0 it is floored, and the months still sum to 1
  q0 <- c(0, 0, 0, 0, 30, 60, 30, 0, 0, 0, 0, 0)
  w0 <- wet_shape_spline(q0)
  expect_true(any(w0 == 0))
  expect_true(all(w0 >= 0))
  expect_equal(unname(month_sums(w0)), matrix(1, 1, 12))
  expect_equal(dim(attr(w0, "flat")), c(1L, 12L))
  expect_error(wet_shape_spline(c(q[1:11], NA)), "NA")
})

test_that("donor: k = 1 is the nearest gauge, an identical gauge is itself, k is capped", {
  g <- shape_gauges()
  st <- c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")
  f1 <- wet_shape_fit(g$d, g$w, "donor", static = st, k = 1)
  expect_s3_class(f1, "wet_shape_fit")
  expect_equal(f1$k, 1L)
  # a point just beside gauge 4 takes gauge 4's weights
  d_new <- g$d[4, ]
  d_new$elev <- d_new$elev + 1
  expect_equal(wet_shape_predict(f1, d_new)[1, ], unname(g$w[4, ]))
  # at distance 0 the gauge itself takes the whole weight, whatever k
  f5 <- wet_shape_fit(g$d, g$w, "donor", static = st, k = 5)
  w5 <- wet_shape_predict(f5, g$d[7, ])
  expect_equal(w5[1, ], unname(g$w[7, ]))
  expect_false(any(attr(w5, "flat")))
  # between gauges, the weights are a mixture that still sums to 1 per month
  mid <- (g$d[4, ] + g$d[5, ]) / 2
  wm <- wet_shape_predict(f5, mid)
  expect_equal(unname(month_sums(wm)), matrix(1, 1, 12))
  # k above the number of gauges is capped
  expect_equal(wet_shape_fit(g$d, g$w, "donor", static = st, k = 50)$k, nrow(g$d))
  # several rows at once
  expect_equal(dim(wet_shape_predict(f5, g$d)), c(nrow(g$d), 365L))
})

test_that("basis: a rank-6 set is reconstructed, predictors are checked, and a dead month falls back to flat", {
  g <- shape_gauges(n_g = 20)
  st <- c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")
  # weights built from 6 components exactly, with scores linear in the predictors: the
  # components are orthogonal to the months (each month's mean stays 1) and small
  # enough that the ratio to flat stays positive, so w * days is exactly rank 6
  set.seed(2)
  mi <- stats::model.matrix(~ factor(m) - 1)
  raw <- matrix(stats::rnorm(365 * 6), 365)
  raw <- raw - mi %*% solve(crossprod(mi), crossprod(mi, raw))
  basis <- qr.Q(qr(raw))
  x <- cbind(1, scale(as.matrix(g$d[st])))
  co <- matrix(stats::rnorm(ncol(x) * 6), ncol(x)) * 0.02
  y <- 1 + (x %*% co) %*% t(basis)   # ratio to flat, around 1
  expect_true(all(y > 0))
  w <- y / n[m][col(y)]
  expect_equal(unname(month_sums(w)), matrix(1, nrow(w), 12))
  fit <- wet_shape_fit(g$d, w, "basis", static = st, n_comp = 6)
  # six columns of [1, predictors] less the centring leave rank 5: the cap at the rank
  expect_equal(fit$n_comp, 5L)
  expect_equal(as.vector(wet_shape_predict(fit, g$d)), as.vector(w), tolerance = 1e-8)
  # with monthly shares as predictors, they are required at prediction and refused otherwise
  sh <- t(sapply(seq_len(nrow(w)), function(i) tapply(y[i, ], m, sum))) / 365
  fs <- wet_shape_fit(g$d, w, "basis", static = st, n_comp = 4, shares = sh)
  expect_true(fs$uses_shares)
  expect_error(wet_shape_predict(fs, g$d), "shares")
  expect_equal(dim(wet_shape_predict(fs, g$d, shares = sh)), c(nrow(w), 365L))
  expect_error(wet_shape_predict(fit, g$d, shares = sh), "without")
  # a reconstruction below 0 is floored and the months still sum to 1
  far <- g$d[1, ]
  far$elev <- -1e6
  wf <- wet_shape_predict(fit, far)
  expect_equal(unname(month_sums(wf)), matrix(1, 1, 12))
  expect_true(any(wf == 0))
  # a month whose reconstruction is all <= 0 takes flat and is flagged
  dead <- fit
  dead$centre[m == 1] <- -1e6
  wd <- wet_shape_predict(dead, g$d[1, ])
  expect_equal(unname(wd[1, m == 1]), rep(1 / 31, 31))
  expect_equal(unname(attr(wd, "flat")[1, ]), c(TRUE, rep(FALSE, 11)))
  # components are capped at the rank
  expect_lte(wet_shape_fit(g$d, w, "basis", static = st, n_comp = 300)$n_comp, 19L)
})

test_that("fits refuse incomplete input", {
  g <- shape_gauges()
  st <- c("elev", "e_km", "n_km")
  expect_error(wet_shape_fit(g$d, g$w, "donor", static = c(st, "p_yr")), "p_yr")
  d <- g$d
  d$elev[3] <- NA
  expect_error(wet_shape_fit(d, g$w, "donor", static = st), "complete")
  expect_error(wet_shape_fit(g$d[1:5, ], g$w, "donor", static = st), "one row")
  d <- g$d
  d$elev <- 1
  expect_error(wet_shape_fit(d, g$w, "donor", static = st), "constant")
  w <- g$w
  w[2, 2] <- NA
  expect_error(wet_shape_fit(g$d, w, "donor", static = st), "NA")
  expect_error(wet_shape_fit(g$d, g$w, "basis", static = st, shares = matrix(1, 2, 12)), "one complete row")
  fit <- wet_shape_fit(g$d, g$w, "donor", static = st)
  expect_error(wet_shape_predict(fit, g$d[c("elev", "e_km")]), "n_km")
  expect_error(wet_shape_flat(-1), "non-negative")
})

test_that("wet_flow_window() over a calendar month of daily flows equals the monthly path", {
  q <- c(2, 2, 3, 8, 20, 15, 6, 3, 2, 3, 3, 2)
  daily <- wet_shape_daily(q, wet_shape_spline(q))[1, ]
  win <- data.frame(window = c("july", "fry"), start = c("07-01", "07-15"), end = c("07-31", "09-07"))
  from_days <- wet_flow_window(data.frame(doy = 1:365, q_m3s = daily), win, by = character())
  from_months <- wet_flow_window(data.frame(month = 1:12, q_m3s = q), win, by = character())
  expect_equal(from_days$basis, c("daily", "daily"))
  expect_equal(from_days$q_m3s[1], from_months$q_m3s[1])
  # the window that starts mid-month differs: late July runs below July's mean here
  expect_lt(from_days$q_m3s[2], from_months$q_m3s[2])
})

test_that("the donor shape is identical after #102 moved its weighting into wet_donor_mean()", {
  g <- shape_gauges(20)
  st <- c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")
  fit <- wet_shape_fit(g$d[1:15, ], g$w[1:15, ], "donor", static = st, k = 5)
  new <- g$d[c(16:20, 3), ]
  # wet_shape_predict()'s donor branch before #102, written out
  xs <- sweep(as.matrix(new[st]), 2, fit$sd, "/")
  old <- t(apply(xs, 1, function(r) {
    dist <- sqrt(colSums((t(fit$x) - r)^2))
    o <- order(dist)[seq_len(fit$k)]
    dd <- dist[o]
    wt <- if (any(dd == 0)) as.numeric(dd == 0) else 1 / (dd + 1e-6 * stats::median(dist))
    colSums(fit$w[o, , drop = FALSE] * wt) / sum(wt)
  }))
  old <- matrix(old, nrow = nrow(xs), ncol = 365)
  w <- wet_shape_predict(fit, new)
  expect_identical(unclass(w)[seq_len(nrow(w)), ], old)
  expect_identical(dim(w), dim(old))
})
