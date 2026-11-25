# Water temperature at a station with no record (#213): air2stream parameters predicted from
# catchment traits, with a whole station held out at a time.
#
#   Rscript scripts/temp_baseline.R
#
# ---- The rule -------------------------------------------------------------------------------
# Registered in this header and in scripts/temp_baseline_rule.R before any real score was
# computed; the thresholds are the owner's (2026-11-25). Registered at 914259d6.
# Amendment 1, also before any real score (no candidate had predicted a real station): the truth
# set's exclusions, the series a run starts on, which station-years the statistic reads, and the
# code the recovery guard names, each marked (A1) below. No threshold moved.
#
# Truth. The station-years of scripts/temp_fill_validate.R (1 March - 30 November observed with
#   no gap longer than 2 days), at the stations the holdout frame keeps
#   (scripts/temp_baseline_traits.R: snapped to the FWA, at least 95 % of the basin inside BC
#   and on the trait grids).
#   (A1) Not a truth year: one whose observed 1 March - 30 November daily means have a standard
#   deviation under 0.1 degC (a sensor reading one value). Not kept: a station outside the
#   pinned HYDAT release (no gross drainage area to snap against), one with no truth year left,
#   and one with fewer than 365 observed days with air, which wet_temp_fill() does not fit.
# Held out. A whole station: its parameters are predicted from other stations only.
# Parameters. Open-loop air2stream, S[t] = S[t-1] + a1 + a2 A[t] - a3 S[t-1], as wet_temp_fill()
#   fits it. A candidate predicts theta = (a1 / a3, a2 / a3, qlogis(a3)): the equilibrium
#   intercept, the equilibrium slope and the response rate. theta is turned back to a1, a2, a3.
# Candidates.
#   mean        the training stations' mean theta (what a model with no covariates gives)
#   regression  ordinary least squares of each theta on the traits
#   donor       wet:::wet_donor_mean() over the k = 5 nearest training stations in trait space,
#               the traits z-scored on the training stations
# Traits. Upstream means of elevation, easting, northing, snowmelt_doy_50 and swe_max; log10
#   upstream area; glacier cover and lake cover (lakes and reservoirs), each a share of
#   upstream area.
# Pools.
#   blocked     wet_cv_folds(): the stations of one WSC sub-sub-drainage are held out together
#   leak-free   each held-out station is predicted from its fold's training stations less those
#               upstream or downstream of it, with every candidate refitted
# Run. wet:::wet_a2s_run() with the predicted parameters on the station's own daily air.
#   (A1) Every run, the benchmark's included, is over the calendar wet:::wet_fill_prepare()
#   gives the station (its whole record, air interpolated across gaps of up to 3 days), from
#   that calendar's first day.
# Benchmark. The same run with the station's own parameters, fitted to its whole record.
# Scores, per station-year. Daily RMSE on the observed days of 1 March - 30 November, and GSDD
#   error: wet_temp_gsdd() on the predicted series against the observed year.
#   (A1) The statistic reads the station-years in which the observed year and every candidate's
#   and the benchmark's predicted year have a GSDD, in both pools; the number left out is
#   printed.
#
# The statistic the rule reads, for each candidate and pool and for the benchmark: the mean,
# over held-out stations, of the station's mean absolute GSDD error over its truth years
# (degC-days).
#
# 1. Which candidate is reported as the baseline. The population mean, unless a trait candidate
#    (regression, donor) beats it by at least 10 degC-days in both pools. When both do, the one
#    with the lower leak-free score; regression when the two are equal at one decimal.
# 2. Close. The baseline is close to the benchmark when its score is within 50 degC-days of the
#    benchmark's in both pools: half the width of the band between the cutthroat thresholds
#    (under 800 degree days unsuitable, 900 and over best). Within 50 in one pool only is
#    reported as that, and is not close.
# 3. A difference exactly on a threshold counts: 10 displaces, 50 is close.
# 4. A candidate scored later on this frame (network kriging, #223) is scored in both pools and
#    reported beside the baseline. It does not become the baseline under this rule.
#
# Printed beside the rule and deciding nothing: the relative gap to the benchmark; the same
# means taken over station-years; daily RMSE and bias; the hidden-season score of
# scripts/temp_fill_validate.R on the station-years both have; the breakdowns by WSC
# sub-drainage, lake influence, glacier cover and HYDAT's regulation flag; and how often each
# candidate's interval holds the station's own theta.
#
# Recovery first. This script refuses to score unless data/checks/temp_baseline_recover.txt is
# committed and names (A1) the md5 of the code a score depends on as it stands (tb_code_md5()
# in scripts/temp_baseline_lib.R) and the holdout frame it ran on
# (scripts/temp_baseline_recover.R: every candidate on stations simulated from known
# trait-to-parameter relationships with a part shared along the stream network).
# ---------------------------------------------------------------------------------------------

# Needs data/temp_fill/ (scripts/temp_fill_validate.R's caches) and the frame. Writes
# data/checks/temp_baseline.txt (byte-identical on a rerun) and data/temp_baseline/scores_<frame>.rds,
# which a later candidate is scored against.

