# The Maxan method at other Chinook streams (#126, component of #118): a
# short-record gauge's window flows extended from its long-record neighbours,
# and donor-carried departures scored held out at every gauge in the site's
# box; at a stream with no gauge, carried departures alone, laid on wet's
# published flow there. The rule below is #120's (the header of
# scripts/departure_pilot.R, retired in #146), taken over per site and fixed
# at what shipped for Maxan. It was committed in this header alone, before any
# body code (planning/archive, issue 126).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_site.R <site_id>
#
# <site_id> is a row of scripts/departure_sites.csv (scripts/departure_site_lib.R,
# site_get()): its box, its target (a HYDAT station, or for an ungauged site
# a blue line and its mouth), and the watershed groups whose Chinook windows
# it runs under (inst/vignette-data/life_history_<group>.csv, BULK first).
# One run per window set; each writes the tracked report
# data/checks/departure_site_<site>_<group>_20260717.txt (no timestamp, so a
# rerun reproduces it byte for byte) and, after it, the gitignored
# data/departure/departure_site_<site>_<group>_20260717.rds: `site`,
# `windows`, `release`, `ship`, `k_main`, `baseline`, `level`, `mx` (the
# target's series per statistic and window, as the pilot's; the carried
# donors per year are in `mx[[...]]$a$donors`), `ws` (the box pool's window
# statistics before the value > 0 filter), `stations`, `pool`, `race` (the
# extension race's medians, #120's pick, gauges, below the floor), `carried`
# (the held-out carried headline), `normal` (ungauged only) and `code_md5` (the md5 of the script file Rscript runs, as
# it stands at the start of the run). Run a frozen copy
# (cp scripts/departure_site.R "$TMPDIR/s.R" && Rscript "$TMPDIR/s.R" <site>),
# as for the pilot. Nothing is published and no fit is read or touched.
#
# Reads HYDAT 20260717 only, and fwapg through libpq's bare PG* variables, as
# the pilot does, for the snaps behind the leak-free sensitivity and the
# normal's error (so the maxan row's leak-free lines are the pilot report's);
# the published product through wet_catalog() and its parts over HTTPS.
#
# ---- what is #120's, unchanged ------------------------------------------------------------------
#
# Statistics (mean, min7, cov_day scored; max reported), the baseline
# (1981-2010), the log-ratio scale, HYDAT approved days only, a complete
# window-year (min_frac 0.8; cov_day every day), the four pools (box,
# extension, departure, short-record) and their thresholds, the predictors
# (easting, northing, log area, each over its box-pool SD), k = 5 with k = 3
# and 8 as sensitivities, the donor availability rules, question 1's
# pseudo-short-record test (tiled 5-year blocks, leave-gauge-out, NSE of log
# values on held-out years, per-gauge median, median over gauges) and its
# sensitivities, question 2's leave-one-gauge-out centred NSE and its
# sensitivities, the usable threshold (departure-pool median >= 0.5), the
# leak-free sensitivity, the target's answer (extended series, departures
# from its own 1981-2010 mean, the carried route beside it, the two routes
# compared, the before/after with its 2000-draw bootstrap under
# set.seed(120), cd's baseline, anomaly and trend), and the report's sections.
#
# ---- what changes per site (decided at #126's plan gate, user, 2026-10-28) ------------------------
#
# The box is the site's. Maxan's row carries #120's box verbatim; every other
# box is the same size (3.8 deg by 2.2 deg) centred on the target.
#
# The method is fixed at Maxan's. The target is extended by OLS (k = 5),
# whatever the race returns. The race of ols, move1 and ratio still runs in
# every box, and the report says which candidate #120's rule (highest median,
# 0.01 over ratio) would pick there. That decides nothing. Fewer than 15
# extension-pool gauges with a pseudo-record no longer stops the run: the
# report flags the box as below #120's floor and goes on.
#
# The carried departures are #120's: inverse distance, k = 5, from the
# departure pool less the target (not #122's covariance_pick).
#
# The windows: each window set the site names gets its own run and report, so a
# site runs under the Bulkley windows and, where cited windows exist for its
# own group, under those too.
#
# The target, an extend site: the site's target_station, which must be in the
# box pool (>= 3 complete migration years). The leave-one-year-out at the
# target (#120 did it at 08EE018) runs at every extend target. The
# short-record set is the box's 3..10-year gauges, the target among them only
# where it qualifies.
#
# The target, an ungauged site: there is no record to extend, so question 1's
# race runs in the box (it scores the box) and the target gets only carried
# departures, per statistic and window, k = 5 from the departure pool, under
# the predictors of a station at the mouth: the site's target_lon/target_lat
# and, for area, the fundamental watersheds whose wscode_ltree descends from
# the blue line's (the stream's whole basin), refused unless within 0.1 km2 of
# data/checks/chinook_sites_use.txt's area for it. The target's row joins the
# station table for its own carry alone; every held-out test runs on the box
# pool's table, so the predictor SDs there are the pool's (amended before any
# body code, after the plan review: a target row in the shared table would move
# every box score). The FWA area stands in for a HYDAT gross area. Its window flow per year is
# the published normal (below) times exp(carried departure), for the window
# mean only. min7 and cov_day get departures only, because the product
# publishes no normal for them. The report says that the result at the
# ungauged point itself is untested: there is nothing there to score against.
#
# The normal (ungauged only): wet's published segment_daily (wet_catalog(),
# the part for the site's group, read with duckdb over HTTPS) on the mouth
# segment, the lowest-measure segment on the blue line that has rows in the
# part. Each source's window mean comes from its days (wet_flow_window(),
# basis "daily"), and the normal is the `pick` source's. Both sources and the
# pick are reported, with the build's tree digest (wet:::wet_catalog_digest())
# and the md5 of each part read, so a rerun on another build shows itself.
#
# The normal's error: at every box gauge in the migration-mean departure pool
# whose snap (wet_station_snap()) is accepted, the published pick's window mean
# on the snapped segment against the gauge's observed 1981-2010 mean of that
# window's complete years (at least 10 of them, the departure pool's floor,
# stated after the code review; every gauge of the Gosnell box meets it). Each is reported as a log ratio, with its source.
# A gauge in the water balance's station set (data/wb/stations_20260717.rds,
# `stations`) is flagged, because the balance publishes a calibration gauge's
# own observed monthly shares, so there it is partly in sample. Reported: the
# median and quartiles of the log ratio over all of these gauges and over the
# unflagged ones, per window. It decides nothing.
#
# New in #126, at every site, deciding nothing: a 90 % interval on the
# carried before/after change (2011-2025 against the years before 1981),
# from 2000 draws that resample years within each period and add to each year
# a residual drawn from the box's held-out carried residuals for that
# statistic and window (each departure-pool gauge's centred observed minus
# centred carried log value, or days, over its scored years, all gauges
# pooled), under set.seed(126) after the extension's bootstrap, so the
# extension's draws are #120's. For an ungauged site this is the headline.
#
# New in #152, at every site, deciding nothing here: the change on both routes
# from 1951-1980 to 2016-2025 (the periods the comparison article uses, set by
# the user at #152's gate), for every statistic and window, computed after
# #126's draws so that neither #120's nor #126's move. Each route's change is
# its mean over the 2016-2025 years minus its mean over the 1951-1980 years,
# with a 90 % interval from 2000 draws that resample years within each period
# and add a held-out residual as #120 (extended years only) and #126 (every
# carried year) do, under set.seed(152). Reported with each period's years,
# and the gauges the 1951-1980 years rest on: the extension donors with the
# years each supplies, and the carried donors named in any of those years.
# Then the interval's coverage, measured: for each change with an interval,
# 1000 simulated series with no change, each period's years drawn normal with
# the series' own standard deviation over that period's years (an extended
# series keeps which years are observed), each put through the same interval
# with 500 draws and the same residual pool; the share of the 1000 whose
# interval covers zero, under set.seed(1520). The comparison article calls the
# interval a 90 % range only if every coverage it draws on is at least 0.87;
# otherwise it calls it the middle 90 % of resampled changes and rests no count
# on it. The rds gains `p152` in each `mx` entry; no line #120's report
# prints depends on it.
#
# ---- the parity gate ----------------------------------------------------------------------------
#
# The maxan row under the BULK windows must reproduce #120's run, whose
# tracked report data/checks/departure_pilot_20260717.txt is its record since
# scripts/departure_pilot.R was retired (#146). Every table row of that
# report must appear verbatim in the site report, at the precision it prints
# (section 4's change table without the carried change's % normal and
# interval, which the site report adds), and so must its pool counts line and
# section 3's HEADLINE and short-record lines (site_parity_pilot() in
# scripts/departure_site_lib.R; tests/testthat/test-departure_site_parity.R
# holds the tracked site report to it). The run stops before writing anything
# otherwise. Until #146 the gate also compared `mx` bit for bit with the
# pilot's saved series.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a site_id not in the table; a target
# outside its box; an extend target not in the box pool; an ungauged blue line
# with no watershed code, or with no segment in the published part; a window
# set whose CSV lacks one CH migration and one CH spawning row; the parity
# gate above; the usual refusals of wet_window_extend() and
# wet_departure_carry().


devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/departure_site_lib.R")  # site_get(), site_windows(), site_in_box()

release <- wb_release()
if (release != "20260717") stop("the rule names HYDAT 20260717, not ", release, call. = FALSE)
# the script this run executes (a frozen copy, say), hashed before anything else can change it
# (Rscript writes a space in the path as ~+~)
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, not through source(), so the script's own md5 can be recorded", call. = FALSE)
}
code_md5 <- unname(tools::md5sum(self))
if (is.na(code_md5)) stop("cannot read the running script at ", self, " to record its md5", call. = FALSE)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript scripts/departure_site.R <site_id>", call. = FALSE)
site <- site_get(args)
wsets <- site_windows(site)
hydat <- wb_hydat(release)
baseline <- 1981:2010
box <- site$box
target <- if (site$kind == "extend") site$target_station else site$site_id
k_main <- 5
level <- 0.9
margin <- 0.01
usable_nse <- 0.5
min_pseudo_gauges <- 15
n_boot <- 2000
fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))

# ---- the pool, the same for every window set ---------------------------------------------------
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
if (site$kind == "extend") {
  tg <- st_all[st_all$station_number == target, ]
  if (nrow(tg) != 1) stop(target, " is not a natural BC gauge with coordinates and area in the box", call. = FALSE)
  site_in_box(site, tg$lon, tg$lat)
}
daily <- suppressWarnings(wet_station_daily(st_all$station_number, hydat, to = NULL, sources = "hydat"))

# fwapg through libpq's bare PG*, as the pilot: the snaps behind the leak-free
# sensitivity and the normal's error, and the ungauged target's stream
conn <- tryCatch(DBI::dbConnect(RPostgres::Postgres()), error = function(e) NULL)

