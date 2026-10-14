#' Mean flow over date windows, from monthly or daily means
#'
#' Turns a flow climatology into mean flow over named month-day windows, such
#' as a species' life stage or a week, and says what it rests on. From monthly
#' means ([wet_segment_monthly()], [wet_station_monthly()]) each day of the
#' window takes its month's mean and the window's flow is the mean over its
#' days: `basis = "monthly"`. That is an approximation where a window takes
#' part of a month whose flow rises or falls fast. From daily means (a `doy`
#' column) the window's flow is the mean of its days: `basis = "daily"`. A
#' caller that swaps monthly input for daily gets the same call and a
#' `basis` that says so.
#'
#' Days are laid on a common year: February has 28 days, and an `end` of
#' `"02-29"` means its last day, as in [wet_window_stats()]. A window whose
#' `end` falls before its `start` runs across 1 January. A window is `NA`
#' when any of its days has no value.
#'
#' @param x A data frame with the `by` columns, `q_m3s`, and either `month`
#'   (1-12; month 0, the annual value, is ignored) or `doy` (day of a common
#'   year, 1-365).
#' @param windows `data.frame(window, start, end)`, with `start` and `end` as
#'   `"MM-DD"`, both inclusive. See [wet_windows_calendar()].
#' @param by Columns that separate series: `c("linear_feature_id", "source")`
#'   for segments, `"station_number"` for gauges, `character()` for one
#'   series.
#' @return One row per series and window: the `by` columns, `window`,
#'   `q_m3s` and `basis` (`"monthly"` or `"daily"`).
#' @seealso [wet_window_stats()] for per-year statistics of a daily series.
#' @examples
#' # a segment's twelve monthly means, with a June freshet
#' x <- data.frame(linear_feature_id = 17094080L, month = 0:12, source = "pcic_routed",
#'                 q_m3s = c(5.9, 1.4, 1.2, 1.5, 4.6, 15.8, 19.1, 9.6, 4.4, 3.5, 3.6, 2.6, 1.7))
#' w <- rbind(wet_windows_calendar()[6:7, ],
#'            data.frame(window = "ch_spawning", start = "08-20", end = "09-30"))
#' wet_flow_window(x, w)
#' @export
wet_flow_window <- function(x, windows, by = c("linear_feature_id", "source")) {
  if (!is.data.frame(x)) stop("`x` must be a data frame", call. = FALSE)
  has_m <- "month" %in% names(x)
  if (has_m == ("doy" %in% names(x))) {
    stop("`x` must have a `month` column (monthly means) or a `doy` column (daily means), not both or neither",
         call. = FALSE)
  }
  for (col in c(by, "q_m3s")) {
    if (!col %in% names(x)) stop("`x` has no column `", col, "`", call. = FALSE)
  }
  if (!is.numeric(x$q_m3s)) stop("`x$q_m3s` must be numeric", call. = FALSE)
  w <- wet_windows_check(windows)
  tcol <- if (has_m) "month" else "doy"
  n_t <- if (has_m) 12L else 365L
  t <- x[[tcol]]
  if (has_m) {
    keep <- !(t %in% 0)
    x <- x[keep, , drop = FALSE]
    t <- t[keep]
  }
  if (!is.numeric(t) || anyNA(t) || !all(t %in% seq_len(n_t))) {
    stop("`", tcol, "` must be whole numbers from 1 to ", n_t, if (has_m) " (or 0, ignored)", call. = FALSE)
  }

  # the days of each window as positions in its months or days of the year
  days <- lapply(seq_len(nrow(w)), function(k) {
    a <- as.Date(paste0("2001-", w$start[k]))
    ey <- 2001L + (w$end[k] < w$start[k])
    b <- if (w$end[k] == "02-29") as.Date(sprintf("%d-03-01", ey)) - 1 else as.Date(sprintf("%d-%s", ey, w$end[k]))
    d <- seq(a, b, by = "day")
    as.integer(format(d, if (has_m) "%m" else "%j"))
  })

  k <- if (length(by)) do.call(paste, c(lapply(x[by], as.character), sep = "\r")) else rep("", nrow(x))
  if (anyDuplicated(data.frame(k, t))) {
    stop("`x` has duplicate ", tcol, "s within a series of `by`", call. = FALSE)
  }
  keys <- unique(k)
  first <- match(keys, k)
  rows <- split(seq_len(nrow(x)), factor(k, levels = keys))
  q <- unlist(lapply(rows, function(i) {
    v <- rep(NA_real_, n_t)
    v[t[i]] <- x$q_m3s[i]
    vapply(days, function(d) mean(v[d]), 0)
  }), use.names = FALSE)

  out <- x[rep(first, each = nrow(w)), by, drop = FALSE]
  out$window <- rep(w$window, length(keys))
  out$q_m3s <- if (length(q)) q else numeric()
  out$basis <- rep(if (has_m) "monthly" else "daily", nrow(out))
  rownames(out) <- NULL
  out
}
