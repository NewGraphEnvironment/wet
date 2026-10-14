# Data for vignettes/segment-discharge.Rmd (#28, #64), which runs on these
# files and never touches fwapg, the network or the province run at build.
#
#   WET_FWAPG_COMMIT=<sha> Rscript data-raw/segment_vignette_data.R
#
# Every segment value it bundles is read from the published product
# (wet_catalog(): the manifest at s3://fresh-bc/discharge/fwa/v1/), and the
# script refuses to write unless each one equals what it was built from: the
# balance's month-0 flow in the shipped fit's output (through the lut that
# gives a segment its watershed), and routed flow's mean of twelve months in
# fwapg's routed table (scripts/pcic_routed_lib.R). The parts are checked
# against their manifest md5s before and after the read, so a read during a
# publish is refused.
#
# Writes inst/vignette-data/segment_values.rds, a list:
#   - segments: per order >= 3 segment of SALR (segment_map.rds), the
#     published annual flow (month 0) from the open water balance (#11) and
#     from PCIC's routed flow (NewGraphEnvironment/fwapg#6, #58), and the
#     source the published `pick` selects
#   - skill: the shipped fit's calibration stations, with their held-out
#     (blocked-CV) error on annual runoff, the segment and watershed each
#     snapped to, zone, nesting and area, whether it lies in a group routed flow
#     covers (in_routed), and the published routed annual runoff on the gauge's
#     segment (routed_mm; NA where it has none), so both estimates are scored
#     on one set, as scripts/pcic_routed_compare.R scores them
#   - gauges_salr: the calibration gauges within 30 km of SALR and its outlet
#     gauge, with their location and observed, held-out water-balance and
#     routed mean annual runoff, to say which estimate the gap between them on
#     SALR belongs to
#   - provenance: the runs, reports and published build these came from, the
#     value checks against the published parts, and the numbers the vignette
#     quotes about them
#
# The water-balance inputs are the shipped fit (scripts/wb_fit_lib.R: the
# province run under data/wb/ and one HYDAT release; scripts wb_province.R,
# wb_stations.R, wb_validate.R and wb_output.R). The script refuses a fit
# whose scores or AET choice were made under other scoring code.
# Routed flow is scripts/pcic_routed_lib.R's, from the table WET_FWAPG_COMMIT
# names; the script refuses a table or a commit other than the ones the tracked
# report (data/checks/pcic_routed_compare_<release>.txt) was made from.
# fwapg from the WET_PG* variables.

# The vignette cites the commit these were built at, so that commit must hold
# what built them; the routed table must be the one the tracked report scored
# (scripts/vignette_data_lib.R holds both guards)
source("scripts/vignette_data_lib.R")
wet_commit <- vd_commit()
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
rc <- vd_routed_check()
fwapg_commit <- rc$commit
routed_fp <- rc$fingerprint
f_routed <- rc$report
rr <- rc$lines

source("scripts/wb_cv_lib.R")  # load_all(), key_dir, cal, groups, score_code_md5

min_order <- 3
wsg <- "SALR"
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
seg <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.linear_feature_id::int AS linear_feature_id, s.watershed_group_code,
         l.watershed_feature_id::int AS watershed_feature_id
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  WHERE s.watershed_group_code IN (%s) AND s.stream_order >= %d",
  paste0("'", wsg, "'", collapse = ", "), min_order))
# the watershed groups routed flow covers: a group counts when at least half
# its segments carry routed flow (data-raw/segment_vignette_map.R draws the
# same rule). The table holds only routed segments, no null rows
cov_share <- 0.5
routed_cov <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.watershed_group_code, count(*)::int AS n_rows, count(r.linear_feature_id)::int AS n_values
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN (SELECT linear_feature_id FROM %s WHERE month = 1) r USING (linear_feature_id)
  GROUP BY 1", routed_table))
