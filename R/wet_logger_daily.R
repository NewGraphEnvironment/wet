# Water temperature loggers on small streams (#235, #215).
#
# A logger series is a published package of one holder's logger records, pinned
# at one version by a tracked manifest, inst/extdata/temp_loggers/<series>_<version>.csv,
# with columns file, bytes, md5, url, fetch. A row whose `file` holds no "/" is a
# file the holder publishes, at `url`; a row "<zip>/<member>" is a member of that
# zip that wet reads, held to its own bytes and md5 once extracted, with no url.
# Files are kept in wet's cache, <cache_dir>/temp_loggers/<series>/<version>/.
# Where `fetch` is TRUE a missing file is fetched from its pinned URL and kept
# only at the manifest's md5 (a Zenodo record, whose files never change); where
# it is FALSE wet never requests it, and a missing file is copied in by hand from
# the private backup s3://fresh-bc/temp_loggers/<series>/<version>/.
#
# Each series' sites are listed in a registry, <series>_<version>_sites.csv,
# written with the pin by data-raw/temp_loggers_<series>.R. Its `station_number`
# is "<SERIES>_<holder's site code>", upper case, so it is never a HYDAT,
# provincial or Water Tool number; wet_temp_daily() sends an id in a registry to
# wet_logger_daily() and every other id to the ECCC archive.

# The series wet reads, each at its pinned version: a new series is its files
# plus one entry here.
wet_logger_versions <- c(nhg = "15053907")

wet_logger_path <- function(f) system.file("extdata", "temp_loggers", f, package = "wet")

wet_logger_cache <- function() tools::R_user_dir("wet", "cache")

# The tracked manifest of a series version, checked for shape: top-level files
# carry the URL of their own version and a fetch flag; members carry neither.
wet_logger_manifest <- function(series, version) {
  wet_logger_version_check(series, version)
  path <- wet_logger_path(sprintf("%s_%s.csv", series, version))
  if (!nzchar(path)) {
    stop("no tracked manifest for the logger series ", series, " ", version, " (inst/extdata/temp_loggers/", series,
         "_", version, ".csv)", call. = FALSE)
  }
  man <- utils::read.csv(path, na.strings = "", encoding = "UTF-8",
                         colClasses = c(file = "character", bytes = "numeric", md5 = "character",
                                        url = "character", fetch = "logical"))
  top <- !grepl("/", man$file, fixed = TRUE)
  zip <- sub("/.*$", "", man$file)
  ok <- identical(names(man), c("file", "bytes", "md5", "url", "fetch")) && nrow(man) > 0L &&
    !anyDuplicated(man$file) && !anyNA(man[c("file", "bytes", "md5")]) && all(grepl("^[0-9a-f]{32}$", man$md5)) &&
    all(!is.na(man$url[top]) & !is.na(man$fetch[top])) && all(is.na(man$url[!top]) & is.na(man$fetch[!top])) &&
    all(grepl(paste0("/records/", version, "/"), man$url[top], fixed = TRUE)) &&
    all(zip[!top] %in% man$file[top] & grepl("[.]zip$", zip[!top]))
  if (!ok) {
    stop("the manifest ", path, " is not a list of files with bytes, md5, the URL of record ", version,
         " and a fetch flag, and of zip members with bytes and md5", call. = FALSE)
  }
  man
}

wet_logger_version_check <- function(series, version) {
  if (!is.character(series) || length(series) != 1L || is.na(series) || !grepl("^[a-z]+$", series)) {
    stop("`series` must be one lower-case series code, such as \"nhg\"", call. = FALSE)
  }
  if (!is.character(version) || length(version) != 1L || is.na(version) || !grepl("^[0-9]+$", version)) {
    stop("`version` must be one record id, digits only", call. = FALSE)
  }
  invisible(TRUE)
}

wet_logger_unavailable <- function(...) wet_snapshot_unavailable("wet_logger_unavailable", ...)

