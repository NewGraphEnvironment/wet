# The inverse-distance mean of the donors' rows of `y`, per row of `x`: the
# `k` nearest rows of `x_donor` in Euclidean distance (both already scaled),
# weighted 1 / (d + 1e-6 * median(d)) over that row's distances to every
# donor, a donor at distance 0 taking the whole weight. One recipe for the
# daily shape (#70, wet_shape_predict()) and the monthly shares (#102,
# wet_share_predict()). A row of `x` with a missing value gets NA.
wet_donor_mean <- function(x, x_donor, y, k) {
  out <- matrix(NA_real_, nrow(x), ncol(y))
  ok <- stats::complete.cases(x)
  if (any(ok)) {
    v <- t(apply(x[ok, , drop = FALSE], 1, function(r) {
      dist <- sqrt(colSums((t(x_donor) - r)^2))
      o <- order(dist)[seq_len(k)]
      dd <- dist[o]
      wt <- if (any(dd == 0)) as.numeric(dd == 0) else 1 / (dd + 1e-6 * stats::median(dist))
      colSums(y[o, , drop = FALSE] * wt) / sum(wt)
    }))
    out[ok, ] <- matrix(v, nrow = sum(ok), ncol = ncol(y))
  }
  out
}
