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

stop("rule registered; the body follows in a later commit (#70)")
