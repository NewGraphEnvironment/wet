# WALLY's flow model beside the open balance at the calibration gauges (#178, items 1 and 2).
#
# WALLY (bcgov/WALLY, Apache-2.0) is the province's Water Allocation tool. Its `modelling/`
# folder holds the per-station training tables and the code of its per-hydrologic-zone
# regressions of mean annual flow (and low flow) on catchment traits, and a report,
# `WALLY_Modeling_FSL_V0.5.pdf`, with the held-out scores. WALLY is a yardstick here, never an
# input (CLAUDE.md, "Own estimates first"): nothing it holds reaches a published value.
#
# Usage, from the repository root (with data/wb pointing at the shipped fit):
#   Rscript scripts/wally_compare.R
#
# Reads:
#   - bcgov/WALLY `modelling/` at the commit `wally_sha` below, fetched once into
#     data/wally/raw/<sha>/ (gitignored); each fetch is logged to data/logs/188/wally_fetch.tsv
#     and each file's md5 printed in the report
#   - scripts/wally_zone_scores.csv: the PDF's held-out scores by zone, one row per number, each
#     with its page, transcribed by hand from the PDF and read a second time
#   - the shipped fit's held-out annual balance (`cv_aet-cfu.rds`) and calibration gauges
#     (scripts/wb_cv_lib.R), and the tracked routed report's gauges for routed PCIC
# Writes data/checks/wally_compare_<release>.txt. Two runs give byte-identical reports.
#
# The hosted WALLY tool is not used: it needs a sign-in, and nothing here depends on it.

suppressPackageStartupMessages({
  library(dplyr)
})
source("scripts/wb_fit_lib.R")

release <- wb_release()
wally_sha <- "9de322b562883a3a590a2e55a0a3f7d7312116f0"
wally_raw <- function(path) {
  paste("https://raw.githubusercontent.com/bcgov/WALLY", wally_sha, "modelling", path, sep = "/")
}
raw_dir <- file.path("data", "wally", "raw", wally_sha)
log_dir <- file.path("data", "logs", "188")
f_fetch <- file.path(log_dir, "wally_fetch.tsv")

# Every file read, relative to `modelling/`.
wally_files <- c(
  "README.md",
  "WALLY_Modeling_FSL_V0.5.pdf",
  "data/4_training/sept13_2021/all_data.csv",
  "scripts/build_latest_training_data_sept13_2021.py",
  "models/input_variation_hydro_zone_model.py"
)

# ---- fetch once ---------------------------------------------------------------------------------
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
for (p in wally_files) {
  dest <- file.path(raw_dir, p)
  if (file.exists(dest)) next
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(dest, ".part")
  t0 <- Sys.time()
  r <- curl::curl_fetch_disk(wally_raw(p), tmp, handle = curl::new_handle(useragent = "wet (R)"))
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  row <- data.frame(utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), sha = wally_sha, path = p,
                    code = r$status_code, bytes = file.size(tmp), secs = round(secs, 2))
  utils::write.table(row, f_fetch, sep = "\t", quote = FALSE, row.names = FALSE,
                     col.names = !file.exists(f_fetch), append = file.exists(f_fetch))
  if (r$status_code != 200L) {
    unlink(tmp)
    stop("fetching ", p, " returned HTTP ", r$status_code)
  }
  if (!file.rename(tmp, dest)) stop("could not move ", tmp, " to ", dest)
}
md5 <- unname(tools::md5sum(file.path(raw_dir, wally_files)))

names(md5) <- wally_files

# ---- inputs -------------------------------------------------------------------------------------
# Table 1 of the PDF (p. 62), transcribed: digits from the PDF's text layer, which predictor each
# coefficient belongs to from the page image (the text layer misplaces columns in rows 6, 18, 19).
# Both reads are held to the table's own Count and Average rows below.
tz <- utils::read.csv("scripts/wally_zone_scores.csv", colClasses = c(zone = "character"))
cols_pred <- c(precip = "precipitation", slope = "average slope", da = "drainage area", glc = "glacier cover",
               med_elev = "median elevation", pet = "potential ET", solexp = "solar exposure")
