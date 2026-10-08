pkgload::load_all("/Users/airvine/Projects/repo/wet", quiet = TRUE)
d <- "/Users/airvine/Projects/repo/wet/data/temp_fill"
w <- readRDS(file.path(d, "spike_08E_water.rds")); air <- readRDS(file.path(d, "spike_08E_air.rds"))
n <- table(w$station_number); st <- names(n)[n >= 1000]
w <- w[w$station_number %in% st, ]
# open-loop air2stream: fit a1..a3 by RMSE of simulation from first obs
ol_run <- function(p, a, w0) { n <- length(a); x <- numeric(n); x[1] <- w0
  for (t in 2:n) x[t] <- max(0, (1 - p[3]) * x[t-1] + p[1] + p[2] * a[t]); x }
ol_fit <- function(y, a) { i <- which(!is.na(y)); w0 <- y[i[1]]
  f <- function(th) { p <- c(th[1], th[2], plogis(th[3])); s <- ol_run(p, a, w0); sqrt(mean((s[i]-y[i])^2)) }
  o <- optim(c(0.5, 0.1, qlogis(0.1)), f, control = list(maxit = 3000))
  p <- c(o$par[1], o$par[2], plogis(o$par[3])); list(p = p, sim = ol_run(p, a, w0)) }
score <- function(holdfun, label) {
  res <- list()
  for (s in st) {
    hide <- holdfun(w, s)
    if (!any(hide)) next
    truth <- w[hide, c("date", "t_mean_c")]
    full <- wet_temp_fill(w[!hide, ], air)
    k <- full$station_number == s
    f <- full[k, ]; m <- match(truth$date, f$date)
    alone <- wet_temp_fill(w[!hide & w$station_number == s, ], air)
    m2 <- match(truth$date, alone$date)
    # open-loop on the station's own calendar
    z <- alone; a <- air$value[air$id == s & air$variable == "tmean"][match(z$date, air$date[air$id == s & air$variable == "tmean"])]
    y <- ifelse(z$filled, NA, z$t_mean_c)
    ol <- ol_fit(y, a)$sim[m2]
    fit <- attr(full, "fit"); fit <- fit[fit$station_number == s, ]
    cover <- mean(truth$t_mean_c >= f$t_lo_c[m] & truth$t_mean_c <= f$t_hi_c[m])
    res[[s]] <- data.frame(station = s, n = nrow(truth), b = round(fit$b, 2), a3 = round(fit$a3, 3),
      full = sqrt(mean((f$t_mean_c[m] - truth$t_mean_c)^2)), smooth_b0 = sqrt(mean((alone$t_mean_c[m2] - truth$t_mean_c)^2)),
      openloop = sqrt(mean((ol - truth$t_mean_c)^2)), cover = cover)
  }
  r <- do.call(rbind, res); cat("\n==", label, "\n"); print(r, digits = 3)
  print(colMeans(r[, c("full", "smooth_b0", "openloop", "cover")]), digits = 3)
}
season <- function(w, s, y = NULL) {
  x <- w[w$station_number == s, ]
  yrs <- unique(format(x$date, "%Y"))
  for (yy in rev(yrs)) { k <- x$date >= as.Date(paste0(yy, "-03-01")) & x$date <= as.Date(paste0(yy, "-11-30"))
    if (sum(k) >= 270) return(w$station_number == s & w$date >= as.Date(paste0(yy, "-03-01")) & w$date <= as.Date(paste0(yy, "-11-30"))) }
  rep(FALSE, nrow(w)) }
july <- function(w, s) { x <- w[w$station_number == s, ]
  for (yy in rev(unique(format(x$date, "%Y")))) { k <- x$date >= as.Date(paste0(yy, "-07-01")) & x$date <= as.Date(paste0(yy, "-07-30"))
    if (sum(k) >= 30) return(w$station_number == s & w$date >= as.Date(paste0(yy, "-07-01")) & w$date <= as.Date(paste0(yy, "-07-30"))) }
  rep(FALSE, nrow(w)) }
t0 <- Sys.time()
score(july, "30-day July gap")
score(season, "whole Mar-Nov season")
print(Sys.time() - t0)
