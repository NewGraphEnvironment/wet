# The published monthly flows against HYDAT at the shipped fit's calibration
# gauges, by region, season and basin size (#6); routed PCIC's seasonal shape
# and what drives it (#67); and DFO's Fraser threat-layer validation beside
# ours (#162, Iacarella et al. 2025, App. F, Table F1). One script, because all
# three read the same held-out balance, routed PCIC on the same gauge segments
# and the same observed months (#166).
#
#   WET_FWAPG_COMMIT=<sha> WET_PCIC_YEARS=<dir> Rscript scripts/gauge_monthly_compare.R
#
# Inputs, each held to the record it must equal:
#   - observed and the held-out balance: the fit's stored blocked-CV months
#     (cv_ann, cv_share in cv_aet-<AET>.rds, #68) under the shares it ships,
#     refused unless the stored observed values are the calibration stations'
#     and the stored months, scored again, give the stored scores (as
#     data-raw/monthly_vignette_data.R refuses);
#   - routed PCIC as published: fwapg's monthly table for the run
#     scripts/pcic_routed_lib.R names, refused unless the table and the fwapg
#     commit are the tracked routed report's;
#   - PCIC's own outlet flow (#67's first check): the run's sub-basin days
#     (q_acc, accumulated routed flow at each outlet), and the segments'
#     weights, refused unless they are the tracked daily report's;
#   - routed PCIC year by year (#162's minimum flows): fwapg#42's per-year
#     sub-basin days under WET_PCIC_YEARS, each file held to its pcic.series
#     row (routed_years_check());
#   - HYDAT (the fit's release) for each gauge's yearly monthly means.
# The gauge table (observed, balance and routed, months 0-12) must equal the
# one the segment-discharge article reads (inst/vignette-data/monthly_values.rds),
# so the report and the article score the same numbers.
#
# Report: data/checks/gauge_monthly_compare_<release>.txt (tracked). PCIC and
# DFO are references here, scored against HYDAT beside our own estimate
# (CLAUDE.md, "Own estimates first"). Connection from WET_PG*.

source("scripts/wb_cv_lib.R")  # load_all(), cal, long(), release, fit_dir, key_dir, wb_report(), stamp()
source("scripts/pcic_routed_lib.R")

git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "inst/vignette-data")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the report:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
fwapg_commit <- routed_commit()

err_cut <- 20        # a gauge-month is "within" when modelled is within +-20 % of observed
min_zone <- 5        # zones with fewer gauges are marked
f_bundle <- file.path("inst", "vignette-data", "monthly_values.rds")
f_hydz <- file.path("data", "hydz", "bc_hydrologic_zones.zip")
month_lab <- month.abb
seasons <- list(DJF = c(12, 1, 2), MAM = 3:5, JJA = 6:8, SON = 9:11, `Mar-Apr` = 3:4, `Jul-Aug` = 7:8)

# ---- the balance held out, by month ---------------------------------------------------------------
ho <- shipped_heldout()
fits <- ho$fits
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", fits$aet)))
stopifnot(fits$keep_adjust, identical(cvr$station_number, cal$station_number))
shipped_cv_share <- if (is.null(cvr$share_method)) NULL else if (cvr$share_method == "regression") {
  cvr$cv_shares[[fits$share_spec]]
} else {
  cvr$cv_share_methods[[cvr$share_method]]
}
if (is.null(cvr$cv_share) || !identical(dim(cvr$cv_share), c(nrow(cal), 12L)) || is.null(fits$share_spec) ||
      !identical(cvr$share_spec, fits$share_spec) || !identical(cvr$share_method, fits$share_method) ||
      !identical(cvr$cv_share, shipped_cv_share)) {
  stop("the fit stores no held-out months under its shipped share specification and method: rerun scripts/wb_validate.R")
}
obs_share <- as.matrix(cal[sprintf("share_%02d", 1:12)])
if (!identical(cvr$obs, cal$obs) || !identical(unname(cvr$obs_share), unname(obs_share))) {
  stop("the stored observed values differ from the calibration stations'")
}
ho_long <- long(cal, cvr$cv_ann, cvr$cv_share)
cols_sc <- c("station_number", "obs", "mod", "err_pct", "nse_month", "nse_share")
if (!isTRUE(all.equal(wet_flow_validate(ho_long)$stations[cols_sc], cvr$cv_v$stations[cols_sc],
                      check.attributes = FALSE))) {
  stop("the stored held-out months do not give the stored scores")
}
hydat_release <- sub("^HYDAT release: ", "", grep("^HYDAT release:", readLines(wb_report("stations_wb", release)),
                                                   value = TRUE))
