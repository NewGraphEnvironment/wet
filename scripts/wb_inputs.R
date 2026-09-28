# Inputs for the open water balance (#11), all on the CGIAR 30" grid over BC.
#
#   Rscript scripts/wb_inputs.R
#
# Builds (cached, gitignored): CGIAR AET, the GLO-90 DEM, climr 1981-2010
# monthly P and T normals, and the extended BC Hydrologic Zones rasterised to
# the grid; for the ET experiment (#15) also climr Tmax/Tmin normals, the
# TerraClimate 1981-2010 AET and precipitation, and NRCan 2020 land-cover
# fractions per Chapman Table 3 class; for #18 the MOD16A3GF 2001-2020 mean
# annual ET (an Earthdata login in a netrc, for granules not yet in
# data/mod16). Writes two tracked reports:
#   * data/checks/wb_inputs.txt    - the input manifest (source, md5, grid)
#   * data/checks/climr_eccc.txt   - climr 1981-2010 vs ECCC station normals
# Connection from WET_PG* env vars (for the BC extent).

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
dir.create("data/checks", recursive = TRUE, showWarnings = FALSE)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

# ---- grid extent: every FWA watershed group, padded ------------------------------
e <- DBI::dbGetQuery(conn, "
  SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT ST_Extent(ST_Transform(geom, 4326)) e
        FROM whse_basemapping.fwa_watershed_groups_poly) x")
DBI::dbDisconnect(conn)
bbox <- round(c(floor(e$xmin * 10) / 10, floor(e$ymin * 10) / 10,
                ceiling(e$xmax * 10) / 10, ceiling(e$ymax * 10) / 10), 1)
stamp("bbox ", paste(bbox, collapse = ", "))

# ---- rasters ----------------------------------------------------------------------
f_aet <- wet_cgiar_aet(bbox)
stamp("AET ", f_aet)
f_dem <- wet_dem_glo90(f_aet)
stamp("DEM ", f_dem)
f_clim <- wet_climr_normals(f_dem)
stamp("climr ", f_clim)
# Tmax/Tmin for Hargreaves PET (#15), in a file of their own so the P/T normals
# above keep their cache key
f_tx <- wet_climr_normals(f_dem, vars = c(sprintf("Tmax_%02d", 1:12), sprintf("Tmin_%02d", 1:12)))
stamp("climr Tmax/Tmin ", f_tx)
f_tc <- wet_terraclimate_aet(f_aet)
stamp("TerraClimate ", f_tc)
f_lc <- wet_landcover_nrcan(f_aet)
stamp("land cover ", f_lc)
# MOD16A3GF v061 annual ET, 2001-2020 (#18); needs an Earthdata login for new granules
f_m16 <- wet_mod16_aet(f_aet)
stamp("MOD16 ", f_m16)
# the granules wet_mod16_aet() read (its tiles x 2001-2020), not whatever else is in the directory
f_m16_granules <- sort(basename(wet:::wet_mod16_local("data/mod16", wet:::wet_modis_tiles(terra::rast(f_aet)),
                                                      2001:2020)$path))

# Extended BC Hydrologic Zones (43 features; reaches the FWA polygons outside BC)
hz_url <- paste0("https://catalogue.data.gov.bc.ca/dataset/f1f86c41-ae83-49d5-92e1-526897b99fa2/",
                 "resource/fc209bd0-26ab-4f8b-9415-8f34081a3c0e/download/bc_hydrologic_zones.zip")
hz_dir <- "data/hydz"
hz_zip <- file.path(hz_dir, "bc_hydrologic_zones.zip")
if (!file.exists(hz_zip)) {
  dir.create(hz_dir, recursive = TRUE, showWarnings = FALSE)
  wet:::wet_download(hz_url, hz_zip, 300)  # renamed into place only when complete
}
# Unzipped into a directory named for the zip's md5, and exactly one layer
# required, so the zones read are always the zip's own.
hz_md5 <- unname(tools::md5sum(hz_zip))
hz_src <- file.path(hz_dir, paste0("src_", substr(hz_md5, 1, 8)))
utils::unzip(hz_zip, exdir = hz_src, overwrite = TRUE)
hz_shp <- list.files(hz_src, "\\.shp$", full.names = TRUE, recursive = TRUE)
if (length(hz_shp) != 1) stop("expected one .shp in ", hz_zip, ", found ", length(hz_shp))
hz <- terra::vect(hz_shp)
# Keyed on the grid it was rasterised to and on the zones' own content.
f_hz <- file.path(hz_dir, sub("^cgiar_aet_(.*)\\.tif$",
                              paste0("hydz_\\1_", substr(hz_md5, 1, 8), ".tif"),
                              basename(f_aet)))
