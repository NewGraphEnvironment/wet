# The whole-station temperature baseline's shared code (#213, scripts/temp_baseline_lib.R).
# scripts/ is not in the installed package, so these run from the source tree only.
local_tb_lib <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "temp_baseline_lib.R"), envir = e)
  e
}

test_that("tb_take() evaluates one top-level assignment and refuses a name assigned twice or never", {
  l <- local_tb_lib()
  f <- withr::local_tempfile(fileext = ".R")
  writeLines(c("stop('the script itself must not run')", "one <- function(x) x + 1", "two <- 2", "two <- 3",
               "inner <- function() { hidden <- 1 }"), f)
  e <- new.env()
  l$tb_take(f, "one", e)
  expect_equal(e$one(1), 2)
  expect_error(l$tb_take(f, "two", e), "assigns two 2 times")
  expect_error(l$tb_take(f, "hidden", e), "assigns hidden 0 times")
})

test_that("theta turns back into the parameters it came from", {
  l <- local_tb_lib()
  par <- cbind(a1 = c(0.5, 0.02, -0.1), a2 = c(0.1, 0.01, 0.3), a3 = c(0.15, 0.015, 0.61))
  rownames(par) <- c("s1", "s2", "s3")
  th <- l$tb_theta(par)
  expect_identical(colnames(th), l$tb_theta_names)
  expect_equal(th[, "eq1"], par[, "a2"] / par[, "a3"])
  expect_equal(l$tb_theta_inv(th), par)
  bad <- par
  bad[2, "a3"] <- 1
  expect_error(l$tb_theta(bad), "inside \\(0, 1\\)")
  bad[2, "a3"] <- NA
  expect_error(l$tb_theta(bad), "finite")
  expect_error(l$tb_theta_inv(th[, c(2, 1, 3)]), "in that order")
})

tb_toy <- function(n = 40, seed = 1) {
  set.seed(seed)
  x <- cbind(elev = runif(n, 0, 2000), lake = runif(n), flat = 3)
  th <- cbind(eq0 = 2 + x[, "elev"] / 1000, eq1 = 0.8 - 0.2 * x[, "lake"], rate = -2 + rnorm(n, 0, 0.3))
  rownames(x) <- rownames(th) <- sprintf("s%02d", seq_len(n))
  list(x = x, th = th)
}

test_that("the population mean predicts the training mean, with one new station's spread", {
  l <- local_tb_lib()
  d <- tb_toy()
  p <- l$tb_predict("mean", d$x[1:30, ], d$th[1:30, ], d$x[31:40, ])
  expect_equal(unname(p$mean[4, ]), unname(colMeans(d$th[1:30, ])))
  expect_equal(unname(p$sd[1, ]), unname(apply(d$th[1:30, ], 2, sd) * sqrt(1 + 1 / 30)))
  expect_equal(p$df, 29)
  expect_identical(rownames(p$mean), rownames(d$x)[31:40])
})

test_that("the regression is lm's, prediction interval included, and drops a trait with no spread", {
  l <- local_tb_lib()
  d <- tb_toy()
  tr <- 1:30
  p <- l$tb_predict("regression", d$x[tr, ], d$th[tr, ], d$x[31:40, ])
  # exact linear relationships come back exactly
  expect_equal(unname(p$mean[, "eq0"]), unname(d$th[31:40, "eq0"]))
  expect_equal(unname(p$mean[, "eq1"]), unname(d$th[31:40, "eq1"]))
  expect_true(all(p$sd[, c("eq0", "eq1")] < 1e-8))
  # the noisy one matches lm
  df <- data.frame(d$x[, c("elev", "lake")], rate = d$th[, "rate"])
  ref <- stats::predict(stats::lm(rate ~ elev + lake, df[tr, ]), df[31:40, ], interval = "prediction", level = 0.9)
  iv <- l$tb_interval(p, 0.9)
  expect_equal(unname(p$mean[, "rate"]), unname(ref[, "fit"]))
  expect_equal(unname(iv$lo[, "rate"]), unname(ref[, "lwr"]))
  expect_equal(unname(iv$hi[, "rate"]), unname(ref[, "upr"]))
  expect_equal(p$df, 27)
  expect_error(l$tb_predict("regression", d$x[1:3, ], d$th[1:3, ], d$x[31:40, ]), "more training stations")
})

