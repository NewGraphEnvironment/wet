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
#   - the crosswalk, the segments' weights and the run's sub-basin days
#     (#67's checks), refused unless they are the tracked daily report's;
#   - routed PCIC year by year (#162's minimum flows): fwapg#42's per-year
#     sub-basin days under WET_PCIC_YEARS, each file held to its pcic.series
#     row, and their bins to the run's pcic.subbasin_daily (routed_years_check);
#   - HYDAT (the fit's release) for each gauge's yearly monthly means.
# The gauge table (observed, balance and routed, months 0-12) must equal the
# one the segment-discharge article reads (inst/vignette-data/monthly_values.rds),
# so the report and the article score the same numbers: observed, balance and
# routed months 1-12 identical, routed month 0 within 1e-12 relative (publish
# takes its mean of twelve in another order), and the fit's files the md5s the
# bundle records.
#
# ---- rules registered at 520b9ca, before the numbers they judge (#166) ------------------------
# The text below is as committed at 520b9ca; amendments made after numbers
# were seen are listed apart, after it, and nowhere else.
#
# A first run (f4e26c3, 2814914) judged #67's checks under rules written with
# their code, and the plan review found two of them unsound: check 1 compared
# the published segment with itself (every outlet segment has share 1, and
# q_acc is accumulated down the FWA tree, fwapg's README step 5), and monthly
# NSE at small gauges mostly measures annual volume (Spearman -0.77 with the
# absolute annual error under 100 km2, against -0.19 for the shape-only share
# NSE). The rules below replace them, before any number they judge is computed.
#
# Check 1, the shape in PCIC's own outflow. A placed outlet's networks agree
# when the placed outlets above it on the FWA tree (fwa_parent_subid) are
# exactly the placed outlets in its PCIC subtree (dowsubid, through unplaced
# outlets); there its q_acc is PCIC's outflow (fwapg's README step 5), and the
# segment it is placed on carries it (share 1). Verdict, at the shared gauges
# whose segment's outlet agrees: theirs if routed's median Mar-Apr error is
# -5 % or lower and its Jul-Aug error +5 % or higher; ours (the crosswalk) if
# neither holds there while both hold at the other shared gauges; otherwise
# unresolved.
#
# Shape is scored by share NSE: the Nash-Sutcliffe efficiency of a gauge's
# twelve monthly shares of its year, so annual volume does not enter. The gap
# is the balance's share NSE minus routed's at the same gauge, medianed, so a
# gauge any model finds hard counts for little.
# Check 2, resolution: at shared gauges under 100 km2, supported (theirs:
# PCIC's sub-basins are coarser than the catchment) if the gap where the
# segment's flow is all its sub-basin's local runoff (local share 1) exceeds
# the gap at the rest by 0.05 or more; otherwise unresolved.
# Check 3, late melt: at shared gauges under 100 km2, supported (theirs: the
# model's melt timing) if the gap at gauges peaking by May exceeds the gap at
# those peaking later by 0.05 or more; otherwise unresolved.
#
# The per-year files (#162): each file's bins, averaged over 1981-2010, equal
# pcic.subbasin_daily for the 1981-2010 run within float32 precision (2^-23 of
# the mean absolute value) on every sub-basin read; and the routed per-year
# days average to the published months within 1e-3 relative at every
# gauge-month (the two clamp at zero in a different order, and the days are
# rounded to 5 decimals).
#
# ---- amended after numbers were seen (code review rounds 1-3, #166) --------------------------
# - Check 2's "local share 1" is taken as above 0.999, for rounding (in the
#   code from ba29835, the first run of these rules).
# - Checks 2 and 3 printed a third outcome, "not supported", from ba29835 to
#   7a8a5ac; since 613b296 they print only the two registered outcomes, with
#   the direction of the gap beside "unresolved".
# - The bin parity adds 1e-9 m3/s to its bound, so a bin of all-zero flow
#   compares, as scripts/departure_pcic.R does (in the code from ba29835).
# - The per-year parity: ba29835 divided by the published month floored at
#   1e-3 m3/s (an absolute bound of 1e-6 m3/s below that); 7a8a5ac floored the
#   bound at 1e-5 m3/s; since 613b296 there is no floor, so the registered rule
#   applies, and a published month of zero admits no difference. No gauge-month
#   was ever under a floor: the smallest published month at the shared Fraser
#   gauges is 0.012 m3/s.
# - HYDAT's yearly monthly means must average to the gauge table's normals
#   (the same flows, summed in another order): within 0.02 relative from
#   ba29835, within 1e-9 since 613b296. Not in the registered text; measured
#   5.9e-16 throughout.
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
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data-raw", "data/checks", "inst/vignette-data")
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
  stop("the fit stores no held-out months under its shipped share specification and method: ",
       "rerun scripts/wb_validate.R")
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
  stop(f_routed, " was not made from this routed table at fwapg ", fwapg_commit,
       ": rerun scripts/pcic_routed_compare.R")
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
# #67's checks: the whole crosswalk (every PCIC outlet, its PCIC parent, and
# for a placed one, flag NULL, its segment and nearest placed outlet below on
# the FWA), the gauge segments' weights, and the run's days for every
# sub-basin those name (q_acc: accumulated flow at the outlet; q_local: the
# runoff given to the sub-basin)
xw <- DBI::dbGetQuery(conn, "
  SELECT subid, dowsubid, fwa_parent_subid, linear_feature_id::int AS linear_feature_id, flag
  FROM pcic.fwa_crosswalk ORDER BY subid")
stopifnot(!anyDuplicated(xw$subid))
w_gauge <- routed_weights(conn, lfid_all)
sub_need <- sort(unique(c(w_gauge$subid, unlist(w_gauge$upstream_subids))))
sb_days <- DBI::dbGetQuery(conn, sprintf("
  SELECT subid, month::int AS month, day::int AS day, n_days, q_local, q_acc
  FROM %s WHERE %s AND subid IN (%s) ORDER BY subid, month, day",
  routed_daily_table, routed_where, paste(sub_need, collapse = ", ")))
stopifnot(setequal(sb_days$subid, sub_need), !anyNA(sb_days$q_acc), !anyNA(sb_days$q_local))
# #162's minimum flows: the per-year files for DFO's period, held to pcic.series
years_dfo <- 1981:2010
lfid_fr <- cal$linear_feature_id[routed_basin(cal$station_number) == "Fraser"]
w_fr_all <- w_gauge[w_gauge$linear_feature_id %in% lfid_fr, ]
yr <- routed_years_check(conn, Sys.getenv("WET_PCIC_YEARS"), years_dfo,
                         subs = sort(unique(c(w_fr_all$subid, unlist(w_fr_all$upstream_subids)))))
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
# observed, balance and routed months 1-12 identical; routed month 0 within
# 1e-12 relative (publish takes its mean of twelve in another order)
cols_id <- c("station_number", "month", "zone", "nesting", "area_class", "obs_mm", "wb_mm")
m0 <- gx$month == 0
if (!identical(gx[cols_id], bg[cols_id]) || !identical(gx$routed_mm[!m0], bg$routed_mm[!m0]) ||
      !identical(is.na(gx$routed_mm), is.na(bg$routed_mm))) {
  stop("the gauge table differs from ", f_bundle, "'s")
}
par_m0 <- max(abs(gx$routed_mm[m0] - bg$routed_mm[m0]) / bg$routed_mm[m0], na.rm = TRUE)
if (par_m0 > 1e-12) stop(sprintf("routed month 0 differs from the bundle's by %.3g relative", par_m0))
md5_now <- tools::md5sum(file.path(fit_dir, c("fits.rds", sprintf("cv_aet-%s.rds", fits$aet))))
if (!identical(unname(md5_now), unname(bundle$provenance$md5[basename(names(md5_now))]))) {
  stop("the fit's files are not the ones ", f_bundle, " was built from")
}
stopifnot(identical(bundle$provenance$routed_commit, fwapg_commit))

# ---- the gauges each comparison uses --------------------------------------------------------------
# per gauge, wide: observed, balance and routed months 1-12 and month 0
st_order <- cal$station_number[order(cal$station_number)]
wide <- function(col) {
  m <- matrix(gx[[col]], ncol = 13, byrow = TRUE, dimnames = list(unique(gx$station_number), 0:12))
  stopifnot(identical(rownames(m), st_order))
  m
}
obs_w <- wide("obs_mm")
wb_w <- wide("wb_mm")
rt_w <- wide("routed_mm")
g <- gx[gx$month == 0, c("station_number", "station_name", "lat", "linear_feature_id", "zone", "nesting",
                         "area_km2", "area_class", "lake", "elev", "upstream_area_m2")]
stopifnot(identical(g$station_number, rownames(obs_w)))
g$basin <- routed_basin(g$station_number)
# the shared set: routed has flow on the segment and it carries at least the
# far-low cut of observed annual flow (as the article's scores and the routed
# report's "without them" line take it)
g$routed <- !is.na(rt_w[, "0"])
g$shared <- g$routed & rt_w[, "0"] >= routed_far_low * obs_w[, "0"]
g$shared[is.na(g$shared)] <- FALSE
stopifnot(sum(g$routed) > 0, all(rowSums(is.na(rt_w[g$routed, ])) == 0))

# ---- scorers --------------------------------------------------------------------------------------
# per gauge-month, modelled over observed; a season is the ratio of its months'
# summed runoff, so a gauge counts once per season
ratio_m <- function(mm, i, m) mm[i, as.character(m)] / obs_w[i, as.character(m)]
ratio_s <- function(mm, i, ms) {
  rowSums(mm[i, as.character(ms), drop = FALSE]) / rowSums(obs_w[i, as.character(ms), drop = FALSE])
}
med_err <- function(r) 100 * (stats::median(r) - 1)
within <- function(r) 100 * mean(abs(r - 1) <= err_cut / 100)
nse_g <- function(mm, i) {
  vapply(which(i), function(k) wet:::wet_nse(obs_w[k, as.character(1:12)], mm[k, as.character(1:12)]), 0)
}
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
i_sh <- g$shared
i_all <- rep(TRUE, nrow(g))
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
    sprintf("gauge table = %s's (%d gauges): observed, balance, routed months 1-12 identical; routed month 0",
            f_bundle, nrow(g)),
    sprintf("  within %.2g relative; fits.rds and cv_aet-%s.rds the md5s it records", par_m0, fits$aet),
    "",
    "## What is scored",
    "Each gauge's monthly means over its complete years in 1981-2010 (at least 10; scripts/wb_stations.R), in mm",
    "over wet's accumulated upstream area. The balance is held out (blocked CV), as it ships; routed PCIC is the",
    sprintf("published %s run on the segment the gauge snapped to.", routed_run$period),
    "- error: modelled over observed, as %; a month's is per gauge-month, a season's the ratio of its summed",
    "  months",
    sprintf("- median: the median of those errors over gauges; within: the share of them inside +-%d %%", err_cut),
    "- monthly NSE: Nash-Sutcliffe efficiency of a gauge's twelve monthly means (1 is perfect, <= 0.5",
    "  unsatisfactory: Moriasi and others 2007), medianed over gauges",
    sprintf("- shared gauges: routed has flow on the segment and carries at least %.0f %% of observed annual flow",
            100 * routed_far_low),
    sprintf("  (%d of the %d with routed flow; %d below that cut are the routed report's far-low list). Both",
            sum(i_sh), sum(g$routed), n_low),
    sprintf("  sources are compared there; the balance alone on all %d.", nrow(g)),
    sprintf("- zones with fewer than %d gauges are marked *", min_zone),
    "")

