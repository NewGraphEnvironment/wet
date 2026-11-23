test_that("a Tool CSV's discharge rows are read, its other series and blank values left out", {
  s <- local_bcwatertool_cache()
  r <- wet_bcwatertool_read(file.path(s$dir, "101.csv"), "101")
  expect_equal(r$q$date, as.Date(c("2020-06-01", "2020-06-02", "2020-06-04", "2020-06-05", "2020-06-06")))
  expect_equal(r$q$q_m3s, c(2, 3, -1, 1e6, 4))
  expect_equal(r$q$qa, c("1", "0", "1", "1", "1"))
  expect_true(all(r$q$id == "101"))
  expect_equal(r$meta[["Name"]], "Alpha Creek")
  expect_equal(wet_bcwatertool_credit(r$meta), "Data from Test District. https://example.org/.")
})

test_that("a value, unit, QA, date or day the reader does not know is refused, not read", {
  f <- withr::local_tempfile(fileext = ".csv")
  refuse <- function(row, msg) {
    writeLines(bcwatertool_fixture_lines(c("Preliminary Discharge,2020-06-01,2,m3/s,1", row)), f)
    expect_error(wet_bcwatertool_read(f, "1"), msg)
  }
  refuse("Preliminary Discharge,2020-06-02,abc,m3/s,1", "not a finite number")
  refuse("Preliminary Discharge,2020-06-02,NaN,m3/s,1", "not a finite number")
  refuse("Preliminary Discharge,2020-06-02,2000,l/s,1", "unit is not m3/s")
  refuse("Preliminary Discharge,2020-06-02,2,m3/s,2", "QA is not 0 or 1")
  refuse("Preliminary Discharge,2020/06/02,2,m3/s,1", "YYYY-MM-DD")
  refuse("Preliminary Discharge,2020-06-01,3,m3/s,1", "two discharge values for one day")
  # a stage row is never checked as discharge
  writeLines(bcwatertool_fixture_lines(c("Primary Water Level,2020-06-01,2,m,7")), f)
  expect_equal(nrow(wet_bcwatertool_read(f, "1")$q), 0)
  writeLines(c("# Name,x", "", "Date,Value", "2020-06-01,2"), f)
  expect_error(wet_bcwatertool_read(f, "1"), "not a Water Tool CSV")
})

test_that("the shipped rules: QA gives status, a negative day and a day above the bound are dropped", {
  s <- local_bcwatertool_cache()
  d <- wet_bcwatertool_daily("TST1", cache_dir = s$cache)
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_equal(d$date, as.Date(c("2020-06-01", "2020-06-02", "2020-06-06")))
  expect_equal(d$q_m3s, c(2, 3, 4))
  expect_equal(d$status, c("provisional", "unchecked", "provisional"))
  expect_true(all(d$source == "bcwatertool") && all(is.na(d$symbol)))
  # the cap is the sub-drainage's ratio times the median positive flow (3): 08H's 268.07 drops 1e6,
  # and with no bound it stays
  expect_equal(nrow(wet_bcwatertool_daily("TST1", bound = Inf, cache_dir = s$cache)), 4)
  expect_error(wet_bcwatertool_daily("TST1", bound = c(`08H` = 2), cache_dir = s$cache), "\\.default")
  expect_error(wet_bcwatertool_daily("NOPE", cache_dir = s$cache), "not in the Water Tool's station registry")
})

test_that("the sub-drainage comes from the registry, not the number", {
  d <- data.frame(station_number = "X", date = as.Date("2020-01-01") + 0:2, q_m3s = c(1, 1, 50), qa = "1")
  # 08C's bound is 39.34: 50 is above 39.34 x 1; the province-wide 2,490.71 keeps it
  expect_equal(nrow(wet_bcwatertool_shape(d, c(X = "08C"), wet_bcenv_bound)), 2)
  expect_equal(nrow(wet_bcwatertool_shape(d, c(X = "99Z"), wet_bcenv_bound)), 3)
})

test_that("a cached file that is not the manifest's is refused, a missing one is never fetched", {
  s <- local_bcwatertool_cache()
  expect_equal(basename(wet_bcwatertool(c("101", "103"), cache_dir = s$cache)), c("101.csv", NA))
  expect_error(wet_bcwatertool("999", cache_dir = s$cache), "holds no listing 999")
  writeLines(bcwatertool_fixture_lines(sub("2.0", "9.0", bcwatertool_fixture_101, fixed = TRUE)),
             file.path(s$dir, "101.csv"))
  expect_error(wet_bcwatertool("101", cache_dir = s$cache), "md5 .* not the manifest's")
  writeLines("short", file.path(s$dir, "101.csv"))
  expect_error(wet_bcwatertool("101", cache_dir = s$cache), "bytes, not the manifest's")
  unlink(file.path(s$dir, "102.csv"))
  local_mocked_bindings(curl_download = function(...) stop("network"), curl_fetch_disk = function(...) stop("network"),
                        .package = "curl")
  err <- expect_error(wet_bcwatertool("102", cache_dir = s$cache), class = "wet_bcwatertool_unavailable")
  expect_s3_class(err, "wet_snapshot_unavailable")
  expect_match(conditionMessage(err), "s3://fresh-bc/station_sources/bcwatertool/20261028/", fixed = TRUE)
  expect_match(conditionMessage(err), "102.csv")
})

