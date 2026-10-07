# Fit and validate the open water balance at HYDAT stations (#11, Phases 4-6),
# for one annual AET variant (#15, #18).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_validate.R [AET]    # AET: a name in wet:::wet_wb_aet_cols()
#
# For one fit (a province run and a HYDAT release, scripts/wb_fit_lib.R):
# reads data/wb/stations_<release>.rds (scripts/wb_stations.R) and the
# upstream means from scripts/wb_province.R. Writes the tracked report
# wb_report("wb_validation_aet-<AET>", release) and <fit>/cv_aet-<AET>.rds
# (read by scripts/wb_aet_compare.R). For the shipped AET it also writes
# wb_report("wb_validation", release) and <fit>/fits.rds (the fits the
# province output uses). The shipped AET is the one scripts/wb_aet_compare.R
# chose for this fit by the #15 and #18 decision rules (<fit>/aet_winner.txt),
# or, with WET_AET_CARRY=<release>, the one shipped by that release's fit
# (#43: AET is carried to a newer HYDAT, not re-picked). Without either, nothing ships.
#
# The pooled zones are adjusted by the variant an inner blocked CV picks in
# each fold, unless <fit>/pooled_variant.txt fixes one (scripts/wb_pooled_test.R,
# #43): then every fold and the shipped fit use it.

source("scripts/wb_cv_lib.R")
f_winner <- file.path(fit_dir, "aet_winner.txt")
carry <- Sys.getenv("WET_AET_CARRY")
# carry when there is no winner yet, or when a carried one went stale with the
# scoring code (a compared winner is only remade by scripts/wb_aet_compare.R)
stale_carry <- file.exists(f_winner) && {
  w0 <- readLines(f_winner)
  length(w0) == 3 && startsWith(w0[3], "carried") && !identical(w0[2], aet_code_md5)
}
if (nzchar(carry) && (carry == release || release == "20251014")) {
  stop("fit_", release, " cannot carry its AET", if (release == "20251014") ": its AET comes from the #15 comparison")
}
if (nzchar(carry) && (!file.exists(f_winner) || stale_carry)) {
  # carry the AET a reference fit ships: its winner, checked against its fits
  ref_dir <- wb_fit_dir(key_dir, carry)
  rw <- readLines(file.path(ref_dir, "aet_winner.txt"))
  rf <- readRDS(file.path(ref_dir, "fits.rds"))
  # the reference fit's winner must be the AET its shipped fits were made
  # with, and both must be current under this code (aet_md5: without a fixed
  # variant), or the carry would stamp a stale choice as current
  ref_md5 <- aet_md5_for(carry)
  if (!identical(rw[2], ref_md5) || !identical(rf$aet_md5, ref_md5) || !identical(rw[1], rf$aet)) {
    stop("fit ", carry, " ships no current, consistent AET to carry: rerun its chain first")
  }
  writeLines(c(rw[1], aet_code_md5, sprintf("carried from fit_%s (#43; its scores %s)", carry, rf$code_md5)),
             f_winner)
  stamp("AET ", rw[1], " carried from fit_", carry)
}
# The winner file holds the variant and the aet_code_md5 it was chosen
# under (and, when carried, where from). One chosen under other code is not
# shipped (the scores are still written, so the comparison can be rerun);
# fits.rds then stays as it was, and scripts/wb_output.R refuses it because it
# was made under other code. Without a current winner nothing ships: there is
# no default AET (#43), so a lost winner cannot turn into a cgiar fit.
ship_aet <- NA_character_
if (file.exists(f_winner)) {
  w <- readLines(f_winner)
  if (!length(w) %in% 2:3 || !w[1] %in% names(wet:::wet_wb_aet_cols())) stop("bad ", f_winner)
  ship_aet <- if (identical(w[2], aet_code_md5)) w[1] else NA_character_
  if (is.na(ship_aet)) {
    message(f_winner, " was chosen under other code: not shipping; rerun ",
            if (length(w) == 3) "with WET_AET_CARRY set" else "scripts/wb_aet_compare.R")
  }
}
f_pooled <- file.path(fit_dir, "pooled_variant.txt")
fixed_variant <- if (file.exists(f_pooled)) readLines(f_pooled)[1] else NA_character_
# the pooled-zone test's outcome, when it has run (scripts/wb_pooled_test.R)
f_test <- file.path(fit_dir, "pooled_test.txt")
pooled_test <- if (file.exists(f_test)) readLines(f_test) else NULL
if (!is.na(fixed_variant) && !fixed_variant %in% variants) stop("bad ", f_pooled)
aet_v <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet_v)) aet_v <- ship_aet
if (is.na(aet_v)) {
  stop("no current AET winner for fit_", release, ": name the AET to score, or carry one (WET_AET_CARRY)")
}
cal$raw <- wet:::wet_wb_raw(cal, aet_v)
raw_v <- wet_flow_validate(long(cal, pmax(cal$raw, 0), matrix(NA_real_, nrow(cal), 12)), groups)
ship_variant <- if (is.na(fixed_variant)) choose_variant(cal) else fixed_variant
ins_fit <- wet_wb_fit(cal, pooled_adjust = ship_variant)
ins_share <- wet_share_fit(cal)
ins_v <- wet_flow_validate(long(cal, wet_wb_adjust(ins_fit, cal), wet_share_predict(ins_share, cal)), groups)
cv_variant <- if (is.na(fixed_variant)) "nested" else fixed_variant
cv <- predict_cv(cal, cal$fold, cv_variant)
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
lo <- predict_cv(cal, loo$fold[match(cal$station_number, loo$station_number)], cv_variant)
lo_v <- wet_flow_validate(long(cal, lo$ann, lo$share), groups)
plain <- lapply(variants, function(v) {
  x <- predict_cv(cal, cal$fold, v)
  wet_flow_validate(long(cal, x$ann, x$share), groups)
})
names(plain) <- variants
stamp("validation done")

