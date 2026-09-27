#' Apply a fitted water-balance adjustment
#'
#' `raw + sum_k (a_k * z_k + b_k * zp_k)`, floored at 0 when `floor = TRUE`.
#' The floor is applied to the watershed value only: cells stay signed, so
#' the adjustment remains linear through accumulation.
#'
#' @param fit A [wet_wb_fit()] result.
#' @param d `data.frame` with `raw` and the `z<k>`, `zp<k>` columns. A zone in
#'   `fit` missing from `d` counts as share 0, so `d` with no zone columns at
#'   all gets no adjustment; a zone in `d` missing from `fit` is an error.
#' @param floor Logical. Floor the result at 0.
#' @return Numeric vector of adjusted runoff (mm), one per row of `d`.
#' @export
wet_wb_adjust <- function(fit, d, floor = TRUE) {
  stopifnot(inherits(fit, "wet_wb_fit"), "raw" %in% names(d))
  # no zone columns at all (ground in no fitted zone): no adjustment
  has_z <- any(grepl("^z[0-9]+$", names(d)))
  zc <- if (has_z) wet_zone_cols(d) else list(zone = character())
  extra <- setdiff(zc$zone, fit$coef$zone)
  if (length(extra)) stop("zones not in the fit: ", paste(extra, collapse = ", "), call. = FALSE)
  adj <- d$raw
  for (i in seq_len(nrow(fit$coef))) {
    k <- fit$coef$zone[i]
    zk <- if (paste0("z", k) %in% names(d)) d[[paste0("z", k)]] else 0
    zpk <- if (paste0("zp", k) %in% names(d)) d[[paste0("zp", k)]] else 0
    adj <- adj + fit$coef$a[i] * zk + fit$coef$b[i] * zpk
  }
  if (floor) adj <- pmax(adj, 0)
  adj
}
