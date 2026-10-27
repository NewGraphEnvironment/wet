#' Carry donor gauges' year-to-year departures onto an ungauged site
#'
#' Gives a site with no record of its own (or a short one) the departure of
#' each year from normal, as the weighted mean of its donor gauges'
#' departures. Each donor's departure is taken from its own baseline mean, so
#' a donor's size does not matter, only how its years vary. The donors are
#' the `k` gauges nearest the target in predictor space (easting and
#' northing in km in BC Albers, EPSG:3005, and log drainage area, each
#' divided by its standard deviation over `stations`), weighted by inverse
#' distance as the monthly shares' and the daily shape's donors are. In a year
#' a donor has no value, it is dropped and the remaining weights renormalised
#' to sum to 1; a year no donor has is not returned.
#'
#' A departure is a log ratio, `log(value / baseline mean)`, reported also as
#' percent of normal, `100 * (exp(anomaly) - 1)`, the scale
#' `cd::cd_anomaly()` uses. A statistic named `*_cov_day` (a day of the
#' window) departs in days instead, and has no percent of normal.
#'
#' @param x Window statistics in [wet_window_stats()]'s long format
#'   (`station_number`, `variable`, `period`, `year`, `value`) for the donors
#'   and, if it has any record, the target. Each `variable` and `period` is
#'   carried on its own. Every donor chosen must have at least
#'   `min_baseline` years in `baseline`.
#' @param stations `data.frame(station_number, lon, lat,
#'   drainage_area_gross_km2)`, as from [wet_station_select()], with a row for
#'   the target and every station in `x`.
#' @param target The target's station number, or any id with a row in
#'   `stations`.
#' @param k Number of donors.
#' @param baseline Baseline years.
#' @param min_baseline Fewest baseline years a donor needs, and the target
#'   needs for `value`.
#' @param weights How the donors are weighted. `"distance"` (the default):
#'   the `k` nearest, by inverse distance. `"covariance"`: the same `k`, each
#'   weight multiplied by `max(r, 0)`, where `r` is the correlation between
#'   the target's and the donor's modelled values in `modelled` (log values
#'   for flow, days for `*_cov_day`) over the years both have; an `r` from
#'   fewer than 30 years, or undefined, counts as 0. `"covariance_pick"`:
#'   among the 15 nearest, the `k` with the highest `r`, weighted by
#'   `max(r, 0)` alone. Where every donor chosen weighs 0, the covariance
#'   options fall back to `"distance"` for that statistic.
#' @param modelled For the covariance options only: modelled values in `x`'s
#'   long format, such as routed PCIC flow at each gauge's segment from
#'   [wet_routed_years()] through [wet_window_stats()], with rows for the
#'   target and every donor the option considers. A station with rows for
#'   some statistics and none for another (a segment routed to 0 has no
#'   `*_cov_day`) has no years there, so its `r` is 0.
#' @return A data frame: `station_number` (the target), `variable`, `period`,
#'   `year`, `anomaly` (log, or days for `*_cov_day`), `pct_normal`,
#'   `n_donors` (present that year), `donors` (`"station:weight"` pairs
#'   used that year, separated by spaces) and `value`: the target's baseline
#'   mean carried by the anomaly, only where the target has its own
#'   baseline in `x`, else `NA`. Under the covariance options each pair in
#'   `donors` also carries the donor's `r` (`"station:weight:r"`), and a
#'   column `weighting` says which weighting was used: the option, or
#'   `"distance"` where it fell back.
#' @examples
#' # Two donors share a wet year in 1990; the target, ungauged, gets it too
#' yrs <- 1975:2000
#' wet <- ifelse(yrs == 1990, 1.5, 1)
#' x <- data.frame(station_number = rep(c("D1", "D2"), each = length(yrs)),
#'                 variable = "q_mean", period = "migration", year = rep(yrs, 2),
#'                 value = c(20 * wet, 300 * wet))
#' st <- data.frame(station_number = c("D1", "D2", "T"), lon = c(-126.6, -127.8, -126.5),
#'                  lat = c(54.4, 55.1, 54.3), drainage_area_gross_km2 = c(2300, 900, 360))
#' a <- wet_departure_carry(x, st, "T", k = 2)
#' a[a$year %in% 1989:1991, c("year", "anomaly", "pct_normal", "donors")]
#' @export
wet_departure_carry <- function(x, stations, target, k = 5, baseline = 1981:2010, min_baseline = 10,
                                weights = c("distance", "covariance", "covariance_pick"), modelled = NULL) {
  weights <- match.arg(weights)
  cov <- weights != "distance"
  if (cov && is.null(modelled)) stop("`weights = \"", weights, "\"` needs `modelled`", call. = FALSE)
  if (!cov && !is.null(modelled)) stop("`modelled` is used only by the covariance weightings", call. = FALSE)
  if (cov) {
    for (col in c("station_number", "variable", "period", "year", "value")) {
      if (!col %in% names(modelled)) stop("`modelled` has no column `", col, "`", call. = FALSE)
    }
    if (anyDuplicated(modelled[c("station_number", "variable", "period", "year")])) {
      stop("`modelled` has more than one value for a station, variable, period and year", call. = FALSE)
    }
  }
  for (col in c("station_number", "variable", "period", "year", "value")) {
    if (!col %in% names(x)) stop("`x` has no column `", col, "`", call. = FALSE)
  }
  if (!is.character(target) || length(target) != 1 || is.na(target)) {
    stop("`target` must be one station number", call. = FALSE)
  }
  if (!(is.numeric(k) && length(k) == 1 && k >= 1)) stop("`k` must be a positive number", call. = FALSE)
  if (anyDuplicated(x[c("station_number", "variable", "period", "year")])) {
    stop("`x` has more than one value for a station, variable, period and year", call. = FALSE)
  }
  space <- wet_station_space(stations)
  miss <- setdiff(unique(c(target, x$station_number)), rownames(space))
  if (length(miss)) stop("`stations` has no row for: ", paste(miss, collapse = ", "), call. = FALSE)

  x <- x[!is.na(x$value), ]
  combos <- unique(x[x$station_number != target, c("variable", "period")])
  if (!nrow(combos)) stop("`x` has no donor rows", call. = FALSE)
  res <- lapply(seq_len(nrow(combos)), function(i) {
    v <- combos$variable[i]
    p <- combos$period[i]
    days <- grepl("_cov_day$", v)
    g <- x[x$variable == v & x$period == p, ]
    if (!days) g <- g[g$value > 0, ]
    cand <- sort(setdiff(unique(g$station_number), target))
    don <- rownames(space)[rownames(space) %in% cand]
    # wet_donor_mean() on the identity gives each donor's distance weight, so
    # the weighting stays the one #70 and #102 use; the covariance options
    # scale or replace it (wet_donor_weights())
    mod <- if (cov) modelled[modelled$variable == v & modelled$period == p, c("station_number", "year", "value")]
    dw <- wet_donor_weights(space, target, don, k, weights, mod, days, known = unique(modelled$station_number))
    wt <- dw$weight
    dist <- sqrt(colSums((t(space[don, , drop = FALSE]) - space[target, ])^2))
    use <- don[order(dist, don)]
    use <- use[wt[use] > 0]
    dep <- lapply(stats::setNames(use, use), function(s) {
      d <- g[g$station_number == s, ]
      b <- d$value[d$year %in% baseline]
      if (length(b) < min_baseline) {
        stop(sprintf("donor %s has %d baseline years of %s in %s; at least %d are needed", s, length(b), v, p,
                     min_baseline), call. = FALSE)
      }
      stats::setNames(if (days) d$value - mean(b) else log(d$value / mean(b)), d$year)
    })
    yrs <- sort(unique(as.integer(unlist(lapply(dep, names)))))
    dep_mat <- vapply(dep, function(a) unname(a[as.character(yrs)]), numeric(length(yrs)))
    dep_mat <- matrix(dep_mat, nrow = length(yrs), dimnames = list(yrs, use))
    wt_mat <- matrix(wt[use], nrow(dep_mat), ncol(dep_mat), byrow = TRUE) * !is.na(dep_mat)
    # every year comes from a donor with positive weight, so no row sums to 0
    wt_mat <- wt_mat / rowSums(wt_mat)
    an <- rowSums(wt_mat * ifelse(is.na(dep_mat), 0, dep_mat))
    used <- vapply(seq_len(nrow(wt_mat)), function(r) {
      j <- which(wt_mat[r, ] > 0)
      if (cov) {
        paste(sprintf("%s:%.4f:%.3f", use[j], wt_mat[r, j], dw$r[use[j]]), collapse = " ")
      } else {
        paste(sprintf("%s:%.4f", use[j], wt_mat[r, j]), collapse = " ")
      }
    }, "")
    tb <- g$value[g$station_number == target & g$year %in% baseline]
    tmean <- if (length(tb) >= min_baseline) mean(tb) else NA_real_
    o <- data.frame(station_number = target, variable = v, period = p, year = yrs, anomaly = unname(an),
                    pct_normal = if (days) NA_real_ else 100 * (exp(unname(an)) - 1),
                    n_donors = unname(rowSums(wt_mat > 0)), donors = used,
                    value = if (days) tmean + unname(an) else tmean * exp(unname(an)))
    if (cov) o$weighting <- if (dw$fallback) "distance" else weights
    o
  })
  out <- do.call(rbind, res)
  out <- out[order(out$variable, out$period, out$year), ]
  rownames(out) <- NULL
  out
}
