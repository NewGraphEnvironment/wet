# Map layers for vignettes/articles/flow-change-sparse-gauges.Rmd (#126),
# which draws them from inst/vignette-data/ and never touches fwapg, HYDAT or
# the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/chinook_sites_map.R
#
# Writes inst/vignette-data/chinook_sites_map.rds: a named list of sf layers
# in EPSG:3005, xz-compressed:
#   - bc: the province outline, for each map's keymap (scripts/vignette_map_lib.R,
#     vm_bc())
#   - targets: each site's target, the HYDAT station or, for an ungauged site,
#     its mouth, with the map it is drawn on (scripts/departure_sites.csv, `map`)
#     and the rivers it flows into, from its blue line's watershed code: `into1`
#     (the stream it joins), `into2` (the one that joins after, NA where `into1`
#     runs to the sea), `system` (the river at the top of its watershed code),
#     and `mouth_x`, `mouth_y`, the downstream end of its blue line (EPSG:3005)
#   - gauges: the gauges each site's numbers are borrowed from (inst/vignette-data/
#     chinook_sites_values.rds, `gauges`, the extension and carried donors), with
#     their site and map
#   - extents: one rectangle per map, the area it draws: its sites' targets and
#     the gauges they borrow from, with a margin, widened to the article's map
#     shape (`map_asp`)
#   - streams: per map, FWA streams of order 7 and up, the target streams and
#     the rivers they flow into (by blue_line_key), simplified and cut to the
#     extent
#   - lakes: per map, FWA lakes of at least 1,000 ha, cut to the extent
#   - places: per map, the places its sites' rows of the site table name, from
#     BC Geographic Names
#
# Run it after data-raw/chinook_sites_data.R, whose gauges it draws. fwapg
# from the WET_PG* variables (scripts/vignette_data_lib.R, vd_connect()).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect()
source("scripts/vignette_map_lib.R")
source("scripts/departure_site_lib.R")
sf::sf_use_s2(FALSE)

values <- readRDS(file.path("inst", "vignette-data", "chinook_sites_values.rds"))
hydat <- wb_hydat(wb_release())
out <- file.path("inst", "vignette-data", "chinook_sites_map.rds")
simplify_m <- 400
margin_m <- 20000
map_asp <- 1.3   # the article's regional maps: 7 in wide, about 5.4 in of map above the legend

sites <- lapply(values$sites$site_id, site_get)
map_of <- vapply(sites, `[[`, "", "map")
names(map_of) <- values$sites$site_id

st <- vm_stations(hydat, unique(values$gauges$station_number))
# the gauges each site borrows from (the target and snow-only gauges are not drawn as donors)
gauges <- values$gauges[values$gauges$role %in% c("extension donor", "carried donor"), ]
gauges <- merge(gauges, st[c("station_number", "station_name", "lon", "lat")], by = "station_number")
gauges$map <- unname(map_of[gauges$site_id])
gauges <- vm_points(gauges[order(gauges$site_id, gauges$role, gauges$station_number), ])

tg <- values$sites
tg$lon <- ifelse(tg$kind == "extend", st$lon[match(tg$target, st$station_number)], tg$target_lon)
tg$lat <- ifelse(tg$kind == "extend", st$lat[match(tg$target, st$station_number)], tg$target_lat)
stopifnot(!anyNA(tg$lon), !anyNA(tg$lat))
tg$map <- unname(map_of[tg$site_id])

