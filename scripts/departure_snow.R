# Snow and the window flows at the Maxan pilot (#121, component 2 of #118):
# regress the Chinook migration- and spawning-window flows at 08EE003 (Bulkley
# near Houston), 08EE013 (Buck Creek) and 08EE018 (Maxan Creek, extended and
# carried by the #120 pilot) on each year's ERA5-Land peak snow water
# equivalent and 50 % melt date over the gauge's own watershed. The
# specification below was fixed in this header, and committed alone, before
# any body code was written (planning/archive, issue 121). Nothing is chosen:
# every fit is reported, nothing ships, nothing is published and no fit is
# read or touched.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_snow.R
#
# Inputs:
#   - data/departure/departure_pilot_20260717.rds (gitignored), written by
#     scripts/departure_pilot.R after its report: Maxan's extended and carried
#     series per statistic and window (`mx`), the pilot gauges' window
#     statistics before the pilot's value > 0 filter, `release`, `ship` (the
#     question-1 candidate the pilot's rule shipped), `k_main`, `baseline`,
#     `level`, and `code_md5` (tools::md5sum of scripts/departure_pilot.R).
#   - HYDAT 20260717 (scripts/wb_fit_lib.R's wb_hydat(), wet's per-user
#     cache), for the gauges' coordinates and drainage areas and the window
#     statistics guard.
#   - fwapg through the WET_PG* env vars, as every other wet script
#     (WET_PGHOST, WET_PGPORT, WET_PGDATABASE, WET_PGUSER, WET_PGPASSWORD,
#     defaulting to localhost:5432 fwapg postgres). The pilot alone reads
#     libpq's bare PG* for its leak-free sensitivity; this script does not.
#   - cd's annual ERA5-Land snow layers (cd::cd_catalog(), period "annual",
#     fetched once with cd::cd_cache_fetch()); the report gives each file's
#     CD_RUN_TIME and CD_SHA tags.
#   - The shipped snow normals data/snow/snow_19812010_*.tif (gitignored,
#     local), for the parity line only.
# Output: the tracked report data/checks/departure_snow_20260717.txt and
# nothing else. It carries no timestamp, so a rerun reproduces it byte for
# byte.
#
# ---- the watersheds ----------------------------------------------------------------------------
#
# Each gauge is snapped with wet_station_snap() from its STATIONS lon, lat and
# gross drainage area; the snap must be accepted and land on the fundamental
# watershed found at the plan (08EE003 7653689, 08EE013 7619666, 08EE018
# 9939958). Its watershed is every fundamental watershed upstream of it:
# fwa_watersheds_poly b joined to the gauge's polygon a on
# FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree,
# b.localcode_ltree) with b.wscode_ltree <@ a.wscode_ltree
# (scripts/upstream_area_check.R), the gauge's own polygon included. Houston
# contains Buck and Maxan; each watershed is sampled on its own.
#
# ---- the predictors ----------------------------------------------------------------------------
#
# wet_snow_annual() over each watershed's polygons (dissolved, then sampled
# once with wet_ws_sample(method = "area")), every year 1950-2025, for
# swe_max (mm, capped per cell and year at 3,000 mm), snowmelt_doy_50 (day of
# year) and snowmelt_rate_peak (mm/wk). In the models swe_max enters per
# 100 mm and snowmelt_doy_50 per 10 days, each centred on the watershed's own
# 1981-2010 mean, so a fit's intercept is the departure in a year of normal
# snow; snowmelt_rate_peak is reported per year and is in no model. The report refuses a year whose cover is below 1
# at any gauge (none was found at the plan: no band has an NA cell over the
# pilot box).
#
# ---- the responses (8 series) ------------------------------------------------------------------
#
# The window mean only (wet_window_stats()'s q_mean), in the migration
# (05-01..08-01) and spawning (08-01..09-15) windows, as the pilot defines
# them. Each response is a log departure, so log flow and its departure share
# every slope.
#
#   (i)   08EE003 and 08EE013 observed: log(value / m), m the arithmetic mean
#         of the gauge's complete window-years in 1981-2010 (at least 10;
#         08EE003 has 18 migration years, 1981-1998, and 08EE013 30), from
#         the rds's window statistics (HYDAT 20260717 approved days, a complete window-year as
#         the pilot defines it). A window-year whose mean is <= 0 is dropped
#         and counted.
#   (ii)  08EE018 extended, under the pilot's shipped route (`ship`, read
#         from the rds and reported, not assumed): `mx[["q_mean <window>"]]$e$dep`,
#         the departure from the extended series' own 1981-2010 mean. Every
#         one of those years is extended, Maxan's observed years being
#         1975-1979. The donor of each extended year is listed.
#   (iii) 08EE018 carried: `mx[["q_mean <window>"]]$a$anomaly`, the
#         donor-carried log departure (wet_departure_carry(), k = 5).
#
# ---- the models (24 fits) ----------------------------------------------------------------------
#
# Per series, three OLS fits (stats::lm()): departure ~ swe + doy,
# departure ~ swe, departure ~ doy, each over the same years: every year in
# 1950-2025 with a response and both predictors (no series reaches 2025;
# Maxan's extension ends 2024). Extended years before 1950 are excluded and
# counted. Reported per fit: each coefficient with its 90 % interval
# (confint(fit, level = 0.9), t), residual SE, R2, n, and the lag-1
# autocorrelation of the residuals over pairs of consecutive years both in the
# fit (08EE003 has no complete window 1999-2010, so its gap contributes no
# pair), with the number of pairs; per series, the correlation of the two
# predictors over the fit's years. No fit, predictor or series is chosen.
#
# Reported beside the fits, deciding nothing:
#   - per year, each watershed's swe_max, snowmelt_doy_50 and
#     snowmelt_rate_peak, and each series' departure (and Maxan's donor);
#   - each watershed's mean swe_max and snowmelt_doy_50 over 2011-2025 against
#     1950-1980, beside the pilot's before/after on the extended and carried
#     migration and spawning means (`mx[[...]]$diff`, `$carried`; the pilot's
#     "before" runs from 1931 where its series does).
#
# ---- the parity line ---------------------------------------------------------------------------
#
# Over each watershed, the 1981-2010 mean of wet_snow_annual()'s per-year
# swe_max and snowmelt_doy_50 against the shipped normals grid
# (data/snow/snow_19812010_*.tif, exactly one file, as scripts/wb_province.R
# finds it) sampled over the same dissolved watershed with
# wet_ws_sample(method = "area"). A per-cell mean commutes with an
# area-weighted mean over full-cover cells, and the cap never binds in the
# pilot box (largest swe_max 1,783 mm), so the difference is the normals'
# bilinear resampling onto the 30-arcsecond grid alone, provided the normals
# were built from the bands read here. That proviso is checked: the report
# says whether wet_snow_normals(<the shipped grid>, dir = tempdir(),
# catalog = <the files read here>) reproduces the shipped file's name, which
# is its cache key over the bands' values. With no file the report says
# "parity not run" and the rest proceeds; with more than one it stops.
#
# ---- what it refuses ---------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; no pilot rds; an rds whose `release`
# is not 20260717 or whose `code_md5` is not the current
# scripts/departure_pilot.R's (rerun the pilot); a snap not accepted or not on
# the fundamental watershed above; a year with cover below 1; the pilot
# gauges' window statistics in the rds differing from wet_window_stats()
# recomputed from HYDAT for them (all.equal(), the pilot's windows and
# statistics); counts other than these:
#   - 08EE018 extended migration mean: n = 75 (1950-2024, every year, the
#     tracked pilot report's per-year table);
#   - 08EE003 and 08EE013: n in each window equals the complete window-years
#     in the tracked pilot report's pool table (08EE003 44 migration and 44
#     spawning; 08EE013 51 and 50) less those years before 1950 and less any
#     dropped for a mean <= 0, both counted from the rds.


devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect(): fwapg from WET_PG*
source("scripts/departure_snow_lib.R")  # ds_gauges, ds_stations(), ds_snap(), ds_watershed()

release <- wb_release()
if (release != "20260717") stop("the specification names HYDAT 20260717, not ", release, call. = FALSE)
hydat <- wb_hydat(release)
report <- file.path("data", "checks", sprintf("departure_snow_%s.txt", release))
pilot_rds <- file.path("data", "departure", sprintf("departure_pilot_%s.rds", release))
years <- 1950:2025
baseline <- 1981:2010
level <- 0.9
vars <- c("swe_max", "snowmelt_doy_50", "snowmelt_rate_peak")
# complete window-years in the tracked pilot report's pool table (mig, spw)
pool_count <- c("08EE003 migration" = 44L, "08EE003 spawning" = 44L,
                "08EE013 migration" = 51L, "08EE013 spawning" = 50L)
maxan_n <- 75L

fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
out <- character()
say <- function(...) out <<- c(out, ...)

# ---- the pilot's series ------------------------------------------------------------------------
if (!file.exists(pilot_rds)) stop("no ", pilot_rds, ": run scripts/departure_pilot.R", call. = FALSE)
pr <- readRDS(pilot_rds)
if (!identical(pr$release, release)) stop(pilot_rds, " is for release ", pr$release, call. = FALSE)
if (!identical(pr$code_md5, unname(tools::md5sum("scripts/departure_pilot.R")))) {
  stop(pilot_rds, " was written by another scripts/departure_pilot.R: rerun the pilot", call. = FALSE)
}
stopifnot(identical(as.integer(pr$baseline), baseline), pr$k_main == 5, pr$level == level)

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$window, c("migration", "spawning")),
          identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))