if (!file.exists(f_hz)) {
  # written to a temp file and renamed, so a killed run never leaves a
  # truncated grid at the cached path
  # Rasterised in memory, then written: rasterize(filename = , wopt =
  # list(datatype = "INT1U")) writes the NA background as 0 (terra 1.9.46 and
  # 1.9.50; rspatial/terra#2195). Drop this once that is fixed.
  tmp <- tempfile(fileext = ".tif", tmpdir = hz_dir)
  z <- terra::rasterize(terra::project(hz, "EPSG:4326"), terra::rast(f_aet)[[1]], field = "HYDZN_NO")
  terra::writeRaster(z, tmp, datatype = "INT1U", overwrite = TRUE)
  if (!file.rename(tmp, f_hz)) stop("could not move zones grid to ", f_hz)
}
stamp("zones ", nrow(hz), " features -> ", f_hz)

# ---- manifest -----------------------------------------------------------------------
md5 <- function(f) unname(tools::md5sum(f))
grid_of <- function(f) {
  r <- terra::rast(f)
  sprintf("%d x %d x %d, res %.7f, ext %s", terra::nrow(r), terra::ncol(r), terra::nlyr(r),
          terra::res(r)[1], paste(round(as.vector(terra::ext(r)), 5), collapse = " "))
}
rows <- data.frame(
  input = c("CGIAR Soil-Water Balance v3 AET (annual)", "CGIAR Soil-Water Balance v3 AET (monthly)",
            "BC Hydrologic Zones (extended)", "AET crop", "GLO-90 DEM", "climr normals",
            "Hydrologic zones grid", "climr Tmax/Tmin normals", "TerraClimate 1981-2010 AET",
            "TerraClimate 1981-2010 precipitation", "TerraClimate annual grid",
            "NRCan 2020 land cover", "Land-cover fractions (Chapman Table 3 classes)"),
  source = c("https://figshare.com/articles/dataset/7707605 (CC0)",
             "https://figshare.com/articles/dataset/7707605 (CC0)", paste(hz_url, "(OGL-BC)"),
             "wet_cgiar_aet()", "Copernicus DEM GLO-90 via wet_dem_glo90()",
             "climr refmap_climr + mswx.blend obs 1981-2010 via wet_climr_normals()",
             "terra::rasterize(HYDZN_NO)",
             "climr refmap_climr + mswx.blend obs 1981-2010 via wet_climr_normals()",
             "http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/climatology (CC0)",
             "http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/climatology (CC0)",
             "wet_terraclimate_aet() (annual sums, bilinear)",
             paste("https://datacube-prod-data-public.s3.ca-central-1.amazonaws.com/store/land/landcover/",
                   "(OGL-Canada)"),
             "wet_landcover_nrcan() (inst/extdata/chapman_table3.csv crosswalk)"),
  file = c("data/cgiar/AET_YR.rar", "data/cgiar/aet_monthly.rar", hz_zip, f_aet, f_dem, f_clim, f_hz,
           f_tx, "data/terraclimate/TerraClimate_19812010_aet.nc",
           "data/terraclimate/TerraClimate_19812010_ppt.nc", f_tc,
           "data/landcover/landcover-2020-classification.tif", f_lc)
)
rows$md5 <- vapply(rows$file, md5, "")
# the MOD16 granules as one row: their count, and the md5 of their names and md5s
m16_g <- file.path("data/mod16", f_m16_granules)
rows <- rbind(rows, data.frame(
  input = c(sprintf("MOD16A3GF v061 annual ET, 2001-2020 (%d granules)", length(m16_g)), "MOD16 annual grid"),
  source = c("https://doi.org/10.5067/MODIS/MOD16A3GF.061 (NASA LP DAAC; CMR search, Earthdata login)",
             "wet_mod16_aet() (year mean, two-step onto the grid)"),
  file = c("data/mod16/MOD16A3GF.A*.hdf", f_m16),
  md5 = c(wet:::wet_md5_text(paste(f_m16_granules, md5(m16_g))), md5(f_m16))))
is_tif <- grepl("\\.tif$", rows$file)
rows$grid <- ""
rows$grid[is_tif] <- vapply(rows$file[is_tif], grid_of, "")
con <- file("data/checks/wb_inputs.txt", "w")
writeLines(c("# Inputs for the open water balance (#11) and the ET experiments (#15, #18)", "",
             sprintf("built: %s", Sys.Date()),
             sprintf("bbox (EPSG:4326): %s", paste(bbox, collapse = ", ")),
             sprintf("climr %s, terra %s", utils::packageVersion("climr"),
                     utils::packageVersion("terra")), ""), con)