zt <- tz[tz$zone != "xgboost", ]
xg <- tz[tz$zone == "xgboost", ]
count_row <- c(precip = 16, slope = 15, da = 2, glc = 14, med_elev = 12, pet = 13, solexp = 8)  # p. 62, "Count"
stopifnot(nrow(zt) == 27, nrow(xg) == 1,
          identical(colSums(zt[names(cols_pred)]), count_row[names(cols_pred)] + 0),
          all(rowSums(zt[names(cols_pred)]) == zt$num_vars),
          round(mean(zt$r2)) == 88, round(mean(zt$adj_r2)) == 87, round(mean(zt$min_r2)) == 82,  # "Average"
          round(mean(zt$avg), 1) == 29.7)

# WALLY's training table: 534 stations, those whose WALLY drainage area is within 20 % of HYDAT's
# gross area and with more than 10 years (the build script); the model then keeps gross licensed
# allocation at most 200 % of mean annual discharge, or net allocation zero (the model script's
# filter_data(), ALLOCATED_THRESHOLD = 2), 482 stations (PDF p. 36, Figure 14).
wt <- utils::read.csv(file.path(raw_dir, "data/4_training/sept13_2021/all_data.csv"),
                      colClasses = c(station_number = "character"))
wt$kept <- wt$percent_allocated_mad <= 2 | wt$percent_allocated_mad_abs == 0
wt$kept[is.na(wt$kept)] <- FALSE
wt$zone <- ifelse(is.na(wt$hydrological_zone), NA_character_,
                  sprintf("%02d", as.integer(round(wt$hydrological_zone))))
wt$zone_w <- ifelse(wt$zone %in% c("07", "11", "12"), "7_11_12", as.character(as.integer(wt$zone)))
stopifnot(nrow(wt) == 534, !anyDuplicated(wt$station_number), sum(wt$kept) == 482)

# The open balance, held out as it ships (`cv_ann`), and routed PCIC as published, from the
# segment-discharge article's gauge table (scripts/gauge_monthly_compare.R holds it to the live
# build): month 0 is the annual mean. The two must agree on every gauge's observed and balance value.
fit_dir <- wb_fit_dir(wb_key_dir(), release)
cv <- readRDS(file.path(fit_dir, "cv_aet-cfu.rds"))
g <- readRDS("inst/vignette-data/monthly_values.rds")$gauges
g <- g[g$month == 0, ]
i <- match(cv$station_number, g$station_number)
stopifnot(identical(cv$release, release), !anyNA(i), isTRUE(all.equal(g$obs_mm[i], cv$obs)),
          isTRUE(all.equal(g$wb_mm[i], cv$cv_ann)), identical(g$zone[i], cv$zone))
ours <- data.frame(station_number = cv$station_number, zone = cv$zone, area_km2 = g$area_km2[i],
                   obs = cv$obs, bal = cv$cv_ann, routed = g$routed_mm[i])
# routed is scored where the gauge's segment carries at least a fifth of observed annual flow, the
# shared set of scripts/gauge_monthly_compare.R
ours$shared <- !is.na(ours$routed) & ours$routed >= 0.2 * ours$obs
stopifnot(sum(ours$shared) == 283)
ours$zone_w <- ifelse(ours$zone %in% c("07", "11", "12"), "7_11_12", as.character(as.integer(ours$zone)))
mm_to_lsk <- 1 / 31.5576  # mm a year (365.25-day years, as `obs`) to litres per second per km2
s <- readRDS(wb_stations_path(release))

# HYDAT's regulation flag for WALLY's stations
con <- wet:::wet_hydat_connect(wb_hydat(release))
reg <- DBI::dbGetQuery(con, "SELECT STATION_NUMBER station_number, REGULATED regulated FROM STN_REGULATION")
DBI::dbDisconnect(con)
wt$regulated <- reg$regulated[match(wt$station_number, reg$station_number)]

# ---- report -------------------------------------------------------------------------------------
out <- character()
say <- function(...) out <<- c(out, ...)
pct <- function(x) sprintf("%.0f %%", 100 * x)
r2 <- function(m, o) if (length(o) >= 3) stats::cor(m, o)^2 else NA_real_
rmse <- function(m, o) sqrt(mean((m - o)^2))

