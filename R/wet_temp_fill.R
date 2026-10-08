#' Daily water temperature with gaps filled from air temperature
#'
#' Fills the missing days in daily water-temperature series, one station at a
#' time, with the daily air2stream model in its three-parameter form
#' (Toffolon & Piccolroaz 2015):
#' \deqn{S_t = S_{t-1} + a_1 + a_2 A_t - a_3 S_{t-1}}
#' where \eqn{A} is the daily mean air temperature, and a departure from it
#' that the station's own observations and its peers' carry across a gap. The
#' result keeps every observed day as it is and adds the filled days, so a
#' growing season cut by an outage or by a seasonal logger becomes complete
#' enough for [wet_temp_gsdd()].
#'
#' @section How a gap is filled:
#' The daily mean water temperature is \eqn{W_t = S_t + u_t}:
#' \itemize{
#'   \item \eqn{S_t} is air2stream run open-loop, from air temperature alone,
#'     floored at 0 °C for ice. Its parameters are fitted by least squares
#'     over the observed days, as air2stream is calibrated. On a long gap the
#'     fill falls back to it.
#'   \item \eqn{u_t} is the departure from \eqn{S_t}, an AR(1) process
#'     \eqn{u_t = \rho u_{t-1} + b \bar{e}_t + \epsilon_t}, run through a Kalman
#'     filter and smoother. Each observed day sets it to the observed departure
#'     (up to a small measurement error, `obs_sd`), so the fill restarts from
#'     every observed day. The smoother also uses the observation at the far
#'     end of a gap, so the fill meets it without a jump. The interval is
#'     narrow beside observed days and widest in the middle of a gap.
#'   \item \eqn{\bar{e}_t} is the mean one-step error of the departures of the
#'     *other* stations in the same `pool` that were observed that day and the
#'     day before: weather that air temperature does not carry (cloud, rain,
#'     snowmelt). \eqn{b} is fitted per station once at least 180 of its
#'     observed days have a peer error. A station that does not follow its peers,
#'     such as a lake outlet, gets \eqn{b} near 0. So pool stations that share
#'     weather, such as one basin's: the Skeena network model found the shared
#'     part still correlated at about 0.9 over 300 km
#'     (`research/station_temperature_fill.md`). A peer error beyond 4 of that
#'     peer's \eqn{\sigma} (a logger out of the water) is clipped.
#' }
#'
#' Each station is fitted alone: \eqn{a_1, a_2, a_3} with [stats::optim()] on
#' the open-loop squared error, then \eqn{\rho}, \eqn{b} and the daily noise
#' \eqn{\sigma} by maximum likelihood. The peer errors come from a first fit
#' of every station with \eqn{b = 0}, so no station's error depends on its own
#' data. The fit uses every observed day with air temperature, whatever `from`
#' and `to` say. Separating \eqn{S} from \eqn{u} is what makes a long gap
#' work: fitted as one recursion by its one-step likelihood, air2stream takes
#' too much persistence and drifts over a season (`research/station_temperature_fill.md`).
#'
#' @section Skill:
#' Held out at 999 station-years of ECCC gauges (`research/station_temperature_fill.md`),
#' mean daily error was 0.48 °C on 7-day gaps, 0.76 °C on 30-day gaps and 0.84 °C
#' on a seasonal logger's missing spring and autumn, against 1.31, 1.43 and 1.14 °C
#' for open-loop air2stream. Over a whole missing season the daily error was
#' 1.12 against 1.29 °C, but GSDD was no better (mean absolute error 130 against
#' 129 °C-days). The interval covered 89-94 % of held-out days at a nominal 95 %.
#'
#' @section Air temperature and days:
#' `air` is the output of `cd::cd_extract_daily()`, which samples ERA5-Land on
#' local days at a fixed UTC−8. [wet_temp_daily()] uses each station's own
#' standard offset, so for the stations on UTC−7 (the Peace and parts of the
#' Kootenays) the two are an hour apart. That is not corrected. Gaps of up to
#' three days in a station's air temperature are interpolated linearly; a
#' station whose air has a longer gap inside its range is returned unfilled,
#' with a warning. Days outside the range of air temperature are not filled.
#'
#' @param temp Daily water temperature in the shape of [wet_temp_daily()]: at
#'   least `station_number`, `date` and `t_mean_c`, from any source (loggers
#'   included). Rows with no date, station or value are dropped.
#' @param air Daily air temperature in the shape of `cd::cd_extract_daily()`:
#'   `id` (the station number), `date`, `variable` and `value` (°C). Only rows
#'   with `variable == "tmean"` are used.
#' @param pool `NULL` (every station in the call shares its anomaly), or a
#'   character vector of groups named by `station_number`, e.g. the WSC
#'   sub-drainage `substr(station_number, 1, 3)`. Peers come only from a
#'   station's own group.
#' @param from,to First and last day to fill, as `Date` or `"YYYY-MM-DD"`.
#'   `NULL` (the default) uses each station's first and last observed day. A
#'   seasonal logger needs `from` and `to` to cover the growing season (March
#'   to November) before [wet_temp_gsdd()] can give a value; there the fill is
#'   anchored on one side only. Observed days outside `from` and `to` are still
#'   returned, and still used in the fit.
#' @param min_days Observed days with air temperature that a station needs to be
#'   fitted. A station with fewer is returned unfilled, with a warning.
#' @param obs_sd Measurement error of an observed daily mean, °C.
#' @param level Coverage of the interval on filled days.
#' @return A data frame with the columns of `temp`, plus `filled` (`TRUE` on a
#'   filled day), `t_lo_c` and `t_hi_c` (the interval, equal to `t_mean_c` on
#'   an observed day), one row per station-day, ordered by station and date.
#'   On filled days `source` is `"air2stream"`, `status` is `"provisional"`
#'   (never final, so [wet_window_stats()] counts them in `frac_provisional`),
#'   `n_hours` is 0 and `t_min_c` and `t_max_c` are `NA`. Rows of `temp` that
#'   are already `filled` are dropped first, so a result can be filled again.
#'   The interval is per day: summing `t_lo_c` or `t_hi_c` does not bound a
#'   sum such as GSDD. The attribute `fit` holds one row per fitted station:
#'   `a1`, `a2`, `a3` (open-loop air2stream), `rmse_open` (its in-sample error,
#'   °C), `rho`, `b`, `sigma` (the departure), `n_obs` (observed days used) and
#'   `loglik`.
#' @references Toffolon, M. and Piccolroaz, S. 2015. A hybrid model for river
#'   water temperature as a function of air temperature and discharge.
#'   Environmental Research Letters 10: 114011. doi:10.1088/1748-9326/10/11/114011.
#' @examples
#' # Three years of air temperature and one station that tracks it
#' date <- seq(as.Date("2018-01-01"), as.Date("2020-12-31"), by = "day")
#' set.seed(1)
#' a <- 4 + 13 * sin(2 * pi * (as.integer(format(date, "%j")) - 110) / 365) +
#'   as.numeric(stats::filter(rnorm(length(date), 0, 2), 0.7, method = "recursive"))
#' w <- numeric(length(date))
#' for (t in 2:length(date)) {
#'   w[t] <- max(0, 0.82 * w[t - 1] + 0.6 + 0.12 * a[t] + rnorm(1, 0, 0.25))
#' }
#' air <- data.frame(id = "08AA001", date = date, variable = "tmean", value = a)
#' temp <- data.frame(station_number = "08AA001", date = date, t_mean_c = w)
#'
#' # The logger was out of the water for July and August 2019
#' gap <- date >= as.Date("2019-07-01") & date <= as.Date("2019-08-31")
#' f <- wet_temp_fill(temp[!gap, ], air)
#' attr(f, "fit")
#'
#' # The fill against what the logger would have read
#' i <- f$filled
#' sqrt(mean((f$t_mean_c[i] - w[gap])^2))
#' plot(date[gap], w[gap], type = "l", xlab = "", ylab = "Water temperature (°C)")
#' lines(f$date[i], f$t_mean_c[i], col = "blue")
#' lines(f$date[i], f$t_lo_c[i], col = "blue", lty = 2)
#' lines(f$date[i], f$t_hi_c[i], col = "blue", lty = 2)
#' @export
wet_temp_fill <- function(temp, air, pool = NULL, from = NULL, to = NULL, min_days = 365,
                          obs_sd = 0.1, level = 0.95) {
  if (!is.data.frame(temp) || !all(c("station_number", "date", "t_mean_c") %in% names(temp))) {
    stop("`temp` must be a data frame with station_number, date and t_mean_c", call. = FALSE)
  }
  if (!is.data.frame(air) || !all(c("id", "date", "variable", "value") %in% names(air))) {
    stop("`air` must be a data frame with id, date, variable and value, as from cd::cd_extract_daily()",
         call. = FALSE)
  }
  if (!inherits(temp$date, "Date") || !inherits(air$date, "Date")) {
    stop("`temp$date` and `air$date` must be Dates", call. = FALSE)
  }
  if (!is.numeric(min_days) || length(min_days) != 1 || is.na(min_days) || min_days < 10) {
    stop("`min_days` must be one number of at least 10", call. = FALSE)
  }
  if (!is.numeric(obs_sd) || length(obs_sd) != 1 || !is.finite(obs_sd) || obs_sd <= 0) {
    stop("`obs_sd` must be one positive number", call. = FALSE)
  }
  if (!is.numeric(level) || length(level) != 1 || !is.finite(level) || level <= 0 || level >= 1) {
    stop("`level` must be one number between 0 and 1", call. = FALSE)
  }
  if (!is.null(pool) && (!is.character(pool) || is.null(names(pool)) || anyNA(pool))) {
    stop("`pool` must be a character vector of groups named by station_number", call. = FALSE)
  }
  from <- wet_fill_day(from, "from")
  to <- wet_fill_day(to, "to")
  if (!is.null(from) && !is.null(to) && from > to) stop("`from` is after `to`", call. = FALSE)
  temp <- wet_fill_clean(temp)
  if (!is.null(pool) && !all(unique(temp$station_number) %in% names(pool))) {
    stop("`pool` has no group for: ",
         paste(setdiff(unique(temp$station_number), names(pool)), collapse = ", "), call. = FALSE)
  }
  r2 <- obs_sd^2
  prep <- wet_fill_prepare(temp, air, pool, from, to, min_days, r2)
  if (length(prep$short)) {
    warning("too few observed days with air temperature to fill: ",
            paste(prep$short, collapse = ", "), call. = FALSE)
  }
  if (length(prep$air_gap)) {
    warning("air temperature has a gap of more than ", wet_air_gap, " days, not filled: ",
            paste(prep$air_gap, collapse = ", "), call. = FALSE)
  }

  out <- list()
  fits <- list()
  for (s in prep$stations) {
    obs <- wet_fill_observed(temp[temp$station_number == s, ])
    if (!s %in% prep$fit_st) {
      out[[s]] <- obs
      next
    }
    st <- wet_fill_station(prep, s, r2)
    fits[[s]] <- st$fit
    gap <- is.na(st$y) & st$fill
    v <- wet_fill_values(st, level)
    filled <- data.frame(station_number = rep(s, sum(gap)), date = st$date[gap],
                         t_mean_c = v$t_mean_c[gap])
    fl <- wet_fill_rows(obs[0, ], filled)
    fl$t_lo_c <- v$t_lo_c[gap]
    fl$t_hi_c <- v$t_hi_c[gap]
    o <- rbind(obs, fl)
    out[[s]] <- o[order(o$date), ]
  }
  res <- do.call(rbind, out)
  if (is.null(res)) {
    res <- wet_fill_observed(temp[0, ])
  }
  res <- res[order(res$station_number, res$date), ]
  rownames(res) <- NULL
  fit <- do.call(rbind, fits)
  if (is.null(fit)) {
    fit <- data.frame(station_number = character(), a1 = numeric(), a2 = numeric(), a3 = numeric(),
                      rmse_open = numeric(), rho = numeric(), b = numeric(), sigma = numeric(),
                      n_obs = integer(), loglik = numeric())
  }
  rownames(fit) <- NULL
  attr(res, "fit") <- fit
  res
}