# ---- #6: by month ---------------------------------------------------------------------------------
month_row <- function(lab, mm, i) {
  e <- vapply(1:12, function(m) med_err(ratio_m(mm, i, m)), 0)
  sprintf("%-26s %4d %s %s", lab, sum(i), paste(fmt_e(e), collapse = ""), fmt_e(med_err(ratio_m(mm, i, 0))))
}
month_head <- sprintf("%-26s %4s %s %6s", "", "n", paste(sprintf("%6s", month_lab), collapse = ""), "year")
say("## #6: median error by month (%)",
    month_head,
    month_row("routed, shared", rt_w, i_sh),
    month_row("balance, shared", wb_w, i_sh),
    month_row("balance, all", wb_w, i_all),
    sprintf("%-26s %4s %s", "within +-20 %, routed", "",
            paste(sprintf("%6.0f", vapply(1:12, function(m) within(ratio_m(rt_w, i_sh, m)), 0)), collapse = "")),
    sprintf("%-26s %4s %s", "within +-20 %, balance", "",
            paste(sprintf("%6.0f", vapply(1:12, function(m) within(ratio_m(wb_w, i_sh, m)), 0)), collapse = "")),
    "")

# ---- #6: by season and group ----------------------------------------------------------------------
season_head <- sprintf("%-30s %4s  %s  |  %s", "", "n",
                       paste(sprintf("%8s", names(seasons)), collapse = ""),
                       paste(sprintf("%8s", names(seasons)), collapse = ""))