say("# WALLY's mean annual runoff model beside the open balance and routed PCIC at the calibration gauges (#178)",
    "",
    sprintf("HYDAT release %s; fit %s; WALLY at bcgov/WALLY@%s (Apache-2.0).", release, basename(dirname(fit_dir)),
            wally_sha),
    "WALLY is a yardstick here, not an input. The hosted WALLY tool was not used.",
    "",
    "## Files read from WALLY's modelling/ folder (md5)",
    sprintf("%s  %s", md5, wally_files),
    "")

say("## 1. WALLY's predictors, from its own Table 1 (PDF p. 62), before any of our numbers",
    "",
    "Mean annual unit runoff (MAR, l/s/km2) is regressed on catchment traits, one ordinary least squares",
    "model per hydrologic zone (zones 7, 11 and 12 pooled), the trait set chosen as the one with the highest",
    "minimum R2 over 30 random 70/30 splits (MkMGR, PDF p. 23). The coefficients are unstandardized, so the",
    "table ranks no trait inside a zone; a trait in a zone's chosen model is counted as used there.",
    "",
    sprintf("%-9s %s", "zone",
            paste(sprintf("%-6s", c("precip", "slope", "DA", "glc", "elev", "PET", "solexp")), collapse = " ")))
for (k in seq_len(nrow(zt))) {
  marks <- ifelse(unlist(zt[k, names(cols_pred)]) == 1, "x", "")
  say(sprintf("%-9s %s", zt$zone[k], paste(sprintf("%-6s", marks), collapse = " ")))
}
used <- colSums(zt[names(cols_pred)])
say(sprintf("%-9s %s", "zones", paste(sprintf("%-6d", used), collapse = " ")),
    "",
    sprintf("Of %d zone models: %s.", nrow(zt),
            paste(sprintf("%s in %d", cols_pred[order(-used)], used[order(-used)]), collapse = ", ")),
    sprintf("Slope is in %d of the %d models and solar exposure in %d. The PDF (p. 35) names precipitation, slope,",
            used[["slope"]], nrow(zt), used[["solexp"]]),
    "glacier, PET and median elevation as the important ones and says drainage area and solar exposure do not",
    "make much impact. Its XGBoost model, one model over all zones with zone as a feature, ranks precipitation",
    "first by gain (1112, then PET 63.1 and glacier 57.3; p. 62).",
    "")

say("## 2. Gauge filters",
    "",
    "WALLY (training table and model script):",
    "- WALLY's own drainage area (delineated from a DEM, then the Freshwater Atlas) within 20 % of HYDAT's gross area;",
    "- more than 10 years of record, any years (mean annual discharge over the whole record);",
    "- gross licensed allocation at most 200 % of mean annual discharge, or net allocation zero;",
    "- no regulation filter: naturalization was not attempted (PDF p. 19).",
    "The open balance (scripts/wb_stations.R, wet_station_select(), scripts/wb_cv_lib.R):",
    "- HYDAT regulation flag 0 (natural); no licensed-use filter;",
    "- at least 10 complete years in 1981-2010 (all 12 months, each with enough days of flow);",
    "- the gauge snapped to the FWA, its accumulated area within 10 % of HYDAT's gross area;",
    "- at least 95 % of the basin inside BC and on the climate grid.",
    "",
    sprintf("WALLY: %d stations in its training table, %d after its allocation filter.", nrow(wt), sum(wt$kept)),
    sprintf("  Of those %d, HYDAT %s flags %d regulated, %d natural and %d with no regulation record.",
            sum(wt$kept), release, sum(wt$kept & wt$regulated %in% 1), sum(wt$kept & wt$regulated %in% 0),
            sum(wt$kept & is.na(wt$regulated))),
    sprintf("Ours: %d natural stations with 10 or more complete years, %d snapped within 10 %%, %d calibration gauges.",
            nrow(s$stations), sum(s$stations$accepted), nrow(ours)),
    "")

