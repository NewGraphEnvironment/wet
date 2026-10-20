# Routed PCIC flow per segment and day of a common year (#99), from fwapg's
# sub-basin day-of-year climatology and per-segment weights
# (NewGraphEnvironment/fwapg#25: pcic.subbasin_daily, pcic.segment_weights).
# A segment's flow over any set of days is
#
#   greatest(sum(q_acc of upstream_subids) + q_local(subid) * share, 0)
#
# with q_acc and q_local first averaged over the days, weighted by n_days
# (fwapg's pcic_crosswalk08_periods.sql and 09_discharge.sql). A day is one
# bin, so its value is routed and then clamped on its own. fwapg rounds the
# clamped flow to 5 decimals (round(q::numeric, 5)), and so does this.

# The 366 calendar bins of each sub-basin folded onto the 365-day common year
# of wet_doy_month(): 29 February goes into 28 February by the n_days
# weights, on q_local and q_acc alike, which commutes with the weights since
# routing is linear. `d` holds subid, month, day, n_days, q_local, q_acc, one
# row per sub-basin and bin. Returns list(subid, q_local, q_acc, n_days):
# sub-basins in increasing subid, two matrices of one row per sub-basin and
# 365 columns, and the 365 folded day weights (the same for every sub-basin).
wet_routed_fold <- function(d) {
  need <- c("subid", "month", "day", "n_days", "q_local", "q_acc")
  if (!is.data.frame(d) || !all(need %in% names(d))) {
    stop("`d` needs columns ", paste(need, collapse = ", "), call. = FALSE)
  }
  if (anyNA(d[need])) stop("`d` has NA values", call. = FALSE)
  md <- c(wet_doy_md(), "02-29")
  key <- sprintf("%02d-%02d", as.integer(d$month), as.integer(d$day))
  bin <- match(key, md)
  if (anyNA(bin)) stop("`d` has a month and day that is not a calendar day", call. = FALSE)
  subid <- sort(unique(as.integer(d$subid)))
  row <- match(as.integer(d$subid), subid)
  if (anyDuplicated(row * 400L + bin) || nrow(d) != 366L * length(subid)) {
    stop("`d` must hold each sub-basin's 366 calendar bins once", call. = FALSE)
  }
  n366 <- matrix(NA_real_, length(subid), 366L)
  n366[cbind(row, bin)] <- as.numeric(d$n_days)
  # every sub-basin of a run has the same days
  if (any(n366 != rep(n366[1, ], each = length(subid))) || any(n366[1, ] <= 0)) {
    stop("`d`'s n_days differ between sub-basins, or are not positive", call. = FALSE)
  }
  n <- n366[1, ]
  feb28 <- match("02-28", md)
  fold <- function(v) {
    m <- matrix(NA_real_, length(subid), 366L)
    m[cbind(row, bin)] <- as.numeric(v)
    m[, feb28] <- (m[, feb28] * n[feb28] + m[, 366L] * n[366L]) / (n[feb28] + n[366L])
    m[, 1:365, drop = FALSE]
  }
  n_days <- n[1:365]
  n_days[feb28] <- n[feb28] + n[366L]
  list(subid = subid, q_local = fold(d$q_local), q_acc = fold(d$q_acc), n_days = n_days)
}

# Flow before the clamp on each segment and day: a matrix of one row per row
# of `weights` (linear_feature_id, subid, share, upstream_subids, the last a
# list of integer vectors) and one column per column of the fold's matrices,
# so a fold averaged to months or weeks gives months or weeks. A segment's
# upstream sub-basins are summed in the order its upstream_subids lists them.
wet_routed_raw <- function(fold, weights) {
  need <- c("linear_feature_id", "subid", "share", "upstream_subids")
  if (!is.data.frame(weights) || !all(need %in% names(weights)) || !is.list(weights$upstream_subids)) {
    stop("`weights` needs columns ", paste(need, collapse = ", "), ", upstream_subids a list", call. = FALSE)
  }
  if (anyNA(weights$subid) || anyNA(weights$share)) stop("`weights` has an NA subid or share", call. = FALSE)
  up <- weights$upstream_subids
  len <- lengths(up)
  ids <- as.integer(unlist(up, use.names = FALSE))
  at <- match(ids, fold$subid)
  own <- match(as.integer(weights$subid), fold$subid)
  if (anyNA(at) || anyNA(own)) stop("`weights` names a sub-basin the fold does not hold", call. = FALSE)
  out <- fold$q_local[own, , drop = FALSE] * as.numeric(weights$share)
  if (length(ids)) {
    seg <- rep(seq_len(nrow(weights)), len)
    s <- rowsum(fold$q_acc[at, , drop = FALSE], seg, reorder = FALSE)
    i <- unique(seg)
    out[i, ] <- s + out[i, , drop = FALSE]
  }
  dimnames(out) <- NULL
  out
}

# fwapg's rounding of a clamped flow, round(q::numeric, 5): Postgres turns a
# double into numeric through its 15 significant digits and rounds half away
# from zero. R's round() agrees except on a 15-digit value that sits exactly
# half way, so those few are rounded from their digits.
wet_routed_round <- function(x) {
  y <- round(x, 5)
  f <- abs(x) * 1e5
  # f carries an error of a few ulps, so the window widens with it
  near <- which(is.finite(x) & abs(f - floor(f) - 0.5) < 1e-6 + 8 * .Machine$double.eps * f)
  if (length(near)) {
    s <- formatC(abs(x[near]), digits = 15, format = "fg", flag = "#")
    int <- sub("\\..*$", "", s)
    frac <- substr(paste0(sub("^[^.]*\\.?", "", s), "000000"), 1, 6)
    units <- as.numeric(int) * 1e5 + as.numeric(substr(frac, 1, 5)) + (substr(frac, 6, 6) >= "5")
    y[near] <- sign(x[near]) * as.numeric(sprintf("%.0f.%05.0f", floor(units / 1e5), units %% 1e5))
  }
  y
}

# Published routed flow on each segment and day: clamped at 0, then rounded.
wet_routed_days <- function(fold, weights) {
  raw <- wet_routed_raw(fold, weights)
  out <- wet_routed_round(pmax(raw, 0))
  dim(out) <- dim(raw)
  structure(out, clamped = raw < 0)
}

# A fold averaged over groups of its days (months 1-12, or weeks), weighted
# by n_days, as fwapg's pcic_crosswalk08_periods.sql averages the bins:
# `by` gives each of the 365 days its group.
wet_routed_period <- function(fold, by) {
  stopifnot(length(by) == 365L, !anyNA(by))
  g <- sort(unique(by))
  avg <- function(m) {
    vapply(g, function(k) {
      j <- which(by == k)
      as.vector(m[, j, drop = FALSE] %*% fold$n_days[j]) / sum(fold$n_days[j])
    }, numeric(nrow(m)))
  }
  list(subid = fold$subid, q_local = matrix(avg(fold$q_local), ncol = length(g)),
       q_acc = matrix(avg(fold$q_acc), ncol = length(g)), n_days = NULL, period = g)
}