test_that("the donor mean is the nearest training stations', and a station's own traits give its own theta", {
  l <- local_tb_lib()
  d <- tb_toy()
  tr <- 1:30
  p <- l$tb_predict("donor", d$x[tr, ], d$th[tr, ], d$x[c(7, 31), ])
  # row 7 is a training row: zero distance takes the whole weight
  expect_equal(unname(p$mean[1, ]), unname(d$th[7, ]))
  expect_equal(unname(p$sd[1, ]), c(0, 0, 0))
  # row 31: by hand, on the two traits with spread, z-scored on the training rows
  z <- scale(d$x[tr, 1:2])
  zn <- (d$x[31, 1:2] - attr(z, "scaled:center")) / attr(z, "scaled:scale")
  dist <- sqrt(colSums((t(z) - zn)^2))
  o <- order(dist)[1:5]
  w <- 1 / (dist[o] + 1e-6 * median(dist))
  expect_equal(unname(p$mean[2, ]), unname(colSums(d$th[tr, ][o, ] * w) / sum(w)))
  expect_true(all(p$sd[2, ] > 0))
  expect_equal(p$df, 4)
})

test_that("candidates refuse traits or theta that are not finite, and inputs that do not line up", {
  l <- local_tb_lib()
  d <- tb_toy()
  x <- d$x
  x[3, 1] <- NA
  for (m in l$tb_methods) expect_error(l$tb_predict(m, x[1:30, ], d$th[1:30, ], d$x[31:40, ]), "finite")
  expect_error(l$tb_predict("mean", d$x[1:30, ], d$th[1:29, ], d$x[31:40, ]), "line up")
  expect_error(l$tb_predict("mean", d$x[1, , drop = FALSE], d$th[1, , drop = FALSE], d$x[31:40, ]), "at least 2")
})

test_that("blocked CV holds a fold out together, and the leak-free pool also drops related stations", {
  l <- local_tb_lib()
  d <- tb_toy(12)
  fold <- rep(c("a", "b", "c"), each = 4)
  related <- matrix(FALSE, 12, 12)
  related[1, 5] <- related[5, 1] <- TRUE   # station 5 (fold b) is upstream of station 1 (fold a)
  d$th[5, ] <- d$th[5, ] + 100
  b <- l$tb_cv(d$x, d$th, fold, related, "blocked", "mean")$mean
  expect_equal(unname(b$mean[1, ]), unname(colMeans(d$th[5:12, ])))
  expect_equal(unname(b$mean[2, ]), unname(b$mean[1, ]))
  f <- l$tb_cv(d$x, d$th, fold, related, "leakfree", "mean")$mean
  # station 1 no longer sees station 5; station 2, unrelated to it, still does
  expect_equal(unname(f$mean[1, ]), unname(colMeans(d$th[6:12, ])))
  expect_equal(unname(f$mean[2, ]), unname(colMeans(d$th[5:12, ])))
  # and station 5 does not see station 1
  expect_equal(unname(f$mean[5, ]), unname(colMeans(d$th[c(2:4, 9:12), ])))
  expect_equal(f$df[1], 6)
  expect_false(anyNA(l$tb_cv(d$x, d$th, fold, related, "leakfree")$donor$mean))
  expect_error(l$tb_cv(d$x, d$th, fold[-1], related), "line up")
  bad <- related
  bad[2, 3] <- NA
  expect_error(l$tb_cv(d$x, d$th, fold, bad), "complete")
})

