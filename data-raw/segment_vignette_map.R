# Map layers for vignettes/segment-discharge.Rmd (#28, #64, #71), which draws them from
# inst/vignette-data/ and never touches fwapg or the network at build.
#
#   Rscript data-raw/segment_vignette_map.R
#
# Writes inst/vignette-data/segment_map.rds, a named list, sf layers in
# EPSG:3005, xz-compressed like station_map.rds:
#   - rivers: the source `pick` takes on each main-flow FWA segment of order >=
#     min_order (pcic_routed, wet_balance, or none where neither source has a
#     value), dissolved by blue_line_key, class and order band, simplified for
#     a page-width province map
#   - regions: a label point for each region the article names (the Liard
#     basin, and the Nechako Reservoir groups scripts/segment_output.R names),
#     with the source `pick` takes on all of its segments, counted
#   - zones: the Extended BC Hydrologic Zones the water balance adjusts by
#     (scripts/wb_inputs.R), code and name only: the article names the weakest
#   - provenance: the published build the picks were read from
#
# The picks are read from the published product (wet_catalog(): the manifest
# at s3://fresh-bc/discharge/fwa/v1/), whose tracked publish report must check
# every part's `pick` against the segment table with none differing
# (vd_published()); the parts are checked against their manifest md5s before
# and after the read, so a read during a publish is refused. The province
# outline is station_map.rds's `bc` layer, not a second copy. fwapg is reached
# through the WET_PG* variables.

# the vignette cites the commit these were built at, so that commit must hold
# what built them (scripts/vignette_data_lib.R)
source("scripts/vignette_data_lib.R")
wet_commit <- vd_commit()
source("scripts/wb_fit_lib.R")
devtools::load_all(quiet = TRUE)
sf::sf_use_s2(FALSE)

min_order <- 5
simplify_m <- 2000
snap_m <- 100
# main flow is not edge type 1000 alone (code-check-spatial.md): single-line,
# lake and double-line main flow
main_flow <- c(1000, 1050, 1200, 1250, 1450)
nechako <- c("LEUT", "UEUT", "UNRS", "LNRS")   # as scripts/segment_output.R
out <- file.path("inst", "vignette-data", "segment_map.rds")
release <- wb_release()

