# Data for vignettes/segment-discharge.Rmd (#28), which runs on these files and
# never touches fwapg, PCIC or the province run at build.
#
#   Rscript data-raw/segment_vignette_data.R
#
# Runs scripts/mad_parity.R SALR itself (a few minutes once PCIC is cached in
# data/pcic/), so its data/parity/SALR_*.csv come from the same commit as
# everything else here.
#
# Writes inst/vignette-data/segment_values.rds, a list:
#   - parity: one row summarising wet's rebuild of fwapg on SALR from PCIC
#     VIC-GL (fwapg mode: centroid sampling, fwapg's stored upstream area): the
#     segments fwapg has a mean annual discharge for, how many match it to the
#     five decimals fwapg stores, and the largest relative difference
#   - sampling: per SALR watershed with a stream, wet's mean annual runoff (mm)
#     with centroid and with area-weighted sampling, and its upstream area
#   - segments: per order >= 3 segment of SALR and BULK (segment_map.rds), mean
#     annual discharge from the open water balance (#11) and from PCIC's routed
#     flow (NewGraphEnvironment/fwapg#6, #58)
#   - skill: the shipped fit's calibration stations, with their held-out
#     (blocked-CV) error on annual runoff, the segment and watershed each
#     snapped to, zone, nesting and area, whether it lies in a group routed flow
#     covers (in_routed), and routed mean annual runoff on the gauge's segment
#     (routed_mm; NA where the segment has none), so both estimates are scored
#     on one set, as scripts/pcic_routed_compare.R scores them
#   - gauges_salr: the calibration gauges within 30 km of SALR and its outlet
#     gauge, with their location and observed, held-out water-balance and
#     routed mean annual runoff, to say which estimate the gap between them on
#     SALR belongs to
#   - provenance: the runs and reports these came from, and the numbers the
#     vignette quotes about them
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
# what built them: the code, and the tracked reports parsed below. Refuse
# uncommitted changes to either. system2() only warns when git fails and
# returns character(0), which would read as a clean tree, so check its status.
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data-raw", "data/checks")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the data:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
stopifnot(length(wet_commit) == 1, nzchar(wet_commit))

# the routed table must be the one the tracked report scored, built at the
# commit it names: checked before the minutes-long parity run below
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
fwapg_commit <- routed_commit()
f_routed <- wb_report("pcic_routed_compare", wb_release())
rr <- readLines(f_routed)
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
routed_fp <- routed_fingerprint(conn)
DBI::dbDisconnect(conn)
if (!any(rr == sprintf("routed: %s, built by NewGraphEnvironment/fwapg at %s", routed_table, fwapg_commit)) ||
    !any(rr == sprintf("table: %s", routed_fp))) {
  stop(f_routed, " was not made from this routed table at fwapg ", fwapg_commit, ": rerun scripts/pcic_routed_compare.R")
}

# PCIC through wet on SALR, from this commit's code: the old outputs go first,
# so a failed run cannot leave an earlier one to be read
f_par <- file.path("data", "parity", "SALR_parity.csv")
f_area <- file.path("data", "parity", "SALR_area_total.csv")
unlink(c(f_par, f_area))
f_log <- file.path("data", "parity", "SALR_run.log")
rc <- system2("Rscript", c("scripts/mad_parity.R", "SALR"), stdout = f_log, stderr = f_log)
if (rc != 0 || !all(file.exists(c(f_par, f_area)))) stop("scripts/mad_parity.R SALR failed: see ", f_log)

source("scripts/wb_cv_lib.R")  # load_all(), key_dir, cal, groups, score_code_md5

min_order <- 3
wsg <- c("SALR", "BULK")
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
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
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
# fwapg's annual table on the two groups: the parity rebuild's segments
n_fwapg <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.watershed_group_code, count(d.linear_feature_id)::int AS n
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_stream_networks_discharge d USING (linear_feature_id)
  WHERE s.watershed_group_code IN (%s) GROUP BY 1", paste0("'", wsg, "'", collapse = ", ")))