# Air gaps longer than this many days are not interpolated across.
wet_air_gap <- 3

# `from` or `to` as one Date, or NULL.
wet_fill_day <- function(x, arg) {
  if (is.null(x)) return(NULL)
  d <- tryCatch(as.Date(x), error = function(e) as.Date(NA))
  if (length(d) != 1 || is.na(d)) stop("`", arg, "` must be one date", call. = FALSE)
  d
}

# Observed rows only: no filled day from an earlier call, no row without a
# date, station or value, one row per station-day.
wet_fill_clean <- function(temp) {
  if ("filled" %in% names(temp)) temp <- temp[!temp$filled %in% TRUE, ]
  temp <- temp[!is.na(temp$t_mean_c) & !is.na(temp$date) & !is.na(temp$station_number), ]
  temp$station_number <- as.character(temp$station_number)
  if (anyDuplicated(temp[c("station_number", "date")])) {
    stop("`temp` has more than one row for a station-day", call. = FALSE)
  }
  temp
}

# Everything that does not depend on a station's peers: its calendar, its
# open-loop fit, its departure, the first (b = 0) fit and its one-step errors.
# `temp` is clean (wet_fill_clean()); `pool` is NULL or covers its stations.
wet_fill_prepare <- function(temp, air, pool, from, to, min_days, r2) {
  stations <- unique(temp$station_number)
  air <- air[air$id %in% stations & air$variable %in% "tmean" & !is.na(air$value) & !is.na(air$date), ]
  air$id <- as.character(air$id)
  air <- split(air[c("date", "value")], factor(air$id, levels = stations))
  if (any(vapply(air, function(a) anyDuplicated(a$date) > 0, logical(1)))) {
    stop("`air` has more than one tmean row for a station-day", call. = FALSE)
  }
  group <- if (is.null(pool)) stats::setNames(rep("all", length(stations)), stations) else pool[stations]
  air_gap <- character()
  # Each station on a full calendar over its record and its fill range,
  # clipped to the air. `fill` marks the days the caller asked to fill.
  series <- lapply(stations, function(s) {
    ts <- temp[temp$station_number == s, ]
    as_ <- air[[s]]
    if (nrow(as_) < 2) return(NULL)
    f_lo <- if (is.null(from)) min(ts$date) else from
    f_hi <- if (is.null(to)) max(ts$date) else to
    lo <- max(min(ts$date, f_lo), min(as_$date))
    hi <- min(max(ts$date, f_hi), max(as_$date))
    if (lo > hi) return(NULL)
    date <- seq(lo, hi, by = "day")
    # a hole in the air that overlaps the calendar, wherever it lies: inside,
    # across either end, or around the whole of it
    ad <- sort(as_$date)
    h <- which(diff(as.numeric(ad)) > wet_air_gap + 1)
    if (any(ad[h] < hi & ad[h + 1] > lo)) {
      air_gap <<- c(air_gap, s)
      return(NULL)
    }
    a <- stats::approx(as.numeric(as_$date), as_$value, xout = as.numeric(date), rule = 1)$y
    y <- ts$t_mean_c[match(date, ts$date)]
    list(date = date, a = a, y = y, fill = date >= f_lo & date <= f_hi)
  })
  names(series) <- stations
  n_obs <- vapply(series, function(z) if (is.null(z)) 0L else sum(!is.na(z$y)), integer(1))
  short <- setdiff(stations[n_obs < min_days], air_gap)
  fit_st <- stations[n_obs >= min_days]

  # Open-loop air2stream per station, then a first fit of each departure with
  # b = 0. Its one-step errors on days observed after an observed day make the
  # peer signal; one beyond 4 sigma is clipped.
  open <- lapply(fit_st, function(s) wet_a2s_fit(series[[s]]$y, series[[s]]$a))
  dep <- lapply(seq_along(fit_st), function(k) series[[fit_st[k]]]$y - open[[k]]$s)
  first <- lapply(dep, function(r) wet_kf_fit(r, NULL, r2))
  err <- lapply(seq_along(fit_st), function(k) {
    r <- dep[[k]]
    n <- length(r)
    e <- c(NA_real_, r[-1] - first[[k]]$par[["rho"]] * r[-n])
    lim <- 4 * first[[k]]$par[["sigma"]]
    stats::setNames(pmin(pmax(e, -lim), lim), as.character(as.integer(series[[fit_st[k]]]$date)))
  })
  names(open) <- names(dep) <- names(first) <- names(err) <- fit_st
  list(stations = stations, group = group, series = series, n_obs = n_obs, short = short,
       air_gap = air_gap, fit_st = fit_st, open = open, dep = dep, first = first, err = err)
}

