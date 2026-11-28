# Hakai Institute's published discharge at seven Calvert and Hecate island
# watersheds, 2013-2019 (#192, #233).
#
# Hakai's data package (Korver, Haughton, Floyd and Giesbrecht, "High-resolution
# hydrometeorological data from seven small coastal watersheds, British
# Columbia, Canada, 2013-2019", DOI 10.21966/J99C-9C14; CC-BY 4.0) lives in
# the GitHub repository HakaiInstitute/essd2021-hydromet-datapackage, its data
# files in Git LFS. wet reads one file of it, 2013-2019_Discharge_Hourly.csv,
# pinned at one commit by a tracked manifest,
# inst/extdata/station_sources/hakai_<version>.csv (file, bytes, md5, url),
# and kept in wet's cache, <cache_dir>/station_sources/hakai/<version>/. A
# published package does not change, so unlike the province's and the Water
# Tool's snapshots a missing file is fetched from its pinned URL (the LFS media
# host, which serves no robots.txt) and kept only at the manifest's md5; it is
# also backed up privately at s3://fresh-bc/station_sources/hakai/<version>/.
#
# Three of the package's watersheds, 626, 703 and 844, are provincial stations
# H08KC0626, H08KC0703 and H08KC0844, whose provincial records begin on
# 2021-10-01. The registry, inst/extdata/station_sources/hakai_<version>_hydat.csv,
# written with the pin by data-raw/station_sources_hakai.R, names them: such a
# row continues a provincial station (`continues`), and only its days before
# `continues_before`, the first day the provincial files hold any usable hour
# of that station, are read, under the provincial number, as the Water Tool's
# continuing listings are. The other four, 693, 708, 819 and 1015, continue no
# provincial station: each is a station of its own under the package's number
# (WTS693, ...), with no `continues` and no `continues_before`. The rules
# (registered in research/station_sources.md, "The Hakai package in wet",
# before any day was counted; the own stations' amendment before theirs):
# - a row's Datetime is the end of its hour in Pacific Standard Time, as the
#   package states, though the file writes a trailing "Z";
# - a day is a PST day: the hours labelled d 01:00 to d+1 00:00; it needs at
#   least 20 hours, and its flow is their mean (Qrate, m^3/s);
# - the first-tier flag is the upper-case codes at the head of Qflag; an hour
#   flagged SVD is dropped; a code outside wet_hakai_codes is refused;
# - an hour whose Qrate is "NA" carries no value and is dropped;
# - a day whose every hour is flagged AV alone at Qlevel 2 is "approved",
#   every other "provisional";
# - a negative day is dropped, and a day above wet_bcenv_bound["08K"] times
#   the median of the watershed's positive complete days.

# The package version wet reads: the repository commit, first 12 characters.
wet_hakai_version <- "8318556d2baf"

# Hakai's first-tier quality codes (the package README; Korver et al. 2022,
# section 3.2): accepted, estimated, suspicious value caution, suspicious
# value discard, missing value, and BR, which no document of the package
# defines and which appears only in mixed hours beside EV.
wet_hakai_codes <- c("AV", "EV", "SVC", "SVD", "MV", "BR")

# Path in the cache to the pinned discharge file, fetched on a miss and held to
# the manifest.
wet_hakai <- function(version = wet_hakai_version, cache_dir = tools::R_user_dir("wet", "cache")) {
  man <- wet_hakai_manifest(version)
  dir <- file.path(cache_dir, "station_sources", "hakai", version)
  f <- file.path(dir, man$file)
  if (!file.exists(f)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    partial <- tempfile(paste0(".", man$file, ".partial-"), tmpdir = dir)
    on.exit(unlink(partial), add = TRUE)
    message("fetching Hakai's discharge package ", version, " (once per machine)")
    ok <- tryCatch({
      curl::curl_download(man$url, partial, quiet = TRUE)
      TRUE
    }, error = function(e) conditionMessage(e))
    if (!isTRUE(ok)) {
      wet_hakai_unavailable("could not fetch ", man$url, ": ", ok, "; or copy ", man$file, " into ", dir,
                            " from s3://fresh-bc/station_sources/hakai/", version, "/")
    }
    wet_bcenv_check(partial, man$bytes, man$md5)
    if (!file.rename(partial, f) && !file.exists(f)) stop("could not move ", man$file, " into ", dir, call. = FALSE)
  }
  wet_bcenv_check(f, man$bytes, man$md5)
  f
}

