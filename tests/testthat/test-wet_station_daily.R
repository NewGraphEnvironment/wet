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
  # tidyhydat's default copy may be older, so the release is pinned
  h <- local_hydat_pinned("20260717")
  d <- wet_station_daily("08EE013", h, from = "2024-01-01")
  expect_setequal(unique(d$source), c("hydat", "provisional", "realtime"))
  expect_false(any(duplicated(d$date)))
  expect_gt(max(d$date), Sys.Date() - 10)
})

# The provincial reader and registry stood in for: 08ZZ0001 is a provincial station.
local_bcenv_stub <- function(env = parent.frame()) {
  calls <- new.env()
  calls$daily <- list()
  local_mocked_bindings(
    wet_bcenv_stations = function(snapshot) data.frame(station_number = c("08ZZ0001", "08ZZ0002")),
    wet_bcenv_daily = function(stations, snapshot) {
      calls$daily[[length(calls$daily) + 1]] <- stations
      data.frame(station_number = "08ZZ0001", date = as.Date("2020-06-02") + 0:2, q_m3s = c(2, 3, 4),
                 symbol = NA_character_, source = "bcenv", status = c("provisional", "unchecked", "provisional"))
    },
    .env = env)
  calls
}

test_that("a call with HYDAT numbers alone opens neither registry nor either reader", {
  h <- local_hydat()
  local_mocked_bindings(wet_bcenv_stations = function(...) stop("registry opened"),
                        wet_bcenv_daily = function(...) stop("provincial reader called"),
                        wet_bcwatertool_stations = function(...) stop("Tool registry opened"),
                        wet_bcwatertool_daily = function(...) stop("Tool reader called"))
  w <- capture_warnings(d <- wet_station_daily("08AA001", h, sources = c("hydat", "bcenv", "bcwatertool")))
  expect_length(w, 0)
  expect_true(all(d$source == "hydat"))
})

test_that("a provincial number is read from the provincial source, and never asked of the federal ones", {
  h <- local_hydat()
  calls <- local_bcenv_stub()
  asked <- character()
  local_mocked_bindings(wet_provisional_daily = function(stations) {
    asked <<- c(asked, stations)
    wet_daily_empty()
  })
  d <- wet_station_daily(c("08AA001", "08ZZ0001"), h, to = NULL, sources = c("hydat", "provisional", "bcenv"))
  expect_equal(asked, "08AA001")
  expect_equal(calls$daily, list("08ZZ0001"))
  p <- d[d$station_number == "08ZZ0001", ]
  expect_equal(p$q_m3s, c(2, 3, 4))
  expect_true(all(p$source == "bcenv"))
  expect_equal(p$status, c("provisional", "unchecked", "provisional"))
  expect_equal(unique(d$station_number), c("08AA001", "08ZZ0001"))
})

test_that("from and to trim provincial days too; a number in neither source is warned about", {
  h <- local_hydat()
  calls <- local_bcenv_stub()
  expect_warning(d <- wet_station_daily(c("08ZZ0001", "XX0001"), h, from = "2020-06-03", sources = "bcenv"),
                 "no flow found for: XX0001")
  expect_equal(d$date, as.Date(c("2020-06-03", "2020-06-04")))
  # only numbers in the registry reach the reader
  expect_equal(calls$daily, list("08ZZ0001"))
})

test_that("without \"bcenv\" a provincial number gets no flow, and the reader is not called", {
  h <- local_hydat()
  local_mocked_bindings(wet_bcenv_stations = function(...) stop("registry opened"),
                        wet_bcenv_daily = function(...) stop("provincial reader called"))
  expect_warning(d <- wet_station_daily("08ZZ0001", h, sources = "hydat"), "no flow found for: 08ZZ0001")
  expect_equal(nrow(d), 0)
})

