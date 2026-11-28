# The pin (#235): manifest shape, md5s, fetching only where allowed.

pin_readings <- function() logger_readings("01XX001", "2020-07-01 08:00", 96, 12)

test_that("a cached file and its members are held to the manifest", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  expect_equal(wet_logger("tst", "1", "01_Data.zip"), fx$zip)
  p <- wet_logger_members("tst", "1", "01_Data.zip/01_Data/01XX001_Site.csv")
  expect_true(file.exists(p))
  expect_equal(unname(tools::md5sum(p)), fx$manifest$md5[2])
})

test_that("a file whose bytes differ from the manifest is refused", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  cat("x", file = fx$zip, append = TRUE)
  expect_error(wet_logger("tst", "1", "01_Data.zip"), "not the manifest's")
})

test_that("a member whose md5 differs from the manifest is refused", {
  fx <- logger_fixture(pin_readings())
  man <- fx$manifest
  man$md5[2] <- strrep("0", 32)
  utils::write.csv(man, file.path(fx$ext, "tst_1.csv"), row.names = FALSE, na = "")
  local_logger_fixture(fx)
  expect_error(wet_logger_members("tst", "1", "01_Data.zip/01_Data/01XX001_Site.csv"), "not the manifest's")
})

test_that("a missing file with fetch FALSE is never requested", {
  fx <- logger_fixture(pin_readings(), fetch = FALSE)
  local_logger_fixture(fx)
  asked <- FALSE
  local_mocked_bindings(curl_download = function(...) {
    asked <<- TRUE
    stop("network")
  }, .package = "curl")
  unlink(fx$zip)
  expect_error(wet_logger("tst", "1", "01_Data.zip"), class = "wet_logger_unavailable")
  expect_error(wet_logger("tst", "1", "01_Data.zip"), "wet does not fetch it.*s3://fresh-bc/temp_loggers/tst/1/")
  expect_false(asked)
})

test_that("a missing file with fetch TRUE is fetched, and a failed fetch is classed", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  keep <- file.path(fx$dir, "keep.zip")
  file.copy(fx$zip, keep)
  unlink(fx$zip)
  expect_error(suppressMessages(wet_logger("tst", "1", "01_Data.zip")), class = "wet_logger_unavailable")
  local_mocked_bindings(curl_download = function(url, destfile, ...) {
    expect_match(url, "/records/1/")
    file.copy(keep, destfile, overwrite = TRUE)
  }, .package = "curl")
  expect_message(p <- wet_logger("tst", "1", "01_Data.zip"), "once per machine")
  expect_equal(unname(tools::md5sum(p)), fx$manifest$md5[1])
})

test_that("a fetched file with the wrong md5 is refused and not kept", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  unlink(fx$zip)
  local_mocked_bindings(curl_download = function(url, destfile, ...) {
    writeLines(strrep("x", 10), destfile)
  }, .package = "curl")
  expect_error(suppressMessages(wet_logger("tst", "1", "01_Data.zip")), "not the manifest's")
  expect_false(file.exists(fx$zip))
})

test_that("a manifest whose URL is not its record's, or of the wrong shape, is refused", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  path <- file.path(fx$ext, "tst_1.csv")
  bad <- function(man) {
    utils::write.csv(man, path, row.names = FALSE, na = "")
    expect_error(wet_logger_manifest("tst", "1"), "is not a list of files")
  }
  man <- fx$manifest
  bad(transform(man, url = sub("/records/1/", "/records/2/", url)))
  bad(transform(man, fetch = c(NA, NA)))
  bad(transform(man, url = c(man$url[1], man$url[1])))
  bad(man[2, ])
  bad(transform(man, md5 = c("abc", man$md5[2])))
  bad(rbind(man, man[2, ]))
  utils::write.csv(man, path, row.names = FALSE, na = "")
  expect_error(wet_logger_manifest("tst", "1a"), "digits only")
  expect_error(wet_logger_manifest("TST", "1"), "lower-case")
  expect_error(wet_logger_manifest("tst", "2"), "no tracked manifest")
  expect_error(wet_logger("tst", "1", "other.zip"), "not a file of tst 1")
})

