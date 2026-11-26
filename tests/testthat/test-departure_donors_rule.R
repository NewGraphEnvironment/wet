# #211's rule (scripts/departure_donors_rule.R), registered before
# scripts/departure_donors.R or any score existed. scripts/ is not shipped, so
# these run under devtools::test() only.
dd_env <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "departure_donors_rule.R"), envir = e)
  e
}

long <- function(id, years, value, variable = "q_mean", period = "migration") {
  data.frame(station_number = id, variable = variable, period = period, year = years, value = value)
}

test_that("dd_box centres a 3.8 by 2.2 degree box on the gauge, as Swift's row", {
  e <- dd_env()
  b <- e$dd_box(-119.2667, 52.83833)   # 08KA012
  expect_equal(unname(b), c(-121.17, -117.37, 51.74, 53.94))
  expect_true(e$dd_in_box(-121.17, 53.94, b))      # bounds inclusive
  expect_false(e$dd_in_box(-121.171, 52, b))
  expect_false(e$dd_in_box(NA, 52, b))
})

test_that("dd_pools are the site script's box, extension and departure pools", {
  e <- dd_env()
  ws <- rbind(long("A", 1961:2000, 1), long("B", c(1990, 1992, 1994), 1), long("C", 1981:1982, 1),
              long("D", c(1981:2004, seq(2006, 2018, 2)), 1),   # 31 years, a 24-year run
              long("E", c(seq(1971, 2029, 2)), 1),               # 30 years, no run of 5
              long("A", 1981:1990, c(0, rep(1, 9)), "q_min7"))
  p <- e$dd_pools(ws, c("A", "B", "C", "D", "E"))
  expect_equal(p$box, c("A", "B", "D", "E"))
  expect_equal(p$ext, c("A", "D"))
  expect_equal(p$dep("q_mean", "migration"), c("A", "D", "E"))
  expect_equal(p$dep("q_min7", "migration"), character())   # one value of 0: 9 usable
})

test_that("dd_candidate keeps natural stations in the box, with an area and 3 years, not at g's site", {
  e <- dd_env()
  b <- e$dd_box(-126, 54)
  st <- data.frame(station_number = paste0("S", 1:8),
                   regulation = c("natural", "regulated", "unknown", "natural", "natural", "natural", "natural", NA),
                   lon = c(-126, -126, -126, -130, -126, -126, -126, -126),
                   lat = 54, drainage_area_gross_km2 = c(100, 100, 100, 100, NA, 100, 0, 100),
                   hydat_site = c(NA, NA, NA, NA, NA, "G1", NA, NA),
                   n_mig = c(3, 3, 3, 3, 3, 3, 3, 3))
  expect_equal(e$dd_candidate(st, "G1", b), c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE))
  expect_equal(e$dd_candidate(st, "G2", b)[6], TRUE)     # another gauge's site is fine
  st$n_mig <- c(2, NA, 3, 3, 3, 3, 3, 3)
  expect_false(e$dd_candidate(st, "G1", b)[1])
  expect_false(e$dd_candidate(transform(st[1, ], n_mig = NA), "G1", b))
  expect_false(e$dd_candidate(transform(st[1, ], lon = NA_real_, n_mig = 3), "G1", b))
})

test_that("dd_fit_years are usable values through 2024 only", {
  e <- dd_env()
  expect_equal(e$dd_fit_years(2020:2026, c(1, NA, 0, 2, 3, 4, 5), "q_mean"), c(2020L, 2023L, 2024L))
  expect_equal(e$dd_fit_years(2023:2026, c(-1, 0, 3, 4), "q_cov_day"), c(2023L, 2024L))
  expect_equal(e$dd_fit_years(2025:2026, c(1, 2), "q_mean"), integer(0))
})

test_that("dd_baseline_rows keeps observed rows and extended rows inside the baseline only", {
  e <- dd_env()
  obs <- long("S", 2016:2026, c(0, 2:11))   # 2016 not usable
  ext <- rbind(
    transform(long("S", 2017:2024, 2:9), lower = NA, upper = NA, donor = NA, source = "observed"),
    transform(long("S", c(1975:2016, 2030), 1), lower = NA, upper = NA, donor = "H", source = "extended"))
  r <- e$dd_baseline_rows(obs, ext)
  expect_equal(r$year[r$source == "observed"], 2017:2026)
  expect_true(all(r$year[r$source == "extended"] %in% 1981:2010))   # fails if the baseline filter goes
  expect_equal(r$year[r$source == "extended"], 1981:2010)
  expect_false(any(r$year %in% c(1975, 2016, 2030)))
  expect_equal(anyDuplicated(r[c("station_number", "year")]), 0L)
  # an observed baseline year is not extended again
  r2 <- e$dd_baseline_rows(rbind(obs, long("S", 1990, 5)), ext)
  expect_equal(sum(r2$year == 1990), 1L)
  expect_equal(r2$source[r2$year == 1990], "observed")
  expect_equal(r2$value[r2$year == 1990], 5)
  # fewer than 10 baseline values: nothing
  ext9 <- ext[ext$source == "observed" | ext$year %in% 1981:1989, ]
  expect_equal(nrow(e$dd_baseline_rows(obs, ext9)), 0L)
})

