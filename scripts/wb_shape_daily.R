# The balance's daily shape within the month (#70), fitted at the calibration
# gauges and scored held out in the blocked CV folds of the shipped fit. The
# rule below was fixed in this header before any candidate was coded or
# scored; the body that runs it came later (planning/archive, issue 70).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_shape_daily.R [AET]   # default: the fit's AET winner
#
# Reads <fit>/fits.rds, <fit>/cv_aet-<AET>.rds (the held-out monthly shares,
# #68) and data/wb/stations_<release>.rds, and HYDAT's daily flows at the
# calibration gauges. Writes <fit>/shape_daily.rds (the shipped shape),
# <fit>/cv_shape_daily.rds (every candidate's held-out shape per gauge) and
# the tracked report wb_report("wb_shape_daily", release). Nothing here is
# hashed by scripts/wb_score_md5.R, so the shipped fit's scores and decisions
# do not move; shape_daily.rds carries the fit's code_md5 and its own.
#
# ---- the product -----------------------------------------------------------------------------
#
# A watershed's published monthly mean flows Q[m] (m3/s, or mm/day) become
# daily flows on a 365-day common year, 29 February folded into 28 February
# (wet_flow_window()'s doy convention):
#
#   q[d] = Q[m(d)] * n[m(d)] * w[d],   d = 1..365,   n = c(31,28,31,30,31,30,31,31,30,31,30,31),
#   sum of w[d] over the days of each month = 1,
#
# so the mean of q over any calendar month is Q[m] exactly: the published
# months are kept, and this shape adds only where the water falls within the
# month (decided at the plan gate, 2026-10-17). w is the within-month weight;
# w * n is its ratio to flat (mean 1 in every month), the quantity the
# candidates work on. At a gauge the observed w is its day-of-year mean flow
# divided by the sum over its month's days (wet_station_doy() over the same
# complete years as wet_station_monthly()); a month of all-zero flow gets the
# flat w and is counted.
#
# ---- the candidates, every setting fixed here -----------------------------------------------
#
#   flat    w = 1 / n[m]. The incumbent: what wet_flow_window() gives from
#           monthly input today.
#   spline  a periodic cubic spline (stats::spline(method = "periodic"))
#           through the 12 monthly means at mid-month, floored at 0, then
#           rescaled month by month until each month's mean is preserved to a
#           relative 1e-9 (at most 100 passes; a month that does not converge,
#           or is all 0, falls back to flat and is counted). Needs no gauge.
#   donor   the inverse-distance mean of the within-month weights of the k = 5
#           nearest training gauges in static-predictor space: elev, e_km,
#           n_km, snowmelt_doy_50, swe_max (the shipped shares' static
#           predictors, #16), each divided by the training gauges' SD;
#           weights 1 / (dist + 1e-6 * median dist), an exact match taking
#           weight 1 alone; k capped at the number of training gauges;
#           renormalised per month.
#   basis   principal components of the training gauges' centred w * n, the
#           first 6, computed per fold on the training gauges alone; the
#           scores regressed by OLS on the 5 static predictors and the 12
#           monthly shares (observed at a training gauge; held-out cv_share at
#           a held-out gauge; the published shares at a segment), the issue's
#           "parametric curve whose freshet timing is predicted from snow
#           timing and the monthly predictors", generalised, since one
#           hand-written freshet family cannot cover coastal gauges that have
#           no freshet; reconstructed, floored at 0, renormalised per month; a
#           month all <= 0 falls back to flat and is counted.
#
# Sensitivity settings, reported and unable to ship (a winning sensitivity is
# a new rule in a new issue): donor k = 3 and 8; basis with 4 and 8
# components; basis on the static predictors plus p_yr and t_yr, without the
# shares.
#
# ---- the rule --------------------------------------------------------------------------------
#
# Per calibration gauge, in the blocked CV folds of the shipped fit
# (wet_cv_folds(), WSC sub-sub-drainage blocks, scripts/wb_cv_lib.R): donor
# and basis are fitted on the fold's training gauges and give the held-out
# gauge's w; spline and flat need no fit. With the gauge's OBSERVED monthly
# means Q (obs_share / wet_month_days()), the score is the NSE of
# q / mean(q) against q_obs / mean(q_obs) over the 365 days (wet:::wet_nse()),
# at gauges with observed runoff of at least 10 mm (wet_flow_validate()'s
# min_obs; on fit_20260717 every gauge passes, the least being 19.9 mm), over
# the gauges every candidate scores. The median over gauges decides: the
# candidate with the highest median ships if it exceeds flat's by at least
# 0.01 (unrounded, 1e-9 allowed for floating point; #16's margin). Otherwise
# nothing ships and shape_daily.rds records method "flat".
#
# Observed months, not the held-out ones, because the held-out months carry
# the same between-month error into every candidate, and that error would
# swamp the within-month term this shape adds. The same NSE with the held-out
# months (cv_share) is reported as the product's realistic skill.
#
# Reported, deciding nothing: the held-out-months NSE; the NSE of w * n
# itself (flat scores 0 there); medians by hydrologic zone, nesting
# (headwater / nested), leak_up > 0 and leak_down > 0, the gauge's peak month
# and lake outlets; a leak sensitivity for donor and basis that removes a
# held-out gauge's upstream and downstream training gauges from its pool
# (wet:::wet_fwa_upstream() on wscode and localcode, recomputed here); the
# issue's free day-of-year curve, the donor mean of the training gauges' doy
# shares with no month constraint, scored at daily NSE and, aggregated to
# months, against obs_share and cv_share; the sensitivity settings; and flow
# in the three Chinook windows of the monthly-flow article at 08EE013 and
# 08EE004 (calibration gauges) in two named columns, (a) observed months with
# the held-out w against the gauge's daily record as that article defines it
# (wet_window_stats() per-year window means; like for like with its 27 %) and
# (b) cv_ann * cv_share with the held-out w against the same record, beside
# the monthly-means estimate; 08EE003 is not a calibration gauge and appears
# from its record only.
#
# ---- what it refuses -------------------------------------------------------------------------
#
# A cv_aet-<AET>.rds or fits.rds scored under other code (code_md5 against
# score_code_md5), a fits.rds whose share_spec is not the cv file's, a cal
# whose stations are not the cv file's, a stations rds whose n_years differ
# from the complete years recomputed on the same HYDAT release (the stored
# rds carries no "years" attribute; it is recomputed with
# wet_station_select()), and a candidate whose monthly means are not
# reproduced by its daily flows to 1e-12. The report carries no timestamp, so
# a rerun reproduces it byte for byte.