test_that("a failing provincial source is skipped with a warning", {
  h <- local_hydat()
  local_mocked_bindings(wet_bcenv_stations = function(...) stop("no registry here"))
  w <- capture_warnings(d <- wet_station_daily(c("08AA001", "08ZZ0001"), h, sources = c("hydat", "bcenv")))
  expect_match(w, "source \"bcenv\" skipped: no registry here", all = FALSE)
  expect_true(all(d$source == "hydat"))
})

test_that("live: Deep Creek's provincial record is read from the pinned snapshot", {
  skip_if_not_installed("duckdb")
  tryCatch(wet_bcenv(), wet_bcenv_unavailable = function(e) skip(conditionMessage(e)))
  d <- wet_station_daily("08EE0001", sources = "bcenv", to = NULL)
  expect_gt(nrow(d), 500)
  expect_true(all(d$source == "bcenv") && all(d$status %in% c("provisional", "unchecked")))
  expect_false(anyDuplicated(d$date) > 0)
  s <- wet_station_list()
  expect_equal(range(d$date), c(s$first[s$station_number == "08EE0001"], s$last[s$station_number == "08EE0001"]))
})

# The Water Tool's registry and reader stood in for, beside a provincial
# registry: TST1 is a Tool station of its own; 4601 continues provincial
# 08ZZ0001 (first day 2021-10-01) and 4602 continues 08ZZ0002 (no complete day).
local_bcwatertool_stub <- function(env = parent.frame(), prov_first = as.Date(c("2021-10-01", NA))) {
  calls <- new.env()
  calls$daily <- list()
  local_mocked_bindings(
    wet_bcenv_stations = function(snapshot) data.frame(station_number = c("08ZZ0001", "08ZZ0002"), first = prov_first),
    wet_bcenv_daily = function(stations, snapshot) {
      data.frame(station_number = "08ZZ0001", date = as.Date("2021-10-01") + 0:1, q_m3s = c(7, 8),
                 symbol = NA_character_, source = "bcenv", status = "provisional")
    },
    wet_bcwatertool_stations = function(snapshot = "20261028") {
      data.frame(station_number = c("4601", "4602", "TST1"), continues = c("08ZZ0001", "08ZZ0002", NA))
    },
    wet_bcwatertool_daily = function(stations, ...) {
      calls$daily[[length(calls$daily) + 1]] <- stations
      d <- data.frame(station_number = rep(c("4601", "4602", "TST1"), each = 3),
                      date = as.Date(c("2015-11-09", "2015-11-10", "2021-10-01", "2015-01-01", "2015-01-02",
                                       "2015-01-03", "2020-06-01", "2020-06-02", "2020-06-03")),
                      q_m3s = 1:9, symbol = NA_character_, source = "bcwatertool", status = "provisional")
      d[d$station_number %in% stations, ]
    },
    .env = env)
  calls
}

test_that("a Water Tool number is read from the Tool's source under its own number", {
  h <- local_hydat()
  calls <- local_bcwatertool_stub()
  d <- wet_station_daily(c("08AA001", "TST1"), h, to = NULL, sources = c("hydat", "bcwatertool"))
  expect_equal(calls$daily, list("TST1"))
  t <- d[d$station_number == "TST1", ]
  expect_equal(t$q_m3s, 7:9)
  expect_true(all(t$source == "bcwatertool"))
})

test_that("a provincial station's record is continued by the Tool gauge at its site, before its first day only", {
  h <- local_hydat()
  calls <- local_bcwatertool_stub()
  w <- capture_warnings(d <- wet_station_daily("08ZZ0001", h, to = NULL, sources = c("bcenv", "bcwatertool")))
  expect_equal(calls$daily, list("4601"))
  expect_equal(d$date, as.Date(c("2015-11-09", "2015-11-10", "2021-10-01", "2021-10-02")))
  expect_equal(d$source, c("bcwatertool", "bcwatertool", "bcenv", "bcenv"))
  expect_equal(d$q_m3s, c(1, 2, 7, 8))
  expect_true(all(d$station_number == "08ZZ0001"))
  # the years between the two publishers are a gap between sources
  expect_match(w, "gap between sources.*08ZZ0001 2015-11-11 to 2021-09-30 \\(bcwatertool -> bcenv\\)", all = FALSE)
  # the cut is the registry's first day, whichever sources are asked
  d2 <- wet_station_daily("08ZZ0001", h, to = NULL, sources = "bcwatertool")
  expect_equal(d2$date, as.Date(c("2015-11-09", "2015-11-10")))
})

