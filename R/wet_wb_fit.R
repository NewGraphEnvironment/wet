#' Fit the gauge-residual adjustment of the annual water balance
#'
#' Chapman et al. (2018) adjust the raw water balance (P - AET) with a
#' regression of the gauge residuals within hydrologic zones. Here the
#' residual `obs - raw` (mm) is regressed, with no global intercept, on each
#' zone's upstream share `z_k` and the upstream mean of zone-masked
#' precipitation `zp_k`, so each zone gets its own intercept and slope on P.
#'
#' Every predictor is an upstream area-weighted mean of a cell layer on one
#' analysis mask (see [wet_ws_sample()] and [wet_upstream_means()]). The fitted
#' adjustment is therefore linear in cell values: applying it to the upstream
#' means of any watershed ([wet_wb_adjust()]) gives exactly what applying it
#' cell by cell and then averaging upstream would, and a basin that straddles
#' zones gets the same mix of coefficients in the fit and in the application.
#'
#' Zones where fewer than `min_gauges` stations have their largest share are
#' pooled, decided from the stations passed in (so a cross-validation fold
#' decides its own pooling from its training stations) unless `pooled` fixes
#' it. With `pooled_adjust = "other"` the pooled zones share one fitted
#' `"other"` level; with `"none"` they get no adjustment. A fitted level whose
#' columns carry no information in the data gets coefficient 0.
#'
#' @param d `data.frame` with `obs` and `raw` (mm) and, per zone `k`, columns
#'   `z<k>` (upstream zone share) and `zp<k>` (upstream mean of zone-masked
#'   annual P), e.g. `z08`, `zp08`.
#' @param min_gauges Minimum stations per zone before it is fitted on its own.
#' @param pooled Optional character vector of zones to pool, overriding
#'   `min_gauges`.
#' @param pooled_adjust `"other"` (one fitted level for the pooled zones) or
#'   `"none"` (no adjustment for them).
#' @return A `wet_wb_fit` object: `list(coef, pooled, pooled_adjust, n)`,
#'   where `coef` is a `data.frame(zone, a, b)` for every zone in `d`. Pooled
#'   zones repeat the `"other"` coefficients, or are 0 under
#'   `pooled_adjust = "none"`.
#' @export
wet_wb_fit <- function(d, min_gauges = 8, pooled = NULL, pooled_adjust = c("other", "none")) {
  pooled_adjust <- match.arg(pooled_adjust)
  zc <- wet_zone_cols(d)
  if (!all(c("obs", "raw") %in% names(d))) stop("d needs obs and raw", call. = FALSE)
  d <- d[stats::complete.cases(d[c("obs", "raw", zc$z, zc$zp)]), ]
  if (!nrow(d)) stop("no complete rows to fit", call. = FALSE)
  if (is.null(pooled)) pooled <- wet_wb_pooled(d, min_gauges)
  pooled <- intersect(pooled, zc$zone)
  own <- setdiff(zc$zone, pooled)
  pooled_level <- if (pooled_adjust == "other") pooled else character()
  design <- function(dd) wet_wb_design(dd, zc, own, pooled_level)
  x <- design(d)
  y <- d$obs - d$raw
  fit <- stats::lm.fit(x, y)
  b <- fit$coefficients
  b[is.na(b)] <- 0  # no information for that level: no adjustment
  lev <- c(own, if (length(pooled_level)) "other")
  a <- c(b[paste0("a_", lev)], a_none = 0)
  s <- c(b[paste0("b_", lev)], b_none = 0)
  pick <- ifelse(zc$zone %in% own, zc$zone, if (pooled_adjust == "other") "other" else "none")
  coef <- data.frame(zone = zc$zone, a = unname(a[paste0("a_", pick)]), b = unname(s[paste0("b_", pick)]))
  structure(list(coef = coef, pooled = pooled, pooled_adjust = pooled_adjust, n = nrow(d)),
            class = "wet_wb_fit")
}

# Zone columns z<k> / zp<k>, paired.
wet_zone_cols <- function(d) {
  z <- grep("^z[0-9]+$", names(d), value = TRUE)
  zone <- sub("^z", "", z)
  zp <- paste0("zp", zone)
  if (!length(z)) stop("no zone columns (z<k>, zp<k>)", call. = FALSE)
  if (!all(zp %in% names(d))) stop("missing zp columns for zones: ",
                                   paste(zone[!zp %in% names(d)], collapse = ", "), call. = FALSE)
  list(zone = zone, z = z, zp = zp)
}

wet_wb_design <- function(d, zc, own, pooled) {
  cols <- list()
  for (k in own) {
    cols[[paste0("a_", k)]] <- d[[paste0("z", k)]]
    cols[[paste0("b_", k)]] <- d[[paste0("zp", k)]]
  }
  if (length(pooled)) {
    cols[["a_other"]] <- rowSums(as.matrix(d[paste0("z", pooled)]))
    cols[["b_other"]] <- rowSums(as.matrix(d[paste0("zp", pooled)]))
  }
  as.matrix(as.data.frame(cols))
}

#' Zones to pool in a water-balance fit
#'
#' The zones where fewer than `min_gauges` stations have their largest
#' upstream share. It reads only where stations are, never what they
#' measured, so computing it on a fold's training stations leaks nothing.
#'
#' @inheritParams wet_wb_fit
#' @return Character vector of zone codes.
#' @export
wet_wb_pooled <- function(d, min_gauges = 8) {
  zc <- wet_zone_cols(d)
  zs <- as.matrix(d[zc$z])
  zs <- zs[rowSums(!is.na(zs)) > 0, , drop = FALSE]  # a station with no data counts nowhere
  zs[is.na(zs)] <- 0
  dom <- zc$zone[max.col(zs, ties.method = "first")]
  n_dom <- table(factor(dom, levels = zc$zone))
  zc$zone[n_dom < min_gauges]
}
