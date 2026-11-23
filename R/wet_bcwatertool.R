# The BC Water Tool's third-party gauges, one pinned snapshot per machine (#144, #195).
#
# The BC Water Tool (Foundry Spatial, for the province) serves a station list,
# https://nr-bcwat.bcwatertool.ca/api/streamflow/stations (GeoJSON), and one
# CSV of daily values per station,
# https://nr-bcwat.bcwatertool.ca/api/streamflow/stations/<id>/csv, where <id>
# is the list's numeric `id`. Beside Water Survey of Canada's and the
# province's own stations it holds the records of third-party networks
# (regional districts, industry, BC Hydro, the Regulator, research projects).
# The survey (scripts/station_sources_probe.R, #123) fetched the list and every
# listing with a record on 2026-10-28; its report records the md5 of the list
# and of the md5 list over the 391 per-station entries (389 CSVs and 2 .status
# files for listings that answered HTTP 500).
#
# The Tool serves only its current values, so each snapshot wet reads is pinned
# by a tracked manifest, inst/extdata/station_sources/bcwatertool_<snapshot>.csv
# (file, bytes, md5: the list and every entry), and lives in wet's cache,
# <cache_dir>/station_sources/bcwatertool/<snapshot>/, one copy shared by every
# checkout. data-raw/station_sources_bcwatertool.R seeds the cache, writes the
# manifest and the station registry, and backs the snapshot up privately at
# s3://fresh-bc/station_sources/bcwatertool/<snapshot>/. wet never downloads a
# pinned snapshot: a file missing from the cache is copied in by hand from that
# backup. Outside NGE, the same URLs give a snapshot of one's own, which the
# manifest's md5s tell apart from the pinned one (research/station_sources.md).
#
# The station registry, inst/extdata/station_sources/bcwatertool_<snapshot>_hydat.csv,
# names the listings wet reads: the third-party listings with discharge, by
# the rule in that script. Most are stations of their own, under the Tool's
# `nid`; a listing at a provincial station's site instead continues that
# station's record (`continues`, the provincial number), and only its days
# before the provincial station's first day are read, under the provincial
# number (wet_station_daily()).

# The snapshot the package reads: the survey's (#123), 2026-10-28.
wet_bcwatertool_snapshot <- "20261028"

# The Tool's station list in a snapshot.
wet_bcwatertool_list_file <- function(snapshot) sprintf("bcwatertool_streamflow_stations_%s.geojson", snapshot)