# cal (with fold, nesting, leaks, zone, lake, shares), s, fit_dir, release, score_code_md5
source("scripts/wb_cv_lib.R")
aet <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(aet)) aet <- readLines(file.path(fit_dir, "aet_winner.txt"))[1]
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", aet)))
fits <- readRDS(file.path(fit_dir, "fits.rds"))
if (!identical(cvr$code_md5, score_code_md5)) {
  stop("cv_aet-", aet, ".rds was scored under other code: rerun scripts/wb_validate.R ", aet)
}
if (!identical(fits$code_md5, cvr$code_md5)) stop("fits.rds was made under other code than cv_aet-", aet, ".rds")
if (!identical(fits$share_spec, cvr$share_spec)) {
  stop("fits.rds ships another share specification than cv_aet-", aet, ".rds")
}
if (!identical(cvr$release, release)) stop("cv_aet-", aet, ".rds is for release ", cvr$release)
if (!identical(cal$station_number, cvr$station_number)) stop("the calibration stations are not the cv file's")
obs_sh <- as.matrix(cal[sprintf("share_%02d", 1:12)])
stopifnot(isTRUE(all.equal(unname(obs_sh), unname(cvr$obs_share))), !anyNA(cvr$cv_share), !anyNA(obs_sh))
n <- nrow(cal)
m <- wet:::wet_doy_month()
nd <- wet:::wet_doy_days()
days <- wet_month_days()
shape_files <- c("scripts/wb_shape_daily.R", sort(Sys.glob("R/wet_shape_*.R")), "R/wet_donor_mean.R", "R/wet_station_doy.R",
                 "R/wet_doy_month.R")
stopifnot(all(file.exists(shape_files)))
shape_code_md5 <- wet:::wet_md5_text(unname(tools::md5sum(shape_files)))

