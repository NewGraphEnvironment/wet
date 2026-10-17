test_that("day-of-year flow steps by month on the fixture, and shares sum to 1", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  d <- wet_station_doy(s, h)
  expect_equal(nrow(d), 365L * nrow(s))
  expect_setequal(d$station_number, s$station_number)
  for (st in s$station_number) {
    x <- d[d$station_number == st, ]
    expect_equal(x$doy, 1:365)
    # flow in month m is m on every day, and the days knocked out of March 1982 do not bias it
    expect_equal(x$q_m3s, as.numeric(wet:::wet_doy_month()))
    expect_equal(sum(x$share), 1)
    expect_equal(x$share, x$q_m3s / sum(x$q_m3s))
    expect_equal(unique(x$n_years), length(attr(s, "years")[[st]]))
  }
  expect_equal(nrow(attr(d, "filled")), 0L)
  # the same years, given explicitly, give the same result
  d2 <- wet_station_doy(s, h, years = attr(s, "years"))
  expect_equal(d2, d)
})

test_that("29 February is averaged into 28 February before the years are", {
  h <- local_hydat()
  # 1980 is a leap year and complete at 08AA001 (1984 is not: July has 19 days)
  s <- wet_station_select(h, years = 1980:1983, min_years = 2)
  yrs <- attr(s, "years")[["08AA001"]]
  expect_true(1980 %in% yrs)
  con <- DBI::dbConnect(RSQLite::SQLite(), h)
  DBI::dbExecute(con, "UPDATE DLY_FLOWS SET FLOW29 = 20 WHERE STATION_NUMBER = '08AA001' AND YEAR = 1980 AND MONTH = 2")
  DBI::dbDisconnect(con)
  d <- wet_station_doy(s, h)
  x <- d[d$station_number == "08AA001", ]
  feb28 <- which(wet:::wet_doy_md() == "02-28")
  expect_equal(feb28, 59L)
  # 1980 contributes mean(2, 20) = 11 for that day; the other years 2
  expect_equal(x$q_m3s[feb28], (2 * (length(yrs) - 1) + 11) / length(yrs))
  expect_equal(x$q_m3s[-feb28], as.numeric(wet:::wet_doy_month())[-feb28])
  expect_equal(nrow(d), 365L * nrow(s))
})

test_that("a day missing from every complete year is interpolated and counted", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  con <- DBI::dbConnect(RSQLite::SQLite(), h)
  # 1 January in every year: the fill wraps around from 31 December
  DBI::dbExecute(con, "UPDATE DLY_FLOWS SET FLOW1 = NULL WHERE STATION_NUMBER = '08AA001' AND MONTH = 1")
  DBI::dbDisconnect(con)
  d <- wet_station_doy(s, h)
  x <- d[d$station_number == "08AA001", ]
  expect_equal(x$q_m3s[1], mean(c(12, 1)))  # between 31 December (12) and 2 January (1)
  expect_equal(attr(d, "filled"), data.frame(station_number = "08AA001", doy = 1L))
  expect_false(anyNA(d$q_m3s))
})

test_that("stations without their years are refused, and empty input returns the shape", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  attr(s, "years") <- NULL
  expect_error(wet_station_doy(s, h), "years")
  expect_error(wet_station_doy(s, h, years = list(`08AA009` = 1981:1983)), "years")  # not this station
  e <- wet_station_doy(s[0, ], h)
  expect_equal(nrow(e), 0L)
  expect_named(e, c("station_number", "doy", "q_m3s", "share", "n_years"))
  expect_equal(nrow(attr(e, "filled")), 0L)
})

test_that("summarising with a looser min_days than the selection is refused", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2, min_days = 19)
  expect_error(wet_station_doy(s, h, min_days = 20), "min_days")
})

test_that("live: the days of a month average to wet_station_monthly()'s mean", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("tidyhydat")
  h <- local_hydat_pinned("20260717")
  s <- wet_station_select(h)
  pick <- c("08EE013", "08EE004", "08MF005")  # Buck Creek, Bulkley at Quick, Fraser at Hope
  pick <- pick[pick %in% s$station_number]
  expect_gte(length(pick), 2L)
  st <- s[s$station_number %in% pick, ]
  yrs <- attr(s, "years")[pick]
  d <- wet_station_doy(st, h, years = yrs)
  m <- wet_station_monthly(structure(st, years = yrs), h)
  for (p in pick) {
    daily <- tapply(d$q_m3s[d$station_number == p], wet:::wet_doy_month(), mean)
    monthly <- m$q_m3s[m$station_number == p & m$month > 0]
    rel <- abs(daily / monthly - 1)
    # February: 28 days against 28 or 29 in the record, so at most 1/29;
    # other months differ only through days missing in some years
    expect_lte(rel[[2]], 1 / 29)
    expect_lt(max(rel[-2]), 0.02)
  }
})