stopifnot(length(hydat_release) == 1)

# ---- fwapg ----------------------------------------------------------------------------------------
f_routed <- wb_report("pcic_routed_compare", release)
f_daily <- wb_report("segment_daily_output", release)
cal$linear_feature_id <- as.integer(cal$linear_feature_id)
lfid_all <- unique(cal$linear_feature_id)
stopifnot(!anyNA(lfid_all))
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                       connect_timeout = 10)
fp <- routed_fingerprint(conn)
rl <- readLines(f_routed)
if (!(any(rl == routed_report_line(fwapg_commit)) && any(rl == sprintf("table: %s", fp)))) {
  stop(f_routed, " was not made from this routed table at fwapg ", fwapg_commit, ": rerun scripts/pcic_routed_compare.R")
}
daily_fp <- sub("^daily: ", "", grep("^daily: ", readLines(f_daily), value = TRUE))
stopifnot(length(daily_fp) == 1L)
if (!identical(routed_daily_fingerprint(conn), daily_fp)) {
  stop("fwapg's routed days or weights are not those ", f_daily, " was built from (", daily_fp, ")")
}
routed_m <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, month::int AS month, q_m3s
  FROM %s WHERE %s AND linear_feature_id IN (%s) ORDER BY 1, 2", routed_table, routed_where,
  paste(lfid_all, collapse = ", ")))
routed_0 <- routed_annual(conn, lfid_all)
# #67's checks: PCIC's outlets placed on the gauges' own segments (the
# crosswalk's flag NULL), the gauge segments' weights, and the run's days for
# every sub-basin those name (q_acc: PCIC's accumulated routed flow at the
# outlet; q_local: the runoff PCIC gives the sub-basin)
outlets <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, subid
  FROM pcic.fwa_crosswalk WHERE flag IS NULL AND linear_feature_id IN (%s) ORDER BY 1, 2",
  paste(lfid_all, collapse = ", ")))
w_gauge <- routed_weights(conn, lfid_all)
sub_need <- sort(unique(c(outlets$subid, w_gauge$subid, unlist(w_gauge$upstream_subids))))
sb_days <- DBI::dbGetQuery(conn, sprintf("
  SELECT subid, month::int AS month, day::int AS day, n_days, q_local, q_acc
  FROM %s WHERE %s AND subid IN (%s) ORDER BY subid, month, day",
  routed_daily_table, routed_where, paste(sub_need, collapse = ", ")))
stopifnot(setequal(sb_days$subid, sub_need), !anyNA(sb_days$q_acc), !anyNA(sb_days$q_local))
DBI::dbDisconnect(conn)

# ---- the gauge table ------------------------------------------------------------------------------
# mm over wet's accumulated area, as the bundle takes them: routed months by
# their days, routed month 0 from the plain mean of twelve on 365.25 days
days <- c(365.25, wet_month_days())
area <- cal$upstream_area_m2[match(ho_long$station_number, cal$station_number)]
lfid <- cal$linear_feature_id[match(ho_long$station_number, cal$station_number)]
q_r <- ifelse(ho_long$month == 0,
              routed_0$q_m3s[match(lfid, routed_0$linear_feature_id)],
              routed_m$q_m3s[match(paste(lfid, ho_long$month), paste(routed_m$linear_feature_id, routed_m$month))])
gx <- data.frame(station_number = ho_long$station_number, month = ho_long$month,
                 obs_mm = ho_long$obs, wb_mm = ho_long$mod,
                 routed_mm = q_r * days[ho_long$month + 1] * 86400 / area * 1000)
meta <- cal[c("station_number", "station_name", "lat", "linear_feature_id", "zone", "nesting", "area_km2",
              "area_class", "lake", "elev", "upstream_area_m2")]