# ---- the gauges' day-of-year record ----------------------------------------------------------
# The stations rds lost its "years" attribute at a merge, so the complete years
# are recomputed on the same release with the same rule (scripts/wb_stations.R)
hydat <- wb_hydat(release)
sel <- wet_station_select(hydat, years = s$years, min_years = 10)
yrs <- attr(sel, "years")[cal$station_number]
if (anyNA(names(yrs)) || !all(lengths(yrs) == cal$n_years)) {
  stop("the recomputed complete years differ from the stations rds")
}
doy <- wet_station_doy(cal["station_number"], hydat, years = yrs)
stopifnot(nrow(doy) == 365L * n, !anyNA(doy$q_m3s))
q_obs <- matrix(doy$q_m3s, nrow = n, ncol = 365, byrow = TRUE,
                dimnames = list(unique(doy$station_number), NULL))[cal$station_number, ]
w_obs <- wet:::wet_shape_within(q_obs)
n_filled <- nrow(attr(doy, "filled"))
n_flat_obs <- sum(attr(w_obs, "flat"))
stamp(n, " gauges with a day-of-year record; ", n_filled, " gauge-days interpolated; ", n_flat_obs,
      " observed gauge-months with no flow")

# ---- monthly means the shape is laid on -------------------------------------------------------
# relative monthly means (mm/day up to the annual, which the shape score cancels)
q_m_obs <- sweep(obs_sh, 2, days, "/")
q_m_cv <- sweep(cvr$cv_share, 2, days, "/")
static <- share_static$snow
stopifnot(identical(fits$share_spec, "snow"))  # the header calls these the shipped shares' static predictors
static_pt <- c(static, "p_yr", "t_yr")
stopifnot(all(c(static_pt) %in% names(cal)), !anyNA(cal[static_pt]))

# ---- candidates, held out ---------------------------------------------------------------------
# upstream relation between the calibration gauges, for the leak sensitivity
# (as wet_cv_folds() computes it; that file is hashed and stays unedited)
up <- matrix(FALSE, n, n)
for (i in seq_len(n)) up[i, ] <- wet:::wet_fwa_upstream(cal$wscode[i], cal$localcode[i], cal$wscode, cal$localcode)
diag(up) <- FALSE
related <- up | t(up)  # related[i, j]: j is upstream or downstream of i

settings <- list(
  donor = list(method = "donor", k = 5, static = static, shares = FALSE),
  basis = list(method = "basis", n_comp = 6, static = static, shares = TRUE),
  donor_k3 = list(method = "donor", k = 3, static = static, shares = FALSE),
  donor_k8 = list(method = "donor", k = 8, static = static, shares = FALSE),
  basis_c4 = list(method = "basis", n_comp = 4, static = static, shares = TRUE),
  basis_c8 = list(method = "basis", n_comp = 8, static = static, shares = TRUE),
  basis_static = list(method = "basis", n_comp = 6, static = static_pt, shares = FALSE)
)
shippable <- c("flat", "spline", "donor", "basis")
fit_of <- function(st, tr) {
  wet_shape_fit(cal[tr, ], w_obs[tr, , drop = FALSE], st$method, static = st$static,
                k = if (is.null(st$k)) 5 else st$k, n_comp = if (is.null(st$n_comp)) 6 else st$n_comp,
                shares = if (st$shares) obs_sh[tr, , drop = FALSE] else NULL)
}
predict_of <- function(fit, st, te) {
  wet_shape_predict(fit, cal[te, , drop = FALSE], shares = if (st$shares) cvr$cv_share[te, , drop = FALSE] else NULL)
}
fold <- cal$fold
held <- lapply(settings, function(st) matrix(NA_real_, n, 365))
n_fallback <- stats::setNames(integer(length(settings)), names(settings))
for (f in unique(fold)) {
  te <- which(fold == f)
  tr <- which(fold != f)
  for (k in names(settings)) {
    w <- predict_of(fit_of(settings[[k]], tr), settings[[k]], te)
    held[[k]][te, ] <- w
    n_fallback[[k]] <- n_fallback[[k]] + sum(attr(w, "flat"))
  }
}
held$flat <- wet_shape_flat(n)
held$spline <- wet_shape_spline(q_m_obs)      # through the observed months (the rule's setting)
spline_cv <- wet_shape_spline(q_m_cv)         # through the held-out months (the product's setting)
# the flatbk column counts held-out gauge-months, so the spline's count is spline_cv's
n_fallback[["spline"]] <- sum(attr(spline_cv, "flat"))
n_fallback_spline_obs <- sum(attr(held$spline, "flat"))
stamp("held-out shapes for ", length(settings), " fitted settings in ", length(unique(fold)), " folds")

