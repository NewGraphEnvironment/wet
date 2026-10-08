#' Growing season degree days per station-year
#'
#' Growing season degree days (GSDD) from daily mean water temperature, one
#' value per station and year, computed by `gsdd::gsdd()` (Coleman & Fausch
#' 2007): the season starts in the first week whose 7-day mean rises above
#' 5 °C and stays there, and ends in the first week whose 7-day mean falls
#' below 4 °C, and GSDD is the sum of the daily means over it. The result is in
#' the long format of [wet_window_stats()], so it goes to `cd::cd_baseline()`,
#' `cd::cd_anomaly()` and `cd::cd_trend()` as is.
#'
#' A season cut by a missing day gives `NA`, not a value that is too low:
#' days absent from `x` are missing, and `gsdd::gsdd()` uses the longest run
#' with no missing day. Fill the gaps first with [wet_temp_fill()]. `frac_filled`
#' then says how much of each value is modelled.
#'
#' @param x Daily water temperature, as from [wet_temp_daily()] or
#'   [wet_temp_fill()]: `date`, the `value` column and the `by` columns, and
#'   optionally `filled`.
#' @param value Name of the daily mean column.
#' @param by Id columns that separate series.
#' @param start_date,end_date The part of each year to consider, as in
#'   `gsdd::gsdd()` (the year is ignored).
#' @param ... Passed to `gsdd::gsdd()`, e.g. `start_temp`, `end_temp`, `pick`
#'   or `ignore_truncation`.
#' @return A data frame: the `by` columns, `variable` (`"gsdd"`), `period`
#'   (`"growing_season"`), `year`, `value` (°C-days, `NA` where the season is
#'   cut), `anomaly_type` (`"absolute"`), `unit` (`"degC_day"`), and over the
#'   days from `start_date` to `end_date` that have a value: `n_days` (how
#'   many), `frac_ice` (`NA`: there is no ice flag), `frac_provisional` (share
#'   whose `status` is `"provisional"`, `NA` without a `status` column) and
#'   `frac_filled` (share that were filled, `NA` without a `filled` column).
#'   The columns are those of [wet_window_stats()] plus `frac_filled`. One row
#'   per series and year that `gsdd::gsdd()` returns. The interval of a
#'   [wet_temp_fill()] result does not carry into GSDD: daily bounds do not add
#'   up to bounds on a sum.
#' @references Coleman, M.A., and Fausch, K.D. 2007. Cold summer temperature
#'   limits recruitment of age-0 cutthroat trout in high-elevation Colorado
#'   streams. Transactions of the American Fisheries Society 136(5):
#'   1231-1244. doi:10.1577/T05-244.1.
#' @examples
#' if (requireNamespace("gsdd", quietly = TRUE)) {
#'   date <- seq(as.Date("2019-01-01"), as.Date("2020-12-31"), by = "day")
#'   doy <- as.integer(format(date, "%j"))
#'   x <- data.frame(station_number = "08AA001", date = date,
#'                   t_mean_c = pmax(0, 6 + 9 * sin(2 * pi * (doy - 110) / 365)))
#'   wet_temp_gsdd(x)
#'
#'   # A week missing in July 2020 leaves that season unknown
#'   gap <- date >= as.Date("2020-07-01") & date <= as.Date("2020-07-07")
#'   wet_temp_gsdd(x[!gap, ])
#' }
#' @export
wet_temp_gsdd <- function(x, value = "t_mean_c", by = "station_number",
                          start_date = as.Date("1972-03-01"), end_date = as.Date("1972-11-30"),
                          ...) {
  if (!requireNamespace("gsdd", quietly = TRUE)) {
    stop("install gsdd (pak::pak(\"poissonconsulting/gsdd\")) for growing season degree days",
         call. = FALSE)
  }
  if (!is.data.frame(x)) stop("`x` must be a data frame", call. = FALSE)
  for (col in c("date", value, by)) {
    if (!col %in% names(x)) stop("`x` has no column `", col, "`", call. = FALSE)
  }
  if (!inherits(x$date, "Date")) stop("`x$date` must be a Date", call. = FALSE)
  if (!is.numeric(x[[value]])) stop("`x$", value, "` must be numeric", call. = FALSE)
  has_filled <- "filled" %in% names(x)
  has_status <- "status" %in% names(x)
  x <- x[!is.na(x[[value]]) & !is.na(x$date), ]
  id <- if (length(by)) interaction(x[by], drop = TRUE, lex.order = TRUE) else factor(rep(1, nrow(x)))
  if (anyDuplicated(data.frame(id, x$date))) stop("`x` has duplicate dates within a series", call. = FALSE)
  md <- c(format(as.Date(start_date), "%m-%d"), format(as.Date(end_date), "%m-%d"))

  out <- lapply(split(seq_len(nrow(x)), id), function(i) {
    if (!length(i)) return(NULL)
    s <- x[i, ]
    # a full calendar, so a day absent from x is a missing day to gsdd
    date <- seq(min(s$date), max(s$date), by = "day")
    k <- match(date, s$date)
    g <- gsdd::gsdd(data.frame(date = date, temperature = s[[value]][k]),
                    start_date = start_date, end_date = end_date, msgs = FALSE, ...)
    if (!nrow(g)) return(NULL)
    year <- as.integer(g$year)
    # the rows of s inside each year's window, NA for a day s does not have
    win <- lapply(year, function(y) {
      a <- wet_md_date(y, md[1], start = TRUE)
      b <- wet_md_date(y + (md[2] < md[1]), md[2], start = FALSE)
      match(seq(a, b, by = "day"), s$date)
    })
    frac <- function(ok, col, hit) {
      if (!ok) return(rep(NA_real_, length(year)))
      vapply(win, function(k) {
        k <- k[!is.na(k)]
        if (length(k)) mean(s[[col]][k] %in% hit) else NA_real_
      }, numeric(1))
    }
    data.frame(x[rep(i[1], length(year)), by, drop = FALSE], variable = "gsdd",
               period = "growing_season", year = year, value = as.numeric(g$gsdd),
               anomaly_type = "absolute", unit = "degC_day",
               n_days = vapply(win, function(k) sum(!is.na(k)), integer(1)),
               frac_ice = NA_real_, frac_provisional = frac(has_status, "status", "provisional"),
               frac_filled = frac(has_filled, "filled", TRUE))
  })
  out <- do.call(rbind, out)
  if (is.null(out)) {
    out <- cbind(x[0, by, drop = FALSE],
                 data.frame(variable = character(), period = character(), year = integer(),
                            value = numeric(), anomaly_type = character(), unit = character(),
                            n_days = integer(), frac_ice = numeric(), frac_provisional = numeric(),
                            frac_filled = numeric()))
  }
  rownames(out) <- NULL
  out
}

# A month-day in a year; 29 February in a common year is 1 March as a start
# and 28 February as an end.
wet_md_date <- function(year, md, start) {
  if (md == "02-29" && is.na(as.Date(paste0(year, "-02-29"), optional = TRUE))) {
    md <- if (start) "03-01" else "02-28"
  }
  as.Date(paste0(year, "-", md))
}
