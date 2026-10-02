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
#   - places: populated places inside the groups, from BC Geographic Names
#     (bcdata); SALR has none
#
# The keymap's province outline is station_map.rds's `bc` layer, not a second
# copy. Separate from the values so a cartographic refresh does not need the
# PCIC or water-balance runs. fwapg from the WET_PG* variables.

devtools::load_all(quiet = TRUE)
sf::sf_use_s2(FALSE)

wsg <- c("SALR", "BULK")
min_order <- 3
simplify_m <- 50
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
DBI::dbDisconnect(conn)

# ---- place names ----------------------------------------------------------------
# a name is not a key: keep the populated places inside the two groups. SALR
# has none (Prince George, the nearest city, is 59 km off), so the vignette
# names each group from `groups` instead
bb <- sf::st_bbox(groups)
gns <- bcdata::bcdc_query_geodata("WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP") |>
  dplyr::filter(FEATURE_TYPE %in% c("City", "Town", "District Municipality (1)", "Village (1)")) |>
  dplyr::filter(bcdata::BBOX(local(bb), crs = "EPSG:3005")) |>
  bcdata::collect()
gns <- sf::st_transform(gns, 3005)
inside <- sf::st_intersects(gns, groups)
gns <- gns[lengths(inside) > 0, ]
places <- sf::st_sf(name = gns$GEOGRAPHICAL_NAME, feature_type = gns$FEATURE_TYPE,
                    watershed_group_code = groups$watershed_group_code[
                      vapply(inside[lengths(inside) > 0], `[`, 1L, 1L)],
                    geom = sf::st_geometry(gns))
print(sf::st_drop_geometry(places))
stopifnot(!anyDuplicated(places$name), "BULK" %in% places$watershed_group_code)

# fwapg's bigint ids reach R as integer64, which readRDS() without bit64 reads
# as raw bits: the SQL casts them, and nothing integer64 is saved
layers <- list(segments = segments, groups = groups, lakes = lakes, places = places)
layers <- lapply(layers, function(x) {
  sf::st_crs(x) <- 3005
  x
})
stopifnot(!any(unlist(lapply(layers, function(x) vapply(x, inherits, NA, "integer64")))))
saveRDS(layers, out, compress = "xz")
print(vapply(layers, function(x) nrow(sf::st_coordinates(x)), 0))
message("segment_map.rds: ", round(file.size(out) / 1024), " KB")
