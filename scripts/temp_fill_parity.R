# GSDD at the 17 Skeena stations, 2015-2024: wet_temp_fill() against the
# weekly network model in hill_etal2025Spatialstream (#40).
#
#   Rscript scripts/temp_fill_parity.R
#
# Theirs: Tables 7 (mean GSDD by year, over the 17 sites) and 8 (mean GSDD by
# site, over 2015-2024) of the rendered memo,
# https://www.poissonconsulting.ca/analyses/skeena-stream-temp-25/ (read
# 2026-10-07). Their rule, from skeena-stream-temp-25 predict-air2stream-gsdd.R
# (NGE fork, c128f14): each day takes its week's predicted mean (week =
# day %/% 7 + 1, counted continuously), and gsdd::gsdd_vctr(complete = TRUE)
# runs on each site's calendar year.
#
# Steps, each changing one thing, so a difference can be attributed:
#   A  ours, daily, gsdd::gsdd() over 1 Mar - 30 Nov (wet_temp_gsdd())
#   B  ours, daily, their rule (gsdd_vctr(complete = TRUE) on the calendar year)
#   C  ours held at each week's mean, their rule
#   D  theirs
# A -> B is the GSDD rule, B -> C the weekly step, C -> D the model (a weekly
# Stan network with an open-loop fill, against a daily per-station fill that
# uses observations); C -> D also carries their air (ERA5-Land hourly to
# weekly), their observation set (realtime_raw_20250521) and archive
# revisions since, which this script does not separate.
#
# Inputs: data/temp_fill/{water,air}_2002_2025.rds (from scripts/temp_fill_validate.R)
# Output: data/checks/temp_fill_skeena_parity.txt

pkgload::load_all(".", quiet = TRUE)
options(width = 160)
stopifnot(requireNamespace("gsdd", quietly = TRUE))
dir <- "data/temp_fill"
water <- readRDS(file.path(dir, "water_2002_2025.rds"))
air <- readRDS(file.path(dir, "air_2002_2025.rds"))

theirs_site <- data.frame(
  station_number = c("08EE020", "08EE012", "08EB005", "08EF005", "08EB003", "08EB007", "08ED001",
                     "08EE013", "08EG019", "08EB004", "08ED002", "08EE005", "08EE003", "08EC001",
                     "08EE004", "08EC013", "08EC004"),
  gsdd = c(1029, 1365, 1653, 1743, 1869, 1910, 1937, 2030, 2056, 2062, 2139, 2309, 2312, 2330, 2364,
           2449, 2639),
  lower = c(964, 1310, 1605, 1683, 1817, 1841, 1884, 1983, 1992, 2011, 2079, 2251, 2265, 2272, 2313,
            2401, 2588),
  upper = c(1098, 1418, 1706, 1804, 1921, 1978, 1987, 2077, 2119, 2113, 2200, 2367, 2359, 2385, 2416,
            2499, 2688))
theirs_year <- data.frame(
  year = 2015:2024,
  gsdd = c(2031, 2120, 1906, 2044, 2042, 1815, 1925, 1984, 2233, 2006),
  lower = c(1944, 2034, 1829, 1958, 1962, 1741, 1847, 1910, 2157, 1922),
  upper = c(2117, 2211, 1992, 2125, 2137, 1896, 2016, 2060, 2315, 2093))
st <- theirs_site$station_number
years <- 2015:2024

w <- water[water$station_number %in% st, ]
missing <- setdiff(st, intersect(st, intersect(w$station_number, air$id)))
if (length(missing)) stop("no water or air temperature for: ", paste(missing, collapse = ", "))
f <- wet_temp_fill(w, air, from = "2015-01-01", to = "2024-12-31")
f <- f[f$date >= as.Date("2015-01-01") & f$date <= as.Date("2024-12-31"), ]

# A
a <- wet_temp_gsdd(f)
a <- a[a$year %in% years, c("station_number", "year", "value", "frac_filled")]
names(a)[3] <- "A"

