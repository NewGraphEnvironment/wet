source("/private/tmp/claude-501/-Users-airvine-Projects-repo-wet/eb2d4c28-2164-43ae-9073-54f7a2bd7d8a/scratchpad/fill2.R")
d <- "/Users/airvine/Projects/repo/wet/data/temp_fill"
w <- readRDS(file.path(d, "spike_08E_water.rds")); air <- readRDS(file.path(d, "spike_08E_air.rds"))
n <- table(w$station_number); st <- names(n)[n >= 1000]; w <- w[w$station_number %in% st, ]
mk <- function(w) { s <- lapply(st, function(s) { x <- w[w$station_number == s, ]; aa <- air[air$id == s, ]
  date <- seq(min(x$date), max(x$date), by = "day"); list(date = date, a = aa$value[match(date, aa$date)], y = x$t_mean_c[match(date, x$date)]) }); names(s) <- st; s }
hold <- function(s, a, b) { x <- w[w$station_number == s, ]
  for (yy in rev(unique(format(x$date, "%Y")))) { lo <- as.Date(paste0(yy, a)); hi <- as.Date(paste0(yy, b))
    k <- x$date >= lo & x$date <= hi; if (sum(k) >= 0.98 * as.integer(hi - lo + 1)) return(w$station_number == s & w$date >= lo & w$date <= hi) }
  rep(FALSE, nrow(w)) }
run <- function(a, b, label) { r <- list()
  for (s in st) { h <- hold(s, a, b); if (!any(h)) next
    tr <- w[h, ]; ser <- mk(w[!h, ])
    f <- fill_pool(ser); f0 <- fill_pool(ser["" != names(ser)][s], peers = FALSE)
    g <- f[[s]]; k <- match(tr$date, g$date); g0 <- f0[[s]]
    rm <- function(v) sqrt(mean((v[k] - tr$t_mean_c)^2))
    r[[s]] <- data.frame(station = s, rho = round(g$par[["rho"]], 2), b = round(g$par[["b"]], 2), a3 = round(g$par[3], 3),
      full = rm(g$mean), smooth_b0 = rm(g0$mean), fwd_b0 = rm(g0$fwd), openloop = rm(g$ol),
      cover = mean(abs(tr$t_mean_c - g$mean[k]) <= 1.96 * g$sd[k])) }
  r <- do.call(rbind, r); cat("\n==", label, "\n"); print(r, digits = 3); print(colMeans(r[, -(1:4)]), digits = 3) }
t0 <- Sys.time(); run("-07-01", "-07-30", "30-day July"); run("-03-01", "-11-30", "season Mar-Nov"); print(Sys.time() - t0)
