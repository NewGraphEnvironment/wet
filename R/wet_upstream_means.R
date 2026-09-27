#' Area-weighted upstream means of several sampled layers
#'
#' The multi-layer form of [wet_upstream_mean()] with `denom = "covered"`:
#' for watershed `a` and each column `x` of `values`,
#' `sum(x_u * area_u * cover_u) / sum(area_u * cover_u)` over the
#' `FWA_Upstream` set of `a`, in one pass of [wet_upstream_sums()]. All
#' columns share one cover (as [wet_ws_sample()] returns for several
#' layers), so the upstream mean of a linear combination of layers is exactly
#' that combination of their upstream means.
#'
#' @param ws `data.frame(watershed_feature_id, wscode, localcode, area_m2)` for
#'   a whole basin, e.g. from [wet_ws_fetch()].
#' @param values `data.frame(watershed_feature_id, <cols>, cover)`. Polygons
#'   absent from it count as uncovered. A polygon with `cover > 0` must have a
#'   value in every column.
#' @param cols Columns of `values` to average. Default: all but
#'   `watershed_feature_id` and `cover`.
#' @param irregular_pairs Passed to [wet_upstream_sums()].
#' @param extra Optional columns of `ws` to average over the **whole** upstream
#'   area (not only the covered part), e.g. an in-BC indicator.
#' @return `data.frame(watershed_feature_id, <cols>, <extra>, coverage,
#'   upstream_area_m2)`, one row per row of `ws`.
#' @export
wet_upstream_means <- function(ws, values, cols = NULL, irregular_pairs = NULL, extra = NULL) {
  need <- c("watershed_feature_id", "wscode", "localcode", "area_m2", extra)
  miss <- setdiff(need, names(ws))
  if (length(miss)) stop("ws is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (is.null(cols)) cols <- setdiff(names(values), c("watershed_feature_id", "cover"))
  stopifnot(all(c("watershed_feature_id", "cover", cols) %in% names(values)),
            !anyDuplicated(values$watershed_feature_id), length(cols) > 0)
  i <- match(ws$watershed_feature_id, values$watershed_feature_id)
  cv <- values$cover[i]
  cv[is.na(cv)] <- 0
  a <- ws$area_m2
  w <- a * cv
  x <- as.matrix(values[i, cols, drop = FALSE])
  if (any(is.na(x[cv > 0, ]))) {
    stop("a covered polygon has an NA value; sample with wet_ws_sample() on all layers at once",
         call. = FALSE)
  }
  x[!(cv > 0), ] <- 0
  q <- data.frame(watershed_feature_id = ws$watershed_feature_id, wscode = ws$wscode,
                  localcode = ws$localcode, w__ = w, a__ = a)
  num <- paste0("n__", seq_along(cols))
  q[num] <- x * w
  ex <- character()
  if (length(extra)) {
    ex <- paste0("e__", seq_along(extra))
    q[ex] <- as.matrix(ws[, extra, drop = FALSE]) * a
  }
  s <- wet_upstream_sums(q, c("w__", "a__", num, ex), irregular_pairs = irregular_pairs)
  out <- data.frame(watershed_feature_id = ws$watershed_feature_id)
  m <- as.matrix(s[, num, drop = FALSE]) / s$w__
  m[!(s$w__ > 0), ] <- NA
  out[cols] <- as.data.frame(m)
  if (length(extra)) out[extra] <- as.data.frame(as.matrix(s[, ex, drop = FALSE]) / s$a__)
  out$coverage <- s$w__ / s$a__
  out$upstream_area_m2 <- s$a__
  attr(out, "irregular") <- attr(s, "irregular")
  out
}
