#' Elevation on a template grid from the Copernicus GLO-90 DEM
#'
#' Averages the Copernicus DEM GLO-90 (public cloud-optimised GeoTIFFs on AWS
#' open data) onto the grid of `template`, reading each 1-degree tile over
#' `/vsicurl/`. Ground covered by no tile (open ocean away from land) is `NA`;
#' sea inside a tile is 0 m, as GLO-90 records it, so `NA` is not a land mask. Used to drive climr's lapse-rate downscaling on the
#' same grid as the CGIAR AET, so no input is resampled twice.
#'
#' Copernicus DEM (c) DLR e.V. 2010-2014 and (c) Airbus Defence and Space GmbH
#' 2014-2018, provided under COPERNICUS by the European Union and ESA.
#'
#' @param template Path to a raster (or a `SpatRaster`) whose grid is the
#'   output grid, in EPSG:4326.
#' @param dir Cache directory.
#' @param overwrite Logical. Rebuild even when cached.
#' @return Path to a one-layer GeoTIFF of elevation (m), named `elev`.
#' @export
wet_dem_glo90 <- function(template, dir = "data/dem", overwrite = FALSE) {
  tmpl <- terra::rast(template)[[1]]
  # the cache key is the extent and dims, which identify a grid only in lon/lat
  if (!terra::is.lonlat(tmpl)) stop("template must be in lon/lat (EPSG:4326)", call. = FALSE)
  e <- as.vector(terra::ext(tmpl))
  # keyed on the grid and the method version, so a changed build never reuses an old DEM
  key <- wet_md5_text(paste(c(wet_grid_key(tmpl), wet_dem_method), collapse = "|"))
  dest <- file.path(dir, sprintf("glo90_%s.tif", substr(key, 1, 10)))
  if (file.exists(dest) && !overwrite) return(dest)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  base <- getOption("wet.glo90_base", "https://copernicus-dem-90m.s3.amazonaws.com")
  lst <- tempfile(fileext = ".txt")
  on.exit(unlink(lst), add = TRUE)
  wet_download(paste0(base, "/tileList.txt"), lst, 120)
  have <- readLines(lst)
  want <- wet_glo90_names(e[c(1, 3, 2, 4)])
  tiles <- intersect(want, have)
  if (!length(tiles)) stop("no GLO-90 tiles intersect the template", call. = FALSE)

  old <- wet_gdal_config_set(c(GDAL_DISABLE_READDIR_ON_OPEN = "EMPTY_DIR",
                               CPL_VSIL_CURL_ALLOWED_EXTENSIONS = ".tif"))
  on.exit(wet_gdal_config_set(old), add = TRUE)
  urls <- sprintf("/vsicurl/%s/%s/%s.tif", base, tiles, tiles)
  # Without a VRT nodata the ground between tiles (open ocean, no tile) reads
  # as 0 m rather than NA. GLO-90's x-resolution steps with latitude (3", 4.5",
  # 6"), so the VRT is built at the finest, not the average, and every tile
  # cell counts in the 30" mean.
  v <- terra::vrt(urls, options = c("-vrtnodata", "-9999", "-resolution", "highest"))
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  out <- terra::project(v, tmpl, method = "average")
  names(out) <- "elev"
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move DEM to ", dest, call. = FALSE)
  dest
}

# Bump whenever wet_dem_glo90() changes what it computes. 3: VRT at the finest
# tile resolution. 2: gaps between tiles are NA. (Before #19 the version sat in
# the file name as "glo90v3_".)
wet_dem_method <- "vrt-highest-average-3"

# GLO-90 tile names covering c(xmin, ymin, xmax, ymax). A tile is named by
# its south-west corner, e.g. N54_00_W128_00 covers 54-55 N, 128-127 W.
wet_glo90_names <- function(bbox) {
  lats <- seq(floor(bbox[2]), ceiling(bbox[4]) - 1)
  lons <- seq(floor(bbox[1]), ceiling(bbox[3]) - 1)
  g <- expand.grid(lat = lats, lon = lons)
  sprintf("Copernicus_DSM_COG_30_%s%02d_00_%s%03d_00_DEM",
          ifelse(g$lat >= 0, "N", "S"), abs(g$lat),
          ifelse(g$lon >= 0, "E", "W"), abs(g$lon))
}

# Set GDAL config options from a named vector and return the previous values
# in the same form, to pass back on exit. The two-argument setGDALconfig() is
# used deliberately: "KEY=" with an empty value (an option that was unset) is
# stored by terra as the string "NA", which breaks every later /vsicurl/ read
# in the session.
wet_gdal_config_set <- function(x) {
  old <- terra::getGDALconfig(names(x))
  terra::setGDALconfig(names(x), unname(x))
  stats::setNames(unname(old), names(x))
}
