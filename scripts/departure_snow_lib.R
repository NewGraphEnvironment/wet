# The pilot gauges' watersheds on fwapg (#121), shared by
# data-raw/snow_pilot_data.R and scripts/departure_site_snow.R (and, until
# #146 retired it, scripts/departure_snow.R). Needs wet loaded
# (wet_station_snap(), wet_hydat_connect()).

# Each gauge's fundamental watershed and its upstream polygon count, measured
# on fwapg at the plan (2026-10-26) and asserted on every run.
ds_gauges <- data.frame(
  station_number = c("08EE003", "08EE013", "08EE018"),
  name = c("houston", "buck", "maxan"),
  watershed_feature_id = c(7653689L, 7619666L, 9939958L),
  n_poly = c(5448L, 1005L, 788L)
)

# STATIONS rows for the gauges, in ds_gauges' order
ds_stations <- function(hydat) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  st <- DBI::dbGetQuery(con, sprintf("
    SELECT STATION_NUMBER AS station_number, LONGITUDE AS lon, LATITUDE AS lat,
           DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", ds_gauges$station_number, "'", collapse = ", ")))
  stopifnot(setequal(st$station_number, ds_gauges$station_number))
  st[match(ds_gauges$station_number, st$station_number), ]
}

# The snap, refused unless accepted and on the fundamental watershed above
ds_snap <- function(conn, st) {
  sn <- wet_station_snap(conn, st)
  sn <- sn[match(st$station_number, sn$station_number), ]
  want <- ds_gauges$watershed_feature_id[match(sn$station_number, ds_gauges$station_number)]
  bad <- !(sn$accepted %in% TRUE) | sn$watershed_feature_id != want
  if (any(bad)) {
    stop("snap not accepted or not on the expected fundamental watershed: ",
         paste(sn$station_number[bad], sn$watershed_feature_id[bad], collapse = ", "), call. = FALSE)
  }
  sn
}

# Every fundamental watershed upstream of `wfid`, its own included, as a
# SpatVector in EPSG:3005 ordered by watershed_feature_id; refused unless the
# count is ds_gauges' n_poly.
ds_watershed <- function(conn, wfid) {
  sql <- sprintf("
    SELECT b.watershed_feature_id, ST_Force2D(b.geom) AS geom
    FROM whse_basemapping.fwa_watersheds_poly a
    JOIN whse_basemapping.fwa_watersheds_poly b
      ON whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree, b.localcode_ltree)
     AND b.wscode_ltree <@ a.wscode_ltree
    WHERE a.watershed_feature_id = %d
    ORDER BY b.watershed_feature_id", as.integer(wfid))
  x <- sf::st_read(conn, query = sql, quiet = TRUE)
  want <- ds_gauges$n_poly[ds_gauges$watershed_feature_id == wfid]
  if (nrow(x) != want) stop(wfid, " has ", nrow(x), " upstream polygons, not ", want, call. = FALSE)
  x$watershed_feature_id <- as.integer(x$watershed_feature_id)
  if (sf::st_crs(x)$epsg != 3005) stop("fwa_watersheds_poly is not in EPSG:3005", call. = FALSE)
  terra::vect(x)
}