devtools::load_all(quiet = TRUE)
source("scripts/temp_baseline_rule.R")
source("scripts/temp_baseline_lib.R")
code <- tb_code_md5()
options(width = 200)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
stopifnot(requireNamespace("gsdd", quietly = TRUE))

# ---- recovery first -----------------------------------------------------------------------------
fr <- tb_frame_read()
f_recover <- file.path("data", "checks", "temp_baseline_recover.txt")
if (!file.exists(f_recover)) stop(f_recover, " is missing: run scripts/temp_baseline_recover.R", call. = FALSE)
tracked <- suppressWarnings(system2("git", c("ls-files", "--error-unmatch", "--", f_recover), stdout = TRUE,
                                    stderr = TRUE))
dirty <- system2("git", c("status", "--porcelain", "--", f_recover), stdout = TRUE)
if (!is.null(attr(tracked, "status")) || length(dirty)) {
  stop(f_recover, " is not committed as it stands: commit the recovery run before scoring", call. = FALSE)
}
rec <- readLines(f_recover)
named <- function(tag) sub(paste0("^", tag, ": "), "", grep(paste0("^", tag, ": "), rec, value = TRUE))
if (!identical(named("frame"), fr$key)) stop("the recovery ran on another frame: ", named("frame"), call. = FALSE)
if (!identical(named("code"), code)) {
  stop("the code a score depends on changed since the recovery run: run scripts/temp_baseline_recover.R again",
       call. = FALSE)
}
if (!any(grepl("^Leak-free check .*: PASS$", rec))) stop("the recovery's leak-free check did not pass", call. = FALSE)

# ---- stations, their own fits and the held-out predictions -----------------------------------------
st <- fr$stations
n <- nrow(st)
x <- as.matrix(st[tb_traits])
rownames(x) <- st$station_number
water <- readRDS(file.path("data", "temp_fill", "water_2002_2025.rds"))
air <- readRDS(file.path("data", "temp_fill", "air_2002_2025.rds"))
water <- water[water$station_number %in% st$station_number, ]
air <- air[air$id %in% st$station_number, ]
prep <- wet:::wet_fill_prepare(water, air, stats::setNames(substr(st$station_number, 1, 3), st$station_number),
                               NULL, NULL, 365, 0.1^2)
stopifnot(all(st$station_number %in% prep$fit_st))
series <- prep$series[st$station_number]
own <- t(vapply(st$station_number, function(s) prep$open[[s]]$par, numeric(3)))
# the fits the recovery took its scale from
stopifnot(isTRUE(all.equal(unname(own), unname(as.matrix(fr$fit[c("a1", "a2", "a3")])), tolerance = 1e-12)))
th <- tb_theta(own)
pools <- tb_pools
cv <- stats::setNames(lapply(pools, function(p) tb_cv(x, th, st$fold, fr$related, p)), pools)
runs <- list(benchmark = th)
for (p in pools) for (m in tb_methods) runs[[paste(p, m)]] <- cv[[p]][[m]]$mean
stamp(n, " stations; ", length(runs), " runs each")

# ---- scores ---------------------------------------------------------------------------------------------
v <- new.env()
tb_take("scripts/temp_fill_validate.R", "gsdd_year", v)
years <- split(fr$truth$year, factor(fr$truth$station_number, levels = st$station_number))
sc <- do.call(rbind, lapply(seq_len(n), function(i) {
  z <- series[[i]]
  # the benchmark is the fit wet_temp_fill() made: the same error over every observed day
  s_own <- tb_run(z, own[i, ])
  o <- !is.na(z$y)
  stopifnot(isTRUE(all.equal(sqrt(mean((s_own[o] - z$y[o])^2)), prep$open[[i]]$rmse, tolerance = 1e-10)),
            identical(names(prep$open)[i], st$station_number[i]))
  obs <- tb_gsdd_observed(z, years[[i]], v$gsdd_year)
  do.call(rbind, lapply(names(runs), function(w) {
    p <- tb_theta_inv(runs[[w]][i, , drop = FALSE])[1, ]
    cbind(station_number = st$station_number[i], run = w, tb_score(z, tb_run(z, p), years[[i]], v$gsdd_year),
          gsdd_obs = obs)
  }))
}))
stamp(nrow(sc), " scores")
stat <- tb_statistic(sc, names(runs))
paired <- stat$paired
left_out <- stat$left_out
d <- stat$scores
d$err <- d$gsdd - d$gsdd_obs
stopifnot(nrow(d) == length(paired) * length(runs))

# per run: the statistic (by station), and what is printed beside it
by_station <- stat$by_station
summ <- data.frame(
  run = names(runs),
  gsdd_mae = stat$statistic[names(runs)],
  gsdd_mae_median_station = apply(by_station, 2, stats::median),
  gsdd_mae_station_year = tapply(abs(d$err), d$run, mean)[names(runs)],
  gsdd_bias = tapply(d$err, d$run, mean)[names(runs)],
  rmse = tapply(d$rmse, d$run, mean)[names(runs)],
  bias = tapply(d$bias, d$run, mean)[names(runs)])
