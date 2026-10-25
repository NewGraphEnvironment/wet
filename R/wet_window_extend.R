#' Extend a short gauge record of window statistics from donor gauges
#'
#' Extends a target gauge's per-year window statistics (from
#' [wet_window_stats()]) into the years it has no record, from nearby gauges
#' that have one, with a prediction interval per year. The donors are the `k`
#' gauges nearest the target in predictor space (easting and northing in km
#' in BC Albers, EPSG:3005, and log drainage area, each divided by its
#' standard deviation over `stations`) that have a value in **every** year
#' the target has. In each year to be extended, the nearest of them with a
#' value that year supplies it; each donor's relation to the target is fitted
#' on the target's years. A year none of them has is not returned.
#'
#' A statistic named `*_cov_day` (a day of the window) is related in days;
#' every other statistic in logs, and a value of 0 or less is left out of the
#' fit (counted in the attribute `"dropped"`).
#'
#' @section Methods:
#' With `x` the donor's value and `y` the target's (log or days) over the
#' target's `n` years:
#' \describe{
#'   \item{`"ols"`}{Least-squares regression of `y` on `x`. The interval is
#'     the regression's prediction interval at `level`, with `n - 2` degrees
#'     of freedom.}
#'   \item{`"move1"`}{The line of organic correlation (MOVE.1), `y = mean(y) +
#'     sign(r) sd(y) / sd(x) (x - mean(x))`, which keeps the target's
#'     variance where regression shrinks it.}
#'   \item{`"ratio"`}{The donor's value times the ratio of the target's mean
#'     to the donor's mean over the same years, on the original scale.}
#' }
#' For `"move1"` and `"ratio"` the interval comes from `resid`: residuals
#' (observed minus predicted, on the method's scale) measured elsewhere, for
#' example at other gauges held out; without them the bounds are `NA`. A
#' log-scale prediction is returned back-transformed, so it is a median.
#'
#' @param x Window statistics in [wet_window_stats()]'s long format
#'   (`station_number`, `variable`, `period`, `year`, `value`) for the target
#'   and its candidate donors. Each `variable` and `period` is extended on its
#'   own. The target's rows are its record: to hold years out, leave them out.
#' @param stations `data.frame(station_number, lon, lat,
#'   drainage_area_gross_km2)`, as from [wet_station_select()], with a row for
#'   the target and every station in `x`. The predictor scaling is taken over
#'   its rows.
#' @param target The target's station number.
#' @param method `"ols"`, `"move1"` or `"ratio"`.
#' @param k Number of nearest covering donors in the chain.
#' @param level Nominal coverage of the interval.
#' @param resid For `"move1"` and `"ratio"`: residuals whose `(1 - level) /
#'   2` and `(1 + level) / 2` quantiles bound the interval.
#' @return A data frame: `station_number` (the target), `variable`, `period`,
#'   `year`, `value`, `lower`, `upper`, `donor` (`NA` for an observed year)
#'   and `source` (`"observed"` or `"extended"`), ordered by variable, period
#'   and year. Attribute `"donors"`: the chain per variable and period, nearest
#'   first.
#' @examples
#' # Three gauges: a long-record donor, a farther one, and a target with five
#' # years whose flow is 0.4 times the donor's to the power 1.1
#' set.seed(1)
#' yrs <- 1961:2020
#' d1 <- exp(rnorm(60, 3, 0.3))
#' d2 <- exp(rnorm(60, 3, 0.3))
#' x <- data.frame(
#'   station_number = rep(c("D1", "D2", "T"), c(60, 60, 5)),
#'   variable = "q_mean", period = "migration",
#'   year = c(yrs, yrs, 1975:1979),
#'   value = c(d1, d2, 0.4 * d1[15:19]^1.1 * exp(rnorm(5, 0, 0.05))))
#' st <- data.frame(station_number = c("D1", "D2", "T"), lon = c(-126.6, -127.8, -126.5),
#'                  lat = c(54.4, 55.1, 54.3), drainage_area_gross_km2 = c(2300, 900, 360))
#' e <- wet_window_extend(x, st, "T", method = "ols")
#' head(e)
#' table(e$source, e$donor, useNA = "ifany")
#' @export
wet_window_extend <- function(x, stations, target, method = c("ols", "move1", "ratio"), k = 5,
                              level = 0.9, resid = NULL) {
  method <- match.arg(method)
  for (col in c("station_number", "variable", "period", "year", "value")) {
    if (!col %in% names(x)) stop("`x` has no column `", col, "`", call. = FALSE)
  }
  if (!is.character(target) || length(target) != 1 || is.na(target)) {
    stop("`target` must be one station number", call. = FALSE)
  }
  if (!(is.numeric(level) && length(level) == 1 && level > 0 && level < 1)) {
    stop("`level` must be one number between 0 and 1", call. = FALSE)
  }
  if (!(is.numeric(k) && length(k) == 1 && k >= 1)) stop("`k` must be a positive number", call. = FALSE)
  if (anyDuplicated(x[c("station_number", "variable", "period", "year")])) {
    stop("`x` has more than one value for a station, variable, period and year", call. = FALSE)
  }
  space <- wet_station_space(stations)
  miss <- setdiff(unique(c(target, x$station_number)), rownames(space))
  if (length(miss)) stop("`stations` has no row for: ", paste(miss, collapse = ", "), call. = FALSE)
  if (!target %in% x$station_number) stop("`x` has no rows for the target ", target, call. = FALSE)

  combos <- unique(x[x$station_number == target, c("variable", "period")])
  chains <- list()
  dropped <- 0L
  res <- lapply(seq_len(nrow(combos)), function(i) {
    v <- combos$variable[i]
    p <- combos$period[i]
    days <- grepl("_cov_day$", v)
    g <- x[x$variable == v & x$period == p & !is.na(x$value), ]
    if (!days) {
      dropped <<- dropped + sum(g$value <= 0)
      g <- g[g$value > 0, ]
    }
    tg <- g[g$station_number == target, ]
    ty <- sort(tg$year)
    if (length(ty) < 3) {
      stop(sprintf("the target %s has %d years of %s in %s; at least 3 are needed", target, length(ty), v, p),
           call. = FALSE)
    }
    yv <- stats::setNames(tg$value, tg$year)[as.character(ty)]
    don <- split(g[g$station_number != target, c("year", "value")], g$station_number[g$station_number != target])
    covers <- names(don)[vapply(don, function(d) all(ty %in% d$year), TRUE)]
    if (!length(covers)) {
      stop(sprintf("no donor has %s in %s in every one of the target %s's %d years", v, p, target, length(ty)),
           call. = FALSE)
    }
    dist <- sqrt(colSums((t(space[covers, , drop = FALSE]) - space[target, ])^2))
    chain <- covers[order(dist, covers)][seq_len(min(k, length(covers)))]
    chains[[paste(v, p, sep = "|")]] <<- chain
    obs <- data.frame(year = ty, value = unname(yv), lower = unname(yv), upper = unname(yv),
                      donor = NA_character_, source = "observed")
    ext <- list()
    taken <- ty
    for (dn in chain) {
      d <- don[[dn]]
      xv <- stats::setNames(d$value, d$year)
      new <- setdiff(d$year, taken)
      if (!length(new)) next
      taken <- c(taken, new)
      f <- wet_extend_fit(xv[as.character(ty)], yv, xv[as.character(new)], method, days, level, resid)
      ext[[dn]] <- data.frame(year = new, value = f$fit, lower = f$lower, upper = f$upper, donor = dn,
                              source = "extended")
    }
    r <- do.call(rbind, c(list(obs), ext))
    r <- r[order(r$year), ]
    cbind(data.frame(station_number = target, variable = v, period = p), r)
  })
  out <- do.call(rbind, res)
  out <- out[order(out$variable, out$period, out$year), ]
  rownames(out) <- NULL
  attr(out, "donors") <- chains
  attr(out, "dropped") <- dropped
  out
}

