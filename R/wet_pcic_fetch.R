#' Download a PCIC VIC-GL subset over OPeNDAP
#'
#' Requests `VAR[t0:t1][lat0:lat1][lon0:lon1]` as NetCDF and caches it. The
#' file is checked for a NetCDF signature before it is kept: an HTTP error or
#' redirect page saved under a `.nc` name is exactly how a download goes wrong
#' silently (PCIC moved hosts in 2026 and `curl` without `-L` saves the 301
#' body).
#'
#' @inheritParams wet_pcic_url
#' @inheritParams wet_pcic_index
#' @param dir Cache directory.
#' @param overwrite Logical. Re-download even when the cached file exists.
#' @param timeout Seconds allowed for the download.
#' @return Path to the NetCDF file.
#' @export
wet_pcic_fetch <- function(variable, bbox, start, end,
                           run = "TPS_gridded_obs_init", dir = "data/pcic",
                           overwrite = FALSE, timeout = 3600) {
  ix <- wet_pcic_index(bbox, start, end)
  constraint <- sprintf("%s[%d:%d][%d:%d][%d:%d]", variable,
                        ix$time[1], ix$time[2], ix$lat[1], ix$lat[2],
                        ix$lon[1], ix$lon[2])
  url <- paste0(wet_pcic_url(variable, run), ".nc?",
                utils::URLencode(constraint, reserved = TRUE))
  dest <- file.path(dir, sprintf("%s_%s_t%d-%d_y%d-%d_x%d-%d.nc", run, variable,
                                 ix$time[1], ix$time[2], ix$lat[1], ix$lat[2],
                                 ix$lon[1], ix$lon[2]))
  if (file.exists(dest) && !overwrite) return(dest)

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(fileext = ".nc", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  old <- options(timeout = max(timeout, getOption("timeout")))
  on.exit(options(old), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE, method = "libcurl")
  if (!wet_is_netcdf(tmp)) {
    stop("download from ", url, " is not NetCDF (",
         file.size(tmp), " bytes); check the URL and the PCIC service",
         call. = FALSE)
  }
  if (!file.rename(tmp, dest)) stop("could not move download to ", dest, call. = FALSE)
  dest
}

# NetCDF classic/64-bit ("CDF\001", "CDF\002", "CDF\005") or NetCDF-4/HDF5.
wet_is_netcdf <- function(path) {
  if (!file.exists(path) || file.size(path) < 8) return(FALSE)
  magic <- readBin(path, "raw", n = 8L)
  identical(magic[1:3], charToRaw("CDF")) ||
    identical(magic, as.raw(c(0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a)))
}
