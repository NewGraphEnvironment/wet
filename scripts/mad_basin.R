# Mean annual discharge for a whole basin, no order-8 skip (#2, Phase 4).
#
#   /usr/bin/time -l Rscript scripts/mad_basin.R [WSCODE]    # default 100 (Fraser)
#
# PCIC VIC-GL historical RUNOFF + BASEFLOW, 1981-2010, fetched and reduced one
# year at a time; centroid (fwapg) and area-weighted sampling; upstream
# accumulation over the whole basin with range sums. Reports:
#   * parity with fwapg's fwa_stream_networks_discharge on every segment fwapg
#     has, by watershed group (fwapg mode: centroid, total denominator, fwapg's
#     stored upstream area),
#   * segments fwapg lacks (its order >= 8 mainstem skip),
#   * sensitivity of area-weighted sampling and the covered denominator,
#   * a sanity check at Fraser River at Hope (HYDAT 08MF005), not a gate.
# Outputs under data/basin/ (gitignored). Connection from WET_PG* env vars.

devtools::load_all(quiet = TRUE)
wscode <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(wscode)) wscode <- "100"
years <- 1981:2010
out_dir <- file.path("data", "basin")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
t_start <- Sys.time()
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

# ---- topology ---------------------------------------------------------------
ws <- wet_ws_fetch(conn, wscode)
irr <- wet_upstream_irregular(conn, wscode)
stored <- DBI::dbGetQuery(conn, "
  SELECT u.watershed_feature_id, u.upstream_area_ha * 10000 AS upstream_area_m2
  FROM whse_basemapping.fwa_watersheds_upstream_area u
  JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
  WHERE w.wscode_ltree <@ $1::ltree", params = list(wscode))
stamp(nrow(ws), " polygons, ", nrow(irr), " irregular pairs")

# ---- PCIC, one year at a time -------------------------------------------------
e <- DBI::dbGetQuery(conn, "
  SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT ST_Extent(geom) e FROM whse_basemapping.fwa_watersheds_poly
        WHERE wscode_ltree <@ $1::ltree) x", params = list(wscode))
ext <- terra::project(terra::ext(unlist(e)[c("xmin", "xmax", "ymin", "ymax")]),
                      "EPSG:3005", "EPSG:4326")
bbox <- c(ext$xmin, ext$ymin, ext$xmax, ext$ymax) + c(-1, -1, 1, 1) * 0.0625
stamp("bbox ", paste(round(bbox, 3), collapse = ", "))
t0 <- Sys.time()
runoff <- wet_pcic_annual("RUNOFF", bbox, years)
baseflow <- wet_pcic_annual("BASEFLOW", bbox, years)
mad_cell <- runoff + baseflow
terra::writeRaster(mad_cell, file.path(out_dir, paste0(wscode, "_mad_cell.tif")), overwrite = TRUE,
                   datatype = "FLT8S")
# NA cells are outside the PCIC model domain (NA on every day)
n_na_any <- sum(is.na(terra::values(mad_cell)))
t_pcic <- as.numeric(Sys.time() - t0, units = "mins")
stamp("PCIC annual in ", round(t_pcic, 1), " min; ", terra::ncell(mad_cell), " cells, ",
      sum(!is.na(terra::values(mad_cell))), " with values")

# ---- sampling -----------------------------------------------------------------
t0 <- Sys.time()
cen <- wet_ws_sample(mad_cell, ws[, c("watershed_feature_id", "lon", "lat")], "centroid")
t_cen <- as.numeric(Sys.time() - t0, units = "secs")
t0 <- Sys.time()
area_vals <- do.call(rbind, lapply(sort(unique(ws$watershed_group_code)), function(g) {
  wet_ws_sample(mad_cell, wet_ws_geom(conn, g), "area")
}))
area_vals <- area_vals[area_vals$watershed_feature_id %in% ws$watershed_feature_id, ]
t_area <- as.numeric(Sys.time() - t0, units = "mins")
stamp("sampled: centroid ", round(t_cen, 1), " s, area ", round(t_area, 1), " min")

# ---- accumulation ---------------------------------------------------------------
build <- function(values, denom, upstream_area = NULL) {
  u <- wet_upstream_mean(ws, values, denom, irregular_pairs = irr, upstream_area = upstream_area)
  u$mad_mm <- u$value
  u$mad_m3s <- wet_mm_to_m3s(u$value, u$upstream_area_m2)
  u
}
t0 <- Sys.time()
fwapg_mode <- build(cen, "total", upstream_area = stored)
t_acc <- as.numeric(Sys.time() - t0, units = "secs")
live <- build(cen, "total")
area_cov <- build(area_vals, "covered")
area_tot <- build(area_vals, "total")
cen_cov <- build(cen, "covered")
stamp("accumulation ", round(t_acc, 1), " s per build")

# ---- segments and fwapg -------------------------------------------------------
seg <- DBI::dbGetQuery(conn, "
  SELECT s.linear_feature_id, s.blue_line_key, s.watershed_group_code, s.stream_order,
         l.watershed_feature_id, d.mad_mm, d.mad_m3s
  FROM whse_basemapping.fwa_stream_networks_sp s
  JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  LEFT JOIN whse_basemapping.fwa_stream_networks_discharge d USING (linear_feature_id)
  WHERE s.wscode_ltree <@ $1::ltree", params = list(wscode))
k <- match(seg$watershed_feature_id, ws$watershed_feature_id)
seg$wet_mm <- fwapg_mode$mad_mm[k]
seg$wet_m3s <- fwapg_mode$mad_m3s[k]
seg$live_m3s <- live$mad_m3s[k]
seg$area_cov_m3s <- area_cov$mad_m3s[k]
seg$coverage <- area_cov$coverage[k]
both <- !is.na(seg$mad_m3s) & !is.na(seg$wet_m3s)
# fwapg stores 5 decimals, and one of the two raster paths carries ~1e-8
# relative float noise (1e-5 mm on 1,000+ mm headwaters), so parity is "within
# half a unit of the 5th decimal plus 1e-7 relative" on both columns.
tol <- function(x) 5e-6 + 1e-7 * abs(x)
seg$same <- NA
seg$same[both] <- abs(seg$wet_m3s[both] - seg$mad_m3s[both]) <= tol(seg$mad_m3s[both]) &
  abs(seg$wet_mm[both] - seg$mad_mm[both]) <= tol(seg$mad_mm[both])

# ---- attribution: reproduce each difference, don't just label it ----------------
# Each cause is accepted only where rebuilding with that cause applied makes
# the segment match fwapg within tolerance.
match_fw <- function(mm, m3s) {
  both & abs(m3s - seg$mad_m3s) <= tol(seg$mad_m3s) & abs(mm - seg$mad_mm) <= tol(seg$mad_mm)
}
seg$cause <- NA_character_
open_ <- function() both & !seg$same & is.na(seg$cause)

# (1) Groups fwapg never valued: its group list comes from
#     fwa_assessment_watersheds_poly and misses some groups with polygons in the
#     basin (LDEN in the Fraser); fwapg counted their ground as zero.
fw_groups <- DBI::dbGetQuery(conn, "
  SELECT DISTINCT watershed_group_code g FROM whse_basemapping.fwa_assessment_watersheds_poly
  WHERE wscode_ltree <@ '100' OR wscode_ltree <@ '200' OR wscode_ltree <@ '300'")$g
cen_fw <- cen
cen_fw$value[!(ws$watershed_group_code[match(cen_fw$watershed_feature_id, ws$watershed_feature_id)] %in% fw_groups)] <- NA
emu1 <- build(cen_fw, "total", upstream_area = stored)
ok1 <- match_fw(emu1$mad_mm[k], emu1$mad_m3s[k])
seg$cause[open_() & ok1] <- "group fwapg never valued (reproduced)"

# (2) Centroid cell flips: fwapg's centroid of a polygon sat in the next cell
#     (cause not established; not the sampler, and not a uniform grid offset).
#     Find, smallest watershed first, the single near-edge polygon upstream
#     whose flip to the neighbouring cell reproduces the remaining gap; then
#     rebuild with all flips. Watersheds whose stored area is stale are left
#     out of the search: their gap has another cause, and a flip fitted to it
#     would break nothing (everything downstream already mismatches).
e0 <- terra::ext(mad_cell); rs <- terra::res(mad_cell)
fx <- ((ws$lon - e0$xmin) / rs[1]) %% 1
fy <- ((ws$lat - e0$ymin) / rs[2]) %% 1
dx_m <- pmin(fx, 1 - fx) * rs[1] * 111320 * cos(ws$lat * pi / 180)
dy_m <- pmin(fy, 1 - fy) * rs[2] * 110574
cand <- which(pmin(dx_m, dy_m) < 1)
nx <- ws$lon[cand] + ifelse(dx_m[cand] <= dy_m[cand], ifelse(fx[cand] < 0.5, -1, 1) * rs[1] / 2, 0)
ny <- ws$lat[cand] + ifelse(dx_m[cand] > dy_m[cand], ifelse(fy[cand] < 0.5, -1, 1) * rs[2] / 2, 0)
v_nb <- terra::extract(mad_cell, cbind(nx, ny))[, 1]
v_own <- cen_fw$value[match(ws$watershed_feature_id[cand], cen_fw$watershed_feature_id)]
delta <- ws$area_m2[cand] * (v_nb - v_own)
ok_c <- !is.na(delta) & delta != 0
cand <- cand[ok_c]; delta <- delta[ok_c]; v_nb <- v_nb[ok_c]
ltree_desc <- function(x, y) x == y | startsWith(x, paste0(y, "."))
up_of <- function(a, b) {  # FWA_Upstream(a, b) for one a over vector b (C collation)
  Wa <- ws$wscode[a]; La <- ws$localcode[a]; Wb <- ws$wscode[b]; Lb <- ws$localcode[b]
  withr::with_collate("C", if (Wa == La) ltree_desc(Wb, Wa) & ltree_desc(Lb, La) else
    ltree_desc(Wb, Wa) & ((Wb > La & !ltree_desc(Wb, La) & ltree_desc(Lb, Wa) & Lb > La) |
                          (Wb == Wa & Lb >= La)))
}
acc_area <- wet_upstream_sums(ws, "area_m2", irregular_pairs = irr)$area_m2
st_area <- stored$upstream_area_m2[match(ws$watershed_feature_id, stored$watershed_feature_id)]
stale <- is.na(st_area) | abs(acc_area - st_area) > 1e-9 * acc_area
open_ws <- unique(seg$watershed_feature_id[open_() & !stale[k]])
ai <- match(open_ws, ws$watershed_feature_id)
ai <- ai[order(stored$upstream_area_m2[match(ws$watershed_feature_id[ai], stored$watershed_feature_id)])]
fw_mm <- tapply(seg$mad_mm, seg$watershed_feature_id, `[`, 1)
flip <- integer()
for (a in ai) {
  up_a <- stored$upstream_area_m2[match(ws$watershed_feature_id[a], stored$watershed_feature_id)]
  fm <- fw_mm[[as.character(ws$watershed_feature_id[a])]]
  tn <- tol(fm) * up_a  # the parity tolerance, in numerator units (mm * m2)
  inside <- up_of(a, cand)
  gap <- (fm - emu1$mad_mm[a]) * up_a - sum(delta[inside & cand %in% flip])
  if (abs(gap) <= tn) next
  hit <- which(inside & !(cand %in% flip) & abs(delta - gap) <= tn)
  if (length(hit)) flip <- c(flip, cand[hit[which.min(abs(delta[hit] - gap))]])
}
cen_fl <- cen_fw
fi <- match(ws$watershed_feature_id[flip], cen_fl$watershed_feature_id)
cen_fl$value[fi] <- v_nb[match(flip, cand)]
emu2 <- build(cen_fl, "total", upstream_area = stored)
ok2 <- match_fw(emu2$mad_mm[k], emu2$mad_m3s[k])
seg$cause[open_() & ok2] <- "centroid flipped to the next cell (reproduced)"

# (3) fwapg's segment-to-watershed lookup was older: its value for the segment
#     equals wet's value for another watershed on the same stream.
rows <- which(open_())
bl <- seg[seg$blue_line_key %in% seg$blue_line_key[rows], c("blue_line_key", "watershed_feature_id")]
bl$mm <- emu2$mad_mm[match(bl$watershed_feature_id, ws$watershed_feature_id)]
bl$m3s <- emu2$mad_m3s[match(bl$watershed_feature_id, ws$watershed_feature_id)]
for (r in rows) {
  # both columns: on a long mainstem neighbouring watersheds differ by less
  # than the mm tolerance, so mm alone matches by coincidence
  sel <- bl$blue_line_key == seg$blue_line_key[r] & bl$watershed_feature_id != seg$watershed_feature_id[r]
  if (any(abs(bl$mm[sel] - seg$mad_mm[r]) <= tol(seg$mad_mm[r]) &
          abs(bl$m3s[sel] - seg$mad_m3s[r]) <= tol(seg$mad_m3s[r]), na.rm = TRUE))
    seg$cause[r] <- "fwapg segment-to-watershed lookup older (reproduced)"
}

# (4) Not reproduced: fwapg's own stored upstream area disagrees with the live
#     polygons (a necessary condition for "built on older polygons", not proof).
seg$cause[open_() & stale[k]] <- "fwapg stored area stale (consistent with older polygons; not reproduced)"
seg$cause[open_()] <- "unexplained"
n_flip_src <- length(flip)
# A spurious flip (or zeroing) would break segments downstream that matched
# before; the rebuilds must not lose any match, or the attribution is void.
broke1 <- sum(seg$same & !ok1, na.rm = TRUE)
broke2 <- sum(seg$same & !ok2, na.rm = TRUE)
flip_dist <- pmin(dx_m, dy_m)[flip]
flip_stale <- sum(stale[flip])
arrow_ok <- requireNamespace("arrow", quietly = TRUE)

pct <- function(x) sprintf("%.3f%%", 100 * mean(x))
cat("\n## Basin", wscode, "- mean annual discharge, PCIC VIC-GL historical 1981-2010\n\n")
cat("segments:", nrow(seg), "| fwapg has value:", sum(!is.na(seg$mad_m3s)),
    "| wet has value:", sum(!is.na(seg$wet_m3s)), "| compared:", sum(both), "\n")
cat("matches fwapg within rounding (mad_mm and mad_m3s):", pct(seg$same[both]),
    "(", sum(!seg$same[both]), "differ )\n")
gb <- stats::aggregate(same ~ watershed_group_code, data = seg[both, ], FUN = mean)
cat("watershed groups compared:", nrow(gb), "| groups at 100%:", sum(gb$same == 1), "\n")
for (g in c("SALR", "LSAL", "BOWR", "LFRA", "FRCN")) {
  x <- seg[both & seg$watershed_group_code == g, ]
  if (nrow(x)) cat(sprintf("  %s: %d segments, identical %s\n", g, nrow(x), pct(x$same)))
}
cat("cells outside the PCIC domain (NA):", n_na_any, "of", terra::ncell(mad_cell),
    "| centroids within 1 m of a cell edge:", length(cand), "| flips needed to reproduce fwapg:", n_flip_src, "\n")
cat("flipped centroids' distance to the cell edge (m):", paste(sprintf("%.3f", sort(flip_dist)), collapse = ", "),
    "| groups:", paste(ws$watershed_group_code[flip], collapse = " "), "\n")
cat("segments that matched before and not after the rebuilds (must be 0): never-valued",
    broke1, "| flips", broke2, "| flipped polygons with a stale stored area (must be 0):", flip_stale,
    if (broke1 + broke2 + flip_stale > 0) "  ** ATTRIBUTION VOID **" else "", "\n")
# same-side near-edge centroids closer than the farthest flip that match
# unflipped: if any exist, a uniform grid offset cannot explain the flips
far <- max(flip_dist)
nf <- setdiff(cand[pmin(dx_m, dy_m)[cand] <= far], flip)
cat("near-edge centroids closer than the farthest flip (", sprintf("%.3f", far), " m) that match unflipped:",
    length(nf), "\n")
if (any(!seg$same[both])) {
  bad <- seg[both & !seg$same, ]
  cat("\nnot identical, by cause (segments | watersheds):\n")
  for (cz in sort(unique(bad$cause))) cat(sprintf("  %-75s %6d | %5d\n", cz, sum(bad$cause == cz),
    length(unique(bad$watershed_feature_id[bad$cause == cz]))))
  cat("\nnot identical, by group:\n"); print(utils::head(sort(table(bad$watershed_group_code), decreasing = TRUE), 15))
  cat("largest relative differences:\n")
  bad$rel <- (bad$wet_m3s - bad$mad_m3s) / bad$mad_m3s
  print(utils::head(bad[order(-abs(bad$rel)), c("linear_feature_id", "watershed_group_code",
    "stream_order", "mad_m3s", "wet_m3s", "live_m3s")], 10), row.names = FALSE)
}
new <- is.na(seg$mad_m3s) & !is.na(seg$wet_m3s)
cat("\nsegments fwapg lacks that wet values:", sum(new), "| of them order >= 8:",
    sum(new & seg$stream_order >= 8), "| max stream order:", max(seg$stream_order[new]), "\n")
# in "total" mode m3/s = sum(value * area) / const, so the denominator only
# moves mad_mm; compare that
seg$live_mm <- live$mad_mm[k]
ch <- both & abs(seg$live_mm - seg$wet_mm) > 1e-9 * abs(seg$wet_mm)
cat("live upstream area vs fwapg's stored table: segments whose mad_mm changes:", sum(ch), "\n")

cat("\n## Sensitivity (per segment, mad_m3s vs the live centroid/total build)\n\n")
# baseline is the live build (accumulated upstream area), as are all variants,
# so the comparison is not mixed with the stored-table staleness
sens <- function(lbl, x) {
  r <- (x - seg$live_m3s) / seg$live_m3s
  ok <- is.finite(r)
  cat(sprintf("%-18s median %+.2f%%, 1-99%% [%+.2f%%, %+.2f%%], |change|>5%%: %s, NA in one build only: %d\n",
              lbl, 100 * stats::median(r[ok]), 100 * stats::quantile(r[ok], 0.01),
              100 * stats::quantile(r[ok], 0.99), pct(abs(r[ok]) > 0.05),
              sum(is.na(x) != is.na(seg$live_m3s))))
}
sens("area / total", area_tot$mad_m3s[k])
sens("centroid / covered", cen_cov$mad_m3s[k])
sens("area / covered", seg$area_cov_m3s)
rc <- (cen_cov$mad_m3s[k] - seg$live_m3s) / seg$live_m3s
cat("covered vs total denominator (centroid): segments changing > 5%:", sum(abs(rc) > 0.05, na.rm = TRUE),
    "| max", sprintf("%+.0f%%", 100 * max(rc, na.rm = TRUE)), "| groups:",
    paste(names(utils::head(sort(table(seg$watershed_group_code[which(abs(rc) > 0.05)]), decreasing = TRUE), 3)), collapse = " "), "\n")
cat("coverage < 1 (area sampling): segments", sum(seg$coverage < 1 - 1e-9, na.rm = TRUE),
    "| < 0.9:", sum(seg$coverage < 0.9, na.rm = TRUE), "| min", signif(min(seg$coverage, na.rm = TRUE), 3), "\n")

if (arrow_ok) arrow::write_parquet(seg, file.path(out_dir, paste0(wscode, "_segments.parquet")))

# ---- sanity: Fraser River at Hope (reported, never fatal) ------------------------
if (wscode == "100") tryCatch({
  st <- tidyhydat::hy_stations("08MF005")
  hy <- tidyhydat::hy_daily_flows("08MF005", start_date = "1981-01-01", end_date = "2010-12-31")
  snap <- DBI::dbGetQuery(conn, "
    SELECT linear_feature_id, gnis_name, distance_to_stream
    FROM postgisftw.fwa_indexpoint($1::double precision, $2::double precision,
                                   4326, 500::double precision, 5)
    WHERE gnis_name = 'Fraser River' ORDER BY distance_to_stream LIMIT 1",
    params = list(st$LONGITUDE, st$LATITUDE))
  h <- seg[seg$linear_feature_id == snap$linear_feature_id, ]
  w <- match(h$watershed_feature_id, ws$watershed_feature_id)
  cat(sprintf("\n## Fraser River at Hope (08MF005)\nHYDAT 1981-2010 mean %.0f m3/s (%d days), gross drainage %.0f km2\n",
              mean(hy$Value, na.rm = TRUE), sum(!is.na(hy$Value)), st$DRAINAGE_AREA_GROSS))
  cat(sprintf("wet segment %s (%.0f m from gauge): upstream %.0f km2 | centroid/total %.0f m3/s | area/covered %.0f m3/s (coverage %.3f) | fwapg %s\n",
              snap$linear_feature_id, snap$distance_to_stream, live$upstream_area_m2[w] / 1e6,
              live$mad_m3s[w], area_cov$mad_m3s[w], area_cov$coverage[w],
              ifelse(is.na(h$mad_m3s), "no value (order >= 8 skipped)", sprintf("%.0f", h$mad_m3s))))
}, error = function(e) cat("\nHope sanity check failed:", conditionMessage(e), "\n"))

DBI::dbDisconnect(conn)
cat(sprintf("\ntiming: PCIC %.1f min | centroid %.1f s | area sampling %.1f min | accumulation %.1f s/build | total %.1f min\n",
            t_pcic, t_cen, t_area, t_acc, as.numeric(Sys.time() - t_start, units = "mins")))