meta$area_class <- as.character(meta$area_class)
gx <- merge(meta, gx, by = "station_number")
gx <- gx[order(gx$station_number, gx$month), ]
rownames(gx) <- NULL
stopifnot(nrow(gx) == 13 * nrow(cal))

# the article's table, built from the published parts: the same numbers
bundle <- readRDS(f_bundle)
bg <- bundle$gauges[order(bundle$gauges$station_number, bundle$gauges$month), ]
cols_par <- c("station_number", "month", "zone", "nesting", "area_class", "obs_mm", "wb_mm", "routed_mm")
par_gauge <- all.equal(gx[cols_par], bg[cols_par], check.attributes = FALSE)
if (!isTRUE(par_gauge)) stop("the gauge table differs from ", f_bundle, "'s: ", paste(par_gauge, collapse = "; "))
stopifnot(identical(bundle$provenance$routed_commit, fwapg_commit))

# ---- the gauges each comparison uses --------------------------------------------------------------
# per gauge, wide: observed, balance and routed months 1-12 and month 0
wide <- function(col) {
  m <- matrix(gx[[col]], ncol = 13, byrow = TRUE, dimnames = list(unique(gx$station_number), 0:12))
  stopifnot(identical(rownames(m), cal$station_number[order(cal$station_number)]))
  m
}
OBS <- wide("obs_mm")
WB <- wide("wb_mm")
RT <- wide("routed_mm")
g <- gx[gx$month == 0, c("station_number", "station_name", "lat", "linear_feature_id", "zone", "nesting",
                         "area_km2", "area_class", "lake", "elev", "upstream_area_m2")]
stopifnot(identical(g$station_number, rownames(OBS)))
g$basin <- routed_basin(g$station_number)
# the shared set: routed has flow on the segment and it carries at least the
# far-low cut of observed annual flow (as the article's scores and the routed
# report's "without them" line take it)
g$routed <- !is.na(RT[, "0"])
g$shared <- g$routed & RT[, "0"] >= routed_far_low * OBS[, "0"]
g$shared[is.na(g$shared)] <- FALSE
stopifnot(sum(g$routed) > 0, all(rowSums(is.na(RT[g$routed, ])) == 0))

# ---- scorers --------------------------------------------------------------------------------------
# per gauge-month, modelled over observed; a season is the ratio of its months'
# summed runoff, so a gauge counts once per season
ratio_m <- function(M, i, m) M[i, as.character(m)] / OBS[i, as.character(m)]
ratio_s <- function(M, i, ms) rowSums(M[i, as.character(ms), drop = FALSE]) / rowSums(OBS[i, as.character(ms), drop = FALSE])
med_err <- function(r) 100 * (stats::median(r) - 1)
within <- function(r) 100 * mean(abs(r - 1) <= err_cut / 100)
nse_g <- function(M, i) vapply(which(i), function(k) wet:::wet_nse(OBS[k, as.character(1:12)], M[k, as.character(1:12)]), 0)
fmt_e <- function(x) ifelse(is.na(x), "     -", sprintf("%+6.1f", x))

# ---- zone names -----------------------------------------------------------------------------------
# from the zip scripts/wb_inputs.R caches (data-raw/segment_vignette_map.R reads it the same way)
if (!file.exists(f_hydz)) stop(f_hydz, " is missing: run scripts/wb_inputs.R, which caches it")
hz_src <- tempfile("hydz")
utils::unzip(f_hydz, exdir = hz_src)
hz_shp <- list.files(hz_src, "\\.shp$", full.names = TRUE, recursive = TRUE)
stopifnot(length(hz_shp) == 1)
hz <- sf::st_drop_geometry(sf::st_read(hz_shp, quiet = TRUE))
hz_code <- sprintf("%02d", as.integer(hz$HYDZN_NO))
# a zone's name is its first feature's: zone 28's two features carry two names
hz_name <- tapply(as.character(hz$HYDZN_NAME), hz_code, `[`, 1)
stopifnot(all(g$zone %in% names(hz_name)))
zone_lab <- function(z) sprintf("%s %s", z, substr(tools::toTitleCase(tolower(hz_name[z])), 1, 26))

# ---- report ---------------------------------------------------------------------------------------
out <- character()
say <- function(...) out <<- c(out, ...)
S <- g$shared
A <- rep(TRUE, nrow(g))
n_low <- sum(g$routed & !g$shared)