# the rds's window statistics for the pilot gauges, recomputed from HYDAT
key_order <- function(x) {
  x <- x[order(x$station_number, x$variable, x$period, x$year), ]
  rownames(x) <- NULL
  x
}
daily <- suppressWarnings(wet_station_daily(ds_gauges$station_number, hydat, to = NULL, sources = "hydat"))
ws_hydat <- wet_window_stats(daily, windows, stats = c("mean", "min7", "max", "cov_day"))
ws_hydat <- key_order(ws_hydat[names(pr$ws)])
ws_rds <- key_order(pr$ws)
ws_check <- all.equal(ws_rds, ws_hydat)
if (!isTRUE(ws_check)) stop("the pilot rds's window statistics differ from HYDAT's: ", ws_check[1], call. = FALSE)

# ---- the watersheds and their snow -------------------------------------------------------------
st <- ds_stations(hydat)
conn <- vd_connect()
sn <- ds_snap(conn, st)
polys <- lapply(stats::setNames(ds_gauges$watershed_feature_id, ds_gauges$station_number),
                function(id) ds_watershed(conn, id))
DBI::dbDisconnect(conn)

cat_cd <- cd::cd_catalog()
cat_cd <- as.data.frame(cat_cd[cat_cd$variable %in% vars & cat_cd$period %in% "annual", c("variable", "period", "href")])
cat_cd <- cat_cd[match(vars, cat_cd$variable), ]
stopifnot(identical(cat_cd$variable, vars), !anyNA(cat_cd$href))
cat_local <- data.frame(variable = vars, period = "annual", href = unname(vapply(cat_cd$href, cd::cd_cache_fetch, "")))
cd_tags <- lapply(cat_local$href, function(f) {
  tg <- terra::metags(terra::rast(f))
  stats::setNames(tg$value, tg$name)[c("CD_RUN_TIME", "CD_SHA", "CD_VERSION")]
})

snow <- lapply(polys, function(p) wet_snow_annual(p, vars, years = years, catalog = cat_local))
# the cap binds where a capped watershed mean differs from the uncapped one
cap_binds <- vapply(names(polys), function(id) {
  !identical(snow[[id]], wet_snow_annual(polys[[id]], vars, years = years, catalog = cat_local, cap = NULL))
}, TRUE)
low <- vapply(snow, function(s) min(s$cover), 0)
if (any(low < 1)) stop("cover below 1 at ", paste(names(low)[low < 1], collapse = ", "), call. = FALSE)
union_km2 <- vapply(polys, function(p) sum(terra::expanse(terra::aggregate(p[, 0]), transform = FALSE)) / 1e6, 0)

