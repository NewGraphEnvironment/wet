# Stations in two zones (08, 09) plus a straddling basin, with a known
# adjustment: zone 08 a = 50, b = -0.1; zone 09 a = -20, b = 0.05.
sim <- function(n = 30, seed = 1) {
  set.seed(seed)
  s08 <- c(rep(1, n), rep(0, n), runif(10))
  s09 <- 1 - s08
  p <- runif(length(s08), 400, 2000)
  d <- data.frame(z08 = s08, zp08 = s08 * p, z09 = s09, zp09 = s09 * p, raw = runif(length(s08), 100, 1500))
  d$obs <- d$raw + 50 * d$z08 - 0.1 * d$zp08 - 20 * d$z09 + 0.05 * d$zp09
  d
}

test_that("a known zone-wise adjustment is recovered and reproduced at the stations", {
  d <- sim()
  f <- wet_wb_fit(d)
  expect_equal(f$coef$a[f$coef$zone == "08"], 50)
  expect_equal(f$coef$b[f$coef$zone == "09"], 0.05)
  expect_equal(wet_wb_adjust(f, d, floor = FALSE), d$obs)
  expect_length(f$pooled, 0)
})

test_that("a zone with too few gauges is pooled, decided by the data passed in", {
  d <- sim()
  d$z10 <- 0
  d$zp10 <- 0
  d$z10[1:3] <- 1
  d$z08[1:3] <- 0
  d$zp10[1:3] <- d$zp08[1:3]
  d$zp08[1:3] <- 0
  f <- wet_wb_fit(d, min_gauges = 8)
  expect_equal(f$pooled, "10")
  # the three pooled stations were generated with zone 08's adjustment
  expect_equal(f$coef$a[f$coef$zone == "10"], 50)
  expect_equal(f$coef$b[f$coef$zone == "10"], -0.1)
  # a zone that no station touches has no dominant gauges, so by default it is
  # pooled and takes the "other" coefficients
  d2 <- sim()
  d2$z11 <- 0
  d2$zp11 <- 0
  f2 <- wet_wb_fit(d2, min_gauges = 1)
  expect_equal(f2$pooled, "11")
  expect_false(anyNA(f2$coef))
  # a level fixed from outside with no information in the data gets 0
  f3 <- wet_wb_fit(d2, pooled = character())
  expect_equal(f3$coef$a[f3$coef$zone == "11"], 0)
  expect_equal(f3$coef$b[f3$coef$zone == "11"], 0)
})

test_that("the floor applies to the output only", {
  d <- sim()
  f <- wet_wb_fit(d)
  low <- d[1, ]
  low$raw <- -500
  expect_equal(wet_wb_adjust(f, low), 0)
  expect_lt(wet_wb_adjust(f, low, floor = FALSE), 0)
})

test_that("zones unknown to the fit are refused; zones absent from the data count as 0", {
  f <- wet_wb_fit(sim())
  d <- sim()
  d$z12 <- 0
  d$zp12 <- 0
  expect_error(wet_wb_adjust(f, d), "12")
  none <- data.frame(raw = c(-5, 100))
  expect_equal(wet_wb_adjust(f, none), c(0, 100))
  one <- sim()[, c("z08", "zp08", "raw")]
  expect_equal(wet_wb_adjust(f, one, floor = FALSE), one$raw + 50 * one$z08 - 0.1 * one$zp08)
})

test_that("a pooling structure passed in is used as is", {
  d <- sim()
  expect_equal(wet_wb_pooled(d, min_gauges = 8), character())
  expect_equal(wet_wb_pooled(d, min_gauges = 100), c("08", "09"))
  f <- wet_wb_fit(d, pooled = "09")
  expect_equal(f$pooled, "09")
  # a station with no data is not counted as a gauge of the first zone
  na <- d[1:3, ]
  na[c("z08", "zp08", "z09", "zp09")] <- NA
  expect_equal(wet_wb_pooled(rbind(d, na), min_gauges = 36), wet_wb_pooled(d, min_gauges = 36))
})

test_that("pooled zones get one fitted level, or no adjustment", {
  d <- sim()
  d$z10 <- 0
  d$zp10 <- 0
  d$z10[1:3] <- 1
  d$z08[1:3] <- 0
  d$zp10[1:3] <- d$zp08[1:3]
  d$zp08[1:3] <- 0
  f_none <- wet_wb_fit(d, min_gauges = 8, pooled_adjust = "none")
  expect_equal(f_none$coef$a[f_none$coef$zone == "10"], 0)
  expect_equal(f_none$coef$b[f_none$coef$zone == "10"], 0)
  expect_equal(f_none$coef$a[f_none$coef$zone == "08"], 50)
  f_oth <- wet_wb_fit(d, min_gauges = 8, pooled_adjust = "other")
  expect_equal(f_oth$coef$a[f_oth$coef$zone == "10"], 50)
})
