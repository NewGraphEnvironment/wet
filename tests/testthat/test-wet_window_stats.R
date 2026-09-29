daily <- function(from, to, value = 1, station = "08AA001") {
  date <- seq(as.Date(from), as.Date(to), by = "day")
  data.frame(station_number = station, date = date, q_m3s = rep_len(value, length(date)))
}

win <- function(window, start, end) data.frame(window = window, start = start, end = end)

test_that("the calendar has months and seasons, with seasons not named like cd's", {
  w <- wet_windows_calendar()
  expect_named(w, c("window", "start", "end"))
  expect_equal(w$window, c(tolower(month.abb), "djf", "mam", "jja", "son"))
  expect_equal(w[w$window %in% c("feb", "djf"), "end"], c("02-29", "02-29"))
  expect_equal(w$start[w$window == "djf"], "12-01")
})

test_that("a window crossing 1 January takes the year it starts in", {
  x <- daily("2000-01-01", "2002-12-31")
  s <- wet_window_stats(x, win("djf", "12-01", "02-29"), stats = "mean")
  # 1999 starts before the record and 2002 ends after it
  expect_equal(s$year, c(2000, 2001))
  expect_equal(s$n_days, c(90, 90))
  expect_equal(s$period, c("djf", "djf"))
})

test_that("an end of 02-29 means the end of February, and 02-28 means the 28th", {
  x <- daily("2003-06-01", "2004-12-31")
  w <- rbind(win("a", "12-01", "02-29"), win("b", "11-01", "02-28"))
  s <- wet_window_stats(x, w, stats = "mean")
  expect_equal(s$n_days[s$period == "a"], 91)
  expect_equal(s$n_days[s$period == "b"], 120)
  # a non-leap year the same window is one day shorter
  y <- daily("2004-06-01", "2005-12-31")
  expect_equal(wet_window_stats(y, win("a", "12-01", "02-29"), stats = "mean")$n_days, 90)
})

test_that("a window starting on 29 February, or malformed, is refused", {
  x <- daily("2001-01-01", "2001-12-31")
  expect_error(wet_window_stats(x, win("a", "02-29", "03-10")), "02-29")
  expect_error(wet_window_stats(x, win("a", "2-1", "03-10")), "MM-DD")
  expect_error(wet_window_stats(x, win("a", "02-30", "03-10")), "MM-DD")
  expect_error(wet_window_stats(x, rbind(win("a", "01-01", "01-05"), win("a", "02-01", "02-05"))),
               "unique")
})

test_that("window-years short of min_frac, or running past the record, are dropped", {
  x <- daily("2000-12-01", "2001-02-15")
  x <- x[!(x$date >= as.Date("2001-01-01") & x$date <= as.Date("2001-01-20")), ]
  jan <- win("jan", "01-01", "01-31")
  expect_equal(nrow(wet_window_stats(x, jan, stats = "mean")), 0)
  expect_equal(wet_window_stats(x, jan, stats = "mean", min_frac = 0.3)$n_days, 11)
  # February 2001 ends after the last day, whatever min_frac says
  expect_equal(nrow(wet_window_stats(x, win("feb", "02-01", "02-29"), stats = "mean",
                                     min_frac = 0)), 0)
})

test_that("each statistic matches a hand calculation", {
  x <- daily("2000-12-01", "2001-02-01")
  i <- x$date >= as.Date("2001-01-01") & x$date <= as.Date("2001-01-10")
  x$q_m3s[i] <- 1:10
  s <- wet_window_stats(x, win("w", "01-01", "01-10"), threshold = 3.5)
  v <- stats::setNames(s$value, s$variable)
  expect_equal(unname(v[c("q_mean", "q_min", "q_max", "q_min7", "q_frac_below", "q_cov_day")]),
               c(5.5, 1, 10, 4, 0.3, 7))
})

test_that("min7 runs over calendar days, and cov_day needs a complete window", {
  x <- daily("2000-12-01", "2001-02-01")
  i <- x$date >= as.Date("2001-01-01") & x$date <= as.Date("2001-01-10")
  x$q_m3s[i] <- 1:10
  x <- x[x$date != as.Date("2001-01-02"), ]
  s <- wet_window_stats(x, win("w", "01-01", "01-10"), threshold = 3.5)
  v <- stats::setNames(s$value, s$variable)
  # the only full 7-day runs are 3-9 and 4-10
  expect_equal(unname(v["q_min7"]), 6)
  expect_equal(unname(v["q_frac_below"]), 2 / 9)
  expect_false("q_cov_day" %in% s$variable)
  expect_equal(unique(s$n_days), 9)
})

test_that("a one-day window has no 7-day minimum", {
  x <- daily("2001-01-01", "2001-12-31")
  s <- wet_window_stats(x, win("d", "06-15", "06-15"), stats = c("mean", "min7"))
  expect_equal(s$variable, "q_mean")
  expect_equal(s$n_days, 1)
})