test_that("the registry holds one row per site, each id the series' own", {
  fx <- logger_fixture(rbind(pin_readings(), logger_readings("01XX002", "2020-07-01 08:00", 4, 10)))
  local_logger_fixture(fx)
  s <- wet_logger_sites("tst")
  expect_equal(s$station_number, c("TST_01XX001", "TST_01XX002"))
  path <- file.path(fx$ext, "tst_1_sites.csv")
  bad <- function(reg) {
    utils::write.csv(reg, path, row.names = FALSE, na = "")
    expect_error(wet_logger_sites("tst"), "does not hold one row per site")
  }
  reg <- fx$registry
  bad(transform(reg, station_number = c("TST_01XX001", "TST_01XX001")))
  bad(transform(reg, station_number = c("08EE013", "TST_01XX002")))
  bad(transform(reg, subdrainage = c("08J", NA)))
  bad(transform(reg, subdrainage = c("08", "08J")))
  bad(transform(reg, record = "2"))
  bad(reg[, -2])
})

test_that("the shipped Nechako manifests and registry pass their own checks", {
  for (v in c("15053907", "6426024")) {
    man <- wet_logger_manifest("nhg", v)
    expect_true(all(grepl("^https://zenodo.org/records/", man$url[!is.na(man$url)])))
    expect_true(all(man$fetch[!is.na(man$fetch)]))
  }
  s <- wet_logger_sites("nhg")
  expect_equal(nrow(s), 32L)
  expect_true(all(grepl("^NHG_[0-9]{2}[A-Z]{2}[0-9]{3}$", s$station_number)))
  expect_false(any(grepl(wet_hydat_number, s$station_number)))
  man <- wet_logger_manifest("nhg", "15053907")
  expect_true(all(s$member %in% man$file))
  expect_true(all(stats::na.omit(s$prior_member) %in% wet_logger_manifest("nhg", "6426024")$file))
})

# ---- readings to days (#235) ----------------------------------------------------------------

# 15-minute readings from local standard midnight of `day` (UTC-8) for `days` days: `base`
# plus a daily sine of half-range `amp`, rounded to 0.01 degC as the Nechako files are.
diurnal <- function(code, day, days, base = 12, amp = 2, flag = "P") {
  n <- days * 96
  k <- seq_len(n) - 1
  data.frame(code = code, time = as.POSIXct(paste(day, "08:00"), tz = "UTC") + k * 900,
             t = round(base + amp * sin(2 * pi * k / 96), 2), flag = flag)
}
as_read <- function(x) data.frame(time = x$time, t = x$t, flag = x$flag, pass = x$flag %in% c("P", "A"))
day_drop <- function(d, day) d$drop[d$date == as.Date(day)]

test_that("a deployment's days are means of hourly means, its first and last days dropped", {
  r <- as_read(diurnal("A", "2020-07-01", 4))
  d <- wet_logger_days(r)
  expect_equal(format(d$date), c("2020-07-01", "2020-07-02", "2020-07-03", "2020-07-04"))
  expect_equal(d$drop, c("deployment", NA, NA, "deployment"))
  k <- d[d$date == as.Date("2020-07-02"), ]
  local_sec <- as.numeric(r$time) - 8 * 3600
  on_day <- r[local_sec %/% 86400 == as.numeric(as.Date("2020-07-02")), ]
  hourly <- tapply(on_day$t, (as.numeric(on_day$time) - 8 * 3600) %/% 3600, mean)
  expect_equal(k$t_mean_c, mean(hourly))
  expect_equal(c(k$t_min_c, k$t_max_c), range(on_day$t))
  expect_equal(k$n_hours, 24L)
  expect_equal(k$n_flagged, 0L)
})

