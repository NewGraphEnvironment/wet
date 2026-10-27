fx <- function() system.file("extdata", "pcic_years", package = "wet")
fx_dir <- function() file.path(fx(), "days")
fx_series <- "synthetic_historical"
fx_weights <- function() {
  w <- utils::read.csv(file.path(fx(), "weights.csv"), colClasses = c(upstream_subids = "character"))
  w$upstream_subids <- lapply(strsplit(w$upstream_subids, ";", fixed = TRUE), as.integer)
  w
}
fx_days <- function() {
  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE))
  d <- DBI::dbGetQuery(duck, sprintf("SELECT * FROM read_parquet('%s') ORDER BY subid, date",
                                     file.path(fx_dir(), "*.parquet")))
  d$year <- as.integer(format(d$date, "%Y"))
  d$month <- as.integer(format(d$date, "%m"))
  d$day <- as.integer(format(d$date, "%d"))
  d
}
# the 1981 file of a copy of the fixture, changed by `f`, in a directory of its own
fx_copy <- function(f) {
  d <- fx_days()
  d <- f(d[d$year == 1981, c("subid", "date", "q_local", "q_acc")])
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE))
  DBI::dbWriteTable(duck, "d", d)
  DBI::dbExecute(duck, sprintf("COPY d TO '%s' (FORMAT parquet)",
                               file.path(dir, sprintf("pcic.subbasin_days.%s.1981.parquet", fx_series))))
  dir
}
routed <- function(dir = fx_dir(), w = fx_weights(), years = 1981) {
  wet_routed_years(dir, w, years = years, series = fx_series)
}

test_that("each segment's day is its routed flow, clamped at 0 and rounded to 5 decimals", {
  skip_if_not_installed("duckdb")
  w <- fx_weights()
  q <- routed(w = w)
  expect_identical(names(q), c("linear_feature_id", "date", "q_m3s"))
  expect_identical(nrow(q), 4L * 365L)
  expect_false(is.unsorted(order(q$linear_feature_id, q$date)))
  d <- fx_days()
  d <- d[d$year == 1981, ]
  by <- function(s, col) d[[col]][d$subid == s]
  # by hand, from the weights: segment 2 is 0.5 of 103's own inflow plus all of 101 and 102
  expect_equal(q$q_m3s[q$linear_feature_id == 2],
               round(pmax(by(101, "q_acc") + by(102, "q_acc") + 0.5 * by(103, "q_local"), 0), 5))
  expect_equal(q$q_m3s[q$linear_feature_id == 1], round(pmax(0.4 * by(101, "q_local"), 0), 5))
  # segment 4 is 104's own inflow alone, which turns negative: clamped
  s4 <- q$q_m3s[q$linear_feature_id == 4]
  expect_true(any(by(104, "q_local") < 0))
  expect_identical(s4, round(pmax(by(104, "q_local"), 0), 5))
  expect_true(all(s4[by(104, "q_local") < 0] == 0))
  expect_identical(q$q_m3s, round(q$q_m3s, 5))
  # the same arithmetic as the daily climatology's routing, on a fold of one year
  fold <- list(subid = c(101L, 102L, 103L, 104L),
               q_local = t(vapply(c(101, 102, 103, 104), by, numeric(365), col = "q_local")),
               q_acc = t(vapply(c(101, 102, 103, 104), by, numeric(365), col = "q_acc")))
  expect_equal(as.vector(t(unclass(wet_routed_days(fold, w)))), q$q_m3s, ignore_attr = TRUE)
})

test_that("a leap year has 29 February, and the years asked are the years returned", {
  skip_if_not_installed("duckdb")
  q <- routed(w = fx_weights()[2, ], years = c(1984, 1990))
  expect_identical(nrow(q), 366L + 365L)
  expect_true(as.Date("1984-02-29") %in% q$date)
  expect_identical(sort(unique(format(q$date, "%Y"))), c("1984", "1990"))
})

test_that("the fixture's years average to its climatology, bin by bin", {
  skip_if_not_installed("duckdb")
  d <- fx_days()
  d <- d[d$year %in% 1951:2012, ]
  cl <- utils::read.csv(file.path(fx(), "climatology.csv"))
  m <- stats::aggregate(cbind(q_local, q_acc) ~ subid + month + day, d, mean)
  m <- merge(m, cl, by = c("subid", "month", "day"), suffixes = c("", "_cl"))
  expect_identical(nrow(m), 4L * 366L)
  expect_equal(m$q_local, m$q_local_cl, tolerance = 1e-12)
  expect_equal(m$q_acc, m$q_acc_cl, tolerance = 1e-12)
})

test_that("a segment the clamp never touches averages over years to its routed climatology", {
  skip_if_not_installed("duckdb")
  w <- fx_weights()[2, ]
  q <- routed(w = w, years = 1951:2012)
  cl <- utils::read.csv(file.path(fx(), "climatology.csv"))
  clim <- wet_routed_days(wet_routed_fold(cl), w)
  md <- format(q$date, "%m-%d")
  keep <- md != "02-29" & md != "02-28"  # the fold puts 29 February into 28 February
  ym <- tapply(q$q_m3s[keep], md[keep], mean)
  cm <- stats::setNames(as.vector(clim), wet_doy_md())[names(ym)]
  # each day is rounded to 5 decimals before the mean, the climatology once
  expect_lt(max(abs(ym - cm)), 1e-5)
})

test_that("it refuses incomplete, repeated or misplaced days, and a missing year", {
  skip_if_not_installed("duckdb")
  w <- fx_weights()
  gone <- function(d) d[!(d$subid == 102 & d$date == as.Date("1981-06-01")), ]
  expect_error(routed(fx_copy(gone)), "lack days.*102")
  twice <- function(d) rbind(d, d[d$subid == 103 & d$date == as.Date("1981-02-23"), ])
  expect_error(routed(fx_copy(twice)), "more than once")
  elsewhere <- function(d) {
    d$date[d$subid == 101 & d$date == as.Date("1981-12-31")] <- as.Date("1982-01-01")
    d
  }
  expect_error(routed(fx_copy(elsewhere)), "outside the years")
  na_flow <- function(d) {
    d$q_acc[d$subid == 104][10] <- NA
    d
  }
  expect_error(routed(fx_copy(na_flow)), "NA value")
  w9 <- w
  w9$upstream_subids[[3]] <- c(103L, 999L)
  expect_error(routed(w = w9), "no rows .* 999")
  expect_error(routed(years = 2013), "no synthetic_historical file for 2013")
  expect_error(routed(years = 1980:1981, dir = fx_copy(identity)), "file for 1980$")
  expect_error(routed(w = rbind(w, w)), "each segment once")
  wna <- w
  wna$upstream_subids[[2]] <- c(101L, NA)
  expect_error(routed(w = wna), "NA subid")
  expect_error(wet_routed_years(fx_dir(), w, years = 1981), "no PNWNAmet_historical file")
  expect_error(routed(dir = file.path(fx(), "nowhere")), "existing directory")
})
