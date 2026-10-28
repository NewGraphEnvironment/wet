# Map layers for vignettes/short-record-flow.Rmd (#130), which draws them from
# inst/vignette-data/ and never touches fwapg, HYDAT or the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/short_record_vignette_map.R
#
# Writes inst/vignette-data/short_record_map.rds: a named list of sf layers in
# EPSG:3005, xz-compressed:
#   - stations: every gauge the article names (inst/vignette-data/short_record_values.rds,
#     `gauges`), from HYDAT STATIONS, with gross drainage area and role
#   - catchments: the upstream watersheds of Maxan Creek (08EE018), Buck Creek
#     (08EE013) and the Bulkley near Houston (08EE003), from each one's FWA
#     snap (wet_station_snap()) and fwapg's fwa_watershedatmeasure()
#   - streams: order >= 5 in the map extent, plus the whole of the Bulkley
#     River, Buck Creek, Maxan Creek and Foxy Creek (Maxan's tributary, which the
#     article names) by blue_line_key, simplified
#   - lakes: FWA lakes of at least 100 ha in the map extent
#   - places: Houston, from BC Geographic Names (bcdata)
#   - bc: the province outline for the keymap
#
# The list carries a "provenance" attribute naming the HYDAT release. Run it
# after data-raw/short_record_vignette_data.R, whose gauges it draws. HYDAT is the
# release WET_HYDAT_RELEASE names, from wet's per-user cache (wb_hydat());
# fwapg from the WET_PG* variables. The layers are made by
# scripts/vignette_map_lib.R, shared with the other articles' map scripts.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # for the fwapg connection, vd_connect
source("scripts/vignette_map_lib.R")
sf::sf_use_s2(FALSE)

values <- readRDS(file.path("inst", "vignette-data", "short_record_values.rds"))
gauges <- values$gauges
catchment_ids <- c("08EE003", "08EE013", "08EE018")   # the three the snow fits sample
blk <- c(bulkley = 360873822L, buck = 360886221L, maxan = 360881038L,   # by key: GNIS names repeat across BC
         foxy = 360877225L)
hydat <- wb_hydat(wb_release())
out <- file.path("inst", "vignette-data", "short_record_map.rds")
simplify_m <- 50

st <- vm_stations(hydat, gauges$station_number)
st <- cbind(st, gauges[match(st$station_number, gauges$station_number),
                       c("extension_donor", "carried_donor", "snow")])
conn <- vd_connect()
catch <- vm_catchments(conn, st[st$station_number %in% catchment_ids, ], simplify_m)
pts <- vm_points(st)
# the extent holds the catchments and every gauge, with room for labels
ext <- vm_extent(rbind(sf::st_sf(geom = sf::st_geometry(catch)),
                       sf::st_sf(geom = sf::st_buffer(sf::st_geometry(pts), 1))), 8000)
streams <- vm_streams(conn, ext$wkt, blk, simplify_m)
# the keys are the streams named, not only three keys
stopifnot(identical(streams$gnis_name[match(blk, streams$blue_line_key)], c("Bulkley River", "Buck Creek", "Maxan Creek", "Foxy Creek")))
lakes <- vm_lakes(conn, ext$wkt, simplify_m)
bc <- vm_bc(conn)
DBI::dbDisconnect(conn)
places <- vm_places(ext$sfc, "Houston")
stopifnot(nrow(places) == 1)

layers <- vm_layers(list(stations = pts, catchments = catch, streams = streams, lakes = lakes,
                         places = places, bc = bc), hydat)
saveRDS(layers, out, compress = "xz")
print(vapply(layers, nrow, 0L))   # features per layer: merged streams mix line types
message("short_record_map.rds: ", round(file.size(out) / 1024), " KB")