# Paths in the cache to the CSVs of the listings `ids` (the Tool's numeric ids,
# as character), each checked against the manifest; NA for a listing the
# snapshot holds only as a .status file (an HTTP error when it was fetched).
wet_bcwatertool <- function(ids, snapshot = wet_bcwatertool_snapshot,
                            cache_dir = tools::R_user_dir("wet", "cache")) {
  man <- wet_bcwatertool_manifest(snapshot)
  if (!is.character(ids) || anyNA(ids)) stop("`ids` must be the Tool's station ids, as character", call. = FALSE)
  csv <- paste0(ids, ".csv")
  status <- paste0(csv, ".status")
  unknown <- ids[!csv %in% man$file & !status %in% man$file]
  if (length(unknown)) {
    stop("the Water Tool snapshot ", snapshot, " holds no listing ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  dir <- file.path(cache_dir, "station_sources", "bcwatertool", snapshot)
  file <- ifelse(csv %in% man$file, csv, status)
  f <- file.path(dir, file)
  missing <- unique(file[!file.exists(f)])
  if (length(missing)) {
    wet_bcwatertool_unavailable(
      "the Water Tool snapshot ", snapshot, " lacks ", paste(missing, collapse = ", "), " in ", dir,
      "; copy each from the backup at s3://fresh-bc/station_sources/bcwatertool/", snapshot,
      "/ (its md5s are in the tracked manifest), or run data-raw/station_sources_bcwatertool.R where the ",
      "survey's raw copy is")
  }
  k <- match(file, man$file)
  for (i in unique(k)) wet_bcenv_check(file.path(dir, man$file[i]), man$bytes[i], man$md5[i])
  ifelse(csv %in% man$file, f, NA_character_)
}

# The tracked manifest of a pinned Tool snapshot: the station list and one row
# per listing, a <id>.csv or <id>.csv.status.
wet_bcwatertool_manifest <- function(snapshot) {
  path <- wet_bcwatertool_manifest_path(snapshot)
  man <- utils::read.csv(path, colClasses = c(file = "character", bytes = "numeric", md5 = "character"))
  ok <- grepl("^[0-9]+[.]csv([.]status)?$", man$file) | man$file == wet_bcwatertool_list_file(snapshot)
  if (!identical(names(man), c("file", "bytes", "md5")) || !nrow(man) || anyNA(man) || anyDuplicated(man$file) ||
      !all(ok) || !wet_bcwatertool_list_file(snapshot) %in% man$file ||
      anyDuplicated(sub("[.]csv([.]status)?$", "", man$file))) {
    stop("the manifest ", path, " is not the station list and one row per listing (<id>.csv or <id>.csv.status) ",
         "with its bytes and md5", call. = FALSE)
  }
  man
}

wet_bcwatertool_manifest_path <- function(snapshot) {
  if (!is.character(snapshot) || length(snapshot) != 1L || is.na(snapshot) || !grepl("^[0-9]{8}$", snapshot)) {
    stop("`snapshot` must be one snapshot date as YYYYMMDD", call. = FALSE)
  }
  path <- system.file("extdata", "station_sources", sprintf("bcwatertool_%s.csv", snapshot), package = "wet")
  if (!nzchar(path)) {
    stop("no tracked manifest for the Water Tool snapshot ", snapshot,
         " (inst/extdata/station_sources/bcwatertool_", snapshot, ".csv)", call. = FALSE)
  }
  path
}

# The station registry of a Tool snapshot, written with it by
# data-raw/station_sources_bcwatertool.R and shipped with the package.
wet_bcwatertool_stations <- function(snapshot = wet_bcwatertool_snapshot) {
  wet_bcwatertool_manifest(snapshot)  # validates the snapshot and that it is pinned
  path <- system.file("extdata", "station_sources", sprintf("bcwatertool_%s_hydat.csv", snapshot), package = "wet")
  if (!nzchar(path)) stop("no station registry for the Water Tool snapshot ", snapshot, call. = FALSE)
  s <- utils::read.csv(path, na.strings = "", encoding = "UTF-8", colClasses = c(
    station_number = "character", id = "character", name = "character", network = "character", lon = "numeric",
    lat = "numeric", subdrainage = "character", nearest_hydat = "character", nearest_km = "numeric",
    first = "Date", last = "Date", regulation = "character", hydat_site = "character", hydat_km = "numeric",
    credit = "character", continues = "character"))
  if (anyDuplicated(s$station_number) || anyNA(s$station_number) || anyDuplicated(s$id) || anyNA(s$id) ||
      anyNA(s$subdrainage) || any(grepl(wet_hydat_number, s$station_number))) {
    stop("the station registry ", path, " does not hold one row per listing, each with its id and sub-drainage ",
         "and a number not shaped like HYDAT's", call. = FALSE)
  }
  s[order(s$station_number, method = "radix"), ]
}

# Daily flow at the Tool listings named by registry number (`stations`), in
# wet_station_daily()'s shape, `source` "bcwatertool", under the shipped rules:
# - one row is one day (the CSVs' Datetime is a date: the survey matched the
#   Tool's copy of the provincial stations to the province's UTC days, so a
#   Tool day may be a UTC day rather than a local-standard-time one);
# - QA 1 ("Quality Checked") is "provisional", QA 0 ("Unchecked Quality")
#   "unchecked": none is "approved";
# - a negative day is dropped, and a day above the plausibility bound
#   (research/station_sources.md): the bound of the listing's sub-drainage,
#   recorded in the registry from the nearest HYDAT station, times the median
#   of the listing's positive daily flows over its whole pinned record.
# The registry number is returned as given; wet_station_daily() renames a
# continuing listing's days to its provincial number and cuts them.
wet_bcwatertool_daily <- function(stations, snapshot = wet_bcwatertool_snapshot, bound = wet_bcenv_bound,
                                  cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.character(stations) || anyNA(stations)) {
    stop("`stations` must be a character vector of Water Tool registry numbers", call. = FALSE)
  }
  reg <- wet_bcwatertool_stations(snapshot)
  unknown <- setdiff(stations, reg$station_number)
  if (length(unknown)) {
    stop("not in the Water Tool's station registry: ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  reg <- reg[reg$station_number %in% stations, ]
  if (!nrow(reg)) return(wet_daily_empty())
  d <- wet_bcwatertool_days(reg$id, snapshot, cache_dir)
  d$station_number <- reg$station_number[match(d$id, reg$id)]
  wet_bcwatertool_shape(d, stats::setNames(reg$subdrainage, reg$station_number), bound)
}

# The shipped rules on the parsed days `d` (station_number, date, q_m3s, qa),
# each station's ratio bound from its sub-drainage `sub` (named by station).
# data-raw/station_sources_bcwatertool.R applies the same function when it
# records the registry's first and last days.
wet_bcwatertool_shape <- function(d, sub, bound) {
  if (!is.numeric(bound) || !length(bound) || anyNA(bound) || any(bound <= 0) ||
      (is.null(names(bound)) && length(bound) != 1L) || (!is.null(names(bound)) && !".default" %in% names(bound))) {
    stop("`bound` must be one positive number (Inf for none), or positive numbers named by WSC sub-drainage ",
         "with a \".default\"", call. = FALSE)
  }
  d <- d[d$q_m3s >= 0, ]
  if (!nrow(d)) return(wet_daily_empty())
  cap <- wet_bcenv_cap(d$station_number, d$q_m3s, bound, sub = unname(sub[d$station_number]))
  d <- d[is.na(cap) | d$q_m3s <= cap, ]
  if (!nrow(d)) return(wet_daily_empty())
  d <- d[order(d$station_number, d$date, method = "radix"), ]
  data.frame(station_number = d$station_number, date = d$date, q_m3s = d$q_m3s, symbol = NA_character_,
             source = "bcwatertool", status = ifelse(d$qa == "1", "provisional", "unchecked"))
}

# Every discharge day the CSVs of listings `ids` hold, with no rule applied:
# data.frame(id, date, q_m3s, qa), qa as written ("0" or "1"). The survey's
# reading (scripts/station_sources_harvest.R reproduces it through this). A
# listing held only as a .status file has no days.
wet_bcwatertool_days <- function(ids, snapshot = wet_bcwatertool_snapshot,
                                 cache_dir = tools::R_user_dir("wet", "cache")) {
  paths <- wet_bcwatertool(ids, snapshot, cache_dir)
  d <- lapply(seq_along(ids), function(i) if (!is.na(paths[i])) wet_bcwatertool_read(paths[i], ids[i])$q)
  d <- do.call(rbind, c(list(data.frame(id = character(), date = as.Date(character()), q_m3s = numeric(),
                                        qa = character())), d))
  rownames(d) <- NULL
  d
}

# One Tool CSV: a block of "# key,value" lines (the licence, name, network,
# QA legend and others), then a table Analysis,Datetime,Value,Units,QA. Returns
# list(meta = named character of the header fields, q = the
# "Preliminary Discharge" rows as data.frame(id, date, q_m3s, qa)). A blank
# value is no value, as the survey read it; a value that is not a finite
# number, a unit other than m3/s, a QA other than 0 or 1, a date not written
# YYYY-MM-DD or two values for one day are refused, not read.
wet_bcwatertool_read <- function(path, id) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  head <- grep("^# ", lines, value = TRUE)
  key <- sub("^# ([^,]*),.*$", "\\1", head)
  meta <- stats::setNames(gsub('^"|"$', "", sub("^# [^,]*,", "", head)), key)
  meta <- meta[!duplicated(key)]
  body <- lines[!grepl("^#", lines) & nzchar(lines)]
  empty <- data.frame(id = character(), date = as.Date(character()), q_m3s = numeric(), qa = character())
  if (!length(body)) return(list(meta = meta, q = empty))
  if (!identical(body[1], "Analysis,Datetime,Value,Units,QA")) {
    stop(path, " is not a Water Tool CSV: its table header is not Analysis,Datetime,Value,Units,QA", call. = FALSE)
  }
  if (length(body) == 1) return(list(meta = meta, q = empty))
  x <- utils::read.csv(text = body, quote = "", colClasses = "character", na.strings = character())
  x <- x[x$Analysis == "Preliminary Discharge" & !x$Value %in% c("", "NA"), ]
  if (!nrow(x)) return(list(meta = meta, q = empty))
  v <- suppressWarnings(as.numeric(x$Value))
  bad <- function(what, i) stop(path, ": ", what, ", such as \"", i[1], "\"", call. = FALSE)
  if (any(!is.finite(v))) bad("a discharge value is not a finite number", x$Value[!is.finite(v)])
  if (any(x$Units != "m3/s")) bad("a discharge value's unit is not m3/s", x$Units[x$Units != "m3/s"])
  if (any(!x$QA %in% c("0", "1"))) bad("a discharge value's QA is not 0 or 1", x$QA[!x$QA %in% c("0", "1")])
  date <- as.Date(x$Datetime, optional = TRUE)
  wrong <- is.na(date) | !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x$Datetime)
  if (any(wrong)) bad("a discharge day is not a date written YYYY-MM-DD", x$Datetime[wrong])
  if (anyDuplicated(date)) bad("two discharge values for one day", x$Datetime[duplicated(date)])
  list(meta = meta, q = data.frame(id = id, date = date, q_m3s = v, qa = x$QA))
}

# The credit a listing's CSV header asks for: its "Data Licence Information"
# up to the liability disclaimer that starts "Any reliance".
wet_bcwatertool_credit <- function(meta) {
  x <- meta[["Data Licence Information"]]
  if (is.null(x) || is.na(x)) return(NA_character_)
  trimws(sub("\\s*Any reliance.*$", "", x))
}

wet_bcwatertool_unavailable <- function(...) wet_snapshot_unavailable("wet_bcwatertool_unavailable", ...)
