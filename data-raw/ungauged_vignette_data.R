# Data for vignettes/ungauged-flow.Rmd (#130), which runs on this file and
# never touches HYDAT, fwapg, S3 or the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/ungauged_vignette_data.R
#
# Reads the series the Maxan pilot and the snow regression save after their
# reports (both gitignored):
#   - data/departure/departure_pilot_20260717.rds (scripts/departure_pilot.R, #120)
#   - data/departure/departure_snow_20260717.rds (scripts/departure_snow.R, #121)
# and refuses unless each one's code_md5 is the md5 of its script as committed
# here, and R/, scripts/, data-raw/ and data/checks/ hold nothing uncommitted
# (vd_commit()), so the commit the bundle names rebuilds it. Every number the
# article can quote is held to its line in the tracked report it came from,
# data/checks/departure_pilot_20260717.txt or departure_snow_20260717.txt, at
# the precision the report prints; the held-out scores, which the series
# files do not carry, are read from those lines.
#
# Writes inst/vignette-data/ungauged_values.rds, a list:
#   - extended: Maxan's (08EE018) migration- and spawning-window mean flow,
#     1931-2024: value and 90 % interval (m3/s), observed or extended, and the
#     donor of each extended year
#   - carried: the donor-carried log departure per window and year
#   - change: the window mean and 7-day minimum in both windows, 2011-2025
#     against the years before 1981: years in each period, the log change,
#     its % of normal and 90 % interval, and the carried change
#   - scores: the held-out scores the article quotes
#   - snow: each watershed's peak snow water equivalent (mm) and 50 % melt
#     date (day of year), 1950-2025, for 08EE003, 08EE013 and 08EE018
#   - departures: the window-mean log departures the snow fits used, per
#     gauge, window and year (observed at 08EE003 and 08EE013, extended and
#     carried at 08EE018)
#   - snow_change: each watershed's mean snow and melt date, 1950-1980 and
#     2011-2025
#   - fits: the one-predictor snow fits (slope, 90 % interval, R2, n)
#   - gauges: every gauge the article names, from HYDAT STATIONS, with its role
#   - provenance: wet commit, build date, HYDAT release, cd's layer SHA, the
#     two scripts' md5s and the two reports' md5s

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_commit()

wet_commit <- vd_commit()
release <- wb_release()
if (release != "20260717") stop("the article's data are HYDAT 20260717's, not ", release, call. = FALSE)
hydat <- wb_hydat(release)
out <- file.path("inst", "vignette-data", "ungauged_values.rds")

# ---- the two series files, each held to the script that made it ------------------------------
read_series <- function(script) {
  f <- file.path("data", "departure", sprintf("%s_%s.rds", script, release))
  if (!file.exists(f)) stop("no ", f, ": run scripts/", script, ".R first", call. = FALSE)
  x <- readRDS(f)
  md5 <- unname(tools::md5sum(file.path("scripts", paste0(script, ".R"))))
  if (!identical(x$code_md5, md5) || !identical(x$release, release)) {
    stop(f, " was made by another scripts/", script, ".R or release: rerun it", call. = FALSE)
  }
  x
}
pilot <- read_series("departure_pilot")
snow_rds <- read_series("departure_snow")
pilot_report <- file.path("data", "checks", sprintf("departure_pilot_%s.txt", release))
snow_report <- file.path("data", "checks", sprintf("departure_snow_%s.txt", release))
pr <- readLines(pilot_report)
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

maxan <- "08EE018"
windows <- c("migration", "spawning")

# ---- Maxan's extended series ---------------------------------------------------------------------
extended <- do.call(rbind, lapply(windows, function(w) {
  e <- pilot$mx[[paste("q_mean", w)]]$e
  stopifnot(all(e$station_number == maxan), all(e$source %in% c("observed", "extended")))
  data.frame(window = w, year = e$year, value = e$value, lower = e$lower, upper = e$upper,
             source = e$source, donor = ifelse(e$source == "observed", NA_character_, e$donor))
}))
# each year against the report's per-year table (m3/s, two decimals)
for (w in windows) {
  head_i <- grep(sprintf("^08EE018 per year, %s mean \\(m3/s\\)", w), pr)
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
  a <- pilot$mx[[paste("q_mean", w)]]$a
  stopifnot(all(a$station_number == maxan))
  data.frame(window = w, year = a$year, dep = a$anomaly, donors = a$donors)
}))
carried <- carried[!is.na(carried$dep), ]
donor_ids <- function(s) sub(":.*", "", unlist(strsplit(s, " ")))
carried_donors <- sort(unique(donor_ids(carried$donors)))

