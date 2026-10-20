#' Predict monthly shares of annual runoff
#'
#' Applies a [wet_share_fit()]. The regressions' predictions are floored at 0
#' and renormalised so the 12 shares sum to 1, and a watershed whose 12
#' floored predictions are all 0 gets `NA` shares. A donor prediction is a
#' weighted mean of observed shares, so it sums to 1 already; a blend is the
#' mean of the two. A watershed missing a predictor gets `NA` shares.
#'
#' @param fit A [wet_share_fit()] result.
#' @param d `data.frame` with the predictors named in `fit`.
#' @return A matrix with one row per row of `d` and columns `share_01` to
#'   `share_12`.
#' @export
wet_share_predict <- function(fit, d) {
  stopifnot(inherits(fit, "wet_share_fit"))
  # a fit made before #102 carries no method: it is the regression
  method <- if (is.null(fit$method)) "regression" else fit$method
  out <- switch(method,
    regression = {
      out <- vapply(1:12, function(m) {
        x <- cbind(1, as.matrix(d[c(sprintf("%s_%02d", fit$terms, m), fit$static)]))
        as.vector(x %*% fit$coef[m, ])
      }, numeric(nrow(d)))
      out <- matrix(out, nrow = nrow(d))
      out[out < 0] <- 0
      tot <- rowSums(out)
      out / ifelse(tot > 0, tot, NA_real_)
    },
    donor = {
      x <- as.matrix(d[fit$static])
      if (!is.numeric(x)) stop("the static predictors must be numeric", call. = FALSE)
      wet_donor_mean(sweep(x, 2, fit$sd, "/"), fit$x, fit$shares, fit$k)
    },
    blend = (wet_share_predict(fit$regression, d) + wet_share_predict(fit$donor, d)) / 2,
    stop("unknown share method: ", method, call. = FALSE)
  )
  out <- matrix(out, nrow = nrow(d))
  colnames(out) <- sprintf("share_%02d", 1:12)
  out
}
