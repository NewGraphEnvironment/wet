# Data for vignettes/short-record-flow.Rmd (#130), which runs on this file and
# never touches HYDAT, fwapg, S3 or the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/short_record_vignette_data.R
#
# Maxan is a row of scripts/departure_sites.csv (#146): the target, its snow
# gauges and its windows (BULK) come from site_get("maxan"). Reads the series
# the site run and its snow regression save after their reports (both
# gitignored):
#   - data/departure/departure_site_maxan_bulk_20260717.rds (scripts/departure_site.R)
#   - data/departure/departure_site_snow_maxan_bulk_20260717.rds (scripts/departure_site_snow.R)
# and refuses unless each one's code_md5 is the md5 of its script as committed
# here, its site row is today's, and R/, scripts/, data-raw/ and data/checks/
# hold nothing uncommitted
# (vd_commit()), so the commit the bundle names rebuilds it. Every number the
# article can quote is held to its line in the tracked report it came from,
# data/checks/departure_site_maxan_bulk_20260717.txt or
# departure_site_snow_maxan_bulk_20260717.txt, at the precision the report
# prints; the held-out scores, which the series files do not carry, are read
# from those lines. Those two reports reproduce #120's and #121's
# (tests/testthat/test-departure_site_parity.R), which these values came from
# until #146 retired the pilot scripts.
#
# Writes inst/vignette-data/short_record_values.rds, a list:
#   - extended: Maxan's (08EE018) migration- and spawning-window mean flow,
#     1931-2024: value and 90 % interval (m3/s), observed or extended, and the
#     donor of each extended year
#   - carried: the donor-carried log departure per window and year
#   - change: the window mean and 7-day minimum in both windows, 2011-2025
#     against the years before 1981: years in each period, the log change,
#     its % of normal and 90 % interval, and the carried change
#   - scores: the held-out scores of each window statistic, for both routes:
#     the extension's median and interval coverage over the extension pool, the
#     carried departures' median over the departure pool, and Maxan's own five
#     years (the carried departures against the observed ones)
#   - snow: each watershed's peak snow water equivalent (mm) and 50 % melt
#     date (day of year), 1950-2025, for 08EE003, 08EE013 and 08EE018
#   - departures: the window-mean log departures the snow fits used, per
#     gauge, window and year, 1950-2025 (observed at 08EE003 and 08EE013,
#     extended and carried at 08EE018)
#   - snow_change: each watershed's mean snow and melt date, 1950-1980 and
#     2011-2025
#   - fits: the one-predictor snow fits (slope, 90 % interval, R2, n)
#   - gauges: every gauge the article names, from HYDAT STATIONS, with its role
#   - site: the site row's site_id, name, wsg_code, target_station,
#     blue_line_key and snow_gauges, which the map script and the article key on
#   - provenance: wet commit, build date, HYDAT release, cd's layer SHA, the
#     two scripts' md5s and the two reports' md5s

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_commit()
source("scripts/departure_site_lib.R")  # site_get()

wet_commit <- vd_commit()
release <- wb_release()
if (release != "20260717") stop("the article's data are HYDAT 20260717's, not ", release, call. = FALSE)
hydat <- wb_hydat(release)
out <- file.path("inst", "vignette-data", "short_record_values.rds")
site <- site_get("maxan")
wname <- site$windows[1]   # BULK, the windows the article cites

# ---- the two series files, each held to the script that made it ------------------------------
read_series <- function(script) {
  f <- file.path("data", "departure", sprintf("%s_%s_%s_%s.rds", script, site$site_id, tolower(wname), release))
  if (!file.exists(f)) stop("no ", f, ": run scripts/", script, ".R ", site$site_id, " first", call. = FALSE)
  x <- readRDS(f)
  md5 <- unname(tools::md5sum(file.path("scripts", paste0(script, ".R"))))
  # the site row is read from scripts/departure_sites.csv, which no md5 covers, so the run's own copy
  # of it must be today's
  if (!identical(x$code_md5, md5) || !identical(x$release, release) || !identical(x$site, site)) {
    stop(f, " was made by another scripts/", script, ".R, release or site row: rerun it", call. = FALSE)
  }
  x
}
srun <- read_series("departure_site")
snow_rds <- read_series("departure_site_snow")
report_of <- function(script) {
  file.path("data", "checks", sprintf("%s_%s_%s_%s.txt", script, site$site_id, tolower(wname), release))
}
flow_report <- report_of("departure_site")
snow_report <- report_of("departure_site_snow")
pr <- readLines(flow_report)
sr <- readLines(snow_report)

