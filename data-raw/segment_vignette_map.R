# Map layers for vignettes/segment-discharge.Rmd (#28), which draws them from
# inst/vignette-data/ and never touches fwapg or the network at build.
#
#   Rscript data-raw/segment_vignette_map.R
#
# Writes inst/vignette-data/segment_map.rds: a named list of sf layers in
# EPSG:3005, xz-compressed like station_map.rds:
#   - segments: FWA stream segments of order >= 3 in SALR and BULK, keyed by
#     linear_feature_id, simplified at 50 m and snapped to a 1 m grid; the
#     discharge per segment is in segment_values.rds
#     (data-raw/segment_vignette_data.R), joined in the vignette
#   - groups: the two watershed group outlines, with their area
#   - lakes: FWA lakes of at least 100 ha in the two groups
#   - places: populated places inside BULK, and inside SALR's context box
#     (SALR itself has none), from BC Geographic Names (bcdata)
#   - context: the box around SALR that its map may draw, which holds the
#     gauges near the group (data-raw/segment_vignette_data.R, near_km) and its
#     outlet gauge, 46 km off at Prince George
#   - context_streams, context_lakes: the larger rivers (order >= 6) and the
#     river each HYDAT gauge in the box sits on (the shipped fit's stations), as main
#     flow lines through lakes, wetlands and double-line reaches, and lakes
#     (>= 1,000 ha) in that box outside SALR, so a gauge off the group sits on its
#     river
#   - coverage: the outline of the watershed groups fwapg gives a discharge in
#     (PCIC's coverage), simplified for a province map
#   - zones: the Extended BC Hydrologic Zones the water balance adjusts by
#     (scripts/wb_inputs.R), simplified for a province map, keyed by the zone
#     code the calibration stations carry, with the zone's name
#
# The province outline is station_map.rds's `bc` layer, not a second copy.
# Separate from the values so a cartographic refresh does not need the PCIC run
# or the water-balance fit; it reads only the snapped stations of the
# water-balance inputs (data/wb/stations_<release>.rds, scripts/wb_fit_lib.R).
# fwapg from the WET_PG* variables.

devtools::load_all(quiet = TRUE)
sf::sf_use_s2(FALSE)

wsg <- c("SALR", "BULK")
min_order <- 3
simplify_m <- 50
context_km <- 60
province_simplify_m <- 4000
cov_share <- 0.5   # as in data-raw/segment_vignette_data.R
out <- file.path("inst", "vignette-data", "segment_map.rds")
in_wsg <- paste0("'", wsg, "'", collapse = ", ")

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))

# 1 m snapping after the simplify: coordinates to the metre compress far better
# under xz, and a metre is invisible at the vignette's scale. A segment shorter
# than the grid collapses to empty, so it keeps its unsnapped line.
segments <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code, blue_line_key, stream_order,
         CASE WHEN ST_IsEmpty(g) THEN ST_Force2D(geom) ELSE g END AS geom
  FROM (SELECT *, ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Force2D(geom), %d), 1) AS g
        FROM whse_basemapping.fwa_stream_networks_sp
        WHERE watershed_group_code IN (%s) AND stream_order >= %d) s", simplify_m, in_wsg, min_order))
n_seg <- DBI::dbGetQuery(conn, sprintf("
  SELECT watershed_group_code, count(*)::int AS n FROM whse_basemapping.fwa_stream_networks_sp
  WHERE watershed_group_code IN (%s) AND stream_order >= %d GROUP BY 1", in_wsg, min_order))
stopifnot(identical(as.vector(table(segments$watershed_group_code)[n_seg$watershed_group_code]), n_seg$n),
          !anyDuplicated(segments$linear_feature_id), all(!sf::st_is_empty(segments)))

# area before the simplify, so it is the group's, not the drawing's
groups <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT watershed_group_code, watershed_group_name, ST_Area(geom) / 1e6 AS area_km2,
         ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Force2D(geom), 100), 1) AS geom
  FROM whse_basemapping.fwa_watershed_groups_poly WHERE watershed_group_code IN (%s)", in_wsg))
stopifnot(setequal(groups$watershed_group_code, wsg))