test_that("dd_scored_years need g observed, both carries and a station among the donors", {
  e <- dd_env()
  w0 <- data.frame(year = 2009:2016, anomaly = c(0.1, 0.1, 0.1, NA, 0.1, 0.1, 0.1, 0.1),
                   donors = "H1:0.5000 H2:0.5000")
  w1 <- data.frame(year = 2009:2016, anomaly = 0.2,
                   donors = c(rep("H1:0.4000 S1:0.6000", 6), "H1:1.0000", "S1:1.0000"))
  expect_equal(e$dd_scored_years(2005:2015, w0, w1, "S1"), c(2011L, 2013L, 2014L))
  expect_equal(e$dd_scored_years(2005:2016, w0, w1, "S1"), c(2011L, 2013L, 2014L, 2016L))
  expect_equal(e$dd_scored_years(integer(0), w0, w1, "S1"), integer(0))
  expect_equal(e$dd_scored_years(2011:2015, w0[0, ], w1, "S1"), integer(0))
  expect_equal(e$dd_scored_years(2011:2015, w0, w1, character()), integer(0))
})

test_that("dd_rmse needs 3 years", {
  e <- dd_env()
  expect_equal(e$dd_rmse(c(1, 2, 3), c(1, 2, 5)), sqrt(4 / 3))
  expect_true(is.na(e$dd_rmse(c(1, 2), c(1, 2))))
})

test_that("dd_ship ships only at -0.01 or lower in both pools with 10 gauges each", {
  e <- dd_env()
  expect_true(e$dd_ship(-0.02, -0.015, 12, 11)$ship)
  expect_true(e$dd_ship(-0.01, -0.01, 10, 10)$ship)                  # exactly the margin
  expect_true(e$dd_ship(-0.01 + 1e-12, -0.01, 10, 10)$ship)          # floating point allowed
  expect_match(e$dd_ship(-0.009, -0.02, 12, 12)$reason, "leave-one-out")
  expect_match(e$dd_ship(-0.02, -0.005, 12, 12)$reason, "leak-free")
  expect_match(e$dd_ship(-0.05, -0.05, 9, 12)$reason, "gauges scored")
  expect_match(e$dd_ship(-0.05, -0.05, 12, 9)$reason, "gauges scored")
  expect_match(e$dd_ship(NA, -0.05, 12, 12)$reason, "NA")
  # counts are checked before the medians
  expect_match(e$dd_ship(NA, NA, 3, 3)$reason, "gauges scored")
  expect_false(e$dd_ship(0.02, 0.02, 20, 20)$ship)
})

# ---- dd_gauge end to end, through the real wet_window_extend() and wet_departure_carry() ----

gauge_data <- function() {
  set.seed(211)
  yrs <- 1961:2024
  sig <- rnorm(length(yrs), 0, 0.3)
  xh <- rbind(long("H1", yrs, exp(3 + sig + rnorm(length(yrs), 0, 0.05))),
              long("H2", yrs, exp(4 + sig + rnorm(length(yrs), 0, 0.05))),
              long("H3", yrs, exp(5 + sig + rnorm(length(yrs), 0, 0.05))))
  sy <- 2016:2026
  ssig <- c(sig[match(2016:2024, yrs)], 0.4, -0.2)
  xo <- long("S1", sy, exp(2 + ssig + rnorm(length(sy), 0, 0.05)))
  st <- data.frame(station_number = c("H1", "H2", "H3", "S1"), lon = c(-126.6, -127.8, -125.9, -126.5),
                   lat = c(54.4, 55.1, 54.0, 54.3), drainage_area_gross_km2 = c(2300, 900, 5000, 360))
  list(xh = xh, xo = xo, st = st, pool = c("H1", "H2", "H3"))
}

