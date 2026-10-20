sim_share <- function(n = 60, seed = 2) {
  set.seed(seed)
  d <- data.frame(elev = runif(n, 200, 2000), e_km = runif(n, 900, 1800), n_km = runif(n, 400, 1500))
  for (m in 1:12) {
    d[[sprintf("ppt_%02d", m)]] <- runif(n, 20, 200)
    d[[sprintf("tave_%02d", m)]] <- runif(n, -15, 20)
    d[[sprintf("aet_%02d", m)]] <- runif(n, 0, 100)
    # a known linear share, small enough to stay positive
    d[[sprintf("share_%02d", m)]] <- 0.05 + 1e-4 * d[[sprintf("ppt_%02d", m)]] +
      1e-5 * d$elev + 0.001 * m
  }
  d
}

test_that("known linear monthly shares are recovered", {
  d <- sim_share()
  f <- wet_share_fit(d)
  expect_equal(unname(f$coef[7, "ppt"]), 1e-4)
  expect_equal(unname(f$coef[3, "elev"]), 1e-5)
  expect_equal(unname(f$coef[5, "(intercept)"]), 0.05 + 0.005)
})

test_that("predicted shares are non-negative and sum to 1", {
  d <- sim_share()
  f <- wet_share_fit(d)
  p <- wet_share_predict(f, d)
  expect_equal(unname(rowSums(p)), rep(1, nrow(d)))
  # force a negative raw prediction in one month: floored, then renormalised
  f$coef[1, "(intercept)"] <- -10
  p <- wet_share_predict(f, d)
  expect_true(all(p[, 1] == 0))
  expect_equal(unname(rowSums(p)), rep(1, nrow(d)))
  # all months negative: NA, not a division by zero
  f$coef[, "(intercept)"] <- -10
  expect_true(all(is.na(wet_share_predict(f, d[1, ]))))
})

test_that("too few stations or missing predictors are refused", {
  d <- sim_share(5)
  expect_error(wet_share_fit(d), "more than")
  expect_error(wet_share_fit(sim_share()[, -1]), "elev")
})

test_that("snow predictors enter as static columns, with a coefficient per month", {
  d <- sim_share()
  d$snowmelt_doy_50 <- runif(nrow(d), 90, 180)
  d$swe_max <- runif(nrow(d), 0, 900)
  # melt timing moves share into May and out of March
  d$share_05 <- d$share_05 + 2e-4 * d$snowmelt_doy_50
  d$share_03 <- d$share_03 - 1e-4 * d$snowmelt_doy_50 + 1e-5 * d$swe_max
  static <- c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")
  f <- wet_share_fit(d, static = static)
  expect_equal(colnames(f$coef), c("(intercept)", "ppt", "tave", "aet", static))
  expect_equal(unname(f$coef[5, "snowmelt_doy_50"]), 2e-4)
  expect_equal(unname(f$coef[3, "snowmelt_doy_50"]), -1e-4)
  expect_equal(unname(f$coef[3, "swe_max"]), 1e-5)
  expect_equal(unname(f$coef[7, "snowmelt_doy_50"]), 0, tolerance = 1e-8)
  # prediction reads the snow columns named in the fit
  expect_error(wet_share_predict(f, d[setdiff(names(d), "swe_max")]), "undefined columns")
  # a station missing a snow value is left out of the fit, not filled
  d$swe_max[1] <- NA
  expect_equal(wet_share_fit(d, static = static)$n, nrow(d) - 1)
})

# #102: donor and blend methods
sim_donor <- function(n = 40, seed = 3) {
  d <- sim_share(n, seed)
  sh <- as.matrix(d[sprintf("share_%02d", 1:12)])
  d[sprintf("share_%02d", 1:12)] <- sh / rowSums(sh)
  d
}