# one line of a report, by an anchored pattern, or stop
one_line <- function(x, pattern, what) {
  i <- grep(pattern, x, perl = TRUE)
  if (length(i) != 1) stop(what, ": ", length(i), " lines match ", pattern, call. = FALSE)
  x[i]
}
# the numbers in a line, in order (a range written a..b gives both)
nums <- function(line) as.numeric(regmatches(line, gregexpr("-?[0-9]+(\\.[0-9]+)?", line))[[1]])
# held to a printed value: within half a unit of its last printed digit
near <- function(x, printed, digits, what) {
  if (length(x) != length(printed) || any(abs(x - printed) > 0.5 * 10^-digits + 1e-9)) {
    stop(what, ": ", paste(signif(x, 6), collapse = " "), " is not the report's ",
         paste(printed, collapse = " "), call. = FALSE)
  }
}

maxan <- site$target_station
windows <- c("migration", "spawning")
stopifnot(identical(srun$windows$window, windows), identical(snow_rds$windows$window, windows))

# ---- Maxan's extended series ---------------------------------------------------------------------
extended <- do.call(rbind, lapply(windows, function(w) {
  e <- srun$mx[[paste("q_mean", w)]]$e
  stopifnot(all(e$station_number == maxan), all(e$source %in% c("observed", "extended")))
  data.frame(window = w, year = e$year, value = e$value, lower = e$lower, upper = e$upper,
             source = e$source, donor = ifelse(e$source == "observed", NA_character_, e$donor))
}))
# each year against the report's per-year table (m3/s, two decimals)
for (w in windows) {
  head_i <- grep(sprintf("^%s per year, %s mean \\(m3/s\\)", maxan, w), pr)
  stopifnot(length(head_i) == 1)
  ex <- extended[extended$window == w, ]
  rows <- pr[head_i + 2 + seq_len(nrow(ex))]
  for (k in seq_len(nrow(ex))) {
    v <- nums(rows[k])
    stopifnot(v[1] == ex$year[k])
    near(c(ex$value[k], ex$lower[k], ex$upper[k]), v[2:4], 2, sprintf("%s mean %d", w, ex$year[k]))
  }
}

# ---- the donor-carried departures --------------------------------------------------------------
carried <- do.call(rbind, lapply(windows, function(w) {
  a <- srun$mx[[paste("q_mean", w)]]$a
  stopifnot(all(a$station_number == maxan))
  data.frame(window = w, year = a$year, dep = a$anomaly, donors = a$donors)
}))
carried <- carried[!is.na(carried$dep), ]
# each carried year against the per-year table's last column (% of normal, one decimal)
for (w in windows) {
  head_i <- grep(sprintf("^%s per year, %s mean \\(m3/s\\)", maxan, w), pr)
  rows <- pr[head_i + 2 + seq_len(sum(extended$window == w))]
  yr <- as.integer(sub("^\\s*(\\d+).*", "\\1", rows))
  last <- sub(".*\\s(\\S+)$", "\\1", rows)
  cw <- carried[carried$window == w, ]
  stopifnot(setequal(yr[last != "-"], cw$year))
  near(100 * (exp(cw$dep) - 1), as.numeric(last[match(cw$year, yr)]), 1, paste("carried", w))
}
donor_ids <- function(s) sub(":.*", "", unlist(strsplit(s, " ")))
carried_donors <- sort(unique(donor_ids(carried$donors)))

# ---- the before/after changes ------------------------------------------------------------------
# section 4's table (section 5's has rows of the same shape); each row prints the extension's change,
# its % normal and interval, then the carried change, its % normal and interval, and the carried years
sec4 <- pr[seq(grep("^## 4\\. ", pr), grep("^## 5\\. ", pr))]
change <- do.call(rbind, lapply(c("mean", "min7"), function(v) do.call(rbind, lapply(windows, function(w) {
  m <- srun$mx[[paste(paste0("q_", v), w)]]
  pct <- 100 * (exp(c(m$diff, m$ci)) - 1)
  line <- one_line(sec4, sprintf("^  %s\\s+%s\\s+\\d+\\s+\\d+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+-?[0-9.]+\\.\\.", v, w),
                   paste("change", v, w))
  p <- nums(sub(sprintf("^  %s\\s+", v), "", line))   # the statistic's own digits (min7) dropped
  stopifnot(length(p) == 12, p[1] == m$n_pre, p[2] == m$n_post, p[11] == m$n_pre_c, p[12] == m$n_post_c)
  near(m$diff, p[3], 3, paste("change", v, w))
  near(pct, p[4:6], 1, paste("% normal", v, w))
  near(m$carried, p[7], 3, paste("carried", v, w))
  data.frame(statistic = v, window = w, n_pre = m$n_pre, n_post = m$n_post, change = m$diff,
             pct = pct[1], pct_lo = pct[2], pct_hi = pct[3], carried = m$carried,
             carried_pct = 100 * (exp(m$carried) - 1), n_pre_carried = m$n_pre_c, n_post_carried = m$n_post_c)
}))))