lakes <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT watershed_group_code, gnis_name_1 AS gnis_name, area_ha,
         ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Force2D(geom), %d), 1) AS geom
  FROM whse_basemapping.fwa_lakes_poly
  WHERE watershed_group_code IN (%s) AND area_ha >= 100", simplify_m, in_wsg))

# ---- SALR's context ----------------------------------------------------------------
# the gauges that arbitrate between the two products on SALR lie off the group,
# so its map draws a wider box, with the larger rivers and lakes in it
context <- sf::st_as_sfc(sf::st_bbox(sf::st_buffer(groups[groups$watershed_group_code == "SALR", ],
                                                   context_km * 1000)))
context <- sf::st_sf(watershed_group_code = "SALR", geom = context)
box <- sf::st_bbox(context)
in_box <- sprintf("ST_Intersects(geom, ST_MakeEnvelope(%f, %f, %f, %f, 3005))",
                  box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]])
# the rivers drawn: order 6 and up, and the river each accepted HYDAT gauge in
# the box sits on (08KC003's Muskeg River is order 5), as main-flow lines
source("scripts/wb_fit_lib.R")
st <- readRDS(wb_stations_path(wb_shipped_release))$stations
st <- st[st$accepted, ]
gauge_blk <- DBI::dbGetQuery(conn, sprintf("
  SELECT DISTINCT blue_line_key::int AS blue_line_key FROM whse_basemapping.fwa_stream_networks_sp
  WHERE linear_feature_id IN (%s) AND %s", paste(st$linear_feature_id, collapse = ", "), in_box))[[1]]
stopifnot(length(gauge_blk) > 0)
context_streams <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT stream_order, ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Force2D(geom), %d), 1) AS geom
  FROM whse_basemapping.fwa_stream_networks_sp
  WHERE %s AND (stream_order >= 6 OR blue_line_key IN (%s)) AND watershed_group_code <> 'SALR'
    AND edge_type IN (1000, 1050, 1200, 1250, 1450)", 2 * simplify_m, in_box, paste(gauge_blk, collapse = ", ")))
context_lakes <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT gnis_name_1 AS gnis_name, area_ha,
         ST_Multi(ST_CollectionExtract(ST_MakeValid(
           ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Force2D(geom), %d), 1)), 3)) AS geom
  FROM whse_basemapping.fwa_lakes_poly
  WHERE %s AND area_ha >= 1000 AND watershed_group_code <> 'SALR'", 4 * simplify_m, in_box))
context_streams <- context_streams[!sf::st_is_empty(context_streams), ]
stopifnot(nrow(context_streams) > 0, nrow(context_lakes) > 0)

# ---- province layers ----------------------------------------------------------------
# PCIC's coverage: the groups where at least half of fwapg's rows hold a
# value (some carry only null rows, and Liard groups at the grid's edge a few
# percent), the rule data-raw/segment_vignette_data.R scores by, as one
# outline; area before the simplify
coverage <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT sum(ST_Area(geom)) / 1e6 AS area_km2,
         ST_Multi(ST_CollectionExtract(ST_MakeValid(
           ST_SnapToGrid(ST_SimplifyPreserveTopology(ST_Union(geom), %d), 100)), 3)) AS geom
  FROM whse_basemapping.fwa_watershed_groups_poly
  WHERE watershed_group_code IN (
    SELECT watershed_group_code FROM whse_basemapping.fwa_stream_networks_discharge
    GROUP BY 1 HAVING count(mad_mm) >= %f * count(*))", province_simplify_m, cov_share))
DBI::dbDisconnect(conn)
stopifnot(nrow(coverage) == 1, !sf::st_is_empty(coverage))
coverage$cov_share <- cov_share   # the tests hold it to the data script's

