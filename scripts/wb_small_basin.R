# Why the open balance runs high at small basins (#176): the held-out annual balance at the
# shipped fit's calibration gauges under 100 km2, against the larger ones, under the rule below.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_small_basin.R
#
# Reads the shipped fit (scripts/wb_cv_lib.R: `cal`, its blocked folds; <fit>/cv_aet-cfu.rds:
# `station_number`, `raw`, `cv_ann`, `obs`, `zone`), #45's cached PCIC terms
# (data/wb_term/diagnose_<release>.rds) and, for glacier cover, the FWA in fwapg (WET_PG*).
# Writes data/checks/wb_small_basin_<release>.txt (tracked, wb_report()). The verdicts are
# computed by scripts/wb_small_basin_rule.R.
#
# ---- the rule, registered in a commit of its own before this script computed any check ----------
#
# The thresholds of check B were set by the owner on 2026-11-23 (#188, "Decisions"). Nothing
# below may change after the first run; an amendment made after numbers were seen is listed apart,
# at the end of this header, with the verdict as registered beside it.
#
# Known before registration, and disclosed: at the 84 calibration gauges under 100 km2 the median
# error is +1.9 % raw (P - AET) and +14.3 % adjusted (the held-out balance as shipped)
# (data/checks/wb_validation_20260717.txt, lines 63 and 106); at the 231 larger gauges, -15.1 %
# raw and -6.7 % adjusted, as the plan's review read them from cv_aet-cfu.rds. So where the bias
# enters is known: with the adjustment. The script prints all four again.
#
# Definitions:
#   - gauges: the shipped fit's calibration gauges; small: accumulated FWA area under 100 km2.
#     The script stops unless cv_aet-cfu.rds and `cal` hold the same stations in the same order
#     with the same `obs`, and unless it reproduces the four medians above to one decimal and the
#     fit's `code_md5` equals `score_code_md5`.
#   - error: 100 * (modelled - observed) / observed, annual. Raw is P - AET; adjusted is `cv_ann`.
#   - a class with fewer than 5 gauges (on either side, where a check compares two) is printed,
#     marked, and not read.
#
# A. Where the bias enters: described, not judged. The size-blind adjustment lifts both classes.
#    A prints the small-minus-larger contrast in median error, raw and adjusted, over all gauges,
#    then within each class of three splits: dominant hydrologic zone (`zone`), elevation tercile
#    (`elev`) and aridity tercile (`pet_yr / p_yr`), terciles cut over all calibration gauges.
#    Reading: the contrast is "general" if the adjusted contrast is +10 points or more in at least
#    two thirds of the readable classes of every split, otherwise "concentrated", naming the
#    readable classes below +10 (sb_reading_contrast()).
#
# B. Do catchment traits explain it. One model, no search: ordinary least squares of
#    log(cv_ann / obs) on the traits below, fitted on all calibration gauges under the fit's
#    blocked folds (`cal$fold`), each gauge predicted from the model fitted on the folds that
#    exclude it, the traits standardized with each training set's means and standard deviations.
#    Traits: log10(area_km2), p_yr, pet_yr / p_yr, elev, t_yr, swe_max / p_yr, and glacier cover
#    (below). Corrected value: cv_ann / exp(predicted); its error as above.
#    Verdict "traits explain the small-basin error" only if all three hold:
#      1. the small gauges' median corrected error is within +/-5 %;
#      2. their mean absolute % error (mae(), scripts/wb_cv_lib.R) falls by at least 3.0 points;
#      3. that of the gauges of 100 km2 and up rises by no more than 1.0 point (the gate's margin,
#         #47, #83).
#    A 90 % interval on test 1 comes from 1,000 bootstrap draws of the blocked folds, with
#    replacement (seed 188), each draw's statistic the median corrected error of the small gauges
#    in the drawn folds, held-out predictions as made (no refit). If tests 2 and 3 hold and the
#    interval crosses -5 or +5, the verdict is "undecided"; otherwise test 1 decides
#    (sb_verdict_traits()).
#    Beside it, an area-only model (log10(area_km2) alone) under the same tests; if it passes, the
#    report says so, because the small class is defined by area.
#    Deviation from #176, which says "at the small gauges": the model is fitted on all gauges,
#    because the candidate adjustment would be.
#    Caveat, stated and not removed: each training gauge's `cv_ann` came from fits that saw the
#    held-out gauge's `obs`, a second-order leak.
#    A per-trait table (Spearman correlation with the adjusted error at the small gauges, and each
#    trait's standardized coefficient in the all-gauge fit) is printed and decides nothing.
#    Glacier cover: the area of FWA glacier polygons (whse_basemapping.fwa_glaciers_poly)
#    intersected with each fundamental watershed upstream of the gauge, over the gauge's
#    accumulated area.
#    Not tested: average slope and solar exposure. Slope is in 15 of WALLY's 27 zone models and
#    solar exposure in 8 (data/checks/wally_compare_20260717.txt, section 1); both need the DEM,
#    which the machine holding this run lacks, so both are carried to the follow-up issue.
#    `lake` is not a trait: it is a lake-outlet label, true at 1 of the 84 small gauges.
#
# C. Which term, against PCIC, where PCIC's grid reaches. #45's per-basin terms
#    (data/wb_term/diagnose_<release>.rds, `basins`: 192 PCIC-covered basins in the Fraser, Peace
#    and Columbia; one row merges two gauges, so basins are counted, not joined on station_number).
#    C first prints the raw and adjusted median errors on its own small basins and names that
#    population. The rule is #45's (planning/archive/2026-10-issue-45-dry-interior-term/findings.md,
#    steps 1 to 5), which diagnoses an overshoot only: verdict() is copied verbatim from
#    scripts/wb_term_diagnose.R, the copy is held to the stored zone verdicts on all 21 rows, and
#    it is applied to the small class with the ECCC corroboration over the zones the small basins
#    fall in, keeping #45's minimum of 4 basins. #45's step 6, leave-one-basin-out stability, is
#    dropped. Caveat: a PCIC cell is about 30 km2, so a small basin spans a few cells; step 3
#    (PCIC a usable reference) is the guard, and its numbers are printed.
#
# D. Sampling: recorded from the code, no number. The province run samples each fundamental
#    watershed area-weighted (scripts/wb_province.R, wet_ws_sample(st, ws, "area")), so #176's
#    "centroid against area-weighted" candidate does not describe the shipped run.
#
# Attribution (ours, theirs or unresolved): the adjustment's lift at small gauges is ours and was
# known before this rule; A's reading says whether it is general or concentrated. The raw
# small-minus-larger contrast is "ours, P" or "ours, AET" on C's population where C names that
# term with its corroboration, otherwise unresolved there (sb_attribution()). B's verdict is
# reported beside it; a pass enters the trait regression in the follow-up issue's candidates.
#
# Amendments after numbers were seen:
#   1. Found by code review after the first run: the verdict functions registered with this header
#      (scripts/wb_small_basin_rule.R, 9f5a0da) can return two outcomes this text does not name.
#      sb_reading_contrast() returns "unreadable" when a split has no readable class, where this
#      text reads "concentrated"; sb_attribution() returns "ours and theirs, P" when check C reads
#      "P side, shared (ours and theirs)", where this text reads "ours, P". Neither fires in this
#      run (A reads "concentrated", C "compensating"), so no verdict moves; the functions stay as
#      registered.
#   2. Found by the same review: check C reads #45's cache, which records its release but not the
#      fit it was made from. The script now rebuilds every column the cache takes from the fit, as
#      #45 builds it, and refuses a cache that differs. It changes no number.

