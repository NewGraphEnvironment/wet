# How the monthly shares are made (#102): the regression, the donor gauges'
# shares and their blend, at the calibration gauges, from the held-out months
# scripts/wb_validate.R stores, and at the short-record test gauges.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_share_donor.R [AET]   # default: the fit's AET winner
#
# Reads <fit>/cv_aet-<AET>.rds and writes the tracked report
# wb_report("wb_share_donor", release), with no timestamp. The decision is
# wb_validate.R's (its rule and outcome are restated here); this report breaks
# it down by month, by hydrologic zone (11, 17 and 04 named, where #70's
# within-month donor was weakest), at the gauges whose flow peaks in May or
# June and at those that peak in other months, in WSC area 10 (the Liard), at
# lake outlets and by nesting, all held out under blocked CV and refitted on
# nothing. Beside them, deciding nothing: the leak-free pool's medians, and
# the short-record test gauges (scripts/wb_stations.R `test`, filtered as
# scripts/wb_pooled_test.R filters them) with twelve observed months, each
# predicted by every method fitted on the calibration gauges outside its WSC
# sub-sub-drainage (the blocks of the headline CV).

source("scripts/wb_cv_lib.R")  # cal, s, with_predictors(), share_static, share_methods, long(), score_code_md5
aet <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet)) aet <- readLines(file.path(fit_dir, "aet_winner.txt"))[1]
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", aet)))
need <- c("cv_share_methods", "cv_share_methods_leakfree", "share_method", "share_method_rule", "obs_share", "zone",
          "lake", "nesting")
if (!all(need %in% names(cvr))) {
  stop("cv_aet-", aet, ".rds predates #102 (no ", paste(setdiff(need, names(cvr)), collapse = ", "),
       "): rerun scripts/wb_validate.R")
}
# scored under this code, or the report would restate a stale outcome as current
if (!identical(cvr$code_md5, score_code_md5)) {
  stop("cv_aet-", aet, ".rds was scored under other code: rerun scripts/wb_validate.R ", aet)
}
stopifnot(identical(cvr$release, release), identical(cvr$station_number, cal$station_number),
          identical(names(cvr$cv_share_methods), share_methods),
          identical(cvr$cv_share, cvr$cv_share_methods[[cvr$share_method]]))
shares <- cvr$cv_share_methods
static <- share_static[[cvr$share_spec]]

# ---- the held-out months, every method -----------------------------------------------------
n <- length(cvr$station_number)
obs_m <- cvr$obs_share * cvr$obs
peak_obs <- max.col(cvr$obs_share, ties.method = "first")
zone_named <- c("04", "11", "17")
groups <- data.frame(station_number = cvr$station_number,
                     zone = paste("zone", cvr$zone),
                     zone_named = ifelse(cvr$zone %in% zone_named, paste("zone", cvr$zone), "other zones"),
                     freshet = ifelse(peak_obs %in% 5:6, "peak May-June", "peak other months"),
                     wsc = ifelse(substr(cvr$station_number, 1, 2) == "10", "WSC area 10", "other areas"),
                     lake = cvr$lake, nesting = cvr$nesting)
v <- lapply(shares, function(sh) wet_flow_validate(long(cal, cvr$cv_ann, sh), groups))
med <- function(x) if (any(!is.na(x))) stats::median(x, na.rm = TRUE) else NA_real_
# per month: the median error of the monthly flow, in percent, over gauges with flow that month
month_err <- function(sh, keep = rep(TRUE, n)) {
  mod_m <- sh * cvr$cv_ann
  vapply(1:12, function(m) {
    i <- keep & obs_m[, m] > 0 & !is.na(mod_m[, m])
    med(100 * (mod_m[i, m] - obs_m[i, m]) / obs_m[i, m])
  }, numeric(1))
}
# at the May-June peak gauges, in the observed peak month
fr <- peak_obs %in% 5:6 & cvr$obs > 0
peak_stats <- function(sh) {
  mod_m <- sh * cvr$cv_ann
  i <- which(fr & !is.na(mod_m[, 1]))
  mo <- mod_m[cbind(i, peak_obs[i])]
  ob <- obs_m[cbind(i, peak_obs[i])]
  c(n = length(i), below = mean(mo < ob), median_err = med(100 * (mo - ob) / ob),
    same_peak = mean(max.col(sh[i, , drop = FALSE], ties.method = "first") == peak_obs[i]))
}
ps <- lapply(shares, peak_stats)

# ---- the short-record test gauges ------------------------------------------------------------
cols_share <- sprintf("share_%02d", 1:12)
if (is.null(s$test) || !nrow(s$test)) {
  stop(wb_stations_path(release), " has no test stations: rerun scripts/wb_stations.R")
}
tst <- with_predictors(s$test[s$test$accepted %in% TRUE, ], s$test_monthly)
tst <- tst[tst$bc_fraction >= min_frac & tst$coverage >= min_frac, ]
tst <- tst[!grepl("CHANNEL|OVERFLOW|DIVERSION", toupper(tst$station_name)), ]
tst <- tst[!is.na(tst$obs) & tst$obs >= 10 & !tst$station_number %in% cal$station_number, ]
tst <- tst[stats::complete.cases(tst[c(cols_share, static)]), ]
tst_sh <- lapply(stats::setNames(share_methods, share_methods), function(k) matrix(NA_real_, nrow(tst), 12))
for (ss in unique(tst$subsubdrainage)) {
  i <- tst$subsubdrainage == ss
  tr <- cal[cal$subsubdrainage != ss, ]
  for (k in share_methods) {
    tst_sh[[k]][i, ] <- wet_share_predict(wet_share_fit(tr, static = static, method = k), tst[i, ])
  }
}
tst_obs <- as.matrix(tst[cols_share])
tst_nse <- lapply(tst_sh, function(sh) {
  vapply(seq_len(nrow(tst)), function(i) if (anyNA(sh[i, ])) NA_real_ else wet:::wet_nse(tst_obs[i, ], sh[i, ]), 1)
})
tst_ok <- Reduce(`&`, lapply(tst_nse, function(x) !is.na(x)))

