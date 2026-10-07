# Settle how the open water balance adjusts its pooled zones, on gauges no fit
# uses (#43), by the rule pre-registered in planning before this ran (as
# amended the same day, before any scoring):
#
#   - test gauges: natural BC stations with 1-9 complete years in 1981-2010
#     (scripts/wb_stations.R, `test`), snapped within +/- 10 %, basin >= 95 %
#     in BC and on the grid, observed annual runoff >= 10 mm, not a
#     calibration gauge, and not a CHANNEL, OVERFLOW or DIVERSION gauge;
#   - each test gauge predicted from 'other' and 'none' fits on the calibration
#     gauges outside its WSC sub-sub-drainage (the headline CV's blocks), with
#     this fit's AET, floored at 0 as shipped;
#   - decided on the test gauges whose dominant zone is pooled in the fit that
#     predicts them: fewer than 10, the test is uninformative and nothing is
#     fixed; otherwise, MAE within 1.0 point fixes the variant choose_variant()
#     picks over all calibration gauges, and a larger gap fixes the lower.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_pooled_test.R
#
# Writes <fit>/pooled_variant.txt when the test fixes a variant, which
# scripts/wb_validate.R then uses for every fold and the shipped fit (rerun
# it), and the tracked report wb_report("wb_pooled_test", release). Runs once
# per fit: a decision already written is not remade.

# the fit is named, never defaulted: the test runs once per fit and fixes it
if (!nzchar(Sys.getenv("WET_HYDAT_RELEASE"))) stop("set WET_HYDAT_RELEASE to the fit the test settles")
# fit_20251014 is the #15 reproduction, which runs with the variant chosen in
# each fold: fixing one there would leave its AET comparison unrepeatable
if (Sys.getenv("WET_HYDAT_RELEASE") == "20251014") stop("the pooled-zone test settles a refit, not fit_20251014 (#15's)")
source("scripts/wb_cv_lib.R")
f_pooled <- file.path(fit_dir, "pooled_variant.txt")
if (file.exists(file.path(fit_dir, "pooled_test.txt"))) stop("this fit's pooled-zone test has run: it is not remade")
tie <- 1.0
min_decision <- 10
min_obs <- 10
fits <- readRDS(file.path(fit_dir, "fits.rds"))
if (!identical(fits$code_md5, score_code_md5)) {
  stop("fits.rds was made under other scoring code: rerun scripts/wb_validate.R")
}
aet <- fits$aet
cal$raw <- wet:::wet_wb_raw(cal, aet)

# ---- test gauges with their predictors, counted at each filter ---------------------------
if (is.null(s$test) || !nrow(s$test)) {
  stop(wb_stations_path(release), " has no test stations: rerun scripts/wb_stations.R")
}
n <- c(short_record = nrow(s$test), snapped = sum(s$test$accepted %in% TRUE))
tst <- with_predictors(s$test[s$test$accepted %in% TRUE, ], s$test_monthly)
n["with_predictors"] <- nrow(tst)
tst <- tst[tst$bc_fraction >= min_frac & tst$coverage >= min_frac, ]
n["in_bc_on_grid"] <- nrow(tst)
tst <- tst[!grepl("CHANNEL|OVERFLOW|DIVERSION", toupper(tst$station_name)), ]
n["not_channel"] <- nrow(tst)
tst <- tst[!is.na(tst$obs) & tst$obs >= min_obs & !tst$station_number %in% cal$station_number, ]
n["obs_ge_10mm"] <- nrow(tst)
stopifnot(nrow(tst) > 0)
tst$raw <- wet:::wet_wb_raw(tst, aet)
zt <- sub("^z", "", grep("^z[0-9]+$", names(tst), value = TRUE))
tst$dominant <- zt[max.col(as.matrix(tst[paste0("z", zt)]), ties.method = "first")]

