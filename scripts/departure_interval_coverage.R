# Does the measured article's change range hold its coverage? (#152)
#
#   Rscript scripts/departure_interval_coverage.R
#
# vignettes/flow-departure-normal.Rmd shows the change in each chinook timing
# window's mean flow from its 1981-2010 mean to the mean of 2016-2025, with
# the middle 90 % of 5000 changes from resampling each period's years with
# replacement (a percentile bootstrap of a ratio of means). #145's review
# measured that with five recent years this covered 82 %, not 90 %. This script
# measures it at the article's own years. The rule, registered here before any
# body code:
#
#   - The article's inputs: inst/vignette-data/station_daily.rds,
#     wet_window_stats(stats = "mean") over its two windows (Migration
#     05-01..08-01, Spawning 08-01..09-15), each gauge's 1981-2010 and
#     2016-2025 window-years, as the article counts them.
#   - Per gauge and window: 2000 simulated records with no change, both
#     periods' window means drawn lognormal with the mean and SD of the log of
#     that gauge's own 1981-2010 window means, as many years per period as the
#     article has. Each is put through the article's interval with 1000 draws.
#     Coverage is the share of the 2000 whose interval covers no change.
#     set.seed(152).
#   - The article calls the interval a 90 % range only if every coverage is at
#     least 0.87. Otherwise it calls it the middle 90 % of resampled changes
#     and rests no count on it.
#
# Writes the tracked report data/checks/departure_interval_coverage.txt (no
# timestamp, so a rerun reproduces it). Needs no network, HYDAT or database.

devtools::load_all(quiet = TRUE)

daily <- readRDS(file.path("inst", "vignette-data", "station_daily.rds"))
windows <- data.frame(window = c("Migration", "Spawning"), start = c("05-01", "08-01"), end = c("08-01", "09-15"))
baseline <- 1981:2010
recent <- 2016:2025
n_sim <- 2000
n_draw <- 1000
floor_cover <- 0.87

stats <- wet_window_stats(daily, windows, stats = "mean")
stats <- stats[stats$variable == "q_mean", ]
# the article's interval, vectorised over draws: the middle 90 % of the resampled changes
interval_of <- function(r, b) {
  mr <- colMeans(matrix(r[sample.int(length(r), length(r) * n_draw, replace = TRUE)], length(r)))
  mb <- colMeans(matrix(b[sample.int(length(b), length(b) * n_draw, replace = TRUE)], length(b)))
  stats::quantile(100 * (mr / mb - 1), c(0.05, 0.95), names = FALSE)
}
set.seed(152)
rows <- list()
for (st in unique(stats$station_number)) {
  for (w in windows$window) {
    x <- stats[stats$station_number == st & stats$period == w, ]
    b <- x$value[x$year %in% baseline]
    n_r <- sum(x$year %in% recent)
    mu <- mean(log(b))
    s <- stats::sd(log(b))
    hit <- vapply(seq_len(n_sim), function(k) {
      q <- interval_of(stats::rlnorm(n_r, mu, s), stats::rlnorm(length(b), mu, s))
      q[1] <= 0 && q[2] >= 0
    }, TRUE)
    rows[[length(rows) + 1]] <- data.frame(station_number = st, window = w, n_base = length(b), n_recent = n_r,
                                           sdlog = s, cover = mean(hit))
  }
}
cv <- do.call(rbind, rows)
pass <- all(cv$cover >= floor_cover)
fmt <- function(x, d) formatC(x, format = "f", digits = d)
out <- c(
  "# The measured article's change range: coverage at its own years (#152)",
  "",
  sprintf("Inputs: inst/vignette-data/station_daily.rds (md5 %s); baseline %d-%d, recent %d-%d.",
          unname(tools::md5sum(file.path("inst", "vignette-data", "station_daily.rds"))), min(baseline), max(baseline),
          min(recent), max(recent)),
  sprintf("Rule (this script's header): %d simulated records with no change per gauge and window, lognormal with the gauge's own 1981-2010 log mean and SD; the article's interval with %d draws; set.seed(152). A 90 %% range only if every coverage is at least %.2f.",
          n_sim, n_draw, floor_cover),
  "",
  sprintf("  %-8s %-10s %6s %6s %6s %6s", "gauge", "window", "base", "recent", "sdlog", "cover"),
  sprintf("  %-8s %-10s %6d %6d %6s %6s", cv$station_number, cv$window, cv$n_base, cv$n_recent, fmt(cv$sdlog, 3),
          fmt(cv$cover, 3)),
  "",
  if (pass) sprintf("OUTCOME: every coverage is at least %.2f, so the article calls it a 90 %% range.", floor_cover) else
    sprintf("OUTCOME: coverage below %.2f at %d of %d, so the article calls it the middle 90 %% of resampled changes and rests no count on it.",
            floor_cover, sum(cv$cover < floor_cover), nrow(cv))
)
writeLines(out, file.path("data", "checks", "departure_interval_coverage.txt"))
message(paste(out, collapse = "\n"))
