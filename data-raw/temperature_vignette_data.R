# Data for vignettes/articles/segment-temperature.Rmd (#220), which runs on
# this file and never touches the archive, cd, HYDAT or fwapg at build.
#
#   Rscript data-raw/temperature_vignette_data.R [basin]
#
# Writes inst/vignette-data/temperature_values.rds: one station's year of
# daily water temperature with a gap filled, its growing season and degree
# days, the stations of its basin, and how the station-year was picked.
#
# THE RULES, written before the pick was computed.
#
# Basin (which row of scripts/temperature_basins.csv is run):
#   1. candidates are whole basins the main-flow tree's network check ran
#      clean on with the additive-function step on, as the fork's record of
#      that check states when this script was written: the Bulkley alone (the
#      Skeena ran the topology check only, and the other clean runs are single
#      watershed groups);
#   2. among them, the basin with the most temperature stations snapped to
#      its network.
#
# Station-year (computed below; never stored in the table):
#   1. the stations are those of the basin's pool (the archive's stations
#      whose number starts with the row's `pool`, a WSC sub-drainage) whose
#      Freshwater Atlas snap (wet_station_snap()) lies under the basin's main
#      stem; water from wet_temp_daily() over `from` to `to`, a fixed range,
#      so the pick does not move as the archive grows;
#   2. a year qualifies when 1 March to 30 November has exactly one run of
#      missing days of 7 to 45 days, with observed days on both sides of it
#      inside that window, and every other missing run is 2 days or shorter
#      (the fill validation's tolerance, scripts/temp_fill_validate.R);
#   3. the station is fitted by wet_temp_fill() (pool: the WSC sub-drainage),
#      the filled year has a degree-day value (wet_temp_gsdd()) where the
#      unfilled year has none, and the gap lies inside a growing season
#      gsdd::gss() finds in the filled year;
#   4. the pick is the year whose gap is closest to 30 days, the validation's
#      30-day holdout, whose error is known; ties go to the later year, then
#      the lower station number;
#   5. with no candidate the gap bound widens once, to 60 days; with none
#      still, the script stops and prints the table (the next basin by the
#      basin rule is another row of the table).
#
# The rule was written after a read of the archive had shown which years of
# the 08EE stations hold a single gap (planning/archive/*issue-220*); it is
# stated here whole so the pick can be checked against it, and
# tests/testthat/test-vignette_data.R re-derives the pick from the bundled
# candidate table.
#
# Inputs: the water-temp-bc archive (public S3) and cd's daily air cube, both
# cached under data/temperature_vignette/ (gitignored) and fetched when
# absent; HYDAT at WET_HYDAT_RELEASE (default the shipped release) for the
# stations' coordinates and areas; fwapg from the WET_PG* variables for the
# snap; the tracked data/checks/temp_fill_validate.txt for the fill's
# held-out error. A rerun that changes no value leaves the file as it is.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")          # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")   # vd_commit(), vd_connect()
source("scripts/vignette_map_lib.R")    # vm_stations()

commit <- vd_commit()
args <- commandArgs(trailingOnly = TRUE)
basin_id <- if (length(args)) args[1] else "bulkley"
from <- "2002-01-01"
to <- "2025-12-31"
window <- c("03-01", "11-30")   # wet_temp_gsdd()'s default start_date and end_date
gap_days <- c(7, 45)
gap_days_wide <- 60
other_max <- 2
gap_target <- 30
out <- file.path("inst", "vignette-data", "temperature_values.rds")
cache <- file.path("data", "temperature_vignette")
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
stopifnot(identical(format(formals(wet_temp_gsdd)$start_date |> eval(), "%m-%d"), window[1]),
          identical(format(formals(wet_temp_gsdd)$end_date |> eval(), "%m-%d"), window[2]))

basins <- utils::read.csv(file.path("scripts", "temperature_basins.csv"), stringsAsFactors = FALSE,
                          colClasses = "character")
basin <- as.list(basins[basins$basin == basin_id, ])
if (length(basin$basin) != 1) stop("no single row for basin ", basin_id, " in scripts/temperature_basins.csv")
basin$blue_line_key <- as.integer(basin$blue_line_key)