# Paths in the cache to the pinned top-level `files` of a series version, each
# held to the manifest; a missing one is fetched only where `fetch` is TRUE.
wet_logger <- function(series, version, files, cache_dir = wet_logger_cache()) {
  man <- wet_logger_manifest(series, version)
  man <- man[!grepl("/", man$file, fixed = TRUE), ]
  miss <- setdiff(files, man$file)
  if (length(miss)) stop("not a file of ", series, " ", version, ": ", paste(miss, collapse = ", "), call. = FALSE)
  dir <- file.path(cache_dir, "temp_loggers", series, version)
  backup <- sprintf("s3://fresh-bc/temp_loggers/%s/%s/", series, version)
  vapply(files, function(fl) {
    m <- man[man$file == fl, ]
    f <- file.path(dir, fl)
    if (!file.exists(f)) {
      if (!isTRUE(m$fetch)) {
        wet_logger_unavailable(fl, " of ", series, " ", version, " is not in ", dir, "; wet does not fetch it: copy ",
                               "it in from ", backup)
      }
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      partial <- tempfile(paste0(".", fl, ".partial-"), tmpdir = dir)
      on.exit(unlink(partial), add = TRUE)
      message("fetching ", fl, " of ", series, " ", version, " (once per machine)")
      ok <- tryCatch({
        curl::curl_download(m$url, partial, quiet = TRUE, handle = curl::new_handle(useragent = "wet"))
        TRUE
      }, error = function(e) conditionMessage(e))
      if (!isTRUE(ok)) {
        wet_logger_unavailable("could not fetch ", m$url, ": ", ok, "; or copy ", fl, " into ", dir, " from ", backup)
      }
      wet_bcenv_check(partial, m$bytes, m$md5)
      if (!file.rename(partial, f) && !file.exists(f)) stop("could not move ", fl, " into ", dir, call. = FALSE)
    }
    wet_bcenv_check(f, m$bytes, m$md5)
    f
  }, "", USE.NAMES = FALSE)
}

# Members `members` ("<zip>/<member>", as the manifest lists them) of a series
# version, extracted into `exdir` and each held to the manifest. Paths in
# `members`' order.
wet_logger_members <- function(series, version, members, exdir = tempfile("wet_logger_"),
                               cache_dir = wet_logger_cache()) {
  man <- wet_logger_manifest(series, version)
  miss <- setdiff(members, man$file[grepl("/", man$file, fixed = TRUE)])
  if (length(miss)) {
    stop("not a listed member of ", series, " ", version, ": ", paste(miss, collapse = ", "), call. = FALSE)
  }
  zip <- sub("/.*$", "", members)
  inner <- sub("^[^/]*/", "", members)
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
  for (z in unique(zip)) {
    zf <- wet_logger(series, version, z, cache_dir)
    utils::unzip(zf, files = inner[zip == z], exdir = file.path(exdir, z), junkpaths = FALSE)
  }
  out <- file.path(exdir, zip, inner)
  for (i in seq_along(members)) {
    m <- man[man$file == members[i], ]
    wet_bcenv_check(out[i], m$bytes, m$md5)
  }
  out
}

# The site registry of a series version: one row per site, ids unique and of
# the series' own shape.
wet_logger_sites <- function(series, version = wet_logger_versions[[series]]) {
  wet_logger_manifest(series, version)
  path <- wet_logger_path(sprintf("%s_%s_sites.csv", series, version))
  if (!nzchar(path)) stop("no site registry for the logger series ", series, " ", version, call. = FALSE)
  cols <- c(station_number = "character", code = "character", record = "character", member = "character",
            name = "character", lon = "numeric", lat = "numeric", elevation_m = "numeric",
            clock_offset = "numeric", day_offset = "numeric", subdrainage = "character",
            nearest_hydat = "character", nearest_eccc = "character", eccc_km = "numeric",
            first_reading = "Date", last_reading = "Date", licence = "character", credit = "character",
            prior_record = "character", prior_code = "character", prior_member = "character")
  bad <- function() {
    stop("the site registry ", path, " does not hold one row per site, each id ", toupper(series),
         "_<the holder's code>, with its member, clock and day offsets and sub-drainage", call. = FALSE)
  }
  if (!identical(names(utils::read.csv(path, nrows = 0L, check.names = FALSE)), names(cols))) bad()
  s <- utils::read.csv(path, na.strings = "", encoding = "UTF-8", colClasses = cols)
  want <- paste0("^", toupper(series), "_[0-9A-Z]+$")
  ok <- nrow(s) > 0L && !anyDuplicated(s$station_number) &&
    all(grepl(want, s$station_number)) && identical(s$station_number, paste0(toupper(series), "_", toupper(s$code))) &&
    !anyNA(s[c("member", "clock_offset", "day_offset", "subdrainage")]) && all(s$record == version) &&
    all(grepl("^[0-9]{2}[A-Z]$", s$subdrainage))
  if (!ok) bad()
  s[order(s$station_number, method = "radix"), ]
}