say("# Monthly flow against HYDAT at the calibration gauges: region, season, basin size (#6), routed PCIC's",
    "# seasonal shape (#67) and DFO's Fraser validation (#162)",
    "",
    sprintf("wet commit %s; fit %s (HYDAT %s), province run %s, scoring code %s; AET %s, shares %s (%s)",
            wet_commit, release, hydat_release, basename(key_dir), score_code_md5, fits$aet, fits$share_method,
            fits$share_spec),
    routed_report_line(fwapg_commit),
    sprintf("table: %s", fp),
    sprintf("daily: %s", daily_fp),
    sprintf("hydrologic zones: %s (md5 %s)", f_hydz, unname(tools::md5sum(f_hydz))),
    sprintf("gauge table = %s's (observed, balance, routed; months 0-12; %d gauges): all.equal TRUE",
            f_bundle, nrow(g)),
    "",
    "## What is scored",
    "Each gauge's monthly means over its complete years in 1981-2010 (at least 10; scripts/wb_stations.R), in mm",
    "over wet's accumulated upstream area. The balance is held out (blocked CV), as it ships; routed PCIC is the",
    sprintf("published %s run on the segment the gauge snapped to.", routed_run$period),
    sprintf("- error: modelled over observed, as %%; a month's is per gauge-month, a season's the ratio of its summed months"),
    sprintf("- median: the median of those errors over gauges; within: the share of them inside +-%d %%", err_cut),
    "- monthly NSE: Nash-Sutcliffe efficiency of a gauge's twelve monthly means (1 is perfect, <= 0.5",
    "  unsatisfactory: Moriasi and others 2007), medianed over gauges",
    sprintf("- shared gauges: routed has flow on the segment and carries at least %.0f %% of observed annual flow (%d of",
            100 * routed_far_low, sum(S)),
    sprintf("  the %d with routed flow; %d below that cut are the routed report's far-low list). Both sources are",
            sum(g$routed), n_low),
    sprintf("  compared there; the balance alone on all %d.", nrow(g)),
    sprintf("- zones with fewer than %d gauges are marked *", min_zone),
    "")

# ---- #6: by month ---------------------------------------------------------------------------------
month_row <- function(lab, M, i) {
  e <- vapply(1:12, function(m) med_err(ratio_m(M, i, m)), 0)
  sprintf("%-26s %4d %s %s", lab, sum(i), paste(fmt_e(e), collapse = ""), fmt_e(med_err(ratio_m(M, i, 0))))
}
month_head <- sprintf("%-26s %4s %s %6s", "", "n", paste(sprintf("%6s", month_lab), collapse = ""), "year")
say("## #6: median error by month (%)",
    month_head,
    month_row("routed, shared", RT, S),
    month_row("balance, shared", WB, S),
    month_row("balance, all", WB, A),
    sprintf("%-26s %4s %s", "within +-20 %, routed", "",
            paste(sprintf("%6.0f", vapply(1:12, function(m) within(ratio_m(RT, S, m)), 0)), collapse = "")),
    sprintf("%-26s %4s %s", "within +-20 %, balance", "",
            paste(sprintf("%6.0f", vapply(1:12, function(m) within(ratio_m(WB, S, m)), 0)), collapse = "")),
    "")

# ---- #6: by season and group ----------------------------------------------------------------------
season_head <- sprintf("%-30s %4s  %s  |  %s", "", "n",
                       paste(sprintf("%8s", names(seasons)), collapse = ""),
                       paste(sprintf("%8s", names(seasons)), collapse = ""))
season_row <- function(lab, i, mark = "") {
  if (!any(i)) return(NULL)
  er <- vapply(seasons, function(ms) med_err(ratio_s(RT, i, ms)), 0)
  ew <- vapply(seasons, function(ms) med_err(ratio_s(WB, i, ms)), 0)
  sprintf("%-30s %4d  %s  |  %s", paste0(lab, mark), sum(i), paste(sprintf("%+8.1f", er), collapse = ""),
          paste(sprintf("%+8.1f", ew), collapse = ""))
}
zones <- sort(unique(g$zone[S]))
say("## #6: median seasonal error by region, shared gauges (%): routed | balance",
    season_head,
    season_row("all", S),
    "-- major basin",
    unlist(lapply(c("Peace", "Fraser", "Columbia", "Coast", "Yukon", "Arctic"), function(b) season_row(b, S & g$basin == b))),
    "-- hydrologic zone",
    unlist(lapply(zones, function(z) {
      i <- S & g$zone == z
      season_row(zone_lab(z), i, if (sum(i) < min_zone) " *" else "")
    })),
    "")