test_that("the simulated network part is shared only between flow-connected stations", {
  l <- local_tb_lib()
  # 1 is the mouth; 2 and 3 are on separate tributaries; 4 is above 2; 5 is in another basin
  up <- matrix(FALSE, 5, 5)
  up[1, c(2, 3, 4)] <- TRUE
  up[2, 4] <- TRUE
  area <- c(100, 40, 30, 10, 50)
  w <- l$tb_net_weights(up, area)
  expect_equal(rowSums(w^2), rep(1, 5))
  expect_equal(w[1, 2] / w[1, 1], 0.4)
  expect_equal(w[4, ], c(0, 0, 0, 1, 0))
  cv <- w %*% t(w)
  connected <- up | t(up) | diag(5) == 1
  expect_true(all(cv[connected] > 0))
  expect_equal(cv[!connected], rep(0, sum(!connected)))

  x <- cbind(t1 = c(1, 2, 3, 4, 6), t2 = c(2, 1, 5, 3, 4))
  rownames(x) <- paste0("s", 1:5)
  b0 <- c(eq0 = 3, eq1 = 0.8, rate = -2)
  beta <- matrix(c(1, 0, 0.1, 0, 0, 0.2), 2, 3)
  set.seed(4)
  s <- l$tb_simulate(x, up, area, b0, beta, sd_net = c(0.5, 0.05, 0.2), sd_noise = c(0.3, 0.03, 0.1))
  expect_identical(dimnames(s$theta), list(rownames(x), names(b0)))
  expect_equal(s$theta, s$fixed + sweep(s$net, 2, c(0.5, 0.05, 0.2), "*") + sweep(s$noise, 2, c(0.3, 0.03, 0.1), "*"))
  expect_equal(unname(s$fixed[, "eq0"]), unname(3 + drop(scale(x) %*% beta[, 1])))
  # over many draws: unit variance, correlated where connected, not otherwise
  set.seed(5)
  net <- t(replicate(4000, l$tb_simulate(x, up, area, b0, beta, c(1, 1, 1), c(0, 0, 0))$net[, 1]))
  expect_equal(unname(apply(net, 2, sd)), rep(1, 5), tolerance = 0.05)
  r <- cor(net)
  expect_gt(r[1, 2], 0.2)
  expect_gt(r[2, 4], 0.1)
  expect_lt(abs(r[2, 3]), 0.06)
  expect_lt(abs(r[1, 5]), 0.06)
  expect_error(l$tb_simulate(x, up[-1, ], area, b0, beta, c(1, 1, 1), c(0, 0, 0)), "line up")
})

test_that("upstream is read from the FWA codes, never a station of itself", {
  l <- local_tb_lib()
  st <- data.frame(station_number = c("mouth", "trib", "other"),
                   wscode = c("100", "100.500000", "200"), localcode = c("100", "100.500000", "200"))
  up <- l$tb_upstream(st)
  expect_true(up["mouth", "trib"])
  expect_false(up["trib", "mouth"])
  expect_false(any(diag(up)))
  expect_false(any(up["other", ], up[, "other"]))
})

test_that("a series is scored on the observed season days of its truth years", {
  l <- local_tb_lib()
  date <- seq(as.Date("2019-01-01"), as.Date("2020-12-31"), by = "day")
  y <- 8 + 6 * sin(2 * pi * (as.integer(format(date, "%j")) - 110) / 365)
  series <- list(date = date, a = y, y = y)
  series$y[date == as.Date("2019-07-04")] <- NA                  # an unobserved day is not scored
  s <- y + ifelse(format(date, "%Y") == "2019", 1, -2)
  s[date < as.Date("2019-03-01")] <- 99                          # outside the season: ignored
  g <- function(date, value, year) sum(value[format(date, "%Y") == year])
  sc <- l$tb_score(series, s, c(2019L, 2020L), g)
  expect_equal(sc$n, c(274L, 275L))
  expect_equal(sc$rmse, c(1, 2))
  expect_equal(sc$bias, c(1, -2))
  expect_equal(sc$gsdd, c(sum(s[format(date, "%Y") == "2019"]), sum(s[format(date, "%Y") == "2020"])))
  # a year with no GSDD is NA, not an error
  expect_true(is.na(l$tb_score(series, s, 2019L, function(...) numeric(0))$gsdd))
  expect_error(l$tb_score(series, s[-1], 2019L, g), "calendar")
  expect_error(l$tb_score(series, s, 2015L, g), "no observed day")
  n_obs <- function(date, value, year) length(value[format(date, "%Y") == year])
  obs <- l$tb_gsdd_observed(series, c(2019L, 2020L), n_obs)
  expect_equal(obs, c(364, 366))
})

