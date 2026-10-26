# PCIC's routed flow on the FWA (#58), shared by scripts/pcic_routed_compare.R
# and data-raw/segment_vignette_data.R, so the report and the vignette read
# one definition. Sourced after scripts/wb_cv_lib.R; not run on its own.
#
# The table is fwapg's pcic.discharge_monthly (NewGraphEnvironment/fwapg#25),
# read for one run: monthly means of daily flow (m3/s) over the run's period,
# PCIC's Raven routing driven by PNWNAmet, placed on FWA segments. The package
# names the table and the run (wet:::wet_segment_sources(), the one place #103
# changes the period); everything here takes them from there. Nothing in the
# database says which fwapg commit built the run, so a caller names it
# (WET_FWAPG_COMMIT) and records the run's fingerprint beside it.

# the run must come from the source tree, not an installed wet
if (!pkgload::is_dev_package("wet")) stop("devtools::load_all() before sourcing scripts/pcic_routed_lib.R", call. = FALSE)
routed_run <- local({
  lk <- wet:::wet_segment_sources("discharge/fwa/v1/segment_monthly")
  lk <- lk[lk$from == "fwapg" & lk$source == "pcic_routed", ]
  stopifnot(nrow(lk) == 1L, !anyNA(lk[c("location", "model", "scenario", "period")]))
  as.list(lk[c("location", "model", "scenario", "period")])
})
routed_table <- routed_run$location
# the filter for one period of the routed run's model and scenario; the
# shipped period by default. Another period is read only where a script says
# so (scripts/departure_pcic.R reads 1951-2012, #122).
routed_where_period <- function(period = routed_run$period) {
  stopifnot(length(period) == 1L, grepl("^[0-9]{4}-[0-9]{4}$", period))
  sprintf("(model, scenario, period) = ('%s', '%s', '%s')", routed_run$model, routed_run$scenario, period)
}
# the filter every read of routed_table carries
routed_where <- routed_where_period()
stopifnot(!grepl("'", paste(routed_run$model, routed_run$scenario, routed_run$period)))

# the fwapg commit the routed run was built at: 7 to 40 hex characters
routed_commit <- function() {
  x <- Sys.getenv("WET_FWAPG_COMMIT")
  if (!grepl("^[0-9a-f]{7,40}$", x)) {
    stop("set WET_FWAPG_COMMIT to the fwapg commit that built ", routed_table, " ",
         paste(routed_run$model, routed_run$scenario, routed_run$period), call. = FALSE)
  }
  x
}

# the report line naming the table, run and commit; written by
# scripts/pcic_routed_compare.R and scripts/segment_output.R, and matched by
# scripts/vignette_data_lib.R and segment_output.R against the routed report
routed_report_line <- function(commit, period = routed_run$period) {
  sprintf("routed: %s (%s %s %s), built by NewGraphEnvironment/fwapg at %s", routed_table,
          routed_run$model, routed_run$scenario, period, commit)
}

