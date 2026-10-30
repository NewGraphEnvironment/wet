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