# ---- the pool's stations, and those on the basin's network ------------------------------------
root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
f_water <- file.path(cache, sprintf("%s_water_%s_%s.rds", basin$pool, substr(from, 1, 4), substr(to, 1, 4)))
if (!file.exists(f_water)) {
  duck <- DBI::dbConnect(duckdb::duckdb())
  invisible(DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;"))
  invisible(DBI::dbExecute(duck, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')"))
  pool_st <- DBI::dbGetQuery(duck, sprintf(
    "SELECT DISTINCT STATION_NUMBER AS s FROM read_parquet(%s) WHERE starts_with(STATION_NUMBER, %s) ORDER BY s",
    DBI::dbQuoteString(duck, paste0(sub("/?$", "/", root), "*.parquet")), DBI::dbQuoteString(duck, basin$pool)))$s
  DBI::dbDisconnect(duck, shutdown = TRUE)
  stopifnot(length(pool_st) > 0)
  w <- wet_temp_daily(pool_st, from = from, to = to)
  attr(w, "retrieved") <- Sys.Date()
  saveRDS(w, f_water)
}
water <- readRDS(f_water)
retrieved <- attr(water, "retrieved")
attr(water, "retrieved") <- NULL
pool_st <- sort(unique(water$station_number), method = "radix")

hydat <- wb_hydat(wb_release())
st <- vm_stations(hydat, pool_st)
if (anyNA(st$drainage_area_gross_km2)) {
  stop("no gross drainage area in HYDAT for: ", paste(st$station_number[is.na(st$drainage_area_gross_km2)], collapse = ", "))
}
conn <- vd_connect()
main <- DBI::dbGetQuery(conn, sprintf("
  SELECT DISTINCT wscode_ltree::text AS wscode FROM whse_basemapping.fwa_stream_networks_sp
  WHERE blue_line_key = %d AND blue_line_key = watershed_key", basin$blue_line_key))$wscode
stopifnot(length(main) == 1)
snap <- wet_station_snap(conn, st)
DBI::dbDisconnect(conn)
stopifnot(identical(snap$station_number, st$station_number))
# under the main stem: its code, or a code that continues it
under <- !is.na(snap$wscode) & (snap$wscode == main | startsWith(snap$wscode, paste0(main, ".")))
if (any(under & !snap$accepted)) {
  stop("a snap under the basin's main stem was not accepted, so the basin's stations are not known: ",
       paste(snap$station_number[under & !snap$accepted], collapse = ", "))
}
basin_st <- snap$station_number[under]
stopifnot(length(basin_st) > 0)

# ---- air, and the fill of the whole pool -----------------------------------------------------
f_air <- file.path(cache, sprintf("%s_air_%s_%s.rds", basin$pool, substr(from, 1, 4), substr(to, 1, 4)))
if (!file.exists(f_air)) {
  p <- data.frame(id = st$station_number, lon = st$lon, lat = st$lat)
  saveRDS(as.data.frame(cd::cd_extract_daily(p, from, to, variables = "tmean")), f_air)
}
air <- readRDS(f_air)
stopifnot(setequal(unique(air$id), pool_st), inherits(air$date, "Date"))
pool <- stats::setNames(substr(pool_st, 1, 3), pool_st)
fill <- wet_temp_fill(water, air, pool = pool)
fit <- attr(fill, "fit")

# ---- the candidate table (rule 2) -------------------------------------------------------------
runs_of <- function(dates, year) {
  d <- seq(as.Date(paste0(year, "-", window[1])), as.Date(paste0(year, "-", window[2])), by = "day")
  miss <- !d %in% dates
  r <- rle(miss)
  last <- cumsum(r$lengths)
  first <- last - r$lengths + 1
  x <- data.frame(start = d[first], end = d[last], days = r$lengths)[r$values, ]
  x$edge <- x$start == d[1] | x$end == d[length(d)]
  list(observed = sum(!miss), runs = x)
}
cand <- do.call(rbind, lapply(basin_st, function(s) {
  dates <- water$date[water$station_number == s]
  do.call(rbind, lapply(sort(unique(as.integer(format(dates, "%Y")))), function(y) {
    g <- runs_of(dates, y)
    if (!g$observed) return(NULL)
    r <- g$runs
    long <- r[r$days > other_max, ]
    one <- nrow(long) == 1 && !long$edge
    data.frame(station_number = s, year = y, observed = g$observed, runs = nrow(r),
               runs_over = nrow(long),
               gap_start = if (one) long$start else as.Date(NA),
               gap_end = if (one) long$end else as.Date(NA),
               gap_days = if (one) long$days else NA_integer_)
  }))
}))
rownames(cand) <- NULL
cand$fitted <- cand$station_number %in% fit$station_number

# rule 3, for every year with one interior gap, whatever its length
obs_gsdd <- wet_temp_gsdd(water[water$station_number %in% basin_st, ])
fill_gsdd <- wet_temp_gsdd(fill[fill$station_number %in% basin_st, ])
value_of <- function(g, s, y) {
  v <- g$value[g$station_number == s & g$year == y]
  if (length(v)) v else NA_real_
}
seasons_of <- function(s, y) {
  x <- fill[fill$station_number == s & format(fill$date, "%Y") == y, ]
  date <- seq(min(x$date), max(x$date), by = "day")
  g <- as.data.frame(gsdd::gss(data.frame(date = date, temperature = x$t_mean_c[match(date, x$date)]), msgs = FALSE))
  g <- g[g$year == y, ]
  data.frame(start = as.Date(paste0(y, format(as.Date(g$start_dayte), "-%m-%d"))),
             end = as.Date(paste0(y, format(as.Date(g$end_dayte), "-%m-%d"))),
             gsdd = as.numeric(g$gsdd), truncation = as.character(g$truncation))
}
cand$gsdd_unfilled <- mapply(value_of, list(obs_gsdd), cand$station_number, cand$year)
cand$gsdd_filled <- mapply(value_of, list(fill_gsdd), cand$station_number, cand$year)
cand$in_season <- vapply(seq_len(nrow(cand)), function(i) {
  if (is.na(cand$gap_days[i]) || !cand$fitted[i]) return(NA)
  s <- seasons_of(cand$station_number[i], cand$year[i])
  any(s$start <= cand$gap_start[i] & s$end >= cand$gap_end[i])
}, NA)

# rules 2 to 5
qualifies <- function(max_days) {
  !is.na(cand$gap_days) & cand$gap_days >= gap_days[1] & cand$gap_days <= max_days &
    cand$fitted & is.na(cand$gsdd_unfilled) & !is.na(cand$gsdd_filled) & cand$in_season %in% TRUE
}
gap_max <- gap_days[2]
if (!any(qualifies(gap_max))) gap_max <- gap_days_wide
cand$qualifies <- qualifies(gap_max)
print(cand[!is.na(cand$gap_days) | cand$qualifies, ], row.names = FALSE)
if (!any(cand$qualifies)) stop("no station-year of ", basin$basin, " meets the rule, at ", gap_days_wide, " days either")
o <- order(abs(cand$gap_days - gap_target), -cand$year, cand$station_number, method = "radix")
o <- o[cand$qualifies[o]]
cand$picked <- seq_len(nrow(cand)) == o[1]
pick <- as.list(cand[cand$picked, c("station_number", "year", "gap_start", "gap_end", "gap_days")])
pick$gap_max <- gap_max
message("picked ", pick$station_number, " ", pick$year, ": ", pick$gap_days, " days from ", pick$gap_start)

# ---- the picked year --------------------------------------------------------------------------
s <- pick$station_number
y <- pick$year
fs <- fill[fill$station_number == s, ]
days <- seq(as.Date(paste0(y, "-01-01")), as.Date(paste0(y, "-12-31")), by = "day")
k <- match(days, fs$date)
year <- data.frame(date = days, t_mean_c = fs$t_mean_c[k], filled = fs$filled[k], t_lo_c = fs$t_lo_c[k],
                   t_hi_c = fs$t_hi_c[k])
as_ <- air[air$id == s & air$variable == "tmean", ]
year$air_c <- as_$value[match(days, as_$date)]
# open-loop air2stream, as the fit ran it: over the station's record, from the first day's
# equilibrium. Its error on the observed days must be the fit's own
ws <- water[water$station_number == s, ]
rec <- seq(min(ws$date), max(ws$date), by = "day")
a <- as_$value[match(rec, as_$date)]
stopifnot(!anyNA(a))
f1 <- fit[fit$station_number == s, ]
s_open <- wet:::wet_a2s_run(f1$a1, f1$a2, f1$a3, a)
obs <- ws$t_mean_c[match(rec, ws$date)]
stopifnot(isTRUE(all.equal(sqrt(mean((s_open - obs)^2, na.rm = TRUE)), f1$rmse_open, tolerance = 1e-10)))
year$s_open_c <- s_open[match(days, rec)]
# every day of the window has a value, and the filled days are the days the station lacks:
# the gap, and the runs of a day or two the rule allows beside it
in_gap <- days >= pick$gap_start & days <= pick$gap_end
in_win <- days >= as.Date(paste0(y, "-", window[1])) & days <= as.Date(paste0(y, "-", window[2]))
stopifnot(!anyNA(year$t_mean_c[in_win]), all(year$filled[in_gap]),
          identical(year$filled[in_win], !days[in_win] %in% ws$date))

season <- seasons_of(s, y)
gsdd_filled <- value_of(fill_gsdd, s, y)
# the seasons' degree days are wet_temp_gsdd()'s value, and the sum of the daily means over them
stopifnot(nrow(season) >= 1, isTRUE(all.equal(sum(season$gsdd), gsdd_filled, tolerance = 1e-10)))
acc <- vapply(seq_len(nrow(season)), function(i) {
  sum(year$t_mean_c[year$date >= season$start[i] & year$date <= season$end[i]])
}, 0)
stopifnot(isTRUE(all.equal(acc, season$gsdd, tolerance = 1e-10)))

# ---- the stations of the basin ----------------------------------------------------------------
i <- match(basin_st, st$station_number)
j <- match(basin_st, snap$station_number)
stations <- data.frame(
  station_number = basin_st, station_name = st$station_name[i], lon = st$lon[i], lat = st$lat[i],
  drainage_area_gross_km2 = st$drainage_area_gross_km2[i],
  linear_feature_id = as.numeric(snap$linear_feature_id[j]), wscode = snap$wscode[j],
  first = do.call(c, lapply(basin_st, function(b) min(water$date[water$station_number == b]))),
  last = do.call(c, lapply(basin_st, function(b) max(water$date[water$station_number == b]))),
  days = vapply(basin_st, function(b) sum(water$station_number == b), 0L, USE.NAMES = FALSE),
  fitted = basin_st %in% fit$station_number)
stopifnot(!anyNA(stations$linear_feature_id), all(stations$linear_feature_id < 2^53))

# ---- the fill's held-out error, from its tracked report ----------------------------------------
f_val <- file.path("data", "checks", "temp_fill_validate.txt")
val <- readLines(f_val)
row_of <- function(shape, method) {
  x <- val[grepl(sprintf("^ *%s +%s +[0-9]+ ", shape, method), val)]
  if (length(x) != 1) stop(f_val, ": no single row for ", shape, " ", method)
  x <- strsplit(trimws(x), " +")[[1]]
  list(n = as.integer(x[3]), rmse_mean = as.numeric(x[4]), gsdd_mae = as.numeric(x[7]))
}
truth <- regmatches(val, regexec("truth station-years ([0-9]+) at ([0-9]+) stations", val))
truth <- Filter(length, truth)
stopifnot(length(truth) == 1)
validation <- list(report = f_val, truth_station_years = as.integer(truth[[1]][2]),
                   truth_stations = as.integer(truth[[1]][3]),
                   season_open = row_of("season", "open"), season_full = row_of("season", "full"),
                   gap30_open = row_of("gap30", "open"), gap30_full = row_of("gap30", "full"))

# ---- write ------------------------------------------------------------------------------------
values <- list(
  basin = basin, stations = stations, pool = list(prefix = basin$pool, stations = length(pool_st)),
  candidates = cand, pick = pick, year = year, season = season,
  gsdd = list(filled = gsdd_filled, unfilled = value_of(obs_gsdd, s, y)),
  fit = as.list(f1), validation = validation,
  provenance = list(commit = commit, retrieved = format(retrieved), from = from, to = to, archive = root,
                    air = getOption("cd.daily_url", "https://stac-era5-land.s3.us-west-2.amazonaws.com/daily"),
                    hydat = format(as.Date(wet_hydat_release(hydat), "%Y%m%d")),
                    cd = as.character(utils::packageVersion("cd")),
                    gsdd = as.character(utils::packageVersion("gsdd")))
)
# a rerun that changes no value keeps the committed file: the commit and the versions it ran on aside
same <- function(a, b) {
  drop <- function(x) {
    x$provenance[c("commit", "cd", "gsdd")] <- NULL
    x
  }
  identical(drop(a), drop(b))
}
if (file.exists(out) && same(values, readRDS(out))) {
  message(basename(out), ": unchanged, left as it is")
} else {
  saveRDS(values, out, compress = "xz")
  message(basename(out), ": wrote ", out, " (", round(file.size(out) / 1024), " KB)")
}