# leak sensitivity: for donor and basis, each held-out gauge's pool loses the
# training gauges upstream or downstream of it
leak <- lapply(settings[c("donor", "basis")], function(st) matrix(NA_real_, n, 365))
for (i in seq_len(n)) {
  tr <- which(fold != fold[i] & !related[i, ])
  for (k in names(leak)) leak[[k]][i, ] <- predict_of(fit_of(settings[[k]], tr), settings[[k]], i)
}

# the issue's free day-of-year curve: the donor mean of the training gauges'
# doy shares, with no month constraint (donor's k, the same distance)
free <- matrix(NA_real_, n, 365)
sh_obs_doy <- q_obs / rowSums(q_obs)
for (f in unique(fold)) {
  te <- which(fold == f)
  tr <- which(fold != f)
  # wet_shape_fit() only carries weights, so the distance weighting is reproduced here
  xs <- scale(as.matrix(cal[tr, static]), center = FALSE, scale = apply(as.matrix(cal[tr, static]), 2, stats::sd))
  for (i in te) {
    r <- as.numeric(as.matrix(cal[i, static])) / attr(xs, "scaled:scale")
    dist <- sqrt(colSums((t(xs) - r)^2))
    o <- order(dist)[seq_len(settings$donor$k)]
    wt <- 1 / (dist[o] + 1e-6 * stats::median(dist))
    free[i, ] <- colSums(sh_obs_doy[tr[o], , drop = FALSE] * wt) / sum(wt)
  }
}
free_months <- t(apply(free, 1, function(r) tapply(r, m, sum)))

# ---- scores -----------------------------------------------------------------------------------
nse <- wet:::wet_nse
# the shape score: daily flows from monthly means Q and weights w, each scaled
# by its own mean, against the gauge's days scaled by theirs
shape_nse <- function(q_month, w) {
  q <- wet_shape_daily(q_month, w)
  # every candidate reproduces the monthly means it was laid on
  back <- t(apply(q, 1, function(r) tapply(r, m, mean)))
  if (max(abs(back / q_month - 1), na.rm = TRUE) > 1e-12) stop("a candidate does not keep the monthly means")
  vapply(seq_len(n), function(i) nse(q_obs[i, ] / mean(q_obs[i, ]), q[i, ] / mean(q[i, ])), numeric(1))
}
w_nse <- function(w) vapply(seq_len(n), function(i) nse(w_obs[i, ] * nd[m], w[i, ] * nd[m]), numeric(1))
scored <- cal$obs >= 10
nse_obs <- lapply(held, function(w) shape_nse(q_m_obs, w))
nse_cv <- lapply(held, function(w) shape_nse(q_m_cv, w))
nse_cv$spline <- shape_nse(q_m_cv, spline_cv)
nse_w <- lapply(held, w_nse)
nse_leak <- lapply(leak, function(w) shape_nse(q_m_obs, w))
nse_free_day <- vapply(seq_len(n), function(i) nse(sh_obs_doy[i, ], free[i, ]), numeric(1))
nse_free_month <- vapply(seq_len(n), function(i) nse(obs_sh[i, ], free_months[i, ]), numeric(1))
nse_cv_month <- vapply(seq_len(n), function(i) nse(obs_sh[i, ], cvr$cv_share[i, ]), numeric(1))
all_scored <- scored & Reduce(`&`, lapply(nse_obs, function(x) !is.na(x)))
med <- function(x, sel = all_scored) if (any(sel)) stats::median(x[sel]) else NA_real_
med_obs <- vapply(nse_obs, med, numeric(1))
med_cv <- vapply(nse_cv, med, numeric(1))
med_w <- vapply(nse_w, med, numeric(1))

