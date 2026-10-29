# Station sources beyond HYDAT: station lists, the HYDAT match and Chinook-window years (#123)
#
# Usage: WET_HYDAT_RELEASE=20260717 Rscript scripts/station_sources_probe.R
#
# For each source in research/station_sources.md that serves a machine-readable
# station list, this reads the list once, matches every station to HYDAT and,
# where the source serves daily discharge, counts the complete Chinook-window
# years each non-HYDAT station holds. It is a survey, not a harvester: what it
# reads is kept only under the gitignored data/station_sources/raw/, and
# nothing is published from it.
#
# ---- decided at the plan gate (user, 2026-10-28), pinned after plan review -------------------
#
# Windows: the CH migration (05-01..08-01) and spawning (08-01..09-15) rows of
#   inst/vignette-data/life_history_bulk.csv, as scripts/departure_pilot.R.
# A complete window-year is a row wet_window_stats() returns at its default
#   min_frac = 0.8. A source that serves no daily values gets its listed
#   period of record instead, a proxy the report marks as such.
# The HYDAT match is against every row of HYDAT's STATIONS (any province, any
#   data type, active or discontinued): first by WSC station number where the
#   source stores one, then within 1 km with the same normalised stream name.
#   Near misses (within 1 km with another name, or the same name at 1-3 km)
#   are listed for a hand check. A matched station whose record extends past
#   HYDAT's at that site counts as "same site, new years", not a duplicate.
# Snapshots: each fetch is written to data/station_sources/raw/ and read from
#   there on every later run, so a rerun on the same snapshots reproduces the
#   report byte for byte; delete a snapshot to fetch it again. The report
#   names each snapshot's md5 and fetch date, and carries no timestamp.
#
# ---- what it refuses -------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()

release <- wb_release()
if (release != "20260717") stop("the survey names HYDAT 20260717, not ", release, call. = FALSE)
# the script this run executes, hashed before anything else can change it
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, not through source(), so the script's own md5 can be recorded", call. = FALSE)
}
code_md5 <- unname(tools::md5sum(self))
if (is.na(code_md5)) stop("cannot read the running script at ", self, " to record its md5", call. = FALSE)
hydat <- wb_hydat(release)
report <- file.path("data", "checks", sprintf("station_sources_%s.txt", release))
raw_dir <- file.path("data", "station_sources", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$window, c("migration", "spawning")),
          identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))
min_years <- 3
match_km <- 1
near_km <- 3