# rows, segments, null flows and total flow of the run: a rebuild that moves
# any value moves the total. Summed as numeric over values rounded to 1e-6
# m3/s, so the total is exact whatever order a parallel aggregate adds in, and
# returned as text, which compares as the report prints it. Computed from the
# rows, which is what catches a table changing during a run, and refused
# unless it equals the run's row in pcic.runs (which uses the same rounding)
routed_fingerprint <- function(conn) {
  fp <- DBI::dbGetQuery(conn, sprintf("
    SELECT count(*)::text AS rows, count(DISTINCT linear_feature_id)::text AS segments,
           count(*) FILTER (WHERE q_m3s IS NULL)::text AS null_q,
           sum(round(q_m3s::numeric, 6))::text AS sum_q
    FROM %s WHERE %s", routed_table, routed_where))
  # the totals compared as numeric in the database, exactly
  run <- DBI::dbGetQuery(conn, sprintf("
    SELECT monthly_rows::text AS rows, monthly_segments::text AS segments, monthly_q_sum = $1::numeric AS same_q
    FROM pcic.runs WHERE %s", routed_where), params = list(fp$sum_q))
  if (nrow(run) != 1L || fp$rows != run$rows || fp$segments != run$segments || !isTRUE(run$same_q)) {
    stop(routed_table, " ", routed_where, " (", fp$rows, " rows, ", fp$segments, " segments, total ", fp$sum_q,
         ") is not the run pcic.runs describes", call. = FALSE)
  }
  sprintf("%s rows, %s segments, %s null flows, total %s m3/s", fp$rows, fp$segments, fp$null_q, fp$sum_q)
}

# Mean annual routed flow (m3/s) per segment: the mean of its 12 monthly
# means, unweighted by month length, as wet_segment_monthly() reads it from
# fwapg (month 0, the published product's rule), from the run routed_run names. NA where the segment has no
# row, or not twelve months of flow.
routed_annual <- function(conn, lfid) {
  lfid <- unique(lfid[!is.na(lfid)])
  q <- wet_segment_monthly(conn, lfid, source = "pcic_routed", from = "fwapg")
  q <- q[q$month == 0, ]
  data.frame(linear_feature_id = q$linear_feature_id, q_m3s = q$q_m3s)
}

# m3/s over an area in m2 as mm a year, on the year scripts/wb_cv_lib.R
# turns observed flow into runoff with (365.25 days)
routed_mm <- function(q_m3s, area_m2) q_m3s * 365.25 * 86400 / area_m2 * 1000

# The held-out error of what ships at the calibration gauges: the shipped
# fit's blocked-CV adjusted prediction, or raw P - AET when the headwater gate
# dropped the adjustment (fits$keep_adjust; #43). Refuses a fit whose scores or
# AET choice were made under other scoring code. Needs wb_cv_lib.R's globals.
shipped_heldout <- function() {
  fits <- readRDS(file.path(fit_dir, "fits.rds"))
  winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
  cv <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", fits$aet)))
  stopifnot(identical(release, wb_shipped_release),
            identical(fits$code_md5, score_code_md5),
            identical(winner[1:2], c(fits$aet, score_code_md5)),
            identical(cv$code_md5, score_code_md5),
            identical(cv$station_number, cal$station_number),
            identical(fits$calibration, cal$station_number))
  ship_v <- if (fits$keep_adjust) cv$cv_v else cv$raw_v
  sk <- ship_v$stations[c("station_number", "obs", "mod", "err_pct")]
  stopifnot(nrow(sk) == nrow(cal), setequal(sk$station_number, cal$station_number), !anyNA(sk$err_pct))
  list(fits = fits, stations = sk)
}

# A gauge whose segment carries less than this share of its observed flow is
# listed: a side channel, which carries only its own water (fwapg's README), a
# reservoir lake, or a misplaced outlet, rather than PCIC's model error. The
# same cut, against the balance rather than observed flow, picks a segment's
# default source (wet_source_pick(), #57)
routed_far_low <- 0.2

# Whether a segment (alias s, fwa_stream_networks_sp) lies on its lut
# watershed's own line (alias w, fwa_watersheds_poly): its blue line is its
# watershed code's main line, and that code is the watershed's. Only there is
# the balance the segment's own flow, so only there can the default pick fall
# to it (wet_source_pick(own_line =), #57). Off it are side channels (blue line
# not the main line), network connectors that sit in another stream's
# watershed (another code), and waterbody connections off the main line.
routed_own_line_sql <- "(s.blue_line_key = s.watershed_key AND s.wscode_ltree = w.wscode_ltree)"

# the major basins, by Water Survey sub-drainage
routed_basin <- function(st) {
  p <- substr(st, 1, 3)
  ifelse(p %in% c("07E", "07F"), "Peace",
         ifelse(p %in% paste0("08", c("J", "K", "L", "M")), "Fraser",
                ifelse(p == "08N", "Columbia",
                       ifelse(substr(p, 1, 2) == "08", "Coast",
                              ifelse(substr(p, 1, 2) == "09", "Yukon", "Arctic")))))
}

# The comparison at the gauges both estimates score: n, mean and median
# absolute error, the share within +-cut %, bias (mean signed error), all in %
# of observed. Shared by the report and the vignette's data script.
routed_scores <- function(err, cut = 20) {
  c(n = length(err), mae = mean(abs(err)), median_ae = stats::median(abs(err)),
    within = 100 * mean(abs(err) <= cut), bias = mean(err))
}

# ---- routed days (#99) ---------------------------------------------------------------------------
# fwapg keeps no per-segment days. It keeps each sub-basin's day-of-year
# climatology (pcic.subbasin_daily, one row per run, sub-basin and calendar
# bin) and each segment's weights (pcic.segment_weights, shared by every run),
# from which wet:::wet_routed_days() gives any segment's 365 days, on the
# same footing as the run's monthly and weekly tables.
routed_daily_table <- "pcic.subbasin_daily"
routed_weights_table <- "pcic.segment_weights"

# The daily rows and the weights as pcic.runs describes them: rows,
# sub-basins and q_acc summed over values rounded to 1e-6 (numeric, so exact
# in any order), and weights rows and shares rounded to 1e-9, which is how
# fwapg's export wrote those columns. Refused unless equal.
routed_daily_fingerprint <- function(conn, period = routed_run$period) {
  where <- routed_where_period(period)
  fp <- DBI::dbGetQuery(conn, sprintf("
    SELECT count(*)::text AS rows, count(DISTINCT subid)::text AS subbasins,
           sum(round(q_acc::numeric, 6))::text AS sum_q
    FROM %s WHERE %s", routed_daily_table, where))
  fw <- DBI::dbGetQuery(conn, sprintf("
    SELECT count(*)::text AS rows, sum(round(share::numeric, 9))::text AS sum_share FROM %s",
    routed_weights_table))
  run <- DBI::dbGetQuery(conn, sprintf("
    SELECT daily_rows::text AS rows, daily_subbasins::text AS subbasins, daily_q_sum = $1::numeric AS same_q,
           weights_rows::text AS w_rows, weights_share_sum = $2::numeric AS same_share
    FROM pcic.runs WHERE %s", where), params = list(fp$sum_q, fw$sum_share))
  if (nrow(run) != 1L || fp$rows != run$rows || fp$subbasins != run$subbasins || !isTRUE(run$same_q) ||
        fw$rows != run$w_rows || !isTRUE(run$same_share)) {
    stop(routed_daily_table, " ", where, " (", fp$rows, " rows, ", fp$subbasins, " sub-basins, total ",
         fp$sum_q, ") or ", routed_weights_table, " (", fw$rows, " rows, shares ", fw$sum_share,
         ") is not what pcic.runs describes", call. = FALSE)
  }
  sprintf("%s rows, %s sub-basins, total q_acc %s m3/s; weights %s rows, shares %s",
          fp$rows, fp$subbasins, fp$sum_q, fw$rows, fw$sum_share)
}

# The run's days folded onto the common year (wet:::wet_routed_fold()), and
# every segment's weights, upstream_subids as a list of integers in the order
# fwapg stored them. Read once per run; about 1 GB in memory.
routed_daily_inputs <- function(conn) {
  d <- DBI::dbGetQuery(conn, sprintf("
    SELECT subid, month, day, n_days, q_local, q_acc FROM %s WHERE %s ORDER BY subid, month, day",
    routed_daily_table, routed_where))
  fold <- wet:::wet_routed_fold(d)
  rm(d)
  list(fold = fold, weights = routed_weights(conn))
}

# Segments' weights alone, upstream_subids as a list of integers in the order
# fwapg stored them: every segment's, or those of `lfid` (a segment without a
# row is absent from the result). Shared by every run.
routed_weights <- function(conn, lfid = NULL) {
  only <- if (is.null(lfid)) "" else {
    stopifnot(length(lfid) > 0, !anyNA(lfid))
    sprintf(" WHERE linear_feature_id IN (%s)", paste(sprintf("%.0f", unique(lfid)), collapse = ", "))
  }
  w <- DBI::dbGetQuery(conn, sprintf("
    SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code, subid, share,
           array_to_string(upstream_subids, ',') AS up
    FROM %s%s ORDER BY linear_feature_id", routed_weights_table, only))
  stopifnot(!anyDuplicated(w$linear_feature_id), !anyNA(w$up))
  w$upstream_subids <- lapply(strsplit(w$up, ",", fixed = TRUE), as.integer)
  w$up <- NULL
  w
}

# Mid-network segments, as fwapg's qa_report_clamped.sql counts them: placed
# outlets above, and not an outlet's own segment. There the clamp hides flow
# passing through rather than a losing headwater.
routed_mid_network <- function(conn, weights) {
  own <- DBI::dbGetQuery(conn, "
    SELECT DISTINCT linear_feature_id::int AS linear_feature_id FROM pcic.fwa_crosswalk WHERE flag IS NULL")
  lengths(weights$upstream_subids) > 0 & !weights$linear_feature_id %in% own$linear_feature_id
}
