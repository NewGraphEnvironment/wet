#' Daily water temperature at hydrometric stations
#'
#' One daily water-temperature series per station, from the ECCC readings that
#' water-temp-bc archives (about 300 BC stations, mostly hourly, from 2002).
#' Readings are reduced to a daily mean, minimum and maximum in the station's
#' local standard time. The result has the shape of [wet_station_daily()], so
#' it feeds [wet_window_stats()] with `value = "t_mean_c"` (or `t_min_c`,
#' `t_max_c`), `level_anomaly = "absolute"` and `unit = "degC"`, and from there
#' `cd::cd_baseline()`, `cd::cd_anomaly()` and `cd::cd_trend()`.
#'
#' @section How readings become days:
#' \enumerate{
#'   \item Readings outside `valid` are dropped: ECCC's sentinels (`99999`,
#'     `999`, `99.9`, `-99999`) and readings of a sensor in air or ice. A
#'     range cannot catch a logger out of the water in summer, when air and
#'     water temperatures overlap.
#'   \item Each reading is placed in its hour and day of local standard time
#'     (no daylight saving), from the station's offset in
#'     `tidyhydat::allstations` (UTC-8 for most BC stations, UTC-7 for the
#'     Peace and parts of the Kootenays). A station that table does not list
#'     is taken as UTC-8, with a warning. UTC days would split the afternoon
#'     maximum, which falls near 00:00 UTC.
#'   \item Readings are averaged within each hour, and `t_mean_c` is the mean
#'     of those hourly means, so a 15-minute hour does not outweigh an hourly
#'     one. `t_min_c` and `t_max_c` are over the readings themselves.
#'   \item A day is kept only when it has readings in at least `min_hours` of
#'     its 24 hours. Short days are dropped, not filled; `n_hours` is
#'     returned so a caller can be stricter.
#' }
#'
#' @section Baseline:
#' Year-round records are short: few stations have most of their days in
#' most years of any decade before the 2010s. A temperature departure is
#' therefore taken against the recent decade, 2016-2025, never 1981-2010, and
#' has to say so beside any flow departure on 1981-2010. The station counts
#' behind that are in `research/station_water_temperature.md`.
#'
#' @section With wet_window_stats():
#' Pass `stats` explicitly. `frac_below` needs a threshold in degrees C, and
#' `cov_day` (when half a window's total has passed) means nothing for a
#' temperature. One call takes one value column, so a window's highest daily
#' maximum is a second call on `t_max_c`.
#'
#' @inheritParams wet_station_daily
#' @param valid Plausible range of a reading, in degrees C, both ends kept.
#' @param min_hours Hours of the day (1 to 24) that must have a valid reading
#'   for the day to count.
#' @return `data.frame(station_number, date, t_mean_c, t_min_c, t_max_c,
#'   n_hours, source, status)`, one row per station-day kept, ordered by
#'   station and date: the shape of [wet_station_daily()] with temperature
#'   columns in place of `q_m3s`, and no `symbol`. There is no ice flag, so
#'   [wet_window_stats()] reports `frac_ice` as `NA`, unknown, not zero.
#'   `source` is `"provisional"`, the water-temp-bc archive, as in
#'   [wet_station_daily()]. `status` is `"approved"` only when every reading
#'   that day is final. No reading in the archive was final on 2026-10-06:
#'   its approvals are ECCC's codes `1` and `4`, whose meanings were never
#'   published with the dump and are treated as provisional, none, or
#'   `Provisional/Provisoire`. The archive is read from option
#'   `wet.temp_root` (default `s3://water-temp-bc/data/canonical/Parameter=5/`)
#'   with duckdb.
#' @examples
#' \dontrun{
#' # Buck Creek at the mouth, since 2016
#' t <- wet_temp_daily("08EE013", from = "2016-01-01")
#' summary(t$t_max_c)
#'
#' # Over the Chinook spawning window, one value per year: the mean of daily
#' # means, and the highest daily maximum
#' w <- data.frame(window = "ch_spawning", start = "08-01", end = "09-15")
#' s <- rbind(
#'   wet_window_stats(t, w, stats = "mean", value = "t_mean_c", prefix = "t",
#'                    level_anomaly = "absolute", unit = "degC"),
#'   wet_window_stats(t, w, stats = "max", value = "t_max_c", prefix = "tmax",
#'                    level_anomaly = "absolute", unit = "degC"))
#'
#' # Departure in degrees C from 2016-2025, one series per cd call
#' m <- s[s$variable == "t_mean", ]
#' cd::cd_anomaly(m, cd::cd_baseline(m, 2016:2025))
#' }
#' @export
wet_temp_daily <- function(stations, from = NULL, to = Sys.Date(), valid = c(-1, 35),
                           min_hours = 20) {
  if (!is.character(stations) || !length(stations) || anyNA(stations)) {
    stop("`stations` must be a non-empty character vector of station numbers", call. = FALSE)
  }
  if (!is.numeric(valid) || length(valid) != 2 || !all(is.finite(valid)) || valid[1] >= valid[2]) {
    stop("`valid` must be two increasing finite numbers, the lowest and highest plausible reading",
         call. = FALSE)
  }
  if (!is.numeric(min_hours) || length(min_hours) != 1 || is.na(min_hours) ||
        min_hours != round(min_hours) || min_hours < 1 || min_hours > 24) {
    stop("`min_hours` must be a whole number from 1 to 24", call. = FALSE)
  }
  # numeric as.Date() needs an origin before R 4.3
  from <- if (is.null(from)) as.Date(-Inf, origin = "1970-01-01") else as.Date(from)
  to <- if (is.null(to)) as.Date(Inf, origin = "1970-01-01") else as.Date(to)
  if (from > to) stop("`from` is after `to`", call. = FALSE)
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to read water temperature", call. = FALSE)
  }
  stations <- unique(stations)
  offset <- wet_temp_offsets(stations)
  no_tz <- stations[is.na(offset)]
  offset[is.na(offset)] <- -8

  root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (startsWith(root, "s3://")) {
    # the bucket is public: an explicit keyless secret keeps any AWS
    # credentials in the environment from being sent with the request
    DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
    DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
  }
  duckdb::duckdb_register(con, "wet_offset",
                          data.frame(station_number = stations, offset_s = as.integer(offset * 3600)))
  # Local standard time as whole seconds from the epoch; days count from
  # 1970-01-01, which as.Date() reads. epoch_ms() needs no time-zone extension.
  # epoch() on a TIMESTAMPTZ autoloads icu, and in duckdb-r 1.5.2 and 1.5.6 the
  # query that autoloads it can fail to bind `+`, return a wrong sum or abort R.
  # The archive starts in 2002, so // never meets a negative.
  bound <- c(if (is.finite(from)) sprintf("dd >= %d", as.integer(from)),
             if (is.finite(to)) sprintf("dd <= %d", as.integer(to)))
  d <- DBI::dbGetQuery(con, sprintf(
    "WITH r AS (
       SELECT p.STATION_NUMBER AS station_number, epoch_ms(p.Date) // 1000 + o.offset_s AS sec,
              p.Value AS v, coalesce(regexp_matches(p.Approval, %s), false) AS final
       FROM read_parquet(%s) AS p JOIN wet_offset AS o ON p.STATION_NUMBER = o.station_number
       WHERE p.STATION_NUMBER IN (%s) AND p.Value BETWEEN %s AND %s
     ), h AS (
       SELECT station_number, CAST(sec // 86400 AS INTEGER) AS dd,
              sec // 3600 AS hh, avg(v) AS v_mean, min(v) AS v_min,
              max(v) AS v_max, bool_and(final) AS final
       FROM r GROUP BY ALL
     )
     SELECT station_number, dd, avg(v_mean) AS t_mean_c, min(v_min) AS t_min_c,
            max(v_max) AS t_max_c, CAST(count(*) AS INTEGER) AS n_hours, bool_and(final) AS final
     FROM h %s GROUP BY station_number, dd HAVING count(*) >= %d
     ORDER BY station_number, dd",
    DBI::dbQuoteString(con, wet_approval_final),
    DBI::dbQuoteString(con, paste0(sub("/?$", "/", root), "*.parquet")),
    paste(DBI::dbQuoteString(con, stations), collapse = ", "),
    wet_sql_num(valid[1]), wet_sql_num(valid[2]),
    if (length(bound)) paste("WHERE", paste(bound, collapse = " AND ")) else "",
    as.integer(min_hours)))

  no_tz <- intersect(no_tz, d$station_number)
  if (length(no_tz)) {
    warning("no time zone for: ", paste(no_tz, collapse = ", "), "; taken as UTC-8", call. = FALSE)
  }
  none <- setdiff(stations, d$station_number)
  if (length(none)) {
    warning("no water temperature found for: ", paste(none, collapse = ", "), call. = FALSE)
  }
  # data.frame() cannot recycle the scalar source onto zero rows
  source <- rep("provisional", nrow(d))
  data.frame(station_number = as.character(d$station_number),
             date = as.Date(as.numeric(d$dd), origin = "1970-01-01"),
             t_mean_c = as.numeric(d$t_mean_c), t_min_c = as.numeric(d$t_min_c),
             t_max_c = as.numeric(d$t_max_c), n_hours = as.integer(d$n_hours), source = source,
             status = c("provisional", "approved")[d$final + 1])
}

# Hours from UTC to each station's local standard time, NA where unknown.
wet_temp_offsets <- function(stations) {
  if (!requireNamespace("tidyhydat", quietly = TRUE)) {
    stop("install tidyhydat for station time zones", call. = FALSE)
  }
  a <- tidyhydat::allstations
  as.numeric(a$standard_offset[match(stations, a$STATION_NUMBER)])
}

# A finite number as a SQL literal. sprintf()'s %g ignores options(OutDec),
# which format(), as.character() and %s follow; Inf and NA have no literal.
wet_sql_num <- function(x) {
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x)) {
    stop("a SQL number must be one finite value", call. = FALSE)
  }
  sprintf("%.15g", x)
}