test_that("the regression is unchanged by #102", {
  d <- sim_share()
  f <- wet_share_fit(d)
  expect_identical(f$method, "regression")
  # what wet_share_predict() computed before #102, written out
  old <- vapply(1:12, function(m) {
    x <- cbind(1, as.matrix(d[c(sprintf("%s_%02d", f$terms, m), f$static)]))
    as.vector(x %*% f$coef[m, ])
  }, numeric(nrow(d)))
  old[old < 0] <- 0
  old <- old / ifelse(rowSums(old) > 0, rowSums(old), NA_real_)
  colnames(old) <- sprintf("share_%02d", 1:12)
  expect_identical(wet_share_predict(f, d), old)
  # a fit stored before #102 carries no method and predicts the same
  f$method <- NULL
  expect_identical(wet_share_predict(f, d), old)
})

test_that("a donor watershed takes the inverse-distance mean of its k nearest stations' shares", {
  d <- sim_donor()
  static <- c("elev", "e_km", "n_km")
  f <- wet_share_fit(d, static = static, method = "donor", k = 3)
  new <- d[1:2, ]
  new$elev <- new$elev + c(50, 0)  # the second is a station itself
  p <- wet_share_predict(f, new)
  sds <- apply(as.matrix(d[static]), 2, sd)
  xs <- sweep(as.matrix(d[static]), 2, sds, "/")
  r <- as.numeric(as.matrix(new[1, static])) / sds
  dist <- sqrt(colSums((t(xs) - r)^2))
  o <- order(dist)[1:3]
  wt <- 1 / (dist[o] + 1e-6 * median(dist))
  sh <- as.matrix(d[sprintf("share_%02d", 1:12)])
  expect_equal(unname(p[1, ]), unname(colSums(sh[o, ] * wt) / sum(wt)))
  # a station at distance 0 takes the whole weight: its own shares
  expect_equal(unname(p[2, ]), unname(sh[2, ]))
  expect_equal(unname(rowSums(p)), c(1, 1))
  expect_identical(colnames(p), sprintf("share_%02d", 1:12))
})

test_that("donor scaling uses the stations' SD, and k is capped at the stations", {
  d <- sim_donor(12)
  f <- wet_share_fit(d, method = "donor", k = 50)
  expect_identical(f$k, 12L)
  expect_equal(f$sd, apply(as.matrix(d[c("elev", "e_km", "n_km")]), 2, sd))
  # k = all stations: every new watershed draws on all of them
  p <- wet_share_predict(f, d[1, ])
  expect_equal(sum(p), 1)
})

test_that("blend is the mean of the regression and donor shares", {
  d <- sim_donor()
  f <- wet_share_fit(d, method = "blend")
  new <- d[5:9, ]
  new$elev <- new$elev * 1.1
  r <- wet_share_predict(wet_share_fit(d), new)
  o <- wet_share_predict(wet_share_fit(d, method = "donor"), new)
  b <- wet_share_predict(f, new)
  expect_equal(b, (r + o) / 2)
  expect_equal(unname(rowSums(b)), rep(1, 5))
  expect_identical(f$n, nrow(d))
})

test_that("every method fits on the same complete stations", {
  d <- sim_donor()
  d$ppt_04[3] <- NA  # a monthly predictor the donor does not use
  ns <- vapply(c("regression", "donor", "blend"), function(m) wet_share_fit(d, method = m)$n, 1L)
  expect_identical(unname(ns), rep(nrow(d) - 1L, 3))
})

test_that("a watershed missing a static predictor gets NA shares from the donor", {
  d <- sim_donor()
  f <- wet_share_fit(d, method = "donor")
  new <- d[1:3, ]
  new$elev[2] <- NA
  p <- wet_share_predict(f, new)
  expect_true(all(is.na(p[2, ])))
  expect_false(anyNA(p[c(1, 3), ]))
})

test_that("bad method, k or constant predictors are refused", {
  d <- sim_donor()
  expect_error(wet_share_fit(d, method = "nearest"), "should be one of")
  expect_error(wet_share_fit(d, method = "donor", k = 0), "`k`")
  expect_error(wet_share_fit(d, method = "donor", k = NA), "`k`")
  d$elev <- 1000
  expect_error(wet_share_fit(d, method = "donor"), "constant: elev")
})