test_that("ice and provisional shares come from symbol and status", {
  x <- daily("2001-01-01", "2001-01-31")
  x$symbol <- ifelse(x$date <= as.Date("2001-01-10"), "B", NA)
  x$status <- ifelse(x$date > as.Date("2001-01-21"), "provisional", "approved")
  s <- wet_window_stats(x, win("jan", "01-01", "01-31"), stats = "mean")
  expect_equal(s$frac_ice, 10 / 31)
  expect_equal(s$frac_provisional, 10 / 31)
  y <- daily("2001-01-01", "2001-01-31")
  s <- wet_window_stats(y, win("jan", "01-01", "01-31"), stats = "mean")
  expect_true(is.na(s$frac_ice) && is.na(s$frac_provisional))
})

test_that("series are kept apart by id, and a threshold can differ per id", {
  x <- rbind(daily("2001-01-01", "2001-01-31", 1, "A"), daily("2001-01-01", "2001-01-31", 5, "B"))
  s <- wet_window_stats(x, win("jan", "01-01", "01-31"), stats = c("mean", "frac_below"),
                        threshold = c(A = 2, B = 2))
  expect_equal(s$station_number, c("A", "A", "B", "B"))
  expect_equal(s$value[s$variable == "q_mean"], c(1, 5))
  expect_equal(s$value[s$variable == "q_frac_below"], c(1, 0))
  expect_error(wet_window_stats(x, win("jan", "01-01", "01-31"), stats = "frac_below",
                                threshold = c(A = 2)), "threshold")
})

test_that("anomaly type and unit follow cd's contract", {
  x <- daily("2001-01-01", "2001-01-31")
  s <- wet_window_stats(x, win("jan", "01-01", "01-31"), threshold = 2)
  m <- unique(s[c("variable", "anomaly_type", "unit")])
  expect_equal(m$anomaly_type[m$variable == "q_mean"], "pct_normal")
  expect_equal(m$unit[m$variable == "q_min7"], "%")
  expect_equal(m$anomaly_type[m$variable == "q_frac_below"], "absolute")
  expect_equal(m$unit[m$variable == "q_cov_day"], "days")
  # a temperature series departs in degrees, not percent
  t <- wet_window_stats(x, win("jan", "01-01", "01-31"), stats = "mean", value = "q_m3s",
                        prefix = "tw", level_anomaly = "absolute", unit = "degC")
  expect_equal(c(t$variable, t$anomaly_type, t$unit), c("tw_mean", "absolute", "degC"))
})

test_that("bad series are refused", {
  x <- daily("2001-01-01", "2001-01-31")
  jan <- win("jan", "01-01", "01-31")
  expect_error(wet_window_stats(rbind(x, x[1, ]), jan), "duplicate")
  expect_error(wet_window_stats(x, jan, stats = "frac_below"), "threshold")
  expect_error(wet_window_stats(x, jan, stats = "median"), "stats")
  expect_error(wet_window_stats(x, jan, value = "nope"), "nope")
  x$date <- as.character(x$date)
  expect_error(wet_window_stats(x, jan), "Date")
})

# cd with #92: variables outside cd_variables() carry their own anomaly type.
skip_if_no_cd92 <- function() {
  skip_if_not_installed("cd")
  skip_if_not_installed("Kendall")
  skip_if_not_installed("zyp")
  x <- data.frame(variable = "zz", period = "p", year = 2000:2001, value = 1:2,
                  anomaly_type = "absolute", unit = "u")
  ok <- tryCatch(!anyNA(cd::cd_anomaly(x, cd::cd_baseline(x, 2000:2001))$anomaly),
                 error = function(e) FALSE)
  if (!ok) skip("cd without the #92 contract")
}

test_that("one station's window statistics go through cd's baseline, anomaly and trend", {
  skip_if_no_cd92()
  date <- seq(as.Date("1990-01-01"), as.Date("2009-12-31"), by = "day")
  yr <- as.numeric(format(date, "%Y"))
  x <- data.frame(station_number = "A", date = date, q_m3s = 10 - 0.2 * (yr - 1990) +
                    sin(as.numeric(format(date, "%j")) / 58))
  # level statistics only: a constant series (frac_below, cov_day here) makes
  # Kendall print a Fortran error, though cd_trend() still returns slope 0, p 1
  s <- wet_window_stats(x, wet_windows_calendar()[c(8, 15), ],
                        stats = c("mean", "min", "max", "min7"))
  s <- s[names(s) != "station_number"]
  b <- cd::cd_baseline(s, 1990:1999)
  a <- cd::cd_anomaly(s, b)
  expect_false(anyNA(a$anomaly))
  expect_equal(unique(a$unit[a$variable == "q_mean"]), "%")
  tr <- cd::cd_trend(a, trend_start = 1990)
  # flow falls every year, so every level statistic trends down
  expect_true(all(tr$slope[tr$variable %in% c("q_mean", "q_min", "q_max", "q_min7")] < 0))
})
