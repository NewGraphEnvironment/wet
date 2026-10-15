# The monthly shares with and without the snow predictors (#16), at the
# calibration gauges, from the held-out months scripts/wb_validate.R stores
# (#68). Nothing is refitted.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_share_snow.R [AET]   # default: the fit's AET winner
#
# Reads <fit>/cv_aet-<AET>.rds and writes the tracked report
# wb_report("wb_share_snow", release). The decision is wb_validate.R's (its
# rule and outcome are restated here); this report breaks the comparison
# down by month, by hydrologic zone (27-29 named in #16), at the gauges whose
# flow peaks in May or June, in WSC area 10 (the Liard) and at lake outlets.
#
# Where the fit made before #16 is set aside under data/wb/_pre16/, every AET
# variant scored in both must have an identical held-out annual (cv_ann): the
# snow layers are filled onto the analysis mask and enter the shares only, so
# the annual balance must not move. A difference stops the script.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
key_dir <- wb_key_dir()
release <- wb_release()
fit_dir <- wb_fit_dir(key_dir, release)
aet <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet)) aet <- readLines(file.path(fit_dir, "aet_winner.txt"))[1]
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", aet)))
need <- c("cv_shares", "share_spec", "share_rule", "obs_share", "zone", "lake")
if (!all(need %in% names(cvr))) {
  stop("cv_aet-", aet, ".rds predates #16 (no ", paste(setdiff(need, names(cvr)), collapse = ", "),
       "): rerun scripts/wb_validate.R")
}
stopifnot(identical(cvr$release, release), all(c("base", "snow") %in% names(cvr$cv_shares)))
shares <- cvr$cv_shares[c("base", "snow")]

# ---- the annual balance must not have moved ------------------------------------------------
old_fit <- Sys.glob(file.path("data", "wb", "_pre16", "*", paste0("fit_", release)))
ident <- character()
if (length(old_fit) > 1) stop("more than one set-aside fit_", release, " under data/wb/_pre16")
if (length(old_fit) == 1) {
  for (f in list.files(fit_dir, "^cv_aet-.*\\.rds$")) {
    of <- file.path(old_fit, f)
    if (!file.exists(of)) next
    a <- readRDS(file.path(fit_dir, f))
    b <- readRDS(of)
    same <- identical(a$station_number, b$station_number) && identical(a$cv_ann, b$cv_ann) &&
      identical(a$raw, b$raw) && identical(a$gate_pass, b$gate_pass)
    if (!same) stop(f, ": the held-out annual differs from the fit set aside in ", old_fit)
    ident <- c(ident, sub("^cv_aet-(.*)\\.rds$", "\\1", f))
  }
}

# ---- the held-out months, both specifications ----------------------------------------------
n <- length(cvr$station_number)
obs_m <- cvr$obs_share * cvr$obs
long_of <- function(sh) {
  rbind(data.frame(station_number = cvr$station_number, month = 0L, obs = cvr$obs, mod = cvr$cv_ann),
        data.frame(station_number = rep(cvr$station_number, 12), month = rep(1:12, each = n),
                   obs = as.vector(obs_m), mod = as.vector(sh * cvr$cv_ann)))
}
peak_obs <- max.col(cvr$obs_share, ties.method = "first")
groups <- data.frame(station_number = cvr$station_number,
                     zone = ifelse(cvr$zone %in% c("27", "28", "29"), paste("zone", cvr$zone), "other zones"),
                     zone_2729 = ifelse(cvr$zone %in% c("27", "28", "29"), "zones 27-29", "other zones"),
                     freshet = ifelse(peak_obs %in% 5:6, "peak May-June", "peak other months"),
                     wsc = ifelse(substr(cvr$station_number, 1, 2) == "10", "WSC area 10", "other areas"),
                     lake = cvr$lake)
v <- lapply(shares, function(sh) wet_flow_validate(long_of(sh), groups))
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
zero <- vapply(shares, function(sh) sum(sh * cvr$cv_ann == 0, na.rm = TRUE), numeric(1))

# ---- report ----------------------------------------------------------------------------------
num <- function(x, d = 3) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = d))
grp <- function(g, val) {
  vapply(v, function(x) {
    y <- x$summary[x$summary$group == g & x$summary$value == val, ]
    c(n = y$n, share = y$nse_share_median, month = y$nse_month_median)
  }, numeric(3))
}
lines_grp <- function(g, vals) {
  unlist(lapply(vals, function(val) {
    m <- grp(g, val)
    sprintf("%-22s %4d   share NSE %s -> %s (%+.3f)   monthly NSE %s -> %s", val, as.integer(m["n", "base"]),
            num(m["share", "base"]), num(m["share", "snow"]), m["share", "snow"] - m["share", "base"],
            num(m["month", "base"]), num(m["month", "snow"]))
  }))
}
r <- cvr$share_rule
report <- wb_report("wb_share_snow", release)
writeLines(c(
  "# Monthly shares with and without the snow predictors (#16), held out under blocked CV", "",
  sprintf("province run: %s; HYDAT release: %s; annual AET: %s; scores %s", basename(key_dir), release, aet,
          cvr$code_md5),
  sprintf("calibration gauges: %d; held-out months read from %s (#68), nothing refitted", n,
          file.path(basename(fit_dir), sprintf("cv_aet-%s.rds", aet))),
  sprintf("snow predictors: upstream means of ERA5-Land 1981-2010 snowmelt_doy_50 and swe_max (wet_snow_normals())"),
  "",
  sprintf(paste("RULE (fixed before the snow predictors were scored, scripts/wb_validate.R): keep them if the",
                "blocked-CV median share NSE (12 held-out shares against the observed, per gauge) rises by",
                ">= %.2f, over the gauges where both give one."), r$min_gain),
  sprintf("  base %.4f, snow %.4f, gain %+.4f over %d gauges -> %s", r$median[["base"]], r$median[["snow"]], r$gain,
          r$n_both, if (cvr$share_spec == "snow") "KEPT (the fit ships the snow predictors)" else "NOT kept"),
  if ("doy" %in% names(r$median)) sprintf("  not deciding: snowmelt_doy_50 alone %.4f", r$median[["doy"]]),
  if (length(ident)) {
    sprintf("held-out annual identical to the fit set aside before #16 (%s) for: %s", old_fit,
            paste(ident, collapse = ", "))
  } else {
    "no fit set aside before #16 to compare the held-out annual with"
  },
  "",
  "## Median share NSE and monthly-flow NSE per gauge, base -> snow (wet_flow_validate(); n excludes low gauges)",
  lines_grp("all", "all"),
  lines_grp("zone", c("zone 27", "zone 28", "zone 29", "other zones")),
  lines_grp("zone_2729", "zones 27-29"),
  lines_grp("freshet", c("peak May-June", "peak other months")),
  lines_grp("wsc", c("WSC area 10", "other areas")),
  lines_grp("lake", c("lake outlet", "not lake outlet")),
  "",
  "## Median error of the monthly flow, percent, by month (gauges with flow that month)",
  sprintf("%-14s %s", "month", paste(sprintf("%6s", month.abb), collapse = "")),
  sprintf("%-14s %s", c("base", "snow"),
          vapply(shares, function(sh) paste(sprintf("%6.1f", month_err(sh)), collapse = ""), "")),
  sprintf("%-14s %s", c("area 10 base", "area 10 snow"),
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
  sprintf("held-out gauge-months with zero predicted flow: base %d, snow %d (of %d)", zero[["base"]], zero[["snow"]],
          12L * n)
), report)
message("report written: ", report)