test_that("a gap over 6 hours splits deployments; one of 6 hours does not", {
  a <- diurnal("A", "2020-07-01", 6)
  utc <- function(x) as.POSIXct(x, tz = "UTC")
  split7 <- a[!(a$time >= utc("2020-07-04 02:00") & a$time < utc("2020-07-04 09:00")), ]
  d <- wet_logger_days(as_read(split7), min_hours = 1)
  expect_equal(day_drop(d, "2020-07-03"), "deployment")
  expect_equal(day_drop(d, "2020-07-04"), "deployment")
  split6 <- a[!(a$time > utc("2020-07-04 02:00") & a$time < utc("2020-07-04 08:00")), ]
  d <- wet_logger_days(as_read(split6), min_hours = 1)
  expect_true(is.na(day_drop(d, "2020-07-03")))
  expect_true(is.na(day_drop(d, "2020-07-04")))
})

test_that("a stuck run over 154 hours in open water is dropped; 154 hours, ice and October are kept", {
  stuck <- function(day, hours, value, days = 12) {
    a <- diurnal("A", day, days)
    i <- seq_len(hours * 4) + 3 * 96
    a$t[i] <- value
    wet_logger_days(as_read(a))
  }
  d <- stuck("2020-07-01", 160, 8)
  expect_true(all(c("2020-07-05", "2020-07-06", "2020-07-07", "2020-07-08", "2020-07-09") %in%
                    format(d$date[d$drop %in% "stuck"])))
  expect_true(is.na(day_drop(d, "2020-07-03")))
  d <- stuck("2020-07-01", 154, 8)
  expect_false(any(d$drop %in% "stuck"))
  d <- stuck("2020-07-01", 200, 0.3)
  expect_false(any(d$drop %in% "stuck"))
  d <- stuck("2020-01-01", 300, 0, days = 18)
  expect_false(any(d$drop %in% "stuck"))
  d <- stuck("2020-10-01", 200, 8)
  expect_false(any(d$drop %in% "stuck"))
})

test_that("an open-water day whose range exceeds its month's threshold is an air day", {
  hot <- diurnal("A", "2020-07-01", 5, amp = 8.6)
  d <- wet_logger_days(as_read(hot))
  expect_true(all(d$drop[!d$drop %in% "deployment"] == "air"))
  warm <- diurnal("A", "2020-07-01", 5, amp = 8.2)
  d <- wet_logger_days(as_read(warm))
  expect_true(all(is.na(d$drop[!d$drop %in% "deployment"])))
  nov <- diurnal("A", "2020-11-01", 5, amp = 10)
  d <- wet_logger_days(as_read(nov))
  expect_false(any(d$drop %in% "air"))
})

test_that("a day short of min_hours is dropped for hours; the holder's flags are counted, not used", {
  a <- diurnal("A", "2020-07-01", 5, flag = "P")
  utc <- function(x) as.POSIXct(x, tz = "UTC")
  i <- which(a$time >= utc("2020-07-03 08:00") & a$time < utc("2020-07-03 13:00"))
  a$t[i] <- NA
  a$flag[i] <- "M"
  s <- which(a$time >= utc("2020-07-04 08:00"))[1:3]
  a$flag[s] <- "S"
  d <- wet_logger_days(as_read(a))
  expect_equal(day_drop(d, "2020-07-03"), "hours")
  expect_equal(d$n_hours[d$date == as.Date("2020-07-03")], 19L)
  expect_true(is.na(day_drop(d, "2020-07-04")))
  expect_equal(d$n_flagged[d$date == as.Date("2020-07-04")], 3L)
})

