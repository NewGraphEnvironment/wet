# Daily flow at the province's non-integrated hydrometric stations (#142),
# from a pinned snapshot of its hourly files (wet_bcenv()).
#
# The hourly files are turned into days once per manifest and reader version,
# and the days kept in wet's cache beside the snapshot as
# days_<manifest md5>_v<wet_bcenv_reader>.parquet (the md5's first 10
# characters), so days built from other files under the same snapshot date are
# never read as these: per station and day, the mean flow of the
# hours used, how many hours there were and how many of them were ungraded.
# The rules a caller may want to revisit (how many hours make a day, what an
# ungraded hour means for status, the plausibility bound) are applied when the
# days are read, not stored, so changing one needs no rebuild.
#
# Building the days, from the probe that surveyed these files
# (scripts/station_sources_probe.R, #123):
# - every file of the snapshot is read; an hour two files hold is taken from
#   the newer;
# - the files end their header line in CRLF, which duckdb's strict mode
#   refuses, and one station name holds byte 0x96 (a Windows-1252 dash), so each
#   file is read from a copy with that byte made "-", without strict mode, and
#   its row count held to its line count, so no row the lenient parser drops
#   goes unseen;
# - flows in l/s are divided by 1000, and any other unit than l/s or m^3/s is
#   refused; NaN hours and hours graded Unusable are left out;
# - the files' times are UTC; an hour belongs to the day of its local standard
#   time, UTC-8, or UTC-7 for stations in the Peace and Liard drainages (WSC
#   drainage areas 07 and 10), which keep Mountain Standard Time all year, so a
#   provincial day means the same day as a HYDAT or ECCC one. `utc = TRUE`
#   builds UTC days instead, the survey's rule, which only the harvest report's
#   reproduction of the survey uses.
#
# Every grade in the files must be one wet_bcenv_grades names; a grade it does
# not know is refused rather than read as graded.
#
# Returns wet_station_daily()'s shape, `source` "bcenv". `status` is
# "unchecked" for a day with any ungraded hour (Undefined, Unspecified or
# Unverified), and "provisional" for a day whose hours are all graded: the files carry no
# approval, so no provincial day is "approved".
wet_bcenv_daily <- function(stations = NULL, snapshot = wet_bcenv_snapshot, bound = wet_bcenv_bound,
                            min_hours = 20L, cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.null(stations) && (!is.character(stations) || anyNA(stations))) {
    stop("`stations` must be a character vector of station numbers, or NULL for all", call. = FALSE)
  }
  if (!is.numeric(bound) || !length(bound) || anyNA(bound) || any(bound <= 0) ||
      (is.null(names(bound)) && length(bound) != 1L) || (!is.null(names(bound)) && !".default" %in% names(bound))) {
    stop("`bound` must be one positive number (Inf for none), or positive numbers named by WSC sub-drainage ",
         "with a \".default\"", call. = FALSE)
  }
  if (!requireNamespace("duckdb", quietly = TRUE)) stop("install duckdb to read provincial flows", call. = FALSE)
  d <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache_dir), stations)
  d <- d[d$hours >= min_hours, ]
  if (!nrow(d)) return(wet_daily_empty())
  d <- d[d$q_m3s >= 0, ]
  cap <- wet_bcenv_cap(d$station_number, d$q_m3s, bound)
  d <- d[is.na(cap) | d$q_m3s <= cap, ]
  if (!nrow(d)) return(wet_daily_empty())
  d <- d[order(d$station_number, d$date, method = "radix"), ]
  data.frame(station_number = d$station_number, date = d$date, q_m3s = d$q_m3s, symbol = NA_character_,
             source = "bcenv", status = ifelse(d$ungraded > 0, "unchecked", "provisional"))
}

# The plausibility bound (research/station_sources.md, registered before it was
# applied): per WSC sub-drainage, the largest ratio of a station's largest daily
# flow to the median of its positive daily flows over BC's HYDAT 20260717
# stations with ten years of days; ".default", the province-wide largest, for a
# sub-drainage with fewer than 10 such stations. Measured by
# scripts/station_sources_bound.R (data/checks/station_sources_bound_20260717.txt),
# which holds this constant to its measurement.
wet_bcenv_bound <- c(.default = 2490.71, "07E" = 108.94, "07F" = 2490.71, "08C" = 39.34, "08E" = 119.78,
                     "08F" = 49.06, "08G" = 389.68, "08H" = 268.07, "08J" = 482.14, "08K" = 205.26,
                     "08L" = 535.45, "08M" = 581.48, "08N" = 535.71, "10B" = 51.52)

# Each day's cap: its station's ratio bound times the median of the station's
# positive flows among the days given (all its complete days in the snapshot);
# NA for a station with no positive flow. scripts/station_sources_bound.R
# applies the bound through this same function. `sub`, one per day, gives the
# sub-drainage where the number carries none (the Water Tool's gauges).
wet_bcenv_cap <- function(ids, q, bound, sub = NULL) {
  pos <- q > 0
  med <- vapply(split(q[pos], factor(ids[pos], unique(ids))), stats::median, 0)
  wet_bcenv_ratio(ids, bound, sub) * unname(med[ids])
}

