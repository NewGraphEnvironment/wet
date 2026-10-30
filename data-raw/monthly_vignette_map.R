# Map layers for the Bulkley gauges in vignettes/segment-discharge.Rmd (#107; the
# monthly-flow article until #149), which reads them from inst/vignette-data/
# and never touches fwapg, HYDAT or the network at build. Since #149 the article
# draws no Bulkley map: it reads only the stations and catchments, to guard its
# sentences on how the gauges nest and which way the Bulkley flows; the other
# layers are kept so the bundle still holds what a map of the three would need.
#
#   Rscript data-raw/monthly_vignette_map.R
#
# Writes inst/vignette-data/monthly_map.rds, the layers of station_map.rds
# (data-raw/station_vignette_map.R, scripts/vignette_map_lib.R) for the three
# Bulkley gauges the article compares, 08EE013, 08EE003 and 08EE004, over the
# extent of the Bulkley at Quick's catchment, which holds the other two:
#   - stations, catchments: as station_map.rds, three of each; the catchments
#     must nest (Buck Creek's inside Houston's, both inside Quick's)
#   - streams: order >= 5 in the extent, plus the Bulkley River and Buck Creek
#   - lakes: FWA lakes of at least 100 ha in the extent
#   - places: Houston and Telkwa, from BC Geographic Names (bcdata)
#   - bc: the province outline for the keymap
#
# HYDAT is the release WET_HYDAT_RELEASE names (wb_hydat()); fwapg from the
# WET_PG* variables. The list carries a "provenance" attribute naming the
# HYDAT release.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # for the fwapg connection, vd_connect
source("scripts/vignette_map_lib.R")
sf::sf_use_s2(FALSE)

stations <- c("08EE013", "08EE003", "08EE004")
blk <- c(bulkley = 360873822L, buck = 360886221L)   # by key: GNIS names repeat across BC
hydat <- wb_hydat(wb_release())
out <- file.path("inst", "vignette-data", "monthly_map.rds")
simplify_m <- 100   # a basin of 7,000 km2 at seven inches: 50 m is below a pixel

st <- vm_stations(hydat, stations)
conn <- vd_connect()
catch <- vm_catchments(conn, st, simplify_m)
ext <- vm_extent(catch, 8000)
streams <- vm_streams(conn, ext$wkt, blk, simplify_m)
lakes <- vm_lakes(conn, ext$wkt, simplify_m)
bc <- vm_bc(conn)
DBI::dbDisconnect(conn)
places <- vm_places(ext$sfc, c("Houston", "Telkwa"))
stopifnot(nrow(places) == 2)

# the catchments nest: each smaller one lies within the next, which the
# article's map and prose say
geom_of <- function(s) sf::st_geometry(catch[catch$station_number == s, ])
inside <- function(a, b) {
  as.numeric(sf::st_area(sf::st_intersection(geom_of(a), geom_of(b)))) / as.numeric(sf::st_area(geom_of(a)))
}
stopifnot(inside("08EE013", "08EE003") > 0.99, inside("08EE003", "08EE004") > 0.99)

layers <- vm_layers(list(stations = vm_points(st), catchments = catch, streams = streams, lakes = lakes,
                         places = places, bc = bc), hydat)
saveRDS(layers, out, compress = "xz")
# vertices per layer, geometry by geometry: a merged stream layer mixes
# LINESTRING and MULTILINESTRING, which st_coordinates() refuses as a whole
print(vapply(layers, function(x) sum(vapply(sf::st_geometry(x), function(g) nrow(sf::st_coordinates(g)), 0)), 0))
message("monthly_map.rds: ", round(file.size(out) / 1024), " KB")