out <- character()
say <- function(...) out <<- c(out, ...)
`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- HYDAT: every station, with its discharge period ------------------------------------------
con <- wet:::wet_hydat_connect(hydat)
hy <- DBI::dbGetQuery(con, "
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.PROV_TERR_STATE_LOC prov,
         s.HYD_STATUS status, s.LONGITUDE lon, s.LATITUDE lat,
         q.YEAR_FROM q_from, q.YEAR_TO q_to
  FROM STATIONS s
  LEFT JOIN (SELECT STATION_NUMBER, YEAR_FROM, YEAR_TO FROM STN_DATA_RANGE WHERE DATA_TYPE = 'Q') q
    USING (STATION_NUMBER)
  ORDER BY s.STATION_NUMBER")
DBI::dbDisconnect(con)
stopifnot(!anyDuplicated(hy$station_number))
hy <- hy[!is.na(hy$lon) & !is.na(hy$lat), ]

# the stream a gauge sits on, from its name: "MAXAN CREEK ABOVE BULKLEY LAKE" and
# "Maxan Ck hydrometric" are both "maxan creek"
stream_of <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9' ]+", " ", x)
  x <- gsub("\\b(ck|cr|crk)\\b", "creek", x)
  x <- gsub("\\br\\b", "river", x)
  x <- gsub("\\btrib\\b", "tributary", x)
  x <- trimws(gsub(" +", " ", x))
  x <- sub("^(upper|lower) ", "", x)
  # up to the first stream noun where there is one, otherwise up to the first word
  # that describes the gauge rather than the stream
  noun <- "^(.*?\\b(creek|river|brook|slough|channel|lake|spring))\\b.*$"
  stop_words <- paste0("\\b(above|below|near|nr|at|on|in|upstream|downstream|abv|blw|",
                       "hydrometric|station|gauge|gage|weir|site|discharge|flow|water|level|",
                       "monitoring|quality|outlet|inlet|mouth)\\b.*$")
  has_noun <- grepl(noun, x, perl = TRUE)
  x[has_noun] <- sub(noun, "\\1", x[has_noun], perl = TRUE)
  x[!has_noun] <- sub(stop_words, "", x[!has_noun])
  trimws(x)
}
hy$stream <- stream_of(hy$station_name)
albers <- function(lon, lat) {
  sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(lon = lon, lat = lat), coords = c("lon", "lat"),
                                                   crs = 4326), 3005)) / 1000
}
hy_xy <- albers(hy$lon, hy$lat)

# match stations s (station_id, name, lon, lat, first, last) to HYDAT. `wsc` names a
# column holding a WSC number where the source stores one.
hydat_match <- function(s, wsc = NULL) {
  xy <- albers(s$lon, s$lat)
  stream <- stream_of(s$name)
  res <- lapply(seq_len(nrow(s)), function(i) {
    d <- sqrt((hy_xy[, 1] - xy[i, 1])^2 + (hy_xy[, 2] - xy[i, 2])^2)
    by_number <- !is.null(wsc) && !is.na(s[[wsc]][i]) && s[[wsc]][i] %in% hy$station_number
    j <- if (by_number) match(s[[wsc]][i], hy$station_number) else {
      same <- which(d <= match_km & hy$stream == stream[i] & nzchar(stream[i]))
      if (length(same)) same[which.min(d[same])] else NA_integer_
    }
    near <- which((d <= match_km & hy$stream != stream[i]) |
                  (d > match_km & d <= near_km & hy$stream == stream[i] & nzchar(stream[i])))
    near <- setdiff(near, j)
    data.frame(
      hydat = if (is.na(j)) NA_character_ else hy$station_number[j],
      hydat_km = if (is.na(j)) NA_real_ else round(d[j], 2),
      hydat_q = if (is.na(j) || is.na(hy$q_from[j])) NA_character_ else sprintf("%d-%d", hy$q_from[j], hy$q_to[j]),
      near_miss = paste(sprintf("%s (%.2f km)", hy$station_number[near], d[near]), collapse = "; "),
      class = if (is.na(j)) "not in HYDAT" else if (!is.na(hy$q_from[j]) && !is.na(s$first[i]) &&
        s$first[i] >= hy$q_from[j] && s$last[i] <= hy$q_to[j]) "duplicate" else "same site, new years"
    )
  })
  cbind(s, do.call(rbind, res))
}

# complete window-years implied by a listed period, assuming no gaps: the [I] proxy.
# One row per station, window and year, as window_rows() gives from daily values.
proxy_rows <- function(id, start, end) {
  do.call(rbind, lapply(seq_along(id), function(i) {
    if (is.na(start[i]) || is.na(end[i]) || end[i] < start[i]) return(NULL)
    yrs <- as.integer(format(start[i], "%Y")):as.integer(format(end[i], "%Y"))
    do.call(rbind, lapply(seq_len(nrow(windows)), function(k) {
      ok <- as.Date(paste0(yrs, "-", windows$start[k])) >= start[i] &
        as.Date(paste0(yrs, "-", windows$end[k])) <= end[i]
      if (any(ok)) data.frame(station_id = id[i], period = windows$window[k], year = yrs[ok]) else NULL
    }))
  }))
}

snapshot <- character()
snap <- function(file) {
  path <- file.path(raw_dir, file)
  if (!file.exists(path)) stop("snapshot ", path, " is missing", call. = FALSE)
  snapshot[[file]] <<- unname(tools::md5sum(path))
  path
}

# ---- Columbia Basin Water Hub (Living Lakes Canada) -------------------------------------------
# robots.txt at data.cbwaterhub.ca disallows /api/ for every agent, so this script fetches
# nothing from that host. It reads one package_search dump (all 452 datasets), taken once by
# hand during the survey; a scripted reader waits on Living Lakes saying it is welcome. The
# daily values sit behind the same path, so window-years here are the [I] period proxy.
cb_file <- "cbwaterhub_package_search_20261028.json"
cb <- jsonlite::fromJSON(snap(cb_file), simplifyVector = FALSE)$result$results
stopifnot(length(cb) == 452)
cb_row <- function(p) {
  q_res <- Filter(function(r) any(vapply(r$parameter, function(x) identical(x$parameter, "Discharge"), FALSE)),
                  p$resources)
  tagged <- any(vapply(p$tags, function(t) identical(t$name, "Discharge"), FALSE))
  if (!length(q_res) && !tagged) return(NULL)
  # the discharge resource's own period where its name gives one, else the dataset's
  per <- regmatches(vapply(q_res, function(r) r$name, ""),
                    regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2} to [0-9]{4}-[0-9]{2}-[0-9]{2}",
                            vapply(q_res, function(r) r$name, "")))
  if (length(per)) {
    d <- as.Date(unlist(strsplit(per, " to ")))
    from <- min(d)
    to <- max(d)
  } else {
    from <- as.Date(if (nzchar(p$start_date %||% "")) p$start_date else NA)
    to <- as.Date(if (nzchar(p$end_date %||% "")) p$end_date else NA)
  }
  site <- if (length(q_res) && length(q_res[[1]]$site)) q_res[[1]]$site[[1]] else NULL
  wb <- trimws(site$waterbody %||% "")
  data.frame(
    source = "cbwaterhub", station_id = p$name,
    name = if (nzchar(wb)) wb else p$title,
    lon = as.numeric(p$longitude %||% NA), lat = as.numeric(p$latitude %||% NA),
    discharge = if (length(q_res)) "parameter" else "tag only",
    org = p$organization$name %||% NA_character_,
    cbwmf = any(vapply(p$groups, function(g) identical(g$name, "columbia-basin-water-monitoring-framework"), FALSE)),
    licence = p$license_id %||% NA_character_,
    from = from, to = to,
    first = as.integer(format(from, "%Y")), last = as.integer(format(to, "%Y")),
    regulation = "unknown", stringsAsFactors = FALSE
  )
}
cbs <- do.call(rbind, lapply(cb, cb_row))
cbs <- cbs[order(cbs$station_id), ]
cb_rows <- proxy_rows(cbs$station_id, cbs$from, cbs$to)
cbs$basis <- "period [I]"

# fetch url to raw_dir/file unless the snapshot is there already; robots.txt was read for
# every host this calls (research/station_sources.md names them)
# With may_fail, an HTTP error is kept as <file>.status (so a rerun reproduces it) and NA returned.
fetch <- function(url, file, delay = 0.5, may_fail = FALSE) {
  path <- file.path(raw_dir, file)
  status <- paste0(path, ".status")
  if (may_fail && file.exists(status)) {
    snapshot[[paste0(file, ".status")]] <<- unname(tools::md5sum(status))
    return(NA_character_)
  }
  if (!file.exists(path)) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    Sys.sleep(delay)
    r <- curl::curl_fetch_disk(url, paste0(path, ".part"),
                               handle = curl::new_handle(useragent = "wet station survey (R curl)", timeout = 300))
    if (r$status_code != 200) {
      unlink(paste0(path, ".part"))
      if (!may_fail) stop("HTTP ", r$status_code, " from ", url, call. = FALSE)
      writeLines(sprintf("HTTP %d", r$status_code), status)
      snapshot[[paste0(file, ".status")]] <<- unname(tools::md5sum(status))
      return(NA_character_)
    }
    file.rename(paste0(path, ".part"), path)
  }
  snapshot[[file]] <<- unname(tools::md5sum(path))
  path
}

# a name that says the flow is managed: the [I] regulation flag where a source has none
regulation_of <- function(name) {
  ifelse(grepl("\\b(dam|diversions?|reservoir|intake|spillway|pump|canal|ditch|pumphouse)\\b",
               tolower(name)), "regulated? (name) [I]", "unknown")
}

# complete window-years from daily values (station_number, date, q_m3s), the pilot's rule
window_rows <- function(daily) {
  ws <- wet_window_stats(daily, windows, stats = "mean")
  data.frame(station_id = ws$station_number, period = ws$period, year = ws$year)
}

# ---- BC Water Tool (Foundry Spatial): the third-party networks ------------------------------
# One station list for the third-party networks the tool holds (and its copy of the provincial
# stations, checked against the province below), and a daily CSV per station. robots.txt
# allows everything.
wt_list_file <- "bcwatertool_streamflow_stations_20261028.geojson"
wt_list <- fetch("https://nr-bcwat.bcwatertool.ca/api/streamflow/stations", wt_list_file)
wt <- jsonlite::fromJSON(wt_list, simplifyVector = FALSE)$features
wt <- do.call(rbind, lapply(wt, function(f) {
  p <- f$properties
  data.frame(id = p$id, nid = p$nid %||% NA_character_, name = p$name, net = p$net,
             status = p$status %||% NA_character_, n_yr = length(p$yr),
             lon = f$geometry$coordinates[[1]], lat = f$geometry$coordinates[[2]], stringsAsFactors = FALSE)
}))
wt <- wt[wt$n_yr > 0 & wt$net != "Water Survey of Canada", ]
wt <- wt[order(wt$nid, wt$id), ]
wt <- wt[!duplicated(wt$nid), ]   # the tool repeats some stations under one nid
read_wt <- function(id) {
  path <- fetch(sprintf("https://nr-bcwat.bcwatertool.ca/api/streamflow/stations/%d/csv", id),
                file.path("bcwatertool", sprintf("%d.csv", id)), may_fail = TRUE)
  if (is.na(path)) {
    return(list(licence = NA_character_, area = NA_real_, q = NULL,
                analyses = readLines(file.path(raw_dir, "bcwatertool", sprintf("%d.csv.status", id)))))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  meta <- grep("^# ", lines, value = TRUE)
  field <- function(k) {
    m <- grep(paste0("^# ", k, ","), meta, value = TRUE)
    if (length(m)) gsub('^"|"$', "", sub(paste0("^# ", k, ","), "", m[1])) else NA_character_
  }
  body <- lines[!grepl("^#", lines) & nzchar(lines)]
  x <- if (length(body) > 1) utils::read.csv(text = body, quote = "", na.strings = c("", "NA"),
                                              stringsAsFactors = FALSE) else NULL
  q <- if (!is.null(x)) x[x$Analysis == "Preliminary Discharge" & !is.na(x$Value), ] else NULL
  list(licence = field("Data Licence Information"), area = suppressWarnings(as.numeric(field("Drainage Area"))),
       q = if (!is.null(q) && nrow(q)) data.frame(station_number = as.character(id), date = as.Date(q$Datetime),
                                                  q_m3s = as.numeric(q$Value), qa = q$QA) else NULL,
       analyses = if (!is.null(x)) paste(sort(unique(x$Analysis)), collapse = "; ") else "")
}
wt_read <- lapply(wt$id, read_wt)
wt$analyses <- vapply(wt_read, function(r) r$analyses, "")
wt$licence <- vapply(wt_read, function(r) r$licence, "")
wt$area_km2 <- vapply(wt_read, function(r) r$area, 0)
wt$discharge <- vapply(wt_read, function(r) !is.null(r$q), FALSE)
wt_q <- do.call(rbind, lapply(wt_read, function(r) r$q))
wt$first <- NA_integer_
wt$last <- NA_integer_
rng <- tapply(wt_q$date, wt_q$station_number, range)
wt$first[wt$discharge] <- vapply(rng[as.character(wt$id[wt$discharge])], function(r) as.integer(format(r[1], "%Y")), 0L)
wt$last[wt$discharge] <- vapply(rng[as.character(wt$id[wt$discharge])], function(r) as.integer(format(r[2], "%Y")), 0L)
wt$days_q <- 0L
wt$days_q[wt$discharge] <- as.integer(table(wt_q$station_number)[as.character(wt$id[wt$discharge])])
wt_rows <- window_rows(wt_q[, c("station_number", "date", "q_m3s")])
wt_rows$station_id <- wt$nid[match(wt_rows$station_id, as.character(wt$id))]
wt$basis <- ifelse(wt$discharge, "daily", NA)
wt$regulation <- regulation_of(wt$name)
wt$station_id <- wt$nid

# ---- the province's non-integrated stations: its own hourly files ----------------------------
# Every discharge file in the BC Data Catalogue's "Hydrometric data" directory (OGL-BC 2.0), as
# listed on 2026-10-28. These, not the tool's copies, give the provincial stations' daily values,
# coordinates and grades: the tool places some stations a degree of latitude from the province.
# A day is a UTC day with at least 20 hourly values, leaving out hours graded Unusable; an hour
# in two files is taken from the newer.
prov_dir <- "https://www.env.gov.bc.ca/wsd/data_searches/water/"
prov_files <- c("Discharge.csv", "Discharge_Archive_Post_20251001.csv", "Discharge_Archive_2023Oct_2025Oct.csv",
                "Discharge_Archive_2021Oct_2023Oct.csv", "Discharge_Archive_2019Oct_2021Oct.csv",
                "Discharge_Archive_2017Oct_2019Oct.csv", "Discharge_Archive_2015Oct_2017Oct.csv",
                "Discharge_Archive_Pre_20151001.csv")  # newest first
prov_paths <- vapply(prov_files, function(f) fetch(paste0(prov_dir, f), file.path("bcenv", f)), "")
# The files end lines in CRLF, which duckdb's strict mode refuses, and one station name holds
# byte 0x96 (a Windows-1252 dash), which is neither UTF-8 nor Latin-1. So each file is read from
# a temporary copy with that byte made "-", without strict mode, and each file's row count is
# held to its line count so that no row the lenient parser drops goes unseen.
prov_tmp <- vapply(prov_paths, function(path) {
  out <- tempfile(fileext = ".csv")
  i <- file(path, "rb")
  o <- file(out, "wb")
  while (length(b <- readBin(i, "raw", 64e6))) {
    b[b == as.raw(0x96)] <- as.raw(0x2d)
    writeBin(b, o)
  }
  close(i)
  close(o)
  out
}, "")
lines_in <- vapply(prov_tmp, function(f) {
  con <- file(f, "rb")
  on.exit(close(con))
  n <- 0
  while (length(b <- readBin(con, "raw", 64e6))) n <- n + sum(b == as.raw(10))
  n
}, 0) - 1
csv_cols <- "columns = {'id': 'VARCHAR', 'name': 'VARCHAR', 'status': 'VARCHAR', 'lat': 'DOUBLE', 'lon': 'DOUBLE',
  't': 'VARCHAR', 'param': 'VARCHAR', 'value': 'DOUBLE', 'unit': 'VARCHAR', 'grade': 'VARCHAR'}"
tmp_list <- paste(sprintf("'%s'", prov_tmp), collapse = ", ")
duck <- DBI::dbConnect(duckdb::duckdb())
rows_read <- DBI::dbGetQuery(duck, sprintf("
  SELECT filename, count(*) AS n
  FROM read_csv([%s], header = true, auto_detect = false, strict_mode = false, filename = true, %s)
  GROUP BY 1", tmp_list, csv_cols))
if (!identical(as.numeric(rows_read$n[match(prov_tmp, rows_read$filename)]), unname(lines_in))) {
  stop("a provincial file read a different number of rows than it has lines", call. = FALSE)
}
# Six stations report 2016-2019 in l/s, the rest in m^3/s; NaN values are dropped and counted.
invisible(DBI::dbExecute(duck, sprintf("
  CREATE TABLE raw AS
  SELECT *, row_number() OVER (PARTITION BY id, t ORDER BY list_position([%s], filename)) AS k
  FROM read_csv([%s], header = true, auto_detect = false, strict_mode = false, filename = true, %s)
  WHERE trim(param) = 'Discharge' AND value IS NOT NULL", tmp_list, tmp_list, csv_cols)))
unlink(prov_tmp)
prov_units <- DBI::dbGetQuery(duck, "SELECT trim(unit) AS unit, count(*) AS n, count(DISTINCT trim(id)) AS stations
  FROM raw WHERE k = 1 AND NOT isnan(value) GROUP BY 1 ORDER BY 1")
if (!all(prov_units$unit %in% c("l/s", "m^3/s"))) {
  stop("a provincial discharge value has a unit other than l/s or m^3/s", call. = FALSE)
}
prov_nan <- DBI::dbGetQuery(duck, "SELECT count(*) AS n, count(DISTINCT trim(id)) AS stations
  FROM raw WHERE k = 1 AND isnan(value)")
invisible(DBI::dbExecute(duck, "
  CREATE TABLE h AS
  SELECT id, name, status, lat, lon, t, grade,
         CASE WHEN trim(unit) = 'l/s' THEN value / 1000 ELSE value END AS value
  FROM raw WHERE k = 1 AND NOT isnan(value)"))
# no plausibility filter: what the province publishes is reported, and complete days do not
# depend on magnitude
prov_big <- DBI::dbGetQuery(duck, "
  SELECT trim(id) AS station_id, trim(arg_max(name, t)) AS name, count(*) AS hours, max(value) AS max_m3s
  FROM h WHERE value > 1000 GROUP BY 1 ORDER BY 1")
prov_q <- DBI::dbGetQuery(duck, "
  SELECT trim(id) AS station_number, CAST(substr(t, 1, 10) AS DATE) AS date, avg(value) AS q_m3s, count(*) AS hours
  FROM h WHERE trim(grade) <> 'Unusable' GROUP BY 1, 2 ORDER BY 1, 2")
prov <- DBI::dbGetQuery(duck, "
  SELECT trim(id) AS station_id, trim(arg_max(name, t)) AS name, trim(arg_max(status, t)) AS status,
         arg_max(lat, t) AS lat, arg_max(lon, t) AS lon, count(*) AS hours_q,
         avg(CASE WHEN trim(grade) IN ('Undefined', 'Unspecified') THEN 1 ELSE 0 END) AS ungraded
  FROM h GROUP BY 1 ORDER BY 1")
prov_grades <- DBI::dbGetQuery(duck, "SELECT trim(grade) AS grade, count(*) AS n FROM h GROUP BY 1 ORDER BY 2 DESC, 1")
DBI::dbDisconnect(duck, shutdown = TRUE)
prov_q$date <- as.Date(prov_q$date)
prov_q24 <- prov_q[prov_q$hours == 24, ]
prov_q <- prov_q[prov_q$hours >= 20, c("station_number", "date", "q_m3s")]
prov_rows <- window_rows(prov_q)
rng <- tapply(prov_q$date, prov_q$station_number, range)
prov$first <- vapply(rng[prov$station_id], function(r) if (is.null(r)) NA_integer_ else as.integer(format(r[1], "%Y")), 0L)
prov$last <- vapply(rng[prov$station_id], function(r) if (is.null(r)) NA_integer_ else as.integer(format(r[2], "%Y")), 0L)
prov$source <- "bcenv"
prov$network <- "BC ENV non-integrated (provincial files)"
prov$basis <- ifelse(is.na(prov$first), "no complete day", "daily")
prov$regulation <- regulation_of(prov$name)
prov$licence <- "OGL-BC 2.0"

# the tool against the province: the same station's daily values (24-hour days) and coordinates
wt_day <- wt_q
wt_day$nid <- wt$nid[match(wt_day$station_number, as.character(wt$id))]
cmp <- merge(setNames(prov_q24[, c("station_number", "date", "q_m3s")], c("nid", "date", "prov_q")),
             wt_day[, c("nid", "date", "q_m3s")])
cmp <- cmp[!is.na(cmp$q_m3s), ]
cmp$rel <- abs(cmp$q_m3s - cmp$prov_q) / pmax(abs(cmp$prov_q), 1e-3)
both <- intersect(prov$station_id, wt$nid)
wt_at <- wt[match(both, wt$nid), ]
pv_at <- prov[match(both, prov$station_id), ]
coord_km <- sqrt(rowSums((albers(wt_at$lon, wt_at$lat) - albers(pv_at$lon, pv_at$lat))^2))
names(coord_km) <- both

# ---- USGS daily discharge at the two BC sites whose record runs past HYDAT's -----------------
# waterservices.usgs.gov serves no robots.txt; the OGC API's items path, which robots.txt
# disallows, is not read. The sites are the survey's (research/station_sources.md).
usgs_sites <- c("12355000", "12212390")
usgs_q <- do.call(rbind, lapply(usgs_sites, function(s) {
  path <- fetch(sprintf("https://waterservices.usgs.gov/nwis/dv/?format=rdb&sites=%s&parameterCd=00060&startDT=1900-01-01&endDT=2026-10-27", s),
                sprintf("usgs_dv_%s_20261028.rdb", s))
  x <- utils::read.delim(path, comment.char = "#", stringsAsFactors = FALSE, quote = "")[-1, ]
  vcol <- grep("_00060_00003$", names(x), value = TRUE)[1]
  v <- x[[vcol]]
  v[!grepl("^[0-9.]+$", v)] <- NA  # a code such as Eqp (equipment malfunction) in place of a value
  data.frame(station_number = s, date = as.Date(x$datetime), q_m3s = as.numeric(v) * 0.0283168,
             approval = x[[paste0(vcol, "_cd")]])
}))
usgs_q <- usgs_q[!is.na(usgs_q$q_m3s), ]
usgs_rows <- window_rows(usgs_q[, c("station_number", "date", "q_m3s")])
usgs_site <- utils::read.delim(fetch(sprintf("https://waterservices.usgs.gov/nwis/site/?format=rdb&sites=%s",
                                               paste(usgs_sites, collapse = ",")), "usgs_site_20261028.rdb"),
                               comment.char = "#", stringsAsFactors = FALSE, quote = "", colClasses = "character")[-1, ]
usgs_site <- usgs_site[match(usgs_sites, usgs_site$site_no), ]
usgs_meta <- data.frame(
  source = "usgs", station_id = usgs_sites, name = usgs_site$station_nm,
  lon = as.numeric(usgs_site$dec_long_va), lat = as.numeric(usgs_site$dec_lat_va),
  first = vapply(usgs_sites, function(s) as.integer(format(min(usgs_q$date[usgs_q$station_number == s]), "%Y")), 0L),
  last = vapply(usgs_sites, function(s) as.integer(format(max(usgs_q$date[usgs_q$station_number == s]), "%Y")), 0L),
  basis = "daily", regulation = "unknown", stringsAsFactors = FALSE)

# ---- one table: every station read, matched to HYDAT -----------------------------------------
cols <- c("source", "network", "station_id", "name", "lon", "lat", "first", "last", "basis", "regulation", "licence")
cbs$network <- paste0("cbwaterhub: ", cbs$org, ifelse(cbs$cbwmf, " (CBWMF)", ""))
cbs$basis[cbs$discharge == "tag only"] <- "period [I], Discharge tag only"
wt$source <- "bcwatertool"
wt$network <- wt$net
wt$basis[!wt$discharge] <- ifelse(grepl("^HTTP", wt$analyses[!wt$discharge]),
                                  paste("no discharge series: csv", wt$analyses[!wt$discharge]), "no discharge series")
usgs_meta$network <- "USGS"
usgs_meta$licence <- "US public domain [I]"
wt_own <- wt[!wt$nid %in% prov$station_id, ]
st <- rbind(cbs[cols], prov[cols], wt_own[cols], usgs_meta[cols])
st <- hydat_match(st)
rows <- rbind(cbind(source = "cbwaterhub", cb_rows), cbind(source = "bcenv", prov_rows),
              cbind(source = "bcwatertool", wt_rows[wt_rows$station_id %in% wt_own$nid, ]),
              cbind(source = "usgs", usgs_rows))
key <- paste(st$source, st$station_id)
rows$key <- paste(rows$source, rows$station_id)
stopifnot(all(rows$key %in% key))
q_from <- hy$q_from[match(st$hydat, hy$station_number)]
q_to <- hy$q_to[match(st$hydat, hy$station_number)]
count_years <- function(i, new_only) {
  r <- rows[rows$key == key[i], ]
  if (new_only && !is.na(q_from[i])) r <- r[r$year < q_from[i] | r$year > q_to[i], ]
  if (!nrow(r)) return(0L)
  max(table(factor(r$period, levels = windows$window)))
}
st$window_years <- vapply(seq_len(nrow(st)), count_years, 0L, new_only = FALSE)
st$window_years_new <- vapply(seq_len(nrow(st)), count_years, 0L, new_only = TRUE)
# seasonal: a daily record with no day in December-February
q_all <- rbind(cbind(source = "bcwatertool", wt_q[, c("station_number", "date")]),
               cbind(source = "bcenv", prov_q[, c("station_number", "date")]),
               cbind(source = "usgs", usgs_q[, c("station_number", "date")]))
q_all$station_number[q_all$source == "bcwatertool"] <-
  wt$nid[match(q_all$station_number[q_all$source == "bcwatertool"], as.character(wt$id))]
winter <- unique(paste(q_all$source, q_all$station_number)[format(q_all$date, "%m") %in% c("12", "01", "02")])
st$seasonal <- ifelse(st$basis == "daily", !key %in% winter, NA)
st$new <- st$class != "duplicate" & !grepl("^no discharge", st$basis)
st$pass <- st$new & st$basis == "daily" & st$window_years_new >= min_years
st <- st[order(st$source, st$network, st$station_id), ]
# one site, several listings (a stewardship network's station also in the provincial
# database, a Water Hub site under two groups): within same_site_km on the same stream
same_site_km <- 0.5
st_xy <- albers(st$lon, st$lat)
st_stream <- stream_of(st$name)
st$site <- seq_len(nrow(st))
for (i in seq_len(nrow(st))) for (j in seq_len(i - 1)) {
  if (sqrt(sum((st_xy[i, ] - st_xy[j, ])^2)) <= same_site_km && identical(st_stream[i], st_stream[j]) &&
      !is.na(st_stream[i])) st$site[st$site == st$site[i]] <- st$site[j]
}
st$also <- vapply(seq_len(nrow(st)), function(i) {
  o <- which(st$site == st$site[i] & seq_len(nrow(st)) != i)
  if (length(o)) paste(sprintf("%s %s", st$network[o], st$station_id[o]), collapse = "; ") else "-"
}, "")

# ---- the report ------------------------------------------------------------------------------
say(sprintf("Station sources beyond HYDAT (#123): station lists, the HYDAT match and Chinook-window years"),
    sprintf("HYDAT release %s; code_md5 %s", release, code_md5),
    "Windows: CH migration 05-01..08-01 and spawning 08-01..09-15; a complete window-year is a",
    "wet_window_stats() row at min_frac 0.8 ('daily'), or a window inside a listed period ('period [I]').",
    sprintf("HYDAT match: within %g km and the same stream name; near misses within %g km listed.", match_km, near_km),
    sprintf("A station passes the station test with >= %d complete window-years (daily) outside HYDAT's discharge years at its site.", min_years),
    "", "Snapshots (data/station_sources/raw/, md5):")
for (f in sort(names(snapshot))) if (!grepl("^bcwatertool/", f)) say(sprintf("  %s  %s", snapshot[[f]], f))
wt_files <- sort(grep("^bcwatertool/", names(snapshot), value = TRUE))
say(sprintf("  bcwatertool/: %d stations answered HTTP errors (kept as .status files)", sum(grepl("[.]status$", wt_files))))
tf <- tempfile()
writeLines(paste(unlist(snapshot[wt_files]), wt_files), tf)
say(sprintf("  bcwatertool/*.csv: %d per-station files; md5 of their md5 list %s", length(wt_files),
            unname(tools::md5sum(tf))))
unlink(tf)

say("", sprintf("HYDAT: %d stations with coordinates, %d in BC, %d BC with a discharge record (STN_DATA_RANGE Q).",
                nrow(hy), sum(hy$prov == "BC"), sum(hy$prov == "BC" & !is.na(hy$q_from))))

say("", "Per network: stations read; with discharge; not in HYDAT; same site, new years; duplicate;",
    "  new stations with >= 1 and >= 3 complete window-years outside HYDAT; seasonal (daily, no Dec-Feb day)")
nets <- unique(st[c("source", "network")])
for (i in seq_len(nrow(nets))) {
  x <- st[st$source == nets$source[i] & st$network == nets$network[i], ]
  q <- !grepl("^no discharge", x$basis)
  say(sprintf("  %-12s %-60s read %4d  Q %4d  new %4d  same-site %3d  dup %3d  >=1 %4d  >=3 %4d  seasonal %s  [%s]",
              nets$source[i], substr(nets$network[i], 1, 60), nrow(x), sum(q), sum(q & x$class == "not in HYDAT"),
              sum(q & x$class == "same site, new years"), sum(q & x$class == "duplicate"),
              sum(x$new & x$window_years_new >= 1), sum(x$new & x$window_years_new >= min_years),
              if (all(is.na(x$seasonal))) "-" else as.character(sum(x$seasonal, na.rm = TRUE)),
              paste(unique(x$basis), collapse = "; ")))
}
say("", sprintf("Stations passing the station test (daily): %d; by network:", sum(st$pass)))
for (n in names(sort(table(st$network[st$pass]), decreasing = TRUE))) say(sprintf("  %3d  %s", sum(st$pass & st$network == n), n))
say(sprintf("Distinct sites among them (within %g km on the same stream): %d", same_site_km, length(unique(st$site[st$pass]))))
proxy_pass <- st$new & st$basis != "daily" & st$window_years_new >= min_years
say(sprintf("Passing on the period proxy alone (cannot reach harvest): %d stations, %d sites; not already a passing site: %d",
            sum(proxy_pass), length(unique(st$site[proxy_pass])), length(setdiff(st$site[proxy_pass], st$site[st$pass]))))
say(sprintf("Lower bars: new discharge stations (any record) %d, sites %d; with >= 1 complete window-year %d, sites %d;",
            sum(st$new), length(unique(st$site[st$new])), sum(st$new & st$window_years_new >= 1),
            length(unique(st$site[st$new & st$window_years_new >= 1]))),
    sprintf("  seasonal-only (daily, no Dec-Feb day) new stations with >= 1 complete window-year: %d",
            sum(st$new & st$window_years_new >= 1 & st$seasonal %in% TRUE)))

say("", sprintf("Provincial files: %d stations with discharge, %d with a complete day; %d hourly values; grades:",
                nrow(prov), sum(!is.na(prov$first)), sum(prov$hours_q)))
say(sprintf("  %s", paste(sprintf("%s %.1f %%", prov_grades$grade, 100 * prov_grades$n / sum(prov_grades$n)), collapse = "; ")))
say(sprintf("  stations whose hours are mostly Undefined or Unspecified: %d of %d", sum(prov$ungraded > 0.5), nrow(prov)))
say(sprintf("  units: %s (l/s divided by 1000); NaN values dropped: %d at %d stations",
            paste(sprintf("%s %d values at %d stations", prov_units$unit, prov_units$n, prov_units$stations), collapse = "; "),
            prov_nan$n, prov_nan$stations))
say("  stations with an hourly value above 1,000 m^3/s (hours, max):")
for (i in seq_len(nrow(prov_big))) {
  say(sprintf("    %s %s: %d, %.1f", prov_big$station_id[i], prov_big$name[i], prov_big$hours[i], prov_big$max_m3s[i]))
}
say("", "The BC Water Tool against the province (the same station's 24-hour UTC days):")
for (x in list(list("before 2025-10-01", cmp$date < as.Date("2025-10-01")), list("from 2025-10-01 (provisional)", cmp$date >= as.Date("2025-10-01")))) {
  c1 <- cmp[x[[2]], ]
  say(sprintf("  %s: %d station-days at %d stations; %.1f %% within 0.1 %%, %.1f %% within 1 %%, %.1f %% within 5 %%",
              x[[1]], nrow(c1), length(unique(c1$nid)), 100 * mean(c1$rel <= 0.001), 100 * mean(c1$rel <= 0.01),
              100 * mean(c1$rel <= 0.05)))
}
cmp_yr <- format(cmp$date, "%Y")
say("  by year: station-days, % within 0.1 %, % within 5 %")
for (y in sort(unique(cmp_yr))) {
  c1 <- cmp[cmp_yr == y, ]
  say(sprintf("    %s %6d %5.1f %5.1f", y, nrow(c1), 100 * mean(c1$rel <= 0.001), 100 * mean(c1$rel <= 0.05)))
}
say(sprintf("  coordinates: %d stations in both; %d more than 1 km apart (tool against province, km):",
            length(coord_km), sum(coord_km > 1)))
for (n in names(sort(coord_km[coord_km > 1], decreasing = TRUE))) say(sprintf("    %s %.1f", n, coord_km[[n]]))
say(sprintf("  provincial-file stations not in the tool: %s", paste(setdiff(prov$station_id, wt$nid), collapse = ", ")),
    sprintf("  tool BC ENV stations with discharge not in the provincial files (kept from the tool): %s",
            paste(wt_own$nid[wt_own$net == "BC ENV - Real-time Water Data Reporting" & wt_own$discharge], collapse = ", ")))

say("", "Licences stated in the BC Water Tool CSV headers, by network (first 100 characters):")
for (n in sort(unique(wt$net))) {
  l <- unique(substr(wt$licence[wt$net == n], 1, 100))
  say(sprintf("  %s: %s", n, paste(l, collapse = " | ")))
}

say("", "Every station read (source | network | id | name | lon | lat | first-last | basis | regulation |",
    "  HYDAT match (km, its Q years) | class | window-years all/new | seasonal | near misses | same site listed as):")
for (i in seq_len(nrow(st))) {
  x <- st[i, ]
  say(sprintf("  %s | %s | %s | %s | %.4f | %.4f | %s-%s | %s | %s | %s | %s | %d/%d | %s | %s | %s",
              x$source, x$network, x$station_id, x$name, x$lon, x$lat, x$first, x$last, x$basis, x$regulation,
              if (is.na(x$hydat)) "-" else sprintf("%s (%.2f km, %s)", x$hydat, x$hydat_km, x$hydat_q %||% "no Q"),
              x$class, x$window_years, x$window_years_new, if (is.na(x$seasonal)) "-" else x$seasonal,
              if (nzchar(x$near_miss)) x$near_miss else "-", x$also))
}

writeLines(out, report)
cat("wrote", report, "\n")
