# Sanity map of the open water balance's annual runoff (#11, Phase 7).
#
#   Rscript scripts/wb_map.R
#
# Reads data/wb/<key>/runoff_annual.tif (scripts/wb_output.R) and the
# calibration stations recorded in fits.rds, and writes the map as a PNG
# under research/ (wb_runoff_annual).

devtools::load_all(quiet = TRUE)
sf::sf_use_s2(FALSE)
keys <- list.dirs("data/wb", recursive = FALSE, full.names = TRUE)
keys <- keys[file.exists(file.path(keys, "upstream", "_complete"))]
if (length(keys) != 1) stop("expected one complete province run under data/wb, found ", length(keys))
if (!file.exists(file.path(keys, "runoff_annual.tif"))) stop("run scripts/wb_output.R first")
cal_ids <- readRDS(file.path(keys, "fits.rds"))$calibration
reg <- gq::gq_reg_main()

ro <- terra::rast(file.path(keys, "runoff_annual.tif"))
ro <- terra::aggregate(ro, 4, mean, na.rm = TRUE)  # ~3 km for a page-width map
ro <- terra::project(ro, "EPSG:3005", method = "bilinear")

s <- readRDS("data/wb/stations.rds")$stations
s <- s[s$station_number %in% cal_ids, ]  # the calibration stations only
pts <- sf::st_as_sf(s, coords = c("lon", "lat"), crs = 4326) |> sf::st_transform(3005)

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
bc <- sf::st_read(conn, query = "SELECT ST_Union(geom) AS geom FROM whse_basemapping.fwa_bcboundary",
                  quiet = TRUE)
DBI::dbDisconnect(conn)

# the output covers BC's FWA watersheds only, so the grid is masked to BC:
# otherwise Alberta, Washington and Alaska read as part of the subject
ro <- terra::mask(ro, terra::vect(bc))
st_sty <- gq::gq_tmap_style(reg$layers$hydrometric_stations_environment_canada)
# canvas aspect from the extent, so the map fills the frame
bb <- sf::st_bbox(bc)
asp <- as.numeric((bb$ymax - bb$ymin) / (bb$xmax - bb$xmin))
brk <- c(0, 100, 200, 400, 700, 1000, 1500, 2500, Inf)
m <- tmap::tm_shape(ro, raster.downsample = FALSE) +
  tmap::tm_raster("runoff_mm",
                  col.scale = tmap::tm_scale_intervals(breaks = brk, values = "brewer.yl_gn_bu"),
                  col.legend = tmap::tm_legend(title = "Mean annual runoff,\n1981-2010 (mm)",
                                               position = tmap::tm_pos_in("right", "top"))) +
  tmap::tm_shape(bc, is.main = TRUE) + tmap::tm_borders(col = "grey30", lwd = 0.6) +
  tmap::tm_shape(pts) +
  tmap::tm_symbols(size = 0.25, fill = st_sty$fill, shape = st_sty$shape, col = "grey20", lwd = 0.4) +
  tmap::tm_add_legend(type = "symbols", labels = "Calibration gauge (HYDAT)", fill = st_sty$fill,
                      shape = st_sty$shape, col = "grey20", size = 0.4,
                      position = tmap::tm_pos_in("right", "top")) +
  tmap::tm_add_legend(type = "lines", labels = "BC boundary", col = "grey30", lwd = 0.6,
                      position = tmap::tm_pos_in("right", "top")) +
  tmap::tm_scalebar(position = tmap::tm_pos_in("left", "bottom")) +
  tmap::tm_layout(frame = TRUE, inner.margins = c(0.01, 0.01, 0.01, 0.01), outer.margins = 0)
tmap::tmap_save(m, "research/wb_runoff_annual.png", width = 7, height = 7 * asp, dpi = 150)
message("research/wb_runoff_annual.png written")
