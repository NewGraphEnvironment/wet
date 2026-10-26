# Maxan Creek Chinook pilot (#120, component 1 of #118): extend a short-record
# gauge's window flows from its long-record neighbours, with an error per year,
# and score donor-carried departures held out at every gauge in the region.
# The rule below was fixed in this header, and committed alone, before any
# candidate was coded or scored; the body that runs it came later
# (planning/archive, issue 120).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_pilot.R
#
# Reads HYDAT 20260717 only (scripts/wb_fit_lib.R's wb_hydat(), wet's
# per-user cache), and fwapg through the PG* env vars for the leak-free
# sensitivity alone. Writes the tracked report
# data/checks/departure_pilot_20260717.txt and nothing else. Nothing is
# published, no fit is read or touched: 08EE018 and 08EE003 are not
# calibration gauges, and 08EE013 is used here only as a HYDAT record.
#
# ---- decided at the plan gate (user, 2026-10-24) ---------------------------------------------
#
# Windows: the CH rows of inst/vignette-data/life_history_bulk.csv,
#   migration 05-01..08-01 and spawning 08-01..09-15, both days inclusive.
# Statistics: wet_window_stats() mean, min7 and cov_day per window; max is
#   computed and reported, never scored.
# Periods: baseline 1981-2010 (as #25); before/after is the mean departure
#   over the years before 1981 against 2011-2025; cd::cd_trend() over the
#   whole extended record.
# Scale: a departure is a log ratio, log(value / baseline mean), the baseline
#   mean being the arithmetic mean of the 1981-2010 values (cd_baseline()'s
#   mean); it is reported as % of normal, 100 * (exp(departure) - 1).
#   cov_day is a day of the window, so its departure is a difference in days.
# Source: HYDAT release 20260717, approved daily flows only
#   (wet_station_daily(sources = "hydat")); no provisional or real-time day.
#
# ---- the pool ----------------------------------------------------------------------------------
#
# The box: BC HYDAT gauges (PROV_TERR_STATE_LOC = "BC") with STN_REGULATION
# REGULATED = 0, inside lon -128.8..-125.0 and lat 53.6..55.8 (Bulkley,
# Morice, Babine, Kispiox, Zymoetz, Kitimat, Nechako headwaters; the issue's
# "Bulkley and neighbouring watershed groups"). A complete window-year is a
# row wet_window_stats() returns at its default min_frac = 0.8 (at least 80 %
# of the window's days present, the window inside the record); for cov_day
# it is a window-year with every day present, which wet_window_stats() alone
# returns, so cov_day's years are its own. A gauge with no drainage area or
# no coordinates in STATIONS is excluded and counted.
#
#   box pool         natural box gauges with >= 3 complete migration-window
#                    years. Predictor scaling and the short-record set come
#                    from it.
#   extension pool   box-pool gauges with >= 30 complete migration-window
#                    years and at least one run of 5 consecutive complete
#                    years. Question 1's donors and its test gauges.
#   departure pool   box-pool gauges with >= 10 complete window-years of the
#                    statistic inside 1981-2010, so the gauge's own baseline
#                    is defined. Question 2's donors and its held-out gauges,
#                    per window and statistic; the counts on the migration
#                    mean are the headline ones.
#   short-record     box-pool gauges with 3..10 complete migration-window
#                    years (08EE018 among them). Scored from the full
#                    departure pool, separately from it.
#
# Predictors, as #70 and #102: easting and northing in km (the station's
# STATIONS lon/lat projected to EPSG:3005) and log drainage area (km2), each
# divided by its SD over the box pool. Distance is Euclidean in that space.
# k = 5 nearest; k = 3 and k = 8 are reported sensitivities.
#
# Donor availability per year (plan review item 1). Extension: the donors are
# the k nearest extension-pool gauges (target excluded) that have a value in
# every one of the target's observed years, ordered by distance; in each year
# to be extended, the nearest of them with a value that year supplies it, and
# a year none of them has stays missing. Each donor's relation is fitted on
# the target's observed years. Carried departures: the k nearest
# departure-pool gauges (target excluded), fixed once by distance; their
# inverse-distance weights are wet_donor_mean()'s (1 / (d + 1e-6 * median d),
# a donor at distance 0 taking the whole weight); a donor without a value in
# a year is dropped for that year and the remaining weights renormalised to
# sum 1; a year with no donor present is missing. wet_departure_carry() does
# the renormalisation; wet_donor_mean()'s contract, shared with #70 and #102,
# is unchanged.
#
# Both functions take the window values in wet_window_stats()'s long format
# and a station table in wet_station_select()'s shape (station_number, lon,
# lat, drainage_area_gross_km2) for the predictors.
#
# ---- question 1: record extension, wet_window_extend() ----------------------------------------
#
# Candidates, every setting fixed here. x is the donor's value and y the
# target's in the same year, both log for mean and min7, days for cov_day; n
# is the number of the target's observed years.
#
#   (a) ols     OLS of y on x over the observed years; the point is the
#               fitted line (back-transformed with exp(), the median, for a
#               log statistic); the 90 % interval is OLS's prediction
#               interval, t(0.95, n - 2) * s * sqrt(1 + 1/n + (x0 - mean x)^2
#               / Sxx), with n - 2 degrees of freedom.
#   (b) move1   the line of organic correlation (MOVE.1): y = mean y +
#               sign(r) * (sd y / sd x) * (x - mean x), which keeps the
#               target's variance where OLS shrinks it.
#   (c) ratio   the incumbent: target value = donor value * (mean of the
#               target's observed values / mean of the donor's in the same
#               years), means taken on the original scale (m3/s; days for
#               cov_day), a ratio of means, not a mean of ratios.
#
# Intervals for (b) and (c) are the 5th and 95th percentiles of the residuals
# (observed minus predicted, log or days) on the held-out years of the OTHER
# extension-pool gauges' pseudo-records (leave-gauge-out), so a gauge's own
# residuals never set its interval. One nominal level, 90 %, for all three.
#
# Reported sensitivities, unable to ship (a winning sensitivity is a new rule
# in a new issue):
#   multi-donor OLS on the min(k, n - 2) nearest covering donors, a year
#     needing every one of them;
#   (d) day by day: OLS of the target's log daily flow on the nearest covering
#     donor's same-day log flow over the window days of the observed years
#     (days with flow <= 0 dropped), the extended days back-transformed and the
#     window statistic taken from them with wet_window_stats() (the issue's
#     "day by day");
#   k = 3 and 8; the spawning window; min7 and cov_day; leak-free (below).
#
# The test. At every extension-pool gauge, its complete migration-window
# years are cut into pseudo-short records: within each maximal run of
# consecutive complete years, non-overlapping blocks of 5 from the run's first
# year (tiled; a remainder shorter than 5 is not one). Each block is the
# gauge's observed record; the gauge is extended from the other
# extension-pool gauges under the donor rule above and scored on its
# HELD-OUT years only, its complete years outside the block, over the years
# every candidate (a), (b), (c) has a value for. A gauge with no block is
# dropped and counted; a block with fewer than 3 held-out years scored is
# dropped and counted. The score is wet:::wet_nse() of predicted against
# observed log migration-window mean. Per gauge, the median NSE over its
# blocks; the median over gauges decides.
#
# The rule: the candidate with the highest median ships for Maxan if that
# median exceeds (c)'s by at least 0.01 (unrounded, 1e-9 allowed for floating
# point; #16's margin); otherwise (c) ships. NSE 0 is the observed years' mean
# repeated, the margin of no skill. Reported beside it, deciding nothing:
# coverage of each candidate's 90 % interval on held-out years; the same test
# on the spawning window, min7 and cov_day (cov_day scored on days, NSE of
# predicted against observed day; a window-year whose mean or min7 is <= 0 is
# dropped from a log score and counted); the sensitivities; and at 08EE018,
# leave-one-year-out over its observed years (fit on the rest, predict the
# one left out) for each candidate.
#
# ---- question 2: donor-carried departures, wet_departure_carry() ------------------------------
#
# Each donor's log departure per year from its own 1981-2010 baseline mean;
# carried onto the target as the per-year weighted mean of its k donors under
# the availability rule above. The target's own value is given only where it
# has its own baseline (>= 10 baseline years).
#
# The test. Leave-one-gauge-out at every departure-pool gauge: its donors are
# the departure pool without it. The carried series is scored against the
# gauge's observed log values over the years both have, BOTH SERIES CENTRED
# ON THEIR MEAN OVER THOSE YEARS (in log space), so no target baseline is
# needed and a short-record gauge is scored the same way (plan review item 3).
# Score: wet:::wet_nse() per gauge; a gauge with fewer than 3 such years is
# not scored and is counted. NSE 0 is "no departure" (climatology), the
# margin the issue asks about. The short-record gauges are scored the same
# way from the full departure pool, separately.
#
# No ship decision: the question is whether a carried departure tracks the
# target's. The report gives the median per-gauge NSE over the departure pool
# on the migration-window mean, with its quartiles, as the headline, and the
# short-record median beside it. The method is USABLE for #122's competition
# if that departure-pool median is >= 0.5; the threshold is set here so #122
# inherits it rather than choosing it after seeing the number. Reported,
# deciding nothing: the spawning window, min7 and cov_day (centred days),
# k = 3 and 8, and leak-free.
#
# ---- leak-free sensitivity (both questions) ---------------------------------------------------
#
# Houston (08EE003) and Quick (08EE004) contain Maxan. When the PG* env vars
# reach an fwapg database, the box pool is snapped with wet_station_snap()
# and a held-out gauge's upstream and downstream gauges
# (wet:::wet_fwa_upstream() on wscode and localcode, either direction) are
# removed from its donors, every candidate refitted. A gauge whose snap is not
# accepted keeps all its donors and is counted. Without a database the report
# says "not run". It decides nothing.
#
# ---- the Maxan answer (reported, deciding nothing beyond question 1's ship) -------------------
#
# 08EE018's migration and spawning series per statistic, observed in its own
# years and extended by the shipped question-1 candidate in every other year
# its donor chain reaches up to 2025, with the 90 % interval and the donor per
# year. Its departures from the extended series' own 1981-2010 mean. Beside it
# the carried route, departures only, and the two routes compared as centred
# departures over the observed years and over the record. The before/after:
# mean departure 2011-2025 minus mean departure before 1981, in log units and
# % of normal, with a 90 % interval from 2000 bootstrap draws that resample
# years within each period and add to each extended year a residual drawn from
# the shipped candidate's leave-gauge-out residuals (observed years add none);
# set.seed(120). The limit stated in the report: the years before 1961 rest on
# the one or two donors in the chain that reach them. cd::cd_baseline(),
# cd_anomaly() (% of normal, cd's cap of 200) and cd_trend() on the extended
# series, from its first year and from 1981.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a target or donor with fewer than 3
# complete window-years in common (wet_window_extend()); a donor with fewer
# than 10 baseline years (wet_departure_carry()); an extension pool with
# fewer than 15 gauges holding a pseudo-record; pilot-gauge counts that differ
# from the issue's table (08EE018 5, 08EE013 51, 08EE003 43 or 44, the report
# fixing which). The report carries no timestamp, so a rerun reproduces it
# byte for byte.


devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()

release <- wb_release()
if (release != "20260717") stop("the pilot's rule names HYDAT 20260717, not ", release, call. = FALSE)
hydat <- wb_hydat(release)
report <- file.path("data", "checks", sprintf("departure_pilot_%s.txt", release))
baseline <- 1981:2010
box <- c(lon_min = -128.8, lon_max = -125.0, lat_min = 53.6, lat_max = 55.8)
k_main <- 5
k_sens <- c(3, 8)
level <- 0.9
margin <- 0.01
usable_nse <- 0.5
min_pseudo_gauges <- 15
pilot <- c(maxan = "08EE018", houston = "08EE003", buck = "08EE013")

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$window, c("migration", "spawning")),
          identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))

fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
out <- character()
say <- function(...) out <<- c(out, ...)

# ---- the pool ----------------------------------------------------------------------------------
con <- wet:::wet_hydat_connect(hydat)
st_all <- DBI::dbGetQuery(con, sprintf("
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.LONGITUDE lon,
         s.LATITUDE lat, s.DRAINAGE_AREA_GROSS drainage_area_gross_km2
  FROM STATIONS s JOIN STN_REGULATION r USING (STATION_NUMBER)
  WHERE r.REGULATED = 0 AND s.PROV_TERR_STATE_LOC = 'BC'
    AND s.LONGITUDE BETWEEN %f AND %f AND s.LATITUDE BETWEEN %f AND %f
  ORDER BY s.STATION_NUMBER", box[["lon_min"]], box[["lon_max"]], box[["lat_min"]], box[["lat_max"]]))
DBI::dbDisconnect(con)
no_meta <- st_all$station_number[is.na(st_all$drainage_area_gross_km2) | is.na(st_all$lon) | is.na(st_all$lat)]
st_all <- st_all[!st_all$station_number %in% no_meta, ]

daily <- suppressWarnings(wet_station_daily(st_all$station_number, hydat, to = NULL, sources = "hydat"))
ws <- wet_window_stats(daily, windows, stats = c("mean", "min7", "max", "cov_day"))
ws <- ws[c("station_number", "variable", "period", "year", "value", "anomaly_type", "unit")]

years_of <- function(st, w = "migration", v = "q_mean") {
  sort(ws$year[ws$station_number == st & ws$period == w & ws$variable == v])
}
n_mig <- vapply(st_all$station_number, function(s) length(years_of(s)), 0L)
pool <- st_all[n_mig >= 3, ]
rownames(pool) <- NULL
xy <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(pool, coords = c("lon", "lat"), crs = 4326), 3005))
pool$e_km <- xy[, 1] / 1000
pool$n_km <- xy[, 2] / 1000
ws <- ws[ws$station_number %in% pool$station_number, ]