season_row <- function(lab, i, mark = "") {
  if (!any(i)) return(NULL)
  er <- vapply(seasons, function(ms) med_err(ratio_s(rt_w, i, ms)), 0)
  ew <- vapply(seasons, function(ms) med_err(ratio_s(wb_w, i, ms)), 0)
  sprintf("%-30s %4d  %s  |  %s", paste0(lab, mark), sum(i), paste(sprintf("%+8.1f", er), collapse = ""),
          paste(sprintf("%+8.1f", ew), collapse = ""))
}
zones <- sort(unique(g$zone[i_sh]))
say("## #6: median seasonal error by region, shared gauges (%): routed | balance",
    season_head,
    season_row("all", i_sh),
    "-- major basin",
    unlist(lapply(c("Peace", "Fraser", "Columbia", "Coast", "Yukon", "Arctic"),
                  function(b) season_row(b, i_sh & g$basin == b))),
    "-- hydrologic zone",
    unlist(lapply(zones, function(z) {
      i <- i_sh & g$zone == z
      season_row(zone_lab(z), i, if (sum(i) < min_zone) " *" else "")
    })),
    "")
say("## #6: median seasonal error by basin size and type, shared gauges (%): routed | balance",
    season_head,
    unlist(lapply(c("<100 km2", "100-1000", "1000-10000", ">10000"),
                  function(a) season_row(a, i_sh & g$area_class == a))),
    season_row("headwater", i_sh & g$nesting == "headwater"),
    season_row("nested", i_sh & g$nesting == "nested"),
    season_row("lake outlet", i_sh & g$lake %in% TRUE),
    season_row("not lake outlet", i_sh & !(g$lake %in% TRUE)),
    "")
zones_all <- sort(unique(g$zone))
say(sprintf("## #6: the balance on all %d gauges, by zone: median seasonal error (%%) and monthly NSE", nrow(g)),
    sprintf("%-30s %4s  %s  %6s", "", "n", paste(sprintf("%8s", names(seasons)), collapse = ""), "NSE"),
    unlist(lapply(zones_all, function(z) {
      i <- g$zone == z
      e <- vapply(seasons, function(ms) med_err(ratio_s(wb_w, i, ms)), 0)
      sprintf("%-30s %4d  %s  %6.2f", paste0(zone_lab(z), if (sum(i) < min_zone) " *" else ""), sum(i),
              paste(sprintf("%+8.1f", e), collapse = ""), stats::median(nse_g(wb_w, i)))
    })),
    "")

# ---- PCIC's sub-basins: months and year from the run's calendar days, weighted by their count ----------
sb_month <- stats::aggregate(cbind(q_local = q_local * n_days, q_acc = q_acc * n_days, n = n_days) ~ subid + month,
                             data = sb_days, FUN = sum)
sb_month$q_local <- sb_month$q_local / sb_month$n
sb_month$q_acc <- sb_month$q_acc / sb_month$n
sb_year <- stats::aggregate(cbind(q_local = q_local * n_days, q_acc = q_acc * n_days, n = n_days) ~ subid,
                            data = sb_days, FUN = sum)
sb_year$q_local <- sb_year$q_local / sb_year$n
sb_year$q_acc <- sb_year$q_acc / sb_year$n

