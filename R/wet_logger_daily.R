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

# ---- days from readings ----------------------------------------------------------------------
#
# The rules, registered in research/station_water_temperature.md ("Logger records") before any
# logger day was screened, applied in this order after the `valid` range:
# 1. stuck runs: in wet_logger_months, consecutive hours whose hourly means are identical (to
#    1e-6 degC) and above wet_logger_stuck_above_c, for more than wet_logger_stuck_h hours, are
#    dropped;
# 2. the hour rule: a day needs `min_hours` hours with a reading;
# 3. deployment ends: a deployment is a run of readings with no gap longer than
#    wet_logger_gap_h hours; its first and last local days are dropped;
# 4. air days: in wet_logger_months, a day whose range of hourly means exceeds its month's
#    wet_logger_air_c is dropped.
# The thresholds are scripts/temp_logger_thresholds.R's (data/checks/temp_logger_thresholds.txt,
# option a under Amendment 1); a test holds these constants to that report.
wet_logger_air_c <- c(`5` = 12.09, `6` = 13.86, `7` = 16.83, `8` = 16.59, `9` = 18.38)
wet_logger_stuck_h <- 154
wet_logger_stuck_above_c <- 0.5
wet_logger_gap_h <- 6
wet_logger_months <- 5:9

# Readings of one logger file: data.frame(time, t, flag, pass), `time` as stamped (read as UTC
# digits; the registry's clock_offset says what clock they are), `pass` TRUE where the holder's
# flag says the reading passed its checks. The format is told by the header, so a series in a
# new format is refused rather than misread.
wet_logger_read <- function(path) {
  x <- utils::read.csv(path, colClasses = "character", check.names = FALSE, na.strings = character(),
                       encoding = "UTF-8")
  nhg <- c("station_code", "timestamp (UTC)", "wtmp (°C)", "wtmp_flag")
  if (!identical(names(x), nhg)) stop(path, " is not a logger file in a format wet reads", call. = FALSE)
  time <- as.POSIXct(x[[2]], format = "%Y-%m-%d %H:%M", tz = "UTC")
  if (anyNA(time)) stop(path, ": a timestamp is not YYYY-MM-DD HH:MM, such as \"", x[[2]][is.na(time)][1], "\"",
                        call. = FALSE)
  t <- suppressWarnings(as.numeric(x[[3]]))
  bad <- is.na(t) & x[[3]] != "NA"
  if (any(bad)) stop(path, ": a temperature that is not a number, such as \"", x[[3]][bad][1], "\"", call. = FALSE)
  if (anyDuplicated(time)) stop(path, ": two readings at ", format(time[duplicated(time)][1]), call. = FALSE)
  # NHG's flags (ReadMe.txt): P passed every check, A averaged from sensors that all passed
  data.frame(time = time, t = t, flag = x[[4]], pass = x[[4]] %in% c("P", "A"))
}