benchmark <- summ$gsdd_mae[summ$run == "benchmark"]
summ$gap <- summ$gsdd_mae - benchmark
summ$gap_pct <- 100 * summ$gap / benchmark
rownames(summ) <- NULL
scores <- data.frame(candidate = rep(tb_methods, length(pools)), pool = rep(pools, each = length(tb_methods)))
scores$gsdd_mae <- summ$gsdd_mae[match(paste(scores$pool, scores$candidate), summ$run)]
verdict <- tb_verdict(scores, benchmark)

# ---- theta: what the traits explain, and the intervals ------------------------------------------------
theta_tab <- do.call(rbind, lapply(pools, function(p) {
  do.call(rbind, lapply(tb_methods, function(m) {
    r <- cv[[p]][[m]]
    iv <- tb_interval(r)
    data.frame(pool = p, method = m, theta = tb_theta_names, rmse = sqrt(colMeans((r$mean - th)^2)),
               r2 = 1 - colSums((r$mean - th)^2) / colSums(sweep(th, 2, colMeans(th))^2),
               cover = colMeans(th >= iv$lo & th <= iv$hi))
  }))
}))
rownames(theta_tab) <- NULL

# ---- context: the hidden-season score of scripts/temp_fill_validate.R ---------------------------------
hs <- readRDS(file.path("data", "temp_fill", "validate_scores.rds"))
hs <- hs[hs$shape == "season" & hs$method == "open", ]
b <- d[d$run == "benchmark", ]
common <- intersect(paste(hs$station_number, hs$year), paste(b$station_number, b$year))
hs_mae <- mean(abs(hs$gsdd_err[match(common, paste(hs$station_number, hs$year))]))
b_mae <- mean(abs(b$err[match(common, paste(b$station_number, b$year))]))

# ---- breakdowns ---------------------------------------------------------------------------------------------
breakdown <- function(class) {
  class <- class[match(rownames(by_station), st$station_number)]
  out <- do.call(rbind, lapply(sort(unique(class)), function(g) {
    data.frame(class = g, stations = sum(class == g), t(colMeans(by_station[class == g, , drop = FALSE])),
               check.names = FALSE)
  }))
  names(out) <- sub("^blocked ", "b.", sub("^leakfree ", "lf.", names(out)))
  out
}
cut3 <- function(v) {
  as.character(cut(v, c(-Inf, 0.01, 0.05, Inf), labels = c("under 1 %", "1 to 5 %", "over 5 %"), right = FALSE))
}
bd <- list(
  "WSC sub-drainage" = breakdown(substr(st$station_number, 1, 3)),
  "lake outlet (a lake of 100 ha or more within 3 km upstream, draining most of the basin)" =
    breakdown(ifelse(st$lake %in% TRUE, "lake outlet", "not a lake outlet")),
  "lake and reservoir cover of the upstream area" = breakdown(cut3(st$lake_cover)),
  "glacier cover of the upstream area" = breakdown(ifelse(st$glacier > 0, "some", "none")),
  "HYDAT regulation flag" = breakdown(st$regulated))

# ---- store and report -----------------------------------------------------------------------------------------
f_scores <- file.path("data", "temp_baseline", sprintf("scores_%s.rds", fr$key))
tb_code_same(code)
saveRDS(list(frame = fr$key, code = code, scores = sc, paired = paired, summary = summ, theta = th,
             cv = cv, verdict = verdict, benchmark = benchmark), f_scores)
fmt <- function(x, digits = 3) utils::capture.output(print(x, row.names = FALSE, digits = digits))
lines <- c(
  "Whole-station temperature baseline (#213): air2stream parameters predicted from catchment traits",
  sprintf("frame: %s", fr$key),
  sprintf("code: %s", code),
  sprintf("gsdd %s", utils::packageVersion("gsdd")),
  sprintf("stations %d; truth station-years %d; read by the statistic %d at %d stations; left out (no GSDD in some series) %d",
          n, nrow(fr$truth), length(paired), nrow(by_station), left_out),
  "",
  "## Scores by run (GSDD in degC-days, daily RMSE and bias in degC)",
  "gsdd_mae is the rule's statistic: the mean over stations of each station's mean absolute GSDD error;",
  "gap is to the benchmark, the station's own parameters; b. is blocked CV, lf. the leak-free pool below",
  fmt(summ), "",
  "## The rule's outcome", verdict$text, "",
  "## Context, deciding nothing",
  sprintf(paste("station-years the hidden-season holdout of scripts/temp_fill_validate.R also scored: %d;",
                "GSDD mean absolute error there: own parameters from the whole record %.1f,",
                "from the record without that season %.1f degC-days"), length(common), b_mae, hs_mae),
  "",
  "## Held-out theta against the stations' own: error, share of variance explained, 90 % interval coverage",
  fmt(theta_tab), "",
  unlist(lapply(names(bd), function(k) {
    c(sprintf("## GSDD mean absolute error by station, by %s (degC-days)", k), fmt(bd[[k]], 4), "")
  })))
writeLines(lines, file.path("data", "checks", "temp_baseline.txt"))
cat(lines, sep = "\n")