# Registered at 9f5a0da ("Register the small-basin diagnosis rule (#176)").
#
# A proof that check B is held out: WET_SB_INSAMPLE=1 fits B's model once on all gauges and
# predicts them in-sample, writes its report to tempdir() instead of data/checks/, and prints
# both runs' mean absolute log residual over all gauges to the log, for comparison.

source("scripts/wb_cv_lib.R")  # cal (with its blocked `fold`), mae(), score_code_md5, release, key_dir
source("scripts/wb_small_basin_rule.R")
insample <- identical(Sys.getenv("WET_SB_INSAMPLE"), "1")
seed <- 188
n_boot <- 1000
min_basins <- 4   # #45's minimum, for verdict() below
omega_max <- 5    # #45's
med <- stats::median

# ---- the shipped fit, reproduced before any check ----------------------------------------------
cv <- readRDS(file.path(fit_dir, "cv_aet-cfu.rds"))
if (!identical(cv$station_number, cal$station_number) || !isTRUE(all.equal(cv$obs, cal$obs))) {
  stop("cv_aet-cfu.rds and cal disagree on station order or obs", call. = FALSE)
}
if (!identical(cv$code_md5, score_code_md5)) {
  stop("the fit's code_md5 (", cv$code_md5, ") is not this tree's score_code_md5 (", score_code_md5,
       "): find which scored file differs before reading any check", call. = FALSE)
}
d <- data.frame(station_number = cal$station_number, fold = cal$fold, zone = cal$zone, area_km2 = cal$area_km2,
                obs = cal$obs, raw = cv$raw, adj = cv$cv_ann, p_yr = cal$p_yr, pet_yr = cal$pet_yr,
                t_yr = cal$t_yr, elev = cal$elev, swe_max = cal$swe_max, wscode = cal$wscode,
                localcode = cal$localcode)