# ---- the rule ---------------------------------------------------------------------------------
min_gain <- 0.01
best <- names(which.max(med_obs[shippable]))
gain <- med_obs[[best]] - med_obs[["flat"]]
ship <- if (best != "flat" && gain >= min_gain - 1e-9) best else "flat"
stamp("medians (observed months): ", paste(sprintf("%s %.4f", shippable, med_obs[shippable]), collapse = ", "),
      "; best ", best, ", gain ", sprintf("%+.4f", gain), " -> ships ", ship)

# ---- breakdowns -------------------------------------------------------------------------------
peak <- max.col(obs_sh, ties.method = "first")
groups_of <- list(
  nesting = cal$nesting,
  leak_up = ifelse(cal$leak_up > 0, "leak_up > 0", "leak_up = 0"),
  leak_down = ifelse(cal$leak_down, "leak_down", "no leak_down"),
  peak = ifelse(peak %in% 5:6, "peak May-June", "peak other months"),
  lake = cvr$lake,
  zone = paste("zone", cvr$zone)
)
group_lines <- function(name, g) {
  vals <- sort(unique(g))
  vapply(vals, function(v) {
    sel <- all_scored & g == v
    meds <- vapply(nse_obs[shippable], med, numeric(1), sel = sel)
    sprintf("%-20s %4d  %s", v, sum(sel), paste(sprintf("%s %.3f", shippable, meds), collapse = "  "))
  }, "")
}

# which candidate leads each group, computed, so the prose can quote it rather than read a rounded table
leader_of <- function(sel) {
  meds <- sort(vapply(nse_obs[shippable], med, numeric(1), sel = sel), decreasing = TRUE)
  margin <- meds[[1]] - meds[[2]]
  list(name = if (margin < 1e-6) sprintf("tie %s/%s", names(meds)[1], names(meds)[2]) else names(meds)[1],
       runner = names(meds)[2], margin = margin)
}
leader_lines <- function(g) {
  vapply(sort(unique(g)), function(v) {
    sel <- all_scored & g == v
    l <- leader_of(sel)
    gain_v <- med(nse_obs[[ship]], sel) - med(nse_obs$flat, sel)
    sprintf("%-20s %4d  %-8s %+.4f over %-7s %s over flat %+.4f", v, sum(sel), l$name, l$margin, l$runner, ship, gain_v)
  }, "")
}
zone_vals <- sort(unique(groups_of$zone))
zone_lead <- vapply(zone_vals, function(v) leader_of(all_scored & groups_of$zone == v)$name, "")
lead_count <- table(factor(zone_lead, levels = c(shippable, setdiff(unique(zone_lead), shippable))))
lead_count <- lead_count[lead_count > 0]
gain_zone <- vapply(zone_vals, function(v) {
  sel <- all_scored & groups_of$zone == v
  med(nse_obs[[ship]], sel) - med(nse_obs$flat, sel)
}, numeric(1))
gain_top <- sort(gain_zone, decreasing = TRUE)[1:5]

# ---- the Chinook windows at the Bulkley gauges -----------------------------------------------
lh <- utils::read.csv(system.file("vignette-data", "life_history_bulk.csv", package = "wet"))
ch <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning", "fry_migration"), ]
stopifnot(nrow(ch) == 3)
windows <- data.frame(window = sub("_", " ", ch$life_stage), start = ch$start, end = ch$end)
ck_st <- c("08EE013", "08EE004", "08EE003")
# the report's text says which of them the balance is calibrated on
stopifnot(c("08EE013", "08EE004") %in% cal$station_number, !"08EE003" %in% cal$station_number)
rec <- wet_station_daily(ck_st, hydat, from = sprintf("%d-01-01", min(s$years)), to = sprintf("%d-12-31", max(s$years)),
                         sources = "hydat")