# the zones the balance adjusts by, from the zip scripts/wb_inputs.R caches
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
hz <- sf::st_transform(sf::st_read(hz_shp, quiet = TRUE), 3005)
# a zone split across the border is several features, dissolved into one; the
# source mixes XY and XYZ rings, which GEOS will not union until Z is dropped
hz <- sf::st_zm(hz)
hz_code <- sprintf("%02d", as.integer(hz$HYDZN_NO))
# drawn at province scale: clipped to BC's box, simplified, and rounded to 100 m
# (st_as_binary's precision), which xz compresses far better than full doubles.
# One zone at a time, so each geometry keeps its code: a clip can empty a zone,
# and a union of parts touching along a line can return a collection
bc_box <- sf::st_as_sfc(sf::st_bbox(readRDS(file.path("inst", "vignette-data", "station_map.rds"))$bc))
zone_geom <- function(z) {
  g <- sf::st_union(sf::st_geometry(hz)[hz_code == z])
  g <- sf::st_simplify(sf::st_intersection(g, bc_box), preserveTopology = TRUE, dTolerance = province_simplify_m)
  g <- sf::st_as_sfc(sf::st_as_binary(g, precision = 0.01), crs = 3005)
  if (!all(sf::st_is_valid(g))) g <- sf::st_make_valid(g)
  if (!length(g) || all(sf::st_is_empty(g))) return(NULL)
  sf::st_cast(sf::st_union(sf::st_collection_extract(g, "POLYGON")), "MULTIPOLYGON")
}
zone_list <- lapply(stats::setNames(sort(unique(hz_code)), sort(unique(hz_code))), zone_geom)
zone_list <- zone_list[!vapply(zone_list, is.null, NA)]
# a zone's name is its first feature's: zone 28's two features carry two names
hz_name <- tapply(as.character(hz$HYDZN_NAME), hz_code, `[`, 1)
zones <- sf::st_sf(zone = names(zone_list), name = unname(hz_name[names(zone_list)]),
                   geom = do.call(c, zone_list))
stopifnot(!anyDuplicated(zones$zone), !anyNA(zones$name), all(!sf::st_is_empty(zones)))

# ---- place names ----------------------------------------------------------------
# a name is not a key: keep the populated places inside BULK, and inside SALR's
# context box (SALR itself has none; Prince George, the nearest city, is 59 km
# off its boundary)
frames <- rbind(sf::st_sf(watershed_group_code = "BULK",
                          geom = sf::st_geometry(groups[groups$watershed_group_code == "BULK", ])),
                context)
bb <- sf::st_bbox(frames)
gns <- bcdata::bcdc_query_geodata("WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP") |>
  dplyr::filter(FEATURE_TYPE %in% c("City", "Town", "District Municipality (1)", "Village (1)")) |>
  dplyr::filter(bcdata::BBOX(local(bb), crs = "EPSG:3005")) |>
  bcdata::collect()
gns <- sf::st_transform(gns, 3005)
inside <- sf::st_intersects(gns, frames)
gns <- gns[lengths(inside) > 0, ]
places <- sf::st_sf(name = gns$GEOGRAPHICAL_NAME, feature_type = gns$FEATURE_TYPE,
                    watershed_group_code = frames$watershed_group_code[
                      vapply(inside[lengths(inside) > 0], `[`, 1L, 1L)],
                    geom = sf::st_geometry(gns))
print(sf::st_drop_geometry(places))
stopifnot(!anyDuplicated(places$name), setequal(places$watershed_group_code, wsg))

# fwapg's bigint ids reach R as integer64, which readRDS() without bit64 reads
# as raw bits: the SQL casts them, and nothing integer64 is saved
layers <- list(segments = segments, groups = groups, lakes = lakes, places = places, context = context,
               context_streams = context_streams, context_lakes = context_lakes, coverage = coverage,
               zones = zones)
layers <- lapply(layers, function(x) {
  sf::st_crs(x) <- 3005
  x
})
stopifnot(!any(unlist(lapply(layers, function(x) vapply(x, inherits, NA, "integer64")))))
# a simplify then a snap can turn a hole outside its shell: every polygon must be valid
poly <- vapply(layers, function(x) all(sf::st_dimension(x) == 2), NA)
stopifnot(all(vapply(layers[poly], function(x) all(sf::st_is_valid(x)), NA)))
saveRDS(layers, out, compress = "xz")
print(vapply(layers, function(x) nrow(sf::st_coordinates(x)), 0))
message("segment_map.rds: ", round(file.size(out) / 1024), " KB")
