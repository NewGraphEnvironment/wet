#' Fit a within-month daily shape at gauges
#'
#' The water balance's daily shape within the month (#70): where a month's
#' water falls among its days, carried from gauges to ungauged watersheds. A
#' gauge's within-month weights `w` are its day-of-year flow divided by its
#' month's total ([wet_station_doy()], then the internal
#' `wet_shape_within()`), so each month's weights sum to 1. Two methods:
#'
#' - `"donor"`: a new watershed takes the inverse-distance mean of the weights
#'   of its `k` nearest gauges in the space of the `static` predictors, each
#'   divided by the gauges' standard deviation. Distance weights are
#'   `1 / (d + 1e-6 * median(d))`; a gauge at distance 0 takes the whole
#'   weight.
#' - `"basis"`: principal components of the gauges' centred ratio to flat
#'   (`w * days`), the first `n_comp`, whose scores are regressed by ordinary
#'   least squares on the `static` predictors and, when given, the 12 monthly
#'   `shares`. A prediction is reconstructed, floored at 0 and renormalised
#'   per month; a month whose reconstruction is all 0 or less falls back to
#'   flat.
#'
#' Both apply through [wet_shape_predict()], and [wet_shape_daily()] turns
#' monthly means and weights into daily flows that keep every monthly mean.
#'
#' @param d `data.frame` of the gauges, with the `static` columns.
#' @param w Matrix of within-month weights, one row per row of `d` and 365
#'   columns (a common year).
#' @param method `"donor"` or `"basis"`.
#' @param static Names of the predictor columns in `d`.
#' @param k Donors per watershed (`"donor"`), capped at the number of gauges.
#' @param n_comp Principal components kept (`"basis"`), capped at the rank.
#' @param shares Optional matrix of the gauges' 12 monthly shares (`"basis"`
#'   only); a fit made with them needs them at prediction too.
#' @return An object of class `wet_shape_fit`.
#' @examples
#' set.seed(1)
#' m <- wet:::wet_doy_month()
#' # eight gauges: a freshet whose timing within May moves with elevation
#' d <- data.frame(elev = seq(300, 2000, length.out = 8), e_km = 1:8, n_km = 8:1)
#' q <- t(sapply(d$elev, function(e) dnorm(1:365, 120 + e / 50, 30) + 1e-3))
#' w <- wet:::wet_shape_within(q)
#' fit <- wet_shape_fit(d, w, "donor", static = c("elev", "e_km", "n_km"), k = 3)
#' w_new <- wet_shape_predict(fit, data.frame(elev = 1000, e_km = 4.5, n_km = 4.5))
#' tapply(w_new[1, ], m, sum)  # each month sums to 1
#' @export
wet_shape_fit <- function(d, w, method = c("donor", "basis"), static = c("elev", "e_km", "n_km"), k = 5,
                          n_comp = 6, shares = NULL) {
  method <- match.arg(method)
  w <- wet_shape_matrix(w)
  if (!is.data.frame(d) || nrow(d) != nrow(w)) stop("`d` must have one row per row of `w`", call. = FALSE)
  if (nrow(d) < 2) stop("at least two gauges are needed", call. = FALSE)
  x <- wet_shape_static(d, static)
  if (anyNA(w)) stop("`w` has NA days", call. = FALSE)
  if (!is.null(shares)) {
    shares <- wet_shape_months(shares)
    if (nrow(shares) != nrow(w) || anyNA(shares)) stop("`shares` must be one complete row per gauge", call. = FALSE)
  }
  sds <- apply(x, 2, stats::sd)
  if (any(!(sds > 0))) {
    stop("a static predictor is constant: ", paste(static[!(sds > 0)], collapse = ", "), call. = FALSE)
  }
  fit <- list(method = method, static = static, sd = sds, n = nrow(w), uses_shares = !is.null(shares))
  if (method == "donor") {
    fit$k <- min(as.integer(k), nrow(w))
    fit$x <- sweep(x, 2, sds, "/")
    fit$w <- w
  } else {
    if (!is.null(shares)) x <- cbind(x, shares)
    y <- w * wet_doy_days()[wet_doy_month()][col(w)]
    fit$centre <- colMeans(y)
    sv <- svd(sweep(y, 2, fit$centre))
    rank <- sum(sv$d > sv$d[1] * 1e-10)
    fit$n_comp <- min(as.integer(n_comp), rank)
    fit$basis <- sv$v[, seq_len(fit$n_comp), drop = FALSE]
    scores <- sweep(y, 2, fit$centre) %*% fit$basis
    xx <- cbind(1, x)
    if (nrow(xx) <= ncol(xx)) stop("more predictors than gauges", call. = FALSE)
    co <- stats::lm.fit(xx, scores)$coefficients
    co[is.na(co)] <- 0
    fit$coef <- matrix(co, nrow = ncol(xx))
  }
  class(fit) <- "wet_shape_fit"
  fit
}

# The static predictors of `d` as a complete numeric matrix
wet_shape_static <- function(d, static) {
  miss <- setdiff(static, names(d))
  if (length(miss)) stop("`d` is missing ", paste(miss, collapse = ", "), call. = FALSE)
  x <- as.matrix(d[static])
  if (!is.numeric(x) || anyNA(x)) stop("the static predictors must be numeric and complete", call. = FALSE)
  x
}
