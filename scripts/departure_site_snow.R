# Snow and the window flows at a Chinook pilot site (#126): #121's regression
# (the header of scripts/departure_snow.R, retired in #146), unchanged, run at
# each site of scripts/departure_sites.csv on the series scripts/departure_site.R saves.
# The specification was committed in this header alone, before any body code
# (planning/archive, issue 126). Every fit is reported. Nothing is chosen,
# nothing ships, nothing is published, and no fit is read or touched.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_site_snow.R <site_id>
#
# One run per window set the site names, each reading
# data/departure/departure_site_<site>_<group>_20260717.rds (refused unless
# its `code_md5` is the current scripts/departure_site.R's and its `release`
# is 20260717), writing the tracked report
# data/checks/departure_site_snow_<site>_<group>_20260717.txt (no timestamp)
# and, after it, the gitignored
# data/departure/departure_site_snow_<site>_<group>_20260717.rds (`snow`,
# `series`, `fits`, `release`, `site`, `code_md5`). fwapg through the WET_PG*
# variables, as #121's run; cd's annual ERA5-Land layers as
# there, with each file's CD_RUN_TIME, CD_SHA and CD_VERSION reported.
#
# ---- what is #121's, unchanged ------------------------------------------------------------------
#
# The predictors (wet_snow_annual() over each watershed's dissolved polygons,
# 1950-2025: swe_max capped at 3,000 mm per cell and year, per 100 mm;
# snowmelt_doy_50 per 10 days; both centred on the watershed's own 1981-2010
# mean; snowmelt_rate_peak reported, in no model). The responses (the window
# mean's log departure in each of the window set's two windows). The three
# OLS fits per series (swe + doy, swe, doy) over every year 1950-2025 with a
# response and both predictors, with 90 % t intervals, residual SE, R2, the
# lag-1 autocorrelation of residuals over consecutive-year pairs, and the
# predictors' correlation. Snow before and after (1950-1980 against
# 2011-2025), beside the site run's flow change. The parity line against the
# shipped normals grid. The per-year tables. A year whose cover is below 1 is
# refused.
#
# New in #152, deciding nothing: snow before and after over the comparison
# article's periods, 1951-1980 against 2016-2025 (each watershed's mean peak
# SWE and 50 % melt date), beside the site run's change over the same periods
# (its `p152`, both routes). #121's and #126's lines are unchanged.
#
# ---- what changes per site ----------------------------------------------------------------------
#
# The series:
#   - each snow gauge observed: log(value / m), m the arithmetic mean of its
#     complete 1981-2010 window-years (at least 10), from the site rds's
#     window statistics, a mean <= 0 dropped and counted;
#   - an extend site's target extended (`mx[["q_mean <window>"]]$e$dep`, the
#     site run's OLS route) and carried (`$a$anomaly`);
#   - an ungauged site's target carried alone.
#
# The snow gauges: the site's snow_gauges column where it names them (Maxan's:
# 08EE003 and 08EE013, #121's). Otherwise the first two gauges, nearest first,
# with at least 10 complete 1981-2010 window-years in both windows and an
# accepted snap (that last condition amended after the first Naver run, whose
# second gauge by the rule, 08KD001, has a snap wet_station_snap() does not
# accept; it decides which gauges are fitted, not what any fit says). For an
# extend site they are taken from the target's extension donor chain under the
# window set's migration mean (attr(e, "donors")); for an ungauged site, from
# its carried donors there.
#
# The watersheds: a gauge's, or an extend target's, is every fundamental
# watershed upstream of its snap (wet_station_snap(), which must be
# accepted), its own polygon included, as in scripts/departure_snow_lib.R's
# ds_watershed(). The polygon count and the snapped watershed_feature_id are
# reported, not asserted, except for Maxan's three, which keep #121's. An
# ungauged target's watershed is every fundamental watershed whose
# wscode_ltree descends from its blue line's, the area its normal used.
# Nesting (a target inside a snow gauge's watershed) is reported.
#
# ---- the parity gate ----------------------------------------------------------------------------
#
# The maxan row under the BULK windows must reproduce #121's run, whose
# tracked report data/checks/departure_snow_20260717.txt is its record since
# scripts/departure_snow.R was retired (#146): every table row of that report
# (the watersheds, the fits, snow and the flow change before and after, the
# parity with the normals, the per-year snow and departures) must appear
# verbatim in the site report, at the precision it prints
# (site_parity_snow() in scripts/departure_site_lib.R;
# tests/testthat/test-departure_site_parity.R holds the tracked site report to
# it), so a maxan run needs the normals grid the parity table reads, as #121's
# did. The run stops before writing anything otherwise. Until #146 the gate
# also compared the fits and series bit for bit with #121's saved series.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a site_id not in the table; no site
# rds, or one made by another scripts/departure_site.R; a snap not accepted;
# a snow gauge with fewer than 10 baseline years in either window; fewer than
# two snow gauges found; a year with cover below 1; the parity gate.


devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect(): fwapg from WET_PG*
source("scripts/departure_site_lib.R")  # site_get(), site_windows()
source("scripts/departure_snow_lib.R")  # ds_gauges: #121's watersheds, asserted for Maxan's three

release <- wb_release()
if (release != "20260717") stop("the specification names HYDAT 20260717, not ", release, call. = FALSE)
# the script this run executes (a frozen copy, say), hashed before anything else can change it
# (Rscript writes a space in the path as ~+~)
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, not through source(), so the script's own md5 can be recorded", call. = FALSE)
}
code_md5 <- unname(tools::md5sum(self))
if (is.na(code_md5)) stop("cannot read the running script at ", self, " to record its md5", call. = FALSE)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript scripts/departure_site_snow.R <site_id>", call. = FALSE)
site <- site_get(args)
wsets <- site_windows(site)
hydat <- wb_hydat(release)
years <- 1950:2025
baseline <- 1981:2010
level <- 0.9
vars <- c("swe_max", "snowmelt_doy_50", "snowmelt_rate_peak")
site_md5 <- unname(tools::md5sum("scripts/departure_site.R"))
fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))

# every fundamental watershed upstream of `wfid`, its own included (ds_watershed() without its
# count assertion, which only Maxan's three keep)
watershed_up <- function(conn, wfid) {
  sql <- sprintf("
    SELECT b.watershed_feature_id, ST_Force2D(b.geom) AS geom
    FROM whse_basemapping.fwa_watersheds_poly a
    JOIN whse_basemapping.fwa_watersheds_poly b
      ON whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree, b.localcode_ltree)
     AND b.wscode_ltree <@ a.wscode_ltree
    WHERE a.watershed_feature_id = %d
    ORDER BY b.watershed_feature_id", as.integer(wfid))
  x <- sf::st_read(conn, query = sql, quiet = TRUE)
  x$watershed_feature_id <- as.integer(x$watershed_feature_id)
  if (sf::st_crs(x)$epsg != 3005) stop("fwa_watersheds_poly is not in EPSG:3005", call. = FALSE)
  terra::vect(x)
}
# an ungauged target's basin: every fundamental watershed under its blue line's watershed code
watershed_code <- function(conn, blue_line_key) {
  code <- DBI::dbGetQuery(conn, sprintf("
    SELECT DISTINCT wscode_ltree::text wscode FROM whse_basemapping.fwa_stream_networks_sp
    WHERE blue_line_key = %d AND blue_line_key = watershed_key AND gnis_name IS NOT NULL", as.integer(blue_line_key)))
  if (nrow(code) != 1) stop("blue line ", blue_line_key, " has no single watershed code", call. = FALSE)
  x <- sf::st_read(conn, query = sprintf("
    SELECT watershed_feature_id, ST_Force2D(geom) AS geom FROM whse_basemapping.fwa_watersheds_poly
    WHERE wscode_ltree <@ '%s'::ltree ORDER BY watershed_feature_id", code$wscode), quiet = TRUE)
  x$watershed_feature_id <- as.integer(x$watershed_feature_id)
  terra::vect(x)
}

cat_cd <- cd::cd_catalog()
cat_cd <- as.data.frame(cat_cd[cat_cd$variable %in% vars & cat_cd$period %in% "annual", c("variable", "period", "href")])
cat_cd <- cat_cd[match(vars, cat_cd$variable), ]
stopifnot(identical(cat_cd$variable, vars), !anyNA(cat_cd$href))
cat_local <- data.frame(variable = vars, period = "annual", href = unname(vapply(cat_cd$href, cd::cd_cache_fetch, "")))
cd_tags <- lapply(cat_local$href, function(f) {
  tg <- terra::metags(terra::rast(f))
  stats::setNames(tg$value, tg$name)[c("CD_RUN_TIME", "CD_SHA", "CD_VERSION")]
})

for (wname in names(wsets)) {
out <- character()
say <- function(...) out <<- c(out, ...)
report <- file.path("data", "checks", sprintf("departure_site_snow_%s_%s_%s.txt", site$site_id, tolower(wname), release))
site_rds <- file.path("data", "departure", sprintf("departure_site_%s_%s_%s.rds", site$site_id, tolower(wname), release))

# ---- the site run's series ---------------------------------------------------------------------
if (!file.exists(site_rds)) stop("no ", site_rds, ": run scripts/departure_site.R ", site$site_id, call. = FALSE)
pr <- readRDS(site_rds)
if (!identical(pr$release, release)) stop(site_rds, " is for release ", pr$release, call. = FALSE)
if (!identical(pr$code_md5, site_md5)) {
  stop(site_rds, " was written by another scripts/departure_site.R: rerun it", call. = FALSE)
}
stopifnot(identical(as.integer(pr$baseline), baseline), pr$k_main == 5, pr$level == level)
windows <- pr$windows
target <- if (site$kind == "extend") site$target_station else site$site_id

# the snow gauges: the table's, or the rule's
n_base <- function(g, w) {
  sum(pr$ws$station_number == g & pr$ws$variable == "q_mean" & pr$ws$period == w & pr$ws$year %in% baseline &
        !is.na(pr$ws$value) & pr$ws$value > 0)
}
m_mig <- pr$mx[["q_mean migration"]]
if (length(site$snow_gauges)) {
  gauges <- site$snow_gauges
  gauge_rule <- "the site table's snow_gauges"
} else {
  cand <- if (site$kind == "extend") {
    attr(m_mig$e, "donors")[[1]]
  } else {
    full <- m_mig$a$donors[which.max(m_mig$a$n_donors)]
    sub(":.*", "", strsplit(full, " ")[[1]])
  }
  ok <- vapply(cand, function(g) n_base(g, "migration") >= 10 && n_base(g, "spawning") >= 10, TRUE)
  # an accepted snap, so the gauge has a watershed to sample
  con0 <- wet:::wet_hydat_connect(hydat)
  st0 <- DBI::dbGetQuery(con0, sprintf("
    SELECT STATION_NUMBER AS station_number, LONGITUDE AS lon, LATITUDE AS lat, DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", cand, "'", collapse = ", ")))
  DBI::dbDisconnect(con0)
  conn0 <- vd_connect()
  sn0 <- wet_station_snap(conn0, st0)
  DBI::dbDisconnect(conn0)
  snapped <- cand %in% sn0$station_number[sn0$accepted %in% TRUE]
  gauges <- utils::head(cand[ok & snapped], 2)
  gauge_rule <- sprintf("the first two of the target's %s (nearest first: %s) with >= 10 baseline years in both windows and an accepted snap",
                        if (site$kind == "extend") "extension donor chain" else "carried donors",
                        paste(cand, collapse = ", "))
}
if (length(gauges) < 2) stop("fewer than two snow gauges found", call. = FALSE)
for (g in gauges) for (w in windows$window) {
  if (n_base(g, w) < 10) stop(g, " has ", n_base(g, w), " baseline years in ", w, ", fewer than 10", call. = FALSE)
}

# ---- the watersheds and their snow -------------------------------------------------------------
con <- wet:::wet_hydat_connect(hydat)
snap_ids <- c(gauges, if (site$kind == "extend") target)
st <- DBI::dbGetQuery(con, sprintf("
  SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, LONGITUDE AS lon, LATITUDE AS lat,
         DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
  FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", snap_ids, "'", collapse = ", ")))
DBI::dbDisconnect(con)
st <- st[match(snap_ids, st$station_number), ]
conn <- vd_connect()
sn <- wet_station_snap(conn, st[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
sn <- sn[match(st$station_number, sn$station_number), ]
if (any(!(sn$accepted %in% TRUE))) stop("snap not accepted: ", paste(sn$station_number[!(sn$accepted %in% TRUE)], collapse = ", "), call. = FALSE)
known <- match(sn$station_number, ds_gauges$station_number)
bad <- !is.na(known) & sn$watershed_feature_id != ds_gauges$watershed_feature_id[known]
if (any(bad)) stop("snap off #121's fundamental watershed: ", paste(sn$station_number[bad], collapse = ", "), call. = FALSE)
polys <- lapply(stats::setNames(sn$watershed_feature_id, sn$station_number), function(id) watershed_up(conn, id))
for (g in names(polys)) {
  i <- match(g, ds_gauges$station_number)
  if (!is.na(i) && nrow(polys[[g]]) != ds_gauges$n_poly[i]) stop(g, " has ", nrow(polys[[g]]), " upstream polygons, not #121's ", ds_gauges$n_poly[i], call. = FALSE)
}
if (site$kind == "ungauged") polys[[target]] <- watershed_code(conn, site$blue_line_key)
# nesting: does a watershed hold another's outlet polygon?
nest <- character()
outlet <- c(stats::setNames(sn$watershed_feature_id, sn$station_number),
            if (site$kind == "ungauged") stats::setNames(NA_integer_, target))
for (a in names(polys)) for (b in setdiff(names(polys), a)) {
  inside <- if (is.na(outlet[[b]])) all(polys[[b]]$watershed_feature_id %in% polys[[a]]$watershed_feature_id) else
    outlet[[b]] %in% polys[[a]]$watershed_feature_id
  if (inside) nest <- c(nest, sprintf("%s contains %s", a, b))
}
DBI::dbDisconnect(conn)

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
for (g in gauges) {
  for (w in windows$window) {
    o <- obs_series(g, w)
    series[[length(series) + 1]] <- list(label = sprintf("%s observed", g), gauge = g, window = w, d = o$d,
                                         le0 = o$le0, n_base = o$n_base, n_rows = o$n_rows)
  }
}
for (w in windows$window) {
  m <- pr$mx[[paste("q_mean", w)]]
  if (site$kind == "extend") {
    series[[length(series) + 1]] <- list(label = sprintf("%s extended", target), gauge = target, window = w,
                                         d = data.frame(year = m$e$year, dep = m$e$dep, donor = m$e$donor), le0 = 0L)
  }
  series[[length(series) + 1]] <- list(label = sprintf("%s carried", target), gauge = target, window = w,
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

# ---- the parity line ---------------------------------------------------------------------------
normals <- list.files(file.path("data", "snow"), "^snow_19812010_.*\\.tif$", full.names = TRUE)
if (length(normals) > 1) stop("expected at most one data/snow/snow_19812010_*.tif, found ", length(normals), call. = FALSE)
parity <- NULL
if (length(normals) == 1) {
  g <- terra::rast(normals)
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
area_of <- function(id) {
  i <- match(id, st$station_number)
  if (is.na(i)) "-" else fmt(st$drainage_area_gross_km2[i], 1)
}
say(sprintf("# Snow and the Chinook window flows at %s (%s, %s windows, #126)", site$name, site$site_id, wname), "",
    sprintf("HYDAT %s. Specification: #121's, taken over per site in scripts/departure_site_snow.R's header, registered at efc23f1 before any body code; nothing is chosen.", release),
    sprintf("Site series: %s (release %s, extension %s, k = %d).", site_rds, pr$release, pr$ship, pr$k_main),
    sprintf("Windows: %s.", paste(sprintf("%s %s..%s", windows$window, windows$start, windows$end), collapse = ", ")),
    sprintf("Snow gauges: %s, by %s.", paste(gauges, collapse = ", "), gauge_rule),
    "Snow: wet_snow_annual() over each watershed's fundamental watersheds (dissolved), cd's annual ERA5-Land layers, swe_max capped per cell and year at 3,000 mm:",
    sprintf("  %s: %s (CD_RUN_TIME %s, CD_SHA %s, CD_VERSION %s)", vars, cat_cd$href,
            vapply(cd_tags, `[[`, "", "CD_RUN_TIME"), vapply(cd_tags, `[[`, "", "CD_SHA"),
            vapply(cd_tags, `[[`, "", "CD_VERSION")),
    "", "## 1. The watersheds", "",
    sprintf("  %-8s %-20s %10s %8s %10s %10s %6s", "gauge", "fwapg snap", "polygons", "km2", "HYDAT km2", "years", "cover"),
    sprintf("  %-8s %-20s %10d %8s %10s %10s %6s", names(polys),
            vapply(names(polys), function(id) {
              i <- match(id, sn$station_number)
              if (is.na(i)) "mouth basin" else sprintf("%d accepted", sn$watershed_feature_id[i])
            }, ""),
            as.integer(vapply(polys, nrow, 0)), fmt(union_km2, 1), vapply(names(polys), area_of, ""),
            vapply(snow, function(s) sprintf("%d-%d", min(s$year), max(s$year)), ""),
            fmt(vapply(snow, function(s) min(s$cover), 0), 3)),
    "", sprintf("Nesting: %s; each watershed is sampled on its own.", if (length(nest)) paste(nest, collapse = "; ") else "none"), "")

say("## 2. The fits", "",
    sprintf("Response: log departure of the window's mean flow (the snow gauges from their own 1981-2010 mean; %s).",
            if (site$kind == "extend") sprintf("%s extended from the extended series' 1981-2010 mean, and carried as the site run carries it", target) else
              sprintf("%s carried as the site run carries it; it has no record", target)),
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

say("", "## 3. Snow before and after, beside the site run's flow change", "",
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
    sprintf("The site run's change at %s, mean log departure 2011-2025 minus before 1981:", target), "",
    sprintf("  %-10s %9s %4s %4s %9s %4s %4s", "window", "extended", "pre", "post", "carried", "pre", "post"))
for (w in windows$window) {
  m <- pr$mx[[paste("q_mean", w)]]
  say(sprintf("  %-10s %9s %4s %4s %9s %4d %4d", w, if (is.null(m$e)) "-" else fmt(m$diff, 3),
              if (is.null(m$e)) "-" else m$n_pre, if (is.null(m$e)) "-" else m$n_post, fmt(m$carried, 3), m$n_pre_c,
              m$n_post_c))
}
# new in #152: the same over the comparison article's periods
ref_years <- 1951:1980
recent_years <- 2016:2025
say("", "Each watershed's mean over 1951-1980 and 2016-2025 (#152):", "",
    sprintf("  %-8s %10s %10s %8s %10s %10s %8s %4s %4s", "gauge", "swe 51-80", "swe 16-25", "change", "doy 51-80",
            "doy 16-25", "change", "ref", "rec"))
for (id in names(snow)) {
  sw <- snow[[id]]
  a <- sw[sw$year %in% ref_years, ]
  b <- sw[sw$year %in% recent_years, ]
  say(sprintf("  %-8s %10s %10s %8s %10s %10s %8s %4d %4d", id, fmt(mean(a$swe_max), 1), fmt(mean(b$swe_max), 1),
              fmt(mean(b$swe_max) - mean(a$swe_max), 1), fmt(mean(a$snowmelt_doy_50), 1),
              fmt(mean(b$snowmelt_doy_50), 1), fmt(mean(b$snowmelt_doy_50) - mean(a$snowmelt_doy_50), 1), nrow(a),
              nrow(b)))
}
say("", sprintf("The site run's change at %s over the same periods (its section 5):", target), "",
    sprintf("  %-10s %9s %4s %4s %9s %4s %4s", "window", "extended", "ref", "rec", "carried", "ref", "rec"))
for (w in windows$window) {
  p <- pr$mx[[paste("q_mean", w)]]$p152
  ext <- !is.null(p$lv)
  say(sprintf("  %-10s %9s %4s %4s %9s %4d %4d", w, if (ext) fmt(p$diff, 3) else "-", if (ext) length(p$i1) else "-",
              if (ext) length(p$i2) else "-", fmt(p$carried, 3), length(p$i1_c), length(p$i2_c)))
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
short_lab <- function(s) {
  kind <- sub("^.* ", "", s$label)
  id <- if (s$gauge == target && site$kind == "ungauged") substr(target, 1, 4) else substr(s$gauge, 5, 7)
  paste0(id, c(observed = "", extended = "ext", carried = "car")[[kind]])
}
say("", paste0("Log departures per series (mig: migration, spw: spawning)", if (site$kind == "extend") sprintf(", and the donor of each of %s's extended years:", target) else ":"), "",
    sprintf("  %4s %s%s", "year",
            paste(vapply(series, function(s) sprintf("%11s", paste(short_lab(s), c(migration = "mig",
                                                                                 spawning = "spw")[[s$window]])), ""),
                  collapse = ""), if (site$kind == "extend") sprintf(" %-8s %-8s", "donor mig", "donor spw") else ""))
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
  say(sprintf("  %4d %s%s", y, paste(vapply(series, function(s) sprintf("%11s", fmt(dep_of(s, y), 3)), ""), collapse = ""),
              if (site$kind == "extend") sprintf(" %-9s %-9s", donor_of("migration", y), donor_of("spawning", y)) else ""))
}

# ---- the parity gate (maxan, BULK): #121's tracked report, before anything is written ----------
if (site$site_id == "maxan" && wname == "BULK") {
  miss <- site_parity_snow(out, readLines(file.path("data", "checks", sprintf("departure_snow_%s.txt", release))))
  if (length(miss)) {
    stop("parity: ", length(miss), " lines of the tracked snow report missing from this run, the first: ",
         paste(utils::head(miss, 3), collapse = " | "), call. = FALSE)
  }
}

writeLines(sub(" +$", "", out), report)
message("wrote ", report)

# the series for the article's data, after the report so nothing in it moves
rds <- file.path("data", "departure", sprintf("departure_site_snow_%s_%s_%s.rds", site$site_id, tolower(wname), release))
dir.create(dirname(rds), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(release = release, site = site, windows = windows, gauges = gauges, snow = snow, series = series,
             fits = fits, nest = nest, cap_binds = cap_binds, code_md5 = code_md5), rds)
}
