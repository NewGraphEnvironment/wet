#' Predict monthly shares of annual runoff
#'
#' Applies the 12 regressions of [wet_share_fit()], floors each prediction at
#' 0 and renormalises so the 12 shares sum to 1. A watershed whose 12 floored
#' predictions are all 0 gets `NA` shares.
#'
#' @param fit A [wet_share_fit()] result.
#' @param d `data.frame` with the predictors named in `fit`.
#' @return A matrix with one row per row of `d` and columns `share_01` to
#'   `share_12`.
#' @export
wet_share_predict <- function(fit, d) {
  stopifnot(inherits(fit, "wet_share_fit"))
  out <- vapply(1:12, function(m) {
    x <- cbind(1, as.matrix(d[c(sprintf("%s_%02d", fit$terms, m), fit$static)]))
    as.vector(x %*% fit$coef[m, ])
  }, numeric(nrow(d)))
  out <- matrix(out, nrow = nrow(d))
  out[out < 0] <- 0
  tot <- rowSums(out)
  out <- out / ifelse(tot > 0, tot, NA_real_)
  colnames(out) <- sprintf("share_%02d", 1:12)
  out
}