# the longest run of consecutive years in y, and the tiled 5-year blocks
runs_of <- function(y) if (length(y)) split(y, cumsum(c(1, diff(y) != 1))) else list()
blocks_of <- function(y, len = 5) {
  b <- list()
  for (r in runs_of(y)) {
    nb <- length(r) %/% len
    for (i in seq_len(nb)) b[[length(b) + 1]] <- r[(i - 1) * len + seq_len(len)]
  }
  b
}
# years as runs: 1973-1974, 1980-2015, 2017-2024
year_runs <- function(y) {
  paste(vapply(runs_of(sort(y)), function(r) if (length(r) > 1) sprintf("%d-%d", min(r), max(r)) else
    as.character(r), ""), collapse = ", ")
}
pool$n_mig <- vapply(pool$station_number, function(s) length(years_of(s)), 0L)
pool$n_spw <- vapply(pool$station_number, function(s) length(years_of(s, "spawning")), 0L)
pool$first <- vapply(pool$station_number, function(s) min(years_of(s)), 0)
pool$last <- vapply(pool$station_number, function(s) max(years_of(s)), 0)
pool$pre1981 <- vapply(pool$station_number, function(s) sum(years_of(s) < 1981), 0L)
pool$base <- vapply(pool$station_number, function(s) sum(years_of(s) %in% baseline), 0L)
pool$recent <- vapply(pool$station_number, function(s) sum(years_of(s) %in% 2011:2025), 0L)
pool$n_blocks <- vapply(pool$station_number, function(s) length(blocks_of(years_of(s))), 0L)
pool$ext <- pool$n_mig >= 30 & pool$n_blocks >= 1
pool$dep <- pool$base >= 10
pool$short <- pool$n_mig <= 10

# the issue's table: 08EE018 5, 08EE013 51, 08EE003 43 (the issue) or 44 (the plan's probe)
cnt <- stats::setNames(stats::setNames(pool$n_mig, pool$station_number)[pilot], names(pilot))
if (!identical(unname(cnt[c("maxan", "buck")]), c(5L, 51L)) || !cnt[["houston"]] %in% c(43L, 44L)) {
  stop("pilot-gauge counts differ from the issue's table: ", paste(pilot, cnt, collapse = ", "), call. = FALSE)
}

say("# Maxan Creek Chinook pilot: extended window flows and donor-carried departures (#120)", "",
    sprintf("HYDAT %s, approved daily flows only. Rule registered in scripts/departure_pilot.R's header at 6894c27, before any candidate.", release),
    sprintf("Windows (CH, inst/vignette-data/life_history_bulk.csv): %s.",
            paste(sprintf("%s %s..%s", windows$window, windows$start, windows$end), collapse = ", ")),
    sprintf("Box: natural (REGULATED = 0) BC gauges, lon %s..%s, lat %s..%s. Baseline %d-%d.",
            box[["lon_min"]], box[["lon_max"]], box[["lat_min"]], box[["lat_max"]], min(baseline), max(baseline)),
    "A complete window-year: at least 80 % of the window's days present, inside the record (wet_window_stats(), min_frac = 0.8).",
    "", "## 1. The pool", "",
    sprintf("Natural box gauges in STATIONS: %d; excluded for no drainage area or coordinates: %d%s.",
            length(n_mig) + length(no_meta), length(no_meta),
            if (length(no_meta)) paste0(" (", paste(no_meta, collapse = ", "), ")") else ""),
    sprintf("Box pool (>= 3 complete migration years): %d. Extension pool (>= 30 and a 5-year run): %d. Departure pool (>= 10 baseline migration years): %d. Short-record (3..10 years): %d.",
            nrow(pool), sum(pool$ext), sum(pool$dep), sum(pool$short)),
    sprintf("Pilot gauges, complete migration-window years by this definition: %s.",
            paste(sprintf("%s %d", pilot, cnt), collapse = ", ")),
    "", sprintf("  %-8s %-42s %8s %4s %4s %5s %5s %4s %4s %5s %s", "station", "name", "km2", "mig", "spw",
                "first", "last", "<81", "base", "11-25", "pool"))
o <- order(-pool$n_mig, pool$station_number)
say(sprintf("  %-8s %-42s %8s %4d %4d %5d %5d %4d %4d %5d %s", pool$station_number[o],
            substr(tools::toTitleCase(tolower(pool$station_name[o])), 1, 42),
            fmt(pool$drainage_area_gross_km2[o], 1), pool$n_mig[o], pool$n_spw[o], as.integer(pool$first[o]),
            as.integer(pool$last[o]), pool$pre1981[o], pool$base[o], pool$recent[o],
            trimws(paste(ifelse(pool$ext[o], "ext", ""), ifelse(pool$dep[o], "dep", ""),
                         ifelse(pool$short[o], "SHORT", "")))),
    "", "mig, spw: complete years in the migration and spawning windows; first, last, <81, base (1981-2010) and 11-25 count migration years.", "")