test_that("readings outside `valid` are dropped before anything else", {
  a <- diurnal("A", "2020-07-01", 5)
  a$t[a$time >= as.POSIXct("2020-07-03 08:00", tz = "UTC") &
        a$time < as.POSIXct("2020-07-04 08:00", tz = "UTC")] <- -22.74
  d <- wet_logger_days(as_read(a))
  expect_false(as.Date("2020-07-03") %in% d$date)
  expect_equal(day_drop(d, "2020-07-02"), "deployment")
  expect_equal(nrow(wet_logger_days(as_read(a[a$t < -20, ]))), 0L)
})

test_that("a logger file in another format, or with a bad or repeated time, is refused", {
  f <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("a,b,c,d", "x,2020-07-01 00:00,1,P"), f)
  expect_error(wet_logger_read(f), "not a logger file in a format wet reads")
  head <- "\"station_code\",\"timestamp (UTC)\",\"wtmp (°C)\",\"wtmp_flag\""
  writeLines(c(head, "x,2020-07-01T00:00,1,P"), f, useBytes = TRUE)
  expect_error(wet_logger_read(f), "not YYYY-MM-DD HH:MM")
  writeLines(c(head, "x,2020-07-01 00:00,1,P", "x,2020-07-01 00:00,2,P"), f, useBytes = TRUE)
  expect_error(wet_logger_read(f), "two readings at")
  writeLines(c(head, "x,2020-07-01 00:00,abc,P"), f, useBytes = TRUE)
  expect_error(wet_logger_read(f), "not a number")
  writeLines(c(head, "x,2020-07-01 00:00,NA,M", "x,2020-07-01 00:15,1.5,A"), f, useBytes = TRUE)
  r <- wet_logger_read(f)
  expect_equal(r$t, c(NA, 1.5))
  expect_equal(r$pass, c(FALSE, TRUE))
})

test_that("the threshold constants are the report's shipped values", {
  report <- test_path("..", "..", "data", "checks", "temp_logger_thresholds.txt")
  skip_if_not(file.exists(report), "the threshold report is not beside the source tree")
  x <- readLines(report)
  air <- x[grepl("^  wet_logger_air_c   = c\\(", x)]
  vals <- as.numeric(regmatches(air, gregexpr("(?<= = )[0-9.]+", air, perl = TRUE))[[1]])
  mon <- as.integer(regmatches(air, gregexpr("(?<=`)[0-9]+(?=`)", air, perl = TRUE))[[1]])
  expect_equal(stats::setNames(vals, mon), wet_logger_air_c)
  stuck <- x[grepl("^  wet_logger_stuck_h = ", x)]
  expect_equal(as.numeric(sub(".*= ", "", stuck)), wet_logger_stuck_h)
  expect_equal(wet_logger_months, 5:9)
})

# ---- wet_temp_daily() routing ---------------------------------------------------------------

routing_fixture <- function(env = parent.frame()) {
  fx <- logger_fixture(rbind(diurnal("01XX001", "2020-07-01", 4), diurnal("01XX002", "2020-07-01", 4)),
                       dir = withr::local_tempdir(.local_envir = env))
  local_logger_fixture(fx, env = env)
  fx
}

test_that("a registry id is read from its logger series and never reaches the ECCC archive", {
  routing_fixture()
  local_mocked_bindings(wet_temp_eccc = function(...) stop("the ECCC branch was called"))
  d <- wet_temp_daily(c("TST_01XX002", "TST_01XX001"), from = "2020-01-01")
  expect_named(d, c("station_number", "date", "t_mean_c", "t_min_c", "t_max_c", "n_hours", "source", "status"))
  expect_equal(d$station_number, rep(c("TST_01XX001", "TST_01XX002"), each = 2))
  expect_equal(format(d$date), rep(c("2020-07-02", "2020-07-03"), 2))
  expect_equal(unique(d$source), "tst")
  expect_equal(unique(d$status), "provisional")
  expect_equal(nrow(wet_temp_daily("TST_01XX001", from = "2020-07-03", to = "2020-07-03")), 1L)
})