ws <- wet_window_stats(rec[c("station_number", "date", "q_m3s")], windows, stats = "mean")
rec$year <- as.integer(format(rec$date, "%Y"))
rec$month <- as.integer(format(rec$date, "%m"))
ck_rows <- do.call(rbind, lapply(ck_st, function(st) {
  i <- match(st, cal$station_number)
  do.call(rbind, lapply(seq_len(nrow(windows)), function(k) {
    w <- windows[k, ]
    sel <- ws$station_number == st & ws$period == w$window
    yr <- ws$year[sel]
    if (!length(yr)) return(NULL)
    # the observed months over the same years as the window's daily means
    om <- stats::aggregate(q_m3s ~ month, rec[rec$station_number == st & rec$year %in% yr, ], mean)
    om <- om$q_m3s[match(1:12, om$month)]  # NA in the months a seasonal gauge never records
    stopifnot(is.na(i) || !anyNA(om))
    win_of <- function(q_doy) wet_flow_window(data.frame(doy = 1:365, q_m3s = q_doy), w, by = character())$q_m3s
    from_months <- wet_flow_window(data.frame(month = 1:12, q_m3s = om), w, by = character())$q_m3s
    # (a) the observed months with the held-out weights; (b) the held-out balance with them
    shape_a <- if (is.na(i)) NA_real_ else win_of(wet_shape_daily(om, held[[ship]][i, , drop = FALSE])[1, ])
    to_m3s <- if (is.na(i)) NA_real_ else cal$upstream_area_m2[i] / 1000 / 86400  # mm/day over the basin to m3/s
    q_cv_m3s <- if (is.na(i)) NA_real_ else cvr$cv_ann[i] * cvr$cv_share[i, ] / days * to_m3s
    shape_b <- if (is.na(i)) NA_real_ else win_of(wet_shape_daily(q_cv_m3s, held[[ship]][i, , drop = FALSE])[1, ])
    data.frame(station_number = st, window = w$window, years = length(yr), daily_record = mean(ws$value[sel]),
               from_months = from_months, shape_a = shape_a, shape_b = shape_b)
  }))
}))
pct <- function(x, ref) 100 * (x / ref - 1)

# ---- artifacts --------------------------------------------------------------------------------
ship_fit <- if (ship %in% names(settings)) fit_of(settings[[ship]], seq_len(n)) else NULL
saveRDS(list(method = ship, fit = ship_fit, setting = settings[[ship]], static = static, aet = aet,
             rule = list(min_gain = min_gain, median = med_obs[shippable], best = best, gain = gain,
                         n = sum(all_scored)),
             release = release, code_md5 = fits$code_md5, shape_code_md5 = shape_code_md5),
        file.path(fit_dir, "shape_daily.rds"))
saveRDS(list(station_number = cal$station_number, held = held, spline_cv = spline_cv, leak = leak, free = free,
             w_obs = w_obs, q_obs = q_obs, nse_obs = nse_obs, nse_cv = nse_cv, nse_w = nse_w, nse_leak = nse_leak,
             nse_free_day = nse_free_day, nse_free_month = nse_free_month, nse_cv_month = nse_cv_month,
             scored = all_scored, zone = cvr$zone, nesting = cal$nesting, leak_up = cal$leak_up,
             leak_down = cal$leak_down, lake = cvr$lake, peak = peak, chinook = ck_rows, ship = ship, aet = aet,
             release = release, code_md5 = fits$code_md5, shape_code_md5 = shape_code_md5),
        file.path(fit_dir, "cv_shape_daily.rds"))