# ---- #67: the shape, rescored on this routed build -----------------------------------------------
# share NSE: the NSE of a gauge's twelve monthly shares of its year, so annual
# volume does not enter; the gap is the balance's minus routed's at one gauge
share_w <- function(mm, i) mm[i, as.character(1:12), drop = FALSE] / rowSums(mm[i, as.character(1:12), drop = FALSE])
nse_share_g <- function(mm, i) {
  so <- share_w(obs_w, i)
  sm <- share_w(mm, i)
  vapply(seq_len(nrow(so)), function(k) wet:::wet_nse(so[k, ], sm[k, ]), 0)
}
g$nse_rt <- g$nse_rt_share <- NA_real_
g$nse_rt[i_sh] <- nse_g(rt_w, i_sh)
g$nse_rt_share[i_sh] <- nse_share_g(rt_w, i_sh)
g$nse_wb <- nse_g(wb_w, i_all)
g$nse_wb_share <- nse_share_g(wb_w, i_all)
g$err_rt <- 100 * (rt_w[, "0"] / obs_w[, "0"] - 1)
gap <- function(i) stats::median(g$nse_wb_share[i] - g$nse_rt_share[i])
gap_margin <- 0.05  # registered in the header
# a verdict that does not reach the margin is unresolved, as registered; the
# line says which way the gap runs
verdict_off <- function(d, where) {
  sprintf("unresolved: the gap is %+.2f %s, %s", d, where,
          if (d < 0) "the other way from the reading" else sprintf("inside the %.2f margin", gap_margin))
}
lowhigh <- function(i) {
  ma <- ratio_s(rt_w, i, 3:4)
  ja <- ratio_s(rt_w, i, 7:8)
  c(low_ma = 100 * mean(ma < 1), high_ja = 100 * mean(ja > 1), both = 100 * mean(ma < 1 & ja > 1))
}
lh <- lowhigh(i_sh)
i_small <- i_sh & g$area_class == "<100 km2"
rho <- function(x, y, i) stats::cor(x[i], y[i], method = "spearman")
say(sprintf("## #67: routed PCIC's shape at the %d shared gauges (%s)", sum(i_sh), routed_run$period),
    sprintf("%-26s %7s %7s %7s %7s   %9s %9s", "", "Mar", "Apr", "Jul", "Aug", "Mar-Apr", "Jul-Aug"),
    sprintf("%-26s %s   %s", "routed, median error",
            paste(sprintf("%+7.1f", vapply(c(3, 4, 7, 8), function(m) med_err(ratio_m(rt_w, i_sh, m)), 0)),
                  collapse = ""),
            paste(sprintf("%+9.1f", c(med_err(ratio_s(rt_w, i_sh, 3:4)), med_err(ratio_s(rt_w, i_sh, 7:8)))),
                  collapse = "")),
    sprintf("%-26s %s   %s", "balance, median error",
            paste(sprintf("%+7.1f", vapply(c(3, 4, 7, 8), function(m) med_err(ratio_m(wb_w, i_sh, m)), 0)),
                  collapse = ""),
            paste(sprintf("%+9.1f", c(med_err(ratio_s(wb_w, i_sh, 3:4)), med_err(ratio_s(wb_w, i_sh, 7:8)))),
                  collapse = "")),
    sprintf("gauges where routed is low in Mar-Apr: %.0f %%; high in Jul-Aug: %.0f %%; both: %.0f %%",
            lh[["low_ma"]], lh[["high_ja"]], lh[["both"]]),
    "",
    "By basin size, at the shared gauges: median monthly NSE (volume and shape) and share NSE (shape alone),",
    "and the median absolute annual error, routed then balance",
    sprintf("%-14s %4s %15s %15s %15s", "", "n", "monthly NSE", "share NSE", "abs annual %"),
    unlist(lapply(c("<100 km2", "100-1000", "1000-10000", ">10000", "all"), function(a) {
      i <- if (a == "all") i_sh else i_sh & g$area_class == a
      sprintf("%-14s %4d %7.2f %7.2f %7.2f %7.2f %7.1f %7.1f", a, sum(i), stats::median(g$nse_rt[i]),
              stats::median(g$nse_wb[i]), stats::median(g$nse_rt_share[i]), stats::median(g$nse_wb_share[i]),
              stats::median(abs(g$err_rt[i])), stats::median(abs(100 * (wb_w[i, "0"] / obs_w[i, "0"] - 1))))
    })),
    sprintf(paste("under 100 km2, Spearman of routed's score with its absolute annual error: monthly NSE %+.2f,",
                  "share NSE %+.2f. Monthly NSE there mostly measures volume."),
            rho(g$nse_rt, abs(g$err_rt), i_small), rho(g$nse_rt_share, abs(g$err_rt), i_small)),
    "")

# ---- #67 check 1: the shape in PCIC's own outflow -------------------------------------------------
# A placed outlet's networks agree when the placed outlets above it on the FWA
# tree are exactly those in its PCIC subtree; there q_acc is PCIC's outflow
# and the segment it is placed on carries it (share 1). Rule in the header.
placed <- xw$subid[is.na(xw$flag)]
kids_pcic <- split(xw$subid, xw$dowsubid)
kids_fwa <- split(xw$subid[is.na(xw$flag) & !is.na(xw$fwa_parent_subid)],
                  xw$fwa_parent_subid[is.na(xw$flag) & !is.na(xw$fwa_parent_subid)])
below <- function(kids, root) {
  out <- integer()
  front <- root
  while (length(front)) {
    nxt <- unlist(kids[as.character(front)], use.names = FALSE)
    nxt <- nxt[!nxt %in% out]
    out <- c(out, nxt)
    front <- nxt
  }
  out
}
wi <- match(g$linear_feature_id, w_gauge$linear_feature_id)
own_seg <- xw$linear_feature_id[match(w_gauge$subid[wi], xw$subid)]
g$outlet <- ifelse(!is.na(wi) & !is.na(own_seg) & own_seg == g$linear_feature_id &
                     w_gauge$subid[wi] %in% placed, w_gauge$subid[wi], NA_integer_)
