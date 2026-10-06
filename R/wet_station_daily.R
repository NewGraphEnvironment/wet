#' Daily flow at hydrometric stations, from HYDAT through to the present
#'
#' One daily discharge series per station. Approved HYDAT flows come first;
#' after HYDAT's last approved day, ECCC provisional daily means fill in, and
#' the real-time feed covers the days since. Each day keeps the source it came
#' from and its HYDAT symbol, so a result built on the series can say what it
#' rests on (ice-affected winter flows are estimates).
#'
#' Ported from `ngr::ngr_hyd_q_daily()`, which joined HYDAT with about 18
#' months of real-time flow.
#'
#' @param stations Character vector of station numbers.
#' @inheritParams wet_station_select
#' @param from,to Optional first and last date (a `Date` or a string
#'   `as.Date()` reads). `NULL` means no bound.
#' @param sources Which sources to read, from `"hydat"`, `"provisional"` and
#'   `"realtime"`. Each source continues the one before it, per station, from
#'   that source's last day over its whole record: provisional days are used
#'   only after HYDAT's last day, and real-time days only after both, whatever
#'   `from` and `to` are. `"provisional"` reads the water-temp-bc archive of ECCC daily means
#'   (option `wet.provisional_root`, default
#'   `s3://water-temp-bc/data/canonical/Parameter=6/`) with duckdb, and
#'   `"realtime"` calls [tidyhydat::realtime_ws()] for the days after the
#'   other sources end (at most about 18 months back).
#' @return `data.frame(station_number, date, q_m3s, symbol, source, status)`,
#'   one row per station-day that has a flow, ordered by station and date.
#'   `symbol` is HYDAT's daily symbol (`"B"` ice, `"E"` estimated, `"A"`
#'   partial day, `"D"` dry) or `NA`; `status` is `"approved"` or
#'   `"provisional"` (any ECCC approval other than final counts as
#'   provisional). Provisional days carry no ice symbol, so their `NA` means
#'   "not recorded", not "open water".
#'
#'   A gap between the end of one source and the start of the next (for
#'   example an old HYDAT ending before the provisional archive begins) is
#'   left unfilled and reported with a warning when it overlaps `from`-`to`. A source that fails is skipped
#'   with a warning and the others are returned.
#' @examples
#' \dontrun{
#' # Buck Creek at the mouth, from the start of its record to last week
#' q <- wet_station_daily("08EE013")
#' table(q$source, q$status)
#' }
#' @export
wet_station_daily <- function(stations, hydat = wet_hydat_path(), from = NULL, to = Sys.Date(),
                              sources = c("hydat", "provisional", "realtime")) {
  if (!is.character(stations) || !length(stations) || anyNA(stations)) {
    stop("`stations` must be a non-empty character vector of station numbers", call. = FALSE)
  }
  bad <- setdiff(sources, c("hydat", "provisional", "realtime"))
  if (!length(sources) || length(bad)) {
    stop("`sources` must be some of \"hydat\", \"provisional\", \"realtime\"", call. = FALSE)
  }
  # numeric as.Date() needs an origin before R 4.3
  from <- if (is.null(from)) as.Date(-Inf, origin = "1970-01-01") else as.Date(from)
  to <- if (is.null(to)) as.Date(Inf, origin = "1970-01-01") else as.Date(to)
  if (from > to) stop("`from` is after `to`", call. = FALSE)
  stations <- unique(stations)

  # The readers return each source's whole record for the stations. Where one
  # source ends, where the next continues, and the gaps between them are all
  # taken from those rows; from/to trims only the result. A provisional flow
  # therefore never fills a hole inside HYDAT's approved record, which ECCC
  # chose not to publish, whatever window is asked for.
  out <- wet_daily_empty()
  if ("hydat" %in% sources) {
    out <- wet_daily_try("hydat", wet_hydat_daily(hydat, stations))
  }
  if ("provisional" %in% sources) {
    pv <- wet_daily_try("provisional", wet_provisional_daily(stations))
    out <- rbind(out, wet_daily_after(pv, out))
  }
  if ("realtime" %in% sources) {
    # today's daily mean is still accumulating
    end <- min(to, Sys.Date() - 1)
    rt <- lapply(stations, function(st) {
      have <- out$date[out$station_number == st]
      # the feed's whole reachable record, not from `from`: gaps are read from
      # whole records, and the final trim applies from/to. c() dispatches on
      # its first argument, so it must be a Date, never NULL
      start <- max(c(Sys.Date() - 540, if (length(have)) max(have) + 1))
      if (start > end) return(NULL)
      wet_daily_try("realtime", wet_realtime_daily(st, start, end))
    })
    rt <- do.call(rbind, c(list(wet_daily_empty()), rt))
    out <- rbind(out, wet_daily_after(rt, out))
  }
  out <- out[order(out$station_number, out$date), ]
  wet_daily_gaps(out, from, to)
  out <- out[out$date >= from & out$date <= to, ]
  rownames(out) <- NULL
  none <- setdiff(stations, out$station_number)
  if (length(none)) warning("no flow found for: ", paste(none, collapse = ", "), call. = FALSE)
  out
}

# Rows of `x` dated after the last day `prior` holds for the same station.
# `prior` is always a whole record, never a from/to window of one.
wet_daily_after <- function(x, prior) {
  if (!nrow(x) || !nrow(prior)) return(x)
  last <- vapply(split(as.numeric(prior$date), prior$station_number), max, 0)
  cut <- unname(last[x$station_number])
  x[is.na(cut) | as.numeric(x$date) > cut, ]
}