# ---- the responses -----------------------------------------------------------------------------
obs_series <- function(g, w) {
  x <- pr$ws[pr$ws$station_number == g & pr$ws$variable == "q_mean" & pr$ws$period == w & !is.na(pr$ws$value),
             c("year", "value")]
  n_rows <- nrow(x)
  le0 <- sum(x$value <= 0)
  x <- x[x$value > 0, ]
  b <- x$value[x$year %in% baseline]
  if (length(b) < 10) stop(g, " ", w, " has ", length(b), " baseline years, fewer than 10", call. = FALSE)
  list(d = data.frame(year = x$year, dep = log(x$value / mean(b)), donor = NA_character_),
       n_rows = n_rows, le0 = le0, n_base = length(b))
}
series <- list()
for (g in c("08EE003", "08EE013")) {
  for (w in windows$window) {
    o <- obs_series(g, w)
    if (o$n_rows != pool_count[[paste(g, w)]]) {
      stop(g, " ", w, ": ", o$n_rows, " complete years in the rds, the pilot report's pool table has ",
           pool_count[[paste(g, w)]], call. = FALSE)
    }
    series[[length(series) + 1]] <- list(label = sprintf("%s observed", g), gauge = g, window = w, d = o$d,
                                         le0 = o$le0, n_base = o$n_base, n_rows = o$n_rows)
  }
}
for (w in windows$window) {
  m <- pr$mx[[paste("q_mean", w)]]
  series[[length(series) + 1]] <- list(label = "08EE018 extended", gauge = "08EE018", window = w,
                                       d = data.frame(year = m$e$year, dep = m$e$dep, donor = m$e$donor), le0 = 0L)
  series[[length(series) + 1]] <- list(label = "08EE018 carried", gauge = "08EE018", window = w,
                                       d = data.frame(year = m$a$year, dep = m$a$anomaly, donor = NA_character_),
                                       le0 = 0L)
}

# ---- the fits ----------------------------------------------------------------------------------
models <- list(both = dep ~ swe + doy, swe = dep ~ swe, doy = dep ~ doy)
lag1 <- function(year, r) {
  o <- order(year)
  year <- year[o]
  r <- r[o]
  i <- which(diff(year) == 1)
  list(r = if (length(i) >= 3) stats::cor(r[i], r[i + 1]) else NA_real_, pairs = length(i))
}
fits <- list()
for (k in seq_along(series)) {
  s <- series[[k]]
  sw <- snow[[s$gauge]]
  base_swe <- mean(sw$swe_max[sw$year %in% baseline])
  base_doy <- mean(sw$snowmelt_doy_50[sw$year %in% baseline])
  d <- merge(s$d[!is.na(s$d$dep), ], data.frame(year = sw$year, swe = (sw$swe_max - base_swe) / 100,
                                              doy = (sw$snowmelt_doy_50 - base_doy) / 10), by = "year")
  d <- d[stats::complete.cases(d[c("dep", "swe", "doy")]), ]
  series[[k]]$pre1950 <- sum(s$d$year < min(years) & !is.na(s$d$dep))
  series[[k]]$n <- nrow(d)
  series[[k]]$r_pred <- stats::cor(d$swe, d$doy)
  series[[k]]$first <- min(d$year)
  series[[k]]$last <- max(d$year)
  for (mn in names(models)) {
    f <- stats::lm(models[[mn]], data = d)
    ci <- stats::confint(f, level = level)
    co <- stats::coef(f)
    l1 <- lag1(d$year, stats::residuals(f))
    term <- function(t) if (t %in% names(co)) c(co[[t]], ci[t, 1], ci[t, 2]) else c(NA, NA, NA)
    fits[[length(fits) + 1]] <- data.frame(series = k, model = mn, n = nrow(d),
                                           b0 = term("(Intercept)")[1], b0_lo = term("(Intercept)")[2],
                                           b0_hi = term("(Intercept)")[3],
                                           bs = term("swe")[1], bs_lo = term("swe")[2], bs_hi = term("swe")[3],
                                           bd = term("doy")[1], bd_lo = term("doy")[2], bd_hi = term("doy")[3],
                                           sigma = summary(f)$sigma, r2 = summary(f)$r.squared,
                                           lag1 = l1$r, pairs = l1$pairs)
  }
}
fits <- do.call(rbind, fits)

