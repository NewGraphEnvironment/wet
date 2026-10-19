# Fit and validate the open water balance at HYDAT stations (#11, Phases 4-6),
# for one annual AET variant (#15, #18).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_validate.R [AET]    # AET: a name in wet:::wet_wb_aet_cols()
#
# For one fit (a province run and a HYDAT release, scripts/wb_fit_lib.R):
# reads data/wb/stations_<release>.rds (scripts/wb_stations.R) and the
# upstream means from scripts/wb_province.R. Writes the tracked report
# wb_report("wb_validation_aet-<AET>", release) and <fit>/cv_aet-<AET>.rds
# (read by scripts/wb_aet_compare.R; it holds the held-out annual and monthly
# balance at every calibration gauge, #68). For the shipped AET it also writes
# wb_report("wb_validation", release) and <fit>/fits.rds (the fits the
# province output uses). The shipped AET is the one scripts/wb_aet_compare.R
# chose for this fit by the #15 and #18 decision rules (<fit>/aet_winner.txt),
# on the fit's own release (#81). Without a winner chosen under this code,
# nothing ships.
#
# The pooled zones are adjusted by the variant an inner blocked CV picks in
# each fold, unless <fit>/pooled_variant.txt fixes one (scripts/wb_pooled_test.R,
# #43): then every fold and the shipped fit use it. Both it and the gate
# override are read by scripts/wb_cv_lib.R.
#
# The monthly shares are held out with and without the snow predictors (#16),
# in the same folds; the snow predictors ship only if they pass the rule fixed
# below (share_min_gain), and scripts/wb_share_snow.R breaks the comparison down.
#
# ---- how the shares are made (#102): the rule, fixed here before any candidate was coded or scored --
#
# #70 measured, deciding nothing, that the donor mean of the five nearest
# training gauges' day-of-year shares, summed to months, scores a median share
# NSE of 0.939 against 0.874 for the shipped regression on the same held-out
# gauges. That number is known, so what guards against a lucky pick is that
# every setting of the candidates is fixed here, not tuned after scoring.
# Decided at the plan gate (airvine, 2026-10-19): the months only (a winner
# replaces the 12 shares; #70's within-month shape stays the daily method and
# is refitted on the new months by scripts/wb_shape_daily.R), and a symmetric
# leak test.
#
# On the static share predictors #16's rule ships (`static`; on fit_20260717
# elev, e_km, n_km, snowmelt_doy_50, swe_max):
#
#   regression  the incumbent: wet_share_fit() as before #102, the twelve
#               monthly regressions, floored at 0 and renormalised.
#   donor       the inverse-distance mean of the OBSERVED monthly shares
#               (share_01..12, from monthly volumes, the values scored against)
#               of the k = 5 nearest training gauges in the space of `static`,
#               each predictor divided by its SD across the training gauges;
#               weights 1 / (dist + 1e-6 * median dist), a gauge at distance 0
#               taking the whole weight (as wet_shape_predict()'s donor, #70);
#               k capped at the number of training gauges.
#   blend       the equal-weight mean of the donor and regression shares.
#
# Per calibration gauge, the NSE of its 12 held-out shares against its
# observed ones (share_nse() below: observed runoff of at least 10 mm), over
# the gauges every candidate scores, in two pools:
#
#   blocked CV  the shipped fit's folds (wet_cv_folds(), WSC sub-sub-drainage
#               blocks): each candidate fitted on the fold's training gauges;
#   leak-free   for each held-out gauge, every candidate (the regression
#               included) refitted on its fold's training gauges less those
#               upstream or downstream of it (wet:::wet_fwa_upstream() on
#               wscode and localcode).
#
# A candidate passes if its median exceeds the regression's in the same pool
# by at least share_method_min_gain = 0.01 (unrounded, 1e-9 allowed for
# floating point; #16's margin) in BOTH pools. If both pass, the higher
# blocked-CV median ships; if neither, the regression stays. The outcome is
# share_method in fits.rds and cv_aet-<AET>.rds. Taken from the shares alone,
# it does not depend on the annual balance, so every AET variant of a fit gives
# the same outcome. There is no "kept on both fits" clause: #81 retired the
# 2025-10-14 fit and the two share the window and most gauges. Headwater and
# nested gauges, and the short-record test stations, are reported beside the
# rule by scripts/wb_share_donor.R and decide nothing.