# ---- overlap ------------------------------------------------------------------------------------
in_w <- ours$station_number %in% wt$station_number[wt$kept]
in_w_all <- ours$station_number %in% wt$station_number
wk <- wt[wt$kept, ]
why <- rep("a calibration gauge", nrow(wk))
why[!wk$station_number %in% ours$station_number] <- "under 95 % in BC or on the grid"
why[!wk$station_number %in% s$stations$station_number[s$stations$accepted]] <- "FWA area outside 10 %"
why[!wk$station_number %in% s$stations$station_number] <- "fewer than 10 complete years in 1981-2010"
why[!wk$regulated %in% 0] <- "regulated or no regulation record in HYDAT"
# fixed levels, so the tables print in one order whatever the locale's collation
why <- factor(why, levels = c("a calibration gauge", "regulated or no regulation record in HYDAT",
                              "fewer than 10 complete years in 1981-2010", "FWA area outside 10 %",
                              "under 95 % in BC or on the grid"))
why_ours <- rep("not in WALLY's table", nrow(ours))
why_ours[in_w_all] <- "in WALLY's table, dropped by its allocation filter"
why_ours[in_w] <- "in WALLY's training set"
why_ours <- factor(why_ours, levels = c("in WALLY's training set", "in WALLY's table, dropped by its allocation filter",
                                        "not in WALLY's table"))
stopifnot(!anyNA(why), !anyNA(why_ours))
say("## 3. Station overlap",
    "",
    sprintf("%d of our %d calibration gauges are among WALLY's %d training stations: a WALLY score there is in-sample.",
            sum(in_w), nrow(ours), sum(wt$kept)),
    "Our gauges, by where they stand in WALLY's data:",
    sprintf("  %-52s %4d", names(table(why_ours)), as.integer(table(why_ours))),
    "WALLY's training stations, by where they stand in ours:",
    sprintf("  %-52s %4d", names(table(why)), as.integer(table(why))),
    "")
ov <- merge(ours[in_w, ], wk[c("station_number", "zone_w", "mar")], by = "station_number", suffixes = c("", "_wally"))
say(sprintf("At the %d shared gauges, WALLY's zone (from the station's location) equals ours (the zone covering most",
            nrow(ov)),
    sprintf("of the basin) at %d. WALLY's measured MAR (whole record, its own area) over ours (complete years in",
            sum(ov$zone_w == ov$zone_w_wally)),
    sprintf("1981-2010, the FWA area): median %.3f, middle half %.3f to %.3f.",
            stats::median(ov$mar / (ov$obs * mm_to_lsk)),
            stats::quantile(ov$mar / (ov$obs * mm_to_lsk), 0.25), stats::quantile(ov$mar / (ov$obs * mm_to_lsk), 0.75)),
    "")

# ---- by zone, in WALLY's metric -----------------------------------------------------------------
# WALLY's R2 is the squared correlation of predicted with measured MAR over all of a zone's stations,
# training and test together (PDF p. 23: in small zones a 2-3 station test set could not be scored);
# MIN R2 is the lowest over 30 random 70/30 splits; STEYX is the model's standard error in l/s/km2
# (residual sum of squares over n - k - 1). Ours: the squared correlation of the held-out balance
# (and of routed PCIC, at its shared gauges) with observed MAR, and the root mean square error in
# l/s/km2 (over n). A zone class with fewer than 5 of our gauges is printed, marked *, and not read.
zones <- zt$zone
by_zone <- do.call(rbind, lapply(zones, function(z) {
  o <- ours[ours$zone_w == z, ]
  r <- o[o$shared, ]
  data.frame(zone = z, w_n = zt$n[zt$zone == z], w_kept = sum(wk$zone_w %in% z), w_r2 = zt$r2[zt$zone == z],
             w_min = zt$min_r2[zt$zone == z], w_steyx = zt$steyx[zt$zone == z], w_avg = zt$avg[zt$zone == z],
             n = nrow(o), n_in = sum(o$station_number %in% wk$station_number),
             avg = mean(o$obs) * mm_to_lsk,
             b_r2 = r2(o$bal, o$obs), b_rmse = rmse(o$bal, o$obs) * mm_to_lsk,
             n_r = nrow(r), r_r2 = r2(r$routed, r$obs), r_rmse = rmse(r$routed, r$obs) * mm_to_lsk)
}))
stopifnot(sum(by_zone$n) == nrow(ours))  # every calibration gauge sits in one of WALLY's zone classes
f1 <- function(x) ifelse(is.na(x), "    -", sprintf("%5.1f", x))
f0 <- function(x) ifelse(is.na(x), "  -", sprintf("%3.0f", 100 * x))
say("## 4. By hydrologic zone, in WALLY's metric",
    "",
    "WALLY: its Table 1 (N, R2 on all data, MIN R2 over 30 test splits, STEYX); kept is how many of its 482",
    sprintf("training stations its table places in the zone, by the station's location (%d have no zone).",
            sum(is.na(wk$zone))),
    "Ours: held out (blocked CV), by the zone covering most of the basin; R2 and RMSE against observed MAR",
    "(l/s/km2, complete years in 1981-2010); in is how many of our gauges are WALLY training stations.",
    "Not like for like: WALLY's R2 includes its training stations and its MAR covers each station's whole",
    "record; the gauge sets differ.",
    "",
    sprintf("%-8s | %4s %4s %4s %4s %5s %5s | %3s %3s %5s | %4s %5s | %3s %4s %5s",
            "zone", "N", "kept", "R2", "min", "STEYX", "AVG", "n", "in", "AVG", "R2", "RMSE", "n", "R2", "RMSE"),
    sprintf("%-8s | %-33s | %-13s | %-10s | %s", "", "WALLY (Table 1)", "our gauges", "balance",
            "routed PCIC (shared)"))
