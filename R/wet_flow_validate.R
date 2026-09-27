#' Skill of modelled runoff against observed runoff at gauges
#'
#' Per station: the annual error `100 * (mod - obs) / obs` and log ratio
#' `log(mod / obs)`, and over the 12 months the Nash-Sutcliffe efficiency of
#' the monthly climatology (mm) and of the monthly shares of the annual
#' total. Summaries by group give the metrics of Chapman et al. (2018) (mean,
#' median and mean absolute error in percent, and the share of stations within
#' +/- 20 %) plus the log-ratio bias and spread.
#'
#' A station whose observed annual runoff is below `min_obs` mm is left out
#' of every summary and counted in `n_low`: percentage errors on near-zero
#' runoff are not informative, and a log ratio of zero or negative runoff is
#' undefined. Months need all 12 values in both series; a station without
#' them gets `NA` monthly metrics.
#'
#' @param x `data.frame(station_number, month, obs, mod)` in mm, `month` 0 for
#'   the annual total and 1-12 for months. Modelled values below 0 should be
#'   floored before they reach here.
#' @param groups Optional `data.frame(station_number, <group columns>)`; each
#'   group column gets its own summary.
#' @param min_obs Minimum observed annual runoff (mm) for a station to count.
#' @return `list(stations, summary)`. `stations`: one row per station with
#'   `obs`, `mod`, `err_pct`, `log_ratio`, `nse_month`, `nse_share`. `summary`:
#'   one row per group value (and an `"all"` row) with `n`, `n_low`, `n_no_mod`
#'   (stations with no modelled value, left out),
#'   `mean_err_pct`, `median_err_pct`, `mae_pct`, `within_20`,
#'   `log_bias_median`, `log_sd`, `nse_month_median`, `nse_share_median`.
#' @export
wet_flow_validate <- function(x, groups = NULL, min_obs = 10) {
  need <- c("station_number", "month", "obs", "mod")
  miss <- setdiff(need, names(x))
  if (length(miss)) stop("x is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (anyDuplicated(x[c("station_number", "month")])) {
    stop("x has duplicate station_number and month rows", call. = FALSE)
  }
  if (!all(x$month %in% 0:12)) stop("month must be 0 (annual) or 1-12", call. = FALSE)
  ids <- sort(unique(x$station_number))
  ann <- x[x$month == 0, ]
  st <- data.frame(station_number = ids,
                   obs = ann$obs[match(ids, ann$station_number)],
                   mod = ann$mod[match(ids, ann$station_number)])
  # a missing modelled value is left out and counted, not allowed to turn
  # every mean in its groups into NA
  st$low <- is.na(st$obs) | st$obs < min_obs
  st$no_mod <- !st$low & is.na(st$mod)
  st$low <- st$low | st$no_mod
  st$err_pct <- ifelse(st$low, NA_real_, 100 * (st$mod - st$obs) / st$obs)
  st$log_ratio <- ifelse(st$low | !(st$mod > 0), NA_real_, log(st$mod / st$obs))
  mo <- x[x$month > 0, ]
  st$nse_month <- NA_real_
  st$nse_share <- NA_real_
  for (k in seq_along(ids)) {
    m <- mo[mo$station_number == ids[k], ]
    m <- m[order(m$month), ]
    if (st$low[k] || nrow(m) != 12 || anyNA(m$obs) || anyNA(m$mod)) next
    st$nse_month[k] <- wet_nse(m$obs, m$mod)
    if (sum(m$obs) > 0 && sum(m$mod) > 0) {
      st$nse_share[k] <- wet_nse(m$obs / sum(m$obs), m$mod / sum(m$mod))
    }
  }
  summ <- list(wet_skill_summary(st, "all", "all"))
  if (!is.null(groups)) {
    if (!"station_number" %in% names(groups)) stop("groups needs station_number", call. = FALSE)
    for (g in setdiff(names(groups), "station_number")) {
      gv <- groups[[g]][match(st$station_number, groups$station_number)]
      for (v in sort(unique(stats::na.omit(gv)))) {
        summ[[length(summ) + 1]] <- wet_skill_summary(st[gv %in% v, ], g, v)
      }
    }
  }
  st$low <- NULL
  st$no_mod <- NULL
  list(stations = st, summary = do.call(rbind, summ))
}

wet_nse <- function(obs, mod) {
  d <- sum((obs - mean(obs))^2)
  if (!(d > 0)) return(NA_real_)
  1 - sum((mod - obs)^2) / d
}

wet_skill_summary <- function(st, group, value) {
  e <- st$err_pct[!st$low]
  med <- function(v) if (length(v) && any(!is.na(v))) stats::median(v, na.rm = TRUE) else NA_real_
  data.frame(group = group, value = as.character(value), n = sum(!st$low),
             n_low = sum(st$low & !st$no_mod), n_no_mod = sum(st$no_mod),
             mean_err_pct = if (length(e)) mean(e) else NA_real_,
             median_err_pct = med(e),
             mae_pct = if (length(e)) mean(abs(e)) else NA_real_,
             within_20 = if (length(e)) mean(abs(e) <= 20) else NA_real_,
             log_bias_median = med(st$log_ratio[!st$low]),
             log_sd = wet_sd(st$log_ratio[!st$low]),
             nse_month_median = med(st$nse_month[!st$low]),
             nse_share_median = med(st$nse_share[!st$low]))
}

wet_sd <- function(v) if (sum(!is.na(v)) > 1) stats::sd(v, na.rm = TRUE) else NA_real_