# Fit and smooth one prepared station: its peers' errors make ebar, b is fitted
# when enough observed days have one. `peers = FALSE` fits with b = 0.
wet_fill_station <- function(prep, s, r2, peers = TRUE) {
  z <- prep$series[[s]]
  key <- as.character(as.integer(z$date))
  fit_st <- prep$fit_st
  pe <- if (peers) setdiff(fit_st[prep$group[fit_st] == prep$group[[s]]], s) else character()
  ebar <- NULL
  if (length(pe)) {
    m <- vapply(pe, function(p) unname(prep$err[[p]][key]), numeric(length(key)))
    m <- matrix(m, nrow = length(key))
    cnt <- rowSums(!is.na(m))
    ebar <- ifelse(cnt > 0, rowSums(m, na.rm = TRUE) / pmax(cnt, 1), 0)
    # b is only fitted with enough observed days that have a peer error
    if (sum(cnt > 0 & !is.na(z$y)) < 180) ebar <- NULL
  }
  dep <- prep$dep[[s]]
  first <- prep$first[[s]]
  f <- if (is.null(ebar)) first else wet_kf_fit(dep, ebar, r2, start = first$par)
  sm <- wet_kf_run(f$par, dep, ebar, r2, smooth = TRUE)
  op <- prep$open[[s]]
  fit <- data.frame(station_number = s, a1 = op$par[["a1"]], a2 = op$par[["a2"]], a3 = op$par[["a3"]],
                    rmse_open = op$rmse, rho = f$par[["rho"]], b = f$par[["b"]],
                    sigma = f$par[["sigma"]], n_obs = prep$n_obs[[s]], loglik = f$loglik)
  list(date = z$date, y = z$y, fill = z$fill, s_open = op$s, mean = sm$mean, var = sm$var,
       fmean = sm$fmean, par = f$par, fit = fit)
}

