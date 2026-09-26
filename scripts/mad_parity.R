# MAD parity check: rebuild fwapg's mean annual discharge for one watershed
# group from PCIC VIC-GL and diff it against
# whse_basemapping.fwa_stream_networks_discharge (#1, Phase 4; #2 Phase 3).
#
# Accumulates over the whole basin with wet_upstream_mean() (range sums, no
# pairs), and cross-checks the result against the old pairwise formula
# (wet_upstream_pairs()) on the group. Then reruns with the method changes
# proposed in #1 (area-weighted cells, covered-area denominator).
#
#   Rscript scripts/mad_parity.R [WSG]        # default SALR
#
# The group must be a headwater group: its upstream polygons must fall inside
# the PCIC subset fetched for its extent (checked). For a whole basin use
# scripts/mad_basin.R.
#
# Connection from WET_PG* env vars, defaulting to the local fresh-db container;
# PG* is deliberately not read, because it often points at a different server.

devtools::load_all(quiet = TRUE)

wsg <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(wsg)) wsg <- "SALR"
out_dir <- file.path("data", "parity")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

# ---- PCIC subset for the group's extent, 1981-2010 (fwapg's slice) ----------
bb <- DBI::dbGetQuery(conn, "
  SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT ST_Extent(ST_Transform(geom, 4326)) e
        FROM whse_basemapping.fwa_watershed_groups_poly
        WHERE watershed_group_code = $1) x", params = list(wsg))
bbox <- unlist(bb[1, ]) + c(-1, -1, 1, 1) * 0.0625
message("bbox: ", paste(round(bbox, 4), collapse = ", "))

f_run <- wet_pcic_fetch("RUNOFF", bbox, "1981-01-01", "2010-12-31")
f_base <- wet_pcic_fetch("BASEFLOW", bbox, "1981-01-01", "2010-12-31")
runoff <- terra::rast(f_run)
baseflow <- terra::rast(f_base)
stopifnot(terra::nlyr(runoff) == 10957, terra::nlyr(baseflow) == 10957)

na_run <- as.vector(is.na(terra::values(runoff[[1]])))
na_base <- as.vector(is.na(terra::values(baseflow[[1]])))
message("NA mask identical: ", identical(na_run, na_base),
        " (", sum(na_run), " NA of ", length(na_run), " cells)")

# fwapg: annual means separately, then add (cdo add).
mad_cell <- wet_runoff_annual(runoff) + wet_runoff_annual(baseflow)
mad_cell_b <- wet_runoff_annual(runoff + baseflow)
d_order <- max(abs(terra::values(mad_cell - mad_cell_b)), na.rm = TRUE)
message("max |sum-then-average - average-then-sum| = ", signif(d_order, 3), " mm/yr")

# ---- basin polygons, topology, values ---------------------------------------
basin <- DBI::dbGetQuery(conn, "
  SELECT DISTINCT subltree(wscode_ltree, 0, 1)::text AS b
  FROM whse_basemapping.fwa_watersheds_poly WHERE watershed_group_code = $1",
  params = list(wsg))$b
