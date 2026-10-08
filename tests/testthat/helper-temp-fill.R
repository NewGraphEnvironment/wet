# Synthetic stations for wet_temp_fill(): air is a seasonal cycle plus shared
# AR(1) weather; water follows the daily air2stream recursion
#   W_t = max(0, (1 - a3) W_{t-1} + a1 + a2 A_t + b g_t + e_t)
# where g_t is a shared daily signal that air temperature does not carry
# (cloud, rain) and e_t is each station's own noise. `pars` has one row per
# station: station_number, a1, a2, a3, b, sd.
sim_temp_fill <- function(pars, from = "2018-01-01", to = "2020-12-31", seed = 1,
                          g_sd = 0.6) {
  set.seed(seed)
  date <- seq(as.Date(from), as.Date(to), by = "day")
  n <- length(date)
  doy <- as.integer(format(date, "%j"))
  z <- as.numeric(stats::filter(stats::rnorm(n, 0, 2), 0.7, method = "recursive"))
  a <- 4 + 13 * sin(2 * pi * (doy - 110) / 365) + z
  g <- stats::rnorm(n, 0, g_sd)
  water <- lapply(seq_len(nrow(pars)), function(k) {
    p <- pars[k, ]
    w <- numeric(n)
    w[1] <- max(0, (p$a1 + p$a2 * a[1]) / p$a3)
    e <- stats::rnorm(n, 0, p$sd)
    for (t in 2:n) {
      w[t] <- max(0, (1 - p$a3) * w[t - 1] + p$a1 + p$a2 * a[t] + p$b * g[t] + e[t])
    }
    data.frame(station_number = p$station_number, date = date, t_mean_c = w,
               t_min_c = w - 1, t_max_c = w + 1, n_hours = 24L, source = "provisional",
               status = "provisional")
  })
  air <- do.call(rbind, lapply(pars$station_number, function(s) {
    data.frame(id = s, date = date, variable = "tmean", value = a, cell = 1L)
  }))
  list(temp = do.call(rbind, water), air = air)
}

sim_pars <- function(b = c(1, 1, 1, 0)) {
  data.frame(station_number = sprintf("08AA%03d", seq_along(b)), a1 = 0.6, a2 = 0.12,
             a3 = 0.18, b = b, sd = 0.25)
}
