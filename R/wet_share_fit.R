#' Fit the monthly share-of-annual-runoff regressions
#'
#' Chapman et al. (2018) split annual runoff into months with one regression
#' per month of each month's share of the annual total. Here the response is
#' the observed share (from monthly volumes, [wet_station_monthly()]) and the
#' predictors, fixed in advance, are upstream means: that month's
#' precipitation, temperature and AET plus any `static` columns (by default
#' elevation and BC Albers easting and northing).
#'
#' @param d `data.frame` with observed shares `share_01` to `share_12`, the
#'   monthly predictors `ppt_MM`, `tave_MM`, `aet_MM`, and the `static`
#'   columns.
#' @param static Predictors used in every month.
#' @return A `wet_share_fit` object: `list(coef, terms, n)`, where `coef` is a
#'   12-row matrix of coefficients (intercept first) by month.
#' @export
wet_share_fit <- function(d, static = c("elev", "e_km", "n_km")) {
  terms <- c("ppt", "tave", "aet")
  need <- c(sprintf("share_%02d", 1:12), as.vector(outer(terms, sprintf("_%02d", 1:12), paste0)), static)
  miss <- setdiff(need, names(d))
  if (length(miss)) stop("d is missing: ", paste(utils::head(miss, 5), collapse = ", "), call. = FALSE)
  d <- d[stats::complete.cases(d[need]), ]
  p <- 1 + length(terms) + length(static)
  if (nrow(d) <= p) stop("need more than ", p, " complete stations to fit", call. = FALSE)
  coef <- t(vapply(1:12, function(m) {
    x <- cbind(1, as.matrix(d[c(sprintf("%s_%02d", terms, m), static)]))
    b <- stats::lm.fit(x, d[[sprintf("share_%02d", m)]])$coefficients
    b[is.na(b)] <- 0
    unname(b)
  }, numeric(p)))
  colnames(coef) <- c("(intercept)", terms, static)
  structure(list(coef = coef, terms = terms, static = static, n = nrow(d)), class = "wet_share_fit")
}