stopifnot(!anyNA(d[setdiff(names(d), c("wscode", "localcode"))]))
d$small <- d$area_km2 < 100
err <- function(m, o) 100 * (m - o) / o
d$e_raw <- err(d$raw, d$obs)
d$e_adj <- err(d$adj, d$obs)
known <- c(small_raw = 1.9, small_adj = 14.3, large_raw = -15.1, large_adj = -6.7)
got <- c(small_raw = med(d$e_raw[d$small]), small_adj = med(d$e_adj[d$small]),
         large_raw = med(d$e_raw[!d$small]), large_adj = med(d$e_adj[!d$small]))
if (sum(d$small) != 84 || any(round(got, 1) != known)) {
  stop("the fit does not reproduce the registered medians: ", paste(names(got), round(got, 2), collapse = ", "),
       call. = FALSE)
}

# ---- glacier cover -----------------------------------------------------------------------------
# FWA glacier area within each fundamental watershed, then summed over each gauge's upstream
# watersheds (wet:::wet_fwa_upstream(), the codes' upstream test). Cached under data/wb_small_basin/,
# named for the query and the glacier table's row count and total area.
conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres"),
  connect_timeout = 10
)
q_glacier <- "
  SELECT w.watershed_feature_id, w.wscode_ltree::text AS wscode, w.localcode_ltree::text AS localcode,
         sum(ST_Area(ST_Intersection(w.geom, g.geom))) AS glacier_m2
  FROM whse_basemapping.fwa_glaciers_poly g
  JOIN whse_basemapping.fwa_watersheds_poly w ON ST_Intersects(w.geom, g.geom)
  GROUP BY w.watershed_feature_id, w.wscode_ltree, w.localcode_ltree
  ORDER BY w.watershed_feature_id"
gl_table <- DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n, sum(ST_Area(geom)) AS m2",
                                        "FROM whse_basemapping.fwa_glaciers_poly"))
gl_dir <- file.path("data", "wb_small_basin")
dir.create(gl_dir, recursive = TRUE, showWarnings = FALSE)
gl_key <- substr(wet:::wet_md5_text(paste(q_glacier, gl_table$n, sprintf("%.0f", gl_table$m2), sep = "|")), 1, 10)
f_gl <- file.path(gl_dir, sprintf("glacier_ws_%s.rds", gl_key))
if (!file.exists(f_gl)) {
  stamp("glacier area per fundamental watershed")
  gw <- DBI::dbGetQuery(conn, q_glacier)
  saveRDS(gw, paste0(f_gl, ".part"))
  if (!file.rename(paste0(f_gl, ".part"), f_gl)) stop("could not move the glacier cache into place")
}
DBI::dbDisconnect(conn)
gw <- readRDS(f_gl)
gw <- gw[gw$glacier_m2 > 0 & !is.na(gw$wscode) & !is.na(gw$localcode), ]
d$glacier <- vapply(seq_len(nrow(d)), function(i) {
  sum(gw$glacier_m2[wet:::wet_fwa_upstream(d$wscode[i], d$localcode[i], gw$wscode, gw$localcode)])
}, 1) / (d$area_km2 * 1e6)
stopifnot(all(is.finite(d$glacier)), all(d$glacier >= 0), all(d$glacier <= 1.01))