stopifnot(length(basin) == 1L)
ws <- wet_ws_fetch(conn, basin)
irr <- wet_upstream_irregular(conn, basin)
stored <- DBI::dbGetQuery(conn, "
  SELECT u.watershed_feature_id, u.upstream_area_ha * 10000 AS upstream_area_m2
  FROM whse_basemapping.fwa_watersheds_upstream_area u
  JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
  WHERE w.wscode_ltree <@ $1::ltree", params = list(basin))
message(nrow(ws), " polygons in basin ", basin, ", ", nrow(irr), " irregular pairs")

# Only polygons inside the fetched extent get values; everything else counts as
# uncovered. So the group is valid for parity only if its upstream ground is
# fully covered.
in_bb <- ws$lon >= bbox[1] & ws$lon <= bbox[3] & ws$lat >= bbox[2] & ws$lat <= bbox[4]
cen <- wet_ws_sample(mad_cell, ws[in_bb, c("watershed_feature_id", "lon", "lat")], "centroid")
grp <- ws$watershed_group_code == wsg

build <- function(values, denom, upstream_area = NULL) {
  u <- wet_upstream_mean(ws, values, denom, irregular_pairs = irr,
                         upstream_area = upstream_area)
  u$mad_mm <- u$value
  u$mad_m3s <- wet_mm_to_m3s(u$value, u$upstream_area_m2)
  u
}
parity <- build(cen, "total", upstream_area = stored)  # fwapg mode
live <- build(cen, "total")                            # accumulated upstream area
# Coverage against the accumulated (live) upstream area: the stored table can
# be stale, which would fail a covered group or pass an uncovered one.
if (any(live$coverage[grp] < 1 - 1e-12)) {
  stop(wsg, " has upstream ground outside the fetched extent; not a headwater group",
       call. = FALSE)
}

# ---- cross-check against the old pairwise formula ---------------------------
pairs <- wet_upstream_pairs(conn, wsg)
i <- match(pairs$id_up, cen$watershed_feature_id)
old <- tapply(ifelse(is.na(cen$value[i]), 0, cen$value[i]) * pairs$area_up_m2,
              pairs$watershed_feature_id, sum) /
  tapply(pairs$upstream_area_m2, pairs$watershed_feature_id, `[`, 1)
j <- match(as.integer(names(old)), parity$watershed_feature_id)
d_old <- max(abs(parity$mad_mm[j] - old) / old)
message("range sums vs pairwise join on ", length(old), " ", wsg,
        " watersheds: max relative difference ", signif(d_old, 3))
stopifnot(d_old < 1e-9)

# ---- compare with fwapg -------------------------------------------------------
ref <- DBI::dbGetQuery(conn, "
  SELECT s.linear_feature_id, l.watershed_feature_id, d.mad_mm, d.mad_m3s
  FROM whse_basemapping.fwa_stream_networks_sp s
  JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  LEFT JOIN whse_basemapping.fwa_stream_networks_discharge d USING (linear_feature_id)
  WHERE s.watershed_group_code = $1", params = list(wsg))

# coverage always from the live build: the stored upstream area can be stale
parity$coverage <- live$coverage[match(parity$watershed_feature_id, live$watershed_feature_id)]
cmp <- merge(ref, parity[, c("watershed_feature_id", "mad_mm", "mad_m3s", "coverage")],
             by = "watershed_feature_id", suffixes = c("_fwapg", "_wet"), all.x = TRUE)
lv <- live[match(cmp$watershed_feature_id, live$watershed_feature_id), ]
cmp$mad_m3s_live <- lv$mad_m3s
cmp$rel_m3s <- (cmp$mad_m3s_wet - cmp$mad_m3s_fwapg) / cmp$mad_m3s_fwapg
cmp$abs_mm <- cmp$mad_mm_wet - cmp$mad_mm_fwapg
both <- !is.na(cmp$mad_m3s_fwapg) & !is.na(cmp$mad_m3s_wet) & cmp$mad_m3s_fwapg > 0
write.csv(cmp, file.path(out_dir, paste0(wsg, "_parity.csv")), row.names = FALSE)

pct <- function(x) sprintf("%.2f%%", 100 * x)
q <- function(x) signif(stats::quantile(x, c(0, 0.01, 0.5, 0.99, 1), na.rm = TRUE), 3)
cat("\n## Parity:", wsg, "\n\n")
cat("segments in lut:", nrow(cmp), "| fwapg has value:", sum(!is.na(cmp$mad_m3s_fwapg)),
    "| wet has value:", sum(!is.na(cmp$mad_m3s_wet)), "| compared:", sum(both), "\n")
# fwapg stores both columns rounded to 5 decimals, so parity is "identical
# after the same rounding"; a relative threshold misreads 2e-5 m3/s headwaters.
cat("identical after 5-decimal rounding (mad_m3s):",
    pct(mean(round(cmp$mad_m3s_wet[both], 5) == round(cmp$mad_m3s_fwapg[both], 5))), "\n")
cat("within 0.1% (mad_m3s):", pct(mean(abs(cmp$rel_m3s[both]) <= 0.001)),
    "| of those >= 0.01 m3/s:",
    pct(mean(abs(cmp$rel_m3s[both & cmp$mad_m3s_fwapg >= 0.01]) <= 0.001)), "\n")
cat("within 1e-4 mm (mad_mm):", pct(mean(abs(cmp$abs_mm[both]) <= 1e-4)), "\n")
cat("rel diff mad_m3s quantiles (0,1,50,99,100%):", q(cmp$rel_m3s[both]), "\n")
rl <- (cmp$mad_m3s_live[both] - cmp$mad_m3s_wet[both]) / cmp$mad_m3s_wet[both]
cat("live upstream area vs fwapg's stored table: segments that change:",
    sum(abs(rl) > 1e-9), "| max rel change", signif(max(abs(rl)), 3), "\n")

# ---- sensitivity: the proposed method changes -------------------------------
cat("\n## Sensitivity vs parity build (per watershed, mad_mm)\n\n")
geom <- do.call(rbind, lapply(unique(ws$watershed_group_code[in_bb]), function(g) wet_ws_geom(conn, g)))
area_vals <- wet_ws_sample(mad_cell, geom, "area")
for (m in list(c("area", "total"), c("centroid", "covered"), c("area", "covered"))) {
  vals <- if (m[1] == "area") area_vals else cen
  s <- build(vals, m[2], upstream_area = stored)
  # coverage against the live upstream area, not the possibly stale stored one
  s$coverage <- build(vals, m[2])$coverage
  j <- data.frame(p = parity$mad_mm[grp], s = s$mad_mm[grp], coverage = s$coverage[grp])
  r <- (j$s - j$p) / j$p
  # A watershed valued by one build and NA in the other is the largest change
  # of all; count it rather than let na.rm drop it from the summary.
  n_flip <- sum(is.na(j$p) != is.na(j$s))
  cat(sprintf("%-8s / %-7s: median %+.2f%%, 1-99%% [%+.2f%%, %+.2f%%], |change|>5%%: %s, NA in one build only: %d, min coverage %.3f\n",
              m[1], m[2], 100 * stats::median(r, na.rm = TRUE),
              100 * stats::quantile(r, 0.01, na.rm = TRUE),
              100 * stats::quantile(r, 0.99, na.rm = TRUE),
              pct(mean(abs(r) > 0.05, na.rm = TRUE)), n_flip, min(j$coverage, na.rm = TRUE)))
  write.csv(s[grp, ], file.path(out_dir, sprintf("%s_%s_%s.csv", wsg, m[1], m[2])), row.names = FALSE)
}

DBI::dbDisconnect(conn)
