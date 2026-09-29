#' Statistics of a daily series over date windows, one value per year
#'
#' Summarises any daily series (flow from [wet_station_daily()], water
#' temperature, ...) over named month-day windows, once per year per window.
#' The result is in the long format `cd`'s consumer functions take
#' (`variable`, `period`, `year`, `value`, `anomaly_type`, `unit`), so
#' `cd::cd_baseline()`, `cd::cd_anomaly()` and `cd::cd_trend()` give the
#' departure and the trend. cd takes one series per call, so split by id
#' first.
#'
#' A window whose `end` falls before its `start` crosses 1 January and takes
#' the year it starts in, so the incubation window September to April 2020
#' runs into 2021. A window-year is kept only when it lies inside the series'
#' first and last day and at least `min_frac` of its days have a value.
#'
#' @section Statistics:
#' \describe{
#'   \item{`mean`, `min`, `max`}{Over the days present.}
#'   \item{`min7`}{Lowest mean over seven consecutive calendar days, all
#'     present and all inside the window. Absent when there is no such run.}
#'   \item{`frac_below`}{Share of the days present below `threshold`, for
#'     example 0.2 times a station's mean annual flow from
#'     [wet_station_monthly()].}
#'   \item{`cov_day`}{Day of the window (1 = `start`) by which half the
#'     window's total has passed. Only for window-years with every day
#'     present, since a missing day moves it.}
#' }
#'
#' @param x A data frame with a `Date` column `date`, a numeric value column
#'   and the `by` id columns. Optional `symbol` (HYDAT `"B"` = ice) and
#'   `status` (`"provisional"`) columns give `frac_ice` and
#'   `frac_provisional`.
#' @param windows `data.frame(window, start, end)`, with `start` and `end` as
#'   `"MM-DD"`, both inclusive. An `end` of `"02-29"` is the last day of
#'   February; a `start` of `"02-29"` is refused. See [wet_windows_calendar()].
#' @param stats Any of `"mean"`, `"min"`, `"max"`, `"min7"`, `"frac_below"`,
#'   `"cov_day"`.
#' @param by Id columns that separate series; `character()` for one series.
#' @param value Name of the value column.
#' @param threshold For `frac_below`: one number, or a vector named by the
#'   values of a single `by` column.
#' @param min_frac Minimum share of a window's days that must have a value.
#' @param prefix Prefix for `variable`, e.g. `"q"` gives `q_mean`.
#' @param level_anomaly The cd anomaly type for `mean`, `min`, `max` and
#'   `min7`: `"pct_normal"` (percent of normal, unit `"%"`) for flow,
#'   `"absolute"` for temperature. `frac_below` and `cov_day` are always
#'   `"absolute"`.
#' @param unit Unit of an `"absolute"` level anomaly, e.g. `"degC"`.
#' @return A data frame: the `by` columns, `variable`, `period` (the window
#'   name), `year`, `value`, `anomaly_type`, `unit` (of the anomaly, as cd
#'   defines it), `n_days` present, `frac_ice` and `frac_provisional` (`NA`
#'   when `x` has no `symbol` or `status` column).
#' @examples
#' # A synthetic flow: low in winter, a freshet in June
#' date <- seq(as.Date("2001-01-01"), as.Date("2005-12-31"), by = "day")
#' doy <- as.numeric(format(date, "%j"))
#' x <- data.frame(station_number = "08XX001", date = date,
#'                 q_m3s = 2 + 40 * exp(-((doy - 165) / 25)^2))
#' w <- data.frame(window = c("spawning", "incubation"), start = c("08-01", "09-01"),
#'                 end = c("09-15", "04-30"))
#' s <- wet_window_stats(x, w, threshold = 0.2 * mean(x$q_m3s))
#' head(s)
#'
#' # The freshet's timing: day of June by which half of June's flow has passed
#' june <- wet_window_stats(x, wet_windows_calendar()[6, ], stats = "cov_day")
#' june[c("year", "value")]
#' @export
wet_window_stats <- function(x, windows = wet_windows_calendar(),
                             stats = c("mean", "min", "max", "min7", "frac_below", "cov_day"),
                             by = "station_number", value = "q_m3s", threshold = NULL,
                             min_frac = 0.8, prefix = "q", level_anomaly = "pct_normal",
                             unit = NULL) {
  all_stats <- c("mean", "min", "max", "min7", "frac_below", "cov_day")
  if (!length(stats) || !all(stats %in% all_stats)) {
    stop("`stats` must be some of ", paste(all_stats, collapse = ", "), call. = FALSE)
  }
  stats <- all_stats[all_stats %in% stats]
  for (col in c("date", value, by)) {
    if (!col %in% names(x)) stop("`x` has no column `", col, "`", call. = FALSE)
  }
  if (!inherits(x$date, "Date")) stop("`x$date` must be a Date", call. = FALSE)
  if (!is.numeric(x[[value]])) stop("`x$", value, "` must be numeric", call. = FALSE)
  if (!level_anomaly %in% c("pct_normal", "absolute")) {
    stop("`level_anomaly` must be \"pct_normal\" or \"absolute\"", call. = FALSE)
  }
  level_unit <- if (level_anomaly == "pct_normal") "%" else unit
  if (is.null(level_unit)) stop("give `unit` for an absolute level anomaly", call. = FALSE)
  w <- wet_windows_check(windows)
  x <- x[!is.na(x[[value]]), ]
  id <- if (length(by)) interaction(x[by], drop = TRUE, lex.order = TRUE) else factor(rep(1, nrow(x)))
  if (anyDuplicated(data.frame(id, x$date))) stop("`x` has duplicate dates within a series", call. = FALSE)
  thr <- wet_threshold(threshold, stats, x, by, id)

  meta <- data.frame(stat = all_stats,
                     anomaly_type = c(rep(level_anomaly, 4), "absolute", "absolute"),
                     unit = c(rep(level_unit, 4), "fraction", "days"))
  out <- lapply(split(seq_len(nrow(x)), id), function(i) {
    if (!length(i)) return(NULL)
    r <- wet_window_series(x[i, ], value, w, stats, thr[[as.character(id[i[1]])]], min_frac)
    if (is.null(r)) return(NULL)
    cbind(x[rep(i[1], nrow(r)), by, drop = FALSE], r)
  })
  out <- do.call(rbind, out)
  if (is.null(out)) {
    out <- cbind(x[0, by, drop = FALSE],
                 data.frame(stat = character(), period = character(), year = integer(),
                            value = numeric(), n_days = integer(), frac_ice = numeric(),
                            frac_provisional = numeric()))
  }
  m <- match(out$stat, meta$stat)
  # paste0() on zero rows would return one phantom "q_"
  out$variable <- if (nrow(out)) paste0(prefix, "_", out$stat) else character()
  out$anomaly_type <- meta$anomaly_type[m]
  out$unit <- meta$unit[m]
  ord <- do.call(order, c(unname(as.list(out[by])), list(m, match(out$period, w$window),
                                                          out$year)))
  out <- out[ord, c(by, "variable", "period", "year", "value", "anomaly_type", "unit", "n_days",
                    "frac_ice", "frac_provisional")]
  rownames(out) <- NULL
  out
}