# ---- report ----------------------------------------------------------------------------------
num <- function(x, d = 3) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = d))
grp <- function(g, val) {
  vapply(v, function(x) {
    y <- x$summary[x$summary$group == g & x$summary$value == val, ]
    if (!nrow(y)) return(c(n = 0, share = NA_real_, month = NA_real_))
    c(n = y$n, share = y$nse_share_median, month = y$nse_month_median)
  }, numeric(3))
}
lines_grp <- function(g, vals) {
  unlist(lapply(vals, function(val) {
    m <- grp(g, val)
    sprintf("%-20s %4d   share NSE %s   monthly NSE %s", val, as.integer(m["n", "regression"]),
            paste(sprintf("%s %s", share_methods, num(m["share", share_methods])), collapse = "  "),
            paste(num(m["month", share_methods]), collapse = " / "))
  }))
}
r <- cvr$share_method_rule
cands <- setdiff(share_methods, "regression")
report <- wb_report("wb_share_donor", release)
writeLines(c(
  "# How the monthly shares are made (#102): regression, donor gauges and their blend, held out under blocked CV", "",
  sprintf("province run: %s; HYDAT release: %s; annual AET: %s; scores %s", basename(key_dir), release, aet,
          cvr$code_md5),
  sprintf("calibration gauges: %d; held-out months read from %s, nothing refitted; static predictors: %s", n,
          file.path(basename(fit_dir), sprintf("cv_aet-%s.rds", aet)), paste(static, collapse = ", ")),
  "",
  sprintf(paste("RULE (fixed in scripts/wb_validate.R's header before any candidate was coded or scored): donor or",
                "blend ships if its median share NSE beats the regression's by >= %.2f under blocked CV and in the",
                "leak-free pool (each held-out gauge's upstream and downstream training gauges removed, every",
                "method refitted); if both pass, the higher blocked-CV median. Over %d gauges:"), r$min_gain, r$n),
  sprintf("  %-10s %s", c("blocked CV", "leak-free"),
          c(paste(sprintf("%s %.4f", share_methods, r$median[share_methods]), collapse = ", "),
            paste(sprintf("%s %.4f", share_methods, r$median_leakfree[share_methods]), collapse = ", "))),
  sprintf("  gain over the regression (blocked CV / leak-free): %s -> %s",
          paste(sprintf("%s %+.4f / %+.4f%s", cands, r$gain[cands], r$gain_leakfree[cands],
                        ifelse(r$pass[cands], " (passes)", "")), collapse = ", "),
          if (cvr$share_method == "regression") "the regression STAYS" else sprintf("%s SHIPS", cvr$share_method)),
  "",
  "## Median share NSE and monthly-flow NSE (regression / donor / blend) per gauge, by group",
  "   (wet_flow_validate(); n excludes gauges with observed runoff under 10 mm)",
  lines_grp("all", "all"),
  lines_grp("nesting", c("headwater", "nested")),
  lines_grp("freshet", c("peak May-June", "peak other months")),
  lines_grp("lake", c("lake outlet", "not lake outlet")),
  lines_grp("wsc", c("WSC area 10", "other areas")),
  lines_grp("zone_named", c(paste("zone", zone_named), "other zones")),
  "# every zone",
  lines_grp("zone", sort(unique(groups$zone))),
  "",
  "## Median error of the monthly flow, percent, by month (gauges with flow that month)",
  sprintf("%-18s %s", "month", paste(sprintf("%6s", month.abb), collapse = "")),
  sprintf("%-18s %s", share_methods,
          vapply(shares, function(sh) paste(sprintf("%6.1f", month_err(sh)), collapse = ""), "")),
  sprintf("%-18s %s", paste("area 10", share_methods),
          vapply(shares, function(sh) {
            paste(sprintf("%6.1f", month_err(sh, groups$wsc == "WSC area 10")), collapse = "")
          }, "")),
  "",
  "## Gauges whose observed flow peaks in May or June, in their peak month",
  sprintf("%-14s %5s %22s %18s %22s", "", "n", "share below the gauge", "median error %", "same peak month"),
  sprintf("%-14s %5d %22.1f %18.1f %22.1f", names(ps), vapply(ps, function(x) as.integer(x[["n"]]), 1L),
          100 * vapply(ps, `[[`, 1, "below"), vapply(ps, `[[`, 1, "median_err"),
          100 * vapply(ps, `[[`, 1, "same_peak")),
  "",
  "## Short-record test gauges (1-9 complete years; no fit uses them), reported only",
  sprintf(paste("%d gauges with twelve observed months and observed runoff >= 10 mm, each predicted from the",
                "calibration gauges outside its sub-sub-drainage (%d of them); median share NSE over the %d every",
                "method scores (their observed shares rest on 1-9 years, so every method scores lower there):"),
          nrow(tst), length(unique(tst$subsubdrainage)), sum(tst_ok)),
  sprintf("  %s", paste(sprintf("%s %s", share_methods,
                                num(vapply(tst_nse, function(x) med(x[tst_ok]), 1), 4)), collapse = ", "))
), report)
message("report written: ", report)
