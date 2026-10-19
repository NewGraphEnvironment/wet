# PCIC's routed flow against the open water balance at the shipped fit's
# calibration gauges (#58).
#
#   WET_FWAPG_COMMIT=<sha> Rscript scripts/pcic_routed_compare.R
#
# Routed flow is fwapg's pcic.discharge_monthly, one run
# (scripts/pcic_routed_lib.R): each gauge's mean annual flow is the mean of
# the 12 monthly means on the segment the gauge snapped to, in mm over wet's
# accumulated upstream area, against observed runoff over the same area. The
# balance is scored held out (blocked CV), as it ships. PCIC is a reference
# here, scored against HYDAT beside our own estimate (CLAUDE.md, "Own
# estimates first").
#
# Report: data/checks/pcic_routed_compare_<release>.txt (tracked, wb_report()).
# It names the fwapg commit that built the run and the run's fingerprint;
# neither is recorded in the database. Connection from WET_PG*.

source("scripts/wb_cv_lib.R")  # load_all(), cal, release, fit_dir, score_code_md5
source("scripts/pcic_routed_lib.R")

# the report cites the commit it was built at, so that commit must hold the code
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the report:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
fwapg_commit <- routed_commit()
err_cut <- 20

ho <- shipped_heldout()
g <- merge(ho$stations, cal[c("station_number", "station_name", "linear_feature_id", "watershed_feature_id",
                              "upstream_area_m2", "nesting", "zone", "area_km2")], by = "station_number")
g$linear_feature_id <- as.integer(g$linear_feature_id)
stopifnot(nrow(g) == nrow(cal), !anyNA(g$linear_feature_id))
hydat_release <- sub("^HYDAT release: ", "", grep("^HYDAT release:", readLines(wb_report("stations_wb", release)),
                                                   value = TRUE))
stopifnot(length(hydat_release) == 1)

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
fp <- routed_fingerprint(conn)
ra <- routed_annual(conn, g$linear_feature_id)
edge <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.linear_feature_id::int AS linear_feature_id, s.edge_type, coalesce(%s, false) AS own_line
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  LEFT JOIN whse_basemapping.fwa_watersheds_poly w ON w.watershed_feature_id = l.watershed_feature_id
  WHERE s.linear_feature_id IN (%s)", routed_own_line_sql, paste(g$linear_feature_id, collapse = ", ")))
