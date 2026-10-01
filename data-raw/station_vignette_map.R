# Map layers for vignettes/station-flow.Rmd (#27), which draws them from
# inst/vignette-data/ and never touches fwapg, HYDAT or the network at build.
#
#   Rscript data-raw/station_vignette_map.R
#
# Writes inst/vignette-data/station_map.rds: a named list of sf layers in
# EPSG:3005, xz-compressed like station_daily.rds (a GeoPackage of the same
# layers is several times larger, in page and index overhead):
#   - stations: 08EE013 and 08EE003 from HYDAT STATIONS, with gross drainage area
#   - catchments: each station's upstream watershed, from its FWA snap
#     (wet_station_snap()) and fwapg's fwa_watershedatmeasure()
#   - streams: order >= 5 in the map extent, plus the whole of the Bulkley
#     River and Buck Creek by blue_line_key, simplified
#   - lakes: FWA lakes of at least 100 ha in the map extent
#   - places: Houston, from BC Geographic Names (bcdata)
#   - bc: the province outline for the keymap, its parts under 2,000 km2
#     dropped and the rest simplified at 5 km
#
# Separate from data-raw/station_vignette_data.R so that refreshing the map
# does not refetch the daily series. HYDAT from WET_HYDAT, defaulting to
# data/hydat/20260717/Hydat.sqlite3; fwapg from the WET_PG* variables.

devtools::load_all(quiet = TRUE)
sf::sf_use_s2(FALSE)

stations <- c("08EE013", "08EE003")
blk <- c(bulkley = 360873822L, buck = 360886221L)   # by key: GNIS names repeat across BC
hydat <- Sys.getenv("WET_HYDAT", file.path("data", "hydat", "20260717", "Hydat.sqlite3"))
out <- file.path("inst", "vignette-data", "station_map.rds")
simplify_m <- 50

con <- wet_hydat_connect(hydat)
st <- DBI::dbGetQuery(con, sprintf(
  "SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, LONGITUDE AS lon,
          LATITUDE AS lat, DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
   FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", stations, "'", collapse = ", ")))
DBI::dbDisconnect(con)
stopifnot(setequal(st$station_number, stations))
st <- st[match(stations, st$station_number), ]

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))

# ---- catchments ----------------------------------------------------------------
# the snap picks the segment by drainage area; the catchment is cut at the
# station's own measure on that segment
snap <- wet_station_snap(conn, st)
if (!all(snap$accepted)) stop("snap not accepted for: ", paste(snap$station_number[!snap$accepted], collapse = ", "))
catch <- do.call(rbind, lapply(seq_len(nrow(st)), function(i) {
  sf::st_read(conn, quiet = TRUE, query = sprintf("
    WITH p AS (
      SELECT c.blue_line_key, c.downstream_route_measure
      FROM whse_basemapping.fwa_indexpoint(
        ST_Transform(ST_SetSRID(ST_MakePoint(%.10f, %.10f), 4326), 3005), 1000, 5) c
      WHERE c.linear_feature_id = %.0f)
    SELECT '%s' AS station_number, w.area_ha / 100 AS area_km2,
           ST_SimplifyPreserveTopology(ST_Force2D(w.geom), %d) AS geom
    FROM p, whse_basemapping.fwa_watershedatmeasure(p.blue_line_key, p.downstream_route_measure) w",
    st$lon[i], st$lat[i], snap$linear_feature_id[i], st$station_number[i], simplify_m))
}))
stopifnot(nrow(catch) == nrow(st))
# area is taken before the simplify, so it is the watershed's, not the drawing's
catch$area_ratio <- catch$area_km2 / st$drainage_area_gross_km2[match(catch$station_number, st$station_number)]
print(sf::st_drop_geometry(catch))
stopifnot(all(abs(catch$area_ratio - 1) < 0.1))

# ---- context, inside the catchments' extent plus a margin -----------------------
ext <- sf::st_as_sfc(sf::st_bbox(sf::st_buffer(sf::st_union(catch), 8000)))
ext_wkt <- sf::st_as_text(ext)
streams <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT blue_line_key, max(gnis_name) AS gnis_name, max(stream_order) AS stream_order,
         ST_SimplifyPreserveTopology(ST_LineMerge(ST_Union(ST_Force2D(geom))), %d) AS geom
  FROM whse_basemapping.fwa_stream_networks_sp
  WHERE (stream_order >= 5 AND ST_Intersects(geom, ST_GeomFromText('%s', 3005)))
     OR blue_line_key IN (%s)
  GROUP BY blue_line_key", simplify_m, ext_wkt, paste(blk, collapse = ", ")))
streams$main <- streams$blue_line_key %in% blk
stopifnot(sum(streams$main) == length(blk))
lakes <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT gnis_name_1 AS gnis_name, area_ha,
         ST_SimplifyPreserveTopology(ST_Force2D(geom), %d) AS geom
  FROM whse_basemapping.fwa_lakes_poly
  WHERE area_ha >= 100 AND ST_Intersects(geom, ST_GeomFromText('%s', 3005))", simplify_m, ext_wkt))
# the keymap is an inch wide: islands under 2,000 km2 are noise at that size
bc <- sf::st_read(conn, quiet = TRUE, query = "
  SELECT ST_SimplifyPreserveTopology(ST_Collect(d.geom), 5000) AS geom
  FROM (SELECT (ST_Dump(ST_Union(geom))).geom FROM whse_basemapping.fwa_bcboundary) d
  WHERE ST_Area(d.geom) >= 2e9")
DBI::dbDisconnect(conn)

# ---- place names ----------------------------------------------------------------
# a name is not a key: keep the populated places inside the map extent
gns <- bcdata::bcdc_query_geodata("WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP") |>
  dplyr::filter(GEOGRAPHICAL_NAME == "Houston") |>
  bcdata::collect()
gns <- gns[lengths(sf::st_intersects(gns, ext)) > 0, ]
places <- sf::st_sf(name = gns$GEOGRAPHICAL_NAME, feature_type = gns$FEATURE_TYPE,
                    geom = sf::st_geometry(gns))
print(sf::st_drop_geometry(places))
stopifnot(nrow(places) == 1)

pts <- sf::st_transform(sf::st_as_sf(st, coords = c("lon", "lat"), crs = 4326), 3005)
sf::st_geometry(pts) <- "geom"

layers <- list(stations = pts, catchments = catch, streams = streams, lakes = lakes,
               places = places, bc = bc)
layers <- lapply(layers, function(x) {
  sf::st_crs(x) <- 3005
  x
})
saveRDS(layers, out, compress = "xz")
print(vapply(layers, function(x) nrow(sf::st_coordinates(x)), 0))
message("station_map.rds: ", round(file.size(out) / 1024), " KB")