# B and C: their rule on each calendar year
week <- as.integer(f$date - as.Date("2015-01-01")) %/% 7 + 1
f$weekly <- stats::ave(f$t_mean_c, f$station_number, week)
their_rule <- function(v) gsdd::gsdd_vctr(v, complete = TRUE, msgs = FALSE)
bc <- do.call(rbind, lapply(split(f, list(f$station_number, format(f$date, "%Y")), drop = TRUE),
                            function(d) {
  d <- d[order(d$date), ]
  data.frame(station_number = d$station_number[1], year = as.integer(format(d$date[1], "%Y")),
             n = nrow(d), B = their_rule(d$t_mean_c), C = their_rule(d$weekly))
}))
r <- merge(a, bc, by = c("station_number", "year"), all = TRUE)
# a calendar year with a day missing has no value under their rule
days <- ifelse(r$year %% 4 == 0, 366L, 365L)
r$B[is.na(r$n) | r$n < days] <- NA
r$C[is.na(r$n) | r$n < days] <- NA

site <- do.call(rbind, lapply(split(r, r$station_number), function(d) {
  data.frame(station_number = d$station_number[1], years = sum(!is.na(d$C)),
             frac_filled = mean(d$frac_filled, na.rm = TRUE), A = mean(d$A, na.rm = TRUE),
             B = mean(d$B, na.rm = TRUE), C = mean(d$C, na.rm = TRUE))
}))
site <- merge(site, theirs_site[c("station_number", "gsdd", "lower", "upper")], by = "station_number")
names(site)[names(site) == "gsdd"] <- "D"
site$C_minus_D <- site$C - site$D
site$in_their_pi <- site$C >= site$lower & site$C <= site$upper
site <- site[order(site$D), ]

yr <- do.call(rbind, lapply(split(r, r$year), function(d) {
  data.frame(year = d$year[1], sites = sum(!is.na(d$C)),
             frac_filled = round(mean(d$frac_filled, na.rm = TRUE), 3), A = mean(d$A, na.rm = TRUE),
             B = mean(d$B, na.rm = TRUE), C = mean(d$C, na.rm = TRUE))
}))
yr <- merge(yr, theirs_year, by = "year")
names(yr)[names(yr) == "gsdd"] <- "D"
yr$C_minus_D <- yr$C - yr$D

fmt <- function(d) utils::capture.output(print(d, row.names = FALSE, digits = 4))
steps <- c(A_to_B = mean(site$B - site$A), B_to_C = mean(site$C - site$B), C_to_D = mean(site$D - site$C))
lines <- c(sprintf("GSDD parity with hill_etal2025Spatialstream, 17 Skeena stations, 2015-2024 (#40), %s",
                   format(Sys.time(), "%Y-%m-%d")),
           sprintf("wet %s, gsdd %s", utils::packageVersion("wet"), utils::packageVersion("gsdd")),
           sprintf("filled days in the 1 Mar - 30 Nov windows: %.1f %% (mean over station-years)",
                   100 * mean(r$frac_filled, na.rm = TRUE)),
           "", "## By site, mean over years (degC-days). D = theirs (Table 8), with its 95 % PI",
           fmt(transform(site, frac_filled = round(frac_filled, 3))), "",
           "## By year, mean over sites. D = theirs (Table 7)", fmt(yr), "",
           "## Mean step over sites (degC-days): the GSDD rule, the weekly step, the model",
           fmt(as.data.frame(t(round(steps, 1)))), "",
           sprintf("Sites whose C lies in their 95 %% PI: %d of %d", sum(site$in_their_pi), nrow(site)),
           sprintf("Correlation of site means, C vs D: %.3f; mean |C - D| %.0f",
                   stats::cor(site$C, site$D), mean(abs(site$C_minus_D))))
fs::dir_create("data/checks")
writeLines(lines, "data/checks/temp_fill_skeena_parity.txt")
cat(lines, sep = "\n")
