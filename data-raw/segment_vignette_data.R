# Data for vignettes/segment-discharge.Rmd (#28, #64, #71), which runs on these
# files and never touches fwapg, the network or the province run at build.
#
#   WET_FWAPG_COMMIT=<sha> Rscript data-raw/segment_vignette_data.R
#
# Every segment value it bundles is read from the published product
# (wet_catalog(): the manifest at s3://fresh-bc/discharge/fwa/v1/), and the
# script refuses to write unless each one equals what it was built from:
# routed flow's mean of twelve months in fwapg's routed table
# (scripts/pcic_routed_lib.R). The parts are checked against their manifest
# md5s before and after the read, so a read during a publish is refused.
#
# Writes inst/vignette-data/segment_values.rds, a list:
#   - skill: the shipped fit's calibration stations, with their held-out
#     (blocked-CV) error on annual runoff, the segment and watershed each
#     snapped to, zone, nesting and area, and the published routed annual
#     runoff on the gauge's segment (routed_mm; NA where it has none), so both
#     estimates are scored on one set, as scripts/pcic_routed_compare.R scores them
#   - segments: how many FWA segments `pick` gives each source, how many get
#     neither and why (no lut watershed; of those, how many are connection
#     lines or secondary-flow channels), and how many the balance takes because routed flow is far low,
#     from the tracked segment report, which must be the one the tracked
#     publish report's build was cut from, checked against the live build's
#     reader counts and fwapg's
#   - daily: the article's daily read (#99) as it prints it, run on the live
#     build: one segment's days and a window's flow from them, beside the same
#     window from its months; refused unless the balance's days keep its months
#   - provenance: the runs, reports and published build these came from, and
#     the value check against the published parts
#
# The water-balance inputs are the shipped fit (scripts/wb_fit_lib.R: the
# province run under data/wb/ and one HYDAT release; scripts wb_province.R,
# wb_stations.R and wb_validate.R). The script refuses a fit whose scores or
# AET choice were made under other scoring code.
# Routed flow is scripts/pcic_routed_lib.R's, from the table WET_FWAPG_COMMIT
# names; the script refuses a table or a commit other than the ones the tracked
# report (data/checks/pcic_routed_compare_<release>.txt) was made from.
# fwapg from the WET_PG* variables.

# The vignette cites the commit these were built at, so that commit must hold
# what built them; the routed table must be the one the tracked report scored
# (scripts/vignette_data_lib.R holds both guards)
source("scripts/vignette_data_lib.R")
wet_commit <- vd_commit()
source("scripts/wb_cv_lib.R")  # load_all(), key_dir, cal, groups, score_code_md5
source("scripts/pcic_routed_lib.R")  # after load_all(): it reads the run from the package
rc <- vd_routed_check()
fwapg_commit <- rc$commit
routed_fp <- rc$fingerprint
f_routed <- rc$report
rr <- rc$lines

out <- file.path("inst", "vignette-data", "segment_values.rds")
budget_kb <- 500

# ---- held-out skill at the calibration stations ---------------------------------------------
# the shipped fit's, and only that (shipped_heldout(): scored under this code)
ho <- shipped_heldout()
fits <- ho$fits
sk <- ho$stations
sk <- merge(sk, cal[c("station_number", "station_name", "lon", "lat", "linear_feature_id", "watershed_feature_id",
                      "zone", "nesting", "area_km2", "upstream_area_m2")], by = "station_number")
# the segment each gauge snapped to, so a gauge can be traced to its segment's value
sk$linear_feature_id <- as.integer(sk$linear_feature_id)
stopifnot(!anyNA(sk$linear_feature_id))
# the tracked report is the published record: the summary must be its blocked-CV rows
rep_lines <- readLines(wb_report("wb_validation", release))
blk <- rep_lines[(grep(if (fits$keep_adjust) "^### Adjusted, blocked CV" else "^### Raw P - AET",
                       rep_lines) + 2):length(rep_lines)]
