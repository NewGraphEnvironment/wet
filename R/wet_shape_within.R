# Within-month weights from a day-of-year climatology (#70): each day's part
# of its month's total, so the weights of a month sum to 1. `x` is a matrix
# with one row per watershed and 365 columns (a common year), in any units
# that are proportional to volume per day (shares, m3/s, mm/day). A month
# whose days sum to 0 gets the flat weight 1 / days and is flagged in the
# "flat" attribute, a logical matrix with one column per month.
wet_shape_within <- function(x) {
  x <- wet_shape_matrix(x)
  if (anyNA(x)) stop("`x` has NA days", call. = FALSE)
  m <- wet_doy_month()
  n <- wet_doy_days()
  tot <- t(apply(x, 1, function(r) tapply(r, m, sum)))
  tot <- matrix(tot, nrow = nrow(x))  # a one-row apply() comes back as a column
  flat <- !(tot > 0)
  w <- x / tot[, m, drop = FALSE]
  w[flat[, m, drop = FALSE]] <- rep(1 / n[m], each = nrow(x))[flat[, m, drop = FALSE]]
  dimnames(w) <- list(rownames(x), NULL)
  structure(w, flat = flat)
}

# A 365-column numeric matrix from a matrix or one vector
wet_shape_matrix <- function(x) {
  if (is.null(dim(x))) x <- matrix(x, nrow = 1)
  if (!is.numeric(x) || ncol(x) != 365) stop("`x` must have 365 columns, one per day of a common year", call. = FALSE)
  x
}

# A 12-column numeric matrix from a matrix or one vector
wet_shape_months <- function(x) {
  if (is.null(dim(x))) x <- matrix(x, nrow = 1)
  if (!is.numeric(x) || ncol(x) != 12) stop("`x` must have 12 columns, one per month", call. = FALSE)
  x
}
