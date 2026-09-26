#' Area-weighted mean over each watershed's upstream area
#'
#' Pure R over a pairs table, so the weighting is testable without a database;
#' [wet_upstream_pairs()] supplies the pairs from fwapg.
#'
#' For watershed `a` with upstream polygons `u` (including `a` itself):
#'
#' * `denom = "total"`: `sum(value_u * area_u * cover_u) / upstream_area_a`, where
#'   `upstream_area_a` is fwapg's precomputed total. Ground without a value
#'   (a polygon's uncovered share, or a polygon with no value) adds nothing to
#'   the numerator but still counts in the denominator, so
#'   partial coverage biases the mean low. This reproduces fwapg, including
#'   `NA` where no upstream polygon has a value.
#' * `denom = "covered"`: `sum(value_u * area_u * cover_u) /
#'   sum(area_u * cover_u)` over polygons with a value: the mean over the
#'   area that has data. `coverage` then says how much of the upstream
#'   area that is.
#'
#' @param pairs `data.frame(watershed_feature_id, id_up, area_up_m2,
#'   upstream_area_m2)`: one row per (watershed, upstream polygon).
#' @param values `data.frame(watershed_feature_id, value, cover)` from
#'   [wet_ws_sample()].
#' @param denom `"total"` or `"covered"`.
#' @return `data.frame(watershed_feature_id, value, coverage,
#'   upstream_area_m2)`.
#' @export
wet_upstream_mean <- function(pairs, values, denom = c("total", "covered")) {
  denom <- match.arg(denom)
  need <- c("watershed_feature_id", "id_up", "area_up_m2", "upstream_area_m2")
  miss <- setdiff(need, names(pairs))
  if (length(miss)) stop("pairs is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  stopifnot(all(c("watershed_feature_id", "value", "cover") %in% names(values)),
            !anyDuplicated(values$watershed_feature_id))

  i <- match(pairs$id_up, values$watershed_feature_id)
  v <- values$value[i]
  cv <- values$cover[i]
  has <- !is.na(v)
  cv[!has | is.na(cv)] <- 0
  v[!has] <- 0
  a <- pairs$area_up_m2

  key <- factor(pairs$watershed_feature_id)
  # Weight by cover in both modes: the uncovered share of a polygon is
  # missing ground, not ground at the polygon's covered mean.
  num <- tapply(v * a * cv, key, sum)
  area_cov <- tapply(a * cv, key, sum)
  up <- tapply(pairs$upstream_area_m2, key, `[`, 1)

  value <- if (denom == "total") num / up else
    ifelse(area_cov > 0, num / area_cov, NA_real_)
  # No covered ground upstream is no data, not zero flow (fwapg gives NULL).
  # Test cover, not value presence: the numerator is cover-weighted, so a
  # value with zero cover contributes nothing either.
  value[!(area_cov > 0)] <- NA_real_
  data.frame(watershed_feature_id = as.integer(levels(key)),
             value = as.numeric(value),
             coverage = as.numeric(area_cov / up),
             upstream_area_m2 = as.numeric(up))
}
