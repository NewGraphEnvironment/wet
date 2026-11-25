# Shared by the whole-station temperature baseline's scripts (#213): scripts/temp_baseline_traits.R,
# scripts/temp_baseline_recover.R and scripts/temp_baseline.R. Sourced after devtools::load_all(),
# not run on its own; tested by tests/testthat/test-temp_baseline_lib.R.

# Evaluate, in `envir`, the top-level assignments to `what` in another script, in the order given:
# a definition taken from the script that owns it, not copied. Each name must be assigned exactly
# once at the script's top level.
tb_take <- function(file, what, envir) {
  ex <- parse(file, keep.source = FALSE)
  target <- vapply(ex, function(e) {
    if (is.call(e) && (identical(e[[1]], as.name("<-")) || identical(e[[1]], as.name("="))) && is.name(e[[2]])) {
      as.character(e[[2]])
    } else {
      ""
    }
  }, character(1))
  for (w in what) {
    i <- which(target == w)
    if (length(i) != 1L) {
      stop(file, " assigns ", w, " ", length(i), " times at its top level, not once", call. = FALSE)
    }
    eval(ex[[i]], envir)
  }
  invisible(envir)
}

# The traits every candidate reads, in the rule's order (scripts/temp_baseline.R).
tb_traits <- c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max", "log_area", "glacier", "lake_cover")

# The holdout frame the tracked report names (scripts/temp_baseline_traits.R writes both).
tb_frame_report <- file.path("data", "checks", "temp_baseline_frame.txt")
tb_frame_read <- function(dir = file.path("data", "temp_baseline")) {
  if (!file.exists(tb_frame_report)) {
    stop(tb_frame_report, " is missing: run scripts/temp_baseline_traits.R", call. = FALSE)
  }
  key <- sub("^frame: ", "", grep("^frame: ", readLines(tb_frame_report), value = TRUE))
  if (length(key) != 1L || !grepl("^[0-9a-f]{10}$", key)) stop(tb_frame_report, " names no frame", call. = FALSE)
  f <- file.path(dir, sprintf("frame_%s.rds", key))
  if (!file.exists(f)) stop("the frame the report names is not here: ", f, call. = FALSE)
  fr <- readRDS(f)
  if (!identical(fr$key, key)) stop(f, " holds frame ", fr$key, call. = FALSE)
  fr
}

# ---- parameters -----------------------------------------------------------------------------------
# theta = (eq0, eq1, rate): the equilibrium intercept a1 / a3, the equilibrium slope a2 / a3 and
# the response rate qlogis(a3). Candidates predict theta; the model runs on a1, a2, a3.
tb_theta_names <- c("eq0", "eq1", "rate")
tb_theta <- function(par) {
  par <- as.matrix(par)
  if (!all(c("a1", "a2", "a3") %in% colnames(par))) stop("par needs a1, a2 and a3", call. = FALSE)
  a3 <- par[, "a3"]
  if (any(!is.finite(par[, c("a1", "a2", "a3")])) || any(a3 <= 0 | a3 >= 1)) {
    stop("a1 and a2 must be finite and a3 inside (0, 1)", call. = FALSE)
  }
  out <- cbind(eq0 = par[, "a1"] / a3, eq1 = par[, "a2"] / a3, rate = stats::qlogis(a3))
  rownames(out) <- rownames(par)
  out
}
tb_theta_inv <- function(theta) {
  theta <- as.matrix(theta)
  if (!identical(colnames(theta), tb_theta_names)) stop("theta needs eq0, eq1 and rate, in that order", call. = FALSE)
  a3 <- stats::plogis(theta[, "rate"])
  out <- cbind(a1 = theta[, "eq0"] * a3, a2 = theta[, "eq1"] * a3, a3 = a3)
  rownames(out) <- rownames(theta)
  out
}

# ---- candidates -----------------------------------------------------------------------------------
tb_methods <- c("mean", "regression", "donor")
tb_k <- 5        # donors, as the monthly shares' donor
tb_level <- 0.9  # the interval scored for coverage

