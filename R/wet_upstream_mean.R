#' Area-weighted mean over each watershed's upstream area
#'
#' Weights each polygon's value by its area and cover, and accumulates over
#' the `FWA_Upstream` set of every watershed with [wet_upstream_sums()], so it
#' runs on a whole basin without materialising upstream pairs.
#'
#' For watershed `a` with upstream polygons `u` (including `a` itself):
#'
#' * `denom = "total"`: `sum(value_u * area_u * cover_u) / upstream_area_a`.
#'   Ground without a value (a polygon's uncovered share, or a polygon with no
#'   value) adds nothing to the numerator but still counts in the denominator,
#'   so partial coverage biases the mean low. This reproduces fwapg, including
#'   `NA` where no upstream ground is covered.
#' * `denom = "covered"`: `sum(value_u * area_u * cover_u) /
#'   sum(area_u * cover_u)`: the mean over the area that has data. `coverage`
#'   says how much of the upstream area that is.
#'
#' `upstream_area_a` is the accumulated polygon area, unless `upstream_area`
#' supplies it. fwapg's discharge build divides by its stored
#' `fwa_watersheds_upstream_area`, a snapshot that can differ from the live
#' polygons, so pass that table to reproduce fwapg exactly. The override
#' applies to the `"total"` value and to the returned `upstream_area_m2`;
#' `coverage` is always covered area over accumulated area.
#'
#' @param ws `data.frame(watershed_feature_id, wscode, localcode, area_m2)`,
#'   e.g. from [wet_ws_fetch()]: every polygon of the basin.
#' @param values `data.frame(watershed_feature_id, value, cover)` from
#'   [wet_ws_sample()]. Polygons absent from it count as uncovered.
#' @param denom `"total"` or `"covered"`.
#' @param irregular_pairs Passed to [wet_upstream_sums()]; from
#'   [wet_upstream_irregular()]. Without it, irregularly coded polygons drop
#'   out of every upstream sum (a warning says how many), and the result no
#'   longer matches `FWA_Upstream`.
#' @param upstream_area Optional `data.frame(watershed_feature_id,
#'   upstream_area_m2)` overriding the accumulated upstream area.
#' @return `data.frame(watershed_feature_id, value, coverage,
#'   upstream_area_m2)`, one row per row of `ws`, with attribute `"irregular"`
#'   (ids of irregularly coded polygons).
#' @export
wet_upstream_mean <- function(ws, values, denom = c("total", "covered"),
                              irregular_pairs = NULL, upstream_area = NULL) {
  denom <- match.arg(denom)
  need <- c("watershed_feature_id", "wscode", "localcode", "area_m2")
  miss <- setdiff(need, names(ws))
  if (length(miss)) stop("ws is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  stopifnot(all(c("watershed_feature_id", "value", "cover") %in% names(values)),
            !anyDuplicated(values$watershed_feature_id))

  i <- match(ws$watershed_feature_id, values$watershed_feature_id)
  v <- values$value[i]
  cv <- values$cover[i]
  has <- !is.na(v)
  cv[!has | is.na(cv)] <- 0
  v[!has] <- 0
  a <- ws$area_m2

  # Weight by cover in both modes: the uncovered share of a polygon is
  # missing ground, not ground at the polygon's covered mean.
  q <- data.frame(watershed_feature_id = ws$watershed_feature_id,
                  wscode = ws$wscode, localcode = ws$localcode,
                  num = v * a * cv, area_cov = a * cv, area = a)
  s <- wet_upstream_sums(q, c("num", "area_cov", "area"),
                         irregular_pairs = irregular_pairs)
  irregular <- attr(s, "irregular")
  up <- s$area
  if (!is.null(upstream_area)) {
    stopifnot(all(c("watershed_feature_id", "upstream_area_m2") %in% names(upstream_area)))
    if (anyDuplicated(upstream_area$watershed_feature_id)) {
      stop("upstream_area has duplicate watershed_feature_id rows", call. = FALSE)
    }
    j <- match(ws$watershed_feature_id, upstream_area$watershed_feature_id)
    if (anyNA(j)) stop(sum(is.na(j)), " watersheds have no upstream_area row", call. = FALSE)
    up <- upstream_area$upstream_area_m2[j]
  }

  value <- if (denom == "total") s$num / up else s$num / s$area_cov
  # No covered ground upstream is no data, not zero flow (fwapg gives NULL).
  value[!(s$area_cov > 0)] <- NA_real_
  out <- data.frame(watershed_feature_id = ws$watershed_feature_id,
                    value = as.numeric(value),
                    # always against the accumulated area: an override (e.g. a
                    # stale stored table) must not leak into a coverage fraction
                    coverage = as.numeric(s$area_cov / s$area),
                    upstream_area_m2 = as.numeric(up))
  attr(out, "irregular") <- irregular
  out
}
