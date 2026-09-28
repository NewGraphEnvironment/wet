#' Annual AET and precipitation from the TerraClimate 1981-2010 climatology
#'
#' Downloads the TerraClimate monthly climatology files (Abatzoglou et al.
#' 2018, *Scientific Data* 5, 170191; CC0) for `period`, sums the 12 months
#' into annual totals, and resamples them bilinearly from TerraClimate's
#' 1/24-degree lattice onto `grid`. GDAL's bilinear reweights around missing
#' neighbours, so only cells whose own TerraClimate cell is empty (sea, and
#' some large lakes) come out `NA`; they are left for the caller to fill.
#'
#' TerraClimate's AET comes from a Thornthwaite-Mather soil-water balance on
#' its own precipitation, so it carries that precipitation's biases. Its
#' precipitation layer is returned alongside so they can be seen.
#'
#' The whole global file is downloaded (about 95 MB for AET, 147 MB for
#' precipitation), because the server's subset service returned empty bodies
#' when this was written (2026-09-27). The option `wet.terraclimate_url` only
#' sets where missing files are fetched from; the cache key is the md5 of the
#' files actually read.
#'
#' @param grid Target grid: a `SpatRaster` or a path to one, in EPSG:4326.
#' @param period Climatology period as in the file names: `"19812010"`,
#'   `"19611990"` or `"19912020"`.
#' @param vars TerraClimate variables to return, as annual totals.
#' @param dir Cache directory.
#' @param overwrite Logical. Rebuild the resampled grid even when cached.
#' @param timeout Seconds allowed for each download.
#' @return Path to a GeoTIFF with one layer per variable, named
#'   `<var>_tc` (mm per year).
#' @export
#' @examplesIf interactive()
#' g <- terra::rast(xmin = -120, xmax = -119, ymin = 49, ymax = 50, res = 1 / 120)
#' tc <- terra::rast(wet_terraclimate_aet(g))
#' terra::global(tc, "mean", na.rm = TRUE)
wet_terraclimate_aet <- function(grid, period = "19812010", vars = c("aet", "ppt"),
                                 dir = "data/terraclimate", overwrite = FALSE, timeout = 1800) {
  grid <- if (inherits(grid, "SpatRaster")) grid[[1]] else terra::rast(grid)[[1]]
  default_url <- "http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/climatology"
  base <- getOption("wet.terraclimate_url", default_url)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ncs <- file.path(dir, sprintf("TerraClimate_%s_%s.nc", period, vars))
  for (i in seq_along(ncs)) {
    if (!file.exists(ncs[i])) wet_download(paste0(base, "/", basename(ncs[i])), ncs[i], timeout)
  }
  # keyed on the grid, the source files' content and the method version (bump it
  # whenever wet_terraclimate_grid() changes what it computes)
  key <- wet_md5_text(paste(c(wet_grid_key(grid), vars, unname(tools::md5sum(ncs)), wet_terraclimate_method),
                            collapse = "|"))
  dest <- file.path(dir, sprintf("tc_%s_%s.tif", period, substr(key, 1, 10)))
  if (file.exists(dest) && !overwrite) return(dest)
  out <- wet_terraclimate_grid(ncs, vars, grid)
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move TerraClimate grid to ", dest, call. = FALSE)
  dest
}

wet_terraclimate_method <- "annual-sum-bilinear-2"

# Annual totals of each monthly file, resampled onto `grid`.
wet_terraclimate_grid <- function(ncs, vars, grid) {
  out <- lapply(seq_along(ncs), function(i) {
    r <- terra::rast(ncs[i])
    # the netCDF declares no CRS; TerraClimate is on a WGS 84 lon/lat lattice
    terra::crs(r) <- "EPSG:4326"
    if (terra::nlyr(r) != 12) stop(basename(ncs[i]), " has ", terra::nlyr(r), " layers, not 12", call. = FALSE)
    # a margin of two source cells, so bilinear at the grid's edge has neighbours
    r <- terra::crop(r, terra::extend(terra::ext(grid), 2 * terra::res(r)), snap = "out")
    yr <- sum(r)
    x <- terra::resample(yr, grid, method = "bilinear")
    names(x) <- paste0(vars[i], "_tc")
    x
  })
  terra::rast(out)
}