test_that("tb_run() is wet's open-loop air2stream", {
  l <- local_tb_lib()
  a <- c(5, 6, 7, -30, -30, 8)
  expect_equal(l$tb_run(list(a = a), c(a1 = 0.5, a2 = 0.1, a3 = 0.2)), wet:::wet_a2s_run(0.5, 0.1, 0.2, a))
})

test_that("the rule's statistic is the mean over stations of each station's mean absolute error", {
  l <- local_tb_lib()
  sc <- data.frame(station_number = rep(c("a", "a", "a", "b"), 2), year = rep(c(2001, 2002, 2003, 2001), 2),
                   run = rep(c("x", "y"), each = 4), gsdd_obs = rep(c(1000, 1000, 1000, 2000), 2),
                   gsdd = c(1010, 970, 1100, 2100, 1000, 1000, 1000, 1900))
  s <- l$tb_statistic(sc)
  # station a: (10 + 30 + 100) / 3; station b: 100; stations weigh the same, whatever their years
  expect_equal(s$statistic, c(x = (140 / 3 + 100) / 2, y = 50))
  expect_equal(dim(s$by_station), c(2L, 2L))
  expect_equal(s$left_out, 0)
  # a year with no GSDD in one run leaves every run's statistic
  sc$gsdd[sc$station_number == "a" & sc$year == 2003 & sc$run == "y"] <- NA
  s <- l$tb_statistic(sc)
  expect_equal(s$statistic, c(x = (20 + 100) / 2, y = 50))
  expect_equal(s$left_out, 1)
  expect_setequal(s$paired, c("a 2001", "a 2002", "b 2001"))
  expect_equal(nrow(s$scores), 6)
  # so does an observed year with none
  sc$gsdd_obs[sc$station_number == "b"] <- NA
  expect_equal(l$tb_statistic(sc)$statistic, c(x = 20, y = 0))
  # the runs come back in the order asked for
  expect_named(l$tb_statistic(sc, c("y", "x"))$statistic, c("y", "x"))
  expect_error(l$tb_statistic(sc[-1, ]), "each run exactly once")
  expect_error(l$tb_statistic(rbind(sc, sc[1, ])), "each run exactly once")
  expect_error(l$tb_statistic(sc, c("x", "y", "z")), "each run exactly once")
  sc$gsdd <- NA
  expect_error(l$tb_statistic(sc), "no station-year")
  expect_error(l$tb_statistic(sc[c("station_number", "year")]), "scores need")
})

test_that("the code md5 covers the lib, the rule and the scoring script, and notices a change", {
  l <- local_tb_lib()
  root <- testthat::test_path("..", "..")
  expect_true(all(file.exists(file.path(root, l$tb_code_files))))
  expect_true(all(c("scripts/temp_baseline_lib.R", "scripts/temp_baseline_rule.R", "scripts/temp_baseline.R") %in%
                    l$tb_code_files))
  expect_match(l$tb_code_md5(root), "^[0-9a-f]{32}$")
  expect_error(l$tb_code_md5(tempdir()), "missing")
  # a copy with one byte more in one file has another md5
  tmp <- withr::local_tempdir()
  for (f in l$tb_code_files) {
    dir.create(dirname(file.path(tmp, f)), recursive = TRUE, showWarnings = FALSE)
    file.copy(file.path(root, f), file.path(tmp, f))
  }
  expect_identical(l$tb_code_md5(tmp), l$tb_code_md5(root))
  cat("\n", file = file.path(tmp, "scripts/temp_baseline.R"), append = TRUE)
  expect_false(identical(l$tb_code_md5(tmp), l$tb_code_md5(root)))
})