# ---- A. where the bias enters ------------------------------------------------------------------
tercile <- function(x) {
  cut(x, stats::quantile(x, c(0, 1 / 3, 2 / 3, 1)), include.lowest = TRUE, labels = c("low", "middle", "high"))
}
d$elev_t <- tercile(d$elev)
d$arid <- d$pet_yr / d$p_yr
d$arid_t <- tercile(d$arid)
split_tab <- function(by) {
  cls <- if (is.factor(d[[by]])) levels(d[[by]]) else sort(unique(as.character(d[[by]])))
  do.call(rbind, lapply(cls, function(k) {
    i <- as.character(d[[by]]) == k
    s <- i & d$small
    l <- i & !d$small
    data.frame(class = k, n_small = sum(s), n_large = sum(l),
               raw_small = if (any(s)) med(d$e_raw[s]) else NA_real_,
               raw_large = if (any(l)) med(d$e_raw[l]) else NA_real_,
               adj_small = if (any(s)) med(d$e_adj[s]) else NA_real_,
               adj_large = if (any(l)) med(d$e_adj[l]) else NA_real_)
  }))
}
splits <- list(zone = split_tab("zone"), elevation = split_tab("elev_t"), aridity = split_tab("arid_t"))
for (k in names(splits)) {
  splits[[k]]$contrast <- splits[[k]]$adj_small - splits[[k]]$adj_large
  splits[[k]]$contrast_raw <- splits[[k]]$raw_small - splits[[k]]$raw_large
}
rd_a <- sb_reading_contrast(splits)

# ---- B. do catchment traits explain it ---------------------------------------------------------
d$log_area <- log10(d$area_km2)
d$swe_p <- d$swe_max / d$p_yr
traits <- c("log_area", "p_yr", "arid", "elev", "t_yr", "swe_p", "glacier")
d$y <- log(d$adj / d$obs)
fit_predict <- function(vars, train, test) {
  mu <- vapply(train[vars], mean, 1)
  sdv <- vapply(train[vars], stats::sd, 1)
  if (any(!is.finite(sdv) | sdv == 0)) stop("a trait is constant in a training set: ", paste(vars, collapse = ", "))
  z <- function(x) as.data.frame(Map(function(v, m, s) (v - m) / s, x[vars], mu, sdv))
  m <- stats::lm(y ~ ., data = cbind(y = train$y, z(train)))
  unname(stats::predict(m, newdata = z(test)))
}
held_out <- function(vars) {
  p <- rep(NA_real_, nrow(d))
  if (insample) return(fit_predict(vars, d, d))
  for (f in unique(d$fold)) {
    te <- d$fold == f
    p[te] <- fit_predict(vars, d[!te, ], d[te, ])
  }
  p
}
score_b <- function(vars) {
  pred <- held_out(vars)
  corr <- d$adj / exp(pred)
  e_corr <- err(corr, d$obs)
  folds <- unique(d$fold)
  set.seed(seed)
  boot <- vapply(seq_len(n_boot), function(b) {
    take <- sample(folds, length(folds), replace = TRUE)
    rows <- unlist(lapply(take, function(f) which(d$fold == f & d$small)))
    if (length(rows)) med(e_corr[rows]) else NA_real_
  }, 1)
  ci <- unname(stats::quantile(boot, c(0.05, 0.95), na.rm = TRUE))
  mae_s <- c(mae(d$obs[d$small], d$adj[d$small]), mae(d$obs[d$small], corr[d$small]))
  mae_l <- c(mae(d$obs[!d$small], d$adj[!d$small]), mae(d$obs[!d$small], corr[!d$small]))
  v <- sb_verdict_traits(med(e_corr[d$small]), ci, mae_s, mae_l)
  list(pred = pred, e_corr = e_corr, med_small = med(e_corr[d$small]), med_large = med(e_corr[!d$small]),
       ci = ci, n_empty = sum(is.na(boot)), mae_small = mae_s, mae_large = mae_l, verdict = v,
       abs_resid = mean(abs(d$y - pred)))
}
b_full <- score_b(traits)
b_area <- score_b("log_area")
message(sprintf("check B (%s): mean |log residual| over all gauges, full %.5f, area-only %.5f; first predictions %s",
                if (insample) "in-sample" else "held out", b_full$abs_resid, b_area$abs_resid,
                paste(sprintf("%.5f", b_full$pred[1:3]), collapse = " ")))
z_all <- as.data.frame(lapply(d[traits], function(x) (x - mean(x)) / stats::sd(x)))
coef_std <- stats::coef(stats::lm(d$y ~ ., data = z_all))[traits]
rho <- vapply(traits, function(v) stats::cor(d[[v]][d$small], d$e_adj[d$small], method = "spearman"), 1)