test_that("the provincial source's unavailable error shares the parent class", {
  err <- expect_error(wet_bcenv_unavailable("gone"), class = "wet_bcenv_unavailable")
  expect_s3_class(err, "wet_snapshot_unavailable")
  expect_false(inherits(err, "wet_bcwatertool_unavailable"))
})

test_that("the manifest validator wants the station list and one row per listing", {
  f <- withr::local_tempfile(fileext = ".csv")
  local_mocked_bindings(wet_bcwatertool_manifest_path = function(snapshot) f)
  ok <- data.frame(file = c("1.csv", "2.csv.status", "bcwatertool_streamflow_stations_20261028.geojson"),
                   bytes = 1, md5 = strrep("a", 32))
  utils::write.csv(ok, f, row.names = FALSE)
  expect_equal(nrow(wet_bcwatertool_manifest("20261028")), 3)
  bad <- function(x) {
    utils::write.csv(x, f, row.names = FALSE)
    expect_error(wet_bcwatertool_manifest("20261028"), "one row per listing")
  }
  bad(ok[-3, ])                                                  # no station list
  bad(transform(ok, file = c("1.csv", "x.csv", ok$file[3])))      # a name of another shape
  bad(transform(ok, file = c("1.csv", "1.csv.status", ok$file[3])))  # one listing twice
  bad(transform(ok, md5 = c(NA, ok$md5[-1])))
})

test_that("the tracked manifest and registry of the pinned snapshot hold their shape", {
  man <- wet_bcwatertool_manifest(wet_bcwatertool_snapshot)
  expect_equal(nrow(man), 392)
  expect_equal(sum(grepl("[.]status$", man$file)), 2)
  reg <- wet_bcwatertool_stations()
  expect_equal(nrow(reg), 53)
  expect_equal(sum(!is.na(reg$continues)), 7)
  expect_setequal(reg$station_number[!is.na(reg$continues)], c("2601", "2602", "2603", "2604", "4601", "4602", "4603"))
  expect_false(any(grepl(wet_hydat_number, reg$station_number)))
  expect_length(intersect(reg$station_number, wet_bcenv_stations(wet_bcenv_snapshot)$station_number), 0)
  expect_true(all(reg$continues[!is.na(reg$continues)] %in% wet_bcenv_stations(wet_bcenv_snapshot)$station_number))
  expect_true(all(grepl("^[0-9]{2}[A-Z]$", reg$subdrainage)))
  # a continuing listing's days are those before its provincial record begins: none at Tofino, where the
  # listings are the same gauges, and 2012-2015 at BC Conservation Foundation's three
  cont <- reg[!is.na(reg$continues), ]
  expect_false(anyNA(cont$continues_before))
  expect_true(all(is.na(cont$first) | cont$last < cont$continues_before))
  expect_setequal(cont$station_number[!is.na(cont$first)], c("4601", "4602", "4603"))
  expect_true(all(is.na(reg$continues_before[is.na(reg$continues)])))
  expect_false(any(grepl("Any reliance", reg$credit)))
  expect_error(wet_bcwatertool_manifest("19000101"), "no tracked manifest")
})

test_that("live: the pinned Tool snapshot in this machine's cache holds the manifest's files", {
  reg <- wet_bcwatertool_stations()
  f <- tryCatch(wet_bcwatertool(reg$id), wet_snapshot_unavailable = function(e) skip(conditionMessage(e)))
  expect_false(anyNA(f))
  d <- wet_bcwatertool_daily(reg$station_number)
  # a continuing listing's registry days are those before its provincial record begins
  cut <- reg$continues_before[match(d$station_number, reg$station_number)]
  d <- d[is.na(cut) | d$date < cut, ]
  expect_setequal(unique(d$station_number), reg$station_number[!is.na(reg$first)])
  rng <- lapply(split(d$date, d$station_number), range)
  expect_equal(unname(vapply(rng, `[`, 0, 1)), as.numeric(reg$first[match(names(rng), reg$station_number)]))
  expect_equal(unname(vapply(rng, `[`, 0, 2)), as.numeric(reg$last[match(names(rng), reg$station_number)]))
})