test_that("every other id goes to the ECCC archive unchanged, HYDAT-shaped or not", {
  routing_fixture()
  asked <- NULL
  local_mocked_bindings(wet_temp_eccc = function(stations, ...) {
    asked <<- stations
    wet_temp_empty()
  })
  expect_warning(wet_temp_daily(c("08NHX18", "TST_01XX001", "08AA001")), "no water temperature found for: 08NHX18")
  expect_equal(asked, c("08NHX18", "08AA001"))
})

test_that("sources limits what is read, and a bad value is refused", {
  routing_fixture()
  local_mocked_bindings(wet_temp_eccc = function(...) stop("the ECCC branch was called"))
  expect_warning(d <- wet_temp_daily(c("TST_01XX001", "08AA001"), sources = "tst"),
                 "no water temperature found for: 08AA001$")
  expect_equal(unique(d$station_number), "TST_01XX001")
  local_mocked_bindings(wet_temp_eccc = function(...) wet_temp_empty())
  expect_warning(d <- wet_temp_daily("TST_01XX001", sources = "provisional"), "no water temperature found")
  expect_equal(nrow(d), 0L)
  expect_named(d, names(wet_temp_empty()))
  expect_error(wet_temp_daily("TST_01XX001", sources = "nope"), "`sources` must name one or more of")
  expect_error(wet_temp_daily("TST_01XX001", sources = character()), "`sources` must name")
})

test_that("a logger series that cannot be read is skipped with a warning", {
  fx <- routing_fixture()
  local_mocked_bindings(wet_temp_eccc = function(...) wet_temp_empty())
  cat("x", file = fx$zip, append = TRUE)
  w <- character()
  d <- withCallingHandlers(wet_temp_daily("TST_01XX001"), warning = function(c) {
    w <<- c(w, conditionMessage(c))
    invokeRestart("muffleWarning")
  })
  expect_match(w, "source \"tst\" skipped: .*not the manifest's", all = FALSE)
  expect_equal(nrow(d), 0L)
})

test_that("a site whose every day is dropped returns zero rows of the shape", {
  fx <- logger_fixture(diurnal("01XX001", "2020-07-01", 2))
  local_logger_fixture(fx)
  d <- wet_logger_daily("TST_01XX001")
  expect_equal(nrow(d), 0L)
  expect_identical(lapply(d, class), lapply(wet_temp_empty(), class))
  expect_error(wet_logger_daily("TST_09XX009"), "not in a logger registry")
})

test_that("a logger series pools with its sub-drainage's stations in the fill and gives GSDD", {
  s <- sim_temp_fill(sim_pars(c(1, 1, 1)))
  logger <- "TST_01XX001"
  s$temp$station_number[s$temp$station_number == "08AA003"] <- logger
  s$temp$source[s$temp$station_number == logger] <- "tst"
  s$air$id[s$air$id == "08AA003"] <- logger
  reg <- data.frame(station_number = logger, subdrainage = "08A")
  ids <- unique(s$temp$station_number)
  pool <- stats::setNames(ifelse(ids %in% reg$station_number, reg$subdrainage[match(ids, reg$station_number)],
                                 substr(ids, 1, 3)), ids)
  expect_equal(unname(pool[logger]), "08A")
  gap <- s$temp$station_number == logger & s$temp$date >= as.Date("2019-06-01") &
    s$temp$date <= as.Date("2019-06-20")
  f <- wet_temp_fill(s$temp[!gap, ], s$air, pool = pool)
  filled <- f[f$station_number == logger & f$date >= as.Date("2019-06-01") & f$date <= as.Date("2019-06-20"), ]
  expect_equal(nrow(filled), 20L)
  expect_true(all(!is.na(filled$t_mean_c)))
  g <- wet_temp_gsdd(f[f$station_number == logger, ])
  expect_true(all(g$station_number == logger))
  expect_true(any(is.finite(g$value)))
})