test_that("dd_gauge returns both carries, the station's late years carried as observed", {
  e <- dd_env()
  d <- gauge_data()
  r <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, d$st, "S1", d$pool, d$pool)
  expect_true(r$scored)
  expect_equal(r$years, 2016:2024)
  expect_true(r$eligible$eligible)
  expect_equal(r$eligible$n_fit, 9L)
  expect_equal(r$rows$year[r$rows$source == "observed"], 2016:2026)
  expect_equal(r$rows$year[r$rows$source == "extended"], 1981:2010)
  # 2025: only the station has a value; its departure is its observed value against its baseline mean
  y25 <- r$with[r$with$year == 2025, ]
  expect_equal(y25$donors, "S1:1.0000")
  base <- r$rows$value[r$rows$year %in% 1981:2010]
  expect_equal(y25$anomaly, log(d$xo$value[d$xo$year == 2025] / mean(base)))
  expect_false(2025 %in% r$without$year)
  expect_equal(r$diff, unname(r$rmse[["with"]] - r$rmse[["without"]]))
  expect_true(all(is.finite(r$rmse)))
})

test_that("dd_gauge gives identical carries with no candidate, and leaves out a station at g's site", {
  e <- dd_env()
  d <- gauge_data()
  st_h <- d$st[d$st$station_number != "S1", ]
  r <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, st_h, character(), d$pool, d$pool)
  expect_identical(r$without, r$with)
  expect_false(r$scored)
  # S1 at H1's site is no candidate, so the box holds none
  so <- data.frame(station_number = "S1", regulation = "natural", lon = -126.5, lat = 54.3,
                   drainage_area_gross_km2 = 360, hydat_site = "H1", n_mig = 11)
  cand <- so$station_number[e$dd_candidate(so, "H1", e$dd_box(-126.6, 54.4))]
  expect_equal(cand, character())
  r2 <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, d$st[d$st$station_number %in% c(d$pool, cand), ],
                   cand, d$pool, d$pool)
  expect_identical(r2$without, r2$with)
})

test_that("dd_gauge does not score a gauge with no HYDAT donor left, without an error", {
  e <- dd_env()
  d <- gauge_data()
  r <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, d$st, "S1", d$pool, "H1")
  expect_false(r$scored)
  expect_equal(r$reason, "no HYDAT donor left")
  r2 <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, d$st, "S1", d$pool, d$pool, drop = c("H2", "H3"))
  expect_equal(r2$reason, "no HYDAT donor left")
})

test_that("dd_gauge names why a station is not eligible", {
  e <- dd_env()
  d <- gauge_data()
  # no extension gauge covers fit years before 1961
  xo <- rbind(d$xo, long("S2", 1955:1958, c(1, 2, 3, 4)))
  st <- rbind(d$st, data.frame(station_number = "S2", lon = -126.2, lat = 54.2, drainage_area_gross_km2 = 50))
  r <- e$dd_gauge("H1", "q_mean", "migration", d$xh, xo, st, c("S1", "S2"), d$pool, d$pool)
  expect_equal(r$eligible$reason[r$eligible$station_number == "S2"], "no extension gauge covers its fit years")
  expect_true(r$eligible$eligible[r$eligible$station_number == "S1"])
  # fewer than 3 fit years (2025 and 2026 never count)
  xo3 <- rbind(d$xo, long("S3", c(2024, 2025, 2026), c(1, 2, 3)))
  st3 <- rbind(d$st, data.frame(station_number = "S3", lon = -126.2, lat = 54.2, drainage_area_gross_km2 = 50))
  r3 <- e$dd_gauge("H1", "q_mean", "migration", d$xh, xo3, st3, c("S1", "S3"), d$pool, d$pool)
  expect_equal(r3$eligible$reason[r3$eligible$station_number == "S3"], "fewer than 3 fit years")
  # a related station is not eligible in the leak-free pool
  r4 <- e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, d$st, "S1", d$pool, d$pool, drop = "S1")
  expect_equal(r4$eligible$reason, "related to the held-out gauge")
  expect_false(r4$scored)
  # an extension donor that does not vary over the fit years
  xh <- d$xh
  xh$value[xh$station_number %in% c("H2", "H3") & xh$year %in% 2016:2024] <- 7
  r5 <- e$dd_gauge("H1", "q_mean", "migration", xh, d$xo, d$st, "S1", d$pool, d$pool)
  expect_equal(r5$eligible$reason, "an extension donor does not vary over its fit years")
})

test_that("dd_gauge lets any other error from the extension or the carry propagate", {
  e <- dd_env()
  d <- gauge_data()
  st_tab <- d$st[d$st$station_number != "S1", ]     # no row for the candidate
  expect_error(e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, st_tab, "S1", d$pool, d$pool),
               "has no row for")
  bad <- d$st
  bad$drainage_area_gross_km2[bad$station_number == "H2"] <- NA
  expect_error(e$dd_gauge("H1", "q_mean", "migration", d$xh, d$xo, bad, "S1", d$pool, d$pool),
               "no positive drainage area")
})