# ---- the held-out scores, from the report's own lines --------------------------------------------
# per window statistic: the extension's median and coverage (its sensitivity table), the carried
# departures' median over the departure pool (its by-setting table), and Maxan's own five years
# (the two-routes table: the carried departures against the observed, the pilot's obs_nse)
setting <- c("mean migration" = "migration mean", "mean spawning" = "spawning mean",
             "min7 migration" = "migration min7", "min7 spawning" = "spawning min7")
pool_line <- one_line(pr, "^Extension pool: \\d+ gauges", "extension pool")
head_line <- one_line(pr, "^HEADLINE: median per-gauge NSE ", "carried headline")
scores <- do.call(rbind, lapply(names(setting), function(k) {
  v <- sub(" .*", "", k)
  w <- sub(".* ", "", k)
  lab <- setting[[k]]
  first <- if (lab == "migration mean") "migration mean, k = 5" else lab
  ext <- one_line(pr, sprintf("^  %s\\s+21\\s+\\d+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+\\w+\\s+ols \\d+",
                              gsub(" ", "\\\\s", first)), paste("extension score", lab))
  e <- nums(sub(sprintf("^  %s", first), "", ext))
  stopifnot(length(e) == 9)   # gauges, blocks, three medians, then ols's coverage (move1's 1 is a name)
  car <- one_line(pr, sprintf("^  %s\\s+\\d+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+\\d+\\s+-?[0-9.]+$",
                              gsub(" ", "\\\\s", first)), paste("carried score", lab))
  cs <- nums(sub(sprintf("^  %s", first), "", car))
  two <- one_line(pr, sprintf("^  %s\\s+%s\\s+5\\s+-?[0-9.]+\\s+\\d+\\s+-?[0-9.]+\\s+[0-9.]+$", v, w),
                  paste("two routes", lab))
  t2 <- nums(sub(sprintf("^  %s\\s+%s", v, w), "", two))
  m <- srun$mx[[paste(paste0("q_", v), w)]]
  near(m$obs_nse, t2[2], 2, paste("Maxan carried", lab))
  stopifnot(t2[1] == m$obs_n)
  data.frame(statistic = v, window = w, extension_gauges = e[1], extension_median = e[3],
             extension_cover = e[6], carried_gauges = cs[1], carried_median = cs[3],
             maxan_years = t2[1], maxan_carried = t2[2])
}))
stopifnot(nums(pool_line)[1] == scores$extension_gauges[1],
          nums(head_line)[1] == scores$carried_median[scores$statistic == "mean" & scores$window == "migration"])

# ---- snow, departures and the snow fits ---------------------------------------------------------
gauges_snow <- names(snow_rds$snow)
stopifnot(identical(gauges_snow, c(site$snow_gauges, maxan)))
snow <- do.call(rbind, lapply(gauges_snow, function(g) {
  s <- snow_rds$snow[[g]]
  stopifnot(all(s$cover == 1))
  data.frame(gauge = g, year = s$year, swe_max = s$swe_max, melt_doy = s$snowmelt_doy_50)
}))
# the per-year table: whole mm and days
snow_head <- grep("^Snow per watershed", sr)
stopifnot(length(snow_head) == 1)
yrs <- sort(unique(snow$year))
for (k in seq_along(yrs)) {
  v <- nums(sr[snow_head + 2 + k])
  stopifnot(v[1] == yrs[k])
  for (j in seq_along(gauges_snow)) {
    s <- snow[snow$gauge == gauges_snow[j] & snow$year == yrs[k], ]
    near(c(s$swe_max, s$melt_doy), v[c(3 * j - 1, 3 * j)], 0, sprintf("snow %s %d", gauges_snow[j], yrs[k]))
  }
}

series_key <- vapply(snow_rds$series, function(s) paste(s$label, s$window), "")
departures <- do.call(rbind, lapply(snow_rds$series, function(s) {
  d <- s$d[!is.na(s$d$dep) & s$d$year >= min(snow$year), ]   # the snow years, which the report checks
  data.frame(gauge = s$gauge, series = sub("^\\S+ ", "", s$label), window = s$window, year = d$year, dep = d$dep)
}))
# against the report's per-year departures (three decimals), every series and year 1950-2025
dep_head <- grep("^Log departures per series", sr)
stopifnot(length(dep_head) == 1)
for (k in seq_along(yrs)) {
  row <- strsplit(trimws(sr[dep_head + 2 + k]), "\\s+")[[1]]
  stopifnot(as.integer(row[1]) == yrs[k])
  for (j in seq_along(snow_rds$series)) {
    s <- snow_rds$series[[j]]
    x <- s$d$dep[match(yrs[k], s$d$year)]
    if (row[j + 1] == "-") stopifnot(is.na(x)) else near(x, as.numeric(row[j + 1]), 3, paste(series_key[j], yrs[k]))
  }
}