# the counts the header holds
for (s in series) {
  want <- if (s$label == "08EE018 extended" && s$window == "migration") {
    maxan_n
  } else if (grepl("observed", s$label)) {
    pool_count[[paste(s$gauge, s$window)]] - s$pre1950 - s$le0
  } else {
    NA_integer_
  }
  if (!is.na(want) && s$n != want) stop(s$label, " ", s$window, ": n = ", s$n, ", not ", want, call. = FALSE)
}

# ---- the parity line ---------------------------------------------------------------------------
normals <- list.files(file.path("data", "snow"), "^snow_19812010_.*\\.tif$", full.names = TRUE)
if (length(normals) > 1) stop("expected at most one data/snow/snow_19812010_*.tif, found ", length(normals), call. = FALSE)
parity <- NULL
if (length(normals) == 1) {
  g <- terra::rast(normals)
  # the shipped file's cache key over the bands read here, rebuilt in tempdir()
  rebuilt <- wet_snow_normals(normals, dir = tempdir(),
                              catalog = cat_local[cat_local$variable %in% c("snowmelt_doy_50", "swe_max"), ])
  same_bands <- identical(basename(rebuilt), basename(normals))
  parity <- do.call(rbind, lapply(names(polys), function(id) {
    u <- terra::aggregate(polys[[id]][, 0])
    u$watershed_feature_id <- 1L
    nm <- wet_ws_sample(g[[c("swe_max", "snowmelt_doy_50")]], u, method = "area")
    sw <- snow[[id]]
    data.frame(gauge = id, swe_annual = mean(sw$swe_max[sw$year %in% baseline]), swe_normals = nm$swe_max,
               doy_annual = mean(sw$snowmelt_doy_50[sw$year %in% baseline]), doy_normals = nm$snowmelt_doy_50,
               cover = nm$cover)
  }))
}

# ---- the report --------------------------------------------------------------------------------
lab <- function(s) sprintf("%s %s", s$label, s$window)
say("# Snow and the Chinook window flows at the Maxan pilot (#121)", "",
    sprintf("HYDAT %s. Specification registered in scripts/departure_snow.R's header at 81580b5, before any body code; nothing is chosen.", release),
    sprintf("Pilot series: %s (release %s, the pilot's shipped extension route: %s, k = %d).",
            pilot_rds, pr$release, pr$ship, pr$k_main),
    sprintf("Its window statistics for %s equal wet_window_stats() recomputed from HYDAT.",
            paste(ds_gauges$station_number, collapse = ", ")),
    "Snow: wet_snow_annual() over each gauge's upstream fundamental watersheds (dissolved), cd's annual ERA5-Land layers, swe_max capped per cell and year at 3,000 mm:",
    sprintf("  %s: %s (CD_RUN_TIME %s, CD_SHA %s, CD_VERSION %s)", vars, cat_cd$href,
            vapply(cd_tags, `[[`, "", "CD_RUN_TIME"), vapply(cd_tags, `[[`, "", "CD_SHA"),
            vapply(cd_tags, `[[`, "", "CD_VERSION")),
    "", "## 1. The watersheds", "",
    sprintf("  %-8s %-20s %10s %8s %10s %10s %6s", "gauge", "fwapg snap", "polygons", "km2", "HYDAT km2", "years", "cover"),
    sprintf("  %-8s %-20s %10d %8s %10s %10s %6s", ds_gauges$station_number,
            sprintf("%d %s", sn$watershed_feature_id, ifelse(sn$accepted, "accepted", "-")), ds_gauges$n_poly,
            fmt(union_km2, 1), fmt(st$drainage_area_gross_km2, 1),
            vapply(snow, function(s) sprintf("%d-%d", min(s$year), max(s$year)), ""),
            fmt(vapply(snow, function(s) min(s$cover), 0), 3)),
    "", "Houston (08EE003) contains Buck (08EE013) and Maxan (08EE018); each is sampled on its own.", "")