# The fill and its interval on every day of a fitted station's calendar:
# open-loop plus smoothed departure, floored at 0 for ice.
wet_fill_values <- function(st, level) {
  est <- st$s_open + st$mean
  half <- stats::qnorm(1 - (1 - level) / 2) * sqrt(st$var)
  data.frame(date = st$date, t_mean_c = pmax(est, 0), t_lo_c = pmax(est - half, 0),
             t_hi_c = pmax(est + half, 0))
}

# A prepared pool with station s's entries taken from `one`, a preparation of
# s alone (for held-out scoring: peers' entries depend only on their own data).
wet_fill_swap <- function(prep, one, s) {
  for (k in c("series", "n_obs")) prep[[k]][s] <- one[[k]][s]
  for (k in c("open", "dep", "first", "err")) prep[[k]][s] <- one[[k]][s]
  if (!s %in% prep$fit_st) prep$fit_st <- c(prep$fit_st, s)
  prep
}

# Observed rows as they came, with the fill columns added.
wet_fill_observed <- function(ts) {
  ts$filled <- rep(FALSE, nrow(ts))
  ts$t_lo_c <- ts$t_mean_c
  ts$t_hi_c <- ts$t_mean_c
  ts
}

# Filled days in the columns of the observed rows `tmpl` (zero rows).
wet_fill_rows <- function(tmpl, filled) {
  n <- nrow(filled)
  out <- tmpl[rep(NA_integer_, n), , drop = FALSE]
  out$station_number <- filled$station_number
  out$date <- filled$date
  out$t_mean_c <- filled$t_mean_c
  if ("n_hours" %in% names(out)) out$n_hours <- rep(0L, n)
  if ("source" %in% names(out)) out$source <- rep("air2stream", n)
  # not final, so wet_window_stats() counts it in frac_provisional
  if ("status" %in% names(out)) out$status <- rep("provisional", n)
  out$filled <- rep(TRUE, n)
  rownames(out) <- NULL
  out
}

