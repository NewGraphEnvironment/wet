# PCIC's routed flow against the open water balance at the shipped fit's
# calibration gauges (#58).
#
#   WET_FWAPG_COMMIT=<sha> Rscript scripts/pcic_routed_compare.R
#
# Routed flow is NewGraphEnvironment/fwapg#6's monthly table
# (scripts/pcic_routed_lib.R): each gauge's mean annual flow is the mean of
# the 12 monthly means on the segment the gauge snapped to, in mm over wet's
# accumulated upstream area, against observed runoff over the same area. The
# balance is scored held out (blocked CV), as it ships. PCIC is a reference
# here, scored against HYDAT beside our own estimate (CLAUDE.md, "Own
# estimates first").
#
# Report: data/checks/pcic_routed_compare_<release>.txt (tracked, wb_report()).
# It names the fwapg commit that built the table and the table's fingerprint;
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
g <- merge(ho$stations, cal[c("station_number", "station_name", "linear_feature_id", "upstream_area_m2",
                              "nesting", "zone", "area_km2")], by = "station_number")
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
DBI::dbDisconnect(conn)
g$routed_m3s <- ra$q_m3s[match(g$linear_feature_id, ra$linear_feature_id)]
g$routed_mm <- routed_mm(g$routed_m3s, g$upstream_area_m2)
g$routed_err <- 100 * (g$routed_mm / g$obs - 1)
g$basin <- routed_basin(g$station_number)
cov <- g[!is.na(g$routed_mm), ]
unc <- g[is.na(g$routed_mm), ]
stopifnot(nrow(cov) > 0, all(cov$routed_mm >= 0))

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
  sprintf("routed: %s, built by NewGraphEnvironment/fwapg at %s", routed_table, fwapg_commit),
  sprintf("table: %s", fmt_fingerprint(fp)),
  "routed per gauge: the mean of the 12 monthly means (1951-2012, unweighted by month length) on the segment",
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
  sprintf("## The %d gauges without routed flow, by sub-drainage", nrow(unc)),
  vapply(names(unc_by), function(p) sprintf("%s %2d  %s", p, length(unc_by[[p]]), paste(unc_by[[p]], collapse = " ")),
         ""),
  sprintf("balance at these, held out: mean absolute error %.1f %%", mean(abs(unc$err_pct))),
  "",
  "## Not like for like",
  "- PCIC calibrated its model at gauges it does not publish, so routed errors may be partly in sample;",
  "  the balance's are out of sample.",
  "- Routed flow is 1951-2012; the balance is 1981-2010 normals; observed is each gauge's record.",
  "",
  "## Per gauge (mm/yr; errors %)",
  "station   basin     nesting        km2    obs  routed balance  r_err  b_err  name",
  {
    o <- g[order(g$basin, g$station_number), ]
    sprintf("%-9s %-9s %-9s %9.0f %6.0f %7s %7.0f %6s %+6.1f  %s", o$station_number, o$basin, o$nesting, o$area_km2,
            o$obs, ifelse(is.na(o$routed_mm), "-", sprintf("%.0f", o$routed_mm)), o$mod,
            ifelse(is.na(o$routed_err), "-", sprintf("%+.1f", o$routed_err)), o$err_pct, substr(o$station_name, 1, 34))
  }
)
f_report <- wb_report("pcic_routed_compare", release)
writeLines(lines, f_report)
stamp("done; report ", f_report)
