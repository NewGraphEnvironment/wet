# MAD parity check: rebuild fwapg's mean annual discharge for one watershed
# group from PCIC VIC-GL and diff it against
# whse_basemapping.fwa_stream_networks_discharge (#1, Phase 4).
#
# Then rerun with the two method changes proposed in #1 (area-weighted cell
# extraction, covered-area normalisation) and report how far each moves
# the result.
#
#   Rscript scripts/mad_parity.R [WSG]        # default SALR
#
# Needs a local fwapg (fresh/docker, container `fresh-db`). Connection comes
# from WET_PG* env vars, defaulting to that container; PG* is deliberately
# not read, because it often points at a different server.

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

t0 <- Sys.time()
f_run <- wet_pcic_fetch("RUNOFF", bbox, "1981-01-01", "2010-12-31")
f_base <- wet_pcic_fetch("BASEFLOW", bbox, "1981-01-01", "2010-12-31")
message("fetched in ", format(round(Sys.time() - t0, 1)))

runoff <- terra::rast(f_run)
baseflow <- terra::rast(f_base)
stopifnot(terra::nlyr(runoff) == 10957, terra::nlyr(baseflow) == 10957)

# Same NA mask in both? (If so, summing before or after averaging is identical.)
na_run <- as.vector(is.na(terra::values(runoff[[1]])))
na_base <- as.vector(is.na(terra::values(baseflow[[1]])))
message("NA mask identical: ", identical(na_run, na_base),
        " (", sum(na_run), " NA of ", length(na_run), " cells)")

# fwapg: annual means separately, then add (cdo add).
mad_cell <- wet_runoff_annual(runoff) + wet_runoff_annual(baseflow)
# Sum per day first, then annual: must agree.
mad_cell_b <- wet_runoff_annual(runoff + baseflow)
d_order <- max(abs(terra::values(mad_cell - mad_cell_b)), na.rm = TRUE)
message("max |sum-then-average - average-then-sum| = ", signif(d_order, 3), " mm/yr")

# ---- upstream topology, then every polygon it touches -----------------------
t0 <- Sys.time()
pairs <- wet_upstream_pairs(conn, wsg)
message(nrow(pairs), " upstream pairs in ", format(round(Sys.time() - t0, 1)))

# Group boundaries can cut a mainstem, leaving slivers of the next group
# upstream of the group's lowest polygons. Sample every upstream polygon, not
# only the group's own, or those slivers would count as uncovered.
ws_df <- DBI::dbGetQuery(conn, "
  SELECT watershed_feature_id, watershed_group_code, ST_AsText(geom) wkt
  FROM whse_basemapping.fwa_watersheds_poly
  WHERE watershed_feature_id = ANY($1::integer[])",
  params = list(paste0("{", paste(unique(pairs$id_up), collapse = ","), "}")))
ws <- terra::vect(ws_df$wkt, crs = "EPSG:3005")
ws$watershed_feature_id <- ws_df$watershed_feature_id
n_out <- sum(ws_df$watershed_group_code != wsg)
message(nrow(ws_df), " polygons sampled (", n_out, " outside ", wsg, ")")
stopifnot(setequal(ws_df$watershed_feature_id, pairs$id_up))
w <- terra::project(terra::ext(ws), "EPSG:3005", "EPSG:4326")
stopifnot(w$xmin >= bbox[1], w$ymin >= bbox[2], w$xmax <= bbox[3], w$ymax <= bbox[4])

# ---- parity: centroid sample, total-area denominator -------------------------
build <- function(method, denom) {
  v <- wet_ws_sample(mad_cell, ws, method)
  u <- wet_upstream_mean(pairs, v, denom)
  u$mad_mm <- u$value
  u$mad_m3s <- wet_mm_to_m3s(u$value, u$upstream_area_m2)
  u
}
parity <- build("centroid", "total")

ref <- DBI::dbGetQuery(conn, "
  SELECT s.linear_feature_id, l.watershed_feature_id, d.mad_mm, d.mad_m3s
  FROM whse_basemapping.fwa_stream_networks_sp s
  JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  LEFT JOIN whse_basemapping.fwa_stream_networks_discharge d USING (linear_feature_id)
  WHERE s.watershed_group_code = $1", params = list(wsg))

cmp <- merge(ref, parity[, c("watershed_feature_id", "mad_mm", "mad_m3s", "coverage")],
             by = "watershed_feature_id", suffixes = c("_fwapg", "_wet"), all.x = TRUE)
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
cat("abs diff mad_mm quantiles:", q(cmp$abs_mm[both]), "\n")
worst <- cmp[both, ][order(-abs(cmp$rel_m3s[both])), ][1:10,
  c("linear_feature_id", "watershed_feature_id", "mad_m3s_fwapg", "mad_m3s_wet", "rel_m3s")]
cat("\nworst 10:\n"); print(worst, row.names = FALSE)

# ---- sensitivity: the proposed method changes -------------------------------
cat("\n## Sensitivity vs parity build (per watershed, mad_mm)\n\n")
for (m in list(c("area", "total"), c("centroid", "covered"), c("area", "covered"))) {
  s <- build(m[1], m[2])
  j <- merge(parity[, c("watershed_feature_id", "mad_mm")],
             s[, c("watershed_feature_id", "mad_mm", "coverage")],
             by = "watershed_feature_id", suffixes = c("_p", "_s"))
  r <- (j$mad_mm_s - j$mad_mm_p) / j$mad_mm_p
  # A watershed valued by one build and NA in the other is the largest change
  # of all; count it rather than let na.rm drop it from the summary.
  n_flip <- sum(is.na(j$mad_mm_p) != is.na(j$mad_mm_s))
  cat(sprintf("%-8s / %-7s: median %+.2f%%, 1-99%% [%+.2f%%, %+.2f%%], |change|>5%%: %s, NA in one build only: %d, min coverage %.3f\n",
              m[1], m[2], 100 * stats::median(r, na.rm = TRUE),
              100 * stats::quantile(r, 0.01, na.rm = TRUE),
              100 * stats::quantile(r, 0.99, na.rm = TRUE),
              pct(mean(abs(r) > 0.05, na.rm = TRUE)), n_flip, min(j$coverage, na.rm = TRUE)))
  write.csv(s, file.path(out_dir, sprintf("%s_%s_%s.csv", wsg, m[1], m[2])), row.names = FALSE)
}

DBI::dbDisconnect(conn)