for (i in seq_len(nrow(rows))) {
  writeLines(c(sprintf("## %s", rows$input[i]), sprintf("source: %s", rows$source[i]),
               sprintf("file:   %s", rows$file[i]), sprintf("md5:    %s", rows$md5[i]),
               if (nzchar(rows$grid[i])) sprintf("grid:   %s", rows$grid[i]), ""), con)
}
close(con)
stamp("manifest written")

# ---- climr vs ECCC 1981-2010 station normals -------------------------------------------
# Independent check of the period: WMO-standard ("A") normals only.
eccc <- function(q) {
  f <- tempfile(fileext = ".json")
  wet:::wet_download(paste0("https://api.weather.gc.ca/collections/", q), f, 300)
  jsonlite::fromJSON(f)$features
}
norm <- function(id) {
  x <- eccc(sprintf("climate-normals/items?f=json&limit=5000&PROVINCE_CODE=BC&MONTH=13&NORMAL_ID=%d", id))
  p <- x$properties
  p <- p[p$NORMAL_CODE == "A" & p$PERIOD_BEGIN == 1981 & p$PERIOD_END == 2010, ]
  data.frame(climate_id = p$CLIMATE_IDENTIFIER, station = p$STATION_NAME, value = p$VALUE)
}
ppt <- norm(56)
tav <- norm(1)
# LATITUDE/LONGITUDE there are packed DMS (544929000 = 54 49' 29"), so take
# the decimal coordinates from the geometry.
stf <- eccc("climate-stations/items?f=json&limit=10000&PROV_STATE_TERR_CODE=BC")
xy <- do.call(rbind, stf$geometry$coordinates)
st <- data.frame(climate_id = stf$properties$CLIMATE_IDENTIFIER, lon = xy[, 1], lat = xy[, 2],
                 elev = as.numeric(stf$properties$ELEVATION))
obs <- merge(merge(ppt, tav, by = c("climate_id", "station"), suffixes = c("_ppt", "_tave")),
             st, by = "climate_id")
obs <- obs[stats::complete.cases(obs), ]
pts <- data.frame(id = seq_len(nrow(obs)), lon = obs$lon, lat = obs$lat, elev = obs$elev)
cl <- suppressMessages(climr::downscale(
  pts, which_refmap = "refmap_climr", obs_ts_dataset = "mswx.blend", obs_years = 1981:2010,
  vars = c("MAP", "MAT"), return_refperiod = FALSE
))
cl <- as.data.frame(cl)
cl <- cl[!is.na(cl$PERIOD), ]
obs$id <- pts$id
obs$climr_map <- as.numeric(tapply(cl$MAP, factor(cl$id, levels = obs$id), mean))
obs$climr_mat <- as.numeric(tapply(cl$MAT, factor(cl$id, levels = obs$id), mean))
n_no_climr <- sum(is.na(obs$climr_map) | is.na(obs$climr_mat))
obs <- obs[!is.na(obs$climr_map) & !is.na(obs$climr_mat), ]
obs$map_ratio <- obs$climr_map / obs$value_ppt
obs$mat_diff <- obs$climr_mat - obs$value_tave
q <- function(x) paste(sprintf("%.3f", stats::quantile(x, c(0.1, 0.5, 0.9), na.rm = TRUE)), collapse = " / ")
con <- file("data/checks/climr_eccc.txt", "w")
writeLines(c(
  "# climr 1981-2010 (refmap_climr + mswx.blend obs, averaged by year) vs ECCC 1981-2010 normals",
  "", sprintf("stations (BC, WMO 'A' code, both P and T): %d (dropped, no climr value: %d)",
              nrow(obs), n_no_climr),
  sprintf("MAP ratio climr / ECCC, p10 / median / p90: %s", q(obs$map_ratio)),
  sprintf("MAT difference climr - ECCC (deg C), p10 / median / p90: %s", q(obs$mat_diff)),
  sprintf("MAP ratio outside 0.8-1.25: %d stations", sum(obs$map_ratio < 0.8 | obs$map_ratio > 1.25)),
  "", "Per station (climate_id, station, elev, ECCC MAP, climr MAP, ratio, ECCC MAT, climr MAT):",
  sprintf("%s  %-28s %6.0f %7.1f %7.1f %5.2f %6.2f %6.2f", obs$climate_id, substr(obs$station, 1, 28),
          obs$elev, obs$value_ppt, obs$climr_map, obs$map_ratio, obs$value_tave, obs$climr_mat)
), con)
close(con)
stamp("climr vs ECCC: ", nrow(obs), " stations, MAP ratio median ",
      round(stats::median(obs$map_ratio), 3))
