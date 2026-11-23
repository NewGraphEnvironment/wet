# The province's non-integrated hydrometric discharge files, one pinned
# snapshot per machine (#142).
#
# The province publishes its non-integrated stations' hourly discharge as
# Discharge.csv (the latest months) beside archive files that each cover a
# period, under https://www.env.gov.bc.ca/wsd/data_searches/water/ (Open
# Government Licence - British Columbia). Discharge.csv is rewritten in place,
# so a snapshot cannot be fetched again as it was: each snapshot wet reads is
# pinned by a tracked manifest, inst/extdata/station_sources/bcenv_<snapshot>.csv
# (file, bytes, md5), and lives in wet's cache,
# <cache_dir>/station_sources/bcenv/<snapshot>/, one copy shared by every
# checkout. data-raw/station_sources_snapshot.R seeds the cache and writes the
# manifest; a private backup of each pinned snapshot sits at
# s3://fresh-bc/station_sources/bcenv/<snapshot>/. wet never downloads a pinned
# snapshot from the province, and a file missing from the cache is copied in
# by hand from the backup. Internal, because that backup is not reachable
# outside NGE.
#
# Returns the snapshot's file paths, newest first: an hour two files both hold
# is taken from the newer.
wet_bcenv <- function(snapshot = wet_bcenv_snapshot, cache_dir = tools::R_user_dir("wet", "cache")) {
  man <- wet_bcenv_manifest(snapshot)
  dir <- file.path(cache_dir, "station_sources", "bcenv", snapshot)
  f <- file.path(dir, man$file)
  missing <- !file.exists(f)
  if (any(missing)) {
    wet_bcenv_unavailable(
      "the provincial discharge snapshot ", snapshot, " lacks ", paste(man$file[missing], collapse = ", "),
      " in ", dir, "; copy each from the backup at s3://fresh-bc/station_sources/bcenv/", snapshot,
      "/ (its md5s are in the tracked manifest), or run data-raw/station_sources_snapshot.R where the ",
      "survey's raw copy is")
  }
  for (i in seq_along(f)) wet_bcenv_check(f[i], man$bytes[i], man$md5[i])
  f[wet_bcenv_order(man$file)]
}

# The snapshot the package reads by default: the survey's (#123), 2026-10-28.
wet_bcenv_snapshot <- "20261028"

# The tracked manifest of a pinned snapshot. A snapshot without one is refused:
# only a tracked md5 says a cached copy is the one the results were made from.
wet_bcenv_manifest <- function(snapshot) {
  if (!is.character(snapshot) || length(snapshot) != 1L || is.na(snapshot) || !grepl("^[0-9]{8}$", snapshot)) {
    stop("`snapshot` must be one snapshot date as YYYYMMDD", call. = FALSE)
  }
  path <- system.file("extdata", "station_sources", sprintf("bcenv_%s.csv", snapshot), package = "wet")
  if (!nzchar(path)) {
    stop("no tracked manifest for the provincial discharge snapshot ", snapshot,
         " (inst/extdata/station_sources/bcenv_", snapshot, ".csv)", call. = FALSE)
  }
  man <- utils::read.csv(path, colClasses = c(file = "character", bytes = "numeric", md5 = "character"))
  if (!identical(names(man), c("file", "bytes", "md5")) || !nrow(man) || anyNA(man) ||
      anyDuplicated(man$file) || !all(grepl("^Discharge[A-Za-z0-9_]*[.]csv$", man$file))) {
    stop("the manifest ", path, " is not one row per Discharge*.csv file with its bytes and md5", call. = FALSE)
  }
  man
}

# A cached file must be the manifest's, byte for byte.
wet_bcenv_check <- function(f, bytes, md5) {
  if (!isTRUE(file.size(f) == bytes)) {
    stop(f, " holds ", format(file.size(f), scientific = FALSE), " bytes, not the manifest's ",
         format(bytes, scientific = FALSE), "; copy it again from the backup", call. = FALSE)
  }
  got <- unname(tools::md5sum(f))
  if (!identical(got, md5)) {
    stop(f, " has md5 ", got, ", not the manifest's ", md5, "; copy it again from the backup", call. = FALSE)
  }
  invisible(f)
}

# Files newest first, by the period each name gives: Discharge.csv is the
# latest months, Discharge_Archive_Post_<date> starts at its date,
# Discharge_Archive_<YYYYMon>_<YYYYMon> at its first month, and
# Discharge_Archive_Pre_<date> holds everything before its date. Read from the
# names, so a new snapshot with other archive files needs no code change; a
# name of another shape is refused rather than guessed.
wet_bcenv_order <- function(files) {
  start <- vapply(files, function(f) {
    if (f == "Discharge.csv") return(Inf)
    if (grepl("^Discharge_Archive_Pre_[0-9]{8}[.]csv$", f)) return(-Inf)
    m <- regmatches(f, regexec("^Discharge_Archive_Post_([0-9]{8})[.]csv$", f))[[1]]
    if (length(m)) return(as.numeric(as.Date(m[2], "%Y%m%d")))
    m <- regmatches(f, regexec("^Discharge_Archive_([0-9]{4})([A-Z][a-z]{2})_[0-9]{4}[A-Z][a-z]{2}[.]csv$", f))[[1]]
    if (length(m) && m[3] %in% month.abb) {
      return(as.numeric(as.Date(sprintf("%s-%02d-01", m[2], match(m[3], month.abb)))))
    }
    stop("cannot tell the period of the provincial file ", f, call. = FALSE)
  }, numeric(1))
  if (anyDuplicated(start)) stop("two provincial files start the same period", call. = FALSE)
  order(start, decreasing = TRUE)
}

# The snapshot cannot be had here, as opposed to a cache holding the wrong
# file: a classed error, so a live test can skip on this and on nothing else.
wet_bcenv_unavailable <- function(...) {
  stop(structure(class = c("wet_bcenv_unavailable", "error", "condition"),
                 list(message = paste0(...), call = NULL)))
}
