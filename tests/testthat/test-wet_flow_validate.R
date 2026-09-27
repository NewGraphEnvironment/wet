mk <- function(id, ann_obs, ann_mod, mo_obs = rep(ann_obs / 12, 12), mo_mod = rep(ann_mod / 12, 12)) {
  data.frame(station_number = id, month = 0:12, obs = c(ann_obs, mo_obs), mod = c(ann_mod, mo_mod))
}

test_that("annual errors and the Chapman summary metrics", {
  x <- rbind(mk("A", 100, 110), mk("B", 200, 150), mk("C", 400, 400))
  v <- wet_flow_validate(x)
  expect_equal(v$stations$err_pct, c(10, -25, 0))
  expect_equal(v$stations$log_ratio, log(c(1.1, 0.75, 1)))
  s <- v$summary[v$summary$group == "all", ]
  expect_equal(s$n, 3)
  expect_equal(s$mean_err_pct, mean(c(10, -25, 0)))
  expect_equal(s$median_err_pct, 0)
  expect_equal(s$mae_pct, mean(c(10, 25, 0)))
  expect_equal(s$within_20, 2 / 3)
})

test_that("monthly NSE is perfect for a perfect climatology and the shares ignore scale", {
  sh <- c(1, 1, 2, 5, 12, 20, 18, 12, 8, 5, 3, 2)
  x <- mk("A", 890, 1780, mo_obs = sh * 10, mo_mod = sh * 20)
  v <- wet_flow_validate(x)
  expect_equal(v$stations$nse_share, 1)
  expect_lt(v$stations$nse_month, 0)  # doubled volumes: poor on mm, perfect on shares
})

test_that("near-zero runoff is counted, not scored, and bad months give NA", {
  x <- rbind(mk("A", 5, 50), mk("B", 100, 90))
  x$mod[x$station_number == "B" & x$month == 7] <- NA
  v <- wet_flow_validate(x)
  s <- v$summary[v$summary$group == "all", ]
  expect_equal(s$n, 1)
  expect_equal(s$n_low, 1)
  expect_true(is.na(v$stations$err_pct[1]))
  expect_true(is.na(v$stations$nse_month[2]))
  # zero modelled runoff: an error in percent, but no log ratio
  z <- wet_flow_validate(mk("Z", 100, 0))
  expect_equal(z$stations$err_pct, -100)
  expect_true(is.na(z$stations$log_ratio))
})

test_that("group summaries partition the stations", {
  x <- rbind(mk("A", 100, 110), mk("B", 200, 150), mk("C", 400, 400))
  g <- data.frame(station_number = c("A", "B", "C"), nesting = c("headwater", "nested", "headwater"))
  s <- wet_flow_validate(x, g)$summary
  expect_equal(s$n[s$value == "headwater"], 2)
  expect_equal(s$mae_pct[s$value == "nested"], 25)
})

test_that("duplicate rows and bad months are refused", {
  x <- mk("A", 100, 110)
  expect_error(wet_flow_validate(rbind(x, x)), "duplicate")
  x$month[2] <- 13
  expect_error(wet_flow_validate(x), "month")
})

test_that("a missing modelled value is left out and counted, not NA everywhere", {
  x <- rbind(mk("A", 100, 110), mk("B", 200, NA))
  s <- wet_flow_validate(x)$summary
  expect_equal(s$n, 1)
  expect_equal(s$n_no_mod, 1)
  expect_equal(s$mae_pct, 10)
})
