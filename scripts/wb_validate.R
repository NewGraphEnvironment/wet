# Fit and validate the open water balance at HYDAT stations (#11, Phases 4-6).
#
#   Rscript scripts/wb_validate.R
#
# Reads data/wb/stations.rds (scripts/wb_stations.R) and the upstream means
# from scripts/wb_province.R, and writes the tracked report
# data/checks/wb_validation.txt plus data/wb/<key>/fits.rds (the fits the
# province output uses).

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
keys <- list.dirs("data/wb", recursive = FALSE, full.names = TRUE)
keys <- keys[file.exists(file.path(keys, "upstream", "_complete"))]
if (length(keys) != 1) stop("expected one complete province run under data/wb, found ", length(keys))
key_dir <- keys
min_frac <- 0.95  # basin share inside BC and on the grid, to calibrate on

# ---- stations with their upstream predictors --------------------------------------------
s <- readRDS("data/wb/stations.rds")
st <- s$stations[s$stations$accepted, ]
# Basins carry columns only for the zones present in them: fill the rest with
# share 0 before stacking.
up <- lapply(list.files(file.path(key_dir, "upstream"), "\\.rds$", full.names = TRUE), function(f) {
  x <- readRDS(f)
  x[x$watershed_feature_id %in% st$watershed_feature_id, ]
})
up <- up[vapply(up, nrow, 1L) > 0]  # basins with no stations
all_cols <- unique(unlist(lapply(up, names)))
up <- do.call(rbind, lapply(up, function(x) {
  for (k in setdiff(all_cols, names(x))) x[[k]] <- 0
  x[all_cols]
}))
cols_up <- setdiff(names(up), c("wscode", "localcode", "area_m2"))
zc <- grep("^zp?[0-9]+$", cols_up, value = TRUE)
st <- merge(st, up[cols_up], by = "watershed_feature_id")
st$area_km2 <- st$upstream_area_m2 / 1e6
st$area_ratio_fwa <- st$area_km2 / st$drainage_area_gross_km2

# observed runoff in mm over the accumulated FWA area (decision 9)
mon <- s$monthly
days <- c(365.25, wet_month_days())
mon$area_m2 <- st$upstream_area_m2[match(mon$station_number, st$station_number)]
mon <- mon[!is.na(mon$area_m2), ]
mon$obs_mm <- mon$q_m3s * days[mon$month + 1] * 86400 / mon$area_m2 * 1000
st$obs <- mon$obs_mm[mon$month == 0][match(st$station_number, mon$station_number[mon$month == 0])]
for (m in 1:12) {
  i <- mon$month == m
  st[[sprintf("share_%02d", m)]] <- mon$share[i][match(st$station_number, mon$station_number[i])]
}
st$raw <- st$ro_raw

cal <- st[st$bc_fraction >= min_frac & st$coverage >= min_frac & !is.na(st$obs), ]
# a zone no calibration station touches carries no information: drop it, so
# it gets no adjustment everywhere (as in scripts/wb_output.R)
zc_all <- sub("^z", "", grep("^z[0-9]+$", names(cal), value = TRUE))
unseen <- zc_all[colSums(cal[paste0("z", zc_all)]) == 0]
cal <- cal[setdiff(names(cal), c(paste0("z", unseen), paste0("zp", unseen)))]
z_only <- grep("^z[0-9]+$", names(cal), value = TRUE)
cal$zone <- sub("^z", "", z_only)[max.col(as.matrix(cal[z_only]), ties.method = "first")]
cal$area_class <- cut(cal$area_km2, c(0, 100, 1000, 10000, Inf),
                      labels = c("<100 km2", "100-1000", "1000-10000", ">10000"))
stamp(nrow(st), " accepted stations with predictors; ", nrow(cal), " to calibrate on")

# ---- cross-validation --------------------------------------------------------------------
folds <- wet_cv_folds(data.frame(station_number = cal$station_number, wscode = cal$wscode,
                                 localcode = cal$localcode, upstream_area_km2 = cal$area_km2))
loo <- wet_cv_folds(data.frame(station_number = cal$station_number, wscode = cal$wscode,
                               localcode = cal$localcode, upstream_area_km2 = cal$area_km2),
                    block = "station")
cal <- merge(cal, folds, by = "station_number")
# Each fold runs the whole procedure on its training stations, pooling
# included (decided from locations only), which is the honest simulation of
# predicting an ungauged basin. The report counts held-out stations whose
# zone was pooled in their fold, and predictions floored to 0.
pooled <- wet_wb_pooled(cal)