# Predict theta at the rows of `x_new` from training stations' traits `x` and theta `th`. Returns
# list(mean, sd, df): matrices with a row per row of `x_new` and a column per theta, and the
# degrees of freedom of the predictive t. A trait with no spread in the training rows is left out
# of that fit.
#   mean        the training mean; sd of one new station about it
#   regression  least squares on the traits; the usual prediction sd
#   donor       wet_donor_mean()'s weights over the tb_k nearest training rows in z-scored trait
#               space; sd from the donors' weighted spread about their mean
tb_predict <- function(method, x, th, x_new) {
  method <- match.arg(method, tb_methods)
  x <- as.matrix(x)
  x_new <- as.matrix(x_new)
  th <- as.matrix(th)
  n <- nrow(x)
  if (nrow(th) != n || ncol(x_new) != ncol(x)) stop("x, th and x_new do not line up", call. = FALSE)
  if (!all(is.finite(x)) || !all(is.finite(th)) || !all(is.finite(x_new))) {
    stop("traits and theta must be finite", call. = FALSE)
  }
  empty <- matrix(NA_real_, nrow(x_new), ncol(th), dimnames = list(rownames(x_new), colnames(th)))
  if (method == "mean") {
    if (n < 2) stop("the mean needs at least 2 training stations", call. = FALSE)
    m <- empty
    m[] <- rep(colMeans(th), each = nrow(x_new))
    s <- empty
    s[] <- rep(apply(th, 2, stats::sd) * sqrt(1 + 1 / n), each = nrow(x_new))
    return(list(mean = m, sd = s, df = n - 1))
  }
  spread <- apply(x, 2, stats::sd) > 0
  x <- x[, spread, drop = FALSE]
  x_new <- x_new[, spread, drop = FALSE]
  if (method == "regression") {
    p <- ncol(x) + 1
    if (n <= p) stop("the regression needs more training stations than coefficients", call. = FALSE)
    xd <- cbind(1, x)
    xtx_inv <- solve(crossprod(xd))
    beta <- xtx_inv %*% crossprod(xd, th)
    xn <- cbind(1, x_new)
    m <- empty
    m[] <- xn %*% beta
    res_sd <- sqrt(colSums((th - xd %*% beta)^2) / (n - p))
    lev <- rowSums((xn %*% xtx_inv) * xn)
    s <- empty
    s[] <- outer(sqrt(1 + lev), res_sd)
    return(list(mean = m, sd = s, df = n - p))
  }
  k <- min(tb_k, n)
  if (k < 2) stop("the donor mean needs at least 2 training stations", call. = FALSE)
  mu <- colMeans(x)
  sg <- apply(x, 2, stats::sd)
  z <- sweep(sweep(x, 2, mu), 2, sg, "/")
  zn <- sweep(sweep(x_new, 2, mu), 2, sg, "/")
  w <- wet:::wet_donor_mean(zn, z, diag(n), k)   # weights over the training rows, summing to 1
  m <- empty
  m[] <- w %*% th
  v <- w %*% th^2 - (w %*% th)^2
  s <- empty
  s[] <- sqrt(pmax(v, 0) * k / (k - 1) * (1 + rowSums(w^2)))
  list(mean = m, sd = s, df = k - 1)
}

# The interval tb_level wide about a prediction.
tb_interval <- function(p, level = tb_level) {
  h <- stats::qt(1 - (1 - level) / 2, p$df) * p$sd
  list(lo = p$mean - h, hi = p$mean + h)
}

# Held-out predictions of every station's theta, by `pool`:
#   blocked   the stations of a fold are predicted together from every other fold
#   leakfree  each station is predicted alone from the other folds less the stations `related`
#             to it (upstream or downstream of it)
# `x` and `th` have a row per station, in the order of `fold` and of `related`'s rows. Returns a
# list per method of tb_predict()'s result with a row per station.
tb_cv <- function(x, th, fold, related, pool = c("blocked", "leakfree"), methods = tb_methods) {
  pool <- match.arg(pool)
  x <- as.matrix(x)
  th <- as.matrix(th)
  n <- nrow(x)
  if (nrow(th) != n || length(fold) != n || !identical(dim(related), c(n, n))) {
    stop("x, th, fold and related do not line up", call. = FALSE)
  }
  if (anyNA(fold) || anyNA(related) || !is.logical(related)) stop("fold and related must be complete", call. = FALSE)
  parts <- if (pool == "blocked") {
    lapply(unique(fold), function(f) list(te = which(fold == f), tr = fold != f))
  } else {
    lapply(seq_len(n), function(i) list(te = i, tr = fold != fold[i] & !related[i, ]))
  }
  blank <- matrix(NA_real_, n, ncol(th), dimnames = list(rownames(x), colnames(th)))
  out <- stats::setNames(lapply(methods, function(m) list(mean = blank, sd = blank, df = rep(NA_real_, n))), methods)
  for (p in parts) {
    if (any(p$tr[p$te])) stop("a held-out station is in its own training set", call. = FALSE)
    for (m in methods) {
      r <- tb_predict(m, x[p$tr, , drop = FALSE], th[p$tr, , drop = FALSE], x[p$te, , drop = FALSE])
      out[[m]]$mean[p$te, ] <- r$mean
      out[[m]]$sd[p$te, ] <- r$sd
      out[[m]]$df[p$te] <- r$df
    }
  }
  out
}

# up[i, j]: station j is upstream of station i (never i itself), from the FWA codes.
tb_upstream <- function(stations) {
  n <- nrow(stations)
  up <- matrix(FALSE, n, n, dimnames = list(stations$station_number, stations$station_number))
  for (i in seq_len(n)) {
    up[i, ] <- wet:::wet_fwa_upstream(stations$wscode[i], stations$localcode[i], stations$wscode, stations$localcode)
  }
  diag(up) <- FALSE
  up
}

