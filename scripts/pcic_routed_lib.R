# PCIC's routed flow on the FWA (#58), shared by scripts/pcic_routed_compare.R
# and data-raw/segment_vignette_data.R, so the report and the vignette read
# one definition. Sourced after scripts/wb_cv_lib.R; not run on its own.
#
# The table is NewGraphEnvironment/fwapg#6's
# whse_basemapping.fwa_stream_networks_discharge_monthly: monthly means of
# daily flow (m3/s), 1951-2012, PCIC's Raven routing driven by PNWNAmet,
# placed on FWA segments. Nothing in the database says which fwapg commit
# built it, so a caller names it (WET_FWAPG_COMMIT) and records the table's
# fingerprint beside it.

routed_table <- "whse_basemapping.fwa_stream_networks_discharge_monthly"

# the fwapg commit the routed table was built at: 7 to 40 hex characters
routed_commit <- function() {
  x <- Sys.getenv("WET_FWAPG_COMMIT")
  if (!grepl("^[0-9a-f]{7,40}$", x)) {
    stop("set WET_FWAPG_COMMIT to the fwapg commit that built ", routed_table, call. = FALSE)
  }
  x
}

# rows, segments, null flows and total flow: a rebuild that moves any value
# moves the total. Summed as numeric over values rounded to 1e-6 m3/s, so the
# total is exact whatever order a parallel aggregate adds in, and returned as
# text, which compares as the report prints it
routed_fingerprint <- function(conn) {
  fp <- DBI::dbGetQuery(conn, sprintf("
    SELECT count(*)::text AS rows, count(DISTINCT linear_feature_id)::text AS segments,
           count(*) FILTER (WHERE q_m3s IS NULL)::text AS null_q,
           sum(round(q_m3s::numeric, 6))::text AS sum_q
    FROM %s", routed_table))
  sprintf("%s rows, %s segments, %s null flows, total %s m3/s", fp$rows, fp$segments, fp$null_q, fp$sum_q)
}

# Mean annual routed flow (m3/s) per segment: the mean of its 12 monthly
# means, unweighted by month length, as wet_segment_monthly() reads it from
# fwapg (month 0, the published product's rule). NA where the segment has no
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
            identical(winner[1:2], c(fits$aet, aet_code_md5)),
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