# The ratio bound each station takes: its sub-drainage's (the first three
# characters of its number once leading letters are dropped, unless `sub`
# gives it), else ".default".
wet_bcenv_ratio <- function(ids, bound, sub = NULL) {
  if (is.null(names(bound))) return(rep(unname(bound), length(ids)))
  if (is.null(sub)) {
    sub <- sub("^[A-Z]+", "", ids)
    sub <- ifelse(grepl("^[0-9]{2}[A-Z]", sub), substr(sub, 1, 3), NA_character_)
  }
  b <- unname(bound[sub])
  b[is.na(b)] <- bound[[".default"]]
  b
}

# The reader version: bump it whenever wet_bcenv_hours() or wet_bcenv_build()
# change what the stored days hold, so an old cache is never read as new.
wet_bcenv_reader <- 2L

# The grades the province's files carry, read from the 20261028 snapshot:
# ungraded hours make a day "unchecked", Unusable hours are left out, and the
# rest are grades (RISC A-E and U, and the older labels).
wet_bcenv_grades <- list(
  ungraded = c("Undefined", "Unspecified", "Unverified"),
  unusable = "Unusable",
  graded = c("RISC A", "RISC B", "RISC C", "RISC D", "RISC E", "RISC U", "Excellent", "Very Good", "Good", "Poor",
             "Estimated", "EXCELLENT - RATED STRUCTURE", "Best Practice"))

# What the stored days of a snapshot are built from: its manifest's md5 (first
# 10 characters) and the reader version. The Water Tool's registry records it,
# since its cuts were measured on these days.
wet_bcenv_days_key <- function(snapshot) {
  sprintf("%s_v%d", substr(unname(tools::md5sum(wet_bcenv_manifest_path(snapshot))), 1, 10), wet_bcenv_reader)
}

# The stored days for a snapshot, built if this machine has none yet.
wet_bcenv_days <- function(snapshot, cache_dir, utc = FALSE) {
  dir <- file.path(cache_dir, "station_sources", "bcenv", snapshot)
  f <- file.path(dir, sprintf("days%s_%s.parquet", if (utc) "_utc" else "", wet_bcenv_days_key(snapshot)))
  if (file.exists(f)) return(f)
  paths <- wet_bcenv(snapshot, cache_dir)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  partial <- tempfile(paste0(".", basename(f), ".partial-"), tmpdir = dir)
  on.exit(unlink(partial), add = TRUE)
  message("building the provincial daily flows for snapshot ", snapshot, " (once per machine)")
  wet_bcenv_build(paths, partial, utc = utc)
  # two builds at once: either copy is whole
  if (!file.rename(partial, f) && !file.exists(f)) stop("could not move the daily flows into ", dir, call. = FALSE)
  f
}

wet_bcenv_days_read <- function(f, stations) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  where <- if (is.null(stations)) "" else if (!length(stations)) "WHERE false" else
    sprintf("WHERE station_number IN (%s)", paste(DBI::dbQuoteString(con, stations), collapse = ", "))
  d <- DBI::dbGetQuery(con, sprintf("SELECT station_number, date, q_m3s, hours, ungraded FROM read_parquet(%s) %s",
                                    DBI::dbQuoteString(con, f), where))
  d$date <- as.Date(d$date)
  d$hours <- as.integer(d$hours)
  d$ungraded <- as.integer(d$ungraded)
  d
}

# Turn the hourly files into days and write them to `dest` as parquet.
wet_bcenv_build <- function(paths, dest, utc = FALSE) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  wet_bcenv_hours(con, paths)
  known <- unlist(wet_bcenv_grades, use.names = FALSE)
  grades <- DBI::dbGetQuery(con, "SELECT DISTINCT grade FROM h")$grade
  if (anyNA(grades) || length(setdiff(grades, known))) {
    stop("a provincial hour carries a grade wet does not know: ",
         paste(ifelse(is.na(setdiff(grades, known)), "(none)", setdiff(grades, known)), collapse = ", "),
         "; add it to wet_bcenv_grades and bump wet_bcenv_reader", call. = FALSE)
  }
  ungraded <- paste(DBI::dbQuoteString(con, wet_bcenv_grades$ungraded), collapse = ", ")
  # local standard time: 7 hours behind UTC in drainage areas 07 and 10, 8 elsewhere
  offset <- if (utc) "0" else
    "CASE WHEN regexp_matches(regexp_replace(id, '^[A-Z]+', ''), '^(07|10)') THEN 7 ELSE 8 END"
  invisible(DBI::dbExecute(con, sprintf("
    COPY (
      SELECT id AS station_number,
             CAST(CAST(t AS TIMESTAMP) - to_hours(%s) AS DATE) AS date,
             avg(value) AS q_m3s, count(*) AS hours,
             count(*) FILTER (WHERE grade IN (%s)) AS ungraded
      FROM h WHERE grade <> %s
      GROUP BY 1, 2 ORDER BY 1, 2
    ) TO %s (FORMAT parquet)", offset, ungraded, DBI::dbQuoteString(con, wet_bcenv_grades$unusable),
    DBI::dbQuoteString(con, dest))))
  invisible(dest)
}

