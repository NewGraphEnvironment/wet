#' Observed day-of-year flow climatology at HYDAT stations
#'
#' For each station, the mean daily flow on each day of a 365-day common year
#' over its complete years, the same years [wet_station_monthly()] uses, so
#' the daily and monthly climatologies describe one record. 29 February is
#' folded into 28 February: in a leap year the two days are averaged before
#' the years are. A day with no value in any complete year (at most 11 days a
#' month can be missing in a complete year) is filled by linear interpolation
#' from its neighbours around the year, and counted in the `"filled"`
#' attribute. `share` is the day's part of the year's volume, so the 365
#' shares sum to 1.
#'
#' @param stations Output of [wet_station_select()], or any data frame with a
#'   `station_number` column when `years` is given.
#' @param years Named list, by station, of the complete years to average
#'   over; by default the `"years"` attribute [wet_station_select()] sets.
#' @inheritParams wet_station_select
#' @return `data.frame(station_number, doy, q_m3s, share, n_years)`, 365 rows
#'   per station, with attribute `"filled"`: a data frame of the
#'   `station_number, doy` pairs that were interpolated (zero rows when none).
#' @examples
#' \dontrun{
#' # a HYDAT release pinned through wet's cache (see wet:::wet_hydat)
#' h <- wet:::wet_hydat("20260717")
#' s <- wet_station_select(h)
#' d <- wet_station_doy(s[s$station_number == "08EE013", ], h,
#'                      years = attr(s, "years")["08EE013"])
#' # a month's days average to its monthly mean, February aside (28 vs 28.25 days)
#' tapply(d$q_m3s, wet:::wet_doy_month(), mean)
#' }
#' @export
wet_station_doy <- function(stations, hydat = wet_hydat_path(), years = attr(stations, "years"),
                            min_days = 20) {
  empty <- data.frame(station_number = character(), doy = integer(), q_m3s = numeric(),
                      share = numeric(), n_years = integer())
  filled <- data.frame(station_number = character(), doy = integer())
  if (!nrow(stations)) return(structure(empty, filled = filled))
  if (is.null(years) || !all(stations$station_number %in% names(years))) {
    stop("`years` must name the complete years of every station: the \"years\" attribute from ",
         "wet_station_select(), or a named list", call. = FALSE)
  }
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  sql <- "SELECT STATION_NUMBER station_number, YEAR year, MONTH month, %s FROM DLY_FLOWS WHERE STATION_NUMBER IN (%s)"
  d <- DBI::dbGetQuery(con, sprintf(sql, paste(sprintf("FLOW%d", 1:31), collapse = ", "),
                                    paste(DBI::dbQuoteString(con, stations$station_number), collapse = ", ")))
  keep <- mapply(function(s, y) y %in% years[[s]], d$station_number, d$year)
  d <- d[keep, , drop = FALSE]
  fl <- as.matrix(d[, sprintf("FLOW%d", 1:31)])
  if (any(rowSums(!is.na(fl)) < min_days)) {
    stop("a month in a complete year has fewer than ", min_days,
         " days; select and summarise with the same min_days", call. = FALSE)
  }
  n <- nrow(d)
  q <- as.vector(t(fl))
  # the calendar day, by date, so 30 February and 31 April fall away by date,
  # as in wet_station_daily()
  date <- as.Date(sprintf("%04d-%02d-%02d", rep(d$year, each = 31), rep(d$month, each = 31), rep(1:31, n)),
                  optional = TRUE)
  ok <- !is.na(q) & !is.na(date)
  x <- data.frame(station_number = rep(d$station_number, each = 31)[ok], year = rep(d$year, each = 31)[ok],
                  md = format(date[ok], "%m-%d"), q = as.numeric(q[ok]))
  x$md[x$md == "02-29"] <- "02-28"
  x$doy <- match(x$md, wet_doy_md())
  # within a year first (29 February averaged into 28), then across years
  yr <- stats::aggregate(q ~ station_number + year + doy, x, mean)
  cl <- stats::aggregate(q ~ station_number + doy, yr, mean)

  out <- do.call(rbind, lapply(stations$station_number, function(s) {
    v <- rep(NA_real_, 365)
    i <- cl$station_number == s
    v[cl$doy[i]] <- cl$q[i]
    gap <- which(is.na(v))
    if (length(gap)) {
      if (length(gap) == 365) stop("station ", s, " has no flow in its complete years", call. = FALSE)
      # around the year: each side's nearest neighbour, the January-December join included
      have <- which(!is.na(v))
      v[gap] <- stats::approx(c(have - 365, have, have + 365), rep(v[have], 3), xout = gap)$y
      filled <<- rbind(filled, data.frame(station_number = s, doy = gap))
    }
    tot <- sum(v)
    data.frame(station_number = s, doy = 1:365, q_m3s = v,
               share = if (tot > 0) v / tot else NA_real_, n_years = length(years[[s]]))
  }))
  out <- out[order(out$station_number, out$doy), ]
  rownames(out) <- NULL
  structure(out, filled = filled)
}