wet_windows_check <- function(windows) {
  if (!is.data.frame(windows) || !all(c("window", "start", "end") %in% names(windows))) {
    stop("`windows` must be a data frame with columns window, start, end", call. = FALSE)
  }
  w <- data.frame(window = as.character(windows$window), start = as.character(windows$start),
                  end = as.character(windows$end))
  if (anyNA(w$window) || anyDuplicated(w$window)) {
    stop("window names must be unique and not NA", call. = FALSE)
  }
  md <- c(w$start, w$end)
  ok <- grepl("^[0-9]{2}-[0-9]{2}$", md) & !is.na(as.Date(paste0("2000-", md), optional = TRUE))
  if (!all(ok)) stop("window start and end must be valid \"MM-DD\": ", paste(md[!ok], collapse = ", "),
                     call. = FALSE)
  if (any(w$start == "02-29")) stop("a window cannot start on 02-29", call. = FALSE)
  w
}

# One threshold per series id, or NA when frac_below is not asked for.
wet_threshold <- function(threshold, stats, x, by, id) {
  ids <- levels(id)
  if (!"frac_below" %in% stats) return(stats::setNames(as.list(rep(NA_real_, length(ids))), ids))
  if (is.null(threshold)) stop("`frac_below` needs a `threshold`", call. = FALSE)
  if (length(threshold) == 1 && is.null(names(threshold))) {
    return(stats::setNames(as.list(rep(threshold, length(ids))), ids))
  }
  if (length(by) != 1 || is.null(names(threshold))) {
    stop("a per-series `threshold` must be named by the values of one `by` column", call. = FALSE)
  }
  key <- as.character(x[[by]][match(ids, as.character(id))])
  if (!all(key %in% names(threshold))) {
    stop("`threshold` has no value for: ", paste(setdiff(key, names(threshold)), collapse = ", "),
         call. = FALSE)
  }
  stats::setNames(as.list(unname(threshold[key])), ids)
}