# the calibration stations in each group, by the watershed their gauge snapped to
st_wsg <- DBI::dbGetQuery(conn, sprintf("
  SELECT watershed_feature_id, watershed_group_code FROM whse_basemapping.fwa_watersheds_poly
  WHERE watershed_feature_id IN (%s)", paste(sk$watershed_feature_id, collapse = ", ")))
# routed mean annual runoff on each calibration gauge's segment, in mm over
# wet's accumulated upstream area, as scripts/pcic_routed_compare.R takes it
ra <- routed_annual(conn, sk$linear_feature_id)
sk$routed_mm <- routed_mm(ra$q_m3s[match(sk$linear_feature_id, ra$linear_feature_id)], sk$upstream_area_m2)
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
near <- sk[sk$salr_km <= near_km | sk$station_number %in% outlet, ]
seg_routed <- routed_annual(conn, seg$linear_feature_id)
DBI::dbDisconnect(conn)
stopifnot(nrow(near) > 0, !anyNA(near$routed_mm))
gauges_salr <- data.frame(station_number = near$station_number, station_name = near$station_name,
                          holds_salr = near$station_number %in% outlet,
                          lon = near$lon, lat = near$lat,
                          area_km2 = near$area_km2, km_from_salr = near$salr_km,
                          obs_mm = near$obs, wb_mm = near$mod, routed_mm = near$routed_mm)
print(gauges_salr)
sk$salr_km <- NULL
sk$watershed_group_code <- st_wsg$watershed_group_code[match(sk$watershed_feature_id, st_wsg$watershed_feature_id)]
stopifnot(!anyNA(sk$watershed_group_code), !anyDuplicated(seg$linear_feature_id))
# routed flow is scored at every gauge whose segment carries it, as the
# report scores it; in_routed says whether the gauge's group is in the
# coverage the province map outlines
sk$in_routed <- sk$watershed_group_code %in% routed_groups
print(table(in_routed = sk$in_routed, routed = !is.na(sk$routed_mm)))
n_fwapg <- stats::setNames(n_fwapg$n, n_fwapg$watershed_group_code)

# ---- the tracked report is the published record ------------------------------------------------
# the gauges' routed scores must be its rows, from the same table and commit
stopifnot(identical(f_routed, wb_report("pcic_routed_compare", release)))
rr_all <- strsplit(trimws(grep("^all +", rr, value = TRUE)[1]), " +")[[1]]
both <- sk[!is.na(sk$routed_mm), ]
r_sc <- routed_scores(100 * (both$routed_mm / both$obs - 1))
w_sc <- routed_scores(both$err_pct)
stopifnot(as.integer(rr_all[2]) == nrow(both),
          as.numeric(rr_all[3]) == round(r_sc[["mae"]], 1), as.numeric(rr_all[4]) == round(w_sc[["mae"]], 1))

# ---- PCIC through wet on SALR (scripts/mad_parity.R, run above) -----------------------------------
par <- utils::read.csv(f_par)
stopifnot(nrow(par) == n_fwapg[["SALR"]], !anyNA(par$mad_m3s_wet), !anyNA(par$mad_m3s_fwapg))
parity <- data.frame(n_segments = nrow(par),
                     n_match5 = sum(round(par$mad_m3s_wet, 5) == round(par$mad_m3s_fwapg, 5)),
                     max_rel_diff = max(abs(par$mad_m3s_wet / par$mad_m3s_fwapg - 1)))
print(parity)
stopifnot(parity$n_match5 == parity$n_segments)   # the vignette says every segment matches
# one value per watershed in each build; the area-weighted file holds every
# watershed in the group, the parity file those with a stream segment
cen <- unique(par[c("watershed_feature_id", "mad_mm_wet")])
stopifnot(!anyDuplicated(cen$watershed_feature_id))
aw <- utils::read.csv(f_area)
sampling <- merge(stats::setNames(cen, c("watershed_feature_id", "mm_centroid")),
                  data.frame(watershed_feature_id = aw$watershed_feature_id, mm_area = aw$mad_mm,
                             upstream_area_km2 = aw$upstream_area_m2 / 1e6),
                  by = "watershed_feature_id")
stopifnot(nrow(sampling) == nrow(cen), !anyNA(sampling))

# ---- the open water balance per segment ----------------------------------------------------------
# SALR lies in the Fraser (100), BULK in the Skeena (400)
basin_of <- c(SALR = "100", BULK = "400")
wb <- do.call(rbind, lapply(basin_of, function(b) {
  x <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(b, ".parquet"))))
  x <- x[x$month == 0 & x$watershed_feature_id %in% seg$watershed_feature_id, ]
  x[c("watershed_feature_id", "discharge_m3s", "coverage", "bc_fraction")]
}))
segments <- data.frame(
  linear_feature_id = seg$linear_feature_id,
  watershed_group_code = seg$watershed_group_code,
  mad_wb_m3s = wb$discharge_m3s[match(seg$watershed_feature_id, wb$watershed_feature_id)],
  mad_routed_m3s = seg_routed$q_m3s[match(seg$linear_feature_id, seg_routed$linear_feature_id)]
)
cov <- wb$coverage[match(seg$watershed_feature_id, wb$watershed_feature_id)]
print(table(segments$watershed_group_code, is.na(segments$mad_wb_m3s), dnn = c("group", "wb NA")))
# a segment with no watershed in the lut has no value in either product
print(table(segments$watershed_group_code, is.na(segments$mad_routed_m3s), dnn = c("group", "routed NA")))
stopifnot(all(is.na(segments$mad_wb_m3s) == is.na(seg$watershed_feature_id)),
          all(cov[!is.na(cov)] >= 0.99))