# ---- the published picks ------------------------------------------------------------------------
pb <- vd_published(release)
parts <- pb$catalog[pb$catalog$dataset == "discharge/fwa/v1/segment_monthly" & pb$catalog$scenario == "historical", ]
vd_verify(parts)
duck <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(duck, "LOAD httpfs"))
pick <- DBI::dbGetQuery(duck, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, source
  FROM read_parquet([%s], hive_partitioning = true)
  WHERE month = 0 AND pick", paste0("'", parts$href, "'", collapse = ", ")))
DBI::dbDisconnect(duck, shutdown = TRUE)
vd_verify(parts)
# one pick per segment, and as many per source as the report's reader saw
n_pick <- table(factor(pick$source, c("pcic_routed", "wet_balance")))
stopifnot(!anyDuplicated(pick$linear_feature_id), !anyNA(pick$source),
          identical(as.numeric(n_pick[pb$reader$source]), pb$reader$picked))

# ---- rivers, classed by the source picked -------------------------------------------------------
conn <- vd_connect()
DBI::dbWriteTable(conn, "vd_pick", pick, temporary = TRUE)
DBI::dbExecute(conn, "CREATE INDEX ON vd_pick (linear_feature_id)")
# every picked segment is one of this fwapg's, so a segment drawn as none has
# no pick in the build rather than a pick on an id this FWA load lacks
n_known <- DBI::dbGetQuery(conn, "
  SELECT count(*)::int FROM vd_pick JOIN whse_basemapping.fwa_stream_networks_sp USING (linear_feature_id)")[[1]]
stopifnot(n_known == nrow(pick))
seg_where <- sprintf("s.stream_order >= %d AND s.edge_type IN (%s)", min_order, paste(main_flow, collapse = ", "))
# every drawn segment is classed once
n_cls <- DBI::dbGetQuery(conn, sprintf("
  SELECT coalesce(p.source, 'none') AS class, count(*)::int AS n
  FROM whse_basemapping.fwa_stream_networks_sp s LEFT JOIN vd_pick p USING (linear_feature_id)
  WHERE %s GROUP BY 1", seg_where))
n_seg <- DBI::dbGetQuery(conn, sprintf("
  SELECT count(*)::int FROM whse_basemapping.fwa_stream_networks_sp s WHERE %s", seg_where))[[1]]
print(n_cls)
stopifnot(sum(n_cls$n) == n_seg, setequal(n_cls$class, c("pcic_routed", "wet_balance", "none")))
# order bands 5, 6, 7 and 8 and up, so line width can rank rivers; a reach
# shorter than the snap grid collapses to empty and is dropped
rivers <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT class, order_band, segments, geom FROM (
    SELECT coalesce(p.source, 'none') AS class, least(s.stream_order, 8)::int AS order_band,
           count(*)::int AS segments,
           ST_Multi(ST_CollectionExtract(ST_SnapToGrid(ST_SimplifyPreserveTopology(
             ST_LineMerge(ST_Union(ST_Force2D(s.geom))), %d), %d), 2)) AS geom
    FROM whse_basemapping.fwa_stream_networks_sp s LEFT JOIN vd_pick p USING (linear_feature_id)
    WHERE %s
    GROUP BY s.blue_line_key, 1, 2) r
  WHERE NOT ST_IsEmpty(geom)", simplify_m, snap_m, seg_where))
rivers <- rivers[order(rivers$order_band), ]   # large rivers drawn last, on top
stopifnot(all(sf::st_geometry_type(rivers) == "MULTILINESTRING"))

# ---- regions the article names ------------------------------------------------------------------
# the Liard basin: every segment under the Liard River's watershed code; its
# label sits in the groups most of whose segments are in it
liard_ws <- "(SELECT wscode_ltree FROM whse_basemapping.fwa_stream_networks_sp
              WHERE gnis_name = 'Liard River' ORDER BY downstream_route_measure LIMIT 1)"
region_sql <- function(name, seg_in, groups_in) {
  sprintf("
  WITH segs AS (
    SELECT s.watershed_group_code, coalesce(p.source, 'none') AS class
    FROM whse_basemapping.fwa_stream_networks_sp s LEFT JOIN vd_pick p USING (linear_feature_id)
    WHERE %s)
  SELECT '%s' AS name,
         (SELECT count(*) FILTER (WHERE class = 'pcic_routed') FROM segs)::int AS pcic_routed,
         (SELECT count(*) FILTER (WHERE class = 'wet_balance') FROM segs)::int AS wet_balance,
         (SELECT count(*) FILTER (WHERE class = 'none') FROM segs)::int AS none,
         (SELECT ST_PointOnSurface(ST_Union(geom)) FROM whse_basemapping.fwa_watershed_groups_poly
          WHERE watershed_group_code IN (%s)) AS geom", seg_in, name, groups_in)
}
liard_groups <- sprintf("
  SELECT watershed_group_code FROM whse_basemapping.fwa_stream_networks_sp
  GROUP BY 1 HAVING avg((wscode_ltree <@ %s)::int) > 0.5", liard_ws)
in_nechako <- paste0("'", nechako, "'", collapse = ", ")
regions <- rbind(
  sf::st_read(conn, quiet = TRUE, query = region_sql("Liard", sprintf("s.wscode_ltree <@ %s", liard_ws), liard_groups)),
  sf::st_read(conn, quiet = TRUE, query = region_sql("Nechako Reservoir",
                                                     sprintf("s.watershed_group_code IN (%s)", in_nechako),
                                                     in_nechako)))
DBI::dbDisconnect(conn)
print(sf::st_drop_geometry(regions))
stopifnot(nrow(regions) == 2, all(!sf::st_is_empty(regions)),
          all(regions$pcic_routed + regions$wet_balance + regions$none > 0))

# ---- zone names ------------------------------------------------------------------------------
# from the zip scripts/wb_inputs.R caches
hz_url <- paste0("https://catalogue.data.gov.bc.ca/dataset/f1f86c41-ae83-49d5-92e1-526897b99fa2/",
                 "resource/fc209bd0-26ab-4f8b-9415-8f34081a3c0e/download/bc_hydrologic_zones.zip")
hz_zip <- file.path("data", "hydz", "bc_hydrologic_zones.zip")
if (!file.exists(hz_zip)) {
  dir.create(dirname(hz_zip), recursive = TRUE, showWarnings = FALSE)
  wet:::wet_download(hz_url, hz_zip, 300)
}
hz_src <- tempfile("hydz")
utils::unzip(hz_zip, exdir = hz_src)
hz_shp <- list.files(hz_src, "\\.shp$", full.names = TRUE, recursive = TRUE)
stopifnot(length(hz_shp) == 1)
hz <- sf::st_drop_geometry(sf::st_read(hz_shp, quiet = TRUE))
hz_code <- sprintf("%02d", as.integer(hz$HYDZN_NO))
# a zone's name is its first feature's: zone 28's two features carry two names
hz_name <- tapply(as.character(hz$HYDZN_NAME), hz_code, `[`, 1)
zones <- data.frame(zone = names(hz_name), name = unname(hz_name))
stopifnot(!anyDuplicated(zones$zone), !anyNA(zones$name))

# ---- write ---------------------------------------------------------------------------------------
layers <- list(rivers = rivers, regions = regions)
layers <- lapply(layers, function(x) {
  sf::st_crs(x) <- 3005
  x
})
stopifnot(!any(unlist(lapply(layers, function(x) vapply(x, inherits, NA, "integer64")))))
provenance <- list(built = Sys.Date(), wet_commit = wet_commit, min_order = min_order, simplify_m = simplify_m,
                   main_flow = main_flow, drawn = stats::setNames(n_cls$n, n_cls$class),
                   published = list(manifest = attr(pb$catalog, "manifest"), built = attr(pb$catalog, "built"),
                                    wet_commit = attr(pb$catalog, "provenance")$wet_commit, report = pb$report))
layers <- c(layers, list(zones = zones, provenance = provenance))
saveRDS(layers, out, compress = "xz")
print(vapply(layers[c("rivers", "regions")], function(x) nrow(sf::st_coordinates(x)), 0))
message("segment_map.rds: ", round(file.size(out) / 1024), " KB")