source("scripts/wb_cv_lib.R")
f_winner <- file.path(fit_dir, "aet_winner.txt")
# The winner file holds the variant and the score_code_md5 it was chosen
# under (the fit's decision files included, scripts/wb_score_md5.R). One chosen under other code is not shipped (the scores are still
# written, so the comparison can be rerun);
# fits.rds then stays as it was, and scripts/wb_output.R refuses it because it
# was made under other code. Without a current winner nothing ships: there is
# no default AET (#43), so a lost winner cannot turn into a cgiar fit.
ship_aet <- NA_character_
if (file.exists(f_winner)) {
  w <- readLines(f_winner)
  # two lines: a winner carried from another fit (#43, retired by #81) is
  # not a choice made on this fit's release
  if (length(w) != 2 || !w[1] %in% names(wet:::wet_wb_aet_cols())) stop("bad ", f_winner)
  ship_aet <- if (identical(w[2], score_code_md5)) w[1] else NA_character_
  if (is.na(ship_aet)) message(f_winner, " was chosen under other code: not shipping; rerun scripts/wb_aet_compare.R")
}
# the pooled-zone test's outcome, when it has run (scripts/wb_pooled_test.R)
f_test <- file.path(fit_dir, "pooled_test.txt")
pooled_test <- if (file.exists(f_test)) readLines(f_test) else NULL
aet_v <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet_v)) aet_v <- ship_aet
if (is.na(aet_v)) {
  stop("no current AET winner for fit_", release, ": name the AET to score, or score every variant and run ",
       "scripts/wb_aet_compare.R (after a DECISION TO USER, the user records the AET in ", f_aet_decision,
       ", or for a raw winner changes a decision file)")
}
cal$raw <- wet:::wet_wb_raw(cal, aet_v)
raw_v <- wet_flow_validate(long(cal, pmax(cal$raw, 0), matrix(NA_real_, nrow(cal), 12)), groups)
ship_variant <- if (is.na(fixed_variant)) choose_variant(cal) else fixed_variant
ins_fit <- wet_wb_fit(cal, pooled_adjust = ship_variant)
cv_variant <- if (is.na(fixed_variant)) "nested" else fixed_variant
cv <- predict_cv(cal, cal$fold, cv_variant)
# Which monthly-share specification ships (#16), by a rule fixed before the
# snow predictors were first scored: they are kept only if the blocked-CV
# median per-gauge share NSE rises by at least share_min_gain (unrounded, with
# 1e-9 allowed for floating point). Per gauge, the NSE of the 12 held-out
# shares against the observed ones, at gauges with observed runoff of at least
# 10 mm (wet_flow_validate()'s min_obs) and shares from both specifications:
# taken from the shares themselves, it does not depend on the annual balance,
# so every AET variant of a fit gives the same outcome. The shipped fit's
# outcome (fit_20260717) is #16's; each fit ships its own.
share_min_gain <- 0.01
obs_sh <- as.matrix(cal[sprintf("share_%02d", 1:12)])
share_nse <- function(sh) {
  vapply(seq_len(nrow(cal)), function(i) {
    if (!(cal$obs[i] >= 10) || anyNA(obs_sh[i, ]) || anyNA(sh[i, ])) return(NA_real_)
    wet:::wet_nse(obs_sh[i, ], sh[i, ])
  }, numeric(1))
}
share_st <- lapply(cv$shares, share_nse)
share_both <- !is.na(share_st$base) & !is.na(share_st$snow)
share_med <- vapply(share_st, function(x) stats::median(x[share_both & !is.na(x)]), numeric(1))
share_gain <- share_med[["snow"]] - share_med[["base"]]
ship_share <- if (share_gain >= share_min_gain - 1e-9) "snow" else "base"
# How the shares are made (#102), by the rule in this script's header, on the
# static predictors just chosen: donor and blend against the regression, under
# the blocked CV and the leak-free pool
share_method_min_gain <- 0.01
static_sh <- share_static[[ship_share]]
sm_cv <- cv_share_methods(cal, cal$fold, static_sh)
# the incumbent is #16's held-out shares exactly: one fit, two routes to it
if (!identical(sm_cv$regression, cv$shares[[ship_share]])) stop("the regression's held-out shares are not #16's")
sm_lf <- cv_share_methods(cal, cal$fold, static_sh, related = share_related(cal))
sm_nse <- lapply(sm_cv, share_nse)
sm_nse_lf <- lapply(sm_lf, share_nse)
sm_scored <- Reduce(`&`, lapply(c(sm_nse, sm_nse_lf), function(x) !is.na(x)))
sm_med <- vapply(sm_nse, function(x) stats::median(x[sm_scored]), numeric(1))
sm_med_lf <- vapply(sm_nse_lf, function(x) stats::median(x[sm_scored]), numeric(1))
cands <- setdiff(share_methods, "regression")
sm_gain <- sm_med[cands] - sm_med[["regression"]]
sm_gain_lf <- sm_med_lf[cands] - sm_med_lf[["regression"]]
sm_pass <- sm_gain >= share_method_min_gain - 1e-9 & sm_gain_lf >= share_method_min_gain - 1e-9
ship_method <- if (any(sm_pass)) {
  ok <- cands[sm_pass]
  ok[which.max(sm_med[ok])]
} else {
  "regression"
}
cv$share <- sm_cv[[ship_method]]
ins_share <- wet_share_fit(cal, static = static_sh, method = ship_method)
ins_v <- wet_flow_validate(long(cal, wet_wb_adjust(ins_fit, cal), wet_share_predict(ins_share, cal)), groups)
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
lo <- predict_cv(cal, loo$fold[match(cal$station_number, loo$station_number)], cv_variant, share_specs = ship_share,
                 share_method = ship_method)
