# Value-by-value agreement of two tables of one quantity per feature and
# month, used where wet checks a published value against the source it was
# built from (scripts/discharge_publish.R, data-raw/segment_vignette_data.R).
#
# `a` and `b` each hold `id_col`, `time` (`month` 0-12, or `doy` 1-365) and
# `value`, with one row per feature and time. A row is equal when both values are NA, when both
# are the same infinity, or when both are finite and no further apart than
# `tol` relative to the larger; anything else differs, a key on one side only
# included. Returns c(compared, differing, max_abs_diff): compared counts the
# keys on either side, and max_abs_diff is the largest absolute difference
# among finite pairs (0 when there are none), so a mismatch is counted and
# sized rather than averaged away.
wet_values_compare <- function(a, b, id_col = "linear_feature_id", value = "q_m3s", tol = 1e-9, time = "month") {
  t_ok <- switch(time, month = 0:12, doy = 1:365, stop("`time` must be \"month\" or \"doy\"", call. = FALSE))
  key <- function(d, side) {
    if (!all(c(id_col, time, value) %in% names(d))) {
      stop("`", side, "` needs columns ", id_col, ", ", time, " and ", value, call. = FALSE)
    }
    if (anyNA(d[[id_col]]) || !all(d[[time]] %in% t_ok)) {
      stop("`", side, "` has an NA ", id_col, " or a ", time, " outside ", min(t_ok), "-", max(t_ok), call. = FALSE)
    }
    # exact in a double: FWA ids are below 2^31, so id * 512 + time is below 2^40
    k <- as.numeric(d[[id_col]]) * 512 + d[[time]]
    if (anyDuplicated(k)) stop("`", side, "` has a feature and ", time, " twice", call. = FALSE)
    k
  }
  ka <- key(a, "a")
  kb <- key(b, "b")
  ia <- match(ka, kb)
  only_a <- sum(is.na(ia))
  only_b <- sum(!kb %in% ka)
  va <- a[[value]][!is.na(ia)]
  vb <- b[[value]][ia[!is.na(ia)]]
  fin <- is.finite(va) & is.finite(vb)
  d <- abs(va - vb)
  same <- (is.na(va) & is.na(vb)) |
    (fin & d <= tol * pmax(abs(va), abs(vb))) |
    (!fin & !is.na(va) & !is.na(vb) & va == vb)
  c(compared = length(ka) + only_b,
    differing = only_a + only_b + sum(!same),
    max_abs_diff = if (any(fin)) max(d[fin]) else 0)
}
