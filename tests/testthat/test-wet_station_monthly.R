test_that("monthly flow, shares and the annual volume-weighted flow are consistent", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  m <- wet_station_monthly(s, h)
  mo <- m[m$month > 0, ]
  # flow in month m is m; days knocked out of March 1982 do not bias the mean
  expect_equal(mo$q_m3s, 1:12)
  days <- wet_month_days()
  expect_equal(mo$share, unname((1:12) * days / sum((1:12) * days)))
  expect_equal(sum(mo$share), 1)
  expect_equal(m$q_m3s[m$month == 0], sum((1:12) * days) / 365.25)
  expect_equal(unique(m$n_years), 3L)
})

test_that("stations without their years attribute are refused", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  attr(s, "years") <- NULL
  expect_error(wet_station_monthly(s, h), "years")
})

test_that("summarising with a looser min_days than the selection is refused", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2, min_days = 19)
  expect_error(wet_station_monthly(s, h, min_days = 20), "min_days")
})
