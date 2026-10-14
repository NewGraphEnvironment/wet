# Data for vignettes/monthly-flow.Rmd (#65), which runs on these files and
# never touches fwapg, HYDAT, the network or the province run at build.
#
#   WET_FWAPG_COMMIT=<sha> WET_HYDAT=<Hydat.sqlite3> Rscript data-raw/monthly_vignette_data.R
#
# The monthly half of the published product (months 1-12 of
# s3://fresh-bc/discharge/fwa/v1/, read through wet_catalog()), on the Bulkley
# gauges' segments and at the shipped fit's calibration gauges. Every published
# value bundled is checked against what it was built from, under the guards
# data-raw/segment_vignette_data.R uses (scripts/vignette_data_lib.R).
#
# Writes inst/vignette-data/monthly_values.rds, a list:
#   - segments: months 0-12 of both sources as published, on the segments
#     the Bulkley gauges 08EE013, 08EE003 and 08EE004 snap to
#     (wet_station_snap()), with period, coverage and pick
#   - gauges: per calibration gauge and month (0-12), observed runoff (the
#     fit's complete years, 1981-2010), the balance held out by the fit's
#     blocked CV, and routed PCIC on the gauge's segment as published, all in
#     mm over wet's accumulated upstream area, as scripts/pcic_routed_compare.R
#     takes them; with the gauge's group, zone, nesting, area class and
#     whether it is a lake outlet
#   - provenance: the runs, reports and published build these came from, and
#     the value checks against the published parts
#
# The held-out monthly balance is not stored by scripts/wb_validate.R (only its
# annual values and scores are), so it is recomputed here with the same
# procedure (scripts/wb_cv_lib.R's predict_cv()) and refused unless its
# annual values equal the stored ones exactly and its per-station scores equal
# the stored ones.

source("scripts/vignette_data_lib.R")
wet_commit <- vd_commit()
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
rc <- vd_routed_check()
source("scripts/wb_cv_lib.R")  # load_all(), cal, predict_cv(), long(), release, fit_dir

stations_bulk <- c("08EE013", "08EE003", "08EE004")
out <- file.path("inst", "vignette-data", "monthly_values.rds")
budget_kb <- 500

# ---- the balance held out at the calibration gauges, by month ----------------------------------
ho <- shipped_heldout()
fits <- ho$fits
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", fits$aet)))
# what ships is the adjusted balance; raw P - AET has no months to score
stopifnot(fits$keep_adjust, identical(cvr$station_number, cal$station_number))
cal$raw <- wet:::wet_wb_raw(cal, fits$aet)
cv <- predict_cv(cal, cal$fold, cvr$cv_variant)
if (!identical(cv$ann, cvr$cv_ann)) stop("the recomputed held-out annual balance differs from the stored one")
ho_long <- long(cal, cv$ann, cv$share)
sc_new <- wet_flow_validate(ho_long)$stations
sc_old <- cvr$cv_v$stations
cols_sc <- c("station_number", "obs", "mod", "err_pct", "nse_month", "nse_share")
if (!isTRUE(all.equal(sc_new[cols_sc], sc_old[cols_sc], check.attributes = FALSE))) {
  stop("the recomputed held-out scores differ from the stored ones")
}

# ---- fwapg ---------------------------------------------------------------------------------------
hydat <- Sys.getenv("WET_HYDAT")
if (!nzchar(hydat)) stop("set WET_HYDAT to the ", release, " Hydat.sqlite3")
hcon <- wet_hydat_connect(hydat)
st_bulk <- DBI::dbGetQuery(hcon, sprintf("
  SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, LONGITUDE AS lon, LATITUDE AS lat,
         DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
  FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", stations_bulk, "'", collapse = ", ")))
DBI::dbDisconnect(hcon)
stopifnot(setequal(st_bulk$station_number, stations_bulk))

conn <- vd_connect()
snap <- wet_station_snap(conn, st_bulk)
if (!all(snap$accepted)) stop("snap not accepted for: ", paste(snap$station_number[!snap$accepted], collapse = ", "))
snap$linear_feature_id <- as.integer(snap$linear_feature_id)
# a gauge in the calibration set must snap where the fit snapped it
in_cal <- snap$station_number %in% cal$station_number
stopifnot(identical(snap$linear_feature_id[in_cal],
                    as.integer(cal$linear_feature_id[match(snap$station_number[in_cal], cal$station_number)])))
seg_bulk <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.linear_feature_id::int AS linear_feature_id, s.watershed_group_code, s.gnis_name, s.stream_order,
         l.watershed_feature_id::int AS watershed_feature_id
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  WHERE s.linear_feature_id IN (%s)", paste(snap$linear_feature_id, collapse = ", ")))
stopifnot(nrow(seg_bulk) == nrow(snap), !anyNA(seg_bulk$watershed_feature_id),
          all(seg_bulk$watershed_group_code == "BULK"))
seg_bulk <- merge(snap[c("station_number", "linear_feature_id")], seg_bulk, by = "linear_feature_id")

# the group of each calibration gauge's segment, which the published parts carry
cal$linear_feature_id <- as.integer(cal$linear_feature_id)
grp <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code
  FROM whse_basemapping.fwa_stream_networks_sp WHERE linear_feature_id IN (%s)",
  paste(unique(cal$linear_feature_id), collapse = ", ")))