# the ungauged target: its mouth, its basin area and its station row
mouth <- NULL
if (site$kind == "ungauged") {
  if (is.null(conn)) stop("an ungauged site needs fwapg through the PG* variables", call. = FALSE)
  code <- DBI::dbGetQuery(conn, sprintf("
    SELECT DISTINCT wscode_ltree::text wscode FROM whse_basemapping.fwa_stream_networks_sp
    WHERE blue_line_key = %d AND blue_line_key = watershed_key AND gnis_name IS NOT NULL", site$blue_line_key))
  if (nrow(code) != 1) stop(site$site_id, ": blue line ", site$blue_line_key, " has no single watershed code", call. = FALSE)
  km2 <- DBI::dbGetQuery(conn, sprintf("
    SELECT sum(ST_Area(geom) ORDER BY watershed_feature_id) / 1e6 km2 FROM whse_basemapping.fwa_watersheds_poly
    WHERE wscode_ltree <@ '%s'::ltree", code$wscode))$km2   # a float sum in a fixed order
  use <- readLines(file.path("data", "checks", "chinook_sites_use.txt"))
  row <- grep(sprintf(" %d ", site$blue_line_key), use, value = TRUE)
  # the km2 column follows the role column; a stream name has spaces in it
  use_km2 <- if (length(row) == 1) suppressWarnings(as.numeric(sub("^.* (extend|morice|dropped) +([0-9.]+) .*$", "\\2", row))) else NA_real_
  if (is.na(use_km2) || abs(km2 - use_km2) > 0.1) {
    stop(site$site_id, ": basin area ", round(km2, 1), " km2 differs from chinook_sites_use.txt's ", use_km2, call. = FALSE)
  }
  segs <- DBI::dbGetQuery(conn, sprintf("
    SELECT linear_feature_id, downstream_route_measure, edge_type, wscode_ltree::text wscode, localcode_ltree::text localcode
    FROM whse_basemapping.fwa_stream_networks_sp WHERE blue_line_key = %d
    ORDER BY downstream_route_measure, linear_feature_id", site$blue_line_key))
  mouth <- list(wscode = code$wscode, km2 = km2, segs = segs)
}

# ---- snaps (fwapg, when reachable), every natural box gauge; relations per window set's pool ----
sn_all <- NULL
if (!is.null(conn)) {
  sn_all <- wet_station_snap(conn, st_all[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
  sn_all <- sn_all[match(st_all$station_number, sn_all$station_number), ]
}
sn <- sn_all

# ---- the published flow (ungauged only) --------------------------------------------------------
pub <- NULL
if (site$kind == "ungauged") {
  catalog <- wet_catalog()
  dly <- catalog[catalog$dataset == "discharge/fwa/v1/segment_daily" & catalog$scenario == "historical", ]
  duck <- DBI::dbConnect(duckdb::duckdb())
  DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;")
  read_days <- function(groups, ids) {
    parts <- dly[dly$code %in% groups, ]
    # the source is a Hive key, not a column: take it from the catalog, as wet_segment_parts() does
    d <- do.call(rbind, lapply(seq_len(nrow(parts)), function(i) {
      x <- DBI::dbGetQuery(duck, sprintf(
        "SELECT linear_feature_id, doy, q_m3s, pick, period FROM read_parquet(%s, hive_partitioning = false)
         WHERE linear_feature_id IN (%s) ORDER BY linear_feature_id, doy",
        DBI::dbQuoteString(duck, parts$href[i]), paste(as.integer(ids), collapse = ",")))
      x$source <- rep(parts$source[i], nrow(x))
      x
    }))
    list(d = d, parts = parts[c("source", "code", "md5")])
  }
  # the mouth segment: the lowest-measure segment on the blue line with rows in the site group's part
  m_read <- read_days(site$wsg_code, mouth$segs$linear_feature_id)
  have <- unique(m_read$d$linear_feature_id)
  i_mouth <- which(mouth$segs$linear_feature_id %in% have)[1]
  if (is.na(i_mouth)) stop(site$site_id, ": no segment of blue line ", site$blue_line_key, " in the published part", call. = FALSE)
  mouth$segment <- mouth$segs[i_mouth, ]
  md <- m_read$d[m_read$d$linear_feature_id == mouth$segment$linear_feature_id, ]
  # box gauges for the normal's error: the migration-mean departure pool, accepted snaps (set below per window set)
  gauge_groups <- NULL
  if (!is.null(sn)) {
    ids <- sn$linear_feature_id[sn$accepted %in% TRUE]
    gauge_groups <- DBI::dbGetQuery(conn, sprintf(
      "SELECT linear_feature_id, watershed_group_code FROM whse_basemapping.fwa_stream_networks_sp
       WHERE linear_feature_id IN (%s) ORDER BY linear_feature_id", paste(as.integer(ids), collapse = ",")))
  }
  g_read <- if (is.null(gauge_groups)) NULL else read_days(sort(unique(gauge_groups$watershed_group_code)),
                                                          gauge_groups$linear_feature_id)
  DBI::dbDisconnect(duck, shutdown = TRUE)
  pick_of <- function(d) {
    p <- unique(d[d$pick %in% TRUE, c("linear_feature_id", "source")])
    if (anyDuplicated(p$linear_feature_id)) stop("a segment has two picked sources", call. = FALSE)
    p
  }
  pub <- list(digest = wet:::wet_catalog_digest(catalog), mouth = md, mouth_parts = m_read$parts,
              gauges = g_read$d, gauge_parts = g_read$parts, groups = gauge_groups, pick_of = pick_of)
}
if (!is.null(conn)) DBI::dbDisconnect(conn)

calib <- readRDS(file.path("data", "wb", sprintf("stations_%s.rds", release)))$stations$station_number

# ---- one run per window set ------------------------------------------------------------------
for (wname in names(wsets)) {
windows <- wsets[[wname]][c("window", "start", "end")]
wsource <- wsets[[wname]]$source[1]
report <- file.path("data", "checks", sprintf("departure_site_%s_%s_%s.txt", site$site_id, tolower(wname), release))
out <- character()
say <- function(...) out <<- c(out, ...)

ws <- wet_window_stats(daily, windows, stats = c("mean", "min7", "max", "cov_day"))
ws <- ws[c("station_number", "variable", "period", "year", "value", "anomaly_type", "unit")]
n_mig_all <- vapply(st_all$station_number, function(s) {
  sum(ws$station_number == s & ws$period == "migration" & ws$variable == "q_mean")
}, 0L)
pool <- st_all[n_mig_all >= 3, ]
rownames(pool) <- NULL
if (site$kind == "extend" && !target %in% pool$station_number) {
  stop(target, " has fewer than 3 complete migration windows: not in the box pool", call. = FALSE)
}
xy <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(pool, coords = c("lon", "lat"), crs = 4326), 3005))
pool$e_km <- xy[, 1] / 1000
pool$n_km <- xy[, 2] / 1000
ws <- ws[ws$station_number %in% pool$station_number, ]
stations <- pool[c("station_number", "lon", "lat", "drainage_area_gross_km2")]
# the target's own station table: the pool's, plus an ungauged target's row
stations_t <- if (site$kind == "ungauged") {
  rbind(stations, data.frame(station_number = target, lon = site$target_lon, lat = site$target_lat,
                             drainage_area_gross_km2 = mouth$km2))
} else {
  stations
}

# leak-free relations: the pool's gauges upstream or downstream of each other
related <- NULL
snap_note <- "not run: no fwapg database reachable through the PG* env vars"
if (!is.null(sn_all)) {
  sp <- sn_all[match(pool$station_number, sn_all$station_number), ]
  ok <- sp$accepted %in% TRUE
  up <- matrix(FALSE, nrow(sp), nrow(sp), dimnames = list(sp$station_number, sp$station_number))
  for (i in which(ok)) up[i, ok] <- wet:::wet_fwa_upstream(sp$wscode[i], sp$localcode[i], sp$wscode[ok], sp$localcode[ok])
  diag(up) <- FALSE
  rel <- up | t(up)
  related <- lapply(stats::setNames(rownames(rel), rownames(rel)), function(g) colnames(rel)[rel[g, ]])
  snap_note <- sprintf("run: %d of %d box-pool gauges snapped and accepted (wet_station_snap()); %d unaccepted keep every donor%s.",
                       sum(ok), nrow(sp), sum(!ok),
                       if (any(!ok)) paste0(" (", paste(sp$station_number[!ok], collapse = ", "), ")") else "")
}

years_of <- function(st, w = "migration", v = "q_mean") {
  sort(ws$year[ws$station_number == st & ws$period == w & ws$variable == v])
}
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
pool$short <- pool$n_mig >= 3 & pool$n_mig <= 10

say(sprintf("# %s Chinook pilot (%s, %s windows): extended window flows and donor-carried departures (#126)",
            site$name, site$site_id, wname), "",
    sprintf("HYDAT %s, approved daily flows only. Rule: #120's, taken over per site in scripts/departure_site.R's header, registered at efc23f1 (amended dc33a61) before any body code.", release),
    sprintf("Site (scripts/departure_sites.csv): %s, %s; target %s%s.", site$site_id, site$kind,
            if (site$kind == "extend") target else sprintf("%s (blue line %d, mouth %s, %s)", site$name, site$blue_line_key,
                                                          site$target_lon, site$target_lat),
            if (site$kind == "ungauged") sprintf(", %s km2 at the mouth", fmt(mouth$km2, 1)) else ""),
    sprintf("Windows (CH, %s, inst/vignette-data/life_history_%s.csv): %s.", wsource, tolower(wname),
            paste(sprintf("%s %s..%s", windows$window, windows$start, windows$end), collapse = ", ")),
    sprintf("Box: natural (REGULATED = 0) BC gauges, lon %s..%s, lat %s..%s. Baseline %d-%d.",
            box[["lon_min"]], box[["lon_max"]], box[["lat_min"]], box[["lat_max"]], min(baseline), max(baseline)),
    "A complete window-year: at least 80 % of the window's days present, inside the record (wet_window_stats(), min_frac = 0.8).",
    "Extension fixed at ols, k = 5 (#126's gate); carried departures inverse-distance, k = 5.",
    "", "## 1. The pool", "",
    sprintf("Natural box gauges in STATIONS: %d; excluded for no drainage area or coordinates: %d%s.",
            nrow(st_all) + length(no_meta), length(no_meta),
            if (length(no_meta)) paste0(" (", paste(no_meta, collapse = ", "), ")") else ""),
    sprintf("Box pool (>= 3 complete migration years): %d. Extension pool (>= 30 and a 5-year run): %d. Departure pool (>= 10 baseline migration years): %d. Short-record (3..10 years): %d.",
            nrow(pool), sum(pool$ext), sum(pool$dep), sum(pool$short)),
    if (site$kind == "extend") sprintf("Target, complete migration-window years by this definition: %s %d (%s).", target,
                                       pool$n_mig[pool$station_number == target],
                                       year_runs(years_of(target))) else
      "Target: ungauged; no record.",
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

# ---- question 1: the pseudo-short-record test ------------------------------------------------
methods <- c("ols", "move1", "ratio")
ext_pool <- pool$station_number[pool$ext]
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
if (is.null(main$r)) stop("no extension-pool gauge holds a scored pseudo-record in this box", call. = FALSE)
below_floor <- main$n[["gauges"]] < min_pseudo_gauges
main_pg <- pseudo_score(main)
dec <- decide(main_pg)
ship <- "ols"   # fixed at #126's gate; dec$ship is what #120's rule would pick
qs <- function(v) fmt(stats::quantile(v, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE))

say("## 2. Record extension (question 1)", "",
    sprintf("Extension pool: %d gauges; %d hold at least one 5-year block (%d without one). Blocks: %d; dropped for no covering donor %d, for fewer than 3 held-out years %d. Window-years <= 0 dropped from the log score: %d.",
            length(ext_pool), main$n[["gauges"]], main$n[["no_block"]], main$n[["blocks"]],
            main$n[["no_donor"]], main$n[["few_held"]], main$n[["dropped_le0"]]),
    if (below_floor) sprintf("BELOW #120's FLOOR: %d gauges hold a pseudo-record, fewer than %d; the race is reported and the run goes on (#126's header).",
                             main$n[["gauges"]], min_pseudo_gauges),
    sprintf("Scored: %d blocks at %d gauges; %d held-out block-years, %d distinct gauge-years.",
            nrow(unique(main$r[c("gauge", "block")])), length(unique(main$r$gauge)), nrow(main$r),
            nrow(unique(main$r[c("gauge", "year")]))),
    "", "Migration-window mean, log NSE on held-out years, k = 5. Per gauge the median over its blocks; across gauges:", "",
    sprintf("  %-6s %8s %8s %8s", "method", "q25", "median", "q75"))
for (mt in methods) say(sprintf("  %-6s %8s %8s %8s", mt, qs(main_pg[[mt]])[1], qs(main_pg[[mt]])[2], qs(main_pg[[mt]])[3]))
say("", sprintf("#120's rule here: the highest median is %s (%s); ratio's is %s; margin %s. It would pick %s. The target is extended by ols (fixed at #126's gate)%s.",
                dec$best, fmt(dec$med[[dec$best]], 3), fmt(dec$med[["ratio"]], 3), margin, dec$ship,
                if (dec$ship == "ols") ", which #120's rule also picks here" else ", which #120's rule would NOT pick here"),
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
  if (is.null(run$r)) return(sprintf("  %-26s no scored pseudo-record", label))
  pg <- pseudo_score(run)
  d <- decide(pg)
  sprintf("  %-26s %6d %6d %7s %7s %7s  %-6s %s", label, nrow(pg), nrow(unique(run$r[c("gauge", "block")])),
          fmt(d$med[["ols"]]), fmt(d$med[["move1"]]), fmt(d$med[["ratio"]]), d$ship,
          paste(sprintf("%s %s", methods, fmt(100 * pseudo_coverage(run), 0)), collapse = " "))
}
say("Sensitivities (median over gauges of per-gauge median NSE; 'rule' is what #120's rule would pick there; coverage %):", "",
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
dmig <- daily[daily$station_number %in% pool$station_number & in_window(daily$date, "migration"),
              c("station_number", "date", "q_m3s")]
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
  if (is.null(r)) return(sprintf("  %-26s none scored", label))
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

# leave-one-year-out at the target, from the extension pool
if (site$kind == "extend") {
  mx_obs <- g_mean[g_mean$station_number == target, ]
  loyo <- do.call(rbind, lapply(mx_obs$year, function(y) {
    xb <- rbind(mx_obs[mx_obs$year != y, ], g_mean[g_mean$station_number %in% ext_pool, ])
    p <- vapply(methods, function(mt) {
      e <- wet_window_extend(xb, stations, target, mt, k = k_main, level = level)
      e$value[e$year == y]
    }, 0)
    e <- wet_window_extend(xb, stations, target, "ols", k = k_main, level = level)
    data.frame(year = y, obs = mx_obs$value[mx_obs$year == y], t(p), donor = e$donor[e$year == y])
  }))
  say(sprintf("Leave-one-year-out at %s (migration mean, m3/s; fit on the other %d years):", target, nrow(mx_obs) - 1), "",
      sprintf("  %4s %8s %8s %8s %8s  %s", "year", "obs", methods[1], methods[2], methods[3], "donor"),
      sprintf("  %4d %8s %8s %8s %8s  %s", loyo$year, fmt(loyo$obs, 3), fmt(loyo$ols, 3), fmt(loyo$move1, 3),
              fmt(loyo$ratio, 3), loyo$donor),
      sprintf("  %-4s %8s %8s %8s %8s", "RMSE", "log", fmt(sqrt(mean(log(loyo$ols / loyo$obs)^2)), 3),
              fmt(sqrt(mean(log(loyo$move1 / loyo$obs)^2)), 3), fmt(sqrt(mean(log(loyo$ratio / loyo$obs)^2)), 3)),
      "")
}

# ---- question 2: donor-carried departures, held out ------------------------------------------
# The departure pool per statistic and window: >= 10 baseline years of it.
dep_pool_of <- function(v, p) {
  g <- wsel(v, p)
  nb <- table(g$station_number[g$year %in% baseline])
  sort(names(nb)[nb >= 10])
}
short_set <- pool$station_number[pool$short]
# a median that is NA, not NULL, for a box with no short-record gauge (NULL drops a report line silently)
med_na <- function(x) if (length(x) && any(!is.na(x))) stats::median(x, na.rm = TRUE) else NA_real_

# One target's carried departures against its observed record, both centred
# on their mean over the years both have; the centred residuals ride along.
carry_score <- function(target, v, p, donors, k) {
  g <- wsel(v, p)
  a <- wet_departure_carry(g[g$station_number %in% setdiff(donors, target), ], stations, target, k = k,
                           baseline = baseline)
  o <- g[g$station_number == target, ]
  yrs <- intersect(o$year, a$year)
  if (length(yrs) < 3) return(list(row = data.frame(gauge = target, n = length(yrs), nse = NA_real_), resid = numeric()))
  obs <- tr_of(v)(o$value[match(yrs, o$year)])
  car <- a$anomaly[match(yrs, a$year)]
  list(row = data.frame(gauge = target, n = length(yrs), nse = wet:::wet_nse(obs - mean(obs), car - mean(car))),
       resid = (obs - mean(obs)) - (car - mean(car)))
}
carry_run <- function(v, p, k = k_main, drop = NULL) {
  dp <- dep_pool_of(v, p)
  hs <- lapply(dp, function(g) carry_score(g, v, p, setdiff(dp, drop[[g]]), k))
  held <- do.call(rbind, lapply(hs, `[[`, "row"))
  sh <- do.call(rbind, lapply(short_set, function(g) {
    if (!any(wsel(v, p)$station_number == g)) return(data.frame(gauge = g, n = 0L, nse = NA_real_))
    carry_score(g, v, p, setdiff(dp, drop[[g]]), k)$row
  }))
  list(held = held, short = sh, resid = unlist(lapply(hs, `[[`, "resid")), v = v, p = p, k = k)
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
    sprintf("USABLE (departure-pool median >= %s, #120's threshold): %s.", usable_nse, if (usable) "YES" else "NO"),
    sprintf("Short-record gauges, scored from the full departure pool: median NSE %s over %d scored (%d not scored).",
            fmt(med_na(cm$short$nse)), sum(!is.na(cm$short$nse)), sum(is.na(cm$short$nse))),
    "", "By setting (median and quartiles over gauges; short-record median):", "",
    sprintf("  %-26s %5s %7s %7s %7s  %5s %7s", "setting", "n", "q25", "median", "q75", "short", "median"))
for (nm in names(cruns)) {
  r <- cruns[[nm]]
  q <- stats::quantile(r$held$nse, c(0.25, 0.5, 0.75), na.rm = TRUE, names = FALSE)
  say(sprintf("  %-26s %5d %7s %7s %7s  %5d %7s", nm, sum(!is.na(r$held$nse)), fmt(q[1]), fmt(q[2]), fmt(q[3]),
              sum(!is.na(r$short$nse)), fmt(med_na(r$short$nse))))
}
if (is.null(related)) say(sprintf("  %-26s %s", "leak-free", snap_note))
say("", "Per gauge, migration mean, k = 5 (years scored, NSE):", "",
    paste0("  ", vapply(split(seq_len(nrow(cm$held)), ceiling(seq_len(nrow(cm$held)) / 4)), function(i) {
      paste(sprintf("%s %3d %6s", cm$held$gauge[i], cm$held$n[i], fmt(cm$held$nse[i])), collapse = "   ")
    }, "")),
    "", "Short-record gauges, migration mean, k = 5:", "",
    if (length(short_set)) paste0("  ", vapply(split(seq_len(nrow(cm$short)), ceiling(seq_len(nrow(cm$short)) / 4)), function(i) {
      paste(sprintf("%s %3d %6s", cm$short$gauge[i], cm$short$n[i], fmt(cm$short$nse[i])), collapse = "   ")
    }, "")) else "  none", "")

# ---- the target's answer ---------------------------------------------------------------------
combos <- list(c("q_mean", "migration"), c("q_mean", "spawning"), c("q_min7", "migration"),
               c("q_min7", "spawning"), c("q_cov_day", "migration"), c("q_cov_day", "spawning"),
               c("q_max", "migration"), c("q_max", "spawning"))
# the pseudo-record run behind each statistic and window (k = 5)
run_for <- function(v, p) {
  for (r in runs) if (r$v == v && r$p == p && r$k == k_main && !identical(r, runs[["leak-free"]])) return(r)
  stop("no pseudo-record run for ", v, " ", p, call. = FALSE)
}
# the held-out carried run behind each statistic and window (k = 5), NULL for max
crun_for <- function(v, p) {
  for (nm in names(cruns)) {
    r <- cruns[[nm]]
    if (r$v == v && r$p == p && r$k == k_main && nm != "leak-free") return(r)
  }
  NULL
}
pre <- function(y) y < 1981
post <- function(y) y %in% 2011:2025
carry_target <- function(v, p) {
  g <- wsel(v, p)
  wet_departure_carry(g[g$station_number %in% setdiff(dep_pool_of(v, p), target), ], stations_t, target,
                      k = k_main, baseline = baseline)
}
set.seed(120)
mx <- list()
for (cb in combos) {
  v <- cb[1]
  p <- cb[2]
  tr <- tr_of(v)
  a <- carry_target(v, p)
  if (site$kind == "ungauged") {
    mx[[paste(v, p)]] <- list(v = v, p = p, e = NULL, a = a, carried = mean(a$anomaly[post(a$year)]) -
                                mean(a$anomaly[pre(a$year)]), n_pre_c = sum(pre(a$year)), n_post_c = sum(post(a$year)))
    next
  }
  # max is reported, never scored, so it has no held-out residuals: its before/after change gets no
  # interval (its per-year values still carry OLS's prediction interval)
  res <- if (v == "q_max") NULL else run_for(v, p)$r[[paste0("r_", ship)]]
  g <- wsel(v, p)
  e <- wet_window_extend(g[g$station_number %in% c(target, ext_pool), ], stations, target, ship, k = k_main,
                         level = level, resid = NULL)
  e$dep <- tr(e$value) - tr(mean(e$value[e$year %in% baseline]))
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
  # the two routes as centred departures, over the target's observed years and over the record
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
# new in #126: the carried change's interval, after the extension's draws
set.seed(126)
for (nm in names(mx)) {
  m <- mx[[nm]]
  cr <- crun_for(m$v, m$p)
  res_c <- if (is.null(cr)) numeric() else cr$resid
  a <- m$a
  i_pre <- which(pre(a$year))
  i_post <- which(post(a$year))
  boot <- if (!length(res_c) || !length(i_pre) || !length(i_post)) NA_real_ else vapply(seq_len(n_boot), function(b) {
    ip <- i_pre[sample.int(length(i_pre), replace = TRUE)]
    iq <- i_post[sample.int(length(i_post), replace = TRUE)]
    z <- a$anomaly + sample(res_c, nrow(a), replace = TRUE)
    mean(z[iq]) - mean(z[ip])
  }, 0)
  mx[[nm]]$ci_c <- stats::quantile(boot, c(q_lo, q_hi), names = FALSE, na.rm = TRUE)
  mx[[nm]]$n_resid_c <- length(res_c)
}

# new in #152: the change from 1951-1980 to 2016-2025 on both routes, after #126's draws
ref_years <- 1951:1980
recent_years <- 2016:2025
# the interval as #120 and #126 draw it: resample years in each period, a residual added to each
# year that gets one (extended years, or every carried year)
interval_of <- function(y, add, res, i1, i2, n = n_boot) {
  if (!length(res) || length(i1) < 2 || length(i2) < 2) return(c(NA_real_, NA_real_))
  b <- vapply(seq_len(n), function(k) {
    ip <- i1[sample.int(length(i1), replace = TRUE)]
    iq <- i2[sample.int(length(i2), replace = TRUE)]
    z <- y + ifelse(add, sample(res, length(y), replace = TRUE), 0)
    mean(z[iq]) - mean(z[ip])
  }, 0)
  stats::quantile(b, c(q_lo, q_hi), names = FALSE)
}
# its coverage: series with no change, each period normal with the series' own SD there, put through
# the same interval (vectorised over draws: column j is draw j)
cover_of <- function(y, add, res, i1, i2, n_sim = 1000, n_draw = 500) {
  if (!length(res) || length(i1) < 2 || length(i2) < 2) return(NA_real_)
  one <- function(z, a, n) {
    m <- z + matrix(sample(res, n * n_draw, replace = TRUE), n) * a
    idx <- matrix(sample.int(n, n * n_draw, replace = TRUE), n) + rep((seq_len(n_draw) - 1) * n, each = n)
    colMeans(matrix(m[idx], n))
  }
  n1 <- length(i1)
  n2 <- length(i2)
  s1 <- stats::sd(y[i1])
  s2 <- stats::sd(y[i2])
  mean(vapply(seq_len(n_sim), function(k) {
    d <- one(stats::rnorm(n2, 0, s2), add[i2], n2) - one(stats::rnorm(n1, 0, s1), add[i1], n1)
    q <- stats::quantile(d, c(q_lo, q_hi), names = FALSE)
    q[1] <= 0 && q[2] >= 0
  }, TRUE))
}
set.seed(152)
for (nm in names(mx)) {
  m <- mx[[nm]]
  cr <- crun_for(m$v, m$p)
  a <- m$a
  p <- list(res_c = if (is.null(cr)) numeric() else cr$resid, i1_c = which(a$year %in% ref_years),
            i2_c = which(a$year %in% recent_years))
  p$carried <- mean(a$anomaly[p$i2_c]) - mean(a$anomaly[p$i1_c])
  p$ci_c <- interval_of(a$anomaly, rep(TRUE, nrow(a)), p$res_c, p$i1_c, p$i2_c)
  p$donors_c <- sort(unique(sub(":.*", "", unlist(strsplit(a$donors[p$i1_c], " ")))))
  if (!is.null(m$e)) {
    e <- m$e
    p$res_e <- if (m$v == "q_max") numeric() else run_for(m$v, m$p)$r[[paste0("r_", ship)]]
    p$lv <- tr_of(m$v)(e$value)
    p$ext <- e$source == "extended"
    p$i1 <- which(e$year %in% ref_years)
    p$i2 <- which(e$year %in% recent_years)
    p$diff <- mean(p$lv[p$i2]) - mean(p$lv[p$i1])
    p$ci <- interval_of(p$lv, p$ext, p$res_e, p$i1, p$i2)
    p$donors_e <- table(ifelse(is.na(e$donor[p$i1]), "observed", e$donor[p$i1]))
  }
  mx[[nm]]$p152 <- p
}
set.seed(1520)
for (nm in names(mx)) {
  p <- mx[[nm]]$p152
  a <- mx[[nm]]$a
  p$cover_c <- cover_of(a$anomaly, rep(TRUE, nrow(a)), p$res_c, p$i1_c, p$i2_c)
  if (!is.null(p$lv)) p$cover <- cover_of(p$lv, p$ext, p$res_e, p$i1, p$i2)
  mx[[nm]]$p152 <- p
}

# ---- the report's answer ---------------------------------------------------------------------
pc <- function(z, days) if (days) fmt(z, 1) else fmt(100 * (exp(z) - 1), 1)
ci_txt <- function(ci, days) {
  if (is.na(ci[1])) "-" else if (days) sprintf("%s..%s", fmt(ci[1], 1), fmt(ci[2], 1)) else
    sprintf("%s..%s %%", pc(ci[1], FALSE), pc(ci[2], FALSE))
}
if (site$kind == "extend") {
  m1 <- mx[["q_mean migration"]]
  e1 <- m1$e
  say(sprintf("## 4. The answer at %s", target), "",
      sprintf("%s extended by %s (fixed at #126's gate), k = 5 covering donors from the extension pool, %d-%d; 90 %% intervals are OLS's prediction interval.",
              target, ship, min(e1$year), max(e1$year)),
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
        if (length(first_use) < 2) {
          return(sprintf("  %s %s: %s; one donor, %s, supplies every extended year.", m$p, sub("^q_", "", m$v),
                         paste(sprintf("%d %s", as.integer(tp), names(tp)), collapse = ", "), names(first_use)[1]))
        }
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
      sprintf("extended: 90 %% interval from %d draws resampling years in each period and adding a held-out residual to each extended year; set.seed(120).", n_boot),
      sprintf("carried: 90 %% interval from %d draws resampling years in each period and adding a held-out carried residual to each year; set.seed(126).", n_boot),
      "", sprintf("  %-9s %-9s %4s %4s %9s %9s %18s   %9s %9s %18s %4s %4s", "statistic", "window", "pre", "post", "change",
                  "% normal", "90 % interval", "carried", "% normal", "90 % interval", "pre", "post"))
  for (m in mx) {
    days <- is_days(m$v)
    say(sprintf("  %-9s %-9s %4d %4d %9s %9s %18s   %9s %9s %18s %4d %4d", sub("^q_", "", m$v), m$p, m$n_pre, m$n_post,
                fmt(m$diff, 3), if (days) "-" else pc(m$diff, FALSE), ci_txt(m$ci, days),
                fmt(m$carried, 3), if (days) "-" else pc(m$carried, FALSE), ci_txt(m$ci_c, days), m$n_pre_c, m$n_post_c))
  }
  say("", "(% normal: 100 (exp(change) - 1). carried: the same change from the donor-carried departures, which need no target baseline. max is reported, never scored, so neither of its changes has an interval; its per-year values below carry OLS's prediction interval.)",
      "", "The two routes as centred departures: NSE of the carried against the extension's over the target's observed years; over the record, correlation and mean absolute difference:", "",
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
    say("", sprintf("%s per year, %s %s (%s): value with the 90 %% interval and the donor; its departure from the extended series' own 1981-2010 mean, and the carried departure (%s):",
                    target, m$p, sub("^q_", "", m$v), if (days) "day of the window" else "m3/s",
                    if (days) "days" else "% of normal"), "",
        sprintf("  %4s %8s %8s %8s %-8s %9s %9s", "year", "value", "lo", "hi", "donor", "departure", "carried"))
    e <- m$e
    for (y in sort(union(e$year, m$a$year))) {
      i <- match(y, e$year)
      k <- match(y, m$a$year)
      say(sprintf("  %4d %8s %8s %8s %-8s %9s %9s", y, fmt(e$value[i], 2), fmt(e$lower[i], 2), fmt(e$upper[i], 2),
                  if (is.na(i)) "-" else if (is.na(e$donor[i])) "observed" else e$donor[i],
                  if (is.na(i)) "-" else pc(e$dep[i], days), if (is.na(k)) "-" else pc(m$a$anomaly[k], days)))
    }
  }
} else {
  # the published normal on the mouth segment, per source, and the pick
  wf <- wet_flow_window(pub$mouth[c("linear_feature_id", "doy", "q_m3s", "source")], windows)
  pk <- pub$pick_of(pub$mouth)
  if (nrow(pk) != 1) stop("the mouth segment has no single picked source", call. = FALSE)
  normal <- wf[wf$source == pk$source, c("window", "q_m3s")]
  # the normal's error at the box gauges: published pick against observed 1981-2010 window means
  dp_mig <- dep_pool_of("q_mean", "migration")
  err <- NULL
  if (!is.null(pub$gauges)) {
    gs <- sn[sn$station_number %in% dp_mig & sn$accepted %in% TRUE, c("station_number", "linear_feature_id")]
    gd <- pub$gauges[pub$gauges$linear_feature_id %in% gs$linear_feature_id, ]
    gw <- wet_flow_window(gd[c("linear_feature_id", "doy", "q_m3s", "source")], windows)
    gp <- pub$pick_of(gd)
    gw <- merge(gw, gp, by = c("linear_feature_id", "source"))
    err <- do.call(rbind, lapply(seq_len(nrow(gs)), function(i) {
      do.call(rbind, lapply(windows$window, function(w) {
        o <- ws[ws$station_number == gs$station_number[i] & ws$variable == "q_mean" & ws$period == w &
                  ws$year %in% baseline & !is.na(ws$value), "value"]
        pq <- gw[gw$linear_feature_id == gs$linear_feature_id[i] & gw$window == w, ]
        data.frame(station_number = gs$station_number[i], window = w,
                   n_base = length(o), obs = if (length(o) >= 10) mean(o) else NA_real_,
                   pub = if (nrow(pq) == 1) pq$q_m3s else NA_real_,
                   source = if (nrow(pq) == 1) pq$source else NA_character_,
                   calib = gs$station_number[i] %in% calib)
      }))
    }))
    err$log_ratio <- log(err$pub / err$obs)
  }
  say(sprintf("## 4. The answer at %s (ungauged)", site$name), "",
      sprintf("No record at %s, so nothing here is scored at the place itself: the result at the ungauged point is UNTESTED. The method is scored at the box's gauges (sections 2 and 3).", site$name),
      sprintf("Carried departures, k = 5 from the departure pool, at a station placed at the mouth (%s, %s) with the basin's FWA area, %s km2, for its predictors.",
              site$target_lon, site$target_lat, fmt(mouth$km2, 1)),
      sprintf("Donors (nearest first), migration mean: %s.",
              {
                # a year with every donor lists them in distance order
                a1 <- mx[["q_mean migration"]]$a
                paste(sub(":.*", "", strsplit(a1$donors[which.max(a1$n_donors)], " ")[[1]]), collapse = ", ")
              }),
      "", "Before/after: mean carried departure 2011-2025 minus mean before 1981 (log, or days for cov_day);",
      sprintf("90 %% interval from %d draws resampling years in each period and adding a held-out carried residual to each year; set.seed(126).", n_boot),
      "", sprintf("  %-9s %-9s %4s %4s %9s %9s %18s %8s", "statistic", "window", "pre", "post", "carried", "% normal",
                  "90 % interval", "resid n"))
  for (m in mx) {
    days <- is_days(m$v)
    say(sprintf("  %-9s %-9s %4d %4d %9s %9s %18s %8d", sub("^q_", "", m$v), m$p, m$n_pre_c, m$n_post_c, fmt(m$carried, 3),
                if (days) "-" else pc(m$carried, FALSE), ci_txt(m$ci_c, days), m$n_resid_c))
  }
  say("", "(max is reported, never scored, so its change has no interval.)", "",
      sprintf("The normal: wet's published segment_daily, build digest %s, on the mouth segment %d (measure %s m, edge type %d), 1981-2010:",
              pub$digest, as.integer(mouth$segment$linear_feature_id), fmt(mouth$segment$downstream_route_measure, 1),
              as.integer(mouth$segment$edge_type)),
      sprintf("  part %s %s md5 %s", pub$mouth_parts$source, pub$mouth_parts$code, pub$mouth_parts$md5), "",
      sprintf("  %-10s %12s %12s  %s", "window", "pcic_routed", "wet_balance", "pick"))
  for (w in windows$window) {
    say(sprintf("  %-10s %12s %12s  %s", w, fmt(wf$q_m3s[wf$window == w & wf$source == "pcic_routed"], 3),
                fmt(wf$q_m3s[wf$window == w & wf$source == "wet_balance"], 3), pk$source))
  }
  say("", "(m3/s, the window mean of the days, wet_flow_window(); only the window mean has a published normal, so min7, cov_day and max get departures only.)", "")
  if (is.null(err)) {
    say("The normal's error at the box gauges: not run (no fwapg database through the PG* variables).")
  } else {
    say("The normal's error at the box gauges (migration-mean departure pool, snap accepted): log(published pick / observed 1981-2010 mean of the window's complete years).",
        "A gauge marked * is in the water balance's station set (data/wb/stations_20260717.rds), where the balance is fitted and publishes the gauge's own monthly shares, so it is partly in sample there.",
        sprintf("  parts read: %s", paste(sprintf("%s %s %s", pub$gauge_parts$source, pub$gauge_parts$code, pub$gauge_parts$md5),
                                          collapse = "; ")), "",
        sprintf("  %-10s %5s %9s %9s %9s   %9s %9s %9s", "window", "n", "q25", "median", "q75", "n (no *)", "median", "med |r|"))
    for (w in windows$window) {
      x <- err[err$window == w & !is.na(err$log_ratio), ]
      xu <- x[!x$calib, ]
      q <- stats::quantile(x$log_ratio, c(0.25, 0.5, 0.75), names = FALSE)
      say(sprintf("  %-10s %5d %9s %9s %9s   %9d %9s %9s", w, nrow(x), fmt(q[1], 3), fmt(q[2], 3), fmt(q[3], 3), nrow(xu),
                  if (nrow(xu)) fmt(stats::median(xu$log_ratio), 3) else "-",
                  if (nrow(xu)) fmt(stats::median(abs(xu$log_ratio)), 3) else "-"))
    }
    say("", sprintf("  %-9s %-10s %4s %10s %10s %-12s %9s", "gauge", "window", "base", "observed", "published", "source", "log ratio"))
    for (i in seq_len(nrow(err))) {
      say(sprintf("  %-9s %-10s %4d %10s %10s %-12s %9s", paste0(err$station_number[i], if (err$calib[i]) "*" else ""),
                  err$window[i], err$n_base[i], fmt(err$obs[i], 3), fmt(err$pub[i], 3),
                  ifelse(is.na(err$source[i]), "-", err$source[i]), fmt(err$log_ratio[i], 3)))
    }
  }
  for (m in mx) {
    days <- is_days(m$v)
    mean_flow <- m$v == "q_mean"
    nq <- if (mean_flow) normal$q_m3s[normal$window == m$p] else NA_real_
    say("", sprintf("%s per year, %s %s: the carried departure (%s)%s:", site$name, m$p, sub("^q_", "", m$v),
                    if (days) "days" else "% of normal",
                    if (mean_flow) sprintf(" and the window flow, the normal (%s m3/s) times exp(departure)", fmt(nq, 3)) else ""), "",
        sprintf("  %4s %9s %9s %3s", "year", "carried", if (mean_flow) "m3/s" else "", "n"))
    for (j in seq_len(nrow(m$a))) {
      say(sprintf("  %4d %9s %9s %3d", m$a$year[j], pc(m$a$anomaly[j], days),
                  if (mean_flow) fmt(nq * exp(m$a$anomaly[j]), 3) else "", as.integer(m$a$n_donors[j])))
    }
  }
  pub_out <- list(normal = normal, sources = wf, pick = pk$source, segment = mouth$segment, digest = pub$digest,
                  parts = pub$mouth_parts, error = err, km2 = mouth$km2)
}

say("", sprintf("## 5. The change from %d-%d to %d-%d (#152)", min(ref_years), max(ref_years), min(recent_years),
                max(recent_years)), "",
    sprintf("Each route's mean over its %d-%d years minus its mean over its %d-%d years (log, or days for cov_day); 90 %% interval from %d draws resampling years in each period and adding a held-out residual to each extended year, or to every carried year; set.seed(152).",
            min(recent_years), max(recent_years), min(ref_years), max(ref_years), n_boot),
    "cover: the share of 1000 simulated series with no change whose interval covers zero (each period normal with the series' own SD there, 500 draws each, the same residual pool); set.seed(1520). The comparison article calls the interval a 90 % range only where every cover it draws on is at least 0.87.",
    "", sprintf("  %-9s %-9s %4s %4s %9s %9s %18s %6s   %4s %4s %9s %9s %18s %6s", "statistic", "window", "ref", "rec",
                "extended", "% normal", "90 % interval", "cover", "ref", "rec", "carried", "% normal", "90 % interval",
                "cover"))
for (m in mx) {
  days <- is_days(m$v)
  p <- m$p152
  ext <- !is.null(p$lv)
  say(sprintf("  %-9s %-9s %4s %4s %9s %9s %18s %6s   %4d %4d %9s %9s %18s %6s", sub("^q_", "", m$v), m$p,
              if (ext) length(p$i1) else "-", if (ext) length(p$i2) else "-", if (ext) fmt(p$diff, 3) else "-",
              if (ext && !days) pc(p$diff, FALSE) else "-", if (ext) ci_txt(p$ci, days) else "-",
              if (ext) fmt(p$cover, 3) else "-", length(p$i1_c), length(p$i2_c), fmt(p$carried, 3),
              if (days) "-" else pc(p$carried, FALSE), ci_txt(p$ci_c, days), fmt(p$cover_c, 3)))
}
say("", sprintf("The gauges the %d-%d years rest on (extended: years per source; carried: every donor named in those years):",
                min(ref_years), max(ref_years)))
for (m in mx) {
  p <- m$p152
  say(sprintf("  %s %s: %scarried %s.", m$p, sub("^q_", "", m$v),
              if (is.null(p$donors_e)) "" else sprintf("extended %s; ",
                                                     paste(sprintf("%d %s", as.integer(p$donors_e), names(p$donors_e)),
                                                           collapse = ", ")),
              paste(p$donors_c, collapse = ", ")))
}

# ---- the parity gate (maxan, BULK): #120's tracked report, before anything is written ----------
if (site$site_id == "maxan" && wname == "BULK") {
  miss <- site_parity_pilot(out, readLines(file.path("data", "checks", sprintf("departure_pilot_%s.txt", release))))
  if (length(miss)) {
    stop("parity: ", length(miss), " lines of the tracked pilot report missing from this run, the first: ",
         paste(utils::head(miss, 3), collapse = " | "), call. = FALSE)
  }
}

writeLines(sub(" +$", "", out), report)
message("wrote ", report)

# the series for scripts/departure_site_snow.R and the article's data, after the report so no draw moves
rds <- file.path("data", "departure", sprintf("departure_site_%s_%s_%s.rds", site$site_id, tolower(wname), release))
dir.create(dirname(rds), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(site = site, windows = windows, release = release, ship = ship, k_main = k_main, baseline = baseline,
             level = level, mx = mx, ws = ws, stations = stations_t, pool = pool,
             race = list(med = dec$med, rule_pick = dec$ship, gauges = main$n[["gauges"]], below_floor = below_floor),
             carried = list(median = head_q[2], q = head_q, n = sum(!is.na(cm$held$nse)), usable = usable,
                            short = med_na(cm$short$nse)),
             normal = if (site$kind == "ungauged") pub_out else NULL, code_md5 = code_md5), rds)
}