for (k in seq_len(nrow(by_zone))) {
  b <- by_zone[k, ]
  say(sprintf("%-8s | %4d %4d %4d %4d %5.1f %5.1f | %3d %3d %s | %s %s | %3d %s %s",
              paste0(b$zone, ifelse(b$n < 5, "*", "")), b$w_n, b$w_kept, b$w_r2, b$w_min, b$w_steyx, b$w_avg,
              b$n, b$n_in, f1(b$avg), f0(b$b_r2), f1(b$b_rmse), b$n_r, f0(b$r_r2), f1(b$r_rmse)))
}
rd <- by_zone[by_zone$n >= 5, ]
rr <- rd[rd$n_r >= 5, ]
say("",
    sprintf(paste0("Readable zone classes (5 or more of our gauges): %d of %d. ",
                   "Median over them: WALLY R2 %.0f %% (MIN R2 %.0f %%),"),
            nrow(rd), nrow(by_zone), stats::median(rd$w_r2), stats::median(rd$w_min)),
    sprintf(paste0("the balance's held-out R2 %.0f %%; routed PCIC's %.0f %% over the %d classes ",
                   "with 5 or more shared gauges."),
            100 * stats::median(rd$b_r2), 100 * stats::median(rr$r_r2), nrow(rr)),
    sprintf("RMSE over STEYX, median: balance %.2f, routed PCIC %.2f (above 1, ours scatters more than WALLY's fit).",
            stats::median(rd$b_rmse / rd$w_steyx), stats::median(rr$r_rmse / rr$w_steyx)),
    sprintf("Zone classes where the balance's held-out R2 is at or above WALLY's all-data R2: %d of %d.",
            sum(100 * rd$b_r2 >= rd$w_r2), nrow(rd)),
    "")
say("## 5. Across the province",
    "",
    sprintf(paste0("WALLY: MkMGR's 27 zone models average R2 %d %% (MIN R2 %d %%); ",
                   "its XGBoost model, R2 %d %% and STEYX %.1f l/s/km2"),
            round(mean(zt$r2)), round(mean(zt$min_r2)), xg$r2, xg$steyx),
    sprintf("over %d stations, predicted against measured on all data (PDF p. 62, note C).", xg$n),
    sprintf("Ours, held out, all %d gauges: the balance R2 %s, RMSE %.1f l/s/km2; routed PCIC at its %d shared gauges",
            nrow(ours), pct(r2(ours$bal, ours$obs)), rmse(ours$bal, ours$obs) * mm_to_lsk, sum(ours$shared)),
    sprintf("R2 %s, RMSE %.1f l/s/km2. Observed MAR over our gauges: mean %.1f, standard deviation %.1f l/s/km2.",
            pct(r2(ours$routed[ours$shared], ours$obs[ours$shared])),
            rmse(ours$routed[ours$shared], ours$obs[ours$shared]) * mm_to_lsk,
            mean(ours$obs) * mm_to_lsk, stats::sd(ours$obs) * mm_to_lsk))

f_out <- wb_report("wally_compare", release)
writeLines(out, f_out)
message("wrote ", f_out)