# A failing source is skipped, not fatal: the others are still worth returning.
wet_daily_try <- function(source, expr) {
  tryCatch(expr, error = function(e) {
    warning("source \"", source, "\" skipped: ", conditionMessage(e), call. = FALSE)
    wet_daily_empty()
  })
}

# Warn where one source ends and the next starts more than a day later, when
# that gap overlaps from-to. `d` is the whole joined record, sorted. Holes
# inside a single source (a seasonal gauge's winters) are part of the record.
wet_daily_gaps <- function(d, from, to) {
  if (nrow(d) < 2) return(invisible())
  n <- nrow(d)
  i <- which(d$station_number[-1] == d$station_number[-n] & d$source[-1] != d$source[-n] &
               as.numeric(d$date[-1] - d$date[-n]) > 1)
  i <- i[d$date[i] + 1 <= to & d$date[i + 1] - 1 >= from]
  if (length(i)) {
    warning("gap between sources, left unfilled: ",
            paste(sprintf("%s %s to %s (%s -> %s)", d$station_number[i], d$date[i] + 1,
                          d$date[i + 1] - 1, d$source[i], d$source[i + 1]), collapse = "; "),
            call. = FALSE)
  }
  invisible()
}

wet_daily_empty <- function() {
  data.frame(station_number = character(), date = as.Date(character()), q_m3s = numeric(),
             symbol = character(), source = character(), status = character())
}

# DLY_FLOWS holds one row per station-month with FLOW1..31 and FLOW_SYMBOL1..31.
# Days past the end of a month are NULL there, and so are missing days: both
# are dropped rather than returned as NA. The whole record is read: a station
# has at most about 1,200 station-months.
wet_hydat_daily <- function(hydat, stations) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  d <- DBI::dbGetQuery(con, sprintf(
    "SELECT STATION_NUMBER station_number, YEAR year, MONTH month, %s, %s FROM DLY_FLOWS
     WHERE STATION_NUMBER IN (%s)",
    paste(sprintf("FLOW%d", 1:31), collapse = ", "),
    paste(sprintf("FLOW_SYMBOL%d", 1:31), collapse = ", "),
    paste(DBI::dbQuoteString(con, stations), collapse = ", ")))
  if (!nrow(d)) return(wet_daily_empty())
  q <- as.vector(t(as.matrix(d[sprintf("FLOW%d", 1:31)])))
  s <- as.vector(t(as.matrix(d[sprintf("FLOW_SYMBOL%d", 1:31)])))
  n <- nrow(d)
  date <- as.Date(sprintf("%04d-%02d-%02d", rep(d$year, each = 31), rep(d$month, each = 31),
                          rep(1:31, n)), optional = TRUE)
  keep <- !is.na(q) & !is.na(date)
  # data.frame() cannot recycle the scalar source onto zero rows
  if (!any(keep)) return(wet_daily_empty())
  data.frame(station_number = rep(d$station_number, each = 31)[keep], date = date[keep],
             q_m3s = as.numeric(q[keep]), symbol = as.character(s[keep]), source = "hydat",
             status = "approved")
}

# ECCC daily means archived monthly by water-temp-bc: the whole archive for the
# stations. Timestamps are 08:00 UTC, local midnight, so the UTC calendar date
# is the day the mean describes.
wet_provisional_daily <- function(stations) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to read provisional flows", call. = FALSE)
  }
  root <- getOption("wet.provisional_root", "s3://water-temp-bc/data/canonical/Parameter=6/")
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (startsWith(root, "s3://")) {
    # the bucket is public: an explicit keyless secret keeps any AWS
    # credentials in the environment from being sent with the request
    DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
    DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
  }
  d <- DBI::dbGetQuery(con, sprintf(
    "SELECT STATION_NUMBER station_number, Date date, Value q_m3s, Symbol symbol, Approval approval
     FROM read_parquet(%s) WHERE STATION_NUMBER IN (%s) AND Value IS NOT NULL",
    DBI::dbQuoteString(con, paste0(sub("/?$", "/", root), "*.parquet")),
    paste(DBI::dbQuoteString(con, stations), collapse = ", ")))
  wet_eccc_daily(d, "provisional")
}

# The last days, from ECCC's real-time web service.
wet_realtime_daily <- function(station, from, to) {
  if (!requireNamespace("tidyhydat", quietly = TRUE)) {
    stop("install tidyhydat to read real-time flows", call. = FALSE)
  }
  d <- tidyhydat::realtime_ws(station_number = station, parameters = 6, start_date = from,
                              end_date = to)
  d <- data.frame(station_number = d$STATION_NUMBER, date = d$Date, q_m3s = d$Value,
                  symbol = d$Symbol, approval = d$Approval)
  d <- wet_eccc_daily(d[!is.na(d$q_m3s), ], "realtime")
  d[d$date >= from & d$date <= to, ]
}

# An ECCC approval that says final. Also matched in SQL by wet_temp_daily().
wet_approval_final <- "^(Final|Approved)"

# Shared shaping for the two ECCC feeds. Only an approval that says final is
# "approved"; anything else, unrecognised included, stays provisional.
wet_eccc_daily <- function(d, source) {
  if (!nrow(d)) return(wet_daily_empty())
  data.frame(station_number = as.character(d$station_number), date = as.Date(d$date, tz = "UTC"),
             q_m3s = as.numeric(d$q_m3s), symbol = as.character(d$symbol), source = source,
             status = ifelse(grepl(wet_approval_final, d$approval), "approved", "provisional"))
}
