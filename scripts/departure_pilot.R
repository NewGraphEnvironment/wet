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
