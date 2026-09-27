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
