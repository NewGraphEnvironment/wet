# A local stand-in for the water-temp-bc archive: one parquet file whose Date is
# a real TIMESTAMP WITH TIME ZONE, as in canonical/. `utc` is a character UTC
# time ("2020-07-01 08:00"). The readers then run their own SQL on it.
local_temp_archive <- function(rows, env = parent.frame()) {
  skip_if_not_installed("duckdb")
  dir <- withr::local_tempdir(.local_envir = env)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  rows$sec <- as.numeric(as.POSIXct(rows$utc, tz = "UTC"))
  rows$utc <- NULL
  duckdb::duckdb_register(con, "rows", rows)
  DBI::dbExecute(con, sprintf(
    "COPY (SELECT STATION_NUMBER, to_timestamp(sec) AS Date, Value, Approval FROM rows)
     TO %s (FORMAT parquet)", DBI::dbQuoteString(con, file.path(dir, "part-0.parquet"))))
  withr::local_options(wet.temp_root = dir, .local_envir = env)
  invisible(dir)
}

# Readings every hour of local day `day` at a station `offset` hours from UTC,
# for the hours in `hours` (0-23, local standard time).
temp_rows <- function(station, day, hours = 0:23, value = 10, offset = -8,
                      approval = "Provisional/Provisoire", minute = 0) {
  t <- as.POSIXct(paste(day, "00:00"), tz = "UTC") + hours * 3600 + minute * 60 - offset * 3600
  data.frame(STATION_NUMBER = station, utc = format(t, "%Y-%m-%d %H:%M:%S"),
             Value = value, Approval = approval)
}

local_offsets <- function(offsets = c("08AA001" = -8, "07AA001" = -7), env = parent.frame()) {
  local_mocked_bindings(wet_temp_offsets = function(stations) {
    unname(offsets[stations])
  }, .env = env)
}

test_that("a full hourly day reduces to its mean, min, max and hour count", {
  local_offsets()
  local_temp_archive(temp_rows("08AA001", "2020-07-01", value = 0:23))
  d <- wet_temp_daily("08AA001")
  expect_named(d, c("station_number", "date", "t_mean_c", "t_min_c", "t_max_c", "n_hours",
                    "source", "status"))
  expect_equal(nrow(d), 1)
  expect_equal(d$date, as.Date("2020-07-01"))
  expect_equal(d$t_mean_c, mean(0:23))
  expect_equal(c(d$t_min_c, d$t_max_c), c(0, 23))
  expect_identical(d$n_hours, 24L)
  expect_equal(d$source, "provisional")
  expect_equal(d$status, "provisional")
})

test_that("days are local standard time: a reading at 07:30 UTC is the day before at -8", {
  local_offsets()
  # 23:30 PST on 1 July is 07:30 UTC on 2 July
  r <- rbind(temp_rows("08AA001", "2020-07-01", hours = 0:22),
             data.frame(STATION_NUMBER = "08AA001", utc = "2020-07-02 07:30:00", Value = 99 / 10,
                        Approval = "Provisional/Provisoire"))
  local_temp_archive(r)
  d <- wet_temp_daily("08AA001")
  expect_equal(d$date, as.Date("2020-07-01"))
  expect_identical(d$n_hours, 24L)
  expect_equal(d$t_max_c, 10)
})

test_that("the offset is per station: the same UTC hours fall on different local days", {
  local_offsets()
  # 07:00-07:59 UTC on 2 July: 23:xx on 1 July at -8, 00:xx on 2 July at -7
  r <- rbind(temp_rows("08AA001", "2020-07-02", hours = 0:22),
             temp_rows("07AA001", "2020-07-02", hours = 1:23, offset = -7))
  r <- rbind(r, data.frame(STATION_NUMBER = c("08AA001", "07AA001"), utc = "2020-07-02 07:15:00",
                           Value = 10, Approval = "Provisional/Provisoire"))
  local_temp_archive(r)
  d <- wet_temp_daily(c("08AA001", "07AA001"), min_hours = 23)
  expect_equal(d$station_number, c("07AA001", "08AA001"))
  expect_equal(d$date, as.Date(c("2020-07-02", "2020-07-02")))
  # 08AA001's 07:15 UTC is 23:15 on 1 July, a day of one hour
  expect_identical(d$n_hours, c(24L, 23L))
})

test_that("a day needs readings in min_hours of its hours, and short days are dropped", {
  local_offsets()
  local_temp_archive(rbind(temp_rows("08AA001", "2020-07-01", hours = 0:19),
                           temp_rows("08AA001", "2020-07-02", hours = 0:18)))
  d <- wet_temp_daily("08AA001")
  expect_equal(d$date, as.Date("2020-07-01"))
  expect_identical(d$n_hours, 20L)
  expect_equal(nrow(wet_temp_daily("08AA001", min_hours = 19)), 2)
  expect_warning(e <- wet_temp_daily("08AA001", min_hours = 24), "no water temperature")
  expect_equal(nrow(e), 0)
})

test_that("sentinels and readings outside `valid` are dropped before hours are counted", {
  local_offsets()
  v <- c(rep(12, 20), 99999, -99999, 999, 36)
  local_temp_archive(temp_rows("08AA001", "2020-07-01", value = v))
  d <- wet_temp_daily("08AA001")
  expect_identical(d$n_hours, 20L)
  expect_equal(c(d$t_mean_c, d$t_min_c, d$t_max_c), c(12, 12, 12))
  expect_warning(e <- wet_temp_daily("08AA001", min_hours = 21), "no water temperature")
  expect_equal(nrow(e), 0)
  # widen the range and 36 comes back as a 21st hour
  expect_identical(wet_temp_daily("08AA001", valid = c(-1, 40))$n_hours, 21L)
  # a comma decimal mark must not reach the SQL
  withr::local_options(OutDec = ",")
  expect_identical(wet_temp_daily("08AA001", valid = c(-0.5, 35.5))$n_hours, 20L)
})

test_that("the daily mean weights hours, not readings", {
  local_offsets()
  # hour 0 has four 15-minute readings of 20; the other 23 hours one reading of 8
  r <- rbind(temp_rows("08AA001", "2020-07-01", hours = 1:23, value = 8),
             do.call(rbind, lapply(c(0, 15, 30, 45), function(m) {
               temp_rows("08AA001", "2020-07-01", hours = 0, value = 20, minute = m)
             })))
  local_temp_archive(r)
  d <- wet_temp_daily("08AA001")
  expect_identical(d$n_hours, 24L)
  expect_equal(d$t_mean_c, (20 + 23 * 8) / 24)
  expect_equal(d$t_max_c, 20)
})

test_that("an hour counts with one valid reading, and :02 stamps stay in their hour", {
  local_offsets()
  # hour 0: one valid 15-minute reading and three sentinels; hours 1-23 at :02
  r <- rbind(temp_rows("08AA001", "2020-07-01", hours = 1:23, value = 8, minute = 2),
             temp_rows("08AA001", "2020-07-01", hours = 0, value = 6, minute = 0),
             do.call(rbind, lapply(c(15, 30, 45), function(m) {
               temp_rows("08AA001", "2020-07-01", hours = 0, value = 99999, minute = m)
             })))
  local_temp_archive(r)
  d <- wet_temp_daily(c("08AA001", "08AA001"))
  expect_equal(nrow(d), 1)
  expect_identical(d$n_hours, 24L)
  expect_equal(d$t_min_c, 6)
  expect_equal(d$t_mean_c, (6 + 23 * 8) / 24)
})

test_that("a day is approved only when every reading in it is final", {
  local_offsets()
  local_temp_archive(rbind(
    temp_rows("08AA001", "2020-07-01", approval = "Final/Finales"),
    temp_rows("08AA001", "2020-07-02", approval = c("Final/Finales", rep("1", 23))),
    temp_rows("08AA001", "2020-07-03", approval = "4"),
    temp_rows("08AA001", "2020-07-04", approval = NA_character_)))
  d <- wet_temp_daily("08AA001")
  expect_equal(d$status, c("approved", "provisional", "provisional", "provisional"))
})

test_that("from and to bound the local dates, and stations come back in order", {
  local_offsets()
  days <- as.character(seq(as.Date("2020-06-28"), as.Date("2020-07-03"), by = "day"))
  local_temp_archive(do.call(rbind, c(lapply(days, function(x) temp_rows("08AA001", x)),
                                      lapply(days, function(x) temp_rows("07AA001", x, offset = -7)))))
  d <- wet_temp_daily(c("08AA001", "07AA001"), from = "2020-06-30", to = as.Date("2020-07-01"))
  expect_equal(d$station_number, rep(c("07AA001", "08AA001"), each = 2))
  expect_equal(d$date, rep(as.Date(c("2020-06-30", "2020-07-01")), 2))
  expect_false(is.unsorted(d$date[d$station_number == "08AA001"]))
})

test_that("from and to apply to the local day, not the UTC date", {
  local_offsets()
  # 2020-06-30 00:00-07:59 UTC is still 29 June at UTC-8
  local_temp_archive(rbind(temp_rows("08AA001", "2020-06-29"), temp_rows("08AA001", "2020-06-30")))
  d <- wet_temp_daily("08AA001", from = "2020-06-30")
  expect_equal(d$date, as.Date("2020-06-30"))
  expect_identical(d$n_hours, 24L)
  expect_equal(wet_temp_daily("08AA001", to = "2020-06-29")$date, as.Date("2020-06-29"))
})

test_that("a station with no readings is warned about, and zero rows keep the shape", {
  local_offsets(c("08AA001" = -8, "08ZZ999" = -8))
  local_temp_archive(temp_rows("08AA001", "2020-07-01"))
  expect_warning(d <- wet_temp_daily(c("08AA001", "08ZZ999")),
                 "no water temperature found for: 08ZZ999")
  expect_equal(unique(d$station_number), "08AA001")
  expect_warning(e <- wet_temp_daily("08ZZ999"), "08ZZ999")
  expect_equal(nrow(e), 0)
  expect_named(e, names(d))
  expect_s3_class(e$date, "Date")
  expect_type(e$n_hours, "integer")
})

test_that("a station with no known offset falls back to Pacific standard time, with a warning", {
  local_offsets(c("08AA001" = NA))
  local_temp_archive(temp_rows("08AA001", "2020-07-01"))
  expect_warning(d <- wet_temp_daily("08AA001"), "no time zone for: 08AA001")
  expect_equal(d$date, as.Date("2020-07-01"))
  expect_identical(d$n_hours, 24L)
})

test_that("bad inputs are refused", {
  local_offsets()
  expect_error(wet_temp_daily(character()), "stations")
  expect_error(wet_temp_daily(NA_character_), "stations")
  expect_error(wet_temp_daily("08AA001", from = "2021-01-01", to = "2020-01-01"), "from")
  expect_error(wet_temp_daily("08AA001", valid = 35), "valid")
  expect_error(wet_temp_daily("08AA001", valid = c(35, -1)), "valid")
  expect_error(wet_temp_daily("08AA001", valid = c(NA, 35)), "valid")
  expect_error(wet_temp_daily("08AA001", valid = c(-Inf, 35)), "valid")
  expect_error(wet_temp_daily("08AA001", min_hours = 0), "min_hours")
  expect_error(wet_temp_daily("08AA001", min_hours = 25), "min_hours")
  expect_error(wet_temp_daily("08AA001", min_hours = 20.5), "min_hours")
})

test_that("the daily series feeds wet_window_stats() as an absolute temperature", {
  local_offsets()
  days <- as.character(seq(as.Date("2020-08-01"), as.Date("2020-08-10"), by = "day"))
  local_temp_archive(do.call(rbind, lapply(seq_along(days), function(i) {
    temp_rows("08AA001", days[i], value = i)
  })))
  d <- wet_temp_daily("08AA001")
  w <- data.frame(window = "early_aug", start = "08-01", end = "08-10")
  s <- wet_window_stats(d, w, stats = c("mean", "max"), value = "t_mean_c", prefix = "t",
                        level_anomaly = "absolute", unit = "degC")
  expect_equal(s$variable, c("t_mean", "t_max"))
  expect_equal(s$value, c(5.5, 10))
  expect_equal(unique(s$anomaly_type), "absolute")
  expect_equal(unique(s$unit), "degC")
  expect_equal(unique(s$frac_provisional), 1)
  # no symbol column, so ice is unknown rather than absent
  expect_true(all(is.na(s$frac_ice)))
})

test_that("offsets come from tidyhydat's station table", {
  skip_if_not_installed("tidyhydat")
  expect_equal(wet_temp_offsets(c("08EE013", "07FA004", "08ZZ999")), c(-8, -7, NA))
})

test_that("live: Buck Creek water temperature from the archive", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()
  skip_if_not_installed("duckdb")
  skip_if_not_installed("tidyhydat")
  d <- wet_temp_daily("08EE013", from = "2024-07-01", to = "2024-08-31")
  expect_gt(nrow(d), 50)
  expect_true(all(d$n_hours >= 20))
  expect_true(all(d$t_min_c <= d$t_mean_c & d$t_mean_c <= d$t_max_c))
  expect_true(all(d$t_max_c > 5 & d$t_max_c < 30))
})

test_that("a SQL number is a finite value with a point, whatever OutDec says", {
  withr::local_options(OutDec = ",")
  expect_equal(wet_sql_num(-0.5), "-0.5")
  expect_equal(wet_sql_num(35L), "35")
  expect_error(wet_sql_num(Inf), "finite")
  expect_error(wet_sql_num(NA_real_), "finite")
  expect_error(wet_sql_num(c(1, 2)), "finite")
})