# Local standard days of one site's readings under the rules above:
# data.frame(date, t_mean_c, t_min_c, t_max_c, n_hours, n_flagged, drop), one row per day with
# any valid reading, `drop` NA for a kept day, else the first rule that dropped it ("stuck",
# "hours", "deployment", "air"); `n_flagged` counts the day's valid readings the holder did not
# pass. Means and sums are taken in a fixed order, so a rerun is identical.
wet_logger_days <- function(r, clock_offset = 0, day_offset = -8, valid = c(-1, 35), min_hours = 20,
                            air_c = wet_logger_air_c, stuck_h = wet_logger_stuck_h,
                            stuck_above = wet_logger_stuck_above_c, gap_h = wet_logger_gap_h,
                            months = wet_logger_months) {
  empty <- data.frame(date = as.Date(character()), t_mean_c = numeric(), t_min_c = numeric(), t_max_c = numeric(),
                      n_hours = integer(), n_flagged = integer(), drop = character())
  r <- r[!is.na(r$t) & r$t >= valid[1] & r$t <= valid[2], ]
  if (!nrow(r)) return(empty)
  sec <- as.numeric(r$time) - clock_offset * 3600 + day_offset * 3600
  o <- order(sec, method = "radix")
  sec <- sec[o]
  t <- r$t[o]
  pass <- r$pass[o]

  # deployments and their end days
  dep <- cumsum(c(TRUE, diff(sec) > gap_h * 3600))
  dday <- sec %/% 86400
  ends <- unique(c(dday[!duplicated(dep)], dday[!duplicated(dep, fromLast = TRUE)]))

  # hours: mean of readings, min, max, flagged count, summed station-hour by station-hour
  hh <- sec %/% 3600
  oh <- order(hh, t, method = "radix")
  hk <- hh[oh]
  first <- c(TRUE, diff(hk) != 0)
  g <- cumsum(first)
  n <- tabulate(g)
  last <- c(first[-1], TRUE)
  hours <- data.frame(hh = hk[first], v = unname(rowsum(t[oh], g, reorder = FALSE)[, 1]) / n,
                      v_min = t[oh][first], v_max = t[oh][last],
                      flagged = unname(rowsum(as.integer(!pass[oh]), g, reorder = FALSE)[, 1]))
  hours$dd <- hours$hh %/% 24
  hours$month <- as.integer(format(as.Date(hours$dd, origin = "1970-01-01"), "%m"))

  # 1. stuck runs
  cand <- hours$month %in% months & hours$v > stuck_above
  vr <- round(hours$v, 6)
  brk <- c(TRUE, diff(hours$hh) != 1 | diff(vr) != 0 | diff(cand) != 0)
  run <- cumsum(brk)
  len <- tabulate(run)[run]
  stuck <- cand & len > stuck_h
  stuck_days <- unique(hours$dd[stuck])
  all_days <- unique(hours$dd)
  hours <- hours[!stuck, ]

  # days from the hours left
  df <- c(TRUE, diff(hours$dd) != 0)
  dg <- cumsum(df)
  ord <- order(dg, hours$v, method = "radix")
  so <- dg[ord]
  lo <- c(TRUE, diff(so) != 0)
  hi <- c(lo[-1], TRUE)
  d <- data.frame(dd = hours$dd[df], n_hours = tabulate(dg),
                  t_mean_c = unname(rowsum(hours$v[ord], so, reorder = FALSE)[, 1]) / tabulate(dg),
                  t_min_c = unname(tapply(hours$v_min, dg, min)), t_max_c = unname(tapply(hours$v_max, dg, max)),
                  range_c = hours$v[ord][hi] - hours$v[ord][lo],
                  n_flagged = as.integer(unname(rowsum(hours$flagged, dg, reorder = FALSE)[, 1])))
  gone <- setdiff(all_days, d$dd)
  if (length(gone)) {
    d <- rbind(d, data.frame(dd = gone, n_hours = 0L, t_mean_c = NA_real_, t_min_c = NA_real_, t_max_c = NA_real_,
                             range_c = NA_real_, n_flagged = 0L))
    d <- d[order(d$dd, method = "radix"), ]
  }
  month <- as.integer(format(as.Date(d$dd, origin = "1970-01-01"), "%m"))
  short <- d$n_hours < min_hours
  cap <- unname(air_c[as.character(month)])
  drop <- ifelse(short & d$dd %in% stuck_days, "stuck",
                 ifelse(short, "hours",
                        ifelse(d$dd %in% ends, "deployment",
                               ifelse(month %in% months & !is.na(cap) & d$range_c > cap, "air", NA_character_))))
  data.frame(date = as.Date(d$dd, origin = "1970-01-01"), t_mean_c = d$t_mean_c, t_min_c = d$t_min_c,
             t_max_c = d$t_max_c, n_hours = as.integer(d$n_hours), n_flagged = d$n_flagged, drop = drop)
}

# Every logger series' registry, with its series code.
wet_logger_registry <- function(series = names(wet_logger_versions)) {
  if (!length(series)) {
    return(data.frame(series = character(), station_number = character(), member = character(),
                      clock_offset = numeric(), day_offset = numeric()))
  }
  do.call(rbind, lapply(series, function(k) cbind(series = k, wet_logger_sites(k))))
}

# Days of logger sites `stations` (registry ids of one or more series), in wet_temp_daily()'s
# shape with `source` the series code. Ids outside every registry are refused.
wet_logger_daily <- function(stations, from = as.Date(-Inf), to = as.Date(Inf), valid = c(-1, 35),
                             min_hours = 20, cache_dir = wet_logger_cache()) {
  reg <- wet_logger_registry()
  unknown <- setdiff(stations, reg$station_number)
  if (length(unknown)) stop("not in a logger registry: ", paste(unknown, collapse = ", "), call. = FALSE)
  reg <- reg[reg$station_number %in% stations, ]
  out <- lapply(split(reg, reg$series), function(s) {
    k <- s$series[1]
    ex <- tempfile("wet_logger_")
    on.exit(unlink(ex, recursive = TRUE), add = TRUE)
    paths <- wet_logger_members(k, wet_logger_versions[[k]], s$member, exdir = ex, cache_dir = cache_dir)
    rows <- lapply(seq_len(nrow(s)), function(i) {
      d <- wet_logger_days(wet_logger_read(paths[i]), s$clock_offset[i], s$day_offset[i], valid, min_hours)
      d <- d[is.na(d$drop) & d$date >= from & d$date <= to, ]
      if (!nrow(d)) return(NULL)
      data.frame(station_number = s$station_number[i], date = d$date, t_mean_c = d$t_mean_c, t_min_c = d$t_min_c,
                 t_max_c = d$t_max_c, n_hours = d$n_hours, source = k, status = "provisional")
    })
    do.call(rbind, rows)
  })
  out <- do.call(rbind, c(list(wet_temp_empty()), unname(out)))
  out <- out[order(out$station_number, out$date, method = "radix"), ]
  rownames(out) <- NULL
  out
}

wet_temp_empty <- function() {
  data.frame(station_number = character(), date = as.Date(character()), t_mean_c = numeric(), t_min_c = numeric(),
             t_max_c = numeric(), n_hours = integer(), source = character(), status = character())
}