# ---- the before/after changes ------------------------------------------------------------------
change <- do.call(rbind, lapply(c("mean", "min7"), function(v) do.call(rbind, lapply(windows, function(w) {
  m <- pilot$mx[[paste(paste0("q_", v), w)]]
  pct <- 100 * (exp(c(m$diff, m$ci)) - 1)
  line <- one_line(pr, sprintf("^  %s\\s+%s\\s+\\d+\\s+\\d+\\s+-?[0-9.]+\\s+-?[0-9.]+\\s+-?[0-9.]+\\.\\.", v, w),
                   paste("change", v, w))
  p <- nums(sub(sprintf("^  %s\\s+", v), "", line))   # the statistic's own digits (min7) dropped
  stopifnot(p[1] == m$n_pre, p[2] == m$n_post, p[8] == m$n_pre_c, p[9] == m$n_post_c)
  near(m$diff, p[3], 3, paste("change", v, w))
  near(pct, p[4:6], 1, paste("% normal", v, w))
  near(m$carried, p[7], 3, paste("carried", v, w))
  data.frame(statistic = v, window = w, n_pre = m$n_pre, n_post = m$n_post, change = m$diff,
             pct = pct[1], pct_lo = pct[2], pct_hi = pct[3], carried = m$carried,
             carried_pct = 100 * (exp(m$carried) - 1), n_pre_carried = m$n_pre_c, n_post_carried = m$n_post_c)
}))))

# ---- the held-out scores, from the report's own lines --------------------------------------------
ext_line <- one_line(pr, "^The rule: the highest median is ols \\(", "extension median")
ext_median <- nums(sub("^.*?is ols", "", ext_line))[1]
cover_line <- one_line(pr, "^Coverage of the nominal 90 % interval on held-out years: ols ", "coverage")
ext_cover <- nums(sub("^.*?: ols ", "", cover_line))[1]
pool_line <- one_line(pr, "^Extension pool: \\d+ gauges", "extension pool")
ext_gauges <- nums(pool_line)[1]
head_line <- one_line(pr, "^HEADLINE: median per-gauge NSE ", "carried headline")
h <- nums(head_line)
carry_median <- h[1]
carry_gauges <- h[4]
maxan_row <- regmatches(pr, regexpr("08EE018\\s+\\d+\\s+-?[0-9.]+", pr))
stopifnot(length(maxan_row) == 1)
mr <- nums(sub("08EE018", "", maxan_row))
scores <- list(extension_median = ext_median, extension_gauges = ext_gauges, extension_cover = ext_cover,
               carried_median = carry_median, carried_gauges = carry_gauges,
               maxan_years = mr[1], maxan_carried = mr[2])
stopifnot(scores$maxan_years == pilot$mx[["q_mean migration"]]$obs_n)

# ---- snow, departures and the snow fits ---------------------------------------------------------
gauges_snow <- names(snow_rds$snow)
stopifnot(identical(gauges_snow, c("08EE003", "08EE013", maxan)))
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
  d <- s$d[!is.na(s$d$dep), ]
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

# the before/after snow table: 1950-1980 and 2011-2025, read from its own section (the parity
# table below it has rows of the same shape)
sec3 <- sr[seq(grep("^## 3\\. ", sr), grep("^## 4\\. ", sr))]
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
  code_md5 = c(departure_pilot = pilot$code_md5, departure_snow = snow_rds$code_md5),
  report_md5 = stats::setNames(unname(tools::md5sum(c(pilot_report, snow_report))), basename(c(pilot_report, snow_report)))
)
values <- list(extended = extended, carried = carried, change = change, scores = scores, snow = snow,
               departures = departures, snow_change = snow_change, fits = fits, gauges = gauges,
               provenance = provenance)
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
saveRDS(values, out, compress = "xz")
message("wrote ", out, " at ", wet_commit, ": ", nrow(extended), " extended years, ", nrow(fits), " fits, ",
        nrow(gauges), " gauges")
