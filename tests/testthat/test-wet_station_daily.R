test_that("HYDAT daily flows unpivot to one row per station-day that has a value", {
  h <- local_hydat()
  d <- wet_station_daily("08AA001", h, sources = "hydat")
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_s3_class(d$date, "Date")
  # 1980-1984 is 1827 days; July 1984 lost days 20-31 and March 1982 days 1-5
  expect_equal(nrow(d), 1827 - 12 - 5)
  expect_false(anyNA(d$q_m3s))
  expect_false(any(d$date %in% as.Date(sprintf("1984-07-%02d", 20:31))))
  # flow equals the month number
  expect_equal(d$q_m3s, as.numeric(format(d$date, "%m")))
  expect_true(all(d$source == "hydat") && all(d$status == "approved"))
  expect_false(is.unsorted(d$date))
})

test_that("days past the end of a month never appear, leap days do", {
  h <- local_hydat()
  d <- wet_station_daily("08AA001", h, sources = "hydat")
  feb <- d[format(d$date, "%m") == "02", ]
  expect_equal(as.vector(table(format(feb$date, "%Y"))), c(29, 28, 28, 28, 29))
})

test_that("HYDAT symbols are carried per day", {
  h <- local_hydat()
  d <- wet_station_daily("08AA001", h, sources = "hydat")
  ice <- d$symbol %in% "B"
  expect_equal(d$date[ice], seq(as.Date("1981-01-01"), as.Date("1981-01-31"), by = "day"))
  expect_equal(d$date[d$symbol %in% "E"], as.Date("1983-06-15"))
  expect_equal(sum(!is.na(d$symbol)), 32)
})

test_that("from and to bound the dates, and stations come back in order", {
  h <- local_hydat()
  d <- wet_station_daily(c("08AA004", "08AA001"), h, from = "1982-12-30", to = "1983-01-02",
                         sources = "hydat")
  # the seasonal station has no winter record
  expect_equal(unique(d$station_number), "08AA001")
  expect_equal(d$date, seq(as.Date("1982-12-30"), as.Date("1983-01-02"), by = "day"))
  e <- wet_station_daily("08AA004", h, sources = "hydat")
  expect_equal(range(e$date), as.Date(c("1980-05-01", "1984-10-31")))
})

test_that("a station with no record returns zero rows of the same shape", {
  h <- local_hydat()
  d <- wet_station_daily("08ZZ999", h, sources = "hydat")
  expect_equal(nrow(d), 0)
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_s3_class(d$date, "Date")
})

test_that("bad inputs are refused", {
  h <- local_hydat()
  expect_error(wet_station_daily(character(), h, sources = "hydat"), "stations")
  expect_error(wet_station_daily(NA_character_, h, sources = "hydat"), "stations")
  expect_error(wet_station_daily("08AA001", h, sources = "hydat", from = "1984-01-01",
                                 to = "1983-01-01"), "from")
  expect_error(wet_station_daily("08AA001", h, sources = "nope"), "sources")
})
