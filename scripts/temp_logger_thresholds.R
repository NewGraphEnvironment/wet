# The logger QA thresholds, measured on the ECCC water temperature archive (#235, #215).
#
# Two rules screen logger days that gauges do not need screening for (registered in
# research/station_water_temperature.md, "Logger records"):
# - an air day: the day's range of hourly means exceeds its month's air threshold;
# - a stuck run: identical hourly means for more than the stuck threshold in hours.
# Both are measured here on the archive's open-water days, as scripts/temp_day_boundary.R
# defines them: May to September by the day's local start, diurnal range of hourly means at
# least 1 degC, under wet_temp_daily()'s rules (readings in its default `valid` range, local
# standard time, at least `min_hours` hours).
#
# The owner's rule (Decision 5 in #235, option a): the air threshold is the 99.9th percentile,
# by month, of the diurnal range on open-water days at ECCC stations whose HYDAT gross drainage
# area is under 1,000 km^2, or at every station in a month where those hold fewer than 1,000
# station-days; the stuck threshold is the 99.9th percentile of the longest run of identical
# hourly means above 0.5 degC per station-year in the open-water months, over every station
# (the rule names no subset for it). Option b, reported beside it: the same at the 99.5th
# percentile, over every station. Percentiles are R's type 7. The air threshold is rounded up
# to 0.01 degC and the stuck threshold to a whole hour, the values R/wet_logger_daily.R holds.
#
# Amendment 1 (the owner, 2026-11-27, after the first run and before any logger day was
# screened): that run's tails were the archive's own faulty sensors (08LG048 at 4.00 degC for
# 3,314 hours; August ranges to 35.5 degC), so the percentiles measured the faults the rules
# exist to catch. The reference is now screened first, by bounds set wide of anything flowing
# water does: a station-year holding a run of identical hourly means of 7 days (168 hours) or
# more is left out of both measures, and so is a day whose range exceeds 20 degC. Both options
# are then taken on what remains; the report lists what the screen removed, and the unscreened
# values beside them.
#
#   [WET_DATA_ROOT=<data dir>] [WET_HYDAT_RELEASE=20260717] Rscript scripts/temp_logger_thresholds.R
#
# The archive's hourly means are computed in R from its readings (not by duckdb's parallel
# avg(), whose last bits move between runs, #224) and kept in
# <WET_DATA_ROOT>/temp_loggers/eccc_hours.rds with the date they were read; a rerun reads that
# file and writes the report byte for byte. Remove it to read the archive again.
# Writes data/checks/temp_logger_thresholds.txt.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_hydat()

root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
release <- Sys.getenv("WET_HYDAT_RELEASE", wb_shipped_release)
report <- file.path("data", "checks", "temp_logger_thresholds.txt")
cache <- file.path(data_root, "temp_loggers", "eccc_hours.rds")
valid <- eval(formals(wet_temp_daily)$valid)
min_hours <- formals(wet_temp_daily)$min_hours
months <- 5:9
small_km2 <- 1000
min_station_days <- 1000
above_c <- 0.5
p_a <- 0.999
p_b <- 0.995

