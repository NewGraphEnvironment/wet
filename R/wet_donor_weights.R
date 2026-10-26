# Donor weights for wet_departure_carry() (#120, #122): which of `donors`
# carry a target's departures, and with what weight. `space` is
# wet_station_space()'s matrix, with rows for the target and every donor;
# `donors` the candidate donors' names, in the order of `space`'s rows.
#
#   distance         wet_donor_mean()'s inverse-distance weights over the k
#                    nearest (#120's rule, computed exactly as before).
#   covariance       the same k nearest, each distance weight times max(r, 0).
#   covariance_pick  among the `n_pick` nearest (a tie to the name), the k
#                    with the highest r (a tie to the nearer), weight max(r, 0).
#
# r is the Pearson correlation of the target's and the donor's modelled
# values over the years both have (log values for a flow statistic, which
# gives the same r as log departures; days when `days`), counted as 0 when it
# rests on fewer than `min_years` years or is NA. A target whose chosen
# donors all weigh 0 falls back to `distance`. `modelled` holds one variable
# and period: station_number, year, value. Returns list(weight, r, fallback):
# `weight` over every donor (0 for one not used), `r` over every donor (NA
# where not computed).
wet_donor_weights <- function(space, target, donors, k, method = c("distance", "covariance", "covariance_pick"),
                              modelled = NULL, days = FALSE, n_pick = 15, min_years = 30) {
  method <- match.arg(method)
  k <- min(k, length(donors))
  wt <- drop(wet_donor_mean(space[target, , drop = FALSE], space[donors, , drop = FALSE],
                            diag(length(donors)), k))
  names(wt) <- donors
  r_all <- stats::setNames(rep(NA_real_, length(donors)), donors)
  if (method == "distance") return(list(weight = wt, r = r_all, fallback = FALSE))

  dist <- sqrt(colSums((t(space[donors, , drop = FALSE]) - space[target, ])^2))
  near <- if (method == "covariance") {
    donors[wt > 0]
  } else {
    donors[order(dist, donors)][seq_len(min(n_pick, length(donors)))]
  }
  series <- function(s) {
    m <- modelled[modelled$station_number == s & !is.na(modelled$value), ]
    if (!days) m <- m[m$value > 0, ]
    stats::setNames(if (days) m$value else log(m$value), m$year)
  }
  have <- unique(modelled$station_number)
  absent <- setdiff(c(target, near), have)
  if (length(absent)) stop("`modelled` has no rows for: ", paste(absent, collapse = ", "), call. = FALSE)
  tm <- series(target)
  r <- vapply(near, function(s) {
    dm <- series(s)
    yrs <- intersect(names(tm), names(dm))
    if (length(yrs) < min_years) return(0)
    v <- suppressWarnings(stats::cor(tm[yrs], dm[yrs]))
    if (is.na(v)) 0 else v
  }, numeric(1))
  r_all[near] <- r
  w <- stats::setNames(numeric(length(donors)), donors)
  if (method == "covariance") {
    w[near] <- wt[near] * pmax(r, 0)
  } else {
    pick <- near[order(-r, dist[near], near)][seq_len(k)]
    w[pick] <- pmax(r[pick], 0)
  }
  if (!any(w > 0)) return(list(weight = wt, r = r_all, fallback = TRUE))
  list(weight = w, r = r_all, fallback = FALSE)
}
