#' Download a PCIC VIC-GL subset over OPeNDAP
#'
#' Requests `VAR[t0:t1][lat0:lat1][lon0:lon1]` as NetCDF and caches it. The
#' download reads its HTTP status: a 429 or 503 (the server asking for less)
#' waits for `Retry-After`, or 60 s doubling when none is given, and tries
#' again, five tries in all; any other status but 200 stops. A 200 is checked
#' for a NetCDF signature, and its days must be exactly `start` to `end`, before
#' it is kept: an HTML page saved under a `.nc` name, or a file on another
#' calendar, is exactly how a download goes wrong silently. A file already in
#' the cache is returned as it is, unread. Requests carry the user agent `wet`.
#'
#' A function set as option `wet.pcic_request_log`, taking `(url, status,
#' bytes, secs)`, is called after every request this makes, a retry or a
#' refused one included (`status` 0 where curl itself failed), so a caller can
#' keep a record of each request.
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
  tries <- 5L
  for (k in seq_len(tries)) {
    unlink(tmp)
    t0 <- Sys.time()
    res <- tryCatch(wet_http_disk(url, tmp, timeout), error = function(e) {
      wet_request_log(url, 0L, tmp, t0)
      stop(e)
    })
    wet_request_log(url, res$status, tmp, t0)
    if (!res$status %in% c(429L, 503L)) break
    if (k == tries) {
      stop("PCIC answered HTTP ", res$status, " on ", tries, " tries for ", url,
           call. = FALSE)
    }
    wait <- res$retry_after
    wet_wait(if (is.na(wait)) 60 * 2^(k - 1L) else wait)
  }
  if (res$status != 200L) {
    stop("PCIC answered HTTP ", res$status, " for ", url, call. = FALSE)
  }
  if (!wet_is_netcdf(tmp)) {
    stop("download from ", url, " is not NetCDF (",
         file.size(tmp), " bytes); check the URL and the PCIC service",
         call. = FALSE)
  }
  asked <- seq(as.Date(start), as.Date(end), by = "day")
  got <- tryCatch(as.Date(terra::time(terra::rast(tmp))), error = function(e) NULL)
  if (is.null(got) || !identical(as.numeric(got), as.numeric(asked))) {
    stop("download from ", url, " holds other days than ", start, " to ", end,
         " (", length(got), " days read, ", length(asked), " asked); not cached",
         call. = FALSE)
  }
  if (!file.rename(tmp, dest)) stop("could not move download to ", dest, call. = FALSE)
  dest
}

# One GET to a file, returning the HTTP status and any Retry-After in seconds.
# The one network call tests mock.
wet_http_disk <- function(url, path, timeout) {
  h <- curl::new_handle(useragent = "wet", followlocation = TRUE,
                        timeout = timeout, failonerror = FALSE)
  res <- curl::curl_fetch_disk(url, path, handle = h)
  hdr <- curl::parse_headers_list(res$headers)
  ra <- suppressWarnings(as.numeric(hdr[["retry-after"]]))
  list(status = as.integer(res$status_code),
       retry_after = if (length(ra) == 1L && is.finite(ra) && ra >= 0) ra else NA_real_)
}

wet_wait <- function(seconds) Sys.sleep(seconds)

# Calls option wet.pcic_request_log, when it is a function, with one request's outcome.
wet_request_log <- function(url, status, path, t0) {
  f <- getOption("wet.pcic_request_log")
  if (is.function(f)) {
    f(url, as.integer(status), if (file.exists(path)) file.size(path) else 0,
      as.numeric(Sys.time() - t0, units = "secs"))
  }
  invisible()
}

# NetCDF classic/64-bit ("CDF\001", "CDF\002", "CDF\005") or NetCDF-4/HDF5.
wet_is_netcdf <- function(path) {
  if (!file.exists(path) || file.size(path) < 8) return(FALSE)
  magic <- readBin(path, "raw", n = 8L)
  identical(magic[1:3], charToRaw("CDF")) ||
    identical(magic, as.raw(c(0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a)))
}