# ---- hourly means ------------------------------------------------------------------------------
if (!file.exists(cache)) {
  con <- DBI::dbConnect(duckdb::duckdb())
  invisible(DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;"))
  invisible(DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')"))
  src <- sprintf("read_parquet(%s)", DBI::dbQuoteString(con, paste0(sub("/?$", "/", root), "*.parquet")))
  stations <- sort(DBI::dbGetQuery(con, sprintf("SELECT DISTINCT STATION_NUMBER AS s FROM %s", src))$s,
                   method = "radix")
  offset <- wet_temp_offsets(stations)
  offset[is.na(offset)] <- -8
  duckdb::duckdb_register(con, "wet_offset",
                          data.frame(station_number = stations, offset_s = as.integer(offset * 3600)))
  # readings with their local standard hour; no aggregation here
  r <- DBI::dbGetQuery(con, sprintf(
    "SELECT p.STATION_NUMBER AS station_number, (epoch_ms(p.Date) // 1000 + o.offset_s) // 3600 AS hh,
            p.Value AS v
     FROM %s AS p JOIN wet_offset AS o ON p.STATION_NUMBER = o.station_number
     WHERE p.Value BETWEEN %s AND %s", src, wet_sql_num(valid[1]), wet_sql_num(valid[2])))
  n_readings <- nrow(r)
  DBI::dbDisconnect(con, shutdown = TRUE)
  # one group per station and hour, summed in a fixed order: station, hour, then value
  si <- match(r$station_number, stations)
  hh <- as.numeric(r$hh)
  o <- order(si, hh, r$v, method = "radix")
  si <- si[o]
  hh <- hh[o]
  v <- r$v[o]
  rm(r, o)
  first <- c(TRUE, diff(si) != 0 | diff(hh) != 0)
  g <- cumsum(first)
  h <- data.frame(station_number = stations[si[first]], hh = hh[first],
                  v = unname(rowsum(v, g, reorder = FALSE)[, 1]) / tabulate(g))
  rm(si, hh, v, first, g)
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  saveRDS(list(read = format(Sys.Date()), root = root, n_readings = n_readings, hours = h), cache)
}
cached <- readRDS(cache)
h <- cached$hours
h$dd <- h$hh %/% 24
h$date <- as.Date(h$dd, origin = "1970-01-01")
h$month <- as.integer(format(h$date, "%m"))
h$year <- as.integer(format(h$date, "%Y"))
h <- h[h$month %in% months, ]

# minimum and maximum of x within consecutive groups g (1, 1, 2, ...)
range_by <- function(x, g) {
  o <- order(g, x, method = "radix")
  last <- c(diff(g[o]) != 0, TRUE)
  first <- c(TRUE, last[-length(last)])
  list(min = x[o][first], max = x[o][last])
}

# ---- open-water days ---------------------------------------------------------------------------
h <- h[order(h$station_number, h$hh, method = "radix"), ]
dfirst <- c(TRUE, h$station_number[-1] != h$station_number[-nrow(h)] | diff(h$dd) != 0)
dg <- cumsum(dfirst)
rng <- range_by(h$v, dg)
days <- data.frame(station_number = h$station_number[dfirst], month = h$month[dfirst], year = h$year[dfirst],
                   n_hours = tabulate(dg), range_c = rng$max - rng$min)
days <- days[days$n_hours >= min_hours & days$range_c >= 1, ]

con <- wet_hydat_connect(wb_hydat(release))
area <- DBI::dbGetQuery(con, "SELECT STATION_NUMBER station_number, DRAINAGE_AREA_GROSS km2 FROM STATIONS")
DBI::dbDisconnect(con)
days$km2 <- area$km2[match(days$station_number, area$station_number)]
days$small <- !is.na(days$km2) & days$km2 < small_km2

# ---- stuck runs --------------------------------------------------------------------------------
# runs of consecutive hours with identical hourly means (to 1e-6 degC) above 0.5 degC, per
# station-year in the open-water months
k <- h[h$v > above_c, ]
k <- k[order(k$station_number, k$hh, method = "radix"), ]
vr <- round(k$v, 6)
brk <- c(TRUE, k$station_number[-1] != k$station_number[-nrow(k)] | diff(k$hh) != 1 | diff(vr) != 0)
run <- cumsum(brk)
len <- tabulate(run)
runs <- data.frame(station_number = k$station_number[brk], year = k$year[brk], start = k$date[brk],
                   v = vr[brk], hours = len)
sy <- stats::aggregate(hours ~ station_number + year, runs, max)
top <- runs[order(-runs$hours, runs$station_number, runs$start, method = "radix"), ][1:10, ]

# ---- Amendment 1: the reference screened of its own faults ---------------------------------------
screen_run_h <- 168
screen_range_c <- 20
gone_sy <- sy[sy$hours >= screen_run_h, ]
gone_sy <- gone_sy[order(gone_sy$station_number, gone_sy$year, method = "radix"), ]
in_gone <- paste(days$station_number, days$year) %in% paste(gone_sy$station_number, gone_sy$year)
gone_days <- days[!in_gone & days$range_c > screen_range_c, ]
raw_days <- days
days <- days[!in_gone & days$range_c <= screen_range_c, ]
raw_sy <- sy
sy <- sy[sy$hours < screen_run_h, ]
stuck_a <- unname(stats::quantile(sy$hours, p_a))
stuck_b <- unname(stats::quantile(sy$hours, p_b))

air_of <- function(days) do.call(rbind, lapply(months, function(m) {
  d <- days[days$month == m, ]
  s <- d[d$small, ]
  use <- if (nrow(s) >= min_station_days) s else d
  data.frame(month = m, days_all = nrow(d), stations_all = length(unique(d$station_number)), days_small = nrow(s),
             stations_small = length(unique(s$station_number)),
             subset = if (nrow(s) >= min_station_days) "under 1,000 km2" else "all stations",
             a = unname(stats::quantile(use$range_c, p_a)), b = unname(stats::quantile(d$range_c, p_b)),
             max_all = max(d$range_c))
}))
air <- air_of(days)
air_raw <- air_of(raw_days)
up2 <- function(x) ceiling(round(x * 100, 6)) / 100
air$a_c <- up2(air$a)
air$b_c <- up2(air$b)

# ---- report ------------------------------------------------------------------------------------
f2 <- function(x) sprintf("%.2f", x)
lines <- c(
  sprintf("Archive %s, read %s: %s readings in %s to %s degC; HYDAT %s for drainage areas.", cached$root, cached$read,
          format(cached$n_readings, big.mark = ","), f2(valid[1]), f2(valid[2]), release),
  sprintf("Open-water days: months %d-%d by the day's local standard start, at least %d hours, range of hourly means",
          min(months), max(months), min_hours),
  "at least 1 degC. Percentiles are R's type 7.",
  "",
  "## Amendment 1: the reference screened of its own faults",
  sprintf("Left out: %d station-years holding a run of identical hourly means of %d hours or more, and %s further",
          nrow(gone_sy), screen_run_h, format(nrow(gone_days), big.mark = ",")),
  sprintf("open-water days whose range exceeds %d degC (%s).", screen_range_c,
          paste(sprintf("%s %d", month.abb[months], tabulate(factor(gone_days$month, months), length(months))),
                collapse = ", ")),
  sprintf("  %s %d: longest run %d h", gone_sy$station_number, gone_sy$year, gone_sy$hours),
  "Unscreened, as the first run measured them:",
  sprintf("  air a: %s degC; stuck a: %d h", paste(sprintf("%s %s", month.abb[air_raw$month], f2(up2(air_raw$a))),
                                                collapse = ", "),
          ceiling(round(unname(stats::quantile(raw_sy$hours, p_a)), 6))),
  "",
  "## Air threshold: diurnal range of hourly means (degC), by month (screened)",
  sprintf("Option a: %.1fth percentile at stations under %s km2 gross drainage area (all stations where those hold",
          100 * p_a, format(small_km2, big.mark = ",")),
  sprintf("fewer than %s station-days). Option b: %.1fth percentile at all stations. Rounded up to 0.01 degC.",
          format(min_station_days, big.mark = ","), 100 * p_b),
  sprintf("  %5s %9s %9s %10s %10s  %-16s %8s %8s %8s", "month", "days", "stations", "days<1000", "stns<1000",
          "subset (a)", "a", "b", "max"),
  sprintf("  %5s %9s %9s %10s %10s  %-16s %8s %8s %8s", month.abb[air$month], format(air$days_all, big.mark = ","),
          air$stations_all, format(air$days_small, big.mark = ","), air$stations_small, air$subset, f2(air$a_c),
          f2(air$b_c), f2(air$max_all)),
  "",
  "## Stuck threshold: longest run of identical hourly means above 0.5 degC per station-year (hours, screened)",
  sprintf("%s station-years in months %d-%d, all stations. Option a: %.1fth percentile; option b: %.1fth.",
          format(nrow(sy), big.mark = ","), min(months), max(months), 100 * p_a, 100 * p_b),
  sprintf("  a: %s hours (%d rounded up)   b: %s hours (%d rounded up)", f2(stuck_a), ceiling(round(stuck_a, 6)),
          f2(stuck_b), ceiling(round(stuck_b, 6))),
  sprintf("  station-years by longest run: median %s h, 99th percentile %s h, longest %d h",
          f2(stats::median(sy$hours)), f2(stats::quantile(sy$hours, 0.99)), max(sy$hours)),
  "The ten longest runs, before the screen:",
  sprintf("  %s  %s  %6.2f degC  %5d h", top$station_number, format(top$start), top$v, top$hours),
  "",
  "## Shipped (option a, the owner's, under Amendment 1)",
  sprintf("  wet_logger_air_c   = c(%s)", paste(sprintf("`%d` = %s", air$month, f2(air$a_c)), collapse = ", ")),
  sprintf("  wet_logger_stuck_h = %d", ceiling(round(stuck_a, 6))))
writeLines(lines, report)
message("wrote ", report)