wet_hakai_unavailable <- function(...) wet_snapshot_unavailable("wet_hakai_unavailable", ...)

# The tracked manifest of a pinned package version: one row, the discharge file.
wet_hakai_manifest <- function(version) {
  if (!is.character(version) || length(version) != 1L || is.na(version) || !grepl("^[0-9a-f]{12}$", version)) {
    stop("`version` must be one package version, the first 12 characters of its commit", call. = FALSE)
  }
  path <- wet_station_sources_path(sprintf("hakai_%s.csv", version))
  if (!nzchar(path)) {
    stop("no tracked manifest for the Hakai package ", version, " (inst/extdata/station_sources/hakai_", version,
         ".csv)", call. = FALSE)
  }
  man <- utils::read.csv(path, colClasses = c(file = "character", bytes = "numeric", md5 = "character",
                                              url = "character"))
  ok <- identical(names(man), c("file", "bytes", "md5", "url")) && nrow(man) == 1L && !anyNA(man) &&
    grepl(paste0("/", version), man$url, fixed = TRUE)
  if (!ok) {
    stop("the manifest ", path, " is not one file with its bytes, md5 and the URL of its commit", call. = FALSE)
  }
  man
}

# The registry of a package version: one row per watershed wet reads, each
# continuing a provincial station or a station of its own (no `continues`,
# and then no `continues_before`).
wet_hakai_stations <- function(version = wet_hakai_version) {
  wet_hakai_manifest(version)
  path <- wet_station_sources_path(sprintf("hakai_%s_hydat.csv", version))
  if (!nzchar(path)) stop("no station registry for the Hakai package ", version, call. = FALSE)
  cols <- c(station_number = "character", watershed = "character", name = "character", lon = "numeric",
            lat = "numeric", continues = "character", continues_before = "Date", first = "Date", last = "Date",
            licence = "character", credit = "character", bcenv_snapshot = "character", bcenv_days = "character")
  s <- utils::read.csv(path, na.strings = "", encoding = "UTF-8", colClasses = cols)
  if (anyDuplicated(s$station_number) || anyNA(s$station_number)) {
    stop("the station registry ", path, " does not hold one row per watershed", call. = FALSE)
  }
  if (any(is.na(s$continues) & !is.na(s$continues_before))) {
    stop("the station registry ", path, " gives a row a cut only where it continues a provincial station",
         call. = FALSE)
  }
  s[order(s$station_number, method = "radix"), ]
}

# The days of registry numbers `stations` (Hakai's own, "WTS626"), under the
# rules above, in wet_station_daily()'s shape with source "hakai". The number is
# returned as given; wet_station_daily() renames and cuts.
wet_hakai_daily <- function(stations, version = wet_hakai_version, bound = wet_bcenv_bound, min_hours = 20L,
                            cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.character(stations) || anyNA(stations)) {
    stop("`stations` must be a character vector of Hakai registry numbers", call. = FALSE)
  }
  reg <- wet_hakai_stations(version)
  unknown <- setdiff(stations, reg$station_number)
  if (length(unknown)) stop("not in the Hakai registry: ", paste(unknown, collapse = ", "), call. = FALSE)
  if (!length(stations)) return(wet_daily_empty())
  h <- wet_hakai_hours(wet_hakai(version, cache_dir), stations)
  wet_hakai_shape(wet_hakai_days(h), bound, min_hours)
}

