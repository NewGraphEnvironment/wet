skip_if_not_installed("duckdb")

test_that("hours become local-standard-time days with the documented flow and status", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily("08ZZ0001", bound = 100, cache_dir = f$cache)
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_equal(format(d$date), c("2020-06-02", "2020-06-03", "2020-06-05", "2020-06-06", "2020-06-09"))
  expect_equal(d$q_m3s, c(2, 3, 4, 5, 6))
  expect_equal(d$status, c("provisional", "unchecked", "provisional", "provisional", "provisional"))
  expect_true(all(d$source == "bcenv") && all(is.na(d$symbol)))
})

test_that("an hour in two files is taken from the newer", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily(c("08ZZ0001", "08ZZ0002"), bound = 100, cache_dir = f$cache)
  expect_equal(d$q_m3s[d$station_number == "08ZZ0001" & d$date == as.Date("2020-06-02")], 2)
  # a station only the older file holds is still read
  b <- d[d$station_number == "08ZZ0002", ]
  expect_equal(b$q_m3s, 7)
  expect_equal(b$status, "unchecked")
})

test_that("l/s is converted to m^3/s", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily("08ZZ0001", bound = 100, cache_dir = f$cache)
  expect_equal(d$q_m3s[d$date == as.Date("2020-06-09")], 6)
})

test_that("a day needs 20 hours; Unusable and NaN hours do not count", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily("08ZZ0001", bound = Inf, cache_dir = f$cache)
  expect_false(as.Date("2020-06-04") %in% d$date)  # 19 hours
  expect_true(as.Date("2020-06-03") %in% d$date)   # 20 hours
  # the Unusable hour's 1000 is not in the mean
  expect_equal(d$q_m3s[d$date == as.Date("2020-06-05")], 4)
  d19 <- wet_bcenv_daily("08ZZ0001", bound = Inf, min_hours = 19L, cache_dir = f$cache)
  expect_true(as.Date("2020-06-04") %in% d19$date)
})

test_that("a day that straddles UTC midnight is one local day; the Peace keeps UTC-7", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily(c("08ZZ0001", "07ZZ0001"), bound = 100, cache_dir = f$cache)
  p <- d[d$station_number == "07ZZ0001", ]
  expect_equal(format(p$date), "2020-06-02")
  expect_equal(p$q_m3s, 2)
  # under UTC days the same hours split into two partial days, neither complete
  utc <- wet_bcenv_days_read(wet_bcenv_days("20261028", f$cache, utc = TRUE), "08ZZ0001")
  expect_equal(utc$hours[utc$date == as.Date("2020-06-02")], 16)
  expect_equal(utc$hours[utc$date == as.Date("2020-06-03")], 8 + 16)
})

test_that("the byte 0x96 in a station name does not stop the read", {
  f <- local_bcenv_fixture()
  con <- DBI::dbConnect(duckdb::duckdb())
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  wet_bcenv_hours(con, f$paths)
  nm <- DBI::dbGetQuery(con, "SELECT DISTINCT name FROM h WHERE id = '08ZZ0001'")$name
  expect_equal(nm, "Alpha Creek - upper")
})

test_that("a row the lenient parser drops is refused", {
  f <- local_bcenv_fixture()
  # a blank line is skipped by duckdb outside strict mode, and counted as a line
  cat("\n", file = f$paths[1], append = TRUE)
  expect_error(wet_bcenv_daily("08ZZ0001", cache_dir = f$cache), "different number of rows")
})

test_that("a file whose last line has no newline is read whole", {
  f <- local_bcenv_fixture()
  b <- readBin(f$paths[1], "raw", file.size(f$paths[1]))
  writeBin(b[-length(b)], f$paths[1])
  d <- wet_bcenv_daily("08ZZ0001", bound = 100, cache_dir = f$cache)
  expect_equal(d$q_m3s, c(2, 3, 4, 5, 6))
})

test_that("a value that is not a number is refused, not read as missing", {
  f <- local_bcenv_fixture()
  cat("08ZZ0001,Alpha,Active,49.1,-123.1,2020-07-01 08:00:00,Discharge,1.0x,m^3/s,RISC A\n",
      file = f$paths[1], append = TRUE)
  expect_error(wet_bcenv_daily("08ZZ0001", cache_dir = f$cache), "not numbers, such as \"1.0x\"")
})

test_that("a unit other than l/s or m^3/s is refused", {
  f <- local_bcenv_fixture()
  cat("08ZZ0001,Alpha,Active,49.1,-123.1,2020-07-01 08:00:00,Discharge,1.0,cfs,RISC A\n",
      file = f$paths[1], append = TRUE)
  expect_error(wet_bcenv_daily("08ZZ0001", cache_dir = f$cache), "unit other than .*cfs")
})