# ---- leak-free relations (fwapg, when reachable) -------------------------------------------------
# related[[g]]: the box-pool gauges upstream or downstream of g. NULL when no
# database is reachable; a gauge whose snap is not accepted relates to none.
related <- NULL
snap_note <- "not run: no fwapg database reachable through the PG* env vars"
conn <- tryCatch(DBI::dbConnect(RPostgres::Postgres()), error = function(e) NULL)
if (!is.null(conn)) {
  sn <- wet_station_snap(conn, pool[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
  DBI::dbDisconnect(conn)
  sn <- sn[match(pool$station_number, sn$station_number), ]
  ok <- sn$accepted %in% TRUE
  up <- matrix(FALSE, nrow(sn), nrow(sn), dimnames = list(sn$station_number, sn$station_number))
  for (i in which(ok)) up[i, ok] <- wet:::wet_fwa_upstream(sn$wscode[i], sn$localcode[i], sn$wscode[ok], sn$localcode[ok])
  diag(up) <- FALSE
  rel <- up | t(up)
  related <- lapply(stats::setNames(rownames(rel), rownames(rel)), function(g) colnames(rel)[rel[g, ]])
  snap_note <- sprintf("run: %d of %d box-pool gauges snapped and accepted (wet_station_snap()); %d unaccepted keep every donor%s.",
                       sum(ok), nrow(sn), sum(!ok),
                       if (any(!ok)) paste0(" (", paste(sn$station_number[!ok], collapse = ", "), ")") else "")
}

# ---- question 1: the pseudo-short-record test ------------------------------------------------
methods <- c("ols", "move1", "ratio")
ext_pool <- pool$station_number[pool$ext]
stations <- pool[c("station_number", "lon", "lat", "drainage_area_gross_km2")]
is_days <- function(v) grepl("_cov_day$", v)
tr_of <- function(v) if (is_days(v)) identity else log
wsel <- function(v, p) {
  g <- ws[ws$variable == v & ws$period == p & !is.na(ws$value), ]
  if (!is_days(v)) g <- g[g$value > 0, ]
  g
}

# Every extension-pool gauge's 5-year blocks, each extended from the other
# extension-pool gauges (less `drop[[g]]`) by each method, kept on held-out years.
pseudo_run <- function(v, p, k = k_main, drop = NULL) {
  g_all <- wsel(v, p)
  tr <- tr_of(v)
  rows <- list()
  n <- c(gauges = 0, no_block = 0, blocks = 0, no_donor = 0, few_held = 0,
         dropped_le0 = sum(ws$variable == v & ws$period == p & ws$station_number %in% ext_pool &
                           !is.na(ws$value) & ws$value <= 0 & !is_days(v)))
  for (g in ext_pool) {
    tg <- g_all[g_all$station_number == g, ]
    bl <- blocks_of(sort(tg$year))
    if (!length(bl)) {
      n[["no_block"]] <- n[["no_block"]] + 1
      next
    }
    n[["gauges"]] <- n[["gauges"]] + 1
    dx <- g_all[g_all$station_number %in% setdiff(ext_pool, c(g, drop[[g]])), ]
    for (b in seq_along(bl)) {
      n[["blocks"]] <- n[["blocks"]] + 1
      xb <- rbind(tg[tg$year %in% bl[[b]], ], dx)
      e <- lapply(stats::setNames(methods, methods), function(m) {
        tryCatch(wet_window_extend(xb, stations, g, m, k = k, level = level), error = function(err) NULL)
      })
      if (is.null(e$ols)) {
        n[["no_donor"]] <- n[["no_donor"]] + 1
        next
      }
      held <- tg[!tg$year %in% bl[[b]], c("year", "value")]
      m <- held
      for (mt in methods) {
        ex <- e[[mt]][e[[mt]]$source == "extended", ]
        i <- match(m$year, ex$year)
        m[[mt]] <- ex$value[i]
        if (mt == "ols") {
          m$lo_ols <- ex$lower[i]
          m$hi_ols <- ex$upper[i]
          m$donor <- ex$donor[i]
        }
      }
      m <- m[stats::complete.cases(m[methods]), ]
      if (nrow(m) < 3) {
        n[["few_held"]] <- n[["few_held"]] + 1
        next
      }
      for (mt in methods) m[[paste0("r_", mt)]] <- tr(m$value) - tr(m[[mt]])
      rows[[length(rows) + 1]] <- data.frame(gauge = g, block = min(bl[[b]]), m,
                                             chain = paste(attr(e$ols, "donors")[[1]], collapse = " "))
    }
  }
  r <- do.call(rbind, rows)
  list(r = r, n = n, v = v, p = p, k = k)
}

# Per gauge: the median over its blocks of each method's NSE on held-out years.
pseudo_score <- function(run, cols = methods) {
  r <- run$r
  tr <- tr_of(run$v)
  nse <- do.call(rbind, lapply(split(r, list(r$gauge, r$block), drop = TRUE), function(d) {
    data.frame(gauge = d$gauge[1], block = d$block[1],
               t(vapply(cols, function(mt) wet:::wet_nse(tr(d$value), tr(d[[mt]])), 0)))
  }))
  per_gauge <- do.call(rbind, lapply(split(nse, nse$gauge), function(d) {
    data.frame(gauge = d$gauge[1], n_blocks = nrow(d),
               t(vapply(cols, function(mt) stats::median(d[[mt]], na.rm = TRUE), 0)))
  }))
  rownames(per_gauge) <- NULL
  per_gauge
}

# Coverage of each method's 90 % interval on held-out years: ols its own
# interval, move1 and ratio the quantiles of the other gauges' residuals.
q_lo <- (1 - level) / 2
q_hi <- (1 + level) / 2
pseudo_coverage <- function(run) {
  r <- run$r
  tr <- tr_of(run$v)
  cov <- c(ols = mean(tr(r$value) >= tr(r$lo_ols) & tr(r$value) <= tr(r$hi_ols)))
  for (mt in c("move1", "ratio")) {
    hit <- unlist(lapply(split(r, r$gauge), function(d) {
      oth <- r[[paste0("r_", mt)]][r$gauge != d$gauge[1]]
      qq <- stats::quantile(oth, c(q_lo, q_hi), names = FALSE)
      d[[paste0("r_", mt)]] >= qq[1] & d[[paste0("r_", mt)]] <= qq[2]
    }))
    cov[[mt]] <- mean(hit)
  }
  cov
}

decide <- function(per_gauge) {
  med <- vapply(methods, function(mt) stats::median(per_gauge[[mt]], na.rm = TRUE), 0)
  best <- methods[which.max(med)]
  ship <- if (best != "ratio" && med[[best]] - med[["ratio"]] >= margin - 1e-9) best else "ratio"
  list(med = med, best = best, ship = ship)
}

main <- pseudo_run("q_mean", "migration")
if (main$n[["gauges"]] < min_pseudo_gauges) {
  stop(sprintf("the extension pool has %d gauges with a pseudo-record; the rule needs at least %d",
               main$n[["gauges"]], min_pseudo_gauges), call. = FALSE)
}
main_pg <- pseudo_score(main)
dec <- decide(main_pg)
ship <- dec$ship
qs <- function(v) fmt(stats::quantile(v, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE))

say("## 2. Record extension (question 1)", "",
    sprintf("Extension pool: %d gauges; %d hold at least one 5-year block (%d without one). Blocks: %d; dropped for no covering donor %d, for fewer than 3 held-out years %d. Window-years <= 0 dropped from the log score: %d.",
            length(ext_pool), main$n[["gauges"]], main$n[["no_block"]], main$n[["blocks"]],
            main$n[["no_donor"]], main$n[["few_held"]], main$n[["dropped_le0"]]),
    sprintf("Scored: %d blocks at %d gauges; %d held-out block-years, %d distinct gauge-years.",
            nrow(unique(main$r[c("gauge", "block")])), length(unique(main$r$gauge)), nrow(main$r),
            nrow(unique(main$r[c("gauge", "year")]))),
    "", "Migration-window mean, log NSE on held-out years, k = 5. Per gauge the median over its blocks; across gauges:", "",
    sprintf("  %-6s %8s %8s %8s", "method", "q25", "median", "q75"))
for (mt in methods) say(sprintf("  %-6s %8s %8s %8s", mt, qs(main_pg[[mt]])[1], qs(main_pg[[mt]])[2], qs(main_pg[[mt]])[3]))
say("", sprintf("The rule: the highest median is %s (%s); ratio's is %s; margin %s. SHIPS FOR MAXAN: %s.",
                dec$best, fmt(dec$med[[dec$best]], 3), fmt(dec$med[["ratio"]], 3), margin, ship),
    "", sprintf("Coverage of the nominal 90 %% interval on held-out years: %s.",
                paste(sprintf("%s %s", methods, fmt(100 * pseudo_coverage(main), 1)), collapse = ", ")),
    "(ols: its own prediction interval; move1 and ratio: 5th-95th percentiles of the other gauges' held-out residuals.)",
    "", "Per gauge (median NSE over its blocks):", "",
    sprintf("  %-8s %6s %7s %7s %7s", "gauge", "blocks", methods[1], methods[2], methods[3]),
    sprintf("  %-8s %6d %7s %7s %7s", main_pg$gauge, main_pg$n_blocks, fmt(main_pg$ols), fmt(main_pg$move1),
            fmt(main_pg$ratio)), "")

# ---- question 1: sensitivities, reported and unable to ship ----------------------------------
sens <- list(
  list(label = "k = 3", v = "q_mean", p = "migration", k = 3),
  list(label = "k = 8", v = "q_mean", p = "migration", k = 8),
  list(label = "spawning mean", v = "q_mean", p = "spawning", k = k_main),
  list(label = "migration min7", v = "q_min7", p = "migration", k = k_main),
  list(label = "spawning min7", v = "q_min7", p = "spawning", k = k_main),
  list(label = "migration cov_day (days)", v = "q_cov_day", p = "migration", k = k_main),
  list(label = "spawning cov_day (days)", v = "q_cov_day", p = "spawning", k = k_main))
if (!is.null(related)) {
  sens[[length(sens) + 1]] <- list(label = "leak-free", v = "q_mean", p = "migration", k = k_main, drop = related)
}
runs <- list(main = main)
for (s in sens) runs[[s$label]] <- pseudo_run(s$v, s$p, s$k, s$drop)
sens_line <- function(label, run) {
  pg <- pseudo_score(run)
  d <- decide(pg)
  sprintf("  %-26s %6d %6d %7s %7s %7s  %-6s %s", label, nrow(pg), nrow(unique(run$r[c("gauge", "block")])),
          fmt(d$med[["ols"]]), fmt(d$med[["move1"]]), fmt(d$med[["ratio"]]), d$ship,
          paste(sprintf("%s %s", methods, fmt(100 * pseudo_coverage(run), 0)), collapse = " "))
}
say("Sensitivities (median over gauges of per-gauge median NSE; 'rule' is what the rule would pick there; coverage %):", "",
    sprintf("  %-26s %6s %6s %7s %7s %7s  %-6s %s", "setting", "gauges", "blocks", methods[1], methods[2], methods[3],
            "rule", "coverage"),
    sens_line("migration mean, k = 5", main))
for (s in sens) say(sens_line(s$label, runs[[s$label]]))
if (is.null(related)) say(sprintf("  %-26s %s", "leak-free", snap_note))
say("", sprintf("Leak-free: %s", snap_note), "")

# multi-donor OLS on the min(k, n - 2) nearest covering donors, and (d) day by
# day on the nearest: each scored over its own held-out years, beside ols on
# the same years. Blocks are 5 consecutive years from `block`.
g_mean <- wsel("q_mean", "migration")
val_of <- function(st, yrs) {
  d <- g_mean[g_mean$station_number == st, ]
  d$value[match(yrs, d$year)]
}
in_window <- function(date, w) {
  md <- format(date, "%m-%d")
  md >= windows$start[windows$window == w] & md <= windows$end[windows$window == w]
}
dmig <- daily[in_window(daily$date, "migration"), c("station_number", "date", "q_m3s")]
dmig$year <- as.integer(format(dmig$date, "%Y"))
dmig <- split(dmig, dmig$station_number)
blk <- split(main$r, list(main$r$gauge, main$r$block), drop = TRUE)
multi <- list()
dbd <- list()
for (d in blk) {
  g <- d$gauge[1]
  by <- d$block[1] + 0:4
  chain <- strsplit(d$chain[1], " ")[[1]]
  # multi-donor
  use <- chain[seq_len(min(k_main, length(by) - 2, length(chain)))]
  X <- vapply(use, function(s) log(val_of(s, by)), numeric(length(by)))
  y <- log(val_of(g, by))
  fit <- stats::lm(y ~ X)
  X0 <- vapply(use, function(s) log(val_of(s, d$year)), numeric(nrow(d)))
  pr <- drop(cbind(1, matrix(X0, nrow(d))) %*% stats::coef(fit))
  ok <- !is.na(pr)
  if (sum(ok) >= 3) {
    multi[[length(multi) + 1]] <- data.frame(gauge = g, block = d$block[1], n_donors = length(use),
      nse = wet:::wet_nse(log(d$value[ok]), pr[ok]), nse_ols = wet:::wet_nse(log(d$value[ok]), log(d$ols[ok])))
  }
  # day by day on the nearest covering donor
  dn <- chain[1]
  tq <- dmig[[g]]
  dq <- dmig[[dn]]
  pair <- merge(tq[tq$year %in% by, c("date", "q_m3s")], dq[dq$year %in% by, c("date", "q_m3s")], by = "date")
  pair <- pair[pair$q_m3s.x > 0 & pair$q_m3s.y > 0, ]
  if (nrow(pair) < 10) next
  cf <- stats::coef(stats::lm(log(q_m3s.x) ~ log(q_m3s.y), pair))
  dd <- dq[dq$year %in% d$year & dq$q_m3s > 0, ]
  if (!nrow(dd)) next
  ext <- data.frame(station_number = g, date = dd$date, q_m3s = exp(cf[[1]] + cf[[2]] * log(dd$q_m3s)))
  wsx <- wet_window_stats(ext, windows[windows$window == "migration", ], stats = "mean")
  i <- match(d$year, wsx$year)
  ok <- !is.na(i)
  if (sum(ok) >= 3) {
    dbd[[length(dbd) + 1]] <- data.frame(gauge = g, block = d$block[1],
      nse = wet:::wet_nse(log(d$value[ok]), log(wsx$value[i[ok]])),
      nse_ols = wet:::wet_nse(log(d$value[ok]), log(d$ols[ok])))
  }
}
alt_line <- function(label, r) {
  pg <- do.call(rbind, lapply(split(r, r$gauge), function(z) {
    data.frame(nse = stats::median(z$nse), nse_ols = stats::median(z$nse_ols))
  }))
  sprintf("  %-26s %6d %6d  median NSE %s; ols on the same years %s", label, nrow(pg), nrow(r),
          fmt(stats::median(pg$nse)), fmt(stats::median(pg$nse_ols)))
}
say("Other candidates, each over its own held-out years (migration mean, k = 5):", "",
    alt_line("multi-donor ols", do.call(rbind, multi)),
    sprintf("  (multi-donor: min(k, n - 2) = %d donors where the chain has them; blocks by donors used: %s)",
            min(k_main, 3), {
              nd <- table(do.call(rbind, multi)$n_donors)
              paste(sprintf("%s: %d", names(nd), as.integer(nd)), collapse = ", ")
            }),
    alt_line("(d) day by day", do.call(rbind, dbd)), "")

# leave-one-year-out at 08EE018, from the extension pool
mx <- g_mean[g_mean$station_number == pilot[["maxan"]], ]
loyo <- do.call(rbind, lapply(mx$year, function(y) {
  xb <- rbind(mx[mx$year != y, ], g_mean[g_mean$station_number %in% ext_pool, ])
  p <- vapply(methods, function(mt) {
    e <- wet_window_extend(xb, stations, pilot[["maxan"]], mt, k = k_main, level = level)
    e$value[e$year == y]
  }, 0)
  e <- wet_window_extend(xb, stations, pilot[["maxan"]], "ols", k = k_main, level = level)
  data.frame(year = y, obs = mx$value[mx$year == y], t(p), donor = e$donor[e$year == y])
}))
say(sprintf("Leave-one-year-out at %s (migration mean, m3/s; fit on the other four years):", pilot[["maxan"]]), "",
    sprintf("  %4s %8s %8s %8s %8s  %s", "year", "obs", methods[1], methods[2], methods[3], "donor"),
    sprintf("  %4d %8s %8s %8s %8s  %s", loyo$year, fmt(loyo$obs, 3), fmt(loyo$ols, 3), fmt(loyo$move1, 3),
            fmt(loyo$ratio, 3), loyo$donor),
    sprintf("  %-4s %8s %8s %8s %8s", "RMSE", "log", fmt(sqrt(mean(log(loyo$ols / loyo$obs)^2)), 3),
            fmt(sqrt(mean(log(loyo$move1 / loyo$obs)^2)), 3), fmt(sqrt(mean(log(loyo$ratio / loyo$obs)^2)), 3)),
    "")

# ---- question 2: donor-carried departures, held out ------------------------------------------
# The departure pool per statistic and window: >= 10 baseline years of it.
dep_pool_of <- function(v, p) {
  g <- wsel(v, p)
  nb <- table(g$station_number[g$year %in% baseline])
  sort(names(nb)[nb >= 10])
}
short_set <- pool$station_number[pool$short]

# One target's carried departures against its observed record, both centred
# on their mean over the years both have.
carry_score <- function(target, v, p, donors, k) {
  g <- wsel(v, p)
  a <- wet_departure_carry(g[g$station_number %in% setdiff(donors, target), ], stations, target, k = k,
                           baseline = baseline)
  o <- g[g$station_number == target, ]
  yrs <- intersect(o$year, a$year)
  if (length(yrs) < 3) return(data.frame(gauge = target, n = length(yrs), nse = NA_real_))
  obs <- tr_of(v)(o$value[match(yrs, o$year)])
  car <- a$anomaly[match(yrs, a$year)]
  data.frame(gauge = target, n = length(yrs), nse = wet:::wet_nse(obs - mean(obs), car - mean(car)))
}
carry_run <- function(v, p, k = k_main, drop = NULL) {
  dp <- dep_pool_of(v, p)
  held <- do.call(rbind, lapply(dp, function(g) carry_score(g, v, p, setdiff(dp, drop[[g]]), k)))
  sh <- do.call(rbind, lapply(short_set, function(g) {
    if (!any(wsel(v, p)$station_number == g)) return(data.frame(gauge = g, n = 0L, nse = NA_real_))
    carry_score(g, v, p, setdiff(dp, drop[[g]]), k)
  }))
  list(held = held, short = sh, v = v, p = p, k = k)
}
carry_sets <- list(
  list(label = "migration mean, k = 5", v = "q_mean", p = "migration", k = k_main),
  list(label = "k = 3", v = "q_mean", p = "migration", k = 3),
  list(label = "k = 8", v = "q_mean", p = "migration", k = 8),
  list(label = "spawning mean", v = "q_mean", p = "spawning", k = k_main),
  list(label = "migration min7", v = "q_min7", p = "migration", k = k_main),
  list(label = "spawning min7", v = "q_min7", p = "spawning", k = k_main),
  list(label = "migration cov_day (days)", v = "q_cov_day", p = "migration", k = k_main),
  list(label = "spawning cov_day (days)", v = "q_cov_day", p = "spawning", k = k_main))
if (!is.null(related)) {
  carry_sets[[length(carry_sets) + 1]] <- list(label = "leak-free", v = "q_mean", p = "migration", k = k_main,
                                               drop = related)
}
cruns <- lapply(carry_sets, function(s) carry_run(s$v, s$p, s$k, s$drop))
names(cruns) <- vapply(carry_sets, `[[`, "", "label")
cm <- cruns[[1]]
head_q <- stats::quantile(cm$held$nse, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE)
usable <- head_q[2] >= usable_nse - 1e-9

say("## 3. Donor-carried departures (question 2)", "",
    sprintf("Leave-one-gauge-out at the departure pool (%d gauges on the migration mean), k = 5 donors from the rest; scored on the years both series have, each centred on its mean over them (log NSE; 0 is no departure).",
            length(dep_pool_of("q_mean", "migration"))),
    sprintf("HEADLINE: median per-gauge NSE %s (quartiles %s to %s) over %d gauges scored; %d not scored (fewer than 3 years).",
            fmt(head_q[2]), fmt(head_q[1]), fmt(head_q[3]), sum(!is.na(cm$held$nse)), sum(is.na(cm$held$nse))),
    sprintf("USABLE for #122 (departure-pool median >= %s, set in the header): %s.", usable_nse, if (usable) "YES" else "NO"),
    sprintf("Short-record gauges, scored from the full departure pool: median NSE %s over %d scored (%d not scored).",
            fmt(stats::median(cm$short$nse, na.rm = TRUE)), sum(!is.na(cm$short$nse)), sum(is.na(cm$short$nse))),
    "", "By setting (median and quartiles over gauges; short-record median):", "",
    sprintf("  %-26s %5s %7s %7s %7s  %5s %7s", "setting", "n", "q25", "median", "q75", "short", "median"))
for (nm in names(cruns)) {
  r <- cruns[[nm]]
  q <- stats::quantile(r$held$nse, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE)
  say(sprintf("  %-26s %5d %7s %7s %7s  %5d %7s", nm, sum(!is.na(r$held$nse)), fmt(q[1]), fmt(q[2]), fmt(q[3]),
              sum(!is.na(r$short$nse)), fmt(stats::median(r$short$nse, na.rm = TRUE))))
}
if (is.null(related)) say(sprintf("  %-26s %s", "leak-free", snap_note))
say("", "Per gauge, migration mean, k = 5 (years scored, NSE):", "",
    paste0("  ", vapply(split(seq_len(nrow(cm$held)), ceiling(seq_len(nrow(cm$held)) / 4)), function(i) {
      paste(sprintf("%s %3d %6s", cm$held$gauge[i], cm$held$n[i], fmt(cm$held$nse[i])), collapse = "   ")
    }, "")),
    "", "Short-record gauges, migration mean, k = 5:", "",
    paste0("  ", vapply(split(seq_len(nrow(cm$short)), ceiling(seq_len(nrow(cm$short)) / 4)), function(i) {
      paste(sprintf("%s %3d %6s", cm$short$gauge[i], cm$short$n[i], fmt(cm$short$nse[i])), collapse = "   ")
    }, "")), "")

# ---- the Maxan answer ------------------------------------------------------------------------
mx_id <- pilot[["maxan"]]
combos <- list(c("q_mean", "migration"), c("q_mean", "spawning"), c("q_min7", "migration"),
               c("q_min7", "spawning"), c("q_cov_day", "migration"), c("q_cov_day", "spawning"),
               c("q_max", "migration"), c("q_max", "spawning"))
# the pseudo-record run behind each statistic and window (k = 5)
run_for <- function(v, p) {
  for (r in runs) if (r$v == v && r$p == p && r$k == k_main && !identical(r, runs[["leak-free"]])) return(r)
  stop("no pseudo-record run for ", v, " ", p, call. = FALSE)
}
pre <- function(y) y < 1981
post <- function(y) y %in% 2011:2025
set.seed(120)
n_boot <- 2000
mx <- list()
for (cb in combos) {
  v <- cb[1]
  p <- cb[2]
  tr <- tr_of(v)
  # max is reported, never scored, so it has no held-out residuals: its before/after change gets no
  # interval (its per-year values still carry OLS's prediction interval when OLS ships)
  res <- if (v == "q_max") NULL else run_for(v, p)$r[[paste0("r_", ship)]]
  g <- wsel(v, p)
  e <- wet_window_extend(g[g$station_number %in% c(mx_id, ext_pool), ], stations, mx_id, ship, k = k_main,
                         level = level, resid = if (ship == "ols") NULL else res)
  e$dep <- tr(e$value) - tr(mean(e$value[e$year %in% baseline]))
  a <- wet_departure_carry(g[g$station_number %in% setdiff(dep_pool_of(v, p), mx_id), ], stations, mx_id,
                           k = k_main, baseline = baseline)
  # before/after on the extension route: the baseline cancels in a difference of mean log values
  lv <- tr(e$value)
  ext_yr <- e$source == "extended"
  i_pre <- which(pre(e$year))
  i_post <- which(post(e$year))
  diff <- mean(lv[i_post]) - mean(lv[i_pre])
  boot <- if (is.null(res)) NA_real_ else vapply(seq_len(n_boot), function(b) {
    ip <- i_pre[sample.int(length(i_pre), replace = TRUE)]
    iq <- i_post[sample.int(length(i_post), replace = TRUE)]
    z <- lv + ifelse(ext_yr, sample(res, length(lv), replace = TRUE), 0)
    mean(z[iq]) - mean(z[ip])
  }, 0)
  ci <- stats::quantile(boot, c(q_lo, q_hi), names = FALSE, na.rm = TRUE)
  a_pre <- a$anomaly[pre(a$year)]
  a_post <- a$anomaly[post(a$year)]
  # the two routes as centred departures, over Maxan's observed years and over the record
  ov <- intersect(e$year[!ext_yr], a$year)
  oe <- e$dep[match(ov, e$year)]
  oa <- a$anomaly[match(ov, a$year)]
  rec <- intersect(e$year, a$year)
  re <- e$dep[match(rec, e$year)]
  ra <- a$anomaly[match(rec, a$year)]
  mx[[paste(v, p)]] <- list(v = v, p = p, e = e, a = a, diff = diff, ci = ci, n_pre = length(i_pre),
                            n_post = length(i_post), carried = mean(a_post) - mean(a_pre),
                            n_pre_c = length(a_pre), n_post_c = length(a_post),
                            obs_nse = if (length(ov) >= 3) wet:::wet_nse(oe - mean(oe), oa - mean(oa)) else NA_real_,
                            rec_r = stats::cor(re, ra), rec_n = length(rec), obs_n = length(ov),
                            rec_mad = mean(abs((re - mean(re)) - (ra - mean(ra)))))
}

m1 <- mx[["q_mean migration"]]
e1 <- m1$e
say("## 4. The Maxan answer", "",
    sprintf("%s extended by %s (the rule's pick), k = 5 covering donors from the extension pool, %d-%d; 90 %% intervals%s.",
            mx_id, ship, min(e1$year), max(e1$year),
            if (ship == "ols") " are OLS's prediction interval" else " from the pseudo-record residuals"),
    sprintf("Donor chain (nearest first): %s.", paste(attr(e1, "donors")[[1]], collapse = ", ")),
    "Years supplied per donor, migration mean:",
    paste0("  ", vapply(names(table(e1$donor)), function(d) {
      sprintf("%s %d years: %s", d, sum(e1$donor %in% d), year_runs(e1$year[e1$donor %in% d]))
    }, "")),
    "Limit: each extended year rests on one donor. Per series, the years before 1981 by source, and the earliest years:",
    vapply(mx, function(m) {
      e <- m$e
      tp <- table(ifelse(is.na(e$donor[pre(e$year)]), "observed", e$donor[pre(e$year)]))
      first_use <- sort(vapply(split(e$year[!is.na(e$donor)], e$donor[!is.na(e$donor)]), min, 0))
      cut <- first_use[[2]]
      # the chain donors with any value of this series before the cut, whichever of them supplied it
      g <- wsel(m$v, m$p)
      ch <- attr(e, "donors")[[1]]
      reach <- ch[vapply(ch, function(d) any(g$year[g$station_number == d] < cut), TRUE)]
      sprintf("  %s %s: %s; before %d, %s supplies every year (chain donors with a value then: %s).",
              m$p, sub("^q_", "", m$v), paste(sprintf("%d %s", as.integer(tp), names(tp)), collapse = ", "),
              as.integer(cut), names(first_use)[1], paste(reach, collapse = ", "))
    }, ""),
    "", "Before/after: mean departure 2011-2025 minus mean departure before 1981 (log, or days for cov_day);",
    sprintf("90 %% interval from %d draws resampling years in each period and adding a held-out residual to each extended year; set.seed(120).", n_boot),
    "", sprintf("  %-9s %-9s %4s %4s %9s %9s %18s   %9s %4s %4s", "statistic", "window", "pre", "post", "change",
                "% normal", "90 % interval", "carried", "pre", "post"))
for (m in mx) {
  days <- is_days(m$v)
  pc <- function(z) if (days) "-" else fmt(100 * (exp(z) - 1), 1)
  say(sprintf("  %-9s %-9s %4d %4d %9s %9s %18s   %9s %4d %4d", sub("^q_", "", m$v), m$p, m$n_pre, m$n_post,
              fmt(m$diff, 3), pc(m$diff),
              if (is.na(m$ci[1])) "-" else if (days) sprintf("%s..%s", fmt(m$ci[1], 1), fmt(m$ci[2], 1))
              else sprintf("%s..%s %%", pc(m$ci[1]), pc(m$ci[2])),
              fmt(m$carried, 3), m$n_pre_c, m$n_post_c))
}
say("", paste0("(% normal: 100 (exp(change) - 1). carried: the same change from the donor-carried departures, which need no Maxan baseline. max is reported, never scored, so its change has no interval",
           if (ship == "ols") "; its per-year values below carry OLS's prediction interval.)" else "; nor do its per-year values below.)"),
    "", "The two routes as centred departures: NSE of the carried against the extension's over Maxan's observed years; over the record, correlation and mean absolute difference:", "",
    sprintf("  %-9s %-9s %8s %8s  %8s %6s %9s", "statistic", "window", "obs yrs", "obs NSE", "rec yrs", "r", "mean |d|"))
for (m in mx) {
  say(sprintf("  %-9s %-9s %8d %8s  %8d %6s %9s", sub("^q_", "", m$v), m$p, m$obs_n, fmt(m$obs_nse), m$rec_n,
              fmt(m$rec_r), fmt(m$rec_mad, 3)))
}

# cd's departure and trend on the extended series
tr_rows <- list()
for (m in mx) {
  s <- data.frame(variable = m$v, period = m$p, year = m$e$year, value = m$e$value,
                  anomaly_type = if (is_days(m$v)) "absolute" else "pct_normal",
                  unit = if (is_days(m$v)) "days" else "%")
  an <- cd::cd_anomaly(s, suppressWarnings(cd::cd_baseline(s, baseline)))
  tr_rows[[length(tr_rows) + 1]] <- cd::cd_trend(an, trend_start = c(min(s$year), 1981))
}
trd <- do.call(rbind, tr_rows)
say("", "Trend in cd's anomaly of the extended series (cd_trend(): Theil-Sen slope per year, Mann-Kendall p; % of normal capped at 200, or days):", "",
    sprintf("  %-9s %-9s %5s %9s %7s %4s", "statistic", "window", "from", "slope/yr", "p", "n"),
    sprintf("  %-9s %-9s %5d %9s %7s %4d", sub("^q_", "", trd$variable), trd$period, as.integer(trd$trend_start),
            fmt(trd$slope, 3), fmt(trd$mk_pvalue, 3), as.integer(trd$n_years)))

for (m in mx) {
  days <- is_days(m$v)
  dep_txt <- function(z) if (days) fmt(z, 1) else fmt(100 * (exp(z) - 1), 1)
  say("", sprintf("%s per year, %s %s (%s): value with the 90 %% interval and the donor; its departure from the extended series' own 1981-2010 mean, and the carried departure (%s):",
                  mx_id, m$p, sub("^q_", "", m$v), if (days) "day of the window" else "m3/s",
                  if (days) "days" else "% of normal"), "",
      sprintf("  %4s %8s %8s %8s %-8s %9s %9s", "year", "value", "lo", "hi", "donor", "departure", "carried"))
  e <- m$e
  for (y in sort(union(e$year, m$a$year))) {
    i <- match(y, e$year)
    k <- match(y, m$a$year)
    say(sprintf("  %4d %8s %8s %8s %-8s %9s %9s", y, fmt(e$value[i], 2), fmt(e$lower[i], 2), fmt(e$upper[i], 2),
                if (is.na(i)) "-" else if (is.na(e$donor[i])) "observed" else e$donor[i],
                if (is.na(i)) "-" else dep_txt(e$dep[i]), if (is.na(k)) "-" else dep_txt(m$a$anomaly[k])))
  }
}

writeLines(out, report)
