# Fit and validate the open water balance at HYDAT stations (#11, Phases 4-6),
# for one annual AET variant (#15, #18).
#
#   Rscript scripts/wb_validate.R [AET]    # AET: a name in wet:::wet_wb_aet_cols(); default the shipped one
#
# Reads data/wb/stations.rds (scripts/wb_stations.R) and the upstream means
# from scripts/wb_province.R. Writes the tracked report
# data/checks/wb_validation_aet-<AET>.txt and data/wb/<key>/cv_aet-<AET>.rds
# (read by scripts/wb_aet_compare.R). For the shipped variant it also writes
# data/checks/wb_validation.txt and data/wb/<key>/fits.rds (the fits the
# province output uses). The shipped variant is the one scripts/wb_aet_compare.R
# chose for this run by the #15 and #18 decision rules (data/wb/<key>/aet_winner.txt),
# or cgiar before a comparison exists.

source("scripts/wb_cv_lib.R")
f_winner <- file.path(key_dir, "aet_winner.txt")
# The winner file holds the variant and the score_code_md5 it was chosen
# under. One chosen under other code is not shipped (the scores are still
# written, so the comparison can be rerun); fits.rds then stays as it was, and
# scripts/wb_output.R refuses it because it was made under other code.
ship_aet <- "cgiar"
if (file.exists(f_winner)) {
  w <- readLines(f_winner)
  if (length(w) != 2 || !w[1] %in% names(wet:::wet_wb_aet_cols())) stop("bad ", f_winner)
  ship_aet <- if (identical(w[2], score_code_md5)) w[1] else NA_character_
  if (is.na(ship_aet)) message(f_winner, " was chosen under other code: not shipping; rerun scripts/wb_aet_compare.R")
}
aet_v <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet_v)) aet_v <- ship_aet
cal$raw <- wet:::wet_wb_raw(cal, aet_v)
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
if (aet_v %in% ship_aet) {
  # outputs of any earlier fit go with it, so scripts/wb_map.R cannot draw them
  # beside this fit's stations; scripts/wb_output.R rebuilds them
  unlink(c(file.path(key_dir, "runoff_annual.tif"), file.path(key_dir, "output")), recursive = TRUE)
  saveRDS(list(wb = ins_fit, share = ins_share, keep_adjust = keep_adjust, min_frac = min_frac,
               calibration = cal$station_number, aet = aet_v, code_md5 = score_code_md5),
          file.path(key_dir, "fits.rds"))
}
# per-station held-out predictions and summaries, for scripts/wb_aet_compare.R
saveRDS(list(aet = aet_v, keep_adjust = keep_adjust, raw_v = raw_v, cv_v = cv_v, lo_v = lo_v, plain = plain,
             ship_variant = ship_variant, station_number = cal$station_number, raw = cal$raw,
             cv_ann = cv$ann, code_md5 = score_code_md5),
        file.path(key_dir, sprintf("cv_aet-%s.rds", aet_v)))

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
report <- sprintf("data/checks/wb_validation_aet-%s.txt", aet_v)
con <- file(report, "w")
writeLines(c(
  "# Open water balance (Chapman et al. 2018 method) validated at HYDAT stations (#11)", "",
  sprintf("province run: %s; annual AET: %s (monthly shares use CGIAR monthly AET)", basename(key_dir), aet_v),
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
if (aet_v %in% ship_aet) invisible(file.copy(report, "data/checks/wb_validation.txt", overwrite = TRUE))
stamp("report written (", aet_v, "); gate ", if (keep_adjust) "PASS" else "FAIL")