rep_mae <- function(g, v) {
  x <- strsplit(trimws(grep(sprintf("^%s +%s ", g, v), blk, value = TRUE)[1]), " +")[[1]]
  as.numeric(x[7])
}
mae <- function(i) round(mean(abs(sk$err_pct[i])), 1)
stopifnot(mae(TRUE) == rep_mae("all", "all"),
          mae(sk$nesting == "headwater") == rep_mae("nesting", "headwater"),
          mae(sk$nesting == "nested") == rep_mae("nesting", "nested"))

# ---- fwapg ---------------------------------------------------------------------------------------
conn <- vd_connect()
# the group of each gauge's segment, which is the one the published parts carry
seg_grp_gauge <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code FROM whse_basemapping.fwa_stream_networks_sp
  WHERE linear_feature_id IN (%s)", paste(unique(sk$linear_feature_id), collapse = ", ")))
stopifnot(setequal(seg_grp_gauge$linear_feature_id, sk$linear_feature_id))
# the province's segments, and those with no watershed in the lut, which no
# source reaches: of those, the connection lines and secondary-flow channels
# (FWA edge types; stream_order cannot say, since these carry order 1 whatever they are)
connector_edges <- c(1100, 1150, 1300, 1350, 1400, 1450)
n_fwa <- DBI::dbGetQuery(conn, sprintf("
  SELECT count(*)::int AS segments, count(*) FILTER (WHERE l.linear_feature_id IS NULL)::int AS no_lut,
         count(*) FILTER (WHERE l.linear_feature_id IS NULL AND s.edge_type IN (%s))::int AS no_lut_connector
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)",
  paste(connector_edges, collapse = ", ")))
# fwapg's routed annual flow on each calibration gauge's segment: what the
# published values must equal (below)
src_routed <- routed_annual(conn, sk$linear_feature_id)
# the table must not have changed since the check above
stopifnot(identical(routed_fingerprint(conn), routed_fp))
DBI::dbDisconnect(conn)

# ---- the published product ------------------------------------------------------------------------
# the live manifest must be the build the tracked publish report checked
# value by value, with nothing failed (vd_published())
pb <- vd_published(release)
cat_pub <- pb$catalog
f_pub <- pb$report
reader <- pb$reader
# Month 0 of routed flow on every gauge's segment, from the routed parts: a
# read filtered on watershed_group_code opens only those groups' row groups.
# The parts must match their manifest before and after
parts <- cat_pub[cat_pub$dataset == "discharge/fwa/v1/segment_monthly" & cat_pub$scenario == "historical" &
                   cat_pub$source == "pcic_routed", ]
vd_verify(parts)
duck <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(duck, "LOAD httpfs"))
gauge_groups <- sort(unique(seg_grp_gauge$watershed_group_code))
t_read <- Sys.time()
pub_r <- DBI::dbGetQuery(duck, sprintf("
  SELECT source, linear_feature_id, watershed_group_code, month, q_m3s, pick, period
  FROM read_parquet([%s], hive_partitioning = true)
  WHERE month = 0 AND watershed_group_code IN (%s)",
  paste0("'", parts$href, "'", collapse = ", "), paste0("'", gauge_groups, "'", collapse = ", ")))
message("published read: ", round(as.numeric(difftime(Sys.time(), t_read, units = "secs"))), " s")
DBI::dbDisconnect(duck, shutdown = TRUE)
vd_verify(parts)
stopifnot(all(pub_r$source == "pcic_routed"), !anyDuplicated(pub_r$linear_feature_id))
# the published routed rows carry the run's period, which the article states
stopifnot(identical(unique(pub_r$period), routed_run$period))
# the published routed annual flow on each gauge's segment, in mm over wet's
# accumulated upstream area, as scripts/pcic_routed_compare.R takes it
sk$routed_mm <- routed_mm(pub_r$q_m3s[match(sk$linear_feature_id, pub_r$linear_feature_id)], sk$upstream_area_m2)
print(table(routed = !is.na(sk$routed_mm)))

