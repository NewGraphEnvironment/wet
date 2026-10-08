gsdd_series <- function(station = "08AA001", from = "2019-01-01", to = "2020-12-31") {
  date <- seq(as.Date(from), as.Date(to), by = "day")
  doy <- as.integer(format(date, "%j"))
  data.frame(station_number = station, date = date,
             t_mean_c = pmax(0, 6 + 9 * sin(2 * pi * (doy - 110) / 365)))
}

test_that("one value per station-year in wet_window_stats()'s long format", {
  skip_if_not_installed("gsdd")
  x <- rbind(gsdd_series(), gsdd_series("08AA002"))
  g <- wet_temp_gsdd(x)
  expect_named(g, c("station_number", "variable", "period", "year", "value", "anomaly_type",
                    "unit", "n_days", "frac_ice", "frac_provisional", "frac_filled"))
  expect_equal(g$station_number, rep(c("08AA001", "08AA002"), each = 2))
  expect_equal(g$year, rep(2019:2020, 2))
  expect_true(all(g$variable == "gsdd" & g$period == "growing_season"))
  expect_true(all(g$anomaly_type == "absolute" & g$unit == "degC_day"))
  expect_true(all(is.na(g$frac_filled) & is.na(g$frac_provisional) & is.na(g$frac_ice)))
  expect_equal(g$n_days, rep(275L, 4))
  # the columns of wet_window_stats(), in its order, then frac_filled
  w <- wet_window_stats(x, data.frame(window = "a", start = "03-01", end = "11-30"), stats = "mean",
                        value = "t_mean_c", prefix = "t", level_anomaly = "absolute", unit = "degC")
  expect_equal(names(g), c(names(w), "frac_filled"))
  # the same numbers gsdd gives on one series
  ref <- gsdd::gsdd(data.frame(date = x$date[1:731], temperature = x$t_mean_c[1:731]), msgs = FALSE)
  expect_equal(g$value[1:2], ref$gsdd)
  expect_true(all(g$value > 1000))
})

test_that("a season cut by days absent from x is NA, not low", {
  skip_if_not_installed("gsdd")
  x <- gsdd_series()
  gap <- x$date >= as.Date("2020-07-01") & x$date <= as.Date("2020-07-07")
  g <- wet_temp_gsdd(x[!gap, ])
  expect_false(is.na(g$value[g$year == 2019]))
  expect_true(is.na(g$value[g$year == 2020]))
  # the same gap as NA values, rather than absent rows
  y <- x
  y$t_mean_c[gap] <- NA
  expect_equal(wet_temp_gsdd(y)$value, g$value)
})

test_that("frac_filled and frac_provisional are shares of the season window", {
  skip_if_not_installed("gsdd")
  x <- gsdd_series()
  x$filled <- x$date >= as.Date("2020-07-01") & x$date <= as.Date("2020-07-30")
  x$status <- ifelse(x$filled | x$date >= as.Date("2020-11-01"), "provisional", "approved")
  g <- wet_temp_gsdd(x)
  window <- as.integer(as.Date("2020-11-30") - as.Date("2020-03-01")) + 1
  expect_equal(g$frac_filled, c(0, 30 / window))
  expect_equal(g$frac_provisional, c(0, 60 / window))
})

test_that("rows with no date are dropped, and a window may end on 29 February", {
  skip_if_not_installed("gsdd")
  x <- gsdd_series(from = "2018-01-01", to = "2021-12-31")
  x$date[c(5, 9)] <- NA
  g <- wet_temp_gsdd(x)
  expect_equal(g$year, 2018:2021)
  w <- wet_temp_gsdd(x, start_date = as.Date("1971-09-01"), end_date = as.Date("1972-02-29"))
  ref <- gsdd::gsdd(data.frame(date = x$date[!is.na(x$date)], temperature = x$t_mean_c[!is.na(x$date)]),
                    start_date = as.Date("1971-09-01"), end_date = as.Date("1972-02-29"), msgs = FALSE)
  expect_equal(w$year, as.integer(ref$year))
  # Sep 1 to the end of February: 181 days, 182 when February has 29
  leap <- (w$year + 1) %% 4 == 0
  # (the first window starts before the data, the last runs past them)
  k <- w$year >= 2018 & w$year < 2021
  expect_equal(w$n_days[k], ifelse(leap, 182L, 181L)[k])
})

test_that("arguments reach gsdd::gsdd()", {
  skip_if_not_installed("gsdd")
  x <- gsdd_series()
  expect_lt(wet_temp_gsdd(x, start_temp = 8, end_temp = 7)$value[1], wet_temp_gsdd(x)$value[1])
})

test_that("bad input is refused, and an empty result keeps its columns", {
  skip_if_not_installed("gsdd")
  x <- gsdd_series()
  expect_error(wet_temp_gsdd(x[, -3]), "t_mean_c")
  expect_error(wet_temp_gsdd(rbind(x, x[1, ])), "duplicate")
  x$date <- as.character(x$date)
  expect_error(wet_temp_gsdd(x), "Date")
  e <- wet_temp_gsdd(gsdd_series()[0, ])
  expect_equal(nrow(e), 0)
  expect_named(e, c("station_number", "variable", "period", "year", "value", "anomaly_type",
                    "unit", "n_days", "frac_ice", "frac_provisional", "frac_filled"))
})

test_that("a seasonal logger filled over the growing season has a GSDD", {
  skip_if_not_installed("gsdd")
  s <- sim_temp_fill(sim_pars(b = c(1, 1, 1)))
  # 08AA001 is in the water May to October only; its peers all year
  m <- as.integer(format(s$temp$date, "%m"))
  keep <- s$temp$station_number != "08AA001" | (m >= 5 & m <= 10)
  obs <- s$temp[keep, ]
  expect_true(all(is.na(wet_temp_gsdd(obs[obs$station_number == "08AA001", ])$value)))
  f <- wet_temp_fill(obs, s$air, from = "2018-01-01", to = "2020-12-31")
  g <- wet_temp_gsdd(f[f$station_number == "08AA001", ])
  truth <- wet_temp_gsdd(s$temp[s$temp$station_number == "08AA001", ])
  expect_false(anyNA(g$value))
  expect_equal(g$value, truth$value, tolerance = 0.1)
  expect_true(all(g$frac_filled > 0.2))
})