stopifnot(all(w_gauge$share[wi[!is.na(g$outlet)]] == 1))
g$agree <- NA
for (k in which(!is.na(g$outlet))) {
  p <- below(kids_pcic, g$outlet[k])
  g$agree[k] <- setequal(intersect(p, placed), below(kids_fwa, g$outlet[k]))
}
i_ag <- i_sh & g$agree %in% TRUE
i_dis <- i_sh & g$agree %in% FALSE
i_none <- i_sh & is.na(g$outlet)
c1_row <- function(lab, i) {
  if (!any(i)) return(sprintf("%-34s %4d", lab, 0L))
  sprintf("%-34s %4d %+8.1f %+8.1f %8.2f   %+8.1f %+8.1f %8.2f", lab, sum(i), med_err(ratio_s(rt_w, i, 3:4)),
          med_err(ratio_s(rt_w, i, 7:8)), stats::median(g$nse_rt_share[i]), med_err(ratio_s(wb_w, i, 3:4)),
          med_err(ratio_s(wb_w, i, 7:8)), stats::median(g$nse_wb_share[i]))
}
shape_holds <- function(i) any(i) && med_err(ratio_s(rt_w, i, 3:4)) <= -5 && med_err(ratio_s(rt_w, i, 7:8)) >= 5
c1_verdict <- if (shape_holds(i_ag)) {
  "theirs. The shape is in PCIC's own outflow, at gauges where the crosswalk only relabels it"
} else if (any(i_ag) && med_err(ratio_s(rt_w, i_ag, 3:4)) > -5 && med_err(ratio_s(rt_w, i_ag, 7:8)) < 5 &&
             shape_holds(i_sh & !i_ag)) {
  "ours (the crosswalk). The shape is absent where the networks agree and present elsewhere"
} else {
  "unresolved"
}
say("## #67 check 1: the shape in PCIC's own outflow",
    "At a segment an outlet is placed on, routed flow is that outlet's accumulated flow (share 1), which fwapg",
    "accumulates down the FWA tree of placed outlets. Where the placed outlets above it on the FWA are exactly",
    "those in its PCIC subtree, that is PCIC's own outflow (fwapg's README, step 5).",
    sprintf("%-34s %4s %8s %8s %8s   %8s %8s %8s", "shared gauges, median", "n", "rt M-A", "rt J-A", "rt shNSE",
            "wb M-A", "wb J-A", "wb shNSE"),
    c1_row("outlet on segment, networks agree", i_ag),
    c1_row("outlet on segment, they differ", i_dis),
    c1_row("no outlet on segment", i_none),
    sprintf("verdict: %s", c1_verdict),
    "")

# ---- #67 check 2: PCIC's resolution ---------------------------------------------------------------
# On the gauge's segment, the share of routed flow that is its sub-basin's
# local runoff spread by FWA area rather than routed from the outlets above:
# at 1, the gauge's months are its PCIC sub-basin's, whatever its own catchment
up_q <- vapply(seq_len(nrow(g)), function(k) {
  if (is.na(wi[k])) return(NA_real_)
  u <- w_gauge$upstream_subids[[wi[k]]]
  if (length(u)) sum(sb_year$q_acc[match(u, sb_year$subid)]) else 0
}, 0)
loc_q <- ifelse(is.na(wi), NA_real_, sb_year$q_local[match(w_gauge$subid[wi], sb_year$subid)] * w_gauge$share[wi])
g$frac_local <- loc_q / (up_q + loc_q)
stopifnot(!anyNA(g$frac_local[i_sh]))
i_own <- i_small & g$frac_local > 0.999
i_part <- i_small & g$frac_local <= 0.999
gap_row <- function(lab, i) {
  sprintf("  %-40s share NSE routed %.2f | balance %.2f | gap %.2f (n %d)", lab, stats::median(g$nse_rt_share[i]),
          stats::median(g$nse_wb_share[i]), gap(i), sum(i))
}
say("## #67 check 2: PCIC's resolution, at the shared gauges under 100 km2",
    "local share: of the routed flow on the gauge's segment, the part that is its PCIC sub-basin's local runoff",
    "(q_local x share, from pcic.segment_weights and the run's days, annual means); at 1 the segment's months are",
    "the sub-basin's own, however the catchment differs.",
    sprintf("gauges: %d; local share median %.2f, at 1 for %.0f %%", sum(i_small), stats::median(g$frac_local[i_small]),
            100 * mean(i_own[i_small])),
    gap_row("local share 1", i_own),
    gap_row("local share below 1", i_part),
    sprintf("verdict: %s", if (gap(i_own) - gap(i_part) >= gap_margin) {
      sprintf(paste("supported (theirs: PCIC's resolution): the gap is %.2f wider where the gauge's months",
                    "are its sub-basin's"),
              gap(i_own) - gap(i_part))
    } else {
      verdict_off(gap(i_own) - gap(i_part), "where the gauge's months are its sub-basin's")
    }),
    "")

# ---- #67 check 3: late melt -----------------------------------------------------------------------
g$peak <- apply(obs_w[, as.character(1:12)], 1, which.max)
i_early <- i_small & g$peak <= 5
tercile <- function(x) cut(x, stats::quantile(x, c(0, 1 / 3, 2 / 3, 1)), include.lowest = TRUE, dig.lab = 4)
t_elev <- tercile(g$elev[i_small])
say("## #67 check 3: late melt, at the shared gauges under 100 km2",
    "A melt that starts late misses an early peak outright, so the late-melt reading predicts routed's shape",
    "loses most where the observed peak is early.",
    gap_row("peak by May", i_early),
    gap_row("peak June or later", i_small & !i_early),
    "by mean upstream elevation (m), terciles:",
    vapply(levels(t_elev), function(l) gap_row(l, seq_len(nrow(g)) %in% which(i_small)[t_elev == l]), ""),
    sprintf("verdict: %s", if (gap(i_early) - gap(i_small & !i_early) >= gap_margin) {
      sprintf("supported (theirs: the model's melt timing): the gap is %.2f wider at early-peaking gauges",
              gap(i_early) - gap(i_small & !i_early))
    } else {
      verdict_off(gap(i_early) - gap(i_small & !i_early), "at early-peaking gauges")
    }),
    "")