# the before/after snow table: 1950-1980 and 2011-2025, the first table of its section (the
# 1951-1980 table after it, and the parity table below, have rows of the same shape)
sec3 <- sr[seq(grep("^## 3\\. ", sr), grep("^\\(swe_max in mm", sr)[1])]
snow_change <- do.call(rbind, lapply(gauges_snow, function(g) {
  s <- snow[snow$gauge == g, ]
  pre <- s$year %in% 1950:1980
  post <- s$year %in% 2011:2025
  stopifnot(sum(pre) == 31, sum(post) == 15)
  r <- data.frame(gauge = g, swe_pre = mean(s$swe_max[pre]), swe_post = mean(s$swe_max[post]),
                  doy_pre = mean(s$melt_doy[pre]), doy_post = mean(s$melt_doy[post]))
  near(c(r$swe_pre, r$swe_post, r$swe_post - r$swe_pre, r$doy_pre, r$doy_post, r$doy_post - r$doy_pre),
       nums(sub(g, "", one_line(sec3, sprintf("^  %s\\s+[0-9.]+\\s+[0-9.]+\\s+-?[0-9.]+\\s+[0-9.]+", g),
                                paste("snow change", g)))), 1, paste("snow change", g))
  r
}))

# the one-predictor fits, each against its report row (three decimals; R2 two)
fits <- do.call(rbind, lapply(seq_len(nrow(snow_rds$fits)), function(i) {
  f <- snow_rds$fits[i, ]
  if (f$model == "both") return(NULL)
  s <- snow_rds$series[[f$series]]
  slope <- if (f$model == "swe") c(f$bs, f$bs_lo, f$bs_hi) else c(f$bd, f$bd_lo, f$bd_hi)
  lab <- gsub(" ", "\\\\s+", paste(s$label, s$window))
  p <- nums(sub(sprintf("^  %s\\s+%s", lab, f$model), "",
                one_line(sr, sprintf("^  %s\\s+%s\\s+\\d+ ", lab, f$model), paste("fit", series_key[f$series], f$model))))
  stopifnot(p[1] == f$n)
  # the absent coefficient prints as "-", which is not a number, so the slope is p[5:7] in both models
  near(slope, p[5:7], 3, paste("slope", series_key[f$series], f$model))
  near(f$r2, p[9], 2, paste("R2", series_key[f$series], f$model))
  data.frame(gauge = s$gauge, series = sub("^\\S+ ", "", s$label), window = s$window, model = f$model,
             n = f$n, slope = slope[1], slope_lo = slope[2], slope_hi = slope[3], r2 = f$r2)
}))

# ---- the gauges the article names ----------------------------------------------------------------
ext_donors <- sort(unique(extended$donor[!is.na(extended$donor)]))
ids <- unique(c(maxan, gauges_snow, ext_donors, carried_donors))
con <- wet_hydat_connect(hydat)
st <- DBI::dbGetQuery(con, sprintf(
  "SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, DRAINAGE_AREA_GROSS AS area_km2
   FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", ids, "'", collapse = ", ")))
DBI::dbDisconnect(con)
stopifnot(setequal(st$station_number, ids))
gauges <- st[match(ids, st$station_number), ]
gauges$extension_donor <- gauges$station_number %in% ext_donors
gauges$carried_donor <- gauges$station_number %in% carried_donors
gauges$snow <- gauges$station_number %in% gauges_snow
rownames(gauges) <- NULL

# ---- provenance and write -----------------------------------------------------------------------
cd_line <- one_line(sr, "^  swe_max: https://", "cd swe_max layer")
cd_sha <- sub(".*CD_SHA ([0-9a-f]+).*", "\\1", cd_line)
stopifnot(grepl("^[0-9a-f]{40}$", cd_sha))
provenance <- list(
  wet_commit = wet_commit, built = Sys.Date(), hydat = as.character(as.Date(release, "%Y%m%d")), cd_sha = cd_sha,
  code_md5 = c(departure_site = srun$code_md5, departure_site_snow = snow_rds$code_md5),
  report_md5 = stats::setNames(unname(tools::md5sum(c(flow_report, snow_report))), basename(c(flow_report, snow_report)))
)
values <- list(extended = extended, carried = carried, change = change, scores = scores, snow = snow,
               departures = departures, snow_change = snow_change, fits = fits, gauges = gauges,
               site = srun$site[c("site_id", "name", "wsg_code", "target_station", "blue_line_key", "snow_gauges")],
               provenance = provenance)
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
saveRDS(values, out, compress = "xz")
message("wrote ", out, " at ", wet_commit, ": ", nrow(extended), " extended years, ", nrow(fits), " fits, ",
        nrow(gauges), " gauges")