say("## #6: median seasonal error by basin size and type, shared gauges (%): routed | balance",
    season_head,
    unlist(lapply(c("<100 km2", "100-1000", "1000-10000", ">10000"), function(a) season_row(a, S & g$area_class == a))),
    season_row("headwater", S & g$nesting == "headwater"),
    season_row("nested", S & g$nesting == "nested"),
    season_row("lake outlet", S & g$lake %in% TRUE),
    season_row("not lake outlet", S & !(g$lake %in% TRUE)),
    "")
zones_all <- sort(unique(g$zone))
say(sprintf("## #6: the balance on all %d gauges, by zone: median seasonal error (%%) and monthly NSE", nrow(g)),
    sprintf("%-30s %4s  %s  %6s", "", "n", paste(sprintf("%8s", names(seasons)), collapse = ""), "NSE"),
    unlist(lapply(zones_all, function(z) {
      i <- g$zone == z
      e <- vapply(seasons, function(ms) med_err(ratio_s(WB, i, ms)), 0)
      sprintf("%-30s %4d  %s  %6.2f", paste0(zone_lab(z), if (sum(i) < min_zone) " *" else ""), sum(i),
              paste(sprintf("%+8.1f", e), collapse = ""), stats::median(nse_g(WB, i)))
    })),
    "")

# ---- #67: the shape, rescored on this routed build -----------------------------------------------
lowhigh <- function(i) {
  ma <- ratio_s(RT, i, 3:4)
  ja <- ratio_s(RT, i, 7:8)
  c(low_ma = 100 * mean(ma < 1), high_ja = 100 * mean(ja > 1), both = 100 * mean(ma < 1 & ja > 1))
}
lh <- lowhigh(S)
say(sprintf("## #67: routed PCIC's shape at the %d shared gauges (%s)", sum(S), routed_run$period),
    sprintf("%-26s %7s %7s %7s %7s   %9s %9s", "", "Mar", "Apr", "Jul", "Aug", "Mar-Apr", "Jul-Aug"),
    sprintf("%-26s %s   %s", "routed, median error",
            paste(sprintf("%+7.1f", vapply(c(3, 4, 7, 8), function(m) med_err(ratio_m(RT, S, m)), 0)), collapse = ""),
            paste(sprintf("%+9.1f", c(med_err(ratio_s(RT, S, 3:4)), med_err(ratio_s(RT, S, 7:8)))), collapse = "")),
    sprintf("%-26s %s   %s", "balance, median error",
            paste(sprintf("%+7.1f", vapply(c(3, 4, 7, 8), function(m) med_err(ratio_m(WB, S, m)), 0)), collapse = ""),
            paste(sprintf("%+9.1f", c(med_err(ratio_s(WB, S, 3:4)), med_err(ratio_s(WB, S, 7:8)))), collapse = "")),
    sprintf("gauges where routed is low in Mar-Apr: %.0f %%; high in Jul-Aug: %.0f %%; both: %.0f %%",
            lh[["low_ma"]], lh[["high_ja"]], lh[["both"]]),
    "",
    "By basin size: median monthly NSE, routed and balance, at the shared gauges",
    sprintf("%-14s %4s %8s %8s", "", "n", "routed", "balance"),
    unlist(lapply(c("<100 km2", "100-1000", "1000-10000", ">10000"), function(a) {
      i <- S & g$area_class == a
      sprintf("%-14s %4d %8.2f %8.2f", a, sum(i), stats::median(nse_g(RT, i)), stats::median(nse_g(WB, i)))
    })),
    sprintf("%-14s %4d %8.2f %8.2f", "all", sum(S), stats::median(nse_g(RT, S)), stats::median(nse_g(WB, S))),
    "")

