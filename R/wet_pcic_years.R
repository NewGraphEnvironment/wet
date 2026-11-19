# PCIC's per-year sub-basin days (fwapg#42), one cache per machine (#135).
#
# fwapg publishes one parquet file per year and series,
# pcic.subbasin_days.<model>_<scenario>.<year>.parquet, on the public fresh-bc
# bucket under fwapg/extras/. A run that needs them reads the directory
# WET_PCIC_YEARS names; unset, it reads wet's cache,
# <cache_dir>/pcic_years/<model>_<scenario>/, one copy shared by every
# checkout, and any year the cache lacks is downloaded first. A file lands
# under its year's name only once its size is the byte count the caller read
# from fwapg's catalogue (pcic.series), so a cut-off download never looks
# whole. The caller still holds every file to its catalogue row: the cache
# saves the download, not the check. A directory WET_PCIC_YEARS names is the
# user's, read and never written. Internal: the callers are the scripts that
# read pcic.series.
#
# Returns the directory.
wet_pcic_years <- function(years, bytes, series = "PNWNAmet_historical",
                           cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.numeric(years) || !length(years) || anyNA(years) || any(years != round(years))) {
    stop("`years` must be whole years", call. = FALSE)
  }
  if (anyDuplicated(years)) stop("`years` must be distinct years", call. = FALSE)
  if (!is.numeric(bytes) || length(bytes) != length(years) || anyNA(bytes) || any(bytes <= 0)) {
    stop("`bytes` must hold one byte count per year, from pcic.series", call. = FALSE)
  }
  if (!is.character(series) || length(series) != 1L || !grepl("^[A-Za-z0-9-]+_[A-Za-z0-9-]+$", series)) {
    stop("`series` must be one <model>_<scenario>, such as \"PNWNAmet_historical\"", call. = FALSE)
  }
  own <- Sys.getenv("WET_PCIC_YEARS")
  if (nzchar(own)) return(own)
  dir <- file.path(cache_dir, "pcic_years", series)
  files <- file.path(dir, wet_pcic_years_file(series, years))
  for (i in which(file.exists(files))) wet_pcic_years_size(files[i], bytes[i], "cached")
  todo <- which(!file.exists(files))
  if (length(todo)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    wet_pcic_years_stale(dir)
  }
  for (i in todo) wet_pcic_years_fetch(years[i], bytes[i], series, dir)
  dir
}

wet_pcic_years_file <- function(series, years) {
  sprintf("pcic.subbasin_days.%s.%d.parquet", series, as.integer(years))
}

wet_pcic_years_size <- function(f, bytes, what) {
  got <- file.size(f)
  if (!isTRUE(got == bytes)) {
    stop("the ", what, " ", f, " holds ", format(got, scientific = FALSE), " bytes, not the ",
         format(bytes, scientific = FALSE), " pcic.series names; delete it and run again", call. = FALSE)
  }
  invisible(f)
}

# partial files left by a run killed more than a day ago
wet_pcic_years_stale <- function(dir) {
  p <- list.files(dir, pattern = "[.]partial-", all.files = TRUE, full.names = TRUE)
  unlink(p[difftime(Sys.time(), file.mtime(p), units = "days") > 1])
}

# Download one year into a partial file of this call's own beside the cache
# entry, and move it into place only once its size is the catalogue's. Two
# runs fetching the same year at once each download; either copy is whole.
wet_pcic_years_fetch <- function(year, bytes, series, dir) {
  name <- wet_pcic_years_file(series, year)
  partial <- tempfile(paste0(".", name, ".partial-"), tmpdir = dir)
  on.exit(unlink(partial), add = TRUE)
  root <- getOption("wet.pcic_years_url", "https://fresh-bc.s3.us-west-2.amazonaws.com/fwapg/extras")
  url <- paste(sub("/+$", "", root), name, sep = "/")
  message("downloading ", name, " (", round(bytes / 2^20), " MB) into ", dir)
  wet_pcic_years_download(url, partial)
  tryCatch(wet_pcic_years_size(partial, bytes, "download of"),
           error = function(e) stop(name, ": ", conditionMessage(e), call. = FALSE))
  if (!file.rename(partial, file.path(dir, name))) stop("could not move ", name, " into ", dir, call. = FALSE)
  invisible(file.path(dir, name))
}

# The one call that reaches the bucket, kept apart so tests can stand it in.
# curl_download() fails on an HTTP error status.
wet_pcic_years_download <- function(url, dest) {
  curl::curl_download(url, dest, quiet = TRUE)
}
