#' Monthly climate normals for an arbitrary period from climr
#'
#' Downscales climr's reference climatology onto an elevation grid, shifted to
#' the mean of an observed time series over `years`. climr expresses each
#' observed year as an anomaly on its 1961-1990 reference period: a ratio for
#' precipitation and an offset for temperature. Both are linear, so averaging
#' the anomalies before downscaling gives the same normal as downscaling each
#' year and averaging, at a thirtieth of the cost.
#'
#' @param dem Path to a one-layer elevation raster (m, EPSG:4326), or a
#'   `SpatRaster`. Its grid is the output grid.
#' @param years Integer vector of years to average.
#' @param dataset climr observed time series: `"mswx.blend"` (default),
#'   `"climatena"` or `"cru.gpcc"`. The ClimateNA series is `NA` over coastal
#'   islands (Haida Gwaii, northern Vancouver Island) on its 1-degree grid, so
#'   averaging its anomalies leaves those islands without normals; the 0.5-degree
#'   MSWX blend covers them.
#' @param vars climr variable codes to return: monthly `PPT_MM`, `Tave_MM`,
#'   `Tmax_MM`, `Tmin_MM`, and `MAP`, `MAT`. Derived variables that are not
#'   linear in the anomalies (degree days, PAS, CMD) are refused, since
#'   averaging anomalies first would bias them.
#' @param dir Cache directory.
#' @param overwrite Logical. Rebuild even when cached.
#' @return Path to a GeoTIFF with one layer per variable in `vars`.
#' @export
wet_climr_normals <- function(dem, years = 1981:2010, dataset = "mswx.blend",
                              vars = c(sprintf("PPT_%02d", 1:12), sprintf("Tave_%02d", 1:12)),
                              dir = "data/climr", overwrite = FALSE) {
  vars <- unique(vars)
  nonlin <- vars[!grepl("^((PPT|Tave|Tmax|Tmin)_(0[1-9]|1[0-2])|MAP|MAT)$", vars)]
  if (length(nonlin)) {
    stop("averaging anomalies first is exact only for monthly PPT/Tave/Tmax/Tmin, MAP and MAT; ",
         "not: ", paste(nonlin, collapse = ", "), call. = FALSE)
  }
  if (!requireNamespace("climr", quietly = TRUE)) {
    stop("wet_climr_normals() needs climr: pak::pak(\"bcgov/climr\")", call. = FALSE)
  }
  # rast() on a SpatRaster returns an empty template, so only paths go through it.
  elev <- if (inherits(dem, "SpatRaster")) dem[[1]] else terra::rast(dem)[[1]]
  # The key carries every year and every variable, so a call for a different
  # set never returns a cached file built from another one.
  years <- sort(unique(as.integer(years)))
  # ... and the elevations themselves, which drive the lapse-rate downscaling:
  # the same grid with other values is other normals.
  vkey <- wet_md5_text(paste(c(paste(years, collapse = ","), vars, wet_raster_md5(elev)),
                             collapse = "|"))
  dest <- file.path(dir, sprintf("climr_%s_%d-%d_%s_%s.tif", dataset, min(years), max(years),
                                 substr(wet_grid_key(elev), 1, 8), substr(vkey, 1, 8)))
  if (file.exists(dest) && !overwrite) return(dest)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  names(elev) <- "elev"
  # As climr::downscale() does for a raster: one bbox from the grid, and the
  # reference map prepared against the grid itself.
  bb <- climr::get_bb(elev)
  refmap <- climr::input_refmap(bbox = bb, xyz = elev)
  ts <- climr::input_obs_ts(dataset = dataset, bbox = bb, years = years)[[1]]
  # downscale_core() rejects an in-memory anomaly raster ("raster has no
  # values"), so the mean is written out and read back as a file-backed one.
  anom <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(anom), add = TRUE)
  terra::writeRaster(wet_climr_anomaly_mean(ts, dataset, years), anom)
  period <- sprintf("%d_%d", min(years), max(years))
  obs <- stats::setNames(list(terra::rast(anom)), period)
  attr(obs, "builder") <- "climr"  # downscale_core() accepts only climr-built inputs

  out <- climr::downscale_core(elev, refmap = refmap, obs = obs, return_refperiod = FALSE,
                               vars = vars)
  # climr labels observed-period layers "OBS_<var>_2001_2020" whatever the
  # period the anomaly carries (climr 0.2.2); the values are ours.
  names(out) <- sub("^OBS_(.*)_[0-9]{4}_[0-9]{4}$", "\\1", names(out))
  out <- out[[vars]]
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move normals to ", dest, call. = FALSE)
  dest
}

# Mean anomaly per variable over the years of a climr observed time series,
# whose layers are named "<dataset>_<VAR>_<MM>_<YYYY>".
wet_climr_anomaly_mean <- function(ts, dataset, years) {
  nm <- names(ts)
  # the dataset name is literal ("mswx.blend" has a dot), so strip it by length
  pre <- paste0(dataset, "_")
  if (!all(startsWith(nm, pre))) stop("layers are not all from climr dataset ", dataset, call. = FALSE)
  var <- sub("_[0-9]{4}$", "", substring(nm, nchar(pre) + 1))
  yr <- as.integer(sub(".*_([0-9]{4})$", "\\1", nm))
  missing <- setdiff(years, yr)
  if (length(missing)) stop("climr ", dataset, " lacks years: ", paste(missing, collapse = ", "),
                            call. = FALSE)
  keep <- yr %in% years
  v <- unique(var[keep])
  out <- terra::rast(lapply(v, function(x) terra::mean(ts[[which(keep & var == x)]])))
  names(out) <- v
  out
}

# md5 of a string, via a file: tools::md5sum() is base R and stable across
# versions, unlike a hash an R package reserves the right to change.
wet_md5_text <- function(x) {
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  writeLines(x, f, useBytes = TRUE)
  unname(tools::md5sum(f))
}

# md5 of a raster's values (not its file, which carries metadata), with NaN
# normalised to NA, so identical values give identical keys whether they came
# from a file or from memory.
wet_raster_md5 <- function(r) {
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  v <- as.vector(terra::values(r, mat = FALSE))
  v[is.na(v)] <- NA_real_  # a FLT4S file reads NA back as NaN; hash them alike
  writeBin(v, f)
  unname(tools::md5sum(f))
}

# Full-precision identity of a raster grid: extent, dims and CRS. Hashed, so
# a filename never carries a rounded extent that two grids could share.
wet_grid_key <- function(r) {
  wet_md5_text(paste(c(sprintf("%.17g", c(as.vector(terra::ext(r)), terra::nrow(r), terra::ncol(r))),
                       terra::crs(r, proj = TRUE)), collapse = "|"))
}