# ---- simulation -------------------------------------------------------------------------------------
# Stations with a known trait-to-theta relationship, on the real traits and topology:
#   theta = b0 + z beta + sd_net net + sd_noise noise
# `z` is the traits z-scored over all stations. `net` is the part shared along the stream network:
# each station's value is the weighted mean of its own draw and the draws of the stations upstream
# of it (weights: the upstream station's share of this station's area), scaled to unit variance.
# Two stations share a draw only when one is upstream of the other, so `net` is correlated between
# flow-connected stations and independent otherwise, which is what the leak-free pool removes.
# `beta` is traits x theta; `b0`, `sd_net` and `sd_noise` have one value per theta. Returns theta
# with its parts: `fixed` (b0 + z beta), `net` and `noise` (both unit variance per station).
tb_simulate <- function(x, up, area, b0, beta, sd_net, sd_noise) {
  x <- as.matrix(x)
  n <- nrow(x)
  q <- length(b0)
  if (!identical(dim(up), c(n, n)) || length(area) != n || !identical(dim(beta), c(ncol(x), q)) ||
        length(sd_net) != q || length(sd_noise) != q) {
    stop("the simulation's inputs do not line up", call. = FALSE)
  }
  z <- scale(x)
  wt <- tb_net_weights(up, area)
  net <- vapply(seq_len(q), function(j) drop(wt %*% stats::rnorm(n)), numeric(n))
  noise <- matrix(stats::rnorm(n * q), n, q)
  fixed <- rep(b0, each = n) + z %*% beta
  theta <- fixed + sweep(net, 2, sd_net, "*") + sweep(noise, 2, sd_noise, "*")
  dimnames(theta) <- dimnames(fixed) <- dimnames(net) <- dimnames(noise) <- list(rownames(x), names(b0))
  list(theta = theta, fixed = fixed, net = net, noise = noise)
}

# The network part's weights: row i holds 1 for station i and area[j] / area[i] (at most 1) for
# each station j upstream of it, scaled so the row's squares sum to 1.
tb_net_weights <- function(up, area) {
  w <- up * pmin(outer(1 / area, area), 1)
  diag(w) <- 1
  w / sqrt(rowSums(w^2))
}

# ---- running and scoring ----------------------------------------------------------------------------
# Open-loop air2stream over a station's calendar (`series`: wet_fill_prepare()'s date, a, y) from
# parameters c(a1, a2, a3).
tb_run <- function(series, par) {
  wet:::wet_a2s_run(par[["a1"]], par[["a2"]], par[["a3"]], series$a)
}

# One predicted series `s` against the observed one, per truth year: daily RMSE and bias on the
# observed days of 1 March - 30 November, and the predicted year's GSDD by `gsdd_year` (taken
# from scripts/temp_fill_validate.R), NA where it has none.
tb_score <- function(series, s, years, gsdd_year) {
  if (length(s) != length(series$date)) stop("the predicted series is not on the station's calendar", call. = FALSE)
  do.call(rbind, lapply(years, function(y) {
    i <- series$date >= as.Date(paste0(y, "-03-01")) & series$date <= as.Date(paste0(y, "-11-30")) &
      !is.na(series$y)
    if (!any(i)) stop("no observed day in the season of ", y, call. = FALSE)
    e <- s[i] - series$y[i]
    g <- gsdd_year(series$date, s, y)
    data.frame(year = y, n = sum(i), rmse = sqrt(mean(e^2)), bias = mean(e),
               gsdd = if (length(g) == 1L) g else NA_real_)
  }))
}

# The observed GSDD of each truth year, NA where the year has none.
tb_gsdd_observed <- function(series, years, gsdd_year) {
  o <- !is.na(series$y)
  vapply(years, function(y) {
    g <- gsdd_year(series$date[o], series$y[o], y)
    if (length(g) == 1L) g else NA_real_
  }, numeric(1))
}

# ---- the code a score depends on --------------------------------------------------------------------
# One md5 over the files whose change could move a score. scripts/temp_baseline_recover.R writes
# it into its report, and scripts/temp_baseline.R refuses to score under another.
tb_code_files <- c("scripts/temp_baseline_lib.R", "scripts/temp_baseline_rule.R", "scripts/temp_fill_validate.R",
                   "R/wet_temp_fill.R", "R/wet_temp_gsdd.R", "R/wet_donor_mean.R", "R/wet_cv_folds.R")
tb_code_md5 <- function(root = ".") {
  f <- file.path(root, tb_code_files)
  if (!all(file.exists(f))) stop("missing: ", paste(f[!file.exists(f)], collapse = ", "), call. = FALSE)
  wet:::wet_md5_text(paste(tb_code_files, unname(tools::md5sum(f))))
}
