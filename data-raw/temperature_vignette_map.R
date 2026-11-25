# Map layers for vignettes/articles/segment-temperature.Rmd (#220), which
# draws them from inst/vignette-data/ and never touches fwapg, HYDAT or the
# network at build.
#
#   Rscript data-raw/temperature_vignette_map.R
#
# Writes inst/vignette-data/temperature_map.rds: a named list of sf layers in
# EPSG:3005, xz-compressed:
#   - basin: the basin of the main stem the values bundle names (the
#     fundamental watershed polygons under its watershed code), with its area
#   - tree: the basin's main-flow tree, the network with no splits a stream
#     network model runs on, one MULTILINESTRING per stream order
#     (scripts/vignette_map_lib.R, vm_tree())
#   - streams: FWA streams of order 7 and up in the map extent, plus the whole
#     of each river the basin's row of scripts/temperature_basins.csv names (by
#     blue_line_key), cut to the extent
#   - lakes: FWA lakes of at least 500 ha, cut to the extent
#   - places: the towns the basin's row names, from BC Geographic Names
#   - stations: the basin's temperature stations (the values bundle's), with
#     `picked` for the one whose year the article shows and `fitted` for those
#     wet_temp_fill() could fit
#   - extent: the rectangle the map draws, the basin with a margin
#   - bc: the province outline for the keymap
#
# The list's "drawn" attribute holds the thresholds the layers were made with
# (`lake_min_ha`, `context_min_order` for the streams outside the tree,
# `simplify_m`), which the article's caption quotes and holds itself to.
# The list's "network" attribute holds what the tree says in numbers: `orders`
# (every tree segment of the basin by stream order, with the orders drawn),
# `reaches`, `km`, `with_station` (segments holding a station) and `wscode`.
# Its "provenance" adds the tree table, its row count and an md5 of the
# basin's segment ids in order to vm_layers()'s: the database records no build
# for the tree, so the count and the md5 are what name the one drawn. The copy
# drawn on 2026-11-25 has the 2026-10 build's 4,510,368 rows and no upstream
# area column, so the additive-function step of the network check was not run
# on this copy; the basin rule rests on the fork's record of that check.
#
# Every order is drawn. Measured on 2026-11-25 (planning/archive/*issue-220*):
# at 200 m, about a pixel of a map this size, all 52,293 segments are 351 KB,
# inside the 500 KB the tests allow one article's bundle; orders 2 and up are
# 104 KB and 3 and up 39 KB.
#
# Run it after data-raw/temperature_vignette_data.R, whose stations and basin
# it draws. fwapg from the WET_PG* variables (scripts/vignette_data_lib.R,
# vd_connect()), with the main-flow tree loaded.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect()
source("scripts/vignette_map_lib.R")
sf::sf_use_s2(FALSE)

f_values <- file.path("inst", "vignette-data", "temperature_values.rds")
# the stations and the pick are the committed bundle's, so the two files are built from one
if (length(vd_git("status", "--porcelain", "--", f_values))) stop("commit ", f_values, " first: its stations are drawn")
values <- readRDS(f_values)
basin <- values$basin
hydat <- wb_hydat(wb_release())
stopifnot(identical(format(as.Date(wet_hydat_release(hydat), "%Y%m%d")), values$provenance$hydat))
out <- file.path("inst", "vignette-data", "temperature_map.rds")
simplify_m <- 200
min_order <- 1
lake_min_ha <- 500
context_min_order <- 7
margin_m <- 12000
rivers <- as.integer(strsplit(basin$rivers, ";")[[1]])
towns <- strsplit(basin$towns, ";")[[1]]
stopifnot(basin$blue_line_key %in% rivers)

conn <- vd_connect()
tr <- vm_tree(conn, basin$blue_line_key, simplify_m, min_order)
# every station of the basin sits on a tree segment
stopifnot(all(values$stations$linear_feature_id %in% tr$ids))
ext <- vm_extent(tr$basin, margin_m)
streams <- vm_streams(conn, ext, rivers, simplify_m, min_order = context_min_order)
lakes <- vm_lakes(conn, ext, simplify_m, min_ha = lake_min_ha)
bc <- vm_bc(conn)
tree_rows <- as.numeric(DBI::dbGetQuery(conn, "
  SELECT count(*) AS n FROM whse_basemapping.fwa_stream_networks_mainflow_tree")$n)
pg <- vm_postgis(conn)
DBI::dbDisconnect(conn)

# a name can be several features: keep one populated place per name, the first by kind of place
places <- vm_places(ext$sfc, towns)
kinds <- c("City", "Town", "District Municipality (1)", "Village (1)", "Community", "Locality")
places <- places[places$feature_type %in% kinds, ]
places <- places[order(places$name, match(places$feature_type, kinds), method = "radix"), ]
places <- places[!duplicated(places$name), ]
if (!setequal(places$name, towns) || nrow(places) != length(towns)) {
  stop("places found ", paste(places$name, collapse = ", "), " for ", paste(towns, collapse = ", "), call. = FALSE)
}
rownames(places) <- NULL

# cut to the extent: a big river or lake comes back whole
clip <- function(x) {
  # a simplified polygon can be invalid: repair only those rows (st_make_valid() rewrites valid ones too)
  bad <- !sf::st_is_valid(x)
  if (any(bad)) sf::st_geometry(x)[bad] <- sf::st_make_valid(sf::st_geometry(x)[bad])
  x <- suppressWarnings(sf::st_intersection(x, ext$sfc))
  x <- x[!sf::st_is_empty(x), ]
  rownames(x) <- NULL
  x
}

st <- values$stations[c("station_number", "station_name", "lon", "lat", "linear_feature_id", "fitted")]
st$picked <- st$station_number == values$pick$station_number
stopifnot(sum(st$picked) == 1)
stations <- vm_points(st)
# each station lies in the basin it was placed in by its watershed code
stopifnot(all(lengths(sf::st_intersects(stations, tr$basin)) == 1))

layers <- vm_layers(list(basin = tr$basin, tree = tr$tree, streams = clip(streams), lakes = clip(lakes),
                         places = places, stations = stations, extent = sf::st_sf(geom = ext$sfc), bc = bc),
                    hydat, pg)
attr(layers, "network") <- list(orders = tr$orders, reaches = sum(tr$orders$segments), km = sum(tr$orders$km),
                                with_station = length(unique(st$linear_feature_id)), wscode = tr$wscode)
attr(layers, "drawn") <- list(lake_min_ha = lake_min_ha, context_min_order = context_min_order,
                              simplify_m = simplify_m)
prov <- attr(layers, "provenance")
f_ids <- tempfile()
writeLines(sprintf("%.0f", tr$ids), f_ids)
prov$tree <- list(table = "whse_basemapping.fwa_stream_networks_mainflow_tree", rows = tree_rows,
                  basin_ids_md5 = unname(tools::md5sum(f_ids)))
attr(layers, "provenance") <- prov
vm_write(layers, basename(out))
print(vapply(layers, nrow, 0L))
print(attr(layers, "network")$orders)
