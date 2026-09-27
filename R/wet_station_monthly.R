#' Observed monthly and annual flow climatology at HYDAT stations
#'
#' For each station, averages the monthly mean daily flow over its complete
#' years, the same set of years for every month, so the monthly and annual
#' values describe one record. Monthly volumes use [wet_month_days()], and the
#' annual flow is the volume-weighted mean over a 365.25-day year, so the
#' twelve shares sum to 1.
#'
#' @param stations Output of [wet_station_select()]; its `"years"` attribute
#'   says which years to use per station.
#' @inheritParams wet_station_select
#' @return `data.frame(station_number, month, q_m3s, share, n_years)`, with
#'   `month` 1-12 and 0 for the annual mean flow (`share` 1).
#' @export
wet_station_monthly <- function(stations, hydat = wet_hydat_path(), min_days = 20) {
  yrs <- attr(stations, "years")
  if (!nrow(stations)) {
    return(data.frame(station_number = character(), month = integer(), q_m3s = numeric(),
                      share = numeric(), n_years = integer()))
  }
  if (is.null(yrs) || !all(stations$station_number %in% names(yrs))) {
    stop("`stations` must carry the \"years\" attribute from wet_station_select()", call. = FALSE)
  }
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  flows <- paste(sprintf("FLOW%d", 1:31), collapse = ", ")
  d <- DBI::dbGetQuery(con, sprintf(
    "SELECT STATION_NUMBER station_number, YEAR year, MONTH month, %s FROM DLY_FLOWS
     WHERE STATION_NUMBER IN (%s)",
    flows, paste(DBI::dbQuoteString(con, stations$station_number), collapse = ", ")))
  keep <- mapply(function(s, y) y %in% yrs[[s]], d$station_number, d$year)
  d <- d[keep, ]
  fl <- as.matrix(d[, sprintf("FLOW%d", 1:31)])
  n <- rowSums(!is.na(fl))
  if (any(n < min_days)) stop("a month in a complete year has fewer than ", min_days,
                              " days; select and summarise with the same min_days", call. = FALSE)
  d$q <- rowMeans(fl, na.rm = TRUE)

  m <- stats::aggregate(q ~ station_number + month, d, mean)
  names(m)[names(m) == "q"] <- "q_m3s"
  days <- wet_month_days()
  m$vol <- m$q_m3s * days[m$month]
  tot <- stats::aggregate(vol ~ station_number, m, sum)
  m$share <- m$vol / tot$vol[match(m$station_number, tot$station_number)]
  ann <- data.frame(station_number = tot$station_number, month = 0L,
                    q_m3s = tot$vol / sum(days), share = 1)
  out <- rbind(m[, c("station_number", "month", "q_m3s", "share")], ann)
  out$month <- as.integer(out$month)
  out$n_years <- unname(lengths(yrs)[out$station_number])
  out <- out[order(out$station_number, out$month), ]
  rownames(out) <- NULL
  out
}
