#' Snow normals from cd's ERA5-Land annual snow layers
#'
#' Reads cd's annual snow layers (one band per year, ERA5-Land at 0.1 degree,
#' built by cd from the Earth Data Hub hourly store), takes the per-cell mean
#' over `years`, and resamples it bilinearly onto `grid`. The mean is
#' `cd::cd_baseline()`'s definition (the mean of the year values, `NA`
#' removed), taken per cell instead of over an area. Every year in `years` must
#' be a band of the file read.
#'
#' The defaults are the two predictors the monthly shares were scored with
#' (#16): `snowmelt_doy_50`, the calendar day of the year by which half the
#' year's snowmelt has happened, and `swe_max`, the year's peak snow water
#' equivalent (mm).
#'
#' ERA5-Land has no cell over the sea, so cells of `grid` whose own ERA5-Land
#' cell is empty come out `NA` (GDAL's bilinear reweights around missing
#' neighbours); they are left for the caller to fill.
#'
#' ERA5-Land's glacier points carry perennial snow: over 1981-2010, 513 BC
#' land cells have a mean `swe_max` of 5,000 to 10,000 mm, against a seasonal
#' maximum of about 3,000 mm elsewhere. `cap` limits each cell's mean before
#' resampling, so a glacier cell still reads as deep snow without dominating
#' an upstream mean (decided for #16 before any score was seen).
#'
#' @param grid Target grid: a `SpatRaster` or a path to one, in EPSG:4326.
#' @param vars cd variable names, each with an `"annual"` row in `catalog`.
#' @param years Years to average.
#' @param dir Cache directory.
#' @param catalog A `data.frame` with columns `variable`, `period` and `href`,
#'   as from `cd::cd_catalog()`; `NULL` reads cd's default catalog. A remote
#'   `href` is read through `cd::cd_cache_fetch()`.
#' @param cap Named numeric: an upper limit for the per-cell mean of each named
#'   variable, applied before resampling. Variables not named are not capped.
#' @param overwrite Logical. Rebuild the resampled grid even when cached.
#' @return Path to a GeoTIFF with one layer per variable, named as in `vars`.
#'   The cache key is the grid, `vars`, `years`, `cap`, the method version and
#'   the values of the bands read (not their files, which cd rebuilds with a
#'   new run time whenever it appends a year).
#' @export
#' @examplesIf interactive()
#' g <- terra::rast(xmin = -127, xmax = -126, ymin = 54, ymax = 55, res = 1 / 120)
#' sn <- terra::rast(wet_snow_normals(g, dir = tempdir()))
#' terra::global(sn, "mean", na.rm = TRUE)
wet_snow_normals <- function(grid, vars = c("snowmelt_doy_50", "swe_max"), years = 1981:2010,
                             dir = "data/snow", catalog = NULL, cap = c(swe_max = 3000), overwrite = FALSE) {
  grid <- if (inherits(grid, "SpatRaster")) grid[[1]] else terra::rast(grid)[[1]]
  if (is.null(catalog)) {
    if (!requireNamespace("cd", quietly = TRUE)) stop("catalog = NULL needs the cd package", call. = FALSE)
    catalog <- cd::cd_catalog()
  }
  if (!length(vars) || anyDuplicated(vars)) stop("vars must be distinct cd variable names", call. = FALSE)
  if (!length(years) || anyNA(years) || anyDuplicated(years)) stop("years must be distinct years", call. = FALSE)
  hrefs <- vapply(vars, function(v) {
    h <- catalog$href[catalog$variable %in% v & catalog$period %in% "annual"]
    if (length(h) != 1) stop("catalog has ", length(h), " annual rows for ", v, ", not 1", call. = FALSE)
    h
  }, "")
  files <- vapply(hrefs, function(h) {
    if (grepl("^https?://", h)) {
      if (!requireNamespace("cd", quietly = TRUE)) stop("a remote href needs the cd package", call. = FALSE)
      cd::cd_cache_fetch(h)
    } else {
      h
    }
  }, "")
  if (!all(file.exists(files))) stop("missing: ", paste(files[!file.exists(files)], collapse = ", "), call. = FALSE)
  if (length(cap) && (is.null(names(cap)) || !all(names(cap) %in% vars) || anyNA(cap))) {
    stop("cap must name variables in vars", call. = FALSE)
  }
  src <- lapply(seq_along(vars), function(i) {
    r <- terra::rast(files[[i]])
    if (!terra::same.crs(r, grid)) stop(vars[i], " is not in the grid's CRS", call. = FALSE)
    miss <- setdiff(as.character(years), names(r))
    if (length(miss)) {
      stop(vars[i], " has no band for ", length(miss), " of the years: ", paste(utils::head(miss, 5), collapse = ", "),
           call. = FALSE)
    }
    # a margin of two source cells, so bilinear at the grid's edge has neighbours
    terra::crop(r[[as.character(years)]], terra::extend(terra::ext(grid), 2 * terra::res(r)), snap = "out")
  })
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  key <- wet_md5_text(paste(c(wet_grid_key(grid), vars, years, names(cap), sprintf("%.17g", cap), wet_snow_method,
                              vapply(src, function(r) paste(wet_grid_key(r), wet_raster_md5(r)), "")),
                            collapse = "|"))
  dest <- file.path(dir, sprintf("snow_%d%d_%s.tif", min(years), max(years), substr(key, 1, 10)))
  if (file.exists(dest) && !overwrite) return(dest)
  out <- terra::rast(lapply(seq_along(vars), function(i) {
    m <- terra::mean(src[[i]], na.rm = TRUE)
    m <- terra::ifel(is.nan(m), NA, m)
    if (vars[i] %in% names(cap)) m <- terra::ifel(m > cap[[vars[i]]], cap[[vars[i]]], m)
    x <- terra::resample(m, grid, method = "bilinear")
    names(x) <- vars[i]
    x
  }))
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move the snow normals to ", dest, call. = FALSE)
  dest
}

# bump whenever wet_snow_normals() changes what it computes
wet_snow_method <- "year-mean-cap-bilinear-2"