stopifnot(setequal(grp$linear_feature_id, cal$linear_feature_id))
# fwapg's routed months on every segment used, which the published values must equal
ids_used <- unique(c(seg_bulk$linear_feature_id, cal$linear_feature_id))
src_routed <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, month::int AS month, q_m3s
  FROM %s WHERE linear_feature_id IN (%s)", routed_table, paste(ids_used, collapse = ", ")))
stopifnot(identical(routed_fingerprint(conn), rc$fingerprint))
DBI::dbDisconnect(conn)

# ---- the published product ------------------------------------------------------------------------
pb <- vd_published(release)
cat_pub <- pb$catalog
parts <- cat_pub[cat_pub$dataset == "discharge/fwa/v1/segment_monthly" & cat_pub$scenario == "historical", ]
vd_verify(parts)
duck <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(duck, "LOAD httpfs"))
read_pub <- function(hrefs, groups, ids) {
  DBI::dbGetQuery(duck, sprintf("
    SELECT source, linear_feature_id, watershed_group_code, month, q_m3s, runoff_mm, coverage, period, pick
    FROM read_parquet([%s], hive_partitioning = true)
    WHERE watershed_group_code IN (%s) AND linear_feature_id IN (%s)",
    paste0("'", hrefs, "'", collapse = ", "), paste0("'", groups, "'", collapse = ", "),
    paste(ids, collapse = ", ")))
}
t_read <- Sys.time()
# the Bulkley lies in the Skeena (400)
pub_bulk <- read_pub(parts$href[parts$code == "400"], "BULK", seg_bulk$linear_feature_id)
pub_gauge <- read_pub(parts$href[parts$source == "pcic_routed"], sort(unique(grp$watershed_group_code)),
                      cal$linear_feature_id)
message("published read: ", round(as.numeric(difftime(Sys.time(), t_read, units = "secs"))), " s")
DBI::dbDisconnect(duck, shutdown = TRUE)
vd_verify(parts)
for (p in c("pub_bulk", "pub_gauge")) {
  x <- get(p)
  x$linear_feature_id <- as.integer(x$linear_feature_id)
  x$month <- as.integer(x$month)
  assign(p, x)
}
stopifnot(setequal(unique(pub_bulk$source), c("pcic_routed", "wet_balance")),
          !anyDuplicated(pub_bulk[c("source", "linear_feature_id", "month")]),
          !anyDuplicated(pub_gauge[c("linear_feature_id", "month")]))

# ---- the published values against what they were built from ---------------------------------------
wb <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", "400.parquet")))
wb <- wb[wb$watershed_feature_id %in% seg_bulk$watershed_feature_id, ]
src_b <- merge(seg_bulk[c("linear_feature_id", "watershed_feature_id")],
               wb[c("watershed_feature_id", "month", "discharge_m3s")], by = "watershed_feature_id")
names(src_b)[names(src_b) == "discharge_m3s"] <- "q_m3s"
src_r0 <- stats::aggregate(q_m3s ~ linear_feature_id, src_routed[src_routed$linear_feature_id %in% seg_bulk$linear_feature_id, ],
                           function(q) if (length(q) == 12) mean(q) else NA_real_)
src_r0$month <- 0L
pb_b <- pub_bulk[pub_bulk$source == "wet_balance", ]
pr_b0 <- pub_bulk[pub_bulk$source == "pcic_routed" & pub_bulk$month == 0, ]
pr_m <- unique(rbind(pub_bulk[pub_bulk$source == "pcic_routed" & pub_bulk$month > 0, names(pub_gauge)],
                     pub_gauge[pub_gauge$month > 0, ]))