# ---- the tracked report is the published record ------------------------------------------------
# the gauges' routed scores must be its rows, from the same table and commit
stopifnot(identical(f_routed, wb_report("pcic_routed_compare", release)))
rr_all <- strsplit(trimws(grep("^all +", rr, value = TRUE)[1]), " +")[[1]]
both <- sk[!is.na(sk$routed_mm), ]
r_sc <- routed_scores(100 * (both$routed_mm / both$obs - 1))
w_sc <- routed_scores(both$err_pct)
stopifnot(as.integer(rr_all[2]) == nrow(both),
          as.numeric(rr_all[3]) == round(r_sc[["mae"]], 1), as.numeric(rr_all[4]) == round(w_sc[["mae"]], 1))

# ---- the published values against what they were built from ---------------------------------------
# routed flow's mean of twelve months from fwapg, on every gauge's segment:
# each published value must equal its source, and no source value may be
# missing from the product, nor any published one lack a source. Routed month
# 0 is R's mean() at publish and here (wet_segment_monthly() through
# routed_annual()), over months read in either order, so the two may differ in
# the last bits
at0 <- function(id, q) data.frame(linear_feature_id = id, month = 0L, q_m3s = q)
src_r <- src_routed[!is.na(src_routed$q_m3s), ]
src_r <- at0(src_r$linear_feature_id, src_r$q_m3s)
pr_used <- pub_r[pub_r$linear_feature_id %in% sk$linear_feature_id, ]
cmp <- list("routed (gauges) = fwapg mean of 12 months" =
              wet_values_compare(at0(pr_used$linear_feature_id, pr_used$q_m3s), src_r))
pub_check <- data.frame(check = names(cmp), do.call(rbind, cmp), row.names = NULL)
print(pub_check)
# no value differs, and every source value was compared (a check of nothing passes nothing)
if (any(pub_check$differing > 0) || !identical(pub_check$compared, as.numeric(nrow(src_r))) ||
      any(pub_check$compared == 0)) {
  stop("the published values differ from what they were built from: see the table above")
}

# ---- the daily read the article shows (#99) --------------------------------------------------------
# Buck Creek at its mouth, the article's recipe as written, on the live build;
# its group's parts must match the manifest before and after
day_seg <- 17094080
day_win <- data.frame(window = "spring", start = "04-15", end = "06-15")
day_parts <- cat_pub[cat_pub$dataset == "discharge/fwa/v1/segment_daily" & cat_pub$scenario == "historical" &
                       cat_pub$code == "BULK", ]
stopifnot(setequal(day_parts$source, c("pcic_routed", "wet_balance")))
vd_verify(day_parts)
q <- wet_segment_daily(NULL, 17094080, groups = "BULK")
day_read <- wet_flow_window(q, data.frame(window = "spring", start = "04-15", end = "06-15"))
vd_verify(day_parts)
q_mon <- wet_segment_monthly(NULL, day_seg, groups = "BULK", catalog = cat_pub)
# both sources have every day, and the balance's days keep its published months
stopifnot(identical(unique(q$linear_feature_id), as.integer(day_seg)), !anyNA(q$q_m3s), nrow(q) == 730L, all(day_read$basis == "daily"), !anyNA(day_read$q_m3s))
bal_d <- q[q$source == "wet_balance", ]
bal_m <- q_mon[q_mon$source == "wet_balance" & q_mon$month > 0L, ]
stopifnot(isTRUE(all.equal(unname(as.vector(tapply(bal_d$q_m3s, wet:::wet_doy_month()[bal_d$doy], mean))),
                           bal_m$q_m3s, tolerance = 1e-9)))
daily <- list(segment = day_seg, group = "BULK", window = day_win, days = day_read,
              months = wet_flow_window(q_mon, day_win), parts = day_parts[c("source", "key", "md5")])
print(daily[c("days", "months")])