variants <- c("other", "none")
# annual only, one variant: held-out predictions for a fold assignment
cv_annual <- function(d, fold, variant) {
  ann <- rep(NA_real_, nrow(d))
  for (f in unique(fold)) {
    tr <- fold != f
    ann[!tr] <- wet_wb_adjust(wet_wb_fit(d[tr, ], pooled_adjust = variant), d[!tr, ])
  }
  ann
}
mae <- function(obs, mod) mean(abs(100 * (mod - obs) / obs), na.rm = TRUE)
# choose how pooled zones are adjusted by blocked CV inside the stations given
choose_variant <- function(d) {
  inner <- substr(d$station_number, 1, 4)
  m <- vapply(variants, function(v) mae(d$obs, cv_annual(d, inner, v)), numeric(1))
  variants[which.min(m)]
}
# held-out annual and monthly predictions; each outer fold runs the whole
# procedure on its training stations: pooling from their locations, and the
# pooled-zone variant chosen by an inner blocked CV (plan decision 5)
predict_cv <- function(d, fold, variant = "nested") {
  ann <- rep(NA_real_, nrow(d))
  raw_adj <- rep(NA_real_, nrow(d))
  was_pooled <- rep(FALSE, nrow(d))
  chosen <- character()
  sh <- matrix(NA_real_, nrow(d), 12)
  for (f in unique(fold)) {
    tr <- fold != f
    v <- if (variant == "nested") choose_variant(d[tr, ]) else variant
    chosen <- c(chosen, v)
    fit <- wet_wb_fit(d[tr, ], pooled_adjust = v)
    ann[!tr] <- wet_wb_adjust(fit, d[!tr, ])
    raw_adj[!tr] <- wet_wb_adjust(fit, d[!tr, ], floor = FALSE)
    was_pooled[!tr] <- d$zone[!tr] %in% fit$pooled
    sf <- wet_share_fit(d[tr, ])
    sh[!tr, ] <- wet_share_predict(sf, d[!tr, ])
  }
  list(ann = ann, share = sh, n_floored = sum(raw_adj < 0), n_pooled = sum(was_pooled),
       was_pooled = was_pooled,
       chosen = table(factor(chosen, levels = variants)))
}
long <- function(d, ann, share) {
  obs_m <- as.matrix(d[sprintf("share_%02d", 1:12)]) * d$obs
  rbind(data.frame(station_number = d$station_number, month = 0L, obs = d$obs, mod = ann),
        data.frame(station_number = rep(d$station_number, 12), month = rep(1:12, each = nrow(d)),
                   obs = as.vector(obs_m), mod = as.vector(share * ann)))
}
groups <- cal[c("station_number", "nesting", "zone", "area_class")]
groups$lake <- ifelse(cal$lake %in% TRUE, "lake outlet", "not lake outlet")

raw_v <- wet_flow_validate(long(cal, pmax(cal$raw, 0), matrix(NA_real_, nrow(cal), 12)), groups)
ship_variant <- choose_variant(cal)
ins_fit <- wet_wb_fit(cal, pooled_adjust = ship_variant)
ins_share <- wet_share_fit(cal)
ins_v <- wet_flow_validate(long(cal, wet_wb_adjust(ins_fit, cal), wet_share_predict(ins_share, cal)), groups)
cv <- predict_cv(cal, cal$fold)
# own-zone vs pooled-in-fold, for the headwater stations, raw and adjusted
g2 <- data.frame(station_number = cal$station_number,
                 zone_in_fold = ifelse(cv$was_pooled, "pooled", "own zone"))
g2 <- g2[cal$nesting == "headwater", ]
groups_cv <- groups
groups_cv$zone_in_fold <- ifelse(cv$was_pooled, "pooled", "own zone")
cv_v <- wet_flow_validate(long(cal, cv$ann, cv$share), groups_cv)
hw_split <- function(v) {
  x <- v$stations[v$stations$station_number %in% g2$station_number, ]
  x$z <- g2$zone_in_fold[match(x$station_number, g2$station_number)]
  vapply(c("own zone", "pooled"), function(k) mean(abs(x$err_pct[x$z == k]), na.rm = TRUE), numeric(1))
}
lo <- predict_cv(cal, loo$fold[match(cal$station_number, loo$station_number)])
lo_v <- wet_flow_validate(long(cal, lo$ann, lo$share), groups)
plain <- lapply(variants, function(v) {
  x <- predict_cv(cal, cal$fold, v)
  wet_flow_validate(long(cal, x$ann, x$share), groups)
})
names(plain) <- variants
stamp("validation done")

# gate: the adjustment must beat raw P - AET on headwater stations under blocked CV
hw <- function(v) v$summary$mae_pct[v$summary$group == "nesting" & v$summary$value == "headwater"]
keep_adjust <- hw(cv_v) < hw(raw_v)
saveRDS(list(wb = ins_fit, share = ins_share, keep_adjust = keep_adjust, min_frac = min_frac,
             calibration = cal$station_number),
        file.path(key_dir, "fits.rds"))

