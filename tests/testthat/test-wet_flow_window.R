# The monthly article's from_months() (vignettes/monthly-flow.Rmd, before
# #59), kept here as the oracle the monthly path must reproduce.
from_months <- function(q12, start, end) {
  d <- seq(as.Date(paste0("2001-", start)), as.Date(paste0("2001-", end)), by = "day")
  mean(q12[as.integer(format(d, "%m"))])
}

months_of <- function(q12, id = 1L, src = "pcic_routed", annual = mean(q12)) {
  data.frame(linear_feature_id = as.integer(id), month = 0:12, q_m3s = c(annual, q12), source = src)
}

chinook <- data.frame(window = c("Migration", "Spawning", "Fry migration"),
                      start = c("07-15", "08-20", "03-01"), end = c("09-15", "09-30", "07-15"))

test_that("the monthly path reproduces the article's from_months()", {
  q12 <- c(3.1, 2.8, 3.5, 9.2, 48, 71, 40, 18, 11, 8.5, 6.2, 4)
  q12b <- q12 * 0.7 + 1
  x <- rbind(months_of(q12, 17094080L), months_of(q12b, 17094080L, "wet_balance"))
  out <- wet_flow_window(x, chinook)
  expect_named(out, c("linear_feature_id", "source", "window", "q_m3s", "basis"))
  expect_identical(nrow(out), 6L)
  expect_identical(out$window, rep(chinook$window, 2))
  expect_identical(out$source, rep(c("pcic_routed", "wet_balance"), each = 3))
  expect_identical(out$basis, rep("monthly", 6))
  oracle <- c(vapply(seq_len(3), function(k) from_months(q12, chinook$start[k], chinook$end[k]), 0),
              vapply(seq_len(3), function(k) from_months(q12b, chinook$start[k], chinook$end[k]), 0))
  expect_identical(out$q_m3s, oracle)
})

test_that("a window inside one month is that month's mean, and month 0 is ignored", {
  q12 <- as.numeric(1:12)
  out <- wet_flow_window(months_of(q12, annual = 999), data.frame(window = "mid_may", start = "05-03", end = "05-20"))
  expect_identical(out$q_m3s, 5)
  cal <- wet_flow_window(months_of(q12, annual = 999), wet_windows_calendar()[1:12, ])
  expect_identical(cal$q_m3s, q12)
})

test_that("a window across the new year and one ending on 02-29 count their days", {
  q12 <- as.numeric(1:12)
  w <- data.frame(window = c("xmas", "febend", "winter"), start = c("12-15", "02-10", "12-01"),
                  end = c("01-15", "02-29", "02-29"))
  out <- wet_flow_window(months_of(q12), w)
  expect_equal(out$q_m3s[1], (17 * 12 + 15 * 1) / 32)
  # 10 to 28 February: a common year, as wet_window_stats() takes 02-29 to mean the month's last day
  expect_equal(out$q_m3s[2], 2)
  expect_equal(out$q_m3s[3], (31 * 12 + 31 * 1 + 28 * 2) / 90)
})

test_that("daily input gives basis daily, the mean of the window's days", {
  q <- seq_len(365) / 10
  x <- data.frame(linear_feature_id = 5L, doy = 1:365, q_m3s = q, source = "pcic_routed")
  w <- data.frame(window = c("jan", "xmas", "febend"), start = c("01-01", "12-15", "02-10"),
                  end = c("01-31", "01-15", "02-29"))
  out <- wet_flow_window(x, w)
  expect_identical(out$basis, rep("daily", 3))
  expect_equal(out$q_m3s, c(mean(q[1:31]), mean(q[c(349:365, 1:15)]), mean(q[41:59])))
})

test_that("station months go through `by`, in wet_station_monthly()'s shape", {
  st <- data.frame(station_number = rep(c("08EE013", "08EE003"), each = 13), month = rep(0:12, 2),
                   q_m3s = c(NA, 1:12, NA, 2 * (1:12)), share = 0, n_years = 30L)
  out <- wet_flow_window(st, wet_windows_calendar()[c(3, 13), ], by = "station_number")
  expect_named(out, c("station_number", "window", "q_m3s", "basis"))
  expect_identical(out$station_number, rep(c("08EE013", "08EE003"), each = 2))
  expect_equal(out$q_m3s, c(3, (31 * 12 + 31 + 28 * 2) / 90, 6, 2 * (31 * 12 + 31 + 28 * 2) / 90))
})

test_that("a missing or NA month makes only the windows that touch it NA", {
  x <- months_of(as.numeric(1:12))
  x$q_m3s[x$month == 7] <- NA
  w <- data.frame(window = c("june", "julaug", "aug"), start = c("06-01", "07-20", "08-01"),
                  end = c("06-30", "08-10", "08-31"))
  expect_identical(wet_flow_window(x, w)$q_m3s, c(6, NA, 8))
  # a missing segment from wet_segment_monthly(): all NA
  y <- months_of(rep(NA_real_, 12), annual = NA_real_)
  expect_identical(wet_flow_window(y, w)$q_m3s, rep(NA_real_, 3))
  # a month absent altogether
  expect_identical(wet_flow_window(x[x$month != 8, ], w)$q_m3s, c(6, NA, NA))
})

test_that("ambiguous or malformed input is refused", {
  x <- months_of(as.numeric(1:12))
  w <- wet_windows_calendar()[1, ]
  expect_error(wet_flow_window(cbind(x, doy = 1L), w), "month.*doy|doy.*month")
  expect_error(wet_flow_window(x[c("linear_feature_id", "q_m3s", "source")], w), "month.*doy|doy.*month")
  expect_error(wet_flow_window(rbind(x, x), w), "duplicate")
  expect_error(wet_flow_window(x, w, by = "station_number"), "station_number")
  expect_error(wet_flow_window(transform(x, month = month + 1L), w), "month")
  expect_error(wet_flow_window(x, data.frame(window = "a", start = "02-29", end = "03-10")), "02-29")
  expect_error(wet_flow_window(x, data.frame(window = "a", start = "13-01", end = "03-10")), "MM-DD")
  d <- data.frame(linear_feature_id = 1L, doy = 0:364, q_m3s = 1, source = "s")
  expect_error(wet_flow_window(d, w), "doy")
})

test_that("zero rows give zero rows with the output's columns", {
  x <- months_of(as.numeric(1:12))[0, ]
  out <- wet_flow_window(x, wet_windows_calendar()[1:2, ])
  expect_identical(nrow(out), 0L)
  expect_named(out, c("linear_feature_id", "source", "window", "q_m3s", "basis"))
})
