# Flow departure at hydrometric stations, per window and year (#25).
#
# For each station:
#   - build one daily series: HYDAT, then provisional, then real-time
#     (wet_station_daily())
#   - summarise it over calendar windows and two example life-history
#     windows (wet_window_stats())
#   - take departure from the 1981-2010 baseline and the trend from cd
#
# The report lists recent years' departures, with how much of each value
# rests on ice-affected or provisional days, and the trends.
#
#   Rscript scripts/station_departure.R [STATION ...]   # default 08EE013 08EE003
#
# HYDAT from WET_HYDAT, defaulting to data/hydat/20260717/Hydat.sqlite3. That
# is a newer release than the one the water balance (#11) was fit against,
# kept at its own path so that fit's inputs do not change.
#
# Needs cd with the #92 contract (series outside cd_variables()), plus Kendall
# and zyp for cd_trend().
#
# The two Chinook windows are the Bulkley columns of the template's
# life-history CSV (fish_species_life_history_gantt.csv). They are examples
# until knowledge#25 publishes the timing table.

devtools::load_all(quiet = TRUE)

stations <- commandArgs(trailingOnly = TRUE)
if (!length(stations)) stations <- c("08EE013", "08EE003")
hydat <- Sys.getenv("WET_HYDAT", file.path("data", "hydat", "20260717", "Hydat.sqlite3"))
baseline <- 1981:2010
trend_start <- c(1981, 2000)
recent <- 2023:2026
report <- file.path("data", "checks", "station_departure_report.txt")

probe <- data.frame(variable = "zz", period = "p", year = 2000:2001, value = 1:2,
                    anomaly_type = "absolute", unit = "u")
ok <- tryCatch(!anyNA(cd::cd_anomaly(probe, cd::cd_baseline(probe, 2000:2001))$anomaly),
               error = function(e) FALSE)
if (!ok) stop("cd lacks the #92 contract; install cd from main once PR #94 merges")

cal <- wet_windows_calendar()
windows <- rbind(
  cal[cal$window %in% c("aug", "sep", "djf", "jja", "son"), ],
  data.frame(window = c("ch_migration_example", "ch_spawning_example"),
             start = c("05-01", "08-01"), end = c("08-01", "09-15"))
)

# ---- daily series and station MAD -------------------------------------------
daily <- wet_station_daily(stations, hydat)
# MAD over 1981-2010 complete years where a station has at least 5, otherwise
# over every complete year it has (a gauge run only in open water until
# recently has none in the baseline).
station_mad <- function(years) {
  sel <- wet_station_select(hydat, years = years, min_years = 5)
  yrs <- attr(sel, "years")
  sel <- sel[sel$station_number %in% stations, ]
  attr(sel, "years") <- yrs[sel$station_number]
  m <- wet_station_monthly(sel, hydat)
  m <- m[m$month == 0, ]
  list(q = stats::setNames(m$q_m3s, m$station_number), years = attr(sel, "years"))
}
mad_base <- station_mad(baseline)
mad_all <- station_mad(1900:as.integer(format(Sys.Date(), "%Y")))
mad <- mad_base$q
mad_years <- mad_base$years
for (st in intersect(setdiff(stations, names(mad)), names(mad_all$q))) {
  mad[st] <- mad_all$q[[st]]
  mad_years[[st]] <- mad_all$years[[st]]
}
min_baseline <- 10

# A station wet_station_select() leaves out (fewer than 5 complete years, a
# regulation flag other than 0, or outside BC) has no MAD, so it gets
# every statistic but frac_below rather than stopping the run.
with_mad <- intersect(stations, names(mad))
no_mad <- setdiff(stations, with_mad)
stats <- rbind(
  if (length(with_mad)) {
    wet_window_stats(daily[daily$station_number %in% with_mad, ], windows,
                     threshold = 0.2 * mad[with_mad])
  },
  if (length(no_mad)) {
    wet_window_stats(daily[daily$station_number %in% no_mad, ], windows,
                     stats = c("mean", "min", "max", "min7", "cov_day"))
  }
)

# Provisional winter flows are not ice-corrected: at 08EE013 the provisional
# Dec 2025-Feb 2026 means are 6.5-15 m3/s against approved winters of
# 0.2-2 m3/s. So a window touching November-April keeps no year that rests on
# any provisional day.
touches_ice <- vapply(seq_len(nrow(windows)), function(k) {
  a <- as.Date(paste0("2001-", windows$start[k]))
  b <- as.Date(paste0(2001 + (windows$end[k] < windows$start[k]), "-",
                      sub("02-29", "02-28", windows$end[k])))
  any(as.integer(format(seq(a, b, by = "day"), "%m")) %in% c(11:12, 1:4))
}, TRUE)
ice_windows <- windows$window[touches_ice]
dropped <- unique(stats[stats$period %in% ice_windows & stats$frac_provisional > 0,
                        c("station_number", "period", "year")])
stats <- stats[!(stats$period %in% ice_windows & stats$frac_provisional > 0), ]

