# Map layers for vignettes/flow-departure-normal.Rmd (#27, #145), which draws them from
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
# The list carries a "provenance" attribute naming the HYDAT release.
#
# Separate from data-raw/station_vignette_data.R so that refreshing the map
# does not refetch the daily series. HYDAT is the release WET_HYDAT_RELEASE
# names, by default the water balance's shipped one, from wet's per-user cache
# (wb_hydat()); fwapg from the WET_PG* variables. The layers are made by
# scripts/vignette_map_lib.R, shared with data-raw/monthly_vignette_map.R.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # for the fwapg connection, vd_connect
source("scripts/vignette_map_lib.R")
sf::sf_use_s2(FALSE)

stations <- c("08EE013", "08EE003")
blk <- c(bulkley = 360873822L, buck = 360886221L)   # by key: GNIS names repeat across BC
hydat <- wb_hydat(wb_release())
out <- file.path("inst", "vignette-data", "station_map.rds")
simplify_m <- 50

st <- vm_stations(hydat, stations)
conn <- vd_connect()
catch <- vm_catchments(conn, st, simplify_m)
ext <- vm_extent(catch, 8000)
streams <- vm_streams(conn, ext$wkt, blk, simplify_m)
lakes <- vm_lakes(conn, ext$wkt, simplify_m)
bc <- vm_bc(conn)
DBI::dbDisconnect(conn)
places <- vm_places(ext$sfc, "Houston")
stopifnot(nrow(places) == 1)

layers <- vm_layers(list(stations = vm_points(st), catchments = catch, streams = streams, lakes = lakes,
                         places = places, bc = bc), hydat)
saveRDS(layers, out, compress = "xz")
print(vapply(layers, function(x) nrow(sf::st_coordinates(x)), 0))
message("station_map.rds: ", round(file.size(out) / 1024), " KB")
