# Map layers for vignettes/articles/flow-change-sparse-gauges.Rmd (#126),
# which draws them from inst/vignette-data/ and never touches fwapg, HYDAT or
# the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/chinook_sites_map.R
#
# Writes inst/vignette-data/chinook_sites_map.rds: a named list of sf layers
# in EPSG:3005, xz-compressed:
#   - bc: the province outline (scripts/vignette_map_lib.R, vm_bc())
#   - boxes: each site's donor box (scripts/departure_sites.csv), densified
#     before it is projected so its edges follow the parallels and meridians
#   - targets: each site's target, the HYDAT station or, for an ungauged site,
#     its mouth
#   - gauges: the gauges each site's numbers rest on (inst/vignette-data/
#     chinook_sites_values.rds, `gauges`), with their site and role
#   - extents: one rectangle per site, the area its own map draws: the target
#     and its gauges, with a margin
#   - streams: per site, FWA streams of order 6 and up and the target stream
#     (by blue_line_key), simplified and cut to its extent
#   - lakes: per site, FWA lakes of at least 500 ha, cut to its extent
#   - places: per site, the places its row of the site table names, from BC
#     Geographic Names
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
simplify_m <- 300
margin_m <- 15000

sites <- lapply(values$sites$site_id, site_get)
boxes <- do.call(rbind, lapply(sites, function(s) {
  b <- s$box
  ring <- matrix(c(b[["lon_min"]], b[["lat_min"]], b[["lon_max"]], b[["lat_min"]], b[["lon_max"]], b[["lat_max"]],
                   b[["lon_min"]], b[["lat_max"]], b[["lon_min"]], b[["lat_min"]]), ncol = 2, byrow = TRUE)
  # densified with no CRS, so the step is planar in degrees, not along great circles
  g <- sf::st_set_crs(sf::st_segmentize(sf::st_sfc(sf::st_polygon(list(ring))), 0.05), 4326)
  sf::st_sf(site_id = s$site_id, name = s$name, geom = sf::st_transform(g, 3005))
}))

st <- vm_stations(hydat, unique(values$gauges$station_number))
gauges <- merge(values$gauges, st[c("station_number", "station_name", "lon", "lat")], by = "station_number")
gauges <- vm_points(gauges[order(gauges$site_id, gauges$role, gauges$station_number), ])

tg <- values$sites
tg$lon <- ifelse(tg$kind == "extend", st$lon[match(tg$target, st$station_number)], tg$target_lon)
tg$lat <- ifelse(tg$kind == "extend", st$lat[match(tg$target, st$station_number)], tg$target_lat)
stopifnot(!anyNA(tg$lon), !anyNA(tg$lat))
targets <- vm_points(tg[c("site_id", "name", "kind", "target", "blue_line_key", "lon", "lat")])

conn <- vd_connect()
bc <- vm_bc(conn)
per_site <- lapply(sites, function(s) {
  pts <- c(sf::st_geometry(targets[targets$site_id == s$site_id, ]),
           sf::st_geometry(gauges[gauges$site_id == s$site_id, ]))
  ext <- vm_extent(sf::st_sf(geom = sf::st_buffer(pts, 1)), margin_m)
  streams <- vm_streams(conn, ext$wkt, s$blue_line_key, simplify_m, min_order = 6)
  if (!s$blue_line_key %in% streams$blue_line_key) stop(s$site_id, ": the target stream is not drawn", call. = FALSE)
  lakes <- vm_lakes(conn, ext$wkt, simplify_m, min_ha = 500)
  places <- if (length(s$places)) vm_places(ext$sfc, s$places) else NULL
  if (length(s$places) && !setequal(places$name, s$places)) {
    stop(s$site_id, ": places found ", paste(places$name, collapse = ", "), " for ", paste(s$places, collapse = ", "),
         call. = FALSE)
  }
  # cut to the extent: a big river comes back whole
  clip <- function(x) {
    # a simplified polygon can be invalid: repair only those rows (st_make_valid() rewrites valid ones too)
    bad <- !sf::st_is_valid(x)
    if (any(bad)) sf::st_geometry(x)[bad] <- sf::st_make_valid(sf::st_geometry(x)[bad])
    x <- suppressWarnings(sf::st_intersection(x, ext$sfc))
    x[!sf::st_is_empty(x), ]
  }
  streams <- clip(streams)
  lakes <- clip(lakes)
  list(extent = sf::st_sf(site_id = s$site_id, geom = ext$sfc),
       streams = cbind(site_id = s$site_id, streams), lakes = cbind(site_id = s$site_id, lakes),
       places = if (!is.null(places)) cbind(site_id = s$site_id, places))
})
DBI::dbDisconnect(conn)
pick <- function(k) do.call(rbind, lapply(per_site, `[[`, k))

layers <- vm_layers(list(bc = bc, boxes = boxes, targets = targets, gauges = gauges, extents = pick("extent"),
                         streams = pick("streams"), lakes = pick("lakes"), places = pick("places")), hydat)
saveRDS(layers, out, compress = "xz")
print(vapply(layers, nrow, 0L))
message("chinook_sites_map.rds: ", round(file.size(out) / 1024), " KB")
