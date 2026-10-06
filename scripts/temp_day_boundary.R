# Where wet_temp_daily() should split a day (#36).
#
# For a split at several local standard hours, the share of open-water days
# (May-September, diurnal range at least 1 degC) whose maximum or minimum
# hourly mean falls in the day's first or last hour. A split that cuts the
# daily cycle puts many extremes at its edges. Days follow wet_temp_daily()'s
# rules: readings in its default `valid` range, at least `min_hours` hours.
#
#   Rscript scripts/temp_day_boundary.R
#
# Reads the whole archive once per split, a few minutes in all. Writes
# data/checks/temp_day_boundary_report.txt.

devtools::load_all(quiet = TRUE)

root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
report <- file.path("data", "checks", "temp_day_boundary_report.txt")
valid <- eval(formals(wet_temp_daily)$valid)
min_hours <- formals(wet_temp_daily)$min_hours
splits <- c(0, 3, 6, 12, 18)

con <- DBI::dbConnect(duckdb::duckdb())
if (startsWith(root, "s3://")) {
  DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
  DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
}
src <- sprintf("read_parquet(%s)", DBI::dbQuoteString(con, paste0(sub("/?$", "/", root), "*.parquet")))
stations <- sort(DBI::dbGetQuery(con, sprintf("SELECT DISTINCT STATION_NUMBER AS s FROM %s", src))$s)
offset <- wet_temp_offsets(stations)
offset[is.na(offset)] <- -8
duckdb::duckdb_register(con, "wet_offset",
                        data.frame(station_number = stations, offset_s = as.integer(offset * 3600)))

# hour of each day's warmest and coolest hourly mean, for a split `h` hours
# after local midnight (hour 0 is then the day's first hour)
day_extremes <- function(h) {
  DBI::dbGetQuery(con, sprintf(
    "WITH r AS (
       SELECT p.STATION_NUMBER AS station_number,
              epoch_ms(p.Date) // 1000 + o.offset_s - %d AS sec, p.Value AS v
       FROM %s AS p JOIN wet_offset AS o ON p.STATION_NUMBER = o.station_number
       WHERE p.Value BETWEEN %s AND %s
     ), hr AS (
       SELECT station_number, sec // 86400 AS dd, (sec // 3600) %% 24 AS hh, avg(v) AS v
       FROM r GROUP BY ALL
     ), d AS (
       SELECT station_number, dd, hh, v, max(v) OVER w AS v_max, min(v) OVER w AS v_min,
              count(*) OVER w AS n_hours
       FROM hr WINDOW w AS (PARTITION BY station_number, dd)
     )
     -- on a tie, the earliest hour, so the report does not change between runs
     SELECT CAST(dd AS INTEGER) AS dd, min(hh) FILTER (WHERE v = v_max) AS h_max,
            min(hh) FILTER (WHERE v = v_min) AS h_min, max(v_max) - max(v_min) AS range_c
     FROM d WHERE n_hours >= %d GROUP BY station_number, dd",
    as.integer(h * 3600), src, wet_sql_num(valid[1]), wet_sql_num(valid[2]), as.integer(min_hours)))
}

edge <- function(h) h %in% c(0, 23)
# open-water days: May-September by the day's local start, diurnal range >= 1 degC
open_water <- function(d) {
  m <- as.integer(format(as.Date(d$dd, origin = "1970-01-01"), "%m"))
  m %in% 5:9 & d$range_c >= 1
}
d0 <- day_extremes(0)
rows <- lapply(splits, function(h) {
  d <- if (h == 0) d0 else day_extremes(h)
  x <- open_water(d)
  data.frame(split = sprintf("%02d:00", h), days = nrow(d), open_water = sum(x),
             max_edge = 100 * mean(edge(d$h_max[x])), min_edge = 100 * mean(edge(d$h_min[x])),
             either = 100 * mean(edge(d$h_max[x]) | edge(d$h_min[x])))
})
DBI::dbDisconnect(con, shutdown = TRUE)
r <- do.call(rbind, rows)

# where the extremes fall with the split at midnight
x0 <- open_water(d0)
hours <- function(h) sprintf("%5.1f", 100 * prop.table(table(factor(h[x0], 0:23))))

lines <- c(
  sprintf("Run %s. Archive %s. valid %s to %s degC, min_hours %d.",
          format(Sys.time(), "%Y-%m-%d %H:%M %Z"), root, valid[1], valid[2], min_hours),
  "Open water: May-September days (by local start) with a diurnal range of at least 1 degC.",
  "Edge: the day's first or last hour.",
  "",
  sprintf("  %-6s %8s %10s %13s %13s %8s", "split", "days", "open water", "max at edge", "min at edge",
          "either"),
  sprintf("  %-6s %8d %10d %12.1f%% %12.1f%% %7.1f%%", r$split, r$days, r$open_water, r$max_edge,
          r$min_edge, r$either),
  "",
  "Split at 00:00, percent of open-water days by local hour of the extreme:",
  sprintf("  hour  %s", paste(sprintf("%5d", 0:23), collapse = "")),
  sprintf("  max   %s", paste(hours(d0$h_max), collapse = "")),
  sprintf("  min   %s", paste(hours(d0$h_min), collapse = ""))
)
writeLines(lines, report)
cat(lines, sep = "\n")
