#' Daily flow at hydrometric stations, from HYDAT through to the present
#'
#' One daily discharge series per station. Approved HYDAT flows come first;
#' after HYDAT's last approved day, ECCC provisional daily means fill in, and
#' the real-time feed covers the days since. Each day keeps the source it came
#' from and its HYDAT symbol, so a result built on the series can say what it
#' rests on (ice-affected winter flows are estimates).
#'
#' Stations of the province's non-integrated hydrometric network (numbers such
#' as `"08EE0001"`, listed by [wet_station_list()]) are read from a pinned
#' snapshot of the province's hourly files instead. Such a station keeps its
#' own number: where it sits at a HYDAT station's site, the two records are not
#' joined, and [wet_station_list()] names the HYDAT station so a caller can.
#'
#' The third-party gauges the BC Water Tool serves (regional districts,
#' industry, BC Hydro, research projects; numbers such as `"HRB3142"` or
#' `"ogc_1002"`, listed by [wet_station_list()]) are read from a pinned
#' snapshot of the Tool's daily files. Where such a gauge sits at a provincial
#' station's site, its record continues the provincial one instead: its days
#' before the provincial record begins (the first day the province's files hold
#' any hour of the station) come back under the provincial number, with
#' `source` `"bcwatertool"`, and none from that day on. Each provincial
#' and Tool station's regulation, natural, regulated or unknown, is
#' [wet_station_list()]'s `regulation`.
#'
#' Ported from `ngr::ngr_hyd_q_daily()`, which joined HYDAT with about 18
#' months of real-time flow.
#'
#' @param stations Character vector of station numbers: HYDAT's
#'   (`"08EE013"`), the provincial network's (`"08EE0001"`) or a Water Tool
#'   gauge's (`"HRB3142"`), mixed freely.
#' @inheritParams wet_station_select
#' @param from,to Optional first and last date (a `Date` or a string
#'   `as.Date()` reads). `NULL` means no bound.
#' @param sources Which sources to read, from `"hydat"`, `"provisional"`,
#'   `"realtime"`, `"bcenv"` and `"bcwatertool"`. The first three read HYDAT-numbered stations
#'   only, and each continues the one before it, per station, from
#'   that source's last day over its whole record: provisional days are used
#'   only after HYDAT's last day, and real-time days only after both, whatever
#'   `from` and `to` are. `"provisional"` reads the water-temp-bc archive of ECCC daily means
#'   (option `wet.provisional_root`, default
#'   `s3://water-temp-bc/data/canonical/Parameter=6/`) with duckdb, and
#'   `"realtime"` calls [tidyhydat::realtime_ws()] for the days after the
#'   other sources end (at most about 18 months back). `"bcenv"` reads the
#'   provincial network's stations named in `snapshot`'s station registry,
#'   from the province's hourly files (Open Government Licence - British
#'   Columbia), with duckdb: a day is a local-standard-time day with at least
#'   20 hours, hours graded Unusable left out, and a day above a plausibility
#'   bound measured on HYDAT dropped. `"bcwatertool"` reads the Water Tool's
#'   third-party gauges from a pinned snapshot of its daily files (the terms
#'   each publisher's file states, given as `credit` by [wet_station_list()]):
#'   a day as the Tool gives it, a day above the same bound (its sub-drainage
#'   taken from the nearest HYDAT station) dropped; and the days of a Tool gauge
#'   at a provincial station's site before that station's record begins, under
#'   the provincial number. A station's own source comes first, and a second
#'   publisher's gauge at its site only for the days before it.
#' @param snapshot The provincial snapshot to read, as `YYYYMMDD`; each pinned
#'   snapshot's files are held to md5s tracked in the package. Read only for
#'   stations that are not HYDAT-numbered. The Water Tool's snapshot is the one
#'   the package pins; a number both its registry and `snapshot`'s hold is
#'   refused.
#' @return `data.frame(station_number, date, q_m3s, symbol, source, status)`,
#'   one row per station-day that has a flow, ordered by station and date.
#'   `symbol` is HYDAT's daily symbol (`"B"` ice, `"E"` estimated, `"A"`
#'   partial day, `"D"` dry) or `NA`. `status` is `"approved"` for HYDAT and
#'   for an ECCC day whose approval says final, and `"provisional"` for any
#'   other ECCC day. A provincial day is `"provisional"` when every hour in it
#'   carries a grade and `"unchecked"` when any hour is graded Undefined or
#'   Unspecified: the province's files carry no approval, so none is
#'   `"approved"`. A Water Tool day is `"provisional"` where the Tool marks it
#'   quality checked and `"unchecked"` where it does not. Provisional,
#'   provincial and Tool days carry no ice symbol, so their `NA` means "not
#'   recorded", not "open water".
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
#'
#' # Deep Creek, a provincial station near Smithers
#' d <- wet_station_daily("08EE0001")
#' table(d$source, d$status)
#'
#' # Rosewall Creek on Vancouver Island: the province's years from 2021, and
#' # BC Conservation Foundation's 2012-2015 gauge at the site before them
#' r <- wet_station_daily("08HB0008")
#' table(format(r$date, "%Y"), r$source)
#' }
#' @export
wet_station_daily <- function(stations, hydat = wet_hydat_path(), from = NULL, to = Sys.Date(),
                              sources = c("hydat", "provisional", "realtime", "bcenv", "bcwatertool"),
                              snapshot = wet_bcenv_snapshot) {
  if (!is.character(stations) || !length(stations) || anyNA(stations)) {
    stop("`stations` must be a non-empty character vector of station numbers", call. = FALSE)
  }
  bad <- setdiff(sources, c("hydat", "provisional", "realtime", "bcenv", "bcwatertool"))
  if (!length(sources) || length(bad)) {
    stop("`sources` must be some of \"hydat\", \"provisional\", \"realtime\", \"bcenv\", \"bcwatertool\"",
         call. = FALSE)
  }
  # numeric as.Date() needs an origin before R 4.3
  from <- if (is.null(from)) as.Date(-Inf, origin = "1970-01-01") else as.Date(from)
  to <- if (is.null(to)) as.Date(Inf, origin = "1970-01-01") else as.Date(to)
  if (from > to) stop("`from` is after `to`", call. = FALSE)
  stations <- unique(stations)
  # the federal sources read HYDAT-numbered stations; any other number is looked up in the
  # provincial snapshot's registry and the Water Tool's, which a call with HYDAT numbers
  # alone never opens
  federal <- stations[grepl(wet_hydat_number, stations)]
  other <- setdiff(stations, federal)

  # The readers return each source's whole record for the stations. Where one
  # source ends, where the next continues, and the gaps between them are all
  # taken from those rows; from/to trims only the result. A provisional flow
  # therefore never fills a hole inside HYDAT's approved record, which ECCC
  # chose not to publish, whatever window is asked for.
  out <- wet_daily_empty()
  if ("hydat" %in% sources && length(federal)) {
    out <- wet_daily_try("hydat", wet_hydat_daily(hydat, federal))
  }
  if ("provisional" %in% sources && length(federal)) {
    pv <- wet_daily_try("provisional", wet_provisional_daily(federal))
    out <- rbind(out, wet_daily_after(pv, out))
  }
  if ("realtime" %in% sources && length(federal)) {
    # today's daily mean is still accumulating
    end <- min(to, Sys.Date() - 1)
    rt <- lapply(federal, function(st) {
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
  if ("bcenv" %in% sources && length(other)) {
    out <- rbind(out, wet_daily_try("bcenv", {
      ids <- intersect(other, wet_bcenv_stations(snapshot)$station_number)
      if (length(ids)) wet_bcenv_daily(ids, snapshot) else wet_daily_empty()
    }))
  }
  if ("bcwatertool" %in% sources && length(other)) {
    out <- rbind(out, wet_daily_try("bcwatertool", wet_bcwatertool_station_days(other, snapshot)))
  }
  # each source takes only days the ones before it lack; a station-day given twice means two of them disagree
  # about where a record ends, and a statistic over the series would count that day twice
  twice <- duplicated(out[c("station_number", "date")])
  if (any(twice)) {
    stop("two sources give one station-day, such as ", out$station_number[twice][1], " on ", out$date[twice][1],
         " (", paste(out$source[out$station_number == out$station_number[twice][1] &
                                  out$date == out$date[twice][1]], collapse = ", "), ")", call. = FALSE)
  }
  out <- out[order(out$station_number, out$date), ]
  wet_daily_gaps(out, from, to)
  out <- out[out$date >= from & out$date <= to, ]
  rownames(out) <- NULL
  none <- setdiff(stations, out$station_number)
  if (length(none)) warning("no flow found for: ", paste(none, collapse = ", "), call. = FALSE)
  out
}

# The Water Tool's days for the non-HYDAT numbers asked: a Tool station's own
# under its number, and a provincial station's continuing listing's days
# before the first day the provincial files hold any usable hour of it (the
# Tool registry's `continues_before`, complete day or not, so a listing that
# is the same gauge never stands in for the province's own partial days; all
# of them where the files hold none), under the provincial number. The cut
# comes from the registry, not from the rows read, so it is the same
# whichever sources are asked.
wet_bcwatertool_station_days <- function(stations, snapshot) {
  tool <- wet_bcwatertool_against(wet_bcwatertool_stations(), snapshot)
  prov <- wet_bcenv_stations(snapshot)
  wet_registry_check(tool, prov, snapshot)
  own <- tool$station_number[is.na(tool$continues) & tool$station_number %in% stations]
  cont <- tool[!is.na(tool$continues) & tool$continues %in% intersect(stations, prov$station_number), ]
  if (!length(own) && !nrow(cont)) return(wet_daily_empty())
  d <- wet_bcwatertool_daily(c(own, cont$station_number))
  k <- match(d$station_number, cont$station_number)
  cut <- cont$continues_before[k]
  keep <- is.na(k) | is.na(cut) | d$date < cut
  d$station_number[!is.na(k)] <- cont$continues[k[!is.na(k)]]
  d <- d[keep, ]
  rownames(d) <- NULL
  d
}

# No number may be both a Water Tool station and a provincial one.
wet_registry_check <- function(tool, prov, snapshot) {
  both <- intersect(tool$station_number, prov$station_number)
  if (length(both)) {
    stop(structure(class = c("wet_registry_conflict", "error", "condition"), list(
      message = paste0("the Water Tool's station registry and the provincial snapshot ", snapshot,
                       "'s both hold ", paste(both, collapse = ", ")), call = NULL)))
  }
  invisible()
}

# A HYDAT station number: two digits, two letters, three digits.
wet_hydat_number <- "^[0-9]{2}[A-Z]{2}[0-9]{3}$"

# Rows of `x` dated after the last day `prior` holds for the same station.
# `prior` is always a whole record, never a from/to window of one.
wet_daily_after <- function(x, prior) {
  if (!nrow(x) || !nrow(prior)) return(x)
  last <- vapply(split(as.numeric(prior$date), prior$station_number), max, 0)
  cut <- unname(last[x$station_number])
  x[is.na(cut) | as.numeric(x$date) > cut, ]
}

# A failing source is skipped, not fatal: the others are still worth returning.
# Two registries claiming one number is a broken package, not a failing source.
# tryCatch() nests its handlers, so the conflict is recorded and raised after it returns.
wet_daily_try <- function(source, expr) {
  conflict <- NULL
  out <- tryCatch(expr, wet_registry_conflict = function(e) {
    conflict <<- e
    NULL
  }, error = function(e) {
    warning("source \"", source, "\" skipped: ", conditionMessage(e), call. = FALSE)
    wet_daily_empty()
  })
  if (!is.null(conflict)) stop(conflict)
  out
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