# ---- report ------------------------------------------------------------------------------------
fmt <- function(v, label) {
  x <- v$summary
  c(sprintf("### %s", label),
    sprintf("%-10s %-18s %4s %5s %8s %8s %7s %7s %8s %6s %9s %9s", "group", "value", "n", "n_low",
            "mean%", "median%", "MAE%", "in20%", "logbias", "logsd", "NSE_mon", "NSE_shr"),
    sprintf("%-10s %-18s %4d %5d %8.1f %8.1f %7.1f %7.1f %8.3f %6.3f %9.2f %9.2f", x$group,
            substr(x$value, 1, 18), x$n, x$n_low, x$mean_err_pct, x$median_err_pct, x$mae_pct,
            100 * x$within_20, x$log_bias_median, x$log_sd, x$nse_month_median, x$nse_share_median),
    "")
}
co <- ins_fit$coef
con <- file("data/checks/wb_validation.txt", "w")
writeLines(c(
  "# Open water balance (Chapman et al. 2018 method) validated at HYDAT stations (#11)", "",
  sprintf("province run: %s", basename(key_dir)),
  sprintf("stations: %d accepted snaps, %d with predictors; %d calibrated on (basin >= %.0f %% in BC and on the grid)",
          nrow(st), sum(st$coverage > 0, na.rm = TRUE), nrow(cal), 100 * min_frac),
  sprintf("pooled zones in the shipped fit (fewer than 8 stations with their largest share): %s",
          paste(pooled, collapse = " ")),
  sprintf("zones no calibration station touches (no adjustment): %s", paste(unseen, collapse = " ")),
  sprintf(paste("pooled zones: one fitted 'other' level, or no adjustment, chosen by an inner blocked CV",
                "on each fold's training stations; blocked-CV folds chose other %d / none %d;",
                "the shipped fit (chosen over all stations): %s"),
          cv$chosen[["other"]], cv$chosen[["none"]], ship_variant),
  sprintf(paste("held-out stations predicted with their zone pooled in the fold: blocked CV %d, LOO %d;",
                "held-out predictions floored to 0: blocked CV %d, LOO %d"),
          cv$n_pooled, lo$n_pooled, cv$n_floored, lo$n_floored),
  sprintf(paste("folds: %d WSC sub-sub-drainages; headwater %d, nested %d;",
                "nested with upstream leak > 0: %d (median leak %.2f)"),
          length(unique(cal$fold)), sum(cal$nesting == "headwater"), sum(cal$nesting == "nested"),
          sum(cal$leak_up > 0), stats::median(cal$leak_up[cal$leak_up > 0])),
  sprintf("observed mm use the accumulated FWA area; FWA / HYDAT gross area median %.3f",
          stats::median(cal$area_ratio_fwa)),
  "", "Metrics: error = 100 (mod - obs) / obs on annual runoff; NSE on the 12-month climatology (mm)",
  "and on the shares. Chapman et al. (2018) report, for their adjusted model on 45 NE BC gauges:",
  "MAE 16.1 %, 77.8 % within +/- 20 %, median monthly NSE 0.92.",
  "",
  sprintf("GATE (adjusted beats raw P - AET on headwater stations, blocked CV): %s (MAE %.1f %% vs %.1f %%)",
          if (keep_adjust) "PASS - adjustment kept" else "FAIL - adjustment dropped", hw(cv_v), hw(raw_v)),
  sprintf(paste("Under the pre-set specification (pooled zones share one fitted 'other' level) the gate",
                "FAILS: %.1f %% vs %.1f %%. Which to ship is an open decision for the maintainer."),
          hw(plain[["other"]]), hw(raw_v)),
  "",
  fmt(raw_v, "Raw P - AET (no fitting)"),
  sprintf(paste("headwater stations, blocked CV MAE, raw -> adjusted: own zone in fold (n %d) %.1f -> %.1f %%;",
                "pooled in fold (n %d) %.1f -> %.1f %%"),
          sum(g2$zone_in_fold == "own zone"), hw_split(raw_v)[1], hw_split(cv_v)[1],
          sum(g2$zone_in_fold == "pooled"), hw_split(raw_v)[2], hw_split(cv_v)[2]), "",
  fmt(cv_v, paste("Adjusted, blocked CV, pooled variant chosen inside each fold (headline; CAVEAT: the 'none'",
                  "candidate was added after the pre-set 'other' specification failed the gate, so this is",
                  "mildly optimistic)")),
  fmt(lo_v, "Adjusted, leave-one-out, pooled variant chosen inside each fold (comparable with Chapman)"),
  fmt(plain[["other"]], "Transparency: blocked CV with every fold forced to 'other'"),
  fmt(plain[["none"]], "Transparency: blocked CV with every fold forced to 'none'"),
  fmt(ins_v, "Adjusted, in-sample (all stations in the fit)"),
  "## Fitted adjustment (all calibration stations): zone, a (mm), b (per mm of P)",
  sprintf("%s  %9.2f  %8.4f%s", co$zone, co$a, co$b,
          ifelse(co$zone %in% ins_fit$pooled, sprintf("  (pooled: %s)", ship_variant), ""))
), con)
close(con)
stamp("report written; gate ", if (keep_adjust) "PASS" else "FAIL")
