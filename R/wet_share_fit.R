#' Fit the monthly share-of-annual-runoff model
#'
#' Splits annual runoff into months. Three methods, each fitted on the same
#' complete stations:
#'
#' - `"regression"`: Chapman et al. (2018) fit one regression per month of
#'   each month's share of the annual total. Here the response is the
#'   observed share (from monthly volumes, [wet_station_monthly()]) and the
#'   predictors, fixed in advance, are upstream means: that month's
#'   precipitation, temperature and AET plus any `static` columns (by default
#'   elevation and BC Albers easting and northing).
#' - `"donor"` (#102): a watershed takes the inverse-distance mean of the
#'   observed shares of its `k` nearest stations in the space of the `static`
#'   predictors, each divided by the stations' standard deviation. Distance
#'   weights are `1 / (d + 1e-6 * median(d))`; a station at distance 0 takes
#'   the whole weight, so a station predicts its own shares.
#' - `"blend"`: the equal-weight mean of the two.
#'
#' @param d `data.frame` with observed shares `share_01` to `share_12`, the
#'   monthly predictors `ppt_MM`, `tave_MM`, `aet_MM`, and the `static`
#'   columns. A station missing any of them is left out, whatever the method.
#' @param static Predictors used in every month, one value per station, each
#'   with its own coefficient in each month (`"regression"`), or the space the
#'   donors are found in (`"donor"`). The snow predictors scored in #16 enter
#'   here: `static = c("elev", "e_km", "n_km", "snowmelt_doy_50",
#'   "swe_max")`, the upstream means of [wet_snow_normals()].
#' @param method `"regression"`, `"donor"` or `"blend"`.
#' @param k Donors per watershed (`"donor"` and `"blend"`), capped at the
#'   number of stations.
#' @return A `wet_share_fit` object. For `"regression"`, `list(coef, terms,
#'   static, n, method)`, where `coef` is a 12-row matrix of coefficients
#'   (intercept first) by month. For `"donor"`, the stations' scaled
#'   predictors `x`, their standard deviations `sd` and observed `shares`.
#'   For `"blend"`, both fits, as `regression` and `donor`.
#' @examples
#' set.seed(1)
#' d <- data.frame(elev = runif(30, 200, 2000), e_km = runif(30, 900, 1800), n_km = runif(30, 400, 1500))
#' for (m in 1:12) {
#'   d[[sprintf("ppt_%02d", m)]] <- runif(30, 20, 200)
#'   d[[sprintf("tave_%02d", m)]] <- runif(30, -15, 20)
#'   d[[sprintf("aet_%02d", m)]] <- runif(30, 0, 100)
#'   # a freshet that comes later and larger at higher elevation
#'   d[[sprintf("share_%02d", m)]] <- 1 + (m %in% 5:7) * d$elev / 500
#' }
#' tot <- rowSums(d[sprintf("share_%02d", 1:12)])
#' d[sprintf("share_%02d", 1:12)] <- d[sprintf("share_%02d", 1:12)] / tot
#' new <- d[1:2, ]
#' new$elev <- c(300, 1900)
#' # the low watershed gets less of its year in May-July than the high one
#' round(wet_share_predict(wet_share_fit(d, method = "donor"), new)[, 5:7], 3)
#' @export
wet_share_fit <- function(d, static = c("elev", "e_km", "n_km"), method = c("regression", "donor", "blend"),
                          k = 5) {
  method <- match.arg(method)
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 1) stop("`k` must be one number of at least 1", call. = FALSE)
  terms <- c("ppt", "tave", "aet")
  cols_share <- sprintf("share_%02d", 1:12)
  need <- c(cols_share, as.vector(outer(terms, sprintf("_%02d", 1:12), paste0)), static)
  miss <- setdiff(need, names(d))
  if (length(miss)) stop("d is missing: ", paste(utils::head(miss, 5), collapse = ", "), call. = FALSE)
  d <- d[stats::complete.cases(d[need]), ]
  p <- 1 + length(terms) + length(static)
  if (nrow(d) <= p) stop("need more than ", p, " complete stations to fit", call. = FALSE)
  if (method == "blend") {
    fit <- list(method = "blend", regression = wet_share_fit(d, static, "regression"),
                donor = wet_share_fit(d, static, "donor", k = k), static = static, n = nrow(d))
    return(structure(fit, class = "wet_share_fit"))
  }
  if (method == "donor") {
    x <- as.matrix(d[static])
    sds <- apply(x, 2, stats::sd)
    if (any(!(sds > 0))) {
      stop("a static predictor is constant: ", paste(static[!(sds > 0)], collapse = ", "), call. = FALSE)
    }
    fit <- list(method = "donor", static = static, sd = sds, x = sweep(x, 2, sds, "/"),
                shares = unname(as.matrix(d[cols_share])), k = min(as.integer(k), nrow(d)), n = nrow(d))
    return(structure(fit, class = "wet_share_fit"))
  }
  coef <- t(vapply(1:12, function(m) {
    x <- cbind(1, as.matrix(d[c(sprintf("%s_%02d", terms, m), static)]))
    b <- stats::lm.fit(x, d[[sprintf("share_%02d", m)]])$coefficients
    b[is.na(b)] <- 0
    unname(b)
  }, numeric(p)))
  colnames(coef) <- c("(intercept)", terms, static)
  structure(list(coef = coef, terms = terms, static = static, n = nrow(d), method = "regression"),
            class = "wet_share_fit")
}