# ---- what pick gives the province ---------------------------------------------------------------
# from the tracked segment report (scripts/segment_output.R), which the
# publish report's build was cut from: its picks must be the live build's
# reader counts, and its segments fwapg's
# the report the publish report's build read, whose parts are all
# byte-identical to the live build's (vd_segment_report(), #93)
sr <- vd_segment_report(pb, release)
f_seg <- sr$report
seg_lines <- sr$lines
seg_num <- function(re) {
  m <- regmatches(seg_lines, regexec(re, seg_lines))
  m <- Filter(length, m)
  stopifnot(length(m) == 1)
  as.numeric(m[[1]][-1])
}
fwa <- seg_num("^FWA segments: ([0-9]+); with a watershed in the lut: ([0-9]+); without .*: ([0-9]+)$")
neither <- seg_num("; neither: ([0-9]+)$")
picked <- seg_num("^picked routed: ([0-9]+) .*; picked balance: ([0-9]+), ([0-9]+) of them under the cut$")
segments <- c(fwa = fwa[1], no_lut = fwa[3], neither = neither, pick_routed = picked[1], pick_balance = picked[2],
              far_low = picked[3], no_lut_connector = n_fwa$no_lut_connector)
print(segments)
n_pick <- stats::setNames(reader$picked, reader$source)
stopifnot(segments[["fwa"]] == n_fwa$segments, segments[["no_lut"]] == n_fwa$no_lut,
          segments[["pick_routed"]] == n_pick[["pcic_routed"]], segments[["pick_balance"]] == n_pick[["wet_balance"]],
          segments[["pick_routed"]] + segments[["pick_balance"]] + segments[["neither"]] == segments[["fwa"]],
          segments[["no_lut"]] <= segments[["neither"]])

# ---- provenance -------------------------------------------------------------------------------------
hydat_release <- sub("^HYDAT release: ", "", grep("^HYDAT release:", readLines(wb_report("stations_wb", release)),
                                                   value = TRUE))
stopifnot(length(hydat_release) == 1)

provenance <- list(
  built = Sys.Date(),
  wet_commit = wet_commit,
  province_run = basename(key_dir),
  aet = fits$aet,
  keep_adjust = fits$keep_adjust,
  pooled_variant = fits$pooled_variant,
  # whether #11's headwater gate itself passed, as against keep_adjust, which
  # an override can hold (#43): the vignette's limits say which
  gate_pass = fits$gate_pass,
  hydat_release = hydat_release,
  # the cut wet_source_pick() takes the balance under (scripts/pcic_routed_lib.R)
  far_low = routed_far_low,
  segment_report = f_seg,
  # the commit the segment report and the publish report's build name, which
  # may be later than the live manifest's segment_commit (#93)
  segment_report_commit = pb$segment_commit,
  # the published build the segment values were read from, the parts read,
  # and the check of each value against its source
  published = list(manifest = attr(cat_pub, "manifest"), built = attr(cat_pub, "built"),
                   wet_commit = attr(cat_pub, "provenance")$wet_commit,
                   segment_commit = attr(cat_pub, "provenance")$segment_commit,
                   parts = cat_pub[c("dataset", "source", "code", "key", "rows", "bytes", "md5")],
                   reader = reader, report = f_pub),
  published_check = pub_check,
  # routed flow (fwapg#6): the table and run read, the commit that built the
  # run, and its fingerprint
  routed = sub("^routed: ", "", routed_report_line(fwapg_commit)),
  # the period on the published routed rows read
  routed_period = unique(pub_r$period),
  routed_commit = fwapg_commit,
  routed_fingerprint = routed_fp,
  routed_report = f_routed
)

# fwapg's bigint ids reach R as integer64, which readRDS() without bit64 reads
# as raw bits, so a join in the vignette would match nothing: the SQL casts them
no64 <- function(x) !any(vapply(x, inherits, NA, "integer64"))
stopifnot(no64(sk))
values <- list(skill = sk, segments = segments, daily = daily, provenance = provenance)
saveRDS(values, out, compress = "xz")
message("segment_values.rds: ", round(file.size(out) / 1024), " KB")
files <- file.path("inst", "vignette-data", c("segment_values.rds", "segment_map.rds"))
kb <- sum(file.size(files)) / 1024
message("vignette data for #28, #64, #71: ", round(kb), " KB of ", budget_kb)
stopifnot(all(file.exists(files)), kb < budget_kb)