# ---- #162: DFO's Fraser validation (Iacarella et al. 2025, App. F, Table F1) -----------------------
# Table F1 scores 86 Fraser gauges (not listed; a map only, Fig. F1) across gauges in m3/s, per month,
# season and year: R2, mean absolute error (m3/s), mean absolute percent error (a fraction) and NSE, each
# on the minimum, maximum and mean of the 1981-2010 monthly (seasonal, annual) flows. Here: the shared
# Fraser calibration gauges, Mean for both sources, and Min for routed PCIC routed year by year from
# fwapg#42's files. The balance is a 1981-2010 normal and has no years, so no Min.
i_fr <- i_sh & g$basin == "Fraser"
fr <- g[i_fr, ]
hydat <- wb_hydat(release)
sel <- wet_station_select(hydat, years = years_dfo, min_years = 10)
yrs <- attr(sel, "years")[fr$station_number]
if (anyNA(names(yrs)) || !all(lengths(yrs) == cal$n_years[match(fr$station_number, cal$station_number)])) {
  stop("the recomputed complete years differ from the stations rds")
}
hcon <- wet_hydat_connect(hydat)
flows <- paste(sprintf("FLOW%d", 1:31), collapse = ", ")
dly <- DBI::dbGetQuery(hcon, sprintf("
  SELECT STATION_NUMBER AS station_number, YEAR AS year, MONTH AS month, %s FROM DLY_FLOWS
  WHERE STATION_NUMBER IN (%s) ORDER BY 1, 2, 3", flows, paste0("'", fr$station_number, "'", collapse = ", ")))
DBI::dbDisconnect(hcon)
dly <- dly[mapply(function(s, y) y %in% yrs[[s]], dly$station_number, dly$year), ]
fl <- as.matrix(dly[sprintf("FLOW%d", 1:31)])
stopifnot(all(rowSums(!is.na(fl)) >= 20))
obs_y <- data.frame(station_number = dly$station_number, year = dly$year, month = dly$month,
                    q = rowMeans(fl, na.rm = TRUE))
stopifnot(!anyDuplicated(obs_y[c("station_number", "year", "month")]),
          nrow(obs_y) == 12 * sum(lengths(yrs)))

# routed year by year on the Fraser gauges' segments
w_fr <- w_gauge[w_gauge$linear_feature_id %in% fr$linear_feature_id, ]
stopifnot(setequal(w_fr$linear_feature_id, fr$linear_feature_id))
rd <- wet_routed_years(dirname(yr$files[1]), w_fr[c("linear_feature_id", "subid", "share", "upstream_subids")],
                       years = years_dfo, series = paste(routed_run$model, routed_run$scenario, sep = "_"))
rd$year <- as.integer(format(rd$date, "%Y"))
rd$month <- as.integer(format(rd$date, "%m"))
rt_y <- stats::aggregate(q_m3s ~ linear_feature_id + year + month, rd, mean)
rt_all <- stats::aggregate(q_m3s ~ linear_feature_id + month, rd, mean)
# parity: the run's days, all 30 years, against the published 1981-2010 months. fwapg averages each
# calendar day over the years first and clamps at zero after; wet_routed_years() clamps and rounds each
# day, so the two part where a sub-basin's day goes below zero, and by rounding (5 decimals) elsewhere.
pub <- routed_m[routed_m$linear_feature_id %in% fr$linear_feature_id, ]
pm <- merge(pub, rt_all, by = c("linear_feature_id", "month"), suffixes = c("_pub", "_days"))
stopifnot(nrow(pm) == 12 * nrow(fr))
par_tol <- 1e-3  # relative, at each gauge-month (registered in the header)
d_par <- abs(pm$q_m3s_pub - pm$q_m3s_days)
par_abs <- max(d_par)
par_rel <- max(d_par[pm$q_m3s_pub > 0] / pm$q_m3s_pub[pm$q_m3s_pub > 0])
if (any(d_par > par_tol * pm$q_m3s_pub)) {
  k <- which.max(d_par - par_tol * pm$q_m3s_pub)
  stop(sprintf("the per-year days do not average to the published months: segment %d month %d, %.3g against %.3g m3/s",
               pm$linear_feature_id[k], pm$month[k], pm$q_m3s_days[k], pm$q_m3s_pub[k]))
}

# per gauge, by the gauge's own complete years: monthly, seasonal (calendar months of one year, so
# winter is Jan, Feb and that year's Dec) and annual flow (m3/s, by month length); Min is the lowest year
dfo_scales <- c(stats::setNames(as.list(1:12), month.name), list(Winter = c(12, 1, 2), Spring = 3:5,
                Summer = 6:8, Autumn = 9:11, Annual = 1:12))
mdays <- wet_month_days()
scale_q <- function(d, ms) {
  d <- d[d$month %in% ms, ]
  d$w <- mdays[d$month]
  a <- stats::aggregate(cbind(qw = q * w, w = w) ~ station_number + year, d, sum)
  a$q <- a$qw / a$w
  a[c("station_number", "year", "q")]
}
rt_y$station_number <- fr$station_number[match(rt_y$linear_feature_id, fr$linear_feature_id)]
rt_y <- rt_y[mapply(function(s, y) y %in% yrs[[s]], rt_y$station_number, rt_y$year), ]
names(rt_y)[names(rt_y) == "q_m3s"] <- "q"
stopifnot(nrow(rt_y) == nrow(obs_y))
# mm over a month -> m3/s: mm * area / 1000 / (days * 86400); a season's mean flow is its volume over its days
to_q <- function(mm, ms) {
  vol_m3 <- rowSums(mm[i_fr, as.character(ms), drop = FALSE]) / 1000 * fr$upstream_area_m2
  vol_m3 / (sum(mdays[ms]) * 86400)
}
# MAPE over the gauges with flow: a gauge whose lowest year is dry (zero) has
# no percent error. Beside DFO's statistics, two that the range of basin sizes
# does not carry: R2 on log flow, and the median over gauges of each gauge's
# absolute percent error (as a fraction, as DFO prints MAPE).
f1 <- function(obs, mod) {
  k <- obs > 0
  kl <- k & mod > 0
  c(r2 = stats::cor(obs, mod)^2, mae = mean(abs(mod - obs)), mape = mean(abs(mod[k] - obs[k]) / obs[k]),
    nse = 1 - sum((mod - obs)^2) / sum((obs - mean(obs))^2), dry = sum(!k),
    r2_log = stats::cor(log(obs[kl]), log(mod[kl]))^2, mdape = stats::median(abs(mod[k] - obs[k]) / obs[k]))
}
dfo <- data.frame(
  scale = names(dfo_scales),
  r2_min = c(0.97, 0.87, 0.68, 0.82, 0.82, 0.88, 0.60, 0.35, 0.34, 0.81, 0.76, 0.87, 0.90, 0.84, 0.86, 0.58, 0.93),
  r2_mean = c(0.95, 0.89, 0.95, 0.99, 0.99, 0.99, 0.99, 0.95, 0.97, 0.99, 0.93, 0.95, 0.95, 0.99, 1.00, 0.96, 0.99),
  mape_min = c(0.54, 0.56, 0.56, 0.58, 0.68, 0.51, 0.66, 0.85, 0.79, 0.58, 0.55, 0.55, 0.56, 0.48, 0.52, 0.62, 0.35),
  mape_mean = c(0.39, 0.43, 0.38, 0.42, 0.45, 0.33, 0.38, 0.49, 0.43, 0.36, 0.45, 0.45, 0.40, 0.36, 0.30, 0.41, 0.25),
  nse_min = c(0.97, 0.92, 0.86, 0.91, 0.91, 0.93, 0.84, 0.79, 0.79, 0.90, 0.88, 0.93, 0.94, 0.91, 0.92, 0.84, 0.95),
  nse_mean = c(0.97, 0.94, 0.97, 0.99, 0.99, 0.99, 0.99, 0.96, 0.98, 0.99, 0.96, 0.97, 0.97, 0.99, 1.00, 0.97, 0.99))
f1_rows <- lapply(names(dfo_scales), function(sc) {
  ms <- dfo_scales[[sc]]
  o_mean <- to_q(obs_w, ms)
  # observed normal from the gauge table against the mean of its years: the same flows
  oy <- scale_q(obs_y, ms)
  oy_mean <- tapply(oy$q, oy$station_number, mean)[fr$station_number]
  ry <- scale_q(rt_y, ms)
  o_min <- tapply(oy$q, oy$station_number, min)[fr$station_number]
  r_min <- tapply(ry$q, ry$station_number, min)[fr$station_number]
  list(scale = sc, obs_gap = max(abs(oy_mean - o_mean) / o_mean), min_ratio = (r_min / o_min)[o_min > 0],
       rt_mean = f1(o_mean, to_q(rt_w, ms)), wb_mean = f1(o_mean, to_q(wb_w, ms)), rt_min = f1(o_min, r_min))
})
obs_gap <- max(vapply(f1_rows, `[[`, 0, "obs_gap"))
# the years' mean equals the normal for months; a season or year weights its months by length the same way
if (obs_gap > 1e-9) stop(sprintf("HYDAT's years do not average to the gauge table's normals: %.3g", obs_gap))
order_f1 <- c("August", "September", setdiff(names(dfo_scales), c("August", "September")))
row_of <- function(sc) f1_rows[[match(sc, names(dfo_scales))]]
f1_line <- function(r, d) {
  sprintf(paste("%-10s  %4.2f %4.2f %4.2f | %4.2f %4.2f %4.2f | %4.2f %4.2f %4.2f ",
                "||  %4.2f %4.2f | %4.2f %5.2f | %4.2f %4.2f"),
          r$scale, d$r2_mean, r$rt_mean[["r2"]], r$wb_mean[["r2"]], d$mape_mean, r$rt_mean[["mape"]],
          r$wb_mean[["mape"]], d$nse_mean, r$rt_mean[["nse"]], r$wb_mean[["nse"]], d$r2_min, r$rt_min[["r2"]],
          d$mape_min, r$rt_min[["mape"]], d$nse_min, r$rt_min[["nse"]])
}
free_line <- function(r) {
  sprintf("%-10s  %4.2f %4.2f | %4.2f %4.2f | %6.1f %6.1f  ||  %4.2f | %4.2f | %6.1f", r$scale, r$rt_mean[["r2_log"]],
          r$wb_mean[["r2_log"]], r$rt_mean[["mdape"]], r$wb_mean[["mdape"]], r$rt_mean[["mae"]], r$wb_mean[["mae"]],
          r$rt_min[["r2_log"]], r$rt_min[["mdape"]], r$rt_min[["mae"]])
}
dry <- vapply(f1_rows, function(r) r$rt_min[["dry"]], 0)
n_years_fr <- cal$n_years[match(fr$station_number, cal$station_number)]
say(sprintf("## #162: DFO's Fraser validation as context, at the %d shared Fraser gauges (08J, 08K, 08L, 08M)",
            nrow(fr)),
    "Iacarella et al. 2025, DFO CSAS Res. Doc. 2025/013, App. F, Table F1: 86 Fraser gauges, not listed, scored",
    "across gauges on flow in m3/s: R2 (squared Pearson correlation), MAPE (mean absolute error over observed, a",
    "fraction) and NSE. Not like for like, so DFO's values are context, not a race:",
    "- their gauges are not ours, and likely include regulated main stems whose six dam corrections were fitted to",
    "  the gauges scored; ours are natural-flow calibration gauges, with 10 to 30 complete years (median",
    sprintf("  %.0f) where theirs span 1981-2010; %d of ours are under 100 km2 and %d over 10,000 km2;",
            stats::median(n_years_fr), sum(fr$area_class == "<100 km2"), sum(fr$area_class == ">10000")),
    "- their modelled Min sums each VIC-GL cell's own lowest month over the period, each from its own year (p. 30),",
    "  which sits at or below the lowest year of the summed flow; ours is the lowest year of the routed flow at",
    "  the segment, against the gauge's lowest year over the same years;",
    "- statistics across gauges in m3/s are carried by the range of basin sizes: an R2 near 1 says the sizes are",
    "  right, not each gauge's flow. The second table gives two the sizes do not carry.",
    "Mean: each gauge's mean flow over its complete years in 1981-2010. Min: the lowest of those years' flows.",
    "Seasons are calendar months of one year (winter: January, February and that year's December).",
    sprintf("routed year by year: fwapg#42's per-year sub-basin days, %d-%d, %d files each equal to its",
            min(years_dfo), max(years_dfo), length(yr$files)),
    "  pcic.series row",
    sprintf("  (rows built by fwapg %s, on the crosswalk of the run above; catalogue md5 %s),",
            yr$commit, yr$catalogue_md5),
    sprintf("  routed onto the segments by wet_routed_years(); the files' bins average to pcic.subbasin_daily at %d",
            yr$parity$subbasins),
    sprintf("  sub-basins (%d bins) within float32 precision: 2^-23 of the mean absolute value, plus 1e-9 m3/s",
            yr$parity$bins),
    sprintf("  (worst %.2f of the bound, largest %.2g m3/s)", yr$parity$worst, yr$parity$max_abs),
    sprintf("parity: the 30 years' days average to the published months within %.2g relative (largest %.2g m3/s;",
            par_rel, par_abs),
    sprintf("  registered bound %.0e relative); HYDAT's years average to the gauge table's normals within %.2g",
            par_tol, obs_gap),
    "  relative (bound 1e-9, set after the first runs; see the header's amendments)",
    "The balance is a 1981-2010 normal with no years, so it has no Min.",
    sprintf("gauges whose lowest year is dry (zero flow), left out of MAPE and median APE for Min: %s",
            paste(sprintf("%s %d", names(dfo_scales)[dry > 0], dry[dry > 0]), collapse = ", ")),
    "",
    "DFO's statistics: DFO, routed (rt), balance (wb)",
    sprintf("%-10s  %-14s | %-14s | %-14s  ||  %-9s | %-10s | %-9s", "", "R2 mean", "MAPE mean", "NSE mean",
            "R2 min", "MAPE min", "NSE min"),
    sprintf("%-10s  %-14s | %-14s | %-14s  ||  %-9s | %-10s | %-9s", "", "DFO  rt   wb", "DFO  rt   wb",
            "DFO  rt   wb", "DFO  rt", "DFO  rt", "DFO  rt"),
    vapply(order_f1, function(sc) f1_line(row_of(sc), dfo[dfo$scale == sc, ]), ""),
    "",
    "Statistics the basin sizes do not carry: R2 on log flow, the median gauge's absolute percent error (a",
    "fraction), and MAE (m3/s), routed then balance; Min for routed alone",
    sprintf("%-10s  %-9s | %-9s | %-13s  ||  %-4s | %-4s | %-6s", "", "R2 log", "med APE", "MAE mean", "R2lg",
            "mAPE", "MAE"),
    sprintf("%-10s  %-9s | %-9s | %-13s  ||  %-15s", "", "rt   wb", "rt   wb", "rt     wb", "min, routed"),
    vapply(order_f1, function(sc) free_line(row_of(sc)), ""),
    "",
    "Per gauge, the lowest year's routed flow over observed (gauges with flow in their lowest year):",
    vapply(c("August", "September", "Annual"), function(sc) {
      r <- row_of(sc)$min_ratio
      sprintf(paste("  %-10s median %+6.1f %%, within +-%d %% at %3.0f %%, over observed by more than half",
                    "at %3.0f %% (n %d)"),
              sc, med_err(r), err_cut, within(r), 100 * mean(r > 1.5), length(r))
    }, ""),
    "")

# ---- per gauge ------------------------------------------------------------------------------------
pct <- function(r) ifelse(is.na(r), "-", sprintf("%+.1f", 100 * (r - 1)))
num <- function(x) ifelse(is.na(x), "-", sprintf("%.2f", x))
o <- order(!g$shared, g$basin, g$station_number)
rt_ok <- g$shared
say("## Per gauge: monthly NSE and share NSE, Mar-Apr and Jul-Aug error (%), routed then balance",
    "(shared gauges first; routed's columns '-' where the gauge is not shared; agree: the outlet on the segment",
    "has matching networks (y), not (n), or there is none (-); local: check 2's local share; peak: observed)",
    sprintf("%-9s %-8s %-4s %8s %5s %5s %5s %5s %7s %7s %7s %7s %5s %5s %4s  %s", "station", "basin", "zone", "km2",
            "rtNSE", "rtSh", "wbNSE", "wbSh", "rt_MA", "rt_JA", "wb_MA", "wb_JA", "agree", "local", "peak", "name"),
    sprintf("%-9s %-8s %-4s %8.0f %5s %5s %5.2f %5.2f %7s %7s %7s %7s %5s %5s %4s  %s", g$station_number[o], g$basin[o],
            g$zone[o], g$area_km2[o], num(ifelse(rt_ok, g$nse_rt, NA))[o], num(ifelse(rt_ok, g$nse_rt_share, NA))[o],
            g$nse_wb[o], g$nse_wb_share[o], pct(ifelse(rt_ok, ratio_s(rt_w, i_all, 3:4), NA))[o],
            pct(ifelse(rt_ok, ratio_s(rt_w, i_all, 7:8), NA))[o], pct(ratio_s(wb_w, i_all, 3:4))[o],
            pct(ratio_s(wb_w, i_all, 7:8))[o], ifelse(is.na(g$agree), "-", ifelse(g$agree, "y", "n"))[o],
            num(ifelse(rt_ok, g$frac_local, NA))[o], month_lab[g$peak[o]], substr(g$station_name[o], 1, 34)))

f_report <- wb_report("gauge_monthly_compare", release)
writeLines(out, f_report)
stamp("done; report ", f_report)