# The hourly rows of watersheds `stations` in the package file at `path`:
# data.frame(station_number, label, q_m3s, codes, level), `label` the hour's
# end as written (PST clock digits, read as UTC so no zone shifts them),
# `codes` its first-tier codes joined by "+". Hours flagged SVD, and hours
# whose Qrate is "NA" (no value), are dropped.
wet_hakai_hours <- function(path, stations) {
  x <- utils::read.csv(path, colClasses = "character", na.strings = character(), encoding = "UTF-8")
  want <- c("Watershed", "Datetime", "Qlevel", "Qflag", "Qrate")
  if (!all(want %in% names(x))) stop(path, " is not Hakai's hourly discharge file", call. = FALSE)
  x <- x[x$Watershed %in% stations, want]
  if (!nrow(x)) {
    return(data.frame(station_number = character(), label = as.POSIXct(character(), tz = "UTC"),
                      q_m3s = numeric(), codes = character(), level = character()))
  }
  bad <- function(what, v) stop(path, ": ", what, ", such as \"", v[1], "\"", call. = FALSE)
  label <- as.POSIXct(x$Datetime, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (anyNA(label) || any(format(label, "%M:%S") != "00:00")) {
    bad("a Datetime is not an hour written YYYY-MM-DDTHH:00:00Z", x$Datetime[is.na(label)])
  }
  head <- regmatches(x$Qflag, regexpr("^([A-Z]{2,3}:?)+", x$Qflag))
  has <- grepl("^([A-Z]{2,3}:?)+", x$Qflag)
  if (!all(has)) bad("an hour carries no quality code", x$Qflag[!has])
  codes <- lapply(strsplit(sub(":$", "", head), ":", fixed = TRUE), function(k) sort(unique(k), method = "radix"))
  unknown <- setdiff(unlist(codes), wet_hakai_codes)
  if (length(unknown)) bad("a quality code wet does not know", unknown)
  lv <- !x$Qlevel %in% c("1", "2", "3")
  if (any(lv)) bad("a Qlevel other than 1, 2 or 3", x$Qlevel[lv])
  none <- x$Qrate == "NA"
  q <- suppressWarnings(as.numeric(x$Qrate))
  q[none] <- NA_real_
  if (any(!is.finite(q) & !none)) bad("a Qrate that is not a finite number", x$Qrate[!is.finite(q) & !none])
  twice <- duplicated(data.frame(x$Watershed, label))
  if (any(twice)) bad("two rows for one hour", x$Datetime[twice])
  keep <- !vapply(codes, function(k) "SVD" %in% k, FALSE) & !none
  data.frame(station_number = x$Watershed, label = label, q_m3s = q,
             codes = vapply(codes, paste, "", collapse = "+"), level = x$Qlevel)[keep, ]
}

# PST days from hours: an hour ending at `label` belongs to the date an hour
# before it, so the day d holds the hours labelled d 01:00 to d+1 00:00.
# data.frame(station_number, date, q_m3s, hours, accepted), `accepted` TRUE
# where every hour is flagged AV alone at Qlevel 2.
wet_hakai_days <- function(h) {
  if (!nrow(h)) {
    return(data.frame(station_number = character(), date = as.Date(character()), q_m3s = numeric(),
                      hours = integer(), accepted = logical()))
  }
  date <- as.Date(h$label - 3600, tz = "UTC")
  key <- paste(h$station_number, as.numeric(date))
  g <- factor(key, unique(key))
  ok <- h$codes == "AV" & h$level == "2"
  data.frame(station_number = h$station_number[!duplicated(g)], date = date[!duplicated(g)],
             q_m3s = unname(tapply(h$q_m3s, g, mean)), hours = unname(as.integer(tapply(h$q_m3s, g, length))),
             accepted = unname(tapply(ok, g, all)))
}

# The shipped rules on days `d` (wet_hakai_days()'s shape): the hours rule, no
# negative day, the 08K bound, status.
wet_hakai_shape <- function(d, bound = wet_bcenv_bound, min_hours = 20L) {
  d <- d[d$hours >= min_hours & d$q_m3s >= 0, ]
  if (!nrow(d)) return(wet_daily_empty())
  cap <- wet_bcenv_cap(d$station_number, d$q_m3s, bound, sub = rep("08K", nrow(d)))
  d <- d[is.na(cap) | d$q_m3s <= cap, ]
  if (!nrow(d)) return(wet_daily_empty())
  d <- d[order(d$station_number, d$date, method = "radix"), ]
  data.frame(station_number = d$station_number, date = d$date, q_m3s = d$q_m3s, symbol = NA_character_,
             source = "hakai", status = ifelse(d$accepted, "approved", "provisional"))
}

# Hakai's days for the non-HYDAT numbers asked: an own station's under its
# number, and a continuing watershed's days before its provincial station's
# record begins, under the provincial number. `tool`
# is the Water Tool's registry when that source is read in the same call, so
# the registry check covers every registry the call opens.
wet_hakai_station_days <- function(stations, snapshot, tool = NULL) {
  reg <- wet_registry_against(wet_hakai_stations(), snapshot, "Hakai", "data-raw/station_sources_hakai.R")
  prov <- wet_bcenv_stations(snapshot)
  wet_registry_check(tool, prov, snapshot, hakai = reg)
  own <- reg$station_number[is.na(reg$continues) & reg$station_number %in% stations]
  cont <- wet_continuing(reg, stations, prov)
  if (!length(own) && !nrow(cont)) return(wet_daily_empty())
  wet_continue_days(wet_hakai_daily(c(own, cont$station_number)), cont)
}