say("## 2. The fits", "",
    "Response: log departure of the window's mean flow (08EE003 and 08EE013 from their own 1981-2010 mean; 08EE018 extended from the extended series' 1981-2010 mean; 08EE018 carried as the pilot carries it).",
    "Predictors: swe_max per 100 mm and snowmelt_doy_50 per 10 days, each centred on the watershed's own 1981-2010 mean, so the intercept is the departure in a year of normal snow.",
    sprintf("OLS over every year %d-%d with a response and both predictors; %d %% intervals (t).", min(years), max(years),
            round(100 * level)), "",
    "Series:", "",
    sprintf("  %-26s %4s %9s %8s %9s %10s %8s", "series", "n", "years", "<1950", "dropped", "r(swe,doy)", "baseline"))
for (s in series) {
  say(sprintf("  %-26s %4d %9s %8d %9d %10s %8s", lab(s), s$n, sprintf("%d-%d", s$first, s$last), s$pre1950, s$le0,
              fmt(s$r_pred), if (is.null(s$n_base)) "-" else as.character(s$n_base)))
}
say("", "(<1950: years with a response before 1950, excluded. dropped: window-years with a mean <= 0. baseline: the observed gauges' complete 1981-2010 window-years.)",
    "", "Coefficients (log departure per 100 mm of swe_max, per 10 days of snowmelt_doy_50), 90 % intervals, residual SE, R2, and the lag-1 autocorrelation of the residuals over consecutive-year pairs:", "")
ci_txt <- function(b, lo, hi, d = 3) ifelse(is.na(b), "-", sprintf("%s [%s, %s]", fmt(b, d), fmt(lo, d), fmt(hi, d)))
say(sprintf("  %-26s %-5s %4s %26s %26s %26s %6s %5s %6s %5s", "series", "model", "n", "intercept", "swe_max /100 mm",
            "snowmelt_doy_50 /10 d", "res.SE", "R2", "lag1", "pairs"))
for (i in seq_len(nrow(fits))) {
  f <- fits[i, ]
  say(sprintf("  %-26s %-5s %4d %26s %26s %26s %6s %5s %6s %5d", lab(series[[f$series]]), f$model, f$n,
              ci_txt(f$b0, f$b0_lo, f$b0_hi), ci_txt(f$bs, f$bs_lo, f$bs_hi), ci_txt(f$bd, f$bd_lo, f$bd_hi),
              fmt(f$sigma, 3), fmt(f$r2), fmt(f$lag1), f$pairs))
}

say("", "## 3. Snow before and after, beside the pilot's flow change", "",
    "Each watershed's mean over 1950-1980 and 2011-2025:", "",
    sprintf("  %-8s %10s %10s %8s %10s %10s %8s", "gauge", "swe 50-80", "swe 11-25", "change", "doy 50-80", "doy 11-25",
            "change"))
for (id in names(snow)) {
  sw <- snow[[id]]
  a <- sw[sw$year %in% 1950:1980, ]
  b <- sw[sw$year %in% 2011:2025, ]
  say(sprintf("  %-8s %10s %10s %8s %10s %10s %8s", id, fmt(mean(a$swe_max), 1), fmt(mean(b$swe_max), 1),
              fmt(mean(b$swe_max) - mean(a$swe_max), 1), fmt(mean(a$snowmelt_doy_50), 1),
              fmt(mean(b$snowmelt_doy_50), 1), fmt(mean(b$snowmelt_doy_50) - mean(a$snowmelt_doy_50), 1)))
}
say("", "(swe_max in mm, snowmelt_doy_50 in days of the year.)", "",
    "The pilot's change at 08EE018, mean log departure 2011-2025 minus before 1981 (its series from 1931):", "",
    sprintf("  %-10s %9s %4s %4s %9s %4s %4s", "window", "extended", "pre", "post", "carried", "pre", "post"))