# fwapg's older annual table (extras/discharge: gridded VIC-GL runoff and
# baseflow accumulated on the FWA, no routing), which wet's vignette scored
# before #58: one mean annual runoff per watershed, so read at the gauge's
annual <- DBI::dbGetQuery(conn, sprintf("
  SELECT DISTINCT l.watershed_feature_id::int AS watershed_feature_id, d.mad_mm
  FROM whse_basemapping.fwa_streams_watersheds_lut l
  JOIN whse_basemapping.fwa_stream_networks_discharge d USING (linear_feature_id)
  WHERE l.watershed_feature_id IN (%s) AND d.mad_mm IS NOT NULL", paste(g$watershed_feature_id, collapse = ", ")))
stopifnot(!anyDuplicated(annual$watershed_feature_id))
DBI::dbDisconnect(conn)
g$annual_mm <- annual$mad_mm[match(g$watershed_feature_id, annual$watershed_feature_id)]
g$routed_m3s <- ra$q_m3s[match(g$linear_feature_id, ra$linear_feature_id)]
g$routed_mm <- routed_mm(g$routed_m3s, g$upstream_area_m2)
g$routed_err <- 100 * (g$routed_mm / g$obs - 1)
g$basin <- routed_basin(g$station_number)
g$edge_type <- edge$edge_type[match(g$linear_feature_id, edge$linear_feature_id)]
g$own_line <- edge$own_line[match(g$linear_feature_id, edge$linear_feature_id)]
stopifnot(!anyNA(g$own_line))
# The default pick (#57, scripts/segment_output.R) at each gauge, made against
# the held-out balance so it uses no observed flow; mm over one area compare
# as the flows do. Its error is the picked source's. A gauge snapped off its
# watershed's own line (a side channel) keeps routed, as the segment does.
g$pick <- wet_source_pick(g$routed_mm, g$mod, routed_far_low, own_line = g$own_line)
stopifnot(!anyNA(g$pick))
g$pick_err <- ifelse(g$pick == "pcic_routed", g$routed_err, g$err_pct)
cov <- g[!is.na(g$routed_mm), ]
low <- cov[cov$routed_mm < routed_far_low * cov$obs, ]
low <- low[order(low$routed_err), ]
unc <- g[is.na(g$routed_mm), ]
stopifnot(nrow(cov) > 0, all(cov$routed_mm >= 0))
flip <- cov[cov$pick == "wet_balance", ]
flip <- flip[order(flip$routed_err), ]

# ---- report -------------------------------------------------------------------------------
score_line <- function(lab, i) {
  r <- routed_scores(cov$routed_err[i], err_cut)
  w <- routed_scores(cov$err_pct[i], err_cut)
  sprintf("%-22s %4d   %5.1f %5.1f   %5.1f %5.1f   %4.0f %4.0f   %+6.1f %+6.1f   %4.0f",
          lab, r[["n"]], r[["mae"]], w[["mae"]], r[["median_ae"]], w[["median_ae"]], r[["within"]], w[["within"]],
          r[["bias"]], w[["bias"]], 100 * mean(abs(cov$routed_err[i]) < abs(cov$err_pct[i])))
}
basins <- intersect(c("Peace", "Fraser", "Columbia", "Coast", "Yukon", "Arctic"), cov$basin)
unc_by <- split(unc$station_number, substr(unc$station_number, 1, 3))
lines <- c(
  "# PCIC routed flow against the open water balance at the calibration gauges (#58)",
  "",
  sprintf("wet commit %s; fit %s (HYDAT %s), province run %s, scoring code %s; balance %s, held out (blocked CV)",
          wet_commit, release, hydat_release, basename(key_dir), score_code_md5,
          if (ho$fits$keep_adjust) "adjusted" else "raw P - AET"),
  routed_report_line(fwapg_commit),
  sprintf("table: %s", fp),
  sprintf("routed per gauge: the mean of the 12 monthly means (%s, unweighted by month length) on the segment",
          routed_run$period),
  "the gauge snapped to, in mm over wet's accumulated upstream area; observed runoff over the same area",
  "",
  sprintf("calibration gauges: %d; with routed flow on their segment: %d; without: %d",
          nrow(g), nrow(cov), nrow(unc)),
  "",
  sprintf("## At the %d gauges both score: error as %% of observed, routed then balance", nrow(cov)),
  sprintf("%-22s %4s   %11s   %11s   %9s   %13s   %4s", "", "n", "mean abs", "median abs",
          sprintf("+-%d %%", err_cut), "bias", "routed closer %"),
  score_line("all", TRUE),
  score_line("headwater", cov$nesting == "headwater"),
  score_line("nested", cov$nesting == "nested"),
  score_line("< 100 km2", cov$area_km2 < 100),
  score_line("100-1,000 km2", cov$area_km2 >= 100 & cov$area_km2 < 1000),
  score_line("1,000-10,000 km2", cov$area_km2 >= 1000 & cov$area_km2 < 10000),
  score_line(">= 10,000 km2", cov$area_km2 >= 10000),
  vapply(basins, function(b) score_line(b, cov$basin == b), ""),
  "",
  "## The default pick (#57): routed unless it carries under the cut of the balance, then the balance",
  sprintf("cut %.2f, against the held-out balance; segments off their own line keep routed; error as %%",
          routed_far_low),
  "of observed",
  sprintf("%-28s %4s %6s %6s %5s %7s", "", "n", "mean", "median", sprintf("+-%d", err_cut), "bias"),
  {
    line <- function(lab, e) {
      r <- routed_scores(e, err_cut)
      sprintf("%-28s %4d %6.1f %6.1f %5.0f %+7.1f", lab, r[["n"]], r[["mae"]], r[["median_ae"]], r[["within"]],
              r[["bias"]])
    }
    c(line(sprintf("pick, the %d with routed", nrow(cov)), cov$pick_err),
      line(sprintf("routed, the %d", nrow(cov)), cov$routed_err),
      line(sprintf("balance, the %d", nrow(cov)), cov$err_pct),
      line(sprintf("pick, every gauge (%d)", nrow(g)), g$pick_err),
      line(sprintf("balance, every gauge (%d)", nrow(g)), g$err_pct))
  },
  sprintf("gauges where the pick is the balance although routed has a value: %d; the balance closer at %d",
          nrow(flip), sum(abs(flip$err_pct) < abs(flip$routed_err))),
  "station    basin       obs  routed balance  r_err  b_err  name",
  if (nrow(flip)) sprintf("%-10s %-8s %6.0f %7.0f %7.0f %+6.1f %+6.1f  %s", flip$station_number, flip$basin, flip$obs,
                          flip$routed_mm, flip$mod, flip$routed_err, flip$err_pct,
                          substr(flip$station_name, 1, 34)) else "  none",
  "",
  sprintf("## The %d gauges whose segment carries less than %.0f %% of observed flow", nrow(low), 100 * routed_far_low),
  "Attributed by fwapg's older annual table, which has no routing and no placement: where it is far low too,",
  "the shortfall is PCIC's runoff; where it is not, it is placement or the gauge's snap (a side channel carries",
  "only its own water, a reservoir lake its regulated outflow); with no annual value, it is unresolved.",
  "station   edge_type      km2    obs  routed  annual  r_err  attribution            name",
  if (nrow(low)) sprintf("%-9s %9d %8.0f %6.0f %7.0f %7s %+6.1f  %-22s %s", low$station_number, low$edge_type,
                         low$area_km2, low$obs, low$routed_mm,
                         ifelse(is.na(low$annual_mm), "-", sprintf("%.0f", low$annual_mm)), low$routed_err,
                         ifelse(is.na(low$annual_mm), "unresolved",
                                ifelse(low$annual_mm < routed_far_low * low$obs, "PCIC runoff", "placement or snap")),
                         substr(low$station_name, 1, 34)) else "  none",
  {
    k <- !cov$station_number %in% low$station_number
    r <- routed_scores(cov$routed_err[k], err_cut)
    w <- routed_scores(cov$err_pct[k], err_cut)
    sprintf("without them (%d gauges): mean absolute error %.1f %% routed, %.1f %% balance; bias %+.1f %% and %+.1f %%",
            sum(k), r[["mae"]], w[["mae"]], r[["bias"]], w[["bias"]])
  },
  "",
  {
    b <- g[!is.na(g$routed_mm) & !is.na(g$annual_mm), ]
    e_a <- 100 * (b$annual_mm / b$obs - 1)
    e_r <- 100 * (b$routed_mm / b$obs - 1)
    line <- function(lab, e) {
      r <- routed_scores(e, err_cut)
      sprintf("%-28s %5.1f %5.1f %4.0f %+6.1f   %5.1f / %5.1f", lab, r[["mae"]], r[["median_ae"]], r[["within"]],
              r[["bias"]], mean(abs(e[b$nesting == "headwater"])), mean(abs(e[b$nesting == "nested"])))
    }
    rat <- b$routed_mm / b$annual_mm
    c(sprintf("## Against fwapg's older annual table, at the %d gauges both PCIC products score", nrow(b)),
      "The annual table (whse_basemapping.fwa_stream_networks_discharge, extras/discharge) accumulates gridded",
      "VIC-GL runoff and baseflow on the FWA without routing, centroid-sampled over fwapg's stored upstream area.",
      sprintf("%-28s %5s %5s %4s %6s   %s", "", "mean", "med", sprintf("+-%d", err_cut), "bias",
              sprintf("headwater (%d) / nested (%d) mean", sum(b$nesting == "headwater"), sum(b$nesting == "nested"))),
      line("annual table", e_a), line("routed", e_r), line("balance (held out)", b$err_pct),
      sprintf("routed / annual: median %.3f, p10-p90 %.2f-%.2f; routed closer than the annual table at %.0f %%",
              stats::median(rat), stats::quantile(rat, 0.1), stats::quantile(rat, 0.9), 100 * mean(abs(e_r) < abs(e_a))),
      {
        k <- !b$station_number %in% low$station_number
        sprintf("without the gauges listed above as carrying < %.0f %% (%d left): annual %.1f %%, routed %.1f %%, balance %.1f %%",
                100 * routed_far_low, sum(k), mean(abs(e_a[k])), mean(abs(e_r[k])), mean(abs(b$err_pct[k])))
      },
      sprintf("gauges routed scores that the annual table does not: %d (balance %.1f %%, routed %.1f %% there)",
              sum(!is.na(g$routed_mm) & is.na(g$annual_mm)),
              mean(abs(g$err_pct[!is.na(g$routed_mm) & is.na(g$annual_mm)])),
              mean(abs(g$routed_err[!is.na(g$routed_mm) & is.na(g$annual_mm)]))),
      "")
  },
  sprintf("## The %d gauges without routed flow, by sub-drainage", nrow(unc)),
  vapply(names(unc_by), function(p) sprintf("%s %2d  %s", p, length(unc_by[[p]]), paste(unc_by[[p]], collapse = " ")),
         ""),
  sprintf("balance at these, held out: mean absolute error %.1f %%", mean(abs(unc$err_pct))),
  "",
  "## Not like for like",
  "- PCIC calibrated its model at gauges it does not publish, so routed errors may be partly in sample;",
  "  the balance's are out of sample.",
  sprintf("- Routed flow is %s; the balance is 1981-2010 normals; observed is each gauge's complete years",
          routed_run$period),
  "  within 1981-2010 (at least 10; scripts/wb_stations.R).",
  "",
  "## Per gauge (mm/yr; errors %)",
  "station   basin     nesting        km2    obs  routed  annual balance  r_err  b_err  pick  name",
  {
    o <- g[order(g$basin, g$station_number), ]
    sprintf("%-9s %-9s %-9s %9.0f %6.0f %7s %7s %7.0f %6s %+6.1f  %-4s  %s", o$station_number, o$basin, o$nesting,
            o$area_km2, o$obs, ifelse(is.na(o$routed_mm), "-", sprintf("%.0f", o$routed_mm)),
            ifelse(is.na(o$annual_mm), "-", sprintf("%.0f", o$annual_mm)), o$mod,
            ifelse(is.na(o$routed_err), "-", sprintf("%+.1f", o$routed_err)), o$err_pct,
            ifelse(o$pick == "pcic_routed", "rt", "bal"), substr(o$station_name, 1, 34))
  }
)
f_report <- wb_report("pcic_routed_compare", release)
writeLines(lines, f_report)
stamp("done; report ", f_report)