# ---- predict each test gauge without its sub-sub-drainage's calibration gauges ----------------
adjust_test <- function(fit, d) {
  # a zone the fit has not seen gets no adjustment, as in scripts/wb_output.R
  drop <- setdiff(zt, fit$coef$zone)
  wet_wb_adjust(fit, d[setdiff(names(d), c(paste0("z", drop), paste0("zp", drop)))])
}
pred <- matrix(NA_real_, nrow(tst), length(variants), dimnames = list(NULL, variants))
decision <- logical(nrow(tst))
for (ss in unique(tst$subsubdrainage)) {
  i <- tst$subsubdrainage == ss
  tr <- cal[cal$subsubdrainage != ss, ]
  for (v in variants) pred[i, v] <- adjust_test(wet_wb_fit(tr, pooled_adjust = v), tst[i, ])
  decision[i] <- tst$dominant[i] %in% wet_wb_pooled(tr)
}
err <- 100 * (pred - tst$obs) / tst$obs
mae_all <- colMeans(abs(err))
mae_dec <- colMeans(abs(err[decision, , drop = FALSE]))
raw_mae <- mae(tst$obs, pmax(tst$raw, 0))
nested <- choose_variant(cal)
informative <- sum(decision) >= min_decision
gap <- unname(mae_dec[["other"]] - mae_dec[["none"]])
fixed <- if (!informative) NA_character_ else if (abs(gap) <= tie) nested else names(which.min(mae_dec))
how <- if (!informative) {
  sprintf("uninformative: %d decision gauges, fewer than %d; nothing fixed, the nested choice and its caveat stay",
          sum(decision), min_decision)
} else if (abs(gap) <= tie) {
  sprintf("tie within %.1f point on %d decision gauges: the nested choice over all calibration gauges (%s)",
          tie, sum(decision), nested)
} else {
  sprintf("the lower MAE on %d decision gauges", sum(decision))
}
# context only: paired bootstrap of the MAE difference on the decision gauges
ci <- if (sum(decision) > 1) {
  set.seed(43)
  d <- abs(err[decision, "other"]) - abs(err[decision, "none"])
  stats::quantile(replicate(2000, mean(sample(d, replace = TRUE))), c(0.025, 0.975))
} else {
  c(NA_real_, NA_real_)
}
if (!is.na(fixed)) writeLines(c(fixed, sprintf("fixed by scripts/wb_pooled_test.R (#43): %s", how)), f_pooled)
# the outcome either way, which scripts/wb_validate.R quotes beside its headline
writeLines(c(if (is.na(fixed)) "uninformative" else fixed, how,
             sprintf("test-gauge MAE on %d decision gauges: other %.1f %%, none %.1f %%", sum(decision),
                     mae_dec[["other"]], mae_dec[["none"]])),
           file.path(fit_dir, "pooled_test.txt"))

con <- file(wb_report("wb_pooled_test", release), "w")
writeLines(c(
  "# Pooled-zone adjustment settled on gauges no fit uses (#43)", "",
  sprintf("fit: province run %s, HYDAT release %s, annual AET %s", basename(key_dir), s$hydat_release, aet),
  sprintf("pooled zones (all calibration gauges): %s", paste(wet_wb_pooled(cal), collapse = " ")),
  "",
  "test gauges at each filter:",
  sprintf("  %-16s %4d", names(n), n),
  sprintf("each predicted from fits leaving out the calibration gauges in its sub-sub-drainage (%d of them)",
          length(unique(tst$subsubdrainage))),
  sprintf("decision gauges (dominant zone pooled in the fit that predicts them): %d", sum(decision)),
  "",
  "MAE (%) on annual runoff:",
  sprintf("  %-6s decision %6.1f   all test gauges %6.1f", variants, mae_dec[variants], mae_all[variants]),
  sprintf("  %-6s                    all test gauges %6.1f", "raw", raw_mae),
  sprintf("other - none on the decision gauges: %+.2f points; paired bootstrap 95 %% interval %+.2f to %+.2f (context)",
          gap, ci[1], ci[2]),
  "",
  sprintf(paste("rule: fewer than %d decision gauges is uninformative; within %.1f point fixes the nested choice",
                "over all calibration gauges (%s); otherwise the lower"), min_decision, tie, nested),
  sprintf("OUTCOME: %s", if (is.na(fixed)) "nothing fixed" else sprintf("fixed '%s'", fixed)),
  sprintf("  (%s)", how),
  if (!is.na(fixed)) sprintf("test-gauge MAE of the fixed variant, decision gauges: %.1f %%", mae_dec[[fixed]])
), con)
close(con)
stamp("pooled-zone test: ", if (is.na(fixed)) "nothing fixed" else paste("fixed", fixed), "; ", how)