# One donor's relation to the target over the target's years (x, y on the
# original scale), applied at the donor's values x0. Log scale unless `days`.
wet_extend_fit <- function(x, y, x0, method, days, level, resid) {
  tr <- if (days) identity else log
  bt <- if (days) identity else exp
  lx <- tr(unname(x))
  ly <- tr(unname(y))
  l0 <- tr(unname(x0))
  n <- length(ly)
  lo <- hi <- rep(NA_real_, length(l0))
  q <- c((1 - level) / 2, (1 + level) / 2)
  if (method == "ols") {
    sxx <- sum((lx - mean(lx))^2)
    if (!(sxx > 0)) stop("the donor's values do not vary over the target's years", call. = FALSE)
    b <- sum((lx - mean(lx)) * (ly - mean(ly))) / sxx
    a <- mean(ly) - b * mean(lx)
    fit <- a + b * l0
    if (n > 2) {
      s <- sqrt(sum((ly - a - b * lx)^2) / (n - 2))
      half <- stats::qt(q[2], n - 2) * s * sqrt(1 + 1 / n + (l0 - mean(lx))^2 / sxx)
      lo <- fit - half
      hi <- fit + half
    }
  } else {
    if (method == "move1") {
      sx <- stats::sd(lx)
      if (!(sx > 0)) stop("the donor's values do not vary over the target's years", call. = FALSE)
      # a target with no variation has slope 0 whatever r is, and cor() would warn
      r <- if (stats::sd(ly) > 0) stats::cor(lx, ly) else 0
      sgn <- if (is.na(r) || r == 0) 1 else sign(r)
      fit <- mean(ly) + sgn * stats::sd(ly) / sx * (l0 - mean(lx))
    } else {
      fit <- tr(unname(x0) * mean(unname(y)) / mean(unname(x)))
    }
    if (length(resid) && any(!is.na(resid))) {
      rq <- stats::quantile(resid, q, na.rm = TRUE, names = FALSE)
      lo <- fit + rq[1]
      hi <- fit + rq[2]
    }
  }
  list(fit = bt(fit), lower = bt(lo), upper = bt(hi))
}

# Predictor space for donor distances: easting and northing in km (EPSG:3005)
# and log drainage area, each divided by its SD over the rows given. Rows are
# named by station number. Shared by wet_window_extend() and
# wet_departure_carry().
wet_station_space <- function(stations) {
  need <- c("station_number", "lon", "lat", "drainage_area_gross_km2")
  miss <- setdiff(need, names(stations))
  if (length(miss)) stop("`stations` is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (anyDuplicated(stations$station_number)) stop("`stations` repeats a station number", call. = FALSE)
  bad <- !stats::complete.cases(stations[need[-1]]) | !(stations$drainage_area_gross_km2 > 0)
  if (any(bad)) {
    stop("`stations` has no coordinates or no positive drainage area for: ",
         paste(stations$station_number[bad], collapse = ", "), call. = FALSE)
  }
  xy <- terra::project(cbind(stations$lon, stations$lat), "EPSG:4326", "EPSG:3005")
  m <- cbind(e_km = xy[, 1] / 1000, n_km = xy[, 2] / 1000, log_area = log(stations$drainage_area_gross_km2))
  if (nrow(m) > 1) {
    s <- apply(m, 2, stats::sd)
    s[!(s > 0)] <- 1
    m <- sweep(m, 2, s, "/")
  }
  rownames(m) <- stations$station_number
  m
}