# ---- C. which term, against PCIC ---------------------------------------------------------------
tm <- readRDS(file.path("data", "wb_term", sprintf("diagnose_%s.rds", release)))
stopifnot(identical(tm$release, release))
b <- tm$basins
# The cache records its release, not its fit. Every column it takes from the fit (#45's `cols_g`, read
# from `cal`, and `cv_ann`) is rebuilt here from this fit as #45 builds it, gauges on one watershed
# averaged, and must equal the cache's; the rest of a row comes from PCIC and fwapg, not the fit.
cols_fit <- c("zone", "nesting", "n_years", "area_km2", "elev", "obs", "p_yr", "aet_cfu", "aet_fu", "pet_yr",
              "ppt_tc", "aet_mod16", "cv_ann")
stale <- function(why) {
  stop("data/wb_term/diagnose_", release, ".rds was made from another fit (", why,
       "): rerun scripts/wb_term_diagnose.R", call. = FALSE)
}
fit_rows <- cal[cal$watershed_feature_id %in% b$watershed_feature_id, ]
fit_rows$cv_ann <- cv$cv_ann[match(fit_rows$station_number, cv$station_number)]
for (j in seq_len(nrow(b))) {
  r <- fit_rows[fit_rows$watershed_feature_id == b$watershed_feature_id[j], ]
  if (!setequal(r$station_number, strsplit(b$station_number[j], "+", fixed = TRUE)[[1]])) {
    stale(paste("gauges at watershed", b$watershed_feature_id[j]))
  }
  for (v in cols_fit) {
    want <- if (is.numeric(r[[v]])) mean(r[[v]]) else r[[v]][1]
    same <- if (is.numeric(want)) isTRUE(all.equal(b[[v]][j], want)) else identical(b[[v]][j], want)
    if (!same) stale(paste(v, "at", b$station_number[j]))
  }
}
ec <- tm$eccc
# copied verbatim from scripts/wb_term_diagnose.R (#45's rule as amended), which cannot be sourced
verdict <- function(d, zones, check_n = TRUE) {
  e <- ec[ec$zone %in% zones & ec$elev >= med(d$elev) - 500, ]
  r <- list(n = nrow(d), le_o = med(d$le_o), le_c = med(d$le_c), ale_o = med(abs(d$le_o)),
            ale_c = med(abs(d$le_c)), closure = med(abs(d$closure)), sdp = sum(d$dp), sda = sum(d$da),
            g = sum(d$gap), tc_o = med(d$ppt_tc / d$p_yr), tc_c = med(d$ppt_tc / d$p_c),
            mod16 = med(d$aet_mod16 / d$aet_cfu),
            # "under both PETs" is per basin: a basin counts only when the test
            # holds under each PET. NA (implied AET <= 0) fails both tests, so
            # every basin is in both denominators.
            w_high = mean(!is.na(d$w_harg) & d$w_harg > omega_max &
                            !is.na(d$w_pcic) & d$w_pcic > omega_max),
            w_low = mean(is.finite(d$w_harg) & d$w_harg <= omega_max &
                           is.finite(d$w_pcic) & d$w_pcic <= omega_max),
            n_eccc = nrow(e), eccc = if (nrow(e) >= 3) med(e$ratio) else NA_real_)
  r$share_p <- if (r$g > 0) r$sdp / r$g else NA_real_
  r$share_a <- if (r$g > 0) -r$sda / r$g else NA_real_
  r$off <- if (r$ale_o > r$ale_c) "ours" else "theirs"
  shared <- NULL
  decompose <- function() {
    if (r$g <= 0) return("decomposition undefined (our P - AET is not above PCIC's)")
    in_band <- function(s) s >= 2 / 3 && s <= 1.5
    p_corr <- r$w_high >= 0.5 || (!is.na(r$eccc) && r$eccc >= 1.10) || r$tc_o <= 0.90
    a_corr <- r$w_low > 0.5 && r$mod16 >= 1.00
    if (in_band(r$share_p)) return(if (p_corr) "P side (ours)" else "unresolved: P by decomposition, not corroborated")
    if (in_band(r$share_a)) return(if (a_corr) "AET side (ours)" else "unresolved: AET by decomposition, not corroborated")
    if (r$share_p > 1.5 || r$share_a > 1.5) return("compensating (the other term offsets more than half)")
    "mixed"
  }
  r$decomp <- decompose()
  r$verdict <- if (check_n && r$n < min_basins) {
    "too few"
  } else if (r$le_o < 0.10) {
    "no material gap"
  } else if (r$ale_c > 0.25 || r$closure > 0.25) {
    "unresolved: PCIC not a usable reference"
  } else if (r$le_c >= 0.10 && r$le_c >= (2 / 3) * r$le_o) {
    if (r$tc_o <= 0.90 && r$tc_c <= 0.90) "P side, shared (ours and theirs)"
    else "gauge side (unresolved: withdrawals or groundwater)"
  } else {
    r$decomp
  }
  r
}
# the copy must reproduce #45's stored zone verdicts (none of which its stability step changed)
again <- vapply(tm$zones$zone, function(z) verdict(b[b$zone == z, ], z)$verdict, "")
if (!identical(unname(again), tm$zones$verdict)) {
  stop("the copied verdict() does not reproduce #45's stored zone verdicts", call. = FALSE)
}
bs <- b[b$area_km2 < 100, ]
c_zones <- sort(unique(bs$zone))
rc <- verdict(bs, c_zones)
attribution <- sb_attribution(rc$verdict)

