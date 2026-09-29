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
#'   `"realtime"`.
#' @return `data.frame(station_number, date, q_m3s, symbol, source, status)`,
#'   one row per station-day that has a flow, ordered by station and date.
#'   `symbol` is HYDAT's daily symbol (`"B"` ice, `"E"` estimated, `"A"`
#'   partial day, `"D"` dry) or `NA`; `status` is `"approved"` or
#'   `"provisional"`.
#' @examples
#' \dontrun{
#' # Buck Creek at the mouth, approved HYDAT only
#' q <- wet_station_daily("08EE013", sources = "hydat")
#' table(q$symbol, useNA = "ifany")
#' }
#' @export
wet_station_daily <- function(stations, hydat = wet_hydat_path(), from = NULL, to = Sys.Date(),
                              sources = "hydat") {
  if (!is.character(stations) || !length(stations) || anyNA(stations)) {
    stop("`stations` must be a non-empty character vector of station numbers", call. = FALSE)
  }
  bad <- setdiff(sources, c("hydat", "provisional", "realtime"))
  if (!length(sources) || length(bad)) {
    stop("`sources` must be some of \"hydat\", \"provisional\", \"realtime\"", call. = FALSE)
  }
  from <- if (is.null(from)) as.Date(-Inf) else as.Date(from)
  to <- if (is.null(to)) as.Date(Inf) else as.Date(to)
  if (from > to) stop("`from` is after `to`", call. = FALSE)
  stations <- unique(stations)

  out <- wet_daily_empty()
  if ("hydat" %in% sources) out <- rbind(out, wet_hydat_daily(hydat, stations, from, to))
  out <- out[order(out$station_number, out$date), ]
  rownames(out) <- NULL
  out
}

wet_daily_empty <- function() {
  data.frame(station_number = character(), date = as.Date(character()), q_m3s = numeric(),
             symbol = character(), source = character(), status = character())
}

# DLY_FLOWS holds one row per station-month with FLOW1..31 and FLOW_SYMBOL1..31.
# Days past the end of a month are NULL there, and so are missing days: both
# are dropped rather than returned as NA.
wet_hydat_daily <- function(hydat, stations, from, to) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  yrs <- c(if (is.finite(from)) as.integer(format(from, "%Y")) else -9999L,
           if (is.finite(to)) as.integer(format(to, "%Y")) else 9999L)
  d <- DBI::dbGetQuery(con, sprintf(
    "SELECT STATION_NUMBER station_number, YEAR year, MONTH month, %s, %s FROM DLY_FLOWS
     WHERE STATION_NUMBER IN (%s) AND YEAR BETWEEN %d AND %d",
    paste(sprintf("FLOW%d", 1:31), collapse = ", "),
    paste(sprintf("FLOW_SYMBOL%d", 1:31), collapse = ", "),
    paste(DBI::dbQuoteString(con, stations), collapse = ", "), yrs[1], yrs[2]))
  if (!nrow(d)) return(wet_daily_empty())
  q <- as.vector(t(as.matrix(d[sprintf("FLOW%d", 1:31)])))
  s <- as.vector(t(as.matrix(d[sprintf("FLOW_SYMBOL%d", 1:31)])))
  n <- nrow(d)
  date <- as.Date(sprintf("%04d-%02d-%02d", rep(d$year, each = 31), rep(d$month, each = 31),
                          rep(1:31, n)), optional = TRUE)
  keep <- !is.na(q) & !is.na(date) & date >= from & date <= to
  data.frame(station_number = rep(d$station_number, each = 31)[keep], date = date[keep],
             q_m3s = as.numeric(q[keep]), symbol = as.character(s[keep]), source = "hydat",
             status = "approved")
}
