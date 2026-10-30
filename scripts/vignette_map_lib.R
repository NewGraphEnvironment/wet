# Map layers shared by the vignette map data scripts
# (data-raw/station_vignette_map.R, #27; data-raw/monthly_vignette_map.R, #107;
# data-raw/short_record_vignette_map.R, #130; data-raw/chinook_sites_map.R, #126):
# the stations from HYDAT, each one's catchment from its FWA snap, and the
# context in an extent (streams, lakes, place names, the province outline),
# all sf in EPSG:3005. Sourced after load_all(); the scripts choose the
# stations, the stream keys and the place names, and connect to fwapg
# themselves (scripts/vignette_data_lib.R, vd_connect()).

# The stations from HYDAT STATIONS, in the order given
vm_stations <- function(hydat, stations) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  sql <- sprintf("
    SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, LONGITUDE AS lon,
           LATITUDE AS lat, DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", stations, "'", collapse = ", "))
  st <- DBI::dbGetQuery(con, sql)
  stopifnot(setequal(st$station_number, stations))
  st[match(stations, st$station_number), ]
}

# Each station's upstream watershed: the snap picks the segment by drainage
# area, and the catchment is cut at the station's own measure on that
# segment. Area is taken before the simplify, so it is the watershed's, not
# the drawing's, and must be within 10% of HYDAT's gross area.
vm_catchments <- function(conn, st, simplify_m) {
  snap <- wet_station_snap(conn, st)
  if (!all(snap$accepted)) stop("snap not accepted for: ", paste(snap$station_number[!snap$accepted], collapse = ", "))
  catch <- do.call(rbind, lapply(seq_len(nrow(st)), function(i) {
    sql <- sprintf("
      WITH p AS (
        SELECT c.blue_line_key, c.downstream_route_measure
        FROM whse_basemapping.fwa_indexpoint(
          ST_Transform(ST_SetSRID(ST_MakePoint(%.10f, %.10f), 4326), 3005), 1000, 5) c
        WHERE c.linear_feature_id = %.0f)
      SELECT '%s' AS station_number, w.area_ha / 100 AS area_km2,
             ST_SimplifyPreserveTopology(ST_Force2D(w.geom), %d) AS geom
      FROM p, whse_basemapping.fwa_watershedatmeasure(p.blue_line_key, p.downstream_route_measure) w",
                   st$lon[i], st$lat[i], snap$linear_feature_id[i], st$station_number[i], simplify_m)
    sf::st_read(conn, quiet = TRUE, query = sql)
  }))
  stopifnot(nrow(catch) == nrow(st))
  catch$area_ratio <- catch$area_km2 / st$drainage_area_gross_km2[match(catch$station_number, st$station_number)]
  print(sf::st_drop_geometry(catch))
  stopifnot(all(abs(catch$area_ratio - 1) < 0.1))
  catch
}

# The map extent: the catchments' bounding box plus a margin, as sfc and WKT
vm_extent <- function(catch, margin_m) {
  ext <- sf::st_as_sfc(sf::st_bbox(sf::st_buffer(sf::st_union(catch), margin_m)))
  list(sfc = ext, wkt = sf::st_as_text(ext))
}