# Window-years for one series, laid on a full calendar so days are positions.
wet_window_series <- function(s, value, w, stats, thr, min_frac) {
  first <- min(s$date)
  last <- max(s$date)
  n <- as.integer(last - first) + 1L
  pos <- as.integer(s$date - first) + 1L
  v <- rep(NA_real_, n)
  v[pos] <- s[[value]]
  ice <- if ("symbol" %in% names(s)) replace(rep(NA, n), pos, s$symbol %in% "B") else NULL
  prov <- if ("status" %in% names(s)) replace(rep(NA, n), pos, s$status %in% "provisional") else NULL
  y0 <- as.integer(format(first, "%Y")) - 1L
  y1 <- as.integer(format(last, "%Y"))
  rows <- list()
  for (k in seq_len(nrow(w))) {
    cross <- w$end[k] < w$start[k]
    for (y in y0:y1) {
      a <- as.Date(sprintf("%d-%s", y, w$start[k]))
      ey <- y + cross
      b <- if (w$end[k] == "02-29") as.Date(sprintf("%d-03-01", ey)) - 1 else as.Date(sprintf("%d-%s", ey, w$end[k]))
      if (a < first || b > last) next
      idx <- seq(as.integer(a - first) + 1L, as.integer(b - first) + 1L)
      vv <- v[idx]
      have <- !is.na(vv)
      nd <- sum(have)
      if (!nd || nd / length(idx) < min_frac) next
      val <- wet_stats_one(vv, have, stats, thr)
      if (!length(val)) next
      rows[[length(rows) + 1]] <- data.frame(
        stat = names(val), period = w$window[k], year = y, value = unname(val), n_days = nd,
        frac_ice = if (is.null(ice)) NA_real_ else mean(ice[idx][have]),
        frac_provisional = if (is.null(prov)) NA_real_ else mean(prov[idx][have]))
    }
  }
  do.call(rbind, rows)
}

wet_stats_one <- function(vv, have, stats, thr) {
  p <- vv[have]
  out <- c()
  if ("mean" %in% stats) out["mean"] <- mean(p)
  if ("min" %in% stats) out["min"] <- min(p)
  if ("max" %in% stats) out["max"] <- max(p)
  if ("min7" %in% stats && length(vv) >= 7) {
    m <- stats::filter(vv, rep(1 / 7, 7), sides = 1)[7:length(vv)]
    if (any(!is.na(m))) out["min7"] <- min(m, na.rm = TRUE)
  }
  if ("frac_below" %in% stats) out["frac_below"] <- mean(p < thr)
  if ("cov_day" %in% stats && all(have) && sum(vv) > 0) {
    out["cov_day"] <- which(cumsum(vv) >= sum(vv) / 2)[1]
  }
  out
}
