# Map layers for vignettes/articles/chinook-sites.Rmd (#126), which draws them
# from inst/vignette-data/ and never touches fwapg, HYDAT or the network at
# build.
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
#
# Run it after data-raw/chinook_sites_data.R, whose gauges it draws. The
# province is drawn whole, so no stream or lake layer: at that scale they are
# noise and would blow the 500 KB budget.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect()
source("scripts/vignette_map_lib.R")
source("scripts/departure_site_lib.R")
sf::sf_use_s2(FALSE)

values <- readRDS(file.path("inst", "vignette-data", "chinook_sites_values.rds"))
hydat <- wb_hydat(wb_release())
out <- file.path("inst", "vignette-data", "chinook_sites_map.rds")

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
gauges <- merge(values$gauges, st[c("station_number", "lon", "lat")], by = "station_number")
gauges <- vm_points(gauges[order(gauges$site_id, gauges$role, gauges$station_number), ])

tg <- values$sites
tg$lon <- ifelse(tg$kind == "extend", st$lon[match(tg$target, st$station_number)], tg$target_lon)
tg$lat <- ifelse(tg$kind == "extend", st$lat[match(tg$target, st$station_number)], tg$target_lat)
stopifnot(!anyNA(tg$lon), !anyNA(tg$lat))
targets <- vm_points(tg[c("site_id", "name", "kind", "target", "lon", "lat")])

conn <- vd_connect()
bc <- vm_bc(conn)
DBI::dbDisconnect(conn)

layers <- vm_layers(list(bc = bc, boxes = boxes, targets = targets, gauges = gauges), hydat)
saveRDS(layers, out, compress = "xz")
print(vapply(layers, nrow, 0L))
message("chinook_sites_map.rds: ", round(file.size(out) / 1024), " KB")
