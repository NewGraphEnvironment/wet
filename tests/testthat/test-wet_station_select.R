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

test_that("wet_hydat_release reads the release date as YYYYMMDD", {
  version_db <- function(dates) {
    p <- withr::local_tempfile(fileext = ".sqlite3", .local_envir = parent.frame())
    con <- DBI::dbConnect(RSQLite::SQLite(), p)
    if (length(dates)) DBI::dbWriteTable(con, "VERSION", data.frame(Version = "1.0", Date = dates))
    DBI::dbDisconnect(con)
    p
  }
  expect_equal(wet:::wet_hydat_release(version_db("2026-07-17 08:08:08")), "20260717")
  expect_equal(wet:::wet_hydat_release(version_db("2025-10-14 15:09:54.000")), "20251014")
  # two releases in one file, or none, cannot name a fit
  expect_error(wet:::wet_hydat_release(version_db(c("2025-10-14", "2026-07-17"))), "one release date")
  expect_error(wet:::wet_hydat_release(version_db(character())), "no VERSION table")
})