# Streams of at least `min_order` in the extent, plus the whole of each stream
# in `blk` (by blue_line_key: GNIS names repeat across BC), merged per key
vm_streams <- function(conn, ext_wkt, blk, simplify_m, min_order = 5) {
  streams <- sf::st_read(conn, quiet = TRUE, query = sprintf("
    SELECT blue_line_key, max(gnis_name) AS gnis_name, max(stream_order) AS stream_order,
           ST_SimplifyPreserveTopology(ST_LineMerge(ST_Union(ST_Force2D(geom))), %d) AS geom
    FROM whse_basemapping.fwa_stream_networks_sp
    WHERE (stream_order >= %d AND ST_Intersects(geom, ST_GeomFromText('%s', 3005)))
       OR blue_line_key IN (%s)
    GROUP BY blue_line_key", simplify_m, min_order, ext_wkt, paste(blk, collapse = ", ")))
  streams$main <- streams$blue_line_key %in% blk
  stopifnot(sum(streams$main) == length(blk))
  streams
}

# FWA lakes of at least `min_ha` in the extent
vm_lakes <- function(conn, ext_wkt, simplify_m, min_ha = 100) {
  sf::st_read(conn, quiet = TRUE, query = sprintf("
    SELECT gnis_name_1 AS gnis_name, area_ha,
           ST_SimplifyPreserveTopology(ST_Force2D(geom), %d) AS geom
    FROM whse_basemapping.fwa_lakes_poly
    WHERE area_ha >= %d AND ST_Intersects(geom, ST_GeomFromText('%s', 3005))", simplify_m, min_ha, ext_wkt))
}

# The province outline for a keymap an inch wide: parts under 2,000 km2 are
# noise at that size, and the rest is simplified at 5 km
vm_bc <- function(conn) {
  sf::st_read(conn, quiet = TRUE, query = "
    SELECT ST_SimplifyPreserveTopology(ST_Collect(d.geom), 5000) AS geom
    FROM (SELECT (ST_Dump(ST_Union(geom))).geom FROM whse_basemapping.fwa_bcboundary) d
    WHERE ST_Area(d.geom) >= 2e9")
}

# The rivers each blue line flows into, from its watershed code: `into1` (the
# stream it joins), `into2` (the one that joins after, NA where `into1` runs to
# the sea), `into1_blk` (into1's blue line), `system` (the river at the top of
# the code), and `mouth_x`, `mouth_y`, the downstream end of the blue line
# (EPSG:3005), one row per key in the order given (from
# data-raw/chinook_sites_map.R, #126; shared with station_vignette_map.R, #145)
vm_into <- function(conn, blks) {
  into <- do.call(rbind, lapply(blks, function(blk) {
    # a stream that joins a river running to the sea (Naver into the Fraser) has no second level
    r <- DBI::dbGetQuery(conn, sprintf("
      WITH t AS (SELECT DISTINCT wscode_ltree FROM whse_basemapping.fwa_stream_networks_sp
                 WHERE blue_line_key = %d AND blue_line_key = watershed_key AND gnis_name IS NOT NULL),
           up AS (SELECT n, subpath(t.wscode_ltree, 0, nlevel(t.wscode_ltree) - n) AS code FROM t, (VALUES (1), (2)) v(n))
      SELECT up.n, max(s.gnis_name) AS gnis_name, min(s.blue_line_key) AS blue_line_key
      FROM up JOIN whse_basemapping.fwa_stream_networks_sp s
        ON s.wscode_ltree = up.code AND s.blue_line_key = s.watershed_key
      GROUP BY up.n ORDER BY up.n", as.integer(blk)))
    if (!1 %in% r$n) stop("blue line ", blk, " flows into no named stream", call. = FALSE)
    merge(data.frame(n = 1:2), r, all.x = TRUE)
  }))
  stopifnot(nrow(into) == 2 * length(blks), !anyNA(into$gnis_name[into$n == 1]))
  out <- data.frame(into1 = into$gnis_name[into$n == 1], into2 = into$gnis_name[into$n == 2],
                    into1_blk = as.integer(into$blue_line_key[into$n == 1]))
  # the river system: the stream at the top of the watershed code (the Skeena's 400, the Fraser's 100)
  out$system <- vapply(blks, function(blk) {
    DBI::dbGetQuery(conn, sprintf("
      SELECT max(s.gnis_name) AS gnis_name FROM whse_basemapping.fwa_stream_networks_sp s
      WHERE s.blue_line_key = s.watershed_key AND s.wscode_ltree = (
        SELECT subpath(wscode_ltree, 0, 1) FROM whse_basemapping.fwa_stream_networks_sp
        WHERE blue_line_key = %d AND blue_line_key = watershed_key LIMIT 1)", as.integer(blk)))$gnis_name
  }, "")
  # the mouth: the downstream end of the blue line's lowest segment
  mouth <- sf::st_read(conn, quiet = TRUE, query = sprintf("
    SELECT DISTINCT ON (blue_line_key) blue_line_key, ST_StartPoint(ST_LineMerge(ST_Force2D(geom))) AS geom
    FROM whse_basemapping.fwa_stream_networks_sp WHERE blue_line_key IN (%s)
    ORDER BY blue_line_key, downstream_route_measure", paste(blks, collapse = ", ")))
  mxy <- sf::st_coordinates(mouth)[match(blks, mouth$blue_line_key), , drop = FALSE]
  out$mouth_x <- mxy[, 1]
  out$mouth_y <- mxy[, 2]
  stopifnot(!anyNA(out$mouth_x), !anyNA(out$system))
  out
}

# Named places from BC Geographic Names (bcdata), kept only inside the
# extent: a name is not a key, and the same name sits in several places
vm_places <- function(ext, names) {
  # bcdata translates the filter to a WFS query, so the column is named bare
  gns <- bcdata::bcdc_query_geodata("WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP") |>
    dplyr::filter(GEOGRAPHICAL_NAME %in% names) |>  # nolint: object_usage_linter.
    bcdata::collect()
  gns <- gns[lengths(sf::st_intersects(gns, ext)) > 0, ]
  places <- sf::st_sf(name = gns$GEOGRAPHICAL_NAME, feature_type = gns$FEATURE_TYPE,
                      geom = sf::st_geometry(gns))
  print(sf::st_drop_geometry(places))
  places
}

# The stations as points in EPSG:3005
vm_points <- function(st) {
  pts <- sf::st_transform(sf::st_as_sf(st, coords = c("lon", "lat"), crs = 4326), 3005)
  sf::st_geometry(pts) <- "geom"
  pts
}

# Every layer with its CRS set, the HYDAT release as provenance
vm_layers <- function(layers, hydat) {
  layers <- lapply(layers, function(x) {
    sf::st_crs(x) <- 3005
    x
  })
  attr(layers, "provenance") <- list(hydat = format(as.Date(wet_hydat_release(hydat), "%Y%m%d")))
  layers
}
