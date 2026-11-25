# The recovery run of the whole-station temperature baseline (#213): every candidate on stations
# simulated from known values, before any real score.
#
#   Rscript scripts/temp_baseline_recover.R
#
# On the holdout frame's real traits, folds and topology (scripts/temp_baseline_traits.R), theta
# is simulated from a known linear relationship with the traits, plus a part shared along the
# stream network, plus noise (tb_simulate(), scripts/temp_baseline_lib.R). The scale comes from
# the stations' own fits, which the frame carries: the mean and spread of theta, split by
# variance into `share` below. Nothing here reads a candidate's prediction of a real station.
#
# Part 1, parameters (n_sim sets). For each candidate, theta component and pool:
#   bias      mean error of the held-out prediction (0 if it recovers the relationship)
#   rmse      against `floor`, the spread no candidate without the network can explain
#             (the network part and the noise), and `null`, the simulated spread of theta
#   cover     how often the 90 % interval holds the simulated theta
#   leak      mean squared error less the same with the held-out station's network part replaced
#             by an independent draw of the same variance, in units of its Monte Carlo standard
#             error (z). A candidate that sees a held-out station's neighbours predicts part of
#             its network part, so its error is lower with the part as drawn (z below 0). The
#             leak-free pool removes those neighbours, and each candidate's weights depend on
#             traits alone, so there the two are equal in distribution: |z| under 3 for every
#             candidate and component is the check that the pool removes what it claims to.
#   Also the regression's coefficients against the known ones, and one set with no network part
#   and no noise, where the regression must return theta exactly.
#
# Part 2, end to end (n_e2e sets). Daily water is simulated at each station from its simulated
# parameters on its real air and its real observed days, with an AR(1) departure at the
# station's own fitted rho, as large as its real one (its standard deviation is the station's
# rmse_open; the fitted sigma is not used, because at a rho near 1 it implies a departure many
# times the one observed), floored at 0. The three components of theta are simulated
# independently, though at the real fits eq0 and eq1 offset each other, so GSDD errors here are
# larger than real ones would be: this part tests the path, not the size. Each station is
# refitted with
# wet:::wet_a2s_fit(), the candidates predict from the refitted theta, and GSDD is scored as the
# real run scores it. Asserted: a run on the simulated parameters scored against the
# departure-free series has no error at all.
#
# Writes data/checks/temp_baseline_recover.txt, which names the frame and the md5 of the code a
# score depends on (tb_code_md5()); scripts/temp_baseline.R refuses to score unless it is
# committed and names both as they stand. Byte-identical on a rerun.

devtools::load_all(quiet = TRUE)
source("scripts/temp_baseline_lib.R")
options(width = 160)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
n_sim <- 200
n_e2e <- 5
seed <- 213
share <- c(traits = 0.5, network = 0.25, noise = 0.25)  # of theta's variance
z_max <- 3

fr <- tb_frame_read()
st <- fr$stations
n <- nrow(st)
x <- as.matrix(st[tb_traits])
rownames(x) <- st$station_number
fold <- st$fold
related <- fr$related
up <- tb_upstream(st)
stopifnot(identical(rownames(related), st$station_number), identical(up | t(up), related))
# the network part is shared by flow-connected stations only
wt <- tb_net_weights(up, st$area_km2)
shared <- wt %*% t(wt)
stopifnot(all(abs(shared[!related & diag(n) == 0]) < 1e-12), all(abs(diag(shared) - 1) < 1e-12))

# ---- the known values ----------------------------------------------------------------------------
th_fit <- tb_theta(fr$fit[c("a1", "a2", "a3")])
b0 <- colMeans(th_fit)
sd_tot <- apply(th_fit, 2, stats::sd)
set.seed(seed)
zx <- scale(x)
beta <- matrix(stats::rnorm(length(tb_traits) * 3), length(tb_traits), 3, dimnames = list(tb_traits, tb_theta_names))
# scaled so the traits carry their share of each component's variance on these stations
beta <- sweep(beta, 2, sqrt(share[["traits"]]) * sd_tot / apply(zx %*% beta, 2, stats::sd), "*")
sd_net <- sqrt(share[["network"]]) * sd_tot
sd_noise <- sqrt(share[["noise"]]) * sd_tot
floor_sd <- sqrt(sd_net^2 + sd_noise^2)