# Open-loop air2stream from the first day's equilibrium, floored at 0.
wet_a2s_run <- function(a1, a2, a3, a) {
  n <- length(a)
  s <- numeric(n)
  s[1] <- max((a1 + a2 * a[1]) / a3, 0)
  if (n > 1) {
    phi <- 1 - a3
    u <- a1 + a2 * a
    for (t in 2:n) {
      v <- phi * s[t - 1] + u[t]
      s[t] <- if (v > 0) v else 0
    }
  }
  s
}

# Least-squares fit of open-loop air2stream to the observed days, from two
# starting time constants; a3 = plogis(.) keeps it in (0, 1).
wet_a2s_fit <- function(y, a) {
  i <- which(!is.na(y))
  sse <- function(th) {
    if (!all(is.finite(th))) return(1e10)
    s <- wet_a2s_run(th[1], th[2], stats::plogis(th[3]), a)
    v <- mean((s[i] - y[i])^2)
    if (is.finite(v)) v else 1e10
  }
  best <- NULL
  for (a3 in c(0.05, 0.15)) {
    o <- stats::optim(c(0.5, 0.1, stats::qlogis(a3)), sse, control = list(maxit = 4000))
    if (is.null(best) || o$value < best$value) best <- o
  }
  par <- c(a1 = best$par[1], a2 = best$par[2], a3 = stats::plogis(best$par[3]))
  list(par = par, s = wet_a2s_run(par[["a1"]], par[["a2"]], par[["a3"]], a), rmse = sqrt(best$value))
}