# ---- #67's checks ---------------------------------------------------------------------------------
# A sub-basin's months and year from its calendar days, each day weighted by
# how often it occurs in the run's years (n_days), as fwapg makes its months
sb_month <- stats::aggregate(cbind(q_local = q_local * n_days, q_acc = q_acc * n_days, n = n_days) ~ subid + month,
                             data = sb_days, FUN = sum)
sb_month$q_local <- sb_month$q_local / sb_month$n
sb_month$q_acc <- sb_month$q_acc / sb_month$n
sb_year <- stats::aggregate(cbind(q_local = q_local * n_days, q_acc = q_acc * n_days, n = n_days) ~ subid,
                            data = sb_days, FUN = sum)
sb_year$q_local <- sb_year$q_local / sb_year$n
sb_year$q_acc <- sb_year$q_acc / sb_year$n

# Check 1: PCIC's own outlet on the gauge's segment. Of several, the one with
# the largest annual q_acc, which is the most downstream on the segment.
outlets$q_year <- sb_year$q_acc[match(outlets$subid, sb_year$subid)]
outlets <- outlets[order(outlets$linear_feature_id, -outlets$q_year, outlets$subid), ]
n_multi <- sum(duplicated(outlets$linear_feature_id))
outlet_of <- outlets[!duplicated(outlets$linear_feature_id), c("linear_feature_id", "subid")]
g$outlet <- outlet_of$subid[match(g$linear_feature_id, outlet_of$linear_feature_id)]
OUT <- matrix(NA_real_, nrow(g), 13, dimnames = list(g$station_number, 0:12))
for (k in which(!is.na(g$outlet))) {
  q <- sb_month$q_acc[sb_month$subid == g$outlet[k]][order(sb_month$month[sb_month$subid == g$outlet[k]])]
  stopifnot(length(q) == 12)
  q0 <- sb_year$q_acc[sb_year$subid == g$outlet[k]]
  OUT[k, ] <- c(q0, q) * days * 86400 / g$upstream_area_m2[k] * 1000
}
i1 <- S & !is.na(g$outlet)
# a month's share of the year, so outlet and segment compare in shape
share_of <- function(M, i) M[i, as.character(1:12), drop = FALSE] / rowSums(M[i, as.character(1:12), drop = FALSE])
d_share <- 100 * (share_of(OUT, i1) - share_of(RT, i1))
c1_rows <- function(lab, M) {
  sprintf("%-28s %+8.1f %+8.1f %+8.1f %8.2f", lab, med_err(ratio_s(M, i1, 3:4)), med_err(ratio_s(M, i1, 7:8)),
          med_err(ratio_m(M, i1, 0)), stats::median(nse_g(M, i1)))
}
c1_ma <- c(outlet = med_err(ratio_s(OUT, i1, 3:4)), segment = med_err(ratio_s(RT, i1, 3:4)))
c1_ja <- c(outlet = med_err(ratio_s(OUT, i1, 7:8)), segment = med_err(ratio_s(RT, i1, 7:8)))
# the rule, set before the numbers: the crosswalk is cleared of the shape when
# PCIC's own outlet is low in Mar-Apr and high in Jul-Aug by at least the
# segment's error less 2 points, i.e. the distribution onto the FWA adds no
# more than 2 points to either
c1_cleared <- c1_ma[["outlet"]] <= c1_ma[["segment"]] + 2 && c1_ja[["outlet"]] >= c1_ja[["segment"]] - 2 &&
  c1_ma[["outlet"]] < 0 && c1_ja[["outlet"]] > 0