# Read the snapshot's hourly discharge into table `h` on `con`: one row per
# station and hour (id, name, status, lat, lon, t, grade, value in m^3/s), the
# newest file's where two files hold the hour, NaN left out. Text columns are
# trimmed. `paths` is newest first, as wet_bcenv() returns them.
wet_bcenv_hours <- function(con, paths) {
  tmp <- vapply(paths, wet_bcenv_dash, "")
  on.exit(unlink(tmp), add = TRUE)
  lines <- vapply(tmp, wet_bcenv_lines, 0) - 1
  cols <- "columns = {'id': 'VARCHAR', 'name': 'VARCHAR', 'status': 'VARCHAR', 'lat': 'DOUBLE', 'lon': 'DOUBLE',
    't': 'VARCHAR', 'param': 'VARCHAR', 'value': 'VARCHAR', 'unit': 'VARCHAR', 'grade': 'VARCHAR'}"
  files <- paste(DBI::dbQuoteString(con, unname(tmp)), collapse = ", ")
  src <- sprintf("read_csv([%s], header = true, auto_detect = false, strict_mode = false, filename = true, %s)",
                 files, cols)
  n <- DBI::dbGetQuery(con, sprintf("SELECT filename, count(*) AS n FROM %s GROUP BY 1", src))
  if (!identical(as.numeric(n$n[match(unname(tmp), n$filename)]), unname(lines))) {
    stop("a provincial file read a different number of rows than it has lines", call. = FALSE)
  }
  # values are read as text and checked here, so a value that is not a number is refused by name before any
  # read; the row count above never casts the column, so it cannot see one
  bad <- DBI::dbGetQuery(con, sprintf("
    SELECT count(*) AS n, any_value(value) AS v FROM %s
    WHERE trim(param) = 'Discharge' AND trim(value) <> '' AND TRY_CAST(trim(value) AS DOUBLE) IS NULL", src))
  if (bad$n > 0) {
    stop(bad$n, " provincial discharge values are not numbers, such as \"", bad$v, "\"", call. = FALSE)
  }
  invisible(DBI::dbExecute(con, sprintf("
    CREATE TEMP TABLE raw AS
    SELECT trim(id) AS id, trim(name) AS name, trim(status) AS status, lat, lon, trim(t) AS t,
           value, trim(unit) AS unit, trim(grade) AS grade
    FROM (SELECT * EXCLUDE (value), CAST(nullif(trim(value), '') AS DOUBLE) AS value,
                 row_number() OVER (PARTITION BY trim(id), trim(t) ORDER BY list_position([%s], filename)) AS k
          FROM %s WHERE trim(param) = 'Discharge' AND nullif(trim(value), '') IS NOT NULL)
    WHERE k = 1 AND NOT isnan(value)", files, src)))
  units <- DBI::dbGetQuery(con, "SELECT DISTINCT unit FROM raw")$unit
  if (!all(units %in% c("l/s", "m^3/s"))) {
    stop("a provincial discharge value has a unit other than l/s or m^3/s: ",
         paste(setdiff(units, c("l/s", "m^3/s")), collapse = ", "), call. = FALSE)
  }
  invisible(DBI::dbExecute(con, "
    CREATE TEMP TABLE h AS
    SELECT id, name, status, lat, lon, t, grade,
           CASE WHEN unit = 'l/s' THEN value / 1000 ELSE value END AS value
    FROM raw"))
  invisible(DBI::dbExecute(con, "DROP TABLE raw"))
  invisible(con)
}

# A copy of a provincial file with byte 0x96 made "-".
wet_bcenv_dash <- function(path) {
  out <- tempfile(fileext = ".csv")
  i <- file(path, "rb")
  on.exit(close(i), add = TRUE)
  o <- file(out, "wb")
  on.exit(close(o), add = TRUE)
  while (length(b <- readBin(i, "raw", 64e6))) {
    b[b == as.raw(0x96)] <- as.raw(0x2d)
    writeBin(b, o)
  }
  out
}

# Lines in a file: newline bytes, plus a last line that has none.
wet_bcenv_lines <- function(f) {
  con <- file(f, "rb")
  on.exit(close(con))
  n <- 0
  last <- as.raw(10)
  while (length(b <- readBin(con, "raw", 64e6))) {
    n <- n + sum(b == as.raw(10))
    last <- b[length(b)]
  }
  n + (last != as.raw(10))
}