# ---- report -----------------------------------------------------------------------------------
num <- function(x, d = 4) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = d))
line_of <- function(k) {
  sprintf("%-14s %s %s %s %s", k, num(med_obs[[k]]), num(med_cv[[k]]), num(med_w[[k]]),
          if (k %in% names(n_fallback)) sprintf("%6d", n_fallback[[k]]) else "     -")
}
report <- wb_report("wb_shape_daily", release)
writeLines(c(
  "# The balance's daily shape within the month (#70), held out under blocked CV", "",
  sprintf("province run: %s; HYDAT release: %s; annual AET: %s; fit scores %s; shape code %s", basename(key_dir),
          release, aet, fits$code_md5, shape_code_md5),
  sprintf("calibration gauges: %d, scored %d (observed runoff >= 10 mm, every candidate scored); folds: %d", n,
          sum(all_scored), length(unique(fold))),
  sprintf("day-of-year record: %d gauge-days interpolated (wet_station_doy()); %d observed gauge-months with no flow",
          n_filled, n_flat_obs),
  "",
  paste("RULE (fixed in this script's header before any candidate existed): per gauge, the NSE of the 365 daily",
        "flows laid on the gauge's OBSERVED monthly means (q / mean(q) against the record's q_obs / mean(q_obs));",
        "the candidate with the highest median ships if it exceeds flat's by >= 0.01."),
  sprintf("  %s", paste(sprintf("%s %.4f", shippable, med_obs[shippable]), collapse = ", ")),
  sprintf("  best %s, gain over flat %+.4f over %d gauges -> %s", best, gain, sum(all_scored),
          if (ship == "flat") "NOTHING SHIPS (the shape stays flat)" else sprintf("SHIPS %s", ship)),
  "",
  "## Median per-gauge NSE: observed months (the rule), held-out months (the product), the weights alone (flat = 0)",
  sprintf("%-14s %6s %6s %6s %6s", "candidate", "obs_m", "cv_m", "w", "flatbk"),
  vapply(shippable, line_of, ""),
  "sensitivity settings (reported, unable to ship):",
  vapply(setdiff(names(settings), shippable), line_of, ""),
  "  flatbk: held-out gauge-months whose reconstruction fell back to flat",
  "",
  "## Leak sensitivity: the held-out gauge's upstream and downstream training gauges removed from its pool",
  "   (observed months)",
  sprintf("%-14s with %s  without %s  (%d gauges)", names(nse_leak), num(med_obs[names(nse_leak)]),
          num(vapply(nse_leak, med, numeric(1))), sum(all_scored)),
  "",
  sprintf("## The issue's free day-of-year curve (donor mean of doy shares, k = %d, no month constraint),",
          settings$donor$k),
  "   reported only",
  sprintf("median NSE of the 365 daily shares against the record: %s (within-month %s on held-out months: %s)",
          num(med(nse_free_day)), ship, num(med_cv[[ship]])),
  sprintf("median NSE of its 12 months against the observed shares: %s; the shipped held-out shares (cv_share): %s",
          num(med(nse_free_month)), num(med(nse_cv_month))),
  "",
  "## Median NSE (observed months) by group",
  unlist(lapply(names(groups_of), function(g) c(sprintf("# %s", g), group_lines(g, groups_of[[g]])))),
  "",
  "## Leader by group: the candidate with the highest median (observed months), its margin over the runner-up",
  "   (a difference under 1e-6 is a tie), and the shipped candidate's gain over flat",
  unlist(lapply(names(groups_of), function(g) leader_lines(groups_of[[g]]))),
  sprintf("zones led: %s", paste(sprintf("%s %d", names(lead_count), lead_count), collapse = ", ")),
  sprintf("largest gains of %s over flat by zone: %s", ship,
          paste(sprintf("%s %+.3f", names(gain_top), gain_top), collapse = ", ")),
  sprintf("spline fallbacks to flat on the observed months: %d gauge-months", n_fallback_spline_obs),
  "",
  sprintf("## Flow in the Chinook windows at the Bulkley gauges (m3/s), %d-%d years with the window's days",
          min(s$years), max(s$years)),
  "   daily_record: the gauge, mean of per-year window means (wet_window_stats()); from_months: those years' observed",
  sprintf("   months spread flat (today's reader); shape_a: the same months with the held-out %s weights;", ship),
  "   shape_b: the held-out balance (cv_ann x cv_share) with them. 08EE003 is not a calibration gauge: record only.",
  sprintf("%-8s %-14s %5s %12s %11s %7s %11s %7s %11s %7s", "gauge", "window", "years", "daily_record", "from_months",
          "err%", "shape_a", "err%", "shape_b", "err%"),
  sprintf("%-8s %-14s %5d %12.2f %11.2f %7.1f %11s %7s %11s %7s", ck_rows$station_number, ck_rows$window, ck_rows$years,
          ck_rows$daily_record, ck_rows$from_months, pct(ck_rows$from_months, ck_rows$daily_record),
          num(ck_rows$shape_a, 2), num(pct(ck_rows$shape_a, ck_rows$daily_record), 1),
          num(ck_rows$shape_b, 2), num(pct(ck_rows$shape_b, ck_rows$daily_record), 1)),
  "",
  sprintf("artifacts: %s (method %s), %s", file.path(basename(fit_dir), "shape_daily.rds"), ship,
          file.path(basename(fit_dir), "cv_shape_daily.rds"))
), report)
message("report written: ", report)