# ---- report ------------------------------------------------------------------------------------
out <- character()
say <- function(...) out <<- c(out, ...)
f1 <- function(x) ifelse(is.na(x), "     -", sprintf("%+6.1f", x))
f2 <- function(x) ifelse(is.na(x), "-", sprintf("%.2f", x))
mark <- function(ns, nl) ifelse(ns < sb_min_n | nl < sb_min_n, "*", " ")
say("# Why the open balance runs high at small basins (#176), under the rule registered at 9f5a0da",
    "",
    sprintf("fit: %s, province run %s, scoring code %s (equal to the fit's); HYDAT %s", release, basename(key_dir),
            score_code_md5, release),
    sprintf("gauges: %d calibration gauges, %d under 100 km2 (small), %d of 100 km2 and up (larger)", nrow(d),
            sum(d$small), sum(!d$small)),
    "error: 100 * (modelled - observed) / observed, annual; raw is P - AET, adjusted the held-out balance as shipped",
    "",
    "Reproduced before any check (registered, known before the rule):",
    sprintf("  median error, small: raw %+.1f %%, adjusted %+.1f %%; larger: raw %+.1f %%, adjusted %+.1f %%",
            got[["small_raw"]], got[["small_adj"]], got[["large_raw"]], got[["large_adj"]]),
    "")

say("## A. Where the bias enters (described; the reading is the only part registered unseen)",
    "",
    sprintf("All gauges: small minus larger median error, raw %+.1f points, adjusted %+.1f points.",
            got[["small_raw"]] - got[["large_raw"]], got[["small_adj"]] - got[["large_adj"]]),
    "By class (n small / n larger; * fewer than 5 on a side, not read):",
    "")
for (k in names(splits)) {
  x <- splits[[k]]
  say(sprintf("%-10s %-8s  %3s %3s   %6s %6s %7s   %6s %6s %7s", k, "class", "ns", "nl", "raw s", "raw l", "raw s-l",
              "adj s", "adj l", "adj s-l"))
  for (j in seq_len(nrow(x))) {
    say(sprintf("%-10s %-7s%s  %3d %3d   %s %s  %s   %s %s  %s", "", x$class[j], mark(x$n_small[j], x$n_large[j]),
                x$n_small[j], x$n_large[j], f1(x$raw_small[j]), f1(x$raw_large[j]), f1(x$contrast_raw[j]),
                f1(x$adj_small[j]), f1(x$adj_large[j]), f1(x$contrast[j])))
  }
  say("")
}
say(sprintf("%-10s readable %d, at or above +%.0f points %d (%.0f %%)%s", rd_a$per$split, rd_a$per$readable,
            sb_contrast_pts, rd_a$per$reach, 100 * rd_a$per$share,
            ifelse(nzchar(rd_a$per$below), paste0("; below: ", rd_a$per$below), "")),
    sprintf("Reading: the adjusted contrast is %s.", rd_a$reading),
    "")

say("## B. Do catchment traits explain it (held out under the fit's blocked folds)",
    "",
    sprintf("traits: %s; glacier cover from %d FWA glacier polygons (%.0f km2), %d gauges with any",
            paste(traits, collapse = ", "), gl_table$n, gl_table$m2 / 1e6, sum(d$glacier > 0)),
    "not tested: average slope and solar exposure (need the DEM; carried to the follow-up issue)",
    sprintf("folds: %d; bootstrap: %d draws of the folds, seed %d (draws with no small gauge: full %d, area-only %d)",
            length(unique(d$fold)), n_boot, seed, b_full$n_empty, b_area$n_empty),
    "",
    sprintf("%-10s %9s %18s   %-21s %-21s  %s", "model", "small med", "90 % interval", "small MAE base->corr",
            "larger MAE base->corr", "verdict"))