say("## #67 check 1: PCIC's own outlet against the published segment",
    "PCIC's accumulated routed flow (q_acc) at the outlet placed on the gauge's segment, months from the run's",
    "calendar days weighted by their count, in mm over the gauge's area as the segment's are. The segment adds",
    "to the outlets above it the local runoff spread by FWA area (fwapg's crosswalk); the outlet has none of that.",
    sprintf("shared gauges with a placed outlet on their segment: %d of %d; segments holding several outlets: %d",
            sum(i1), sum(S), sum(g$linear_feature_id[i1] %in% outlets$linear_feature_id[duplicated(outlets$linear_feature_id)])),
    sprintf("(of several, the outlet with the largest annual flow; %d outlets set aside that way across all gauges)", n_multi),
    sprintf("%-28s %8s %8s %8s %8s", "median error (%)", "Mar-Apr", "Jul-Aug", "year", "NSE"),
    c1_rows("PCIC outlet", OUT), c1_rows("published segment", RT), c1_rows("balance", WB),
    sprintf("outlet share minus segment share, per month, median over gauges (points of the year's flow):"),
    sprintf("  %s", paste(sprintf("%s %+.2f", month_lab, apply(d_share, 2, stats::median)), collapse = "  ")),
    sprintf("  largest absolute difference at any gauge-month: %.2f points", max(abs(d_share))),
    sprintf("verdict: %s", if (c1_cleared) {
      "theirs. PCIC's own outlet carries the shape; the crosswalk's distribution onto the FWA adds no more than 2 points"
    } else {
      "unresolved. PCIC's own outlet does not carry the shape within 2 points of the segment's"
    }),
    "")

# Check 2: scale and placement. On the gauge's segment, the share of routed
# flow that is the sub-basin's local runoff spread by FWA area rather than
# routed from the outlets above: near 1, the gauge's months are the PCIC
# sub-basin's, not its catchment's. And the catchment in VIC-GL cells
# (0.0625 degrees, about 30 km2 in BC).
wi <- match(g$linear_feature_id, w_gauge$linear_feature_id)
up_q <- vapply(seq_len(nrow(g)), function(k) {
  if (is.na(wi[k])) return(NA_real_)
  u <- w_gauge$upstream_subids[[wi[k]]]
  if (length(u)) sum(sb_year$q_acc[match(u, sb_year$subid)]) else 0
}, 0)
loc_q <- ifelse(is.na(wi), NA_real_,
                sb_year$q_local[match(w_gauge$subid[wi], sb_year$subid)] * w_gauge$share[wi])
g$frac_local <- loc_q / (up_q + loc_q)
cell_km2 <- (0.0625 * 111.32)^2 * cos(g$lat * pi / 180)
g$cells <- g$area_km2 / cell_km2
g$nse_rt <- NA_real_
g$nse_rt[S] <- nse_g(RT, S)
g$nse_wb <- nse_g(WB, A)
i_small <- S & g$area_class == "<100 km2"
stopifnot(!anyNA(g$frac_local[S]))
i_own <- i_small & g$frac_local > 0.999
i_part <- i_small & g$frac_local <= 0.999
tercile <- function(x) cut(x, stats::quantile(x, c(0, 1 / 3, 2 / 3, 1)), include.lowest = TRUE, dig.lab = 3)
# the gap: balance NSE minus routed NSE per gauge, medianed. A gauge both
# sources find hard has a small gap; one routed alone finds hard, a large one.
gap <- function(i) stats::median(g$nse_wb[i] - g$nse_rt[i])
by_tercile <- function(lab, x, i) {
  t <- tercile(x[i])
  c(sprintf("%s, terciles: median monthly NSE, routed | balance | gap (n)", lab),
    vapply(levels(t), function(l) {
      k <- which(i)[t == l]
      sprintf("  %-22s %6.2f | %5.2f | %5.2f (%d)", l, stats::median(g$nse_rt[k]), stats::median(g$nse_wb[k]),
              stats::median(g$nse_wb[k] - g$nse_rt[k]), length(k))
    }, ""))
}
# the rule for checks 2 and 3, set before the numbers: a reading is supported
# where routed's gap to the balance at the gauges it names exceeds the gap at
# the other small gauges by at least 0.1 NSE
gap_margin <- 0.1
rho <- function(x, i) stats::cor(x[i], g$nse_rt[i], method = "spearman")
say("## #67 check 2: scale and placement, at the shared gauges under 100 km2",
    "local share: of the routed flow on the gauge's segment, the part that is its PCIC sub-basin's local runoff",
    "spread by FWA area (q_local x share, from pcic.segment_weights and the run's days, annual means); 1 means",
    "the segment's months are the sub-basin's own. cells: the catchment's area in VIC-GL cells at its latitude.",
    sprintf("gauges: %d; local share median %.2f (%.0f %% of them at 1); cells median %.1f",
            sum(i_small), stats::median(g$frac_local[i_small]), 100 * mean(g$frac_local[i_small] > 0.999),
            stats::median(g$cells[i_small])),
    sprintf("Spearman rank correlation with routed monthly NSE: local share %+.2f, cells %+.2f",
            rho(g$frac_local, i_small), rho(g$cells, i_small)),
    by_tercile("cells", g$cells, i_small),
    sprintf("local share = 1 (the sub-basin's own months): routed %.2f | balance %.2f | gap %.2f (n %d)",
            stats::median(g$nse_rt[i_own]), stats::median(g$nse_wb[i_own]), gap(i_own), sum(i_own)),
    sprintf("local share below 1:                         routed %.2f | balance %.2f | gap %.2f (n %d)",
            stats::median(g$nse_rt[i_part]), stats::median(g$nse_wb[i_part]), gap(i_part), sum(i_part)),
    sprintf("for scale: at all %d shared gauges, local share median %.2f; Spearman with routed NSE %+.2f",
            sum(S), stats::median(g$frac_local[S]), rho(g$frac_local, S)),
    sprintf("verdict: %s", if (gap(i_own) - gap(i_part) >= gap_margin) {
      sprintf(paste("theirs (PCIC's resolution). Where the gauge sits inside one PCIC sub-basin with no outlet above,",
                    "its months are that sub-basin's, and routed's gap to the balance there is %.2f wider"),
              gap(i_own) - gap(i_part))
    } else {
      sprintf("unresolved. The gap at gauges inside one sub-basin differs from the rest by %+.2f, inside the %.1f margin",
              gap(i_own) - gap(i_part), gap_margin)
    }),
    "")