# ---- provenance -------------------------------------------------------------------------------------
# fwapg's stored upstream area against the live accumulation, Fraser-wide
# (scripts/upstream_area_check.R): the vignette quotes it
ua <- readLines("data/checks/upstream_area_100_full.txt")
ua_line <- grep("^polygons:", ua, value = TRUE)
ua_mis <- as.integer(sub(".*mismatches > 1e-9: ([0-9]+).*", "\\1", grep("^max relative", ua, value = TRUE)))
ua_poly <- as.integer(sub("^polygons: ([0-9]+).*", "\\1", ua_line))
stopifnot(!is.na(ua_mis), !is.na(ua_poly))
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
  # SALR segments whose MAD moves between fwapg's stored upstream area and the
  # live accumulation (the vignette's stale-snapshot bullet)
  salr_stale_segments = sum(abs(par$mad_m3s_live - par$mad_m3s_wet) > 1e-9 * par$mad_m3s_wet),
  # fwapg's annual table on the two groups: the parity rebuild's segments
  fwapg_discharge_rows = n_fwapg,
  # routed flow (fwapg#6): the commit that built the table and its fingerprint
  routed_commit = fwapg_commit,
  routed_fingerprint = routed_fp,
  routed_report = f_routed,
  routed_groups = length(routed_groups),
  routed_cov_share = cov_share,
  # in the groups routed flow covers: their segments, and those it reaches
  routed_cov_rows = c(rows = sum(routed_cov$n_rows[routed_cov$watershed_group_code %in% routed_groups]),
                      values = sum(routed_cov$n_values[routed_cov$watershed_group_code %in% routed_groups])),
  routed_order8 = c(segments = routed_large$segments, valued = routed_large$valued),
  upstream_area_100 = c(polygons = ua_poly, stale = ua_mis)
)

# fwapg's bigint ids reach R as integer64, which readRDS() without bit64 reads
# as raw bits, so a join in the vignette would match nothing: the SQL casts them
no64 <- function(x) !any(vapply(x, inherits, NA, "integer64"))
stopifnot(no64(parity), no64(sampling), no64(segments), no64(sk), no64(gauges_salr))
values <- list(parity = parity, sampling = sampling, segments = segments, skill = sk,
               gauges_salr = gauges_salr, provenance = provenance)
saveRDS(values, out, compress = "xz")
message("segment_values.rds: ", round(file.size(out) / 1024), " KB")
files <- file.path("inst", "vignette-data", c("segment_values.rds", "segment_map.rds"))
kb <- sum(file.size(files)) / 1024
message("vignette data for #28: ", round(kb), " KB of ", budget_kb)
stopifnot(all(file.exists(files)), kb < budget_kb)