for (w in windows$window) {
  m <- pr$mx[[paste("q_mean", w)]]
  say(sprintf("  %-10s %9s %4d %4d %9s %4d %4d", w, fmt(m$diff, 3), m$n_pre, m$n_post, fmt(m$carried, 3), m$n_pre_c,
              m$n_post_c))
}

say("", "## 4. Parity with the shipped snow normals", "")
if (is.null(parity)) {
  say("parity not run: no data/snow/snow_19812010_*.tif on this machine.")
} else {
  say(sprintf("Normals: %s. Rebuilt from the bands read here in tempdir(), its cache key %s the shipped file's name, so the normals %s these bands.",
              normals, if (same_bands) "reproduces" else "does NOT reproduce", if (same_bands) "were built from" else "were not built from"),
      "The 1981-2010 mean of the per-year values over each dissolved watershed against the normals sampled over it (wet_ws_sample(), area):", "",
      sprintf("  %-8s %10s %10s %8s %10s %10s %8s %6s", "gauge", "swe annual", "normals", "diff", "doy annual", "normals",
              "diff", "cover"),
      sprintf("  %-8s %10s %10s %8s %10s %10s %8s %6s", parity$gauge, fmt(parity$swe_annual, 1), fmt(parity$swe_normals, 1),
              fmt(parity$swe_annual - parity$swe_normals, 2), fmt(parity$doy_annual, 1), fmt(parity$doy_normals, 1),
              fmt(parity$doy_annual - parity$doy_normals, 2), fmt(parity$cover, 3)),
      "", sprintf("The per-year values are ERA5-Land's 0.1-degree cells; the normals are their per-cell mean resampled bilinearly onto the 30-arcsecond grid. The 3,000 mm cap binds in %s.",
                  if (any(cap_binds)) paste(names(cap_binds)[cap_binds], collapse = ", ") else "none of the watersheds in any year"))
}

say("", "## 5. Per year", "", "Snow per watershed (swe_max mm, snowmelt_doy_50 day of year, snowmelt_rate_peak mm/wk):", "",
    sprintf("  %4s  %s", "year", paste(sprintf("%-8s %6s %5s %5s", names(snow), "swe", "doy", "rate"), collapse = "  ")))
for (y in years) {
  say(sprintf("  %4d  %s", y, paste(vapply(names(snow), function(id) {
    sw <- snow[[id]][snow[[id]]$year == y, ]
    sprintf("%-8s %6s %5s %5s", "", fmt(sw$swe_max, 0), fmt(sw$snowmelt_doy_50, 0), fmt(sw$snowmelt_rate_peak, 0))
  }, ""), collapse = "  ")))
}
short <- c("08EE003 observed" = "003", "08EE013 observed" = "013", "08EE018 extended" = "018ext",
           "08EE018 carried" = "018car")
say("", "Log departures per series (mig: migration, spw: spawning), and the donor of each of 08EE018's extended years:", "",
    sprintf("  %4s %s %-8s %-8s", "year",
            paste(vapply(series, function(s) sprintf("%11s", paste(short[[s$label]], c(migration = "mig",
                                                                                     spawning = "spw")[[s$window]])), ""),
                  collapse = ""), "donor mig", "donor spw"))
dep_of <- function(s, y) {
  i <- match(y, s$d$year)
  if (is.na(i)) NA_real_ else s$d$dep[i]
}
donor_of <- function(w, y) {
  e <- pr$mx[[paste("q_mean", w)]]$e
  i <- match(y, e$year)
  if (is.na(i)) "-" else if (is.na(e$donor[i])) "observed" else e$donor[i]
}
for (y in years) {
  say(sprintf("  %4d %s %-9s %-9s", y, paste(vapply(series, function(s) sprintf("%11s", fmt(dep_of(s, y), 3)), ""),
                                             collapse = ""), donor_of("migration", y), donor_of("spawning", y)))
}

writeLines(sub(" +$", "", out), report)