# Check 3: late melt against basin character. The observed peak month and the
# catchment's median elevation (the fit's predictor) against routed's score.
g$peak <- apply(OBS[, as.character(1:12)], 1, which.max)
g$peak_class <- cut(g$peak, c(0, 5, 6, 12), labels = c("Jan-May", "Jun", "Jul-Dec"))
i_early <- i_small & g$peak <= 5
i_early_low <- i_early & g$elev < stats::median(g$elev[i_small])
peak_tab <- function(i, lab) {
  c(sprintf("%s: median monthly NSE by observed peak month, routed | balance (n)", lab),
    vapply(levels(g$peak_class), function(p) {
      k <- i & g$peak_class == p
      if (!any(k)) return(sprintf("  %-8s       -", p))
      sprintf("  %-8s %6.2f | %5.2f (%d)", p, stats::median(g$nse_rt[k]), stats::median(g$nse_wb[k]), sum(k))
    }, ""))
}
say("## #67 check 3: late melt against basin character",
    "The late-melt reading predicts routed loses most at early-peaking, low-elevation gauges, where a melt that",
    "starts late misses the peak month outright.",
    peak_tab(i_small, sprintf("under 100 km2 (%d)", sum(i_small))),
    peak_tab(S & !i_small, sprintf("100 km2 and over (%d)", sum(S & !i_small))),
    by_tercile("median elevation (m), under 100 km2", g$elev, i_small),
    sprintf("Spearman with routed monthly NSE, under 100 km2: elevation %+.2f, peak month %+.2f",
            rho(g$elev, i_small), rho(g$peak, i_small)),
    sprintf("under 100 km2, peaking by May: gap %.2f (n %d); peaking later: gap %.2f (n %d)",
            gap(i_early), sum(i_early), gap(i_small & !i_early), sum(i_small & !i_early)),
    sprintf("under 100 km2, peaking by May and below the median elevation (%.0f m): gap %.2f (n %d); the rest %.2f",
            stats::median(g$elev[i_small]), gap(i_early_low), sum(i_early_low), gap(i_small & !i_early_low)),
    sprintf("verdict: %s", if (gap(i_early) - gap(i_small & !i_early) >= gap_margin) {
      sprintf(paste("theirs (the model's melt timing). Routed's gap to the balance at small early-peaking gauges is",
                    "%.2f wider than at the later-peaking ones, as a late melt predicts"),
              gap(i_early) - gap(i_small & !i_early))
    } else {
      sprintf("unresolved. Routed's gap at small early-peaking gauges differs from the later-peaking by %+.2f, inside the %.1f margin",
              gap(i_early) - gap(i_small & !i_early), gap_margin)
    }),
    "")