# Maximum-likelihood fit of a departure series: rho = plogis(.), sigma = exp(.).
wet_kf_fit <- function(r, ebar, r2, start = NULL) {
  has_b <- !is.null(ebar)
  if (is.null(start)) start <- c(rho = 0.8, b = 0, sigma = 0.3)
  # start inside the region the run allows, whatever an earlier fit reached
  th <- c(stats::qlogis(min(max(start[["rho"]], 0.01), 0.99)), log(max(start[["sigma"]], 0.01)))
  if (has_b) th <- c(th, start[["b"]])
  # the caps wet_kf_run() applies, so the reported fit is the one used
  par_of <- function(th) {
    c(rho = min(stats::plogis(th[1]), 0.999), b = if (has_b) th[3] else 0,
      sigma = max(exp(th[2]), 0.01))
  }
  nll <- function(th) {
    if (!all(is.finite(th))) return(1e10)
    v <- -wet_kf_run(par_of(th), r, ebar, r2)$loglik
    if (is.finite(v)) v else 1e10
  }
  o <- stats::optim(th, nll, method = "BFGS", control = list(maxit = 500))
  list(par = par_of(o$par), loglik = -o$value)
}

# Kalman filter (and RTS smoother) for one station's AR(1) departure.
wet_kf_run <- function(par, r, ebar, r2, smooth = FALSE) {
  n <- length(r)
  # a stuck sensor fits sigma to 0 and rho can round to 1; either makes the
  # smoother divide 0 by 0 (wet_kf_fit() reports the same caps)
  rho <- min(par[["rho"]], 0.999)
  q <- max(par[["sigma"]], 0.01)^2
  u <- if (is.null(ebar)) rep(0, n) else par[["b"]] * ebar
  # start from the stationary distribution
  m <- 0
  p <- q / (1 - rho^2)
  mp <- pp <- mf <- pf <- numeric(n)
  ll <- 0
  for (t in seq_len(n)) {
    if (t > 1) {
      mt <- rho * m + u[t]
      pt <- rho * rho * p + q
    } else {
      mt <- m
      pt <- p
    }
    mp[t] <- mt
    pp[t] <- pt
    yt <- r[t]
    if (!is.na(yt)) {
      sv <- pt + r2
      v <- yt - mt
      k <- pt / sv
      m <- mt + k * v
      p <- (1 - k) * pt
      ll <- ll - 0.5 * (log(2 * pi * sv) + v * v / sv)
    } else {
      m <- mt
      p <- pt
    }
    mf[t] <- m
    pf[t] <- p
  }
  if (!smooth) return(list(loglik = ll))
  ms <- mf
  ps <- pf
  if (n > 1) {
    for (t in (n - 1):1) {
      g <- pf[t] * rho / pp[t + 1]
      ms[t] <- mf[t] + g * (ms[t + 1] - mp[t + 1])
      ps[t] <- pf[t] + g * g * (ps[t + 1] - pp[t + 1])
    }
  }
  list(loglik = ll, mean = ms, var = pmax(ps, 0), fmean = mf)
}
