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
  # a value on 30 February 1983, a day that does not exist (real HYDAT leaves
  # it NULL, so only this test carries it)
  con <- DBI::dbConnect(RSQLite::SQLite(), h)
  DBI::dbExecute(con, "UPDATE DLY_FLOWS SET FLOW30 = 99
                       WHERE STATION_NUMBER = '08AA001' AND YEAR = 1983 AND MONTH = 2")
  DBI::dbDisconnect(con)
  d <- wet_station_daily("08AA001", h, sources = "hydat")
  feb <- d[format(d$date, "%m") == "02", ]
  expect_equal(as.vector(table(format(feb$date, "%Y"))), c(29, 28, 28, 28, 29))
  expect_false(99 %in% d$q_m3s)
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
  expect_warning(
    d <- wet_station_daily(c("08AA004", "08AA001"), h, from = "1982-12-30", to = "1983-01-02",
                           sources = "hydat"),
    "no flow found for: 08AA004")
  # the seasonal station has no winter record
  expect_equal(unique(d$station_number), "08AA001")
  expect_equal(d$date, seq(as.Date("1982-12-30"), as.Date("1983-01-02"), by = "day"))
  e <- wet_station_daily("08AA004", h, sources = "hydat")
  expect_equal(range(e$date), as.Date(c("1980-05-01", "1984-10-31")))
})

test_that("a station with no record returns zero rows of the same shape", {
  h <- local_hydat()
  expect_warning(d <- wet_station_daily("08ZZ999", h, sources = "hydat"), "08ZZ999")
  expect_equal(nrow(d), 0)
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_s3_class(d$date, "Date")
})

test_that("HYDAT rows that all fall outside from/to give zero rows, not an error", {
  h <- local_hydat()
  expect_warning(d <- wet_station_daily("08AA001", h, from = "1984-12-31", to = "1984-12-31",
                                        sources = "hydat"), NA)
  expect_equal(nrow(d), 1)
  # 1984 rows are read for the year, but 08AA004 has none on this day
  w <- capture_warnings(e <- wet_station_daily("08AA004", h, from = "1984-12-31",
                                               to = "1984-12-31", sources = "hydat"))
  expect_false(any(grepl("skipped", w)))
  expect_match(w, "no flow found", all = FALSE)
  expect_equal(nrow(e), 0)
})

test_that("bad inputs are refused", {
  h <- local_hydat()
  expect_error(wet_station_daily(character(), h, sources = "hydat"), "stations")
  expect_error(wet_station_daily(NA_character_, h, sources = "hydat"), "stations")
  expect_error(wet_station_daily("08AA001", h, sources = "hydat", from = "1984-01-01",
                                 to = "1983-01-01"), "from")
  expect_error(wet_station_daily("08AA001", h, sources = "nope"), "sources")
})

# Both network readers fail unless a test says otherwise.
local_offline <- function(env = parent.frame()) {
  local_mocked_bindings(
    wet_provisional_daily = function(...) stop("no network in tests"),
    wet_realtime_daily = function(...) stop("no network in tests"),
    .env = env)
}

eccc_rows <- function(station, dates, q, hour = 8, approval = "Provisional/Provisoire") {
  data.frame(station_number = station,
             date = as.POSIXct(paste(dates, sprintf("%02d:00:00", hour)), tz = "UTC"),
             q_m3s = q, symbol = NA_character_, approval = approval)
}

test_that("ECCC timestamps become the day they describe, and status follows Approval", {
  d <- eccc_rows("08AA001", c("2025-03-01", "2025-03-02"), c(1, 2), hour = c(8, 7),
                 approval = c("Provisional/Provisoire", "Final/Finales"))
  e <- wet_eccc_daily(d, "provisional")
  expect_equal(e$date, as.Date(c("2025-03-01", "2025-03-02")))
  expect_equal(e$status, c("provisional", "approved"))
  expect_equal(e$source, c("provisional", "provisional"))
})

test_that("an ECCC approval that is not final stays provisional", {
  d <- eccc_rows("08AA001", c("2025-03-01", "2025-03-02", "2025-03-03"), 1,
                 approval = c("Final/Finales", NA, "Something new"))
  expect_equal(wet_eccc_daily(d, "provisional")$status, c("approved", "provisional", "provisional"))
  expect_named(wet_eccc_daily(d[0, ], "provisional"), names(wet_daily_empty()))
})