# gate: the adjustment must beat raw P - AET on headwater stations under blocked CV
hw <- function(v) v$summary$mae_pct[v$summary$group == "nesting" & v$summary$value == "headwater"]
gate_pass <- hw(cv_v) < hw(raw_v)
# A recorded override (<fit>/adjust_override.txt: a tolerance in points, then
# who and why) keeps the adjustment when the gate fails by no more than that
# tolerance: a tie the headwater-only gate cannot break, decided by the user
# for #43's refit because the adjustment corrects the main stems the gate does
# not score. A larger failure still drops the adjustment.
f_override <- file.path(fit_dir, "adjust_override.txt")
override <- if (file.exists(f_override)) readLines(f_override) else NULL
tie_tol <- if (is.null(override)) NA_real_ else as.numeric(override[1])
if (!is.null(override) && (is.na(tie_tol) || tie_tol < 0 || tie_tol > 0.5 || length(override) < 2)) {
  stop(f_override, " needs a tolerance (0 to 0.5 point) on line 1 and who decided, and why, after it")
}
keep_adjust <- gate_pass || (!is.null(override) && hw(cv_v) - hw(raw_v) <= tie_tol)
# a pooled variant fixed on the test gauges that drops the adjustment, so that
# raw P - AET would ship, is not shipped on its own authority (#43): cfu was
# chosen with the variant picked inside each fold
if (!is.na(fixed_variant) && !keep_adjust && aet_v %in% ship_aet) {
  stop(sprintf("the fixed pooled variant '%s' fails the headwater gate (%.2f %% vs raw %.2f %%%s): %s",
               fixed_variant, hw(cv_v), hw(raw_v),
               if (is.null(override)) "" else sprintf(", beyond the override's %.2f point", tie_tol),
               "nothing ships until the user decides (#43)"))
}
if (aet_v %in% ship_aet) {
  # outputs of any earlier fit go with it, so scripts/wb_map.R cannot draw them
  # beside this fit's stations; scripts/wb_output.R rebuilds them
  unlink(c(file.path(fit_dir, "runoff_annual.tif"), file.path(fit_dir, "output")), recursive = TRUE)
  saveRDS(list(wb = ins_fit, share = ins_share, keep_adjust = keep_adjust, gate_pass = gate_pass, min_frac = min_frac,
               calibration = cal$station_number, aet = aet_v, pooled_variant = ship_variant,
               pooled_fixed = !is.na(fixed_variant), release = release, code_md5 = score_code_md5,
               aet_md5 = aet_code_md5),
          file.path(fit_dir, "fits.rds"))
}
# per-station held-out predictions and summaries, for scripts/wb_aet_compare.R
saveRDS(list(aet = aet_v, keep_adjust = keep_adjust, gate_pass = gate_pass, raw_v = raw_v, cv_v = cv_v, lo_v = lo_v,
             plain = plain,
             ship_variant = ship_variant, station_number = cal$station_number, raw = cal$raw,
             cv_ann = cv$ann, cv_variant = cv_variant, nesting = cal$nesting, obs = cal$obs,
             release = release, code_md5 = score_code_md5),
        file.path(fit_dir, sprintf("cv_aet-%s.rds", aet_v)))

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
report <- wb_report(sprintf("wb_validation_aet-%s", aet_v), release)
con <- file(report, "w")
writeLines(c(
  "# Open water balance (Chapman et al. 2018 method) validated at HYDAT stations (#11)", "",
  sprintf("province run: %s; annual AET: %s (monthly shares use CGIAR monthly AET)", basename(key_dir), aet_v),
  sprintf("HYDAT release: %s", s$hydat_release),
  sprintf("stations: %d accepted snaps, %d with predictors; %d calibrated on (basin >= %.0f %% in BC and on the grid)",
          nrow(st), sum(st$coverage > 0, na.rm = TRUE), nrow(cal), 100 * min_frac),
  sprintf("pooled zones in the shipped fit (fewer than 8 stations with their largest share): %s",
          paste(pooled, collapse = " ")),
  sprintf("zones no calibration station touches (no adjustment): %s", paste(unseen, collapse = " ")),
  if (is.na(fixed_variant)) {
    sprintf(paste("pooled zones: one fitted 'other' level, or no adjustment, chosen by an inner blocked CV",
                  "on each fold's training stations; blocked-CV folds chose other %d / none %d;",
                  "the shipped fit (chosen over all stations): %s"),
            cv$chosen[["other"]], cv$chosen[["none"]], ship_variant)
  } else {
    sprintf(paste("pooled zones: '%s', fixed on short-record gauges no fit uses (scripts/wb_pooled_test.R, #43);",
                  "every fold and the shipped fit use it"), fixed_variant)
  },
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
  sprintf("GATE (adjusted beats raw P - AET on headwater stations, blocked CV): %s (MAE %.2f %% vs %.2f %%)",
          if (gate_pass) "PASS - adjustment kept" else if (keep_adjust) {
            sprintf("FAIL within the recorded tie tolerance of %.2f point - adjustment kept by override", tie_tol)
          } else "FAIL - adjustment dropped", hw(cv_v), hw(raw_v)),
  if (!is.null(override)) sprintf("override (%s): %s", basename(f_override), paste(override[-1], collapse = " ")),
  if (is.na(fixed_variant)) {
    sprintf(paste("Under the pre-set specification (pooled zones share one fitted 'other' level) the gate",
                  "FAILS: %.1f %% vs %.1f %%. Which to ship is an open decision for the maintainer."),
            hw(plain[["other"]]), hw(raw_v))
  } else {
    sprintf(paste("The pooled-zone variant was fixed outside the calibration gauges (%s),",
                  "so the headline has no selection caveat. %s"),
            basename(f_pooled), pooled_test[3])
  },
  "",
  fmt(raw_v, "Raw P - AET (no fitting)"),
  sprintf(paste("headwater stations, blocked CV MAE, raw -> adjusted: own zone in fold (n %d) %.1f -> %.1f %%;",
                "pooled in fold (n %d) %.1f -> %.1f %%"),
          sum(g2$zone_in_fold == "own zone"), hw_split(raw_v)[1], hw_split(cv_v)[1],
          sum(g2$zone_in_fold == "pooled"), hw_split(raw_v)[2], hw_split(cv_v)[2]), "",
  if (is.na(fixed_variant)) {
    fmt(cv_v, if (is.null(pooled_test)) {
      paste("Adjusted, blocked CV, pooled variant chosen inside each fold (headline; CAVEAT: the 'none'",
            "candidate was added after the pre-set 'other' specification failed the gate, so this is",
            "mildly optimistic)")
    } else {
      paste("Adjusted, blocked CV, pooled variant chosen inside each fold (headline; CAVEAT: the 'none'",
            "candidate was added after the pre-set specification failed, and the test on short-record",
            sprintf("gauges (#43) was %s, so this is mildly optimistic)", pooled_test[1]))
    })
  } else {
    fmt(cv_v, sprintf("Adjusted, blocked CV, pooled variant fixed to '%s' (headline)", fixed_variant))
  },
  fmt(lo_v, sprintf("Adjusted, leave-one-out, pooled variant %s (comparable with Chapman)",
                    if (is.na(fixed_variant)) "chosen inside each fold" else sprintf("fixed to '%s'", fixed_variant))),
  fmt(plain[["other"]], "Transparency: blocked CV with every fold forced to 'other'"),
  fmt(plain[["none"]], "Transparency: blocked CV with every fold forced to 'none'"),
  fmt(ins_v, "Adjusted, in-sample (all stations in the fit)"),
  "## Fitted adjustment (all calibration stations): zone, a (mm), b (per mm of P)",
  sprintf("%s  %9.2f  %8.4f%s", co$zone, co$a, co$b,
          ifelse(co$zone %in% ins_fit$pooled, sprintf("  (pooled: %s)", ship_variant), ""))
), con)
close(con)
if (aet_v %in% ship_aet) invisible(file.copy(report, wb_report("wb_validation", release), overwrite = TRUE))
stamp("report written (", aet_v, "); gate ", if (gate_pass) "PASS" else "FAIL",
      "; adjustment ", if (keep_adjust) "kept" else "dropped")
