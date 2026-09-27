test_that("only natural stations with enough complete years in the window qualify", {
  h <- local_hydat()
  s <- wet_station_select(h, years = 1981:1984, min_years = 2)
  # regulated, no regulation record, and seasonal gauges are all out
  expect_equal(s$station_number, "08AA001")
  # 1980 is outside the window and 1984 has a 19-day July
  expect_equal(s$n_years, 3L)
  expect_equal(attr(s, "years")[["08AA001"]], 1981:1983)
  expect_equal(s$drainage_area_gross_km2, 100)
})

test_that("min_years, min_days and prov change the selection", {
  h <- local_hydat()
  expect_equal(nrow(wet_station_select(h, years = 1981:1984, min_years = 4)), 0)
  expect_equal(wet_station_select(h, years = 1981:1984, min_years = 4, min_days = 19)$n_years, 4L)
  expect_equal(wet_station_select(h, years = 1981:1984, min_years = 2, prov = c("BC", "YT"))$station_number,
               c("08AA001", "09AA001"))
})

test_that("a missing database is an error, not an empty file", {
  p <- file.path(withr::local_tempdir(), "nope.sqlite3")
  expect_error(wet_station_select(p), "HYDAT not found")
  expect_false(file.exists(p))
})