for (nm in c("full", "area-only")) {
  r <- if (nm == "full") b_full else b_area
  say(sprintf("%-10s %+8.1f %% [%+6.1f, %+6.1f] %%   %5.1f -> %5.1f (%+5.1f)   %5.1f -> %5.1f (%+5.1f)  %s", nm,
              r$med_small, r$ci[1], r$ci[2], r$mae_small[1], r$mae_small[2], r$mae_small[2] - r$mae_small[1],
              r$mae_large[1], r$mae_large[2], r$mae_large[2] - r$mae_large[1], r$verdict$verdict))
}
say(sprintf(paste0("tests (full): median within +/-%.0f %% %s; small MAE gain >= %.1f %s; ",
                   "larger MAE cost <= %.1f %s; interval crosses %s"),
            sb_median_pts, b_full$verdict$tests[["median"]], sb_gain_pts, b_full$verdict$tests[["gain"]], sb_cost_pts,
            b_full$verdict$tests[["cost"]], b_full$verdict$crosses),
    sprintf("larger gauges' median corrected error: full %+.1f %%, area-only %+.1f %%", b_full$med_large,
            b_area$med_large),
    sprintf("Verdict: %s.%s", b_full$verdict$verdict,
            if (b_area$verdict$verdict == "traits explain the small-basin error") {
              " Area alone passes the same tests."
            } else {
              ""
            }),
    "",
    "Per trait (decides nothing): Spearman with the adjusted error at the small gauges, and the standardized",
    "coefficient in one fit on all gauges (response log(adjusted / observed)):",
    sprintf("  %-9s %+6.2f   %+7.3f", traits, rho, coef_std),
    "")

say("## C. Which term, against PCIC (#45's rule on the small class)",
    "",
    sprintf("population: %d PCIC-covered basins under 100 km2 (Fraser, Peace and Columbia), of %d in #45's table;",
            nrow(bs), nrow(b)),
    sprintf("  zones: %s", paste(c_zones, collapse = ", ")),
    sprintf("  median error there: raw %+.1f %%, adjusted %+.1f %%", med(err(bs$r_o, bs$obs)),
            med(err(bs$cv_ann, bs$obs))),
    sprintf("the copied verdict() reproduces #45's %d stored zone verdicts", nrow(tm$zones)),
    "",
    sprintf(paste0("n %d; our raw log error (le_o) %+.3f, PCIC's (le_c) %+.3f; |le_c| %.3f; closure %.3f ",
                   "(step 3: usable if both <= 0.25)"),
            rc$n, rc$le_o, rc$le_c, rc$ale_c, rc$closure),
    sprintf(paste0("sum dP %.0f, sum dA %.0f, gap %.0f; share P %s, share AET %s; ",
                   "TerraClimate/P ours %.2f, PCIC %.2f; MOD16/AET %.2f"),
            rc$sdp, rc$sda, rc$g, f2(rc$share_p), f2(rc$share_a), rc$tc_o, rc$tc_c, rc$mod16),
    sprintf("omega > 5 under both PETs %.0f %%, <= 5 %.0f %%; ECCC stations %d, climr/ECCC %s; decomposition: %s",
            100 * rc$w_high, 100 * rc$w_low, rc$n_eccc, f2(rc$eccc), rc$decomp),
    sprintf("Verdict: %s.", rc$verdict),
    "")

say("## D. Sampling",
    "",
    "The province run samples each fundamental watershed area-weighted (scripts/wb_province.R,",
    "wet_ws_sample(st, ws, \"area\")): #176's centroid-against-area-weighted candidate does not describe it.",
    "")

say("## Attribution",
    "",
    sprintf("- The adjustment's lift at small gauges: ours, known before the rule; the contrast is %s.", rd_a$reading),
    sprintf("- The raw small-minus-larger contrast, on check C's %d basins: %s.", nrow(bs), attribution),
    sprintf("- Catchment traits (check B): %s.", b_full$verdict$verdict))

f_out <- if (insample) file.path(tempdir(), "wb_small_basin_insample.txt") else wb_report("wb_small_basin", release)
writeLines(out, f_out)
message("wrote ", f_out)
