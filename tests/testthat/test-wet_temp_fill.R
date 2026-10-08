hide <- function(x, station, from, to) {
  x$station_number == station & x$date >= as.Date(from) & x$date <= as.Date(to)
}

test_that("observed days pass through unchanged and gaps are filled", {
  s <- sim_temp_fill(sim_pars())
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  obs <- s$temp[!gap, ]
  f <- wet_temp_fill(obs, s$air)
  expect_named(f, c(names(obs), "filled", "t_lo_c", "t_hi_c"))
  expect_equal(nrow(f), nrow(s$temp))
  expect_equal(sum(f$filled), sum(gap))
  o <- f[!f$filled, ]
  key <- match(paste(o$station_number, o$date), paste(obs$station_number, obs$date))
  expect_false(anyNA(key))
  expect_equal(o$t_mean_c, obs$t_mean_c[key])
  expect_equal(o$t_lo_c, o$t_mean_c)
  expect_equal(o$t_hi_c, o$t_mean_c)
  fl <- f[f$filled, ]
  expect_true(all(fl$station_number == "08AA001"))
  expect_true(all(is.na(fl$t_min_c) & is.na(fl$t_max_c)))
  expect_true(all(fl$n_hours == 0L))
  expect_true(all(fl$source == "air2stream" & fl$status == "provisional"))
  expect_true(all(fl$t_lo_c <= fl$t_mean_c & fl$t_mean_c <= fl$t_hi_c))
  expect_false(is.unsorted(order(f$station_number, f$date)))
})

test_that("known parameters are recovered and a station that ignores its peers gets b near 0", {
  s <- sim_temp_fill(sim_pars())
  fit <- attr(wet_temp_fill(s$temp, s$air), "fit")
  expect_equal(fit$station_number, sprintf("08AA%03d", 1:4))
  expect_equal(fit$a3, rep(0.18, 4), tolerance = 0.25)
  expect_equal(fit$a2, rep(0.12, 4), tolerance = 0.25)
  # equilibrium at a summer air temperature, the quantity a fill rests on
  eq <- (fit$a1 + fit$a2 * 17) / fit$a3
  expect_equal(eq, rep((0.6 + 0.12 * 17) / 0.18, 4), tolerance = 0.03)
  # tracking stations: b is their loading over the peers' mean loading (2/3)
  expect_true(all(fit$b[1:3] > 1 & fit$b[1:3] < 2))
  expect_lt(abs(fit$b[4]), 0.1)
})

test_that("the shared anomaly makes the fill better than the station alone", {
  s <- sim_temp_fill(sim_pars())
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  truth <- s$temp$t_mean_c[gap]
  rmse <- function(f) sqrt(mean((f$t_mean_c[f$filled] - truth)^2))
  with_peers <- wet_temp_fill(s$temp[!gap, ], s$air)
  alone <- wet_temp_fill(s$temp[!gap & s$temp$station_number == "08AA001", ], s$air)
  expect_equal(attr(alone, "fit")$b, 0)
  expect_lt(rmse(with_peers), 0.8 * rmse(alone))
})

test_that("the fill meets the observation at both ends of a gap", {
  s <- sim_temp_fill(sim_pars(b = 1))
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  f <- wet_temp_fill(s$temp[!gap, ], s$air)
  d <- f$t_mean_c
  i <- which(f$filled)
  # the step into and out of the gap is no larger than a typical day-to-day step
  typical <- stats::quantile(abs(diff(s$temp$t_mean_c)), 0.95)
  expect_lt(abs(d[min(i)] - d[min(i) - 1]), typical)
  expect_lt(abs(d[max(i) + 1] - d[max(i)]), typical)
  # the interval is narrow beside observations and widest mid-gap
  w <- f$t_hi_c[i] - f$t_lo_c[i]
  mid <- w[ceiling(length(w) / 2)]
  expect_lt(w[1], mid)
  expect_lt(w[length(w)], mid)
})

test_that("the interval covers close to its level across gaps and stations", {
  hits <- c()
  for (seed in 1:3) {
    s <- sim_temp_fill(sim_pars(), seed = seed)
    gap <- hide(s$temp, "08AA001", "2019-05-01", "2019-09-30") |
      hide(s$temp, "08AA004", "2020-04-01", "2020-06-30")
    f <- wet_temp_fill(s$temp[!gap, ], s$air)
    tr <- s$temp[gap, ]
    k <- match(paste(tr$station_number, tr$date), paste(f$station_number, f$date))
    hits <- c(hits, tr$t_mean_c >= f$t_lo_c[k] & tr$t_mean_c <= f$t_hi_c[k])
  }
  expect_gt(mean(hits), 0.85)
  expect_lt(mean(hits), 0.995)
})

