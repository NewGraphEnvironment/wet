# Value-by-value agreement of two tables of one quantity per feature and
# month, used where wet checks a published value against the source it was
# built from (scripts/discharge_publish.R, data-raw/segment_vignette_data.R).
#
# `a` and `b` each hold `id_col`, `month` (0-12) and `value`, with one row
# per feature and month. A row differs when its key is on one side only, when
# its value is NA on one side only, or when the two values are further apart
# than `tol` relative to the larger. Returns c(compared, differing, max_abs_diff):
# compared counts the keys on either side, and max_abs_diff is the largest
# absolute difference among keys on both sides (0 when there are none), so a
# mismatch is counted and sized rather than averaged away.
wet_values_compare <- function(a, b, id_col = "linear_feature_id", value = "q_m3s", tol = 1e-9) {
  key <- function(d, side) {
    if (!all(c(id_col, "month", value) %in% names(d))) {
      stop("`", side, "` needs columns ", id_col, ", month and ", value, call. = FALSE)
    }
    if (anyNA(d[[id_col]]) || !all(d$month %in% 0:12)) {
      stop("`", side, "` has an NA ", id_col, " or a month outside 0-12", call. = FALSE)
    }
    # exact in a double: FWA ids are below 2^31, so id * 16 + month is below 2^35
    k <- as.numeric(d[[id_col]]) * 16 + d$month
    if (anyDuplicated(k)) stop("`", side, "` has a feature and month twice", call. = FALSE)
    k
  }
  ka <- key(a, "a")
  kb <- key(b, "b")
  ia <- match(ka, kb)
  only_a <- sum(is.na(ia))
  only_b <- sum(!kb %in% ka)
  va <- a[[value]][!is.na(ia)]
  vb <- b[[value]][ia[!is.na(ia)]]
  na_one <- is.na(va) != is.na(vb)
  d <- abs(va - vb)
  far <- !is.na(d) & d > tol * pmax(abs(va), abs(vb))
  c(compared = length(ka) + only_b,
    differing = only_a + only_b + sum(na_one) + sum(far),
    max_abs_diff = if (any(!is.na(d))) max(d, na.rm = TRUE) else 0)
}