test_that("a provincial station with no complete day takes all its continuing gauge's days", {
  h <- local_hydat()
  calls <- local_bcwatertool_stub()
  d <- wet_station_daily("08ZZ0002", h, to = NULL, sources = "bcwatertool")
  expect_equal(d$q_m3s, 4:6)
  expect_true(all(d$station_number == "08ZZ0002"))
})

test_that("a continuing gauge's own number gets nothing, and without \"bcwatertool\" there is no chain", {
  h <- local_hydat()
  calls <- local_bcwatertool_stub()
  expect_warning(d <- wet_station_daily("4601", h, to = NULL, sources = "bcwatertool"), "no flow found for: 4601")
  expect_equal(nrow(d), 0)
  local_mocked_bindings(wet_bcwatertool_stations = function(...) stop("Tool registry opened"))
  d <- wet_station_daily("08ZZ0001", h, to = NULL, sources = "bcenv")
  expect_true(all(d$source == "bcenv"))
})

test_that("a provincial number no Tool gauge continues never calls the Tool's reader", {
  h <- local_hydat()
  local_bcwatertool_stub()
  local_mocked_bindings(
    wet_bcwatertool_stations = function(...) data.frame(station_number = "TST1", continues = NA_character_),
    wet_bcwatertool_daily = function(...) stop("Tool reader called"))
  w <- capture_warnings(d <- wet_station_daily("08ZZ0001", h, to = NULL))
  expect_false(any(grepl("skipped", w)))
  expect_true(all(d$source == "bcenv"))
})

test_that("a number held by both registries is refused, not skipped", {
  h <- local_hydat()
  local_bcwatertool_stub()
  local_mocked_bindings(
    wet_bcwatertool_stations = function(...) data.frame(station_number = "08ZZ0001", continues = NA_character_))
  expect_error(wet_station_daily("TST1", h, sources = "bcwatertool"), "both hold 08ZZ0001",
               class = "wet_registry_conflict")
  expect_error(wet_station_list(), "both hold 08ZZ0001")
})

test_that("a failing Tool source is skipped with a warning", {
  h <- local_hydat()
  local_bcwatertool_stub()
  local_mocked_bindings(wet_bcwatertool_daily = function(...) stop("no Tool cache here"))
  w <- capture_warnings(d <- wet_station_daily(c("08AA001", "TST1"), h, sources = c("hydat", "bcwatertool")))
  expect_match(w, "source \"bcwatertool\" skipped: no Tool cache here", all = FALSE)
  expect_true(all(d$source == "hydat"))
})

test_that("live: Rosewall Creek's provincial record is continued by BC Conservation Foundation's years", {
  skip_if_not_installed("duckdb")
  tryCatch({
    wet_bcenv()
    reg <- wet_bcwatertool_stations()
    wet_bcwatertool(reg$id[reg$station_number == "4602"])
  }, wet_snapshot_unavailable = function(e) skip(conditionMessage(e)))
  d <- suppressWarnings(wet_station_daily("08HB0008", sources = c("bcenv", "bcwatertool"), to = NULL))
  s <- wet_station_list()
  r <- s[s$station_number == "08HB0008", ]
  first <- min(d$date[d$source == "bcenv"])
  expect_true(all(d$date[d$source == "bcwatertool"] < first))
  expect_equal(format(range(d$date[d$source == "bcwatertool"]), "%Y"), c("2012", "2015"))
  expect_equal(min(d$date), r$first)
  expect_match(r$credit, "; days before 2021-10-01: Data from BC Conservation Foundation", fixed = TRUE)
})