# ---- departure and trend, one station at a time (cd takes one series) ------
fmt <- function(x, d = 1) formatC(x, format = "f", digits = d)
out <- c(
  "# Flow departure at hydrometric stations (#25)",
  "",
  sprintf("Run %s. HYDAT %s. Baseline %d-%d. Threshold for frac_below: 20%% of the station's MAD (1981-2010, or its whole record of complete years where 1981-2010 has fewer than 5).",
          format(Sys.Date()), hydat, min(baseline), max(baseline)),
  "Anomalies: q_mean and q_min7 in % of normal; q_frac_below as a change in the share of days below the threshold.",
  "ice = share of the days present flagged B (ice); prov = share of the days present that are provisional (no ice flag recorded).",
  "The ch_* windows are examples from the template's Bulkley life-history CSV, pending knowledge#25.",
  sprintf("Windows touching Nov-Apr (%s) drop any year with provisional days: provisional winter flow is not ice-corrected.",
          paste(ice_windows, collapse = ", ")),
  ""
)
for (st in stations) {
  d <- daily[daily$station_number == st, ]
  s <- stats[stats$station_number == st, names(stats) != "station_number"]
  # cd_baseline() warns about baseline years without data; the count per window is reported
  # Baseline years per variable and window, over every window asked for: a
  # window with no qualifying year at all counts 0, it does not vanish.
  sb <- s[s$year %in% baseline, ]
  vars <- unique(c("q_mean", s$variable))
  nb <- expand.grid(variable = vars, period = windows$window, stringsAsFactors = FALSE)
  nb$year <- vapply(seq_len(nrow(nb)), function(k) {
    sum(sb$variable == nb$variable[k] & sb$period == nb$period[k])
  }, 0L)
  keep <- paste(nb$variable, nb$period)[nb$year >= min_baseline]
  thin <- nb$period[nb$variable == "q_mean" & nb$year < min_baseline]
  s <- s[paste(s$variable, s$period) %in% keep, ]

  out <- c(out, sprintf("## %s", st), "",
           if (st %in% with_mad) {
             sprintf("MAD: %s m3/s over %d complete years (%s)", fmt(mad[[st]], 2),
                     length(mad_years[[st]]), paste(range(mad_years[[st]]), collapse = "-"))
           } else paste("MAD: none (not a natural-flow BC station with 5+ complete years in HYDAT),",
                        "so no frac_below"),
           "")
  for (so in c("hydat", "provisional", "realtime")) {
    z <- d$date[d$source == so]
    if (length(z)) out <- c(out, sprintf("  %-11s %s .. %s  (%d days)", so, min(z), max(z), length(z)))
  }
  dr <- dropped[dropped$station_number == st, ]
  out <- c(out, "", sprintf("Dropped as provisional winter: %s",
                            if (nrow(dr)) paste(dr$period, dr$year, collapse = ", ") else "none"))
  out <- c(out, "", sprintf("No departure (fewer than %d baseline years): %s", min_baseline,
                            if (length(thin)) paste(thin, collapse = ", ") else "none"),
           "", "Baseline years per window (q_mean):",
           paste0("  ", paste(sprintf("%s %d", nb$period[nb$variable == "q_mean"],
                                      nb$year[nb$variable == "q_mean"]), collapse = ", ")),
           "")
  if (!nrow(s)) {
    out <- c(out, sprintf("No window has %d baseline years, so no departures.", min_baseline), "")
    next
  }
  b <- suppressWarnings(cd::cd_baseline(s, baseline))
  a <- cd::cd_anomaly(s, b)
  a <- merge(a, s[c("variable", "period", "year", "value", "n_days", "frac_ice",
                    "frac_provisional")], by = c("variable", "period", "year"))
  tr <- cd::cd_trend(a, trend_start = trend_start)
  out <- c(out, "Recent departures:", "",
           sprintf("  %-22s %4s %9s %9s %11s %5s %5s", "window", "year", "q_mean%", "q_min7%",
                   "frac_below", "ice", "prov"))
  for (w in windows$window) for (y in recent) {
    g <- a[a$period == w & a$year == y, ]
    if (!nrow(g)) next
    pick <- function(v) { r <- g$anomaly[g$variable == v]; if (length(r)) fmt(r) else "-" }
    q <- g[g$variable == "q_mean", ]
    out <- c(out, sprintf("  %-22s %4d %9s %9s %11s %5s %5s", w, y, pick("q_mean"), pick("q_min7"),
                          if (any(g$variable == "q_frac_below"))
                            fmt(g$anomaly[g$variable == "q_frac_below"], 2) else "-",
                          fmt(q$frac_ice, 2), fmt(q$frac_provisional, 2)))
  }
  tr <- tr[tr$variable %in% c("q_mean", "q_min7", "q_frac_below"), ]
  tr <- tr[order(tr$variable, match(tr$period, windows$window), tr$trend_start), ]
  out <- c(out, "", "Trends in the anomaly (Theil-Sen slope per year, Mann-Kendall p):", "",
           sprintf("  %-13s %-22s %5s %9s %7s %4s", "variable", "window", "from", "slope/yr", "p", "n"),
           sprintf("  %-13s %-22s %5d %9s %7s %4d", tr$variable, tr$period, as.integer(tr$trend_start),
                   fmt(tr$slope, 3), fmt(tr$mk_pvalue, 3), tr$n_years), "")
}
writeLines(out, report)
writeLines(out)
