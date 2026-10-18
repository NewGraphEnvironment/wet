#' Within-month weights for watersheds, and the daily flows they give
#'
#' `wet_shape_predict()` applies a [wet_shape_fit()]. `wet_shape_flat()` and
#' `wet_shape_spline()` are the two candidates that need no gauge: flat gives
#' every day of a month the same weight (what a reader of monthly means
#' assumes), and spline draws a periodic cubic spline through the 12 monthly
#' means at mid-month, floors it at 0 and takes each month's days as their
#' part of the month's spline total. `wet_shape_daily()` lays monthly means
#' onto a 365-day common year: `q[d] = Q[m(d)] * days[m(d)] * w[d]`, so the
#' mean of any calendar month's days is that month's `Q`, whatever the
#' weights.
#'
#' Every result has one row per watershed and 365 columns, and the weights
#' of each month sum to 1. `wet_shape_predict()` and `wet_shape_spline()`
#' carry a `"flat"` attribute, a logical matrix flagging the months that fell
#' back to flat.
#'
#' @param fit A [wet_shape_fit()].
#' @param d `data.frame` of the watersheds, with the fit's `static` columns.
#' @param shares Matrix of the watersheds' 12 monthly shares, required by a
#'   `"basis"` fit made with shares.
#' @param n Number of watersheds.
#' @param q_month Matrix of monthly means, 12 columns, one row per watershed
#'   (a vector is one watershed); any unit proportional to volume per day.
#' @param w Matrix of within-month weights, 365 columns, one row per row of
#'   `q_month`.
#' @return A numeric matrix with 365 columns.
#' @examples
#' m <- wet:::wet_doy_month()
#' q <- c(2, 2, 3, 8, 20, 15, 6, 3, 2, 3, 3, 2)  # monthly mean flows
#' w <- wet_shape_spline(q)
#' daily <- wet_shape_daily(q, w)
#' all.equal(unname(tapply(daily[1, ], m, mean)), q)  # each month's mean is kept
#' plot(daily[1, ], type = "l", xlab = "day", ylab = "m3/s")
#' @name wet_shape_predict
NULL

#' @rdname wet_shape_predict
#' @export
wet_shape_predict <- function(fit, d, shares = NULL) {
  stopifnot(inherits(fit, "wet_shape_fit"))
  if (!is.data.frame(d)) stop("`d` must be a data frame", call. = FALSE)
  x <- wet_shape_static(d, fit$static)
  n <- wet_doy_days()
  m <- wet_doy_month()
  if (fit$method == "donor") {
    xs <- sweep(x, 2, fit$sd, "/")
    w <- t(apply(xs, 1, function(r) {
      dist <- sqrt(colSums((t(fit$x) - r)^2))
      o <- order(dist)[seq_len(fit$k)]
      dd <- dist[o]
      wt <- if (any(dd == 0)) as.numeric(dd == 0) else 1 / (dd + 1e-6 * stats::median(dist))
      colSums(fit$w[o, , drop = FALSE] * wt) / sum(wt)
    }))
    w <- matrix(w, nrow = nrow(x), ncol = 365)
    flat <- matrix(FALSE, nrow(x), 12)
  } else {
    if (fit$uses_shares) {
      if (is.null(shares)) stop("this fit was made with monthly shares: give `shares`", call. = FALSE)
      shares <- wet_shape_months(shares)
      if (nrow(shares) != nrow(x) || anyNA(shares)) {
        stop("`shares` must be one complete row per watershed", call. = FALSE)
      }
      x <- cbind(x, shares)
    } else if (!is.null(shares)) {
      stop("this fit was made without monthly shares", call. = FALSE)
    }
    scores <- cbind(1, x) %*% fit$coef
    y <- sweep(scores %*% t(fit$basis), 2, fit$centre, "+")
    y[y < 0] <- 0
    w <- wet_shape_within(y / n[m][col(y)])
    flat <- attr(w, "flat")
  }
  dimnames(w) <- NULL
  structure(w, flat = flat)
}

#' @rdname wet_shape_predict
#' @export
wet_shape_flat <- function(n) {
  if (!is.numeric(n) || length(n) != 1 || n < 0) stop("`n` must be one non-negative number", call. = FALSE)
  w <- matrix(1 / wet_doy_days()[wet_doy_month()], nrow = n, ncol = 365, byrow = TRUE)
  dimnames(w) <- NULL
  w
}

#' @rdname wet_shape_predict
#' @export
wet_shape_spline <- function(q_month) {
  q <- wet_shape_months(q_month)
  if (anyNA(q)) stop("`q_month` has NA months", call. = FALSE)
  n <- wet_doy_days()
  mid <- cumsum(n) - n / 2 + 0.5  # mid-month, in days of the common year
  y <- t(apply(q, 1, function(r) {
    f <- stats::splinefun(c(mid, mid[1] + 365), c(r, r[1]), method = "periodic")
    pmax(f(1:365), 0)
  }))
  y <- matrix(y, nrow = nrow(q), ncol = 365)
  wet_shape_within(y)
}

#' @rdname wet_shape_predict
#' @export
wet_shape_daily <- function(q_month, w) {
  q <- wet_shape_months(q_month)
  w <- wet_shape_matrix(w)
  if (nrow(w) != nrow(q)) stop("`w` must have one row per row of `q_month`", call. = FALSE)
  m <- wet_doy_month()
  n <- wet_doy_days()
  tot <- t(apply(w, 1, function(r) tapply(r, m, sum)))
  tot <- matrix(tot, nrow = nrow(w))
  if (anyNA(tot) || any(abs(tot - 1) > 1e-8)) stop("the weights of every month must sum to 1", call. = FALSE)
  out <- q[, m, drop = FALSE] * n[m][col(w)] * w
  attributes(out) <- list(dim = dim(out))  # no dimnames, and not `w`'s "flat" flags
  out
}