# ---- part 1: parameters -----------------------------------------------------------------------------
pools <- c("blocked", "leakfree")
cells <- expand.grid(theta = tb_theta_names, method = tb_methods, pool = pools, stringsAsFactors = FALSE)
acc <- lapply(c(err = 1, sq = 2, cover = 3, leak = 4), function(i) matrix(NA_real_, n_sim, nrow(cells)))
coef_hat <- array(NA_real_, c(n_sim, length(tb_traits), 3))
stamp("part 1: ", n_sim, " simulated sets at ", n, " stations")
for (r in seq_len(n_sim)) {
  sim <- tb_simulate(x, up, st$area_km2, b0, beta, sd_net, sd_noise)
  alt <- matrix(stats::rnorm(n * 3), n, 3)
  theta_alt <- sim$fixed + sweep(alt, 2, sd_net, "*") + sweep(sim$noise, 2, sd_noise, "*")
  for (pool in pools) {
    cv <- tb_cv(x, sim$theta, fold, related, pool)
    for (m in tb_methods) {
      e <- cv[[m]]$mean - sim$theta
      iv <- tb_interval(cv[[m]])
      j <- which(cells$method == m & cells$pool == pool)
      acc$err[r, j] <- colMeans(e)
      acc$sq[r, j] <- colMeans(e^2)
      acc$cover[r, j] <- colMeans(sim$theta >= iv$lo & sim$theta <= iv$hi)
      acc$leak[r, j] <- colMeans(e^2 - (cv[[m]]$mean - theta_alt)^2)
    }
  }
  coef_hat[r, , ] <- stats::coef(stats::lm(sim$theta ~ zx))[-1, ]
}
part1 <- cbind(cells[c("pool", "method", "theta")],
               bias = colMeans(acc$err), bias_se = apply(acc$err, 2, stats::sd) / sqrt(n_sim),
               rmse = sqrt(colMeans(acc$sq)), floor = floor_sd[cells$theta], null = sd_tot[cells$theta],
               cover = colMeans(acc$cover),
               leak_z = colMeans(acc$leak) / (apply(acc$leak, 2, stats::sd) / sqrt(n_sim)))
part1 <- part1[order(match(part1$pool, pools), match(part1$method, tb_methods)), ]
rownames(part1) <- NULL
leak_ok <- all(abs(part1$leak_z[part1$pool == "leakfree"]) < z_max)
coefs <- data.frame(trait = rep(tb_traits, 3), theta = rep(tb_theta_names, each = length(tb_traits)),
                    known = as.vector(beta), mean_fitted = as.vector(apply(coef_hat, c(2, 3), mean)),
                    se = as.vector(apply(coef_hat, c(2, 3), stats::sd)) / sqrt(n_sim))
coefs$z <- (coefs$mean_fitted - coefs$known) / coefs$se
# no network part, no noise: the regression returns theta exactly
exact <- tb_simulate(x, up, st$area_km2, b0, beta, c(0, 0, 0), c(0, 0, 0))
exact_err <- vapply(tb_methods, function(m) {
  max(abs(tb_cv(x, exact$theta, fold, related, "leakfree", m)[[m]]$mean - exact$theta) / rep(sd_tot, each = n))
}, numeric(1))
stopifnot(exact_err[["regression"]] < 1e-8)

# ---- part 2: end to end ------------------------------------------------------------------------------
stamp("part 2: ", n_e2e, " end-to-end sets")
water <- readRDS(file.path("data", "temp_fill", "water_2002_2025.rds"))
air <- readRDS(file.path("data", "temp_fill", "air_2002_2025.rds"))
water <- water[water$station_number %in% st$station_number, ]
air <- air[air$id %in% st$station_number, ]
pool_of <- stats::setNames(substr(st$station_number, 1, 3), st$station_number)
series <- wet:::wet_fill_prepare(water, air, pool_of, NULL, NULL, 365, 0.1^2)$series[st$station_number]
stopifnot(!vapply(series, is.null, logical(1)))
years <- split(fr$truth$year, factor(fr$truth$station_number, levels = st$station_number))
rho <- fr$fit$rho
sigma <- fr$fit$rmse_open * sqrt(1 - rho^2)  # innovations that give the departure its observed spread
stopifnot(all(rho > 0 & rho < 1), all(sigma > 0))

e2e_one <- function(k) {
  v <- new.env()
  tb_take("scripts/temp_fill_validate.R", "gsdd_year", v)
  set.seed(seed * 1000 + k)
  sim <- tb_simulate(x, up, st$area_km2, b0, beta, sd_net, sd_noise)
  par <- tb_theta_inv(sim$theta)
  # each station's simulated record, on its real air and observed days
  rec <- lapply(seq_len(n), function(i) {
    z <- series[[i]]
    s0 <- tb_run(z, par[i, ])
    u <- as.numeric(stats::arima.sim(list(ar = rho[i]), length(s0), sd = sigma[i]))
    z$y <- ifelse(is.na(z$y), NA_real_, pmax(s0 + u, 0))
    clean <- z
    clean$y <- s0
    zero <- tb_score(clean, s0, years[[i]], v$gsdd_year)
    stopifnot(all(zero$rmse == 0), all(zero$bias == 0),
              identical(zero$gsdd, tb_gsdd_observed(clean, years[[i]], v$gsdd_year)))
    list(z = z, fit = wet:::wet_a2s_fit(z$y, z$a)$par)
  })
  fitted <- tb_theta(do.call(rbind, lapply(rec, `[[`, "fit")))
  rownames(fitted) <- st$station_number
  runs <- list(simulated = sim$theta, own_fit = fitted)
  for (pool in pools) {
    cv <- tb_cv(x, fitted, fold, related, pool)
    for (m in tb_methods) runs[[paste(pool, m)]] <- cv[[m]]$mean
  }
  sc <- do.call(rbind, lapply(seq_len(n), function(i) {
    z <- rec[[i]]$z
    obs <- tb_gsdd_observed(z, years[[i]], v$gsdd_year)
    do.call(rbind, lapply(names(runs), function(w) {
      p <- tb_theta_inv(runs[[w]][i, , drop = FALSE])[1, ]
      cbind(station_number = st$station_number[i], run = w, tb_score(z, tb_run(z, p), years[[i]], v$gsdd_year),
            gsdd_obs = obs)
    }))
  }))
  list(set = k, scores = sc, fit_err = fitted - sim$theta)
}
cl <- parallel::makeCluster(min(n_e2e, max(1, parallel::detectCores() - 2)))
root <- normalizePath(".")
parallel::clusterExport(cl, "root")
invisible(parallel::clusterEvalQ(cl, {
  setwd(root)
  pkgload::load_all(root, quiet = TRUE)
  source("scripts/temp_baseline_lib.R")
}))
parallel::clusterExport(cl, c("x", "up", "st", "b0", "beta", "sd_net", "sd_noise", "series", "years", "rho",
                              "sigma", "fold", "related", "pools", "seed", "n"))