conn <- vd_connect()
# the rivers each target stream flows into: the streams whose watershed code is its own, one and two levels up
into <- do.call(rbind, lapply(tg$blue_line_key, function(blk) {
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
stopifnot(nrow(into) == 2 * nrow(tg), !anyNA(into$gnis_name[into$n == 1]))
tg$into1 <- into$gnis_name[into$n == 1]
tg$into2 <- into$gnis_name[into$n == 2]
tg$into1_blk <- as.integer(into$blue_line_key[into$n == 1])
# the river system: the stream at the top of the watershed code (the Skeena's 400, the Fraser's 100)
tg$system <- vapply(tg$blue_line_key, function(blk) {
  DBI::dbGetQuery(conn, sprintf("
    SELECT max(s.gnis_name) AS gnis_name FROM whse_basemapping.fwa_stream_networks_sp s
    WHERE s.blue_line_key = s.watershed_key AND s.wscode_ltree = (
      SELECT subpath(min(wscode_ltree), 0, 1) FROM whse_basemapping.fwa_stream_networks_sp
      WHERE blue_line_key = %d AND blue_line_key = watershed_key)", as.integer(blk)))$gnis_name
}, "")
# the mouth: the downstream end of the blue line's lowest segment
mouth <- sf::st_read(conn, quiet = TRUE, query = sprintf("
  SELECT DISTINCT ON (blue_line_key) blue_line_key, ST_StartPoint(ST_LineMerge(ST_Force2D(geom))) AS geom
  FROM whse_basemapping.fwa_stream_networks_sp WHERE blue_line_key IN (%s)
  ORDER BY blue_line_key, downstream_route_measure", paste(tg$blue_line_key, collapse = ", ")))
mxy <- sf::st_coordinates(mouth)[match(tg$blue_line_key, mouth$blue_line_key), ]
tg$mouth_x <- mxy[, 1]
tg$mouth_y <- mxy[, 2]
stopifnot(!anyNA(tg$mouth_x), !anyNA(tg$system))
# each target inside its own box (scripts/departure_site_lib.R)
for (k in seq_len(nrow(tg))) site_in_box(sites[[k]], tg$lon[k], tg$lat[k])
targets <- vm_points(tg[c("site_id", "name", "kind", "target", "blue_line_key", "map", "into1", "into2", "into1_blk",
                          "system", "mouth_x", "mouth_y", "lon", "lat")])

bc <- vm_bc(conn)
maps <- unique(unname(map_of))
per_map <- lapply(maps, function(m) {
  pts <- c(sf::st_geometry(targets[targets$map == m, ]), sf::st_geometry(gauges[gauges$map == m, ]))
  ext <- vm_extent(sf::st_sf(geom = sf::st_buffer(pts, 1)), margin_m)
  # the shape of the article's maps, so the clip below reaches every edge of the frame
  sq <- gq::gq_bbox_aspect(sf::st_bbox(ext$sfc), asp = map_asp)
  ext <- list(sfc = sf::st_as_sfc(sq), wkt = sf::st_as_text(sf::st_as_sfc(sq)))
  keys <- unique(c(targets$blue_line_key[targets$map == m], targets$into1_blk[targets$map == m]))
  streams <- vm_streams(conn, ext$wkt, keys, simplify_m, min_order = 7)
  streams$main <- streams$blue_line_key %in% targets$blue_line_key
  lakes <- vm_lakes(conn, ext$wkt, simplify_m, min_ha = 1000)
  want <- unique(unlist(lapply(sites[map_of == m], `[[`, "places")))
  places <- vm_places(ext$sfc, want)
  # a name can be several features (Hixon is a community and a locality): keep one populated place per name,
  # the first by kind of place
  kinds <- c("City", "Town", "District Municipality (1)", "Village (1)", "Community", "Locality")
  places <- places[places$feature_type %in% kinds, ]
  places <- places[order(places$name, match(places$feature_type, kinds)), ]
  places <- places[!duplicated(places$name), ]
  if (!setequal(places$name, want) || nrow(places) != length(want)) {
    stop(m, ": places found ", paste(places$name, collapse = ", "), " for ", paste(want, collapse = ", "), call. = FALSE)
  }
  # cut to the extent: a big river comes back whole
  clip <- function(x) {
    # a simplified polygon can be invalid: repair only those rows (st_make_valid() rewrites valid ones too)
    bad <- !sf::st_is_valid(x)
    if (any(bad)) sf::st_geometry(x)[bad] <- sf::st_make_valid(sf::st_geometry(x)[bad])
    x <- suppressWarnings(sf::st_intersection(x, ext$sfc))
    x[!sf::st_is_empty(x), ]
  }
  list(extent = sf::st_sf(map = m, geom = ext$sfc), streams = cbind(map = m, clip(streams)),
       lakes = cbind(map = m, clip(lakes)), places = cbind(map = m, places))
})
DBI::dbDisconnect(conn)
pick <- function(k) do.call(rbind, lapply(per_map, `[[`, k))

layers <- vm_layers(list(bc = bc, targets = targets, gauges = gauges, extents = pick("extent"),
                         streams = pick("streams"), lakes = pick("lakes"), places = pick("places")), hydat)
attr(layers, "map_asp") <- map_asp
saveRDS(layers, out, compress = "xz")
print(vapply(layers, nrow, 0L))
print(sf::st_drop_geometry(targets[c("site_id", "into1", "into2")]))
message("chinook_sites_map.rds: ", round(file.size(out) / 1024), " KB")