routed_groups <- routed_cov$watershed_group_code[routed_cov$n_values >= cov_share * routed_cov$n_rows]
print(routed_cov[routed_cov$n_values > 0 & !routed_cov$watershed_group_code %in% routed_groups, ])
in_groups <- paste0("'", routed_groups, "'", collapse = ", ")
# routed flow reaches the largest rivers: its values on segments of order 8 and
# up in the groups it covers, which the vignette quotes
routed_large <- DBI::dbGetQuery(conn, sprintf("
  SELECT count(*)::int AS segments, count(r.linear_feature_id)::int AS valued
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN (SELECT linear_feature_id FROM %s WHERE month = 1) r USING (linear_feature_id)
  WHERE s.watershed_group_code IN (%s) AND s.stream_order >= 8", routed_table, in_groups))
stopifnot(routed_large$segments > 0)
# the table must not have changed since the check above
stopifnot(identical(routed_fingerprint(conn), routed_fp))
# the calibration stations in each group, by the watershed their gauge snapped to
st_wsg <- DBI::dbGetQuery(conn, sprintf("
  SELECT watershed_feature_id, watershed_group_code FROM whse_basemapping.fwa_watersheds_poly
  WHERE watershed_feature_id IN (%s)", paste(sk$watershed_feature_id, collapse = ", ")))
# the group of each gauge's segment, which is the one the published parts carry
seg_grp_gauge <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code FROM whse_basemapping.fwa_stream_networks_sp
  WHERE linear_feature_id IN (%s)", paste(unique(sk$linear_feature_id), collapse = ", ")))
stopifnot(setequal(seg_grp_gauge$linear_feature_id, sk$linear_feature_id))
# the calibration gauges near SALR, to arbitrate between the two products there:
# those within 30 km, and the smallest whose basin holds the whole group (its
# outlet gauge)
near_km <- 30
sk_pts <- sf::st_transform(sf::st_as_sf(sk, coords = c("lon", "lat"), crs = 4326), 3005)
salr <- sf::st_read(conn, quiet = TRUE, query = "
  SELECT geom FROM whse_basemapping.fwa_watershed_groups_poly WHERE watershed_group_code = 'SALR'")
sk$salr_km <- as.numeric(sf::st_distance(sk_pts, salr)) / 1000
# a gauge holds the group when its polygons are upstream of the gauge's
# watershed: 4,586 of SALR's 4,587 are by fwa_upstream() at 08KC001, so the
# test is 99 %, not all
holds <- DBI::dbGetQuery(conn, sprintf("
  SELECT g.watershed_feature_id, count(*)::int AS n
  FROM whse_basemapping.fwa_watersheds_poly g
  JOIN whse_basemapping.fwa_watersheds_poly s
    ON s.watershed_group_code = 'SALR'
   AND whse_basemapping.fwa_upstream(g.wscode_ltree, g.localcode_ltree, s.wscode_ltree, s.localcode_ltree)
  WHERE g.watershed_feature_id IN (%s) GROUP BY 1", paste(sk$watershed_feature_id, collapse = ", ")))
n_salr <- DBI::dbGetQuery(conn, "
  SELECT count(*)::int FROM whse_basemapping.fwa_watersheds_poly WHERE watershed_group_code = 'SALR'")[[1]]
holds <- sk[sk$watershed_feature_id %in% holds$watershed_feature_id[holds$n >= 0.99 * n_salr], ]
outlet <- holds$station_number[which.min(holds$area_km2)]
stopifnot(length(outlet) == 1)
# fwapg's routed annual flow on SALR's segments and each calibration gauge's,
# in one query, so a segment that is both has one value: what the published
# values must equal (below)
src_routed <- routed_annual(conn, c(seg$linear_feature_id, sk$linear_feature_id))
DBI::dbDisconnect(conn)
sk$watershed_group_code <- st_wsg$watershed_group_code[match(sk$watershed_feature_id, st_wsg$watershed_feature_id)]
stopifnot(!anyNA(sk$watershed_group_code), !anyDuplicated(seg$linear_feature_id))

# ---- the published product ------------------------------------------------------------------------
# the live manifest must be the build the tracked publish report checked
# value by value, with nothing failed (vd_published())
pb <- vd_published(release)
cat_pub <- pb$catalog
f_pub <- pb$report
reader <- pb$reader
# Month 0 of both sources in SALR, from the Fraser's parts (100), and of
# routed flow on every gauge's segment, from the routed parts: a read filtered
# on watershed_group_code opens only those groups' row groups. The parts must
# match their manifest before and after
parts <- cat_pub[cat_pub$dataset == "discharge/fwa/v1/segment_monthly" & cat_pub$scenario == "historical", ]
verify <- function() vd_verify(parts)
verify()
duck <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(duck, "LOAD httpfs"))
read_pub <- function(hrefs, groups) {
  DBI::dbGetQuery(duck, sprintf("
    SELECT source, linear_feature_id, watershed_group_code, month, q_m3s, pick
    FROM read_parquet([%s], hive_partitioning = true)
    WHERE month = 0 AND watershed_group_code IN (%s)",
    paste0("'", hrefs, "'", collapse = ", "), paste0("'", groups, "'", collapse = ", ")))
}
t_read <- Sys.time()
pub_salr <- read_pub(parts$href[parts$code == "100"], wsg)
# a gauge's group is its segment's, as the parts are sorted by it
gauge_groups <- sort(unique(seg_grp_gauge$watershed_group_code))
pub_gauge <- read_pub(parts$href[parts$source == "pcic_routed"], gauge_groups)
message("published read: ", round(as.numeric(difftime(Sys.time(), t_read, units = "secs"))), " s")
DBI::dbDisconnect(duck, shutdown = TRUE)
verify()
pub <- unique(rbind(pub_salr, pub_gauge))
stopifnot(setequal(unique(pub$source), c("pcic_routed", "wet_balance")),
          !anyDuplicated(pub[c("source", "linear_feature_id")]))
pub_r <- pub[pub$source == "pcic_routed", ]
pub_b <- pub[pub$source == "wet_balance", ]
# the published routed annual flow on each gauge's segment, in mm over wet's
# accumulated upstream area, as scripts/pcic_routed_compare.R takes it
sk$routed_mm <- routed_mm(pub_r$q_m3s[match(sk$linear_feature_id, pub_r$linear_feature_id)], sk$upstream_area_m2)
near <- sk[sk$salr_km <= near_km | sk$station_number %in% outlet, ]
stopifnot(nrow(near) > 0, !anyNA(near$routed_mm))
gauges_salr <- data.frame(station_number = near$station_number, station_name = near$station_name,
                          holds_salr = near$station_number %in% outlet,
                          lon = near$lon, lat = near$lat,
                          area_km2 = near$area_km2, km_from_salr = near$salr_km,
                          obs_mm = near$obs, wb_mm = near$mod, routed_mm = near$routed_mm)
print(gauges_salr)
sk$salr_km <- NULL
# routed flow is scored at every gauge whose segment carries it, as the
# report scores it; in_routed says whether the gauge's group is in the
# coverage the province map outlines
sk$in_routed <- sk$watershed_group_code %in% routed_groups
print(table(in_routed = sk$in_routed, routed = !is.na(sk$routed_mm)))

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
# SALR lies in the Fraser (100)
wb <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", "100.parquet")))
wb <- wb[wb$month == 0 & wb$watershed_feature_id %in% seg$watershed_feature_id, ]
# the balance on each SALR segment from the fit's output through the lut, and
# routed flow's mean of twelve months from fwapg, on SALR's segments and every
# gauge's: each published value must equal its source, and no source value may
# be missing from the product, nor any published one lack a source
at0 <- function(id, q) data.frame(linear_feature_id = id, month = 0L, q_m3s = q)
src_b <- seg[!is.na(seg$watershed_feature_id), ]
src_b <- at0(src_b$linear_feature_id, wb$discharge_m3s[match(src_b$watershed_feature_id, wb$watershed_feature_id)])
src_b <- src_b[!is.na(src_b$q_m3s), ]
src_r <- src_routed[!is.na(src_routed$q_m3s), ]
src_r <- at0(src_r$linear_feature_id, src_r$q_m3s)
in_salr <- pub$watershed_group_code %in% wsg & pub$linear_feature_id %in% seg$linear_feature_id
pb_salr <- pub_b[pub_b$linear_feature_id %in% seg$linear_feature_id, ]
pr_used <- pub_r[pub_r$linear_feature_id %in% c(seg$linear_feature_id, sk$linear_feature_id), ]
# the balance is copied from a double, so it must match exactly; routed month
# 0 is R's mean() at publish and SQL avg() here, which differ in the last bits
cmp <- list(
  "balance (SALR) = fit output via lut" =
    wet_values_compare(at0(pb_salr$linear_feature_id, pb_salr$q_m3s), src_b, tol = 0),
  "routed (SALR and gauges) = fwapg mean of 12 months" =
    wet_values_compare(at0(pr_used$linear_feature_id, pr_used$q_m3s), src_r)
)
pub_check <- data.frame(check = names(cmp), do.call(rbind, cmp), row.names = NULL)
print(pub_check)
# no value differs, and every source value was compared (a check of nothing passes nothing)
if (any(pub_check$differing > 0) || !identical(pub_check$compared, as.numeric(c(nrow(src_b), nrow(src_r)))) ||
      any(pub_check$compared == 0)) {
  stop("the published values differ from what they were built from: see the table above")
}

# the bundled values are the published ones, unrounded
pick_src <- pub$source[pub$pick & in_salr]
segments <- data.frame(
  linear_feature_id = seg$linear_feature_id,
  watershed_group_code = seg$watershed_group_code,
  mad_wb_m3s = pub_b$q_m3s[match(seg$linear_feature_id, pub_b$linear_feature_id)],
  mad_routed_m3s = pub_r$q_m3s[match(seg$linear_feature_id, pub_r$linear_feature_id)],
  pick = pick_src[match(seg$linear_feature_id, pub$linear_feature_id[pub$pick & in_salr])]
)
cov <- wb$coverage[match(seg$watershed_feature_id, wb$watershed_feature_id)]
print(table(wb_na = is.na(segments$mad_wb_m3s), routed_na = is.na(segments$mad_routed_m3s)))
print(table(segments$pick, useNA = "ifany"))
# a segment with no watershed in the lut has no value in either product, and
# every segment with a value has one picked source
stopifnot(all(is.na(segments$mad_wb_m3s) == is.na(seg$watershed_feature_id)),
          all(is.na(segments$pick) == (is.na(segments$mad_wb_m3s) & is.na(segments$mad_routed_m3s))),
          all(cov[!is.na(cov)] >= 0.99))

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
  min_order = min_order,
  near_km = near_km,
  # the published build the segment values were read from, the parts read,
  # and the check of each value against its source
  published = list(manifest = attr(cat_pub, "manifest"), built = attr(cat_pub, "built"),
                   wet_commit = attr(cat_pub, "provenance")$wet_commit,
                   segment_commit = attr(cat_pub, "provenance")$segment_commit,
                   parts = cat_pub[c("dataset", "source", "code", "key", "rows", "bytes", "md5")],
                   reader = reader, report = f_pub),
  published_check = pub_check,
  # routed flow (fwapg#6): the commit that built the table and its fingerprint
  routed_commit = fwapg_commit,
  routed_fingerprint = routed_fp,
  routed_report = f_routed,
  routed_groups = length(routed_groups),
  routed_cov_share = cov_share,
  # in the groups routed flow covers: their segments, and those it reaches
  routed_cov_rows = c(rows = sum(routed_cov$n_rows[routed_cov$watershed_group_code %in% routed_groups]),
                      values = sum(routed_cov$n_values[routed_cov$watershed_group_code %in% routed_groups])),
  routed_order8 = c(segments = routed_large$segments, valued = routed_large$valued)
)

# fwapg's bigint ids reach R as integer64, which readRDS() without bit64 reads
# as raw bits, so a join in the vignette would match nothing: the SQL casts them
no64 <- function(x) !any(vapply(x, inherits, NA, "integer64"))
stopifnot(no64(segments), no64(sk), no64(gauges_salr))
values <- list(segments = segments, skill = sk, gauges_salr = gauges_salr, provenance = provenance)
saveRDS(values, out, compress = "xz")
message("segment_values.rds: ", round(file.size(out) / 1024), " KB")
files <- file.path("inst", "vignette-data", c("segment_values.rds", "segment_map.rds"))
kb <- sum(file.size(files)) / 1024
message("vignette data for #28, #64: ", round(kb), " KB of ", budget_kb)
stopifnot(all(file.exists(files)), kb < budget_kb)