test_that("a trailing HYDAT month with only an impossible day does not move HYDAT's end", {
  h <- local_hydat()
  local_offline()
  con <- DBI::dbConnect(RSQLite::SQLite(), h)
  row <- DBI::dbGetQuery(con, "SELECT * FROM DLY_FLOWS WHERE STATION_NUMBER = '08AA001'
                               AND YEAR = 1984 AND MONTH = 2")
  row$YEAR <- 1985L
  row[sprintf("FLOW%d", 1:31)] <- NA_real_
  row$FLOW30 <- 5
  DBI::dbAppendTable(con, "DLY_FLOWS", row)
  DBI::dbDisconnect(con)
  local_mocked_bindings(wet_provisional_daily = function(stations) {
    days <- as.character(seq(as.Date("1984-12-20"), as.Date("1985-01-10"), by = "day"))
    wet_eccc_daily(eccc_rows("08AA001", days, 100), "provisional")
  })
  d <- wet_station_daily("08AA001", h, sources = c("hydat", "provisional"))
  expect_false(any(duplicated(d$date)))
  expect_equal(min(d$date[d$source == "provisional"]), as.Date("1985-01-01"))
})

test_that("provisional flows continue HYDAT and never fill a hole inside it", {
  h <- local_hydat()
  local_offline()
  local_mocked_bindings(wet_provisional_daily = function(stations) {
    days <- c(as.character(as.Date("1984-07-25")),
              as.character(seq(as.Date("1984-12-20"), as.Date("1985-01-10"), by = "day")))
    wet_eccc_daily(eccc_rows("08AA001", days, 100), "provisional")
  })
  d <- wet_station_daily("08AA001", h, to = "1985-01-10", sources = c("hydat", "provisional"))
  expect_false(as.Date("1984-07-25") %in% d$date)
  dec <- d[d$date >= as.Date("1984-12-20") & d$date <= as.Date("1984-12-31"), ]
  expect_true(all(dec$source == "hydat") && all(dec$q_m3s == 12))
  jan <- d[d$date >= as.Date("1985-01-01"), ]
  expect_equal(jan$date, seq(as.Date("1985-01-01"), as.Date("1985-01-10"), by = "day"))
  expect_true(all(jan$source == "provisional") && all(jan$status == "provisional"))
})

test_that("a window inside a HYDAT hole still gets no provisional flow there", {
  h <- local_hydat()
  local_offline()
  local_mocked_bindings(wet_provisional_daily = function(stations) {
    days <- c("1984-07-25", as.character(seq(as.Date("1984-12-20"), as.Date("1985-01-10"),
                                             by = "day")))
    wet_eccc_daily(eccc_rows("08AA001", days, 100), "provisional")
  })
  # the whole window sits in July 1984, where HYDAT lost days 20-31
  d <- wet_station_daily("08AA001", h, from = "1984-07-01", to = "1984-07-31",
                         sources = c("hydat", "provisional"))
  expect_false(as.Date("1984-07-25") %in% d$date)
  # the internal cutoff attribute does not reach the result
  p <- wet_station_daily("08AA001", h, to = "1985-01-10", sources = "provisional")
  expect_null(attr(p, "last"))
  expect_true(all(d$source == "hydat"))
})

test_that("real-time never fills a provisional hole before a window's end", {
  h <- local_hydat()
  local_offline()
  called <- FALSE
  local_mocked_bindings(
    wet_provisional_daily = function(stations) {
      days <- as.character(Sys.Date() - c(30:20, 17:11))
      wet_eccc_daily(eccc_rows("08AA001", days, 5), "provisional")
    },
    wet_realtime_daily = function(station, from, to) {
      called <<- TRUE
      wet_eccc_daily(eccc_rows(station, as.character(seq(from, to, by = "day")), 7), "realtime")
    })
  # the window ends inside the provisional hole (days 19-18 before today)
  d <- wet_station_daily("08AA001", h, from = Sys.Date() - 30, to = Sys.Date() - 18,
                         sources = c("provisional", "realtime"))
  expect_false(called)
  expect_true(all(d$source == "provisional"))
})

test_that("real-time starts the day after the last earlier source and stops before today", {
  h <- local_hydat()
  local_offline()
  got <- NULL
  local_mocked_bindings(
    wet_provisional_daily = function(stations) {
      wet_eccc_daily(eccc_rows("08AA001", as.character(Sys.Date() - 30:11), 5), "provisional")
    },
    wet_realtime_daily = function(station, from, to) {
      got <<- list(station = station, from = from, to = to)
      wet_eccc_daily(eccc_rows(station, as.character(seq(from, to, by = "day")), 7), "realtime")
    })
  d <- suppressWarnings(wet_station_daily("08AA001", h, from = Sys.Date() - 30,
                                          to = Sys.Date() + 5))
  expect_equal(got$from, Sys.Date() - 10)
  expect_equal(got$to, Sys.Date() - 1)
  expect_equal(max(d$date), Sys.Date() - 1)
  expect_equal(sum(d$source == "realtime"), 10)
})

test_that("real-time alone still gets Dates when nothing came before it", {
  h <- local_hydat()
  local_offline()
  got <- NULL
  local_mocked_bindings(wet_realtime_daily = function(station, from, to) {
    got <<- from
    wet_daily_empty()
  })
  suppressWarnings(wet_station_daily("08AA001", h, sources = "realtime"))
  expect_s3_class(got, "Date")
  expect_equal(got, Sys.Date() - 540)
})

test_that("a gap at a seam between sources is warned about and left unfilled", {
  h <- local_hydat()
  local_offline()
  local_mocked_bindings(wet_provisional_daily = function(stations) {
    wet_eccc_daily(eccc_rows("08AA001", c("1985-01-05", "1985-01-06"), 100), "provisional")
  })
  expect_warning(
    d <- wet_station_daily("08AA001", h, to = "1985-01-06", sources = c("hydat", "provisional")),
    "08AA001 1985-01-01 to 1985-01-04 \\(hydat -> provisional\\)")
  expect_equal(nrow(d[d$source == "provisional", ]), 2)
  # a window starting inside the gap still hears about it
  expect_warning(
    wet_station_daily("08AA001", h, from = "1985-01-02", to = "1985-01-06",
                      sources = c("hydat", "provisional")),
    "1985-01-01 to 1985-01-04")
  # one wholly after it does not
  expect_no_warning(wet_station_daily("08AA001", h, from = "1985-01-05", to = "1985-01-06",
                                      sources = c("hydat", "provisional")))
})

test_that("a window starting inside a real-time hole reports no seam gap", {
  h <- local_hydat()
  local_offline()
  t0 <- Sys.Date()
  local_mocked_bindings(
    wet_provisional_daily = function(stations) {
      wet_eccc_daily(eccc_rows("08AA001", as.character(t0 - 90:60), 5), "provisional")
    },
    wet_realtime_daily = function(station, from, to) {
      days <- c(t0 - 59:40, t0 - 29:1)
      days <- days[days >= from & days <= to]
      wet_eccc_daily(eccc_rows(station, as.character(days), 7), "realtime")
    })
  expect_no_warning(wet_station_daily("08AA001", h, sources = c("provisional", "realtime")))
  expect_no_warning(d <- wet_station_daily("08AA001", h, from = t0 - 35,
                                           sources = c("provisional", "realtime")))
  expect_equal(min(d$date), t0 - 29)
})

test_that("holes inside one source are not warned about", {
  h <- local_hydat()
  expect_no_warning(wet_station_daily("08AA004", h, sources = "hydat"))
})

test_that("a failing source is skipped with a warning and the rest returned", {
  h <- local_hydat()
  local_offline()
  expect_warning(
    d <- wet_station_daily("08AA001", h, to = "1990-01-01", sources = c("hydat", "provisional")),
    "source \"provisional\" skipped: no network in tests")
  expect_true(all(d$source == "hydat"))
  expect_equal(max(d$date), as.Date("1984-12-31"))
})

test_that("a station with no flow anywhere is named in a warning", {
  h <- local_hydat()
  expect_warning(d <- wet_station_daily(c("08AA001", "08ZZ999"), h, sources = "hydat"),
                 "no flow found for: 08ZZ999")
  expect_equal(unique(d$station_number), "08AA001")
})

test_that("live: Buck Creek runs from HYDAT through provisional to real-time", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()
  skip_if_not_installed("duckdb")
  skip_if_not_installed("tidyhydat")
  # needs a HYDAT that reaches the provisional archive's start (2024-10);
  # tidyhydat's default copy may be older, so no fallback to it
  h <- test_path("..", "..", "data", "hydat", "20260717", "Hydat.sqlite3")
  if (!file.exists(h)) skip("needs HYDAT 2026-07-17 at data/hydat/20260717/")
  d <- wet_station_daily("08EE013", h, from = "2024-01-01")
  expect_setequal(unique(d$source), c("hydat", "provisional", "realtime"))
  expect_false(any(duplicated(d$date)))
  expect_gt(max(d$date), Sys.Date() - 10)
})