# copied from a double, so exact; routed month 0 is a mean of twelve, which
# R's mean() at publish and aggregate() here round differently in the last bits
cmp <- list(
  "routed months 1-12 (Bulkley segments and gauges) = fwapg monthly table" =
    wet_values_compare(pr_m[c("linear_feature_id", "month", "q_m3s")], src_routed, tol = 0),
  "routed month 0 (Bulkley segments) = mean of fwapg's 12 months" =
    wet_values_compare(pr_b0[c("linear_feature_id", "month", "q_m3s")], src_r0),
  "balance months 0-12 (Bulkley segments) = fit output via lut" =
    wet_values_compare(pb_b[c("linear_feature_id", "month", "q_m3s")], src_b[c("linear_feature_id", "month", "q_m3s")],
                       tol = 0)
)
pub_check <- data.frame(check = names(cmp), do.call(rbind, cmp), row.names = NULL)
print(pub_check)
# no value differs, and every source value was compared
if (any(pub_check$differing > 0) || any(pub_check$compared == 0) ||
      !identical(pub_check$compared, as.numeric(c(nrow(src_routed), nrow(src_r0), nrow(src_b))))) {
  stop("the published values differ from what they were built from: see the table above")
}

# ---- the tables -----------------------------------------------------------------------------------
segments <- merge(seg_bulk[c("station_number", "linear_feature_id", "gnis_name", "stream_order")],
                  pub_bulk[c("source", "linear_feature_id", "month", "q_m3s", "runoff_mm", "coverage", "period", "pick")],
                  by = "linear_feature_id")
segments <- segments[order(segments$station_number, segments$source, segments$month), ]
rownames(segments) <- NULL
stopifnot(nrow(segments) == 2 * 13 * length(stations_bulk))

# routed PCIC in mm over wet's accumulated area: months by their days, as
# observed runoff is (scripts/wb_cv_lib.R), and month 0 from the published
# annual (the plain mean of twelve) on 365.25 days, as the routed report takes it
days <- c(365.25, wet_month_days())
area <- cal$upstream_area_m2[match(ho_long$station_number, cal$station_number)]
lfid <- cal$linear_feature_id[match(ho_long$station_number, cal$station_number)]
pg <- pub_gauge
q_r <- pg$q_m3s[match(paste(lfid, ho_long$month), paste(pg$linear_feature_id, pg$month))]
gauges <- data.frame(station_number = ho_long$station_number, month = ho_long$month,
                     obs_mm = ho_long$obs, wb_mm = ho_long$mod,
                     routed_mm = q_r * days[ho_long$month + 1] * 86400 / area * 1000)
meta <- cal[c("station_number", "station_name", "lon", "lat", "linear_feature_id", "zone", "nesting",
              "area_km2", "area_class", "lake", "n_years")]
meta$area_class <- as.character(meta$area_class)
meta$watershed_group_code <- grp$watershed_group_code[match(meta$linear_feature_id, grp$linear_feature_id)]
gauges <- merge(meta, gauges, by = "station_number")
gauges <- gauges[order(gauges$station_number, gauges$month), ]
rownames(gauges) <- NULL
stopifnot(nrow(gauges) == 13 * nrow(cal))
# routed PCIC reaches the gauges the tracked report scores it at
n_routed <- sum(!is.na(gauges$routed_mm[gauges$month == 0]))
rr_all <- strsplit(trimws(grep("^all +", rc$lines, value = TRUE)[1]), " +")[[1]]
stopifnot(as.integer(rr_all[2]) == n_routed)
print(table(month = gauges$month, routed = !is.na(gauges$routed_mm))[1:2, ])

# ---- provenance -------------------------------------------------------------------------------------
hydat_release <- sub("^HYDAT release: ", "", grep("^HYDAT release:", readLines(wb_report("stations_wb", release)),
                                                   value = TRUE))
stopifnot(length(hydat_release) == 1)
provenance <- list(
  built = Sys.Date(),
  wet_commit = wet_commit,
  province_run = basename(key_dir),
  release = release,
  aet = fits$aet,
  cv_variant = cvr$cv_variant,
  hydat_release = hydat_release,
  years = range(s$years),
  published = list(manifest = attr(cat_pub, "manifest"), built = attr(cat_pub, "built"),
                   wet_commit = attr(cat_pub, "provenance")$wet_commit,
                   parts = cat_pub[c("dataset", "source", "code", "key", "rows", "bytes", "md5")],
                   reader = pb$reader, report = pb$report),
  published_check = pub_check,
  routed_commit = rc$commit,
  routed_fingerprint = rc$fingerprint,
  routed_report = rc$report,
  snap = snap[c("station_number", "linear_feature_id", "distance_m", "area_ratio")]
)

no64 <- function(x) !any(vapply(x, inherits, NA, "integer64"))
stopifnot(no64(segments), no64(gauges), no64(provenance$snap))
values <- list(segments = segments, gauges = gauges, provenance = provenance)
saveRDS(values, out, compress = "xz")
kb <- file.size(out) / 1024
message("monthly_values.rds: ", round(kb), " KB of ", budget_kb)
stopifnot(kb < budget_kb)
