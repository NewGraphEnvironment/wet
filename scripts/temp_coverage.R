# Water-temperature coverage in the water-temp-bc archive (#36).
#
# What the archive holds at Parameter=5, what wet_temp_daily()'s filter drops,
# how many station-days survive its hour rule, and how many stations have a
# usable baseline in each decade. These are the numbers behind the 2016-2025
# baseline rule in wet_temp_daily() and research/station_water_temperature.md.
#
#   Rscript scripts/temp_coverage.R
#
# Reads the whole archive twice (raw readings, then wet_temp_daily() for every
# station), about a minute on a home connection. Writes
# data/checks/temp_coverage_report.txt.

devtools::load_all(quiet = TRUE)

root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
report <- file.path("data", "checks", "temp_coverage_report.txt")
valid <- eval(formals(wet_temp_daily)$valid)
min_hours <- formals(wet_temp_daily)$min_hours
decades <- list(2003:2012, 2011:2020, 2014:2023, 2016:2025)
# the Chinook open-water windows of vignettes/station-flow.Rmd
windows <- data.frame(window = c("ch_migration", "ch_spawning", "ch_fry_migration"),
                      start = c("05-01", "08-01", "07-15"), end = c("08-01", "09-15", "09-07"))

con <- DBI::dbConnect(duckdb::duckdb())
if (startsWith(root, "s3://")) {
  DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
  DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
}
# the bounds as wet_temp_daily() writes them into its own SQL
lo <- wet_sql_num(valid[1])
hi <- wet_sql_num(valid[2])
src <- sprintf("read_parquet(%s)", DBI::dbQuoteString(con, paste0(sub("/?$", "/", root), "*.parquet")))
raw <- DBI::dbGetQuery(con, sprintf(
  "SELECT count(*) AS n, count(Value) AS n_value, count(DISTINCT STATION_NUMBER) AS n_stations,
          min(Date) AS first, max(Date) AS last,
          count(*) FILTER (WHERE Value < %1$s) AS below,
          count(*) FILTER (WHERE Value > %2$s) AS above,
          count(*) FILTER (WHERE Value BETWEEN %1$s AND -0.5) AS kept_below_minus_half,
          count(*) FILTER (WHERE Value IN (99999, -99999, 999, 99.9)) AS sentinels
   FROM %3$s", lo, hi, src))
junk <- DBI::dbGetQuery(con, sprintf(
  "SELECT Value AS value, count(*) AS n FROM %s WHERE Value < %s OR Value > %s
   GROUP BY 1 ORDER BY n DESC, value LIMIT 8", src, lo, hi))
approval <- DBI::dbGetQuery(con, sprintf(
  "SELECT coalesce(Approval, '(none)') AS approval, min(Date) AS first,
          max(Date) AS last, count(*) AS n
   FROM %s GROUP BY 1 ORDER BY first", src))
stations <- DBI::dbGetQuery(con, sprintf("SELECT DISTINCT STATION_NUMBER AS s FROM %s", src))$s
DBI::dbDisconnect(con, shutdown = TRUE)
stations <- sort(stations)

offset <- wet_temp_offsets(stations)
# every station-day with a valid reading, then the hour rule applied to it
all_days <- suppressWarnings(wet_temp_daily(stations, to = NULL, min_hours = 1))
days <- all_days[all_days$n_hours >= min_hours, ]
days$year <- as.integer(format(days$date, "%Y"))

per_year <- as.data.frame(table(year = days$year), responseName = "days")
per_year$stations <- as.vector(tapply(days$station_number, days$year, function(x) length(unique(x))))

# stations with at least 300 days in at least 8 of the 10 years
year_days <- as.data.frame(table(station = days$station_number, year = days$year))
year_days$year <- as.integer(as.character(year_days$year))
base <- vapply(decades, function(yrs) {
  ok <- year_days[year_days$year %in% yrs & year_days$Freq >= 300, ]
  sum(table(as.character(ok$station)) >= 8)
}, 0L)

# the same bar for an open-water window: 80% of its days in 8 of 10 years
ws <- wet_window_stats(days, windows, stats = "mean", value = "t_mean_c", prefix = "t",
                       level_anomaly = "absolute", unit = "degC")
win <- vapply(windows$window, function(w) {
  vapply(decades, function(yrs) {
    ok <- ws[ws$period == w & ws$year %in% yrs, ]
    sum(table(ok$station_number) >= 8)
  }, 0L)
}, integer(length(decades)))

pct <- function(x, n) sprintf("%.2f %%", 100 * x / n)
lines <- c(
  sprintf("Run %s. Archive %s.", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), root),
  sprintf("wet_temp_daily() defaults: valid %s to %s degC, min_hours %d.", valid[1], valid[2],
          min_hours),
  "",
  "## Readings",
  sprintf("%s readings (%s with a value), %d stations, %s to %s UTC.",
          format(raw$n, big.mark = ","), format(raw$n_value, big.mark = ","), raw$n_stations,
          format(raw$first, tz = "UTC"), format(raw$last, tz = "UTC")),
  sprintf("Dropped below %s: %s (%s). Above %s: %s (%s). ECCC sentinels among them: %s.",
          valid[1], format(raw$below, big.mark = ","), pct(raw$below, raw$n_value), valid[2],
          format(raw$above, big.mark = ","), pct(raw$above, raw$n_value),
          format(raw$sentinels, big.mark = ",")),
  sprintf("Kept although between %s and -0.5: %s.", valid[1],
          format(raw$kept_below_minus_half, big.mark = ",")),
  "Most frequent dropped values:",
  sprintf("  %10s  %s", format(junk$value), format(junk$n, big.mark = ",")),
  "Approval, by first and last reading:",
  sprintf("  %-24s %s to %s  %s", approval$approval, as.Date(approval$first, tz = "UTC"),
          as.Date(approval$last, tz = "UTC"),
          format(approval$n, big.mark = ",")),
  "",
  "## Time zones (tidyhydat::allstations standard_offset)",
  sprintf("  %s: %d stations", c("UTC-8", "UTC-7", "not listed (taken as UTC-8)"),
          c(sum(offset %in% -8), sum(offset %in% -7), sum(is.na(offset)))),
  if (any(is.na(offset))) paste("  not listed:", paste(stations[is.na(offset)], collapse = ", ")),
  "",
  "## Station-days (local standard time)",
  sprintf("%s with a valid reading; %s (%s) have readings in at least %d hours.",
          format(nrow(all_days), big.mark = ","), format(nrow(days), big.mark = ","),
          pct(nrow(days), nrow(all_days)), min_hours),
  sprintf("Hours per day with a valid reading: median %g, 10th percentile %g.",
          stats::median(all_days$n_hours), stats::quantile(all_days$n_hours, 0.1, type = 1)),
  "",
  "Kept days and stations per year:",
  sprintf("  %s  %6s days  %3d stations", per_year$year, format(per_year$days, big.mark = ","),
          per_year$stations),
  "",
  "## Baseline coverage: stations with the bar met in at least 8 of 10 years",
  sprintf("  %-12s %-14s %s", "decade", "whole year", paste(sprintf("%-16s", windows$window), collapse = "")),
  sprintf("  %-12s %-14s %s", vapply(decades, function(y) paste(range(y), collapse = "-"), ""),
          base, apply(win, 1, function(r) paste(sprintf("%-16d", r), collapse = ""))),
  "  whole year: at least 300 kept days. Window: at least 80 % of its days kept (wet_window_stats() min_frac)."
)
writeLines(lines, report)
cat(lines, sep = "\n")