test_that("the bound drops an impossible day, and a negative day is dropped", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily("08ZZ0001", bound = 100, cache_dir = f$cache)
  expect_false(as.Date("2020-06-07") %in% d$date)
  expect_false(as.Date("2020-06-08") %in% d$date)
  # without a bound the impossible day stays; the negative day never does
  inf <- wet_bcenv_daily("08ZZ0001", bound = Inf, cache_dir = f$cache)
  expect_equal(inf$q_m3s[inf$date == as.Date("2020-06-07")], 1e6)
  expect_false(as.Date("2020-06-08") %in% inf$date)
  # the cap is the bound times the median of positive days (2, 3, 4, 5, 1e6, 6: 4.5)
  edge <- wet_bcenv_daily("08ZZ0001", bound = 1e6 / 4.5 * (1 + 1e-9), cache_dir = f$cache)
  expect_true(as.Date("2020-06-07") %in% edge$date)
  below <- wet_bcenv_daily("08ZZ0001", bound = 1e6 / 4.5 * (1 - 1e-9), cache_dir = f$cache)
  expect_false(as.Date("2020-06-07") %in% below$date)
})

test_that("the stored days are built once and reused, and keyed by the manifest and reader version", {
  f <- local_bcenv_fixture()
  wet_bcenv_daily("08ZZ0001", cache_dir = f$cache)
  dir <- file.path(f$cache, "station_sources", "bcenv", "20261028")
  stored <- list.files(dir, pattern = sprintf("^days_[0-9a-f]{10}_v%d[.]parquet$", wet_bcenv_reader), full.names = TRUE)
  expect_length(stored, 1)
  # keyed by the manifest's content: another manifest under the same snapshot date is another file
  local({
    local_mocked_bindings(wet_bcenv_manifest_path = function(snapshot) f$paths[1])
    expect_false(identical(wet_bcenv_days("20261028", f$cache), stored))
  })
  expect_identical(wet_bcenv_days("20261028", f$cache), stored)
  # a second read does not rebuild: the snapshot's files are no longer needed
  unlink(f$paths)
  expect_equal(nrow(wet_bcenv_daily("08ZZ0001", bound = 100, cache_dir = f$cache)), 5)
  expect_length(list.files(dir, pattern = "partial", all.files = TRUE), 0)
})

test_that("unknown stations give zero rows of the same shape; bad arguments are refused", {
  f <- local_bcenv_fixture()
  d <- wet_bcenv_daily("08ZZ9999", cache_dir = f$cache)
  expect_equal(nrow(d), 0)
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_error(wet_bcenv_daily(NA_character_, cache_dir = f$cache), "stations")
  expect_error(wet_bcenv_daily("08ZZ0001", bound = 0, cache_dir = f$cache), "bound")
})

test_that("a named bound is taken per WSC sub-drainage, with a default for the rest", {
  b <- c(.default = 1000, "08Z" = 2)
  expect_equal(wet_bcenv_ratio(c("08ZZ0001", "H08ZC0626", "07ZZ0001", "XYZ"), b), c(2, 2, 1000, 1000))
  expect_equal(wet_bcenv_ratio(c("08ZZ0001", "07ZZ0001"), 5), c(5, 5))
  f <- local_bcenv_fixture()
  # 08Z at 2 x the median (4.5) keeps 2, 3, 4, 5, 6 only up to 9; 07Z's lone day stays under the default
  d <- wet_bcenv_daily(c("08ZZ0001", "07ZZ0001"), bound = b, cache_dir = f$cache)
  expect_equal(d$q_m3s[d$station_number == "08ZZ0001"], c(2, 3, 4, 5, 6))
  expect_equal(d$q_m3s[d$station_number == "07ZZ0001"], 2)
  d1 <- wet_bcenv_daily("08ZZ0001", bound = c(.default = 1000, "08Z" = 1), cache_dir = f$cache)
  expect_equal(d1$q_m3s, c(2, 3, 4))
  expect_error(wet_bcenv_daily("08ZZ0001", bound = c("08Z" = 2), cache_dir = f$cache), "default")
  expect_error(wet_bcenv_daily("08ZZ0001", bound = c(1, 2), cache_dir = f$cache), "bound")
})

test_that("the shipped bound is the measured one: finite, per sub-drainage, with a default", {
  expect_true(all(is.finite(wet_bcenv_bound)) && all(wet_bcenv_bound > 1))
  expect_equal(wet_bcenv_bound[[".default"]], 2490.71)
  expect_equal(wet_bcenv_bound[["08H"]], 268.07)
  # the report's printed line is the constant
  rep <- test_path("..", "..", "data", "checks", "station_sources_bound_20260717.txt")
  skip_if_not(file.exists(rep), "the bound report is not in this tree")
  line <- grep("^As R \\(wet_bcenv_bound\\): ", readLines(rep), value = TRUE)
  expect_identical(eval(parse(text = sub("^As R \\(wet_bcenv_bound\\): ", "", line))), wet_bcenv_bound)
})