test_that("a station short of min_days is returned unfilled, with a warning", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  keep <- s$temp$station_number == "08AA001" |
    (s$temp$date >= as.Date("2019-06-01") & s$temp$date <= as.Date("2019-06-30"))
  keep <- keep | (s$temp$date == as.Date("2019-08-01"))
  expect_warning(f <- wet_temp_fill(s$temp[keep, ], s$air), "too few observed days.*08AA002")
  f2 <- f[f$station_number == "08AA002", ]
  expect_equal(nrow(f2), 31)
  expect_false(any(f2$filled))
  expect_equal(attr(f, "fit")$station_number, "08AA001")
})

test_that("days without air temperature are interpolated inside the range, not filled outside it", {
  s <- sim_temp_fill(sim_pars(b = 1))
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-06-30")
  air <- s$air[!(s$air$date >= as.Date("2019-06-10") & s$air$date <= as.Date("2019-06-12")), ]
  # air ends before the water record does
  air <- air[air$date <= as.Date("2020-11-30"), ]
  f <- wet_temp_fill(s$temp[!gap, ], air)
  expect_equal(sum(f$filled), sum(gap))
  expect_false(anyNA(f$t_mean_c))
  late <- f[f$date > as.Date("2020-11-30"), ]
  expect_equal(nrow(late), 31)
  expect_false(any(late$filled))
})

test_that("a long hole in the air leaves the station unfilled, wherever it lies", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  cut_air <- function(lo, hi) {
    s$air[!(s$air$id == "08AA001" & s$air$date >= as.Date(lo) & s$air$date <= as.Date(hi)), ]
  }
  one <- s$temp$station_number == "08AA001"
  start <- s$temp[!gap & (!one | s$temp$date >= as.Date("2018-05-01")), ]
  end <- s$temp[!gap & (!one | s$temp$date <= as.Date("2020-08-01")), ]
  around <- s$temp[!one | format(s$temp$date, "%Y") == "2019", ]
  cases <- list(inside = list(s$temp[!gap, ], cut_air("2019-05-15", "2019-09-15")),
                # the record starts, or ends, inside the hole
                start = list(start, cut_air("2018-03-01", "2018-05-31")),
                end = list(end, cut_air("2020-07-01", "2020-09-30")),
                # the whole record inside the hole
                around = list(around, cut_air("2019-01-01", "2019-12-31")))
  for (k in names(cases)) {
    expect_warning(f <- wet_temp_fill(cases[[k]][[1]], cases[[k]][[2]], min_days = 100),
                   "gap of more than 3 days.*08AA001", info = k)
    expect_false(any(f$filled[f$station_number == "08AA001"]), info = k)
    expect_equal(attr(f, "fit")$station_number, "08AA002", info = k)
  }
  # a hole outside the record does not matter
  later <- s$temp[!one | s$temp$date >= as.Date("2019-01-01"), ]
  expect_no_warning(f <- wet_temp_fill(later, cut_air("2018-03-01", "2018-05-31")))
  expect_true("08AA001" %in% attr(f, "fit")$station_number)
})

test_that("a station that reads a constant value fills without NaN", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  one <- s$temp$station_number == "08AA001"
  s$temp$t_mean_c[one] <- 4
  gap <- hide(s$temp, "08AA001", "2019-07-10", "2019-07-16")
  f <- wet_temp_fill(s$temp[!gap, ], s$air)
  fl <- f[f$filled, ]
  expect_equal(nrow(fl), 7)
  expect_false(anyNA(c(fl$t_mean_c, fl$t_lo_c, fl$t_hi_c)))
  expect_equal(fl$t_mean_c, rep(4, 7), tolerance = 0.01)
})

test_that("the fill is floored at 0 degC", {
  s <- sim_temp_fill(sim_pars(b = 1))
  gap <- hide(s$temp, "08AA001", "2018-12-01", "2019-02-28")
  f <- wet_temp_fill(s$temp[!gap, ], s$air)
  fl <- f[f$filled, ]
  expect_true(all(fl$t_mean_c >= 0 & fl$t_lo_c >= 0))
  expect_lt(mean(fl$t_mean_c), 1)
})

test_that("from and to extend the fill beyond the record", {
  s <- sim_temp_fill(sim_pars(b = 1))
  obs <- s$temp[s$temp$date >= as.Date("2018-06-01"), ]
  f <- wet_temp_fill(obs, s$air, from = "2018-03-01")
  expect_equal(min(f$date), as.Date("2018-03-01"))
  expect_true(all(f$filled[f$date < as.Date("2018-06-01")]))
})

test_that("air takes cd_extract_daily()'s shape, tmean rows only", {
  s <- sim_temp_fill(sim_pars(b = 1))
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-06-30")
  hot <- transform(s$air, variable = "tmax", value = value + 50)
  air <- rbind(s$air, hot)
  air$cell_moved <- FALSE
  a <- wet_temp_fill(s$temp[!gap, ], s$air)
  b <- wet_temp_fill(s$temp[!gap, ], air)
  expect_equal(a$t_mean_c, b$t_mean_c)
})