e2e <- parallel::parLapply(cl, seq_len(n_e2e), e2e_one)
parallel::stopCluster(cl)

run_names <- unique(e2e[[1]]$scores$run)
part2 <- do.call(rbind, lapply(e2e, function(s) {
  d <- s$scores
  d$err <- abs(d$gsdd - d$gsdd_obs)
  # the station-years where the simulated year and every run have a GSDD
  key <- paste(d$station_number, d$year)
  full <- names(which(tapply(!is.na(d$err), key, all)))
  d <- d[key %in% full, ]
  by_station <- tapply(d$err, list(d$station_number, d$run), mean)
  data.frame(set = s$set, run = run_names, station_years = length(full),
             gsdd_mae = unname(colMeans(by_station)[run_names]),
             rmse = unname(tapply(d$rmse, d$run, mean)[run_names]))
}))
part2_mean <- stats::aggregate(cbind(gsdd_mae, rmse) ~ run, part2, mean)
part2_mean <- part2_mean[match(run_names, part2_mean$run), ]
part2_mean$gsdd_mae_range <- vapply(run_names, function(w) {
  paste(formatC(range(part2$gsdd_mae[part2$run == w]), format = "f", digits = 1), collapse = " to ")
}, character(1))
fit_err <- abs(do.call(rbind, lapply(e2e, `[[`, "fit_err")))
fit_tab <- data.frame(theta = tb_theta_names, sd_simulated = sd_tot,
                      median_abs_error = apply(fit_err, 2, stats::median),
                      q95_abs_error = apply(fit_err, 2, stats::quantile, 0.95), largest = apply(fit_err, 2, max))

# ---- report ---------------------------------------------------------------------------------------------
fmt <- function(d, digits = 3) utils::capture.output(print(d, row.names = FALSE, digits = digits))
lines <- c(
  "Recovery run of the whole-station temperature baseline (#213)",
  sprintf("frame: %s", fr$key),
  sprintf("code: %s", tb_code_md5()),
  sprintf("stations %d; seed %d; %d parameter sets; %d end-to-end sets", n, seed, n_sim, n_e2e),
  sprintf("theta's variance: %s", paste(sprintf("%s %.0f %%", names(share), 100 * share), collapse = ", ")),
  "",
  "## The known values: mean and spread of theta at the stations' own fits",
  fmt(data.frame(theta = tb_theta_names, b0 = b0, sd = sd_tot, sd_network = sd_net, sd_noise = sd_noise,
                 floor = floor_sd)), "",
  "## Part 1: held-out theta by pool, candidate and component",
  "bias and rmse in theta's units; floor is the network part and the noise together; null is theta's spread;",
  "cover is of the 90 % interval; leak_z is the leak in Monte Carlo standard errors (below 0: neighbours used)",
  fmt(part1), "",
  sprintf("Leak-free check (|leak_z| under %d for every candidate and component in the leak-free pool): %s", z_max,
          if (leak_ok) "PASS" else "FAIL"),
  "",
  "## The regression's coefficients on z-scored traits, fitted on every station, against the known ones",
  "z is the mean fitted coefficient's distance from the known one in Monte Carlo standard errors",
  fmt(coefs), "",
  "## One set with no network part and no noise: largest held-out error, in units of theta's spread",
  fmt(data.frame(method = tb_methods, max_error = exact_err), 2), "",
  "## Part 2: end to end, GSDD mean absolute error by station (degC-days) and daily RMSE (degC)",
  "simulated: the run on the simulated parameters, so its error is the departure alone; own_fit: the benchmark",
  fmt(part2_mean), "",
  sprintf("station-years scored per set: %s", paste(unique(part2[c("set", "station_years")])$station_years,
                                                     collapse = ", ")),
  "",
  "## Refitted theta against the simulated theta, every station of every set",
  fmt(fit_tab), "",
  "run on the simulated parameters against the departure-free series: no error at any station-year (asserted)")
writeLines(lines, file.path("data", "checks", "temp_baseline_recover.txt"))
cat(lines, sep = "\n")
if (!leak_ok) stop("the leak-free check failed: see the report", call. = FALSE)