lo_v <- wet_flow_validate(long(cal, lo$ann, lo$share), groups)
plain <- lapply(variants, function(v) {
  x <- predict_cv(cal, cal$fold, v, share_specs = ship_share, share_method = ship_method)
  wet_flow_validate(long(cal, x$ann, x$share), groups)
})
names(plain) <- variants
stamp("validation done")

# gate: the adjustment must beat raw P - AET on headwater stations under blocked CV
hw <- function(v) v$summary$mae_pct[v$summary$group == "nesting" & v$summary$value == "headwater"]
gate_pass <- hw(cv_v) < hw(raw_v)
# A recorded override (<fit>/adjust_override.txt, read by scripts/wb_cv_lib.R)
# keeps the adjustment when the gate fails by no more than its tolerance
# (keep_adjust_for()). A larger failure still drops the adjustment.
keep_adjust <- keep_adjust_for(hw(cv_v), hw(raw_v))
# a pooled variant fixed on the test gauges that drops the adjustment, so that
# raw P - AET would ship, is not shipped on its own authority (#43);
# scripts/wb_aet_compare.R writes no winner file for such a variant (#81)
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
  saveRDS(list(wb = ins_fit, share = ins_share, share_spec = ship_share, share_method = ship_method,
               keep_adjust = keep_adjust,
               gate_pass = gate_pass, min_frac = min_frac,
               calibration = cal$station_number, aet = aet_v, pooled_variant = ship_variant,
               pooled_fixed = !is.na(fixed_variant), release = release, code_md5 = score_code_md5,
               aet_decision = if (is.null(aet_decision)) NA_character_ else aet_decision[1],
               aet_md5 = aet_code_md5),
          file.path(fit_dir, "fits.rds"))
}
# per-station held-out predictions and summaries, for scripts/wb_aet_compare.R;
# the held-out monthly balance too (#68): long(cal, cv_ann, cv_share) rebuilt
# from obs, obs_share, cv_ann and cv_share alone (rows in station_number
# order). cv_share is the shipped specification's; cv_shares holds every
# specification scored, for scripts/wb_share_snow.R (#16)
saveRDS(list(aet = aet_v, keep_adjust = keep_adjust, gate_pass = gate_pass, raw_v = raw_v, cv_v = cv_v, lo_v = lo_v,
             plain = plain,
             ship_variant = ship_variant, station_number = cal$station_number, raw = cal$raw,
             cv_ann = cv$ann, cv_share = cv$share, obs_share = as.matrix(cal[sprintf("share_%02d", 1:12)]),
             cv_shares = cv$shares, share_spec = ship_share,
             share_rule = list(min_gain = share_min_gain, median = share_med, gain = share_gain,
                               n_both = sum(share_both), nse = share_st),
             share_method = ship_method, cv_share_methods = sm_cv, cv_share_methods_leakfree = sm_lf,
             share_method_rule = list(min_gain = share_method_min_gain, median = sm_med, median_leakfree = sm_med_lf,
                                      gain = sm_gain, gain_leakfree = sm_gain_lf, pass = sm_pass,
                                      n = sum(sm_scored), nse = sm_nse, nse_leakfree = sm_nse_lf),
             zone = cal$zone, lake = groups$lake, cv_variant = cv_variant, nesting = cal$nesting, obs = cal$obs,
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
  sprintf(paste("SHARES (#16; rule fixed before the snow predictors were scored: keep snowmelt_doy_50 and swe_max",
                "if the blocked-CV median share NSE rises by >= %.2f): base %.4f, with snow %.4f, gain %+.4f",
                "over %d gauges with both -> %s"),
          share_min_gain, share_med[["base"]], share_med[["snow"]], share_gain, sum(share_both),
          if (ship_share == "snow") "snow predictors KEPT" else "snow predictors NOT kept"),
  sprintf("  (not deciding: snowmelt_doy_50 alone %.4f over the same gauges)", share_med[["doy"]]),
  sprintf(paste("SHARE METHOD (#102; rule fixed in this script's header before any candidate was scored: donor or",
                "blend ships if its median share NSE beats the regression's by >= %.2f under blocked CV and in the",
                "leak-free pool), over %d gauges:"), share_method_min_gain, sum(sm_scored)),
  sprintf("  blocked CV: %s", paste(sprintf("%s %.4f", share_methods, sm_med[share_methods]), collapse = ", ")),
  sprintf("  leak-free:  %s", paste(sprintf("%s %.4f", share_methods, sm_med_lf[share_methods]), collapse = ", ")),
  sprintf("  gain over the regression: %s -> %s",
          paste(sprintf("%s %+.4f / %+.4f%s", cands, sm_gain, sm_gain_lf, ifelse(sm_pass, " (passes)", "")),
                collapse = ", "),
          if (ship_method == "regression") "the regression STAYS" else sprintf("%s SHIPS", ship_method)),
  sprintf("shares shipped: the %s on %s (every table below uses them)", ship_method,
          paste(share_static[[ship_share]], collapse = ", ")),
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
  fmt(ins_v, if (ship_method == "regression") "Adjusted, in-sample (all stations in the fit)" else {
    sprintf("Adjusted, in-sample (all stations in the fit; the %s shares draw on each gauge's own)", ship_method)
  }),
  "## Fitted adjustment (all calibration stations): zone, a (mm), b (per mm of P)",
  sprintf("%s  %9.2f  %8.4f%s", co$zone, co$a, co$b,
          ifelse(co$zone %in% ins_fit$pooled, sprintf("  (pooled: %s)", ship_variant), ""))
), con)
close(con)
if (aet_v %in% ship_aet) invisible(file.copy(report, wb_report("wb_validation", release), overwrite = TRUE))
stamp("report written (", aet_v, "); gate ", if (gate_pass) "PASS" else "FAIL",
      "; adjustment ", if (keep_adjust) "kept" else "dropped")