test_that("filled days count as provisional in wet_window_stats()", {
  s <- sim_temp_fill(sim_pars(b = 1))
  s$temp$status <- "approved"
  gap <- hide(s$temp, "08AA001", "2019-07-01", "2019-07-31")
  f <- wet_temp_fill(s$temp[!gap, ], s$air)
  w <- wet_window_stats(f, data.frame(window = "jul", start = "07-01", end = "07-31"), stats = "mean",
                        value = "t_mean_c", prefix = "t", level_anomaly = "absolute", unit = "degC")
  expect_equal(w$frac_provisional[w$year == 2019], 1)
  expect_equal(w$frac_provisional[w$year == 2018], 0)
})

test_that("pool keeps peers within their group", {
  s <- sim_temp_fill(sim_pars())
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  pool <- c("08AA001" = "a", "08AA002" = "b", "08AA003" = "b", "08AA004" = "b")
  f <- wet_temp_fill(s$temp[!gap, ], s$air, pool = pool)
  fit <- attr(f, "fit")
  expect_equal(fit$b[fit$station_number == "08AA001"], 0)
  # station 1 alone gives the same fill as station 1 in its own group
  alone <- wet_temp_fill(s$temp[!gap & s$temp$station_number == "08AA001", ], s$air)
  expect_equal(f$t_mean_c[f$station_number == "08AA001"], alone$t_mean_c)
  expect_error(wet_temp_fill(s$temp, s$air, pool = pool[-1]), "no group for: 08AA001")
  expect_error(wet_temp_fill(s$temp, s$air, pool = unname(pool)), "named")
})

test_that("a result can be filled again: filled rows are not observations", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  f <- wet_temp_fill(s$temp[!gap, ], s$air)
  again <- wet_temp_fill(f, s$air)
  expect_equal(sum(again$filled), sum(gap))
  expect_equal(again$t_mean_c, f$t_mean_c)
})

test_that("empty input and a station with too little air do not stop the call", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  e <- wet_temp_fill(s$temp[0, ], s$air)
  expect_equal(nrow(e), 0)
  expect_named(e, c(names(s$temp), "filled", "t_lo_c", "t_hi_c"))
  expect_equal(nrow(attr(e, "fit")), 0)
  air <- s$air[s$air$id != "08AA002" | s$air$date == as.Date("2019-01-01"), ]
  expect_warning(f <- wet_temp_fill(s$temp, air), "too few.*08AA002")
  expect_false(any(f$filled[f$station_number == "08AA002"]))
})

test_that("from and to limit the fill, not the fit", {
  s <- sim_temp_fill(sim_pars())
  gap <- hide(s$temp, "08AA001", "2019-06-01", "2019-08-31")
  all <- wet_temp_fill(s$temp[!gap, ], s$air)
  one <- wet_temp_fill(s$temp[!gap, ], s$air, from = "2019-03-01", to = "2019-11-30")
  expect_equal(attr(one, "fit"), attr(all, "fit"))
  expect_equal(nrow(one), nrow(s$temp[!gap, ]) + sum(gap))
  k <- one$filled
  expect_equal(one$t_mean_c[k], all$t_mean_c[all$filled])
  # a window that holds no observation still fills
  late <- wet_temp_fill(s$temp[s$temp$date <= as.Date("2020-06-30"), ], s$air,
                        from = "2020-07-01", to = "2020-07-31")
  expect_equal(sum(late$filled), 4 * 31)
})

test_that("rows with no date or station are dropped, not fatal", {
  s <- sim_temp_fill(sim_pars(b = c(1, 1)))
  x <- s$temp
  x$date[5] <- NA
  x$station_number[10] <- NA
  a <- s$air
  a$id[3] <- NA
  f <- wet_temp_fill(x, a)
  expect_equal(sum(!f$filled), nrow(s$temp) - 2)
  expect_false(anyNA(f$date))
})

test_that("bad input is refused", {
  s <- sim_temp_fill(sim_pars(b = 1))
  expect_error(wet_temp_fill(s$temp[, -3], s$air), "t_mean_c")
  expect_error(wet_temp_fill(s$temp, s$air[, -1]), "cd_extract_daily")
  expect_error(wet_temp_fill(rbind(s$temp, s$temp[1, ]), s$air), "more than one row")
  expect_error(wet_temp_fill(s$temp, rbind(s$air, s$air[1, ])), "more than one tmean")
  expect_error(wet_temp_fill(s$temp, s$air, min_days = 5), "min_days")
  expect_error(wet_temp_fill(s$temp, s$air, obs_sd = 0), "obs_sd")
  expect_error(wet_temp_fill(s$temp, s$air, level = 1), "level")
  expect_error(wet_temp_fill(s$temp, s$air, from = "2020-01-01", to = "2019-01-01"), "after")
  expect_error(wet_temp_fill(s$temp, s$air, from = NA), "`from` must be one date")
  expect_error(wet_temp_fill(s$temp, s$air, to = c("2019-01-01", "2019-02-01")), "`to` must be one date")
  expect_error(wet_temp_fill(s$temp, s$air, from = "not a date"), "`from` must be one date")
})
