# Plateau precipitation (#50): climr, PNWNAmet and TerraClimate against
# precipitation observed at plateau elevation in the dry interior (hydrologic
# zones 15, 17, 23, 24), under the rule pre-registered in the #50 findings
# ("Pre-registered scoring rule" as replaced by "Amendment 2", with
# "Deviation 1"; archived with #50) before any product value was computed at
# an observation site.
#
#   Rscript scripts/wb_plateau_p.R
#
# Observations are the BC River Forecast Centre's: automated snow weather
# station (ASWS) precipitation gauges and pillows, and manual snow courses.
# The products are references for our input (climr) and two others; none is
# fitted. Stages, each cached under data/plateau_p/ (gitignored):
#   1. raw snapshots of the observation files, downloaded once and kept (their
#      md5 is in the report, so a rerun on another day reads the same bytes);
#   2. observations by site and water year: gauge P over covered months, the
#      pillow catch factor, the snow-course survey nearest April 1. Prints no
#      magnitude (Amendment 2, O1);
#   3. products at the sites, monthly: climr (mswx.blend), PNWNAmet (PCIC
#      VIC-GL PREC, daily), TerraClimate ppt; and the elevation of each
#      product's cell (climr's reference-map DEM);
#   4. the tests and the verdict.
# Report: data/checks/wb_plateau_p.txt (tracked). Connection from WET_PG* (the
# PCIC basin extents, as scripts/wb_term_diagnose.R).

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
out_dir <- file.path("data", "plateau_p")
raw_dir <- file.path(out_dir, "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
hz_zip <- file.path("data", "hydz", "bc_hydrologic_zones.zip")
stopifnot(file.exists(hz_zip))
dry <- c("15", "17", "23", "24")
# primary contrast: interior zones east of the Coast Mountains divide (Amendment 2, G6)
contrast_zones <- sprintf("%02d", c(2:9, 12:14, 16, 18:22))
band <- c(900, 2100)  # site elevation, m, both groups
pcic_run <- "TPS_gridded_obs_init"
basins <- c("300", "100", "200")  # PCIC's domain: Columbia, Fraser, Peace

# a cache is renamed into place only once complete, so a killed run leaves none
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}
key_of <- function(...) substr(wet:::wet_md5_text(paste(unlist(list(...)), collapse = "|")), 1, 10)

# ---- 1. raw snapshots ----------------------------------------------------------------------
asws <- "https://www.env.gov.bc.ca/wsd/data_searches/snow/asws/data/"
wfs <- paste0("https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0&request=GetFeature",
              "&outputFormat=json&srsName=EPSG:4326&typeName=pub:WHSE_WATER_MANAGEMENT.")
src <- c(
  courses = paste0(asws, "allmss_archive.csv"),
  courses_current = paste0(asws, "allmss_current.csv"),
  daily = paste0("https://catalogue.data.gov.bc.ca/dataset/5e7acd31-b242-4f09-8a64-000af872d68f/",
                 "resource/945c144a-d094-4a20-a3c6-9fe74cad368a/download/daily.csv"),
  pc_archive = paste0(asws, "PC_Archive.csv"),
  pc = paste0(asws, "PC.csv"),
  sw_archive = paste0(asws, "SW_Archive.csv"),
  sw = paste0(asws, "SW.csv"),
  course_locs = paste0(wfs, "SSL_SNOW_MSS_LOCS_SP"),
  gauge_locs = paste0(wfs, "SSL_SNOW_ASWS_STNS_SP"),
  prism_list = "https://services.pacificclimate.org/data/pcds/lister/climo/ENV-ASP/"
)
ext <- ifelse(grepl("WFS", src, ignore.case = TRUE) & grepl("json", src), ".json",
              ifelse(grepl("lister", src), ".html", ".csv"))
raw <- stats::setNames(file.path(raw_dir, paste0(names(src), ext)), names(src))
for (k in names(src)) {
  if (!file.exists(raw[[k]])) {
    stamp("downloading ", k)
    wet:::wet_download(src[[k]], raw[[k]], 1800)
  }
}
raw_md5 <- vapply(raw, function(f) unname(tools::md5sum(f)), "")
raw_date <- vapply(raw, function(f) format(file.mtime(f), "%Y-%m-%d"), "")

# ---- sites: zone, group, elevation, PRISM-input flag, PCIC domain ---------------------------
locs <- function(f, type) {
  j <- jsonlite::fromJSON(f)$features
  xy <- do.call(rbind, j$geometry$coordinates)
  data.frame(id = j$properties$LOCATION_ID, type = type, name = j$properties$LOCATION_NAME,
             elev = as.numeric(j$properties$ELEVATION), lon = xy[, 1], lat = xy[, 2])
}
sites <- rbind(locs(raw[["gauge_locs"]], "gauge"), locs(raw[["course_locs"]], "course"))
stopifnot(!anyDuplicated(sites[c("id", "type")]), !anyNA(sites$lon), !anyNA(sites$lat))
hz_src <- file.path("data", "hydz", paste0("src_", substr(unname(tools::md5sum(hz_zip)), 1, 8)))
utils::unzip(hz_zip, exdir = hz_src, overwrite = TRUE)  # every run, as scripts/wb_inputs.R
hz <- terra::vect(list.files(hz_src, "[.]shp$", full.names = TRUE, recursive = TRUE))
sites_v <- terra::vect(sites, geom = c("lon", "lat"), crs = "EPSG:4326")
zp <- terra::extract(hz, terra::project(sites_v, terra::crs(hz)))
zp <- zp[!duplicated(zp$id.y), ]
stopifnot(nrow(zp) == nrow(sites), all(zp$id.y == seq_len(nrow(sites))))
sites$zone <- ifelse(is.na(zp$HYDZN_NO), NA, sprintf("%02d", as.integer(zp$HYDZN_NO)))
sites$group <- ifelse(sites$zone %in% dry, "dry", ifelse(sites$zone %in% contrast_zones, "contrast", "other"))
sites$in_band <- !is.na(sites$elev) & sites$elev >= band[1] & sites$elev <= band[2]
html <- readLines(raw[["prism_list"]], warn = FALSE)
prism_ids <- regmatches(html, regexpr("[0-9][A-Z][0-9]{2}[A-Z]?P(?=/)", html, perl = TRUE))
stopifnot(length(prism_ids) > 0)
sites$prism <- sites$type == "gauge" & sites$id %in% prism_ids

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)
# the same basin extents as scripts/wb_term_diagnose.R, so its PCIC downloads are reused
basin_bbox <- function(code) {
  e <- DBI::dbGetQuery(conn, "
    SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
    FROM (SELECT ST_Extent(geom) e FROM whse_basemapping.fwa_watersheds_poly
          WHERE wscode_ltree <@ $1::ltree) x", params = list(code))
  ext <- terra::project(terra::ext(unlist(e)[c("xmin", "xmax", "ymin", "ymax")]), "EPSG:3005", "EPSG:4326")
  c(ext$xmin, ext$ymin, ext$xmax, ext$ymax) + c(-1, -1, 1, 1) * 0.0625
}
bbs <- lapply(basins, basin_bbox)
DBI::dbDisconnect(conn)
pcic_year <- function(bb, y) {
  for (i in 1:3) {
    f <- tryCatch(wet_pcic_fetch("PREC", bb, sprintf("%d-01-01", y), sprintf("%d-12-31", y), run = pcic_run),
                  error = function(e) e)
    if (!inherits(f, "error")) return(f)
    stamp("PREC ", y, ": attempt ", i, " failed: ", conditionMessage(f))
  }
  stop("PREC ", y, " failed 3 times", call. = FALSE)
}
# PCIC's domain: the non-missing mask of one PREC day (Amendment 2, O3); only is.na() is read
sites$pcic <- Reduce(`|`, lapply(bbs, function(bb) {
  !is.na(terra::extract(terra::rast(pcic_year(bb, 1981))[[1]], sites_v, ID = FALSE)[, 1])
}))
sites$use <- sites$in_band & sites$pcic & !is.na(sites$zone)

# ---- 2. observations by site and water year (no magnitude printed) ---------------------------
wy_of <- function(d) as.integer(format(d, "%Y")) + (as.integer(format(d, "%m")) >= 10)
ym_of <- function(d) format(d, "%Y-%m")
min_days <- 330        # valid days for a complete water year
min_month_days <- 27   # valid days for a covered month
min_hours <- 12        # hourly readings for a valid day
reset_drop <- 25       # an hourly drop of at least this (mm) is a reset
reset_frac <- 0.10     # ... or a fall to below this share of the previous reading
reset_hold <- 72       # hours zeroed after a reset
day_max <- 100         # a day above this (mm) is invalid
neg_flag <- 25         # Jun-Sep negative increments above this (mm) flag the site-year
swe_min_peak <- 100    # peak SWE for a catch-factor year (mm)
# Bump obs_method whenever stage 2 changes what it computes; the key also
# carries the raw files, the zones and every parameter above.
obs_method <- "deviation-1c-correction-1"
obs_key <- key_of(raw_md5, unname(tools::md5sum(hz_zip)), obs_method, min_days, min_month_days, min_hours,
                  reset_drop, reset_frac, reset_hold, day_max, neg_flag, swe_min_peak)
f_obs <- file.path(out_dir, sprintf("obs_%s.rds", obs_key))
if (!file.exists(f_obs)) {
  da <- utils::read.csv(raw[["daily"]], colClasses = c("character", "character", "character", "numeric",
                                                       "character"), na.strings = "")
  da <- da[da$variable %in% c("P", "AccumP", "SWE") & !is.na(da$value) & !grepl("^M", ifelse(is.na(da$code), "", da$code)), ]
  da$id <- sub("^_", "", da$Pillow_ID)
  da$date <- as.Date(da$Date, optional = TRUE)
  # Some rows are year-day-month (4A29P, 1984-1990): where the day is <= 12
  # they parse silently to the wrong date, so every station-year holding an
  # unparseable date is dropped, and counted.
  bad <- unique(paste(da$id, substr(da$Date, 1, 4))[is.na(da$date)])
  n_bad_rows <- sum(paste(da$id, substr(da$Date, 1, 4)) %in% bad)
  da <- da[!paste(da$id, substr(da$Date, 1, 4)) %in% bad, ]
  stopifnot(!anyNA(da$date))

  # hourly wide files: the archive and the current file carry different station sets
  read_hourly <- function(files) {
    hs <- lapply(files, function(f) utils::read.csv(f, check.names = FALSE, na.strings = "",
                                                   colClasses = "character"))
    cols <- unique(unlist(lapply(hs, names)))
    h <- do.call(rbind, lapply(hs, function(x) {
      x[setdiff(cols, names(x))] <- NA_character_
      x[cols]
    }))
    t <- as.POSIXct(h[[1]], format = "%Y-%m-%d %H:%M", tz = "UTC")  # the column is DATE(UTC)
    stopifnot(!anyNA(t))
    keep <- !duplicated(t)  # the current file repeats the archive's last hours
    h <- h[keep, ]
    t <- t[keep]
    o <- order(t)
    list(t = t[o], h = h[o, -1, drop = FALSE])
  }
  day_of <- function(t) as.Date(format(t - 8 * 3600, "%Y-%m-%d", tz = "UTC"))  # local standard time
  hp <- read_hourly(c(raw[["pc_archive"]], raw[["pc"]]))
  pc_days <- do.call(rbind, lapply(names(hp$h), function(s) {
    v <- suppressWarnings(as.numeric(hp$h[[s]]))
    ok <- !is.na(v)
    if (sum(ok) < 2) return(NULL)
    t <- hp$t[ok]
    v <- v[ok]
    prev <- c(NA, v[-length(v)])
    inc <- c(0, diff(v))  # between consecutive readings, so a gap is bridged
    reset <- !is.na(prev) & (inc <= -reset_drop | (prev > 0 & v < reset_frac * prev))
    tn <- as.numeric(t)
    for (tr in tn[reset]) inc[tn >= tr & tn < tr + reset_hold * 3600] <- 0
    day <- day_of(t)
    n <- tapply(inc, day, length)
    p <- tapply(inc, day, sum)
    d <- data.frame(id = sub(" .*$", "", s), date = as.Date(names(p)), net = as.numeric(p), n = as.integer(n))
    d <- d[d$n >= min_hours & d$net <= day_max, ]
    # the daily archive's P is max(0, day's change in AccumP): the same here (Deviation 1)
    d$p <- pmax(d$net, 0)
    d[c("id", "date", "p", "net")]
  }))
  hs <- read_hourly(c(raw[["sw_archive"]], raw[["sw"]]))
  sw_days <- do.call(rbind, lapply(names(hs$h), function(s) {
    v <- suppressWarnings(as.numeric(hs$h[[s]]))
    ok <- !is.na(v)
    if (!any(ok)) return(NULL)
    day <- day_of(hs$t[ok])
    n <- tapply(v[ok], day, length)
    m <- tapply(v[ok], day, mean)
    d <- data.frame(id = sub(" .*$", "", s), date = as.Date(names(m)), swe = as.numeric(m), n = as.integer(n))
    d[d$n >= min_hours, c("id", "date", "swe")]
  }))

  # gauge P by day: the daily archive through WY 2011, the hourly PC after
  dp <- da[da$variable == "P" & da$value <= day_max, ]
  # the archive's P is max(0, day's change in AccumP); its negatives are reset
  # artefacts, floored like the hourly era's (Deviation 1b)
  dp <- data.frame(id = dp$id, date = dp$date, p = pmax(dp$value, 0), net = NA_real_)
  # the flag needs signed daily increments in both eras: the archive's P is
  # floored, so in the daily era they come from its AccumP, with the hourly
  # era's reset rule at daily resolution (Deviation 1c)
  ac <- da[da$variable == "AccumP", c("id", "date", "value")]
  ac <- ac[order(ac$id, ac$date), ]
  ac_net <- do.call(rbind, lapply(split(ac, ac$id), function(x) {
    v <- x$value
    prev <- c(NA, v[-length(v)])
    inc <- c(NA, diff(v))
    reset <- !is.na(prev) & (inc <= -reset_drop | (prev > 0 & v < reset_frac * prev))
    for (tr in as.numeric(x$date[reset])) inc[as.numeric(x$date) >= tr & as.numeric(x$date) < tr + reset_hold / 24] <- 0
    data.frame(id = x$id, date = x$date, net = inc)
  }))
  dp$net <- ac_net$net[match(paste(dp$id, dp$date), paste(ac_net$id, ac_net$date))]
  complete_years <- function(d) {
    d$wy <- wy_of(d$date)
    n <- stats::aggregate(list(n = d$p), d[c("id", "wy")], length)
    s <- stats::aggregate(list(p = d$p), d[c("id", "wy")], sum)
    m <- merge(n, s)
    m[m$n >= min_days, ]
  }
  # check (a): daily-archive P against hourly PC where both are complete (WY 2004-2011)
  ca <- merge(complete_years(dp), complete_years(pc_days), by = c("id", "wy"), suffixes = c("_d", "_h"))
  ca <- ca[ca$wy >= 2004 & ca$wy <= 2011 & ca$p_h > 0, ]
  check_a <- list(n = nrow(ca), sites = length(unique(ca$id)), ratio = stats::median(ca$p_d / ca$p_h))
  # the flag on the same overlap years from each source, so the two eras' flags can be compared
  flag_of <- function(d) {
    j <- d[format(d$date, "%m") %in% c("06", "07", "08", "09") & !is.na(d$net) & d$net < 0, ]
    f <- stats::aggregate(list(neg = -j$net), list(id = j$id, wy = wy_of(j$date)), sum)
    paste(f$id, f$wy)[f$neg > neg_flag]
  }
  ov <- paste(ca$id, ca$wy)
  fd <- intersect(flag_of(dp), ov)
  fh <- intersect(flag_of(pc_days), ov)
  check_a$flag <- c(daily = length(fd), hourly = length(fh), both = length(intersect(fd, fh)))
  dp$src <- "daily"
  pc_days$src <- "hourly"
  gd <- rbind(dp[wy_of(dp$date) <= 2011, ], pc_days[wy_of(pc_days$date) >= 2012, ])
  gd$wy <- wy_of(gd$date)
  gd$ym <- ym_of(gd$date)
  gy <- complete_years(gd)[c("id", "wy", "n")]
  gd <- merge(gd, gy[c("id", "wy")])
  # covered months of complete years, and the gauge's sum over each
  mn <- stats::aggregate(list(n = gd$p), gd[c("id", "wy", "ym")], length)
  ms <- stats::aggregate(list(p = gd$p), gd[c("id", "wy", "ym")], sum)
  gm <- merge(mn, ms)
  gm <- gm[gm$n >= min_month_days, c("id", "wy", "ym", "p")]
  # flag: Jun-Sep negative daily increments above neg_flag in sum
  js <- gd[format(gd$date, "%m") %in% c("06", "07", "08", "09") & !is.na(gd$net) & gd$net < 0, ]
  neg <- if (nrow(js)) stats::aggregate(list(neg = -js$net), js[c("id", "wy")], sum) else
    data.frame(id = character(), wy = integer(), neg = numeric())
  gy <- merge(gy, neg, all.x = TRUE)
  gy$neg[is.na(gy$neg)] <- 0
  gy$flag <- gy$neg > neg_flag
  gy$src <- ifelse(gy$wy <= 2011, "daily", "hourly")

  # pillow SWE by day, the same split; the catch factor per complete gauge-year
  sw <- rbind(data.frame(id = da$id, date = da$date, swe = da$value)[da$variable == "SWE" & wy_of(da$date) <= 2011, ],
              sw_days[wy_of(sw_days$date) >= 2012, ])
  sw$wy <- wy_of(sw$date)
  sw <- sw[format(sw$date, "%m") %in% sprintf("%02d", c(10:12, 1:6)), ]
  sw <- merge(sw, gy[c("id", "wy")])
  pk <- do.call(rbind, lapply(split(sw, paste(sw$id, sw$wy)), function(s) s[which.max(s$swe), ]))
  pk <- pk[pk$swe >= swe_min_peak, c("id", "wy", "date", "swe")]
  names(pk)[3:4] <- c("peak_date", "swe_peak")
  gdc <- gd[paste(gd$id, gd$wy, gd$ym) %in% paste(gm$id, gm$wy, gm$ym), ]
  gsplit <- split(gdc[c("date", "p")], paste(gdc$id, gdc$wy))
  to_peak <- function(id, wy, peak) {
    x <- gsplit[[paste(id, wy)]]
    if (is.null(x) || is.na(peak)) return(NA_real_)
    sum(x$p[x$date <= peak])
  }
  # the peak builds over every day from 1 October, so a year counts toward c
  # only when every month from October to the peak's month is covered
  gm_key <- paste(gm$id, gm$wy, gm$ym)
  oct_to_peak_covered <- function(id, wy, peak) {
    ms <- seq(as.Date(sprintf("%d-10-01", wy - 1)), as.Date(format(peak, "%Y-%m-01")), by = "month")
    all(paste(id, wy, ym_of(ms)) %in% gm_key)
  }
  pk$p_to_peak <- mapply(to_peak, pk$id, pk$wy, pk$peak_date)
  pk$full <- mapply(oct_to_peak_covered, pk$id, pk$wy, pk$peak_date)
  pk$ratio <- ifelse(pk$full & !is.na(pk$p_to_peak) & pk$p_to_peak > 0, pk$swe_peak / pk$p_to_peak, NA)
  cf <- stats::aggregate(list(c_raw = pk$ratio), pk["id"], stats::median, na.rm = TRUE)
  cf$c <- pmax(1, cf$c_raw)
  # covered P up to the peak each year: that year's peak, or the site's median peak day
  pk$doy <- as.integer(pk$peak_date - as.Date(sprintf("%d-10-01", pk$wy - 1)))
  med_doy <- stats::aggregate(list(doy = pk$doy), pk["id"], stats::median)
  gy <- merge(gy, pk[c("id", "wy", "peak_date")], all.x = TRUE)
  gy <- merge(gy, med_doy, all.x = TRUE)
  fallback <- as.Date(sprintf("%d-10-01", gy$wy - 1)) + round(gy$doy)
  gy$peak_use <- as.Date(ifelse(is.na(gy$peak_date), fallback, gy$peak_date), origin = "1970-01-01")
  gy$p_to_peak <- mapply(to_peak, gy$id, gy$wy, gy$peak_use)
  gy <- merge(gy, cf[c("id", "c")], all.x = TRUE)

  # snow courses: per water year the survey dated 20 Mar - 10 Apr nearest April 1
  rd <- function(f) {
    x <- utils::read.csv(f, check.names = FALSE, na.strings = "", strip.white = TRUE)
    names(x) <- trimws(names(x))
    data.frame(id = trimws(x$Number), date = as.Date(x[["Date of Survey"]], "%Y/%m/%d"),
               swe = suppressWarnings(as.numeric(x[["Water Equiv. mm"]])))
  }
  sc <- rbind(rd(raw[["courses"]]), rd(raw[["courses_current"]]))
  sc <- sc[!is.na(sc$swe) & !is.na(sc$date) & !duplicated(sc[c("id", "date")]), ]
  md <- as.integer(format(sc$date, "%m%d"))
  sc <- sc[md >= 320 & md <= 410, ]
  sc$wy <- wy_of(sc$date)
  sc$off <- abs(as.integer(sc$date - as.Date(sprintf("%d-04-01", sc$wy))))
  sc <- sc[order(sc$id, sc$wy, sc$off), ]
  sc <- sc[!duplicated(sc[c("id", "wy")]), c("id", "wy", "date", "swe")]

  save_atomic(list(gy = gy, gm = gm, cf = cf, course = sc, check_a = check_a, bad = bad, n_bad_rows = n_bad_rows),
              f_obs)
}
obs <- readRDS(f_obs)
check_a <- obs$check_a
stamp("check (a): ", check_a$n, " gauge-years at ", check_a$sites, " sites; median daily/hourly ",
      sprintf("%.3f", check_a$ratio))
if (check_a$n < 3 || check_a$ratio < 0.95 || check_a$ratio > 1.05) {
  stop("check (a) failed: the daily archive and the hourly PC disagree, or cannot be compared", call. = FALSE)
}

# eligibility: gauges with a complete year (>= 3 per test), courses with >= 10
# surveys in WY 1982-2010, a median SWE >= 100 mm and a non-zero sum
gsite <- sites[sites$type == "gauge" & sites$use & sites$id %in% obs$gy$id, ]
gy <- obs$gy[obs$gy$id %in% gsite$id, ]
gm <- obs$gm[obs$gm$id %in% gsite$id, ]
csite <- sites[sites$type == "course" & sites$use, ]
sc <- obs$course[obs$course$id %in% csite$id & obs$course$wy >= 1982 & obs$course$wy <= 2010, ]
cn <- data.frame(id = sort(unique(sc$id)))
cn$n <- as.integer(table(sc$id)[cn$id])
cn$med <- as.numeric(tapply(sc$swe, sc$id, stats::median)[cn$id])
cn$sum <- as.numeric(tapply(sc$swe, sc$id, sum)[cn$id])
n_zero <- sum(cn$n >= 10 & cn$sum == 0)
c_ok <- cn$id[cn$n >= 10 & cn$med >= 100 & cn$sum > 0]
sc <- sc[sc$id %in% c_ok, ]
csite <- csite[csite$id %in% c_ok, ]
grp <- function(ids, s) s$group[match(ids, s$id)]
cf_g <- obs$cf[obs$cf$id %in% gsite$id, ]
cmed <- tapply(cf_g$c, grp(cf_g$id, gsite), stats::median, na.rm = TRUE)
stamp("stage 2: gauges with a complete year: dry ", sum(gsite$group == "dry"), ", contrast ",
      sum(gsite$group == "contrast"), ", other ", sum(gsite$group == "other"), "; flagged site-years ",
      sum(gy$flag), "; catch factor median dry ", sprintf("%.2f", cmed["dry"]), ", contrast ",
      sprintf("%.2f", cmed["contrast"]), "; courses: dry ", sum(csite$group == "dry"), ", contrast ",
      sum(csite$group == "contrast"), " (zero-sum dropped ", n_zero, ")")

# ---- 3. products at the sites, monthly -------------------------------------------------------
psite <- rbind(gsite, csite)
psite <- psite[!duplicated(psite[c("lon", "lat", "elev")]), ]
psite$pid <- seq_len(nrow(psite))
site_key <- key_of(sprintf("%.6f %.6f %.1f", psite$lon, psite$lat, psite$elev))
yrs <- 1967:2024
pts <- data.frame(id = psite$pid, lon = psite$lon, lat = psite$lat, elev = psite$elev)
pv <- terra::vect(pts, geom = c("lon", "lat"), crs = "EPSG:4326")
long_months <- function(pid, y, m, p, product) {
  data.frame(pid = pid, ym = sprintf("%d-%02d", y, m), p = p, product = product)
}

# climr, as the water balance uses it; bump climr_method if this call changes
climr_method <- "downscale-mswx.blend-ppt-1"
f_cl <- file.path(out_dir, sprintf("climr_%s.rds", key_of(site_key, yrs, climr_method,
                                                          as.character(utils::packageVersion("climr")))))
if (!file.exists(f_cl)) {
  stamp("climr at ", nrow(pts), " sites")
  cl <- suppressMessages(climr::downscale(
    pts, which_refmap = "refmap_climr", obs_ts_dataset = "mswx.blend", obs_years = yrs,
    vars = sprintf("PPT_%02d", 1:12), return_refperiod = FALSE
  ))
  cl <- as.data.frame(cl)
  # climr 0.2.2 returns its 1961_1990 reference row even with return_refperiod = FALSE
  cl <- cl[cl$DATASET %in% "mswx.blend" & grepl("^[0-9]{4}$", cl$PERIOD), ]
  cl$y <- as.integer(cl$PERIOD)
  stopifnot(!anyNA(cl$y), all(table(cl$id) == length(yrs)), !anyDuplicated(cl[c("id", "y")]))
  pm <- do.call(rbind, lapply(1:12, function(m) long_months(cl$id, cl$y, m, cl[[sprintf("PPT_%02d", m)]], "climr")))
  save_atomic(pm, f_cl)
}
p_cl <- readRDS(f_cl)

# PNWNAmet: PCIC VIC-GL PREC by calendar year over the basin extents, at each site's cell
pn_yrs <- 1967:2012
pn_method <- "pcic-prec-daily-cell-1"
f_pn <- file.path(out_dir, sprintf("pnwnamet_%s.rds", key_of(site_key, pn_yrs, pn_method, pcic_run,
                                                             vapply(bbs, paste, "", collapse = ","))))
if (!file.exists(f_pn)) {
  pm <- do.call(rbind, lapply(pn_yrs, function(y) {
    stamp("PREC ", y)
    days <- seq(as.Date(sprintf("%d-01-01", y)), as.Date(sprintf("%d-12-31", y)), by = "day")
    v <- NULL
    for (bb in bbs) {
      r <- terra::rast(pcic_year(bb, y))
      stopifnot(terra::nlyr(r) == length(days))  # a standard calendar, one layer per day
      x <- as.matrix(terra::extract(r, pv, ID = FALSE))
      v <- if (is.null(v)) x else ifelse(is.na(v), x, v)
    }
    mo <- as.integer(format(days, "%m"))
    do.call(rbind, lapply(1:12, function(m) {
      long_months(pts$id, y, m, rowSums(v[, mo == m, drop = FALSE]), "pnwnamet")
    }))
  }))
  save_atomic(pm, f_pn)
}
p_pn <- readRDS(f_pn)

# TerraClimate ppt by year, subset over the sites (NCSS), at each site's cell
tc_dir <- file.path(out_dir, "terraclimate")
dir.create(tc_dir, showWarnings = FALSE)
tc_bb <- c(floor(min(pts$lon)) - 0.5, floor(min(pts$lat)) - 0.5, ceiling(max(pts$lon)) + 0.5,
           ceiling(max(pts$lat)) + 0.5)
tc_file <- function(y) {
  f <- file.path(tc_dir, sprintf("ppt_%d_%s.nc", y, key_of(tc_bb)))
  if (!file.exists(f)) {
    u <- sprintf(paste0("http://thredds.northwestknowledge.net:8080/thredds/ncss/TERRACLIMATE_ALL/data/",
                        "TerraClimate_ppt_%d.nc?var=ppt&north=%s&south=%s&west=%s&east=%s&temporal=all&accept=netcdf"),
                 y, tc_bb[4], tc_bb[2], tc_bb[1], tc_bb[3])
    wet:::wet_download(u, f, 600)
    if (!wet:::wet_is_netcdf(f)) {
      unlink(f)
      stop("TerraClimate ", y, " is not NetCDF", call. = FALSE)
    }
  }
  f
}
tc_method <- "ncss-ppt-cell-1"
f_tc <- file.path(out_dir, sprintf("terraclimate_%s.rds", key_of(site_key, yrs, tc_method, tc_bb)))
if (!file.exists(f_tc)) {
  pm <- do.call(rbind, lapply(yrs, function(y) {
    r <- terra::rast(tc_file(y), "ppt")
    tt <- terra::time(r)
    stopifnot(terra::nlyr(r) == 12, !anyNA(tt), all(format(tt, "%Y") == as.character(y)),
              all(as.integer(format(tt, "%m")) == 1:12))
    x <- as.matrix(terra::extract(r, pv, ID = FALSE))
    do.call(rbind, lapply(1:12, function(m) long_months(pts$id, y, m, x[, m], "terraclimate")))
  }))
  save_atomic(pm, f_tc)
}
p_tc <- readRDS(f_tc)
prod <- rbind(p_cl, p_pn, p_tc)
stopifnot(!anyDuplicated(prod[c("pid", "ym", "product")]))

# cell elevations from climr's reference-map DEM (Amendment 2, G4)
f_dz <- file.path(out_dir, sprintf("cellz_%s.rds", key_of(site_key, tc_bb, climr_method, pcic_run,
                                                          as.character(utils::packageVersion("climr")))))
if (!file.exists(f_dz)) {
  dem <- climr::input_refmap(bbox = climr::get_bb(pts))[["dem2_WNA"]]
  z_cl <- terra::extract(dem, pv, ID = FALSE)[, 1]
  cell_mean <- function(tmpl) {
    tmpl <- terra::crop(tmpl, terra::ext(dem), snap = "out")
    terra::extract(terra::resample(dem, tmpl, method = "average"), pv, ID = FALSE)[, 1]
  }
  z_pn <- Reduce(function(a, b) ifelse(is.na(a), b, a),
                 lapply(bbs, function(bb) cell_mean(terra::rast(pcic_year(bb, 1981))[[1]])))
  z_tc <- cell_mean(terra::rast(tc_file(1981), "ppt")[[1]])
  save_atomic(data.frame(pid = pts$id, z_climr = z_cl, z_pnwnamet = z_pn, z_terraclimate = z_tc), f_dz)
}
cz <- readRDS(f_dz)
psite <- merge(psite, cz, by = "pid")
psite$dz_climr <- psite$z_climr - psite$elev
psite$dz_pnwnamet <- psite$z_pnwnamet - psite$elev
psite$dz_terraclimate <- psite$z_terraclimate - psite$elev
loc_key <- function(s) paste(s$lon, s$lat, s$elev)
pid_of <- function(id, type) {
  s <- sites[sites$type == type, ]
  psite$pid[match(loc_key(s[match(id, s$id), ]), loc_key(psite))]
}

# ---- 4. tests ------------------------------------------------------------------------------------
med <- stats::median
wy_max <- c(climr = 2024, pnwnamet = 2012, terraclimate = 2024)
gm$pid <- pid_of(gm$id, "gauge")
gm$m <- as.integer(substr(gm$ym, 6, 7))
# gauge and product sums over the covered months, per gauge-year
gyear <- function(product, months = 1:12) {
  x <- merge(gm[gm$m %in% months, ], prod[prod$product == product, c("pid", "ym", "p")], by = c("pid", "ym"),
             suffixes = c("", "_prod"))
  x <- x[x$wy <= wy_max[[product]], ]
  a <- stats::aggregate(list(obs = x$p, prod = x$p_prod), x[c("id", "wy")], sum)
  a <- merge(a, gy[c("id", "wy", "flag", "c", "p_to_peak")], by = c("id", "wy"))
  a$adj <- a$obs + ifelse(is.na(a$c) | is.na(a$p_to_peak), 0, (a$c - 1) * a$p_to_peak)
  a$era <- ifelse(a$wy <= 2011, "<=2011", ">=2012")
  a
}
gys <- lapply(stats::setNames(names(wy_max), names(wy_max)), gyear)
# per-site ratio of sums over its eligible years (>= 3)
site_ratio <- function(a, adj = FALSE, years = NULL) {
  if (!is.null(years)) a <- a[paste(a$id, a$wy) %in% years, ]
  if (!nrow(a)) return(stats::setNames(numeric(), character()))
  o <- if (adj) a$adj else a$obs
  n <- tapply(a$wy, a$id, length)
  r <- tapply(a$prod, a$id, sum) / tapply(o, a$id, sum)
  r[names(n)[n >= 3]]
}
gs <- gsite
dmed <- function(r, contrast = "contrast", ids = names(r)) {
  r <- r[ids]
  g <- grp(names(r), gs)
  cg <- if (identical(contrast, "full")) g %in% c("contrast", "other") else g == contrast
  list(d = med(r[g == "dry"]) / med(r[cg]), n_dry = sum(g == "dry"), n_con = sum(cg),
       zones = length(unique(gs$zone[match(names(r)[g == "dry"], gs$id)])))
}
# G1: catch-adjusted P in both groups when the group medians of c differ by > 10 %
use_adj <- !any(is.na(cmed[c("dry", "contrast")])) &&
  (cmed[["dry"]] / cmed[["contrast"]] > 1.1 || cmed[["dry"]] / cmed[["contrast"]] < 1 / 1.1)
cls_c <- function(d) if (is.na(d)) NA_character_ else if (d >= 1.15) "high" else if (d <= 1.05) "not high" else "inconclusive"
cls_p <- function(d) if (is.na(d)) NA_character_ else if (d <= 0.83) "low" else if (d > 0.90) "not low" else "between"
cls_r <- function(d) "reported"
judge_t1 <- function(product, classify) {
  a <- gys[[product]]
  r <- site_ratio(a, use_adj)
  base <- dmed(r)
  out <- list(d = base$d, n_dry = base$n_dry, n_con = base$n_con, zones = base$zones, class = classify(base$d),
              loo_range = c(NA, NA), d_noflag = NA, `d_era<=2011` = NA, `d_era>=2012` = NA,
              `n_era<=2011` = c(NA, NA), `n_era>=2012` = c(NA, NA), d_dz = NA, n_dz = c(NA, NA), dz_check = "-",
              d_unflagged = NA, n_unflagged = c(NA, NA), prism_check = "-")
  enough <- function(x) x$n_dry >= 4 && x$n_con >= 4
  if (!enough(base) || base$zones < 2) {
    out$status <- "unavailable"
    return(out)
  }
  notes <- character()
  loo_d <- vapply(names(r), function(i) dmed(r[setdiff(names(r), i)])$d, 1)
  out$loo_range <- range(loo_d)
  if (any(vapply(loo_d, classify, "") != out$class)) notes <- c(notes, "unstable (leave-one-out)")
  f <- dmed(site_ratio(a, use_adj, paste(a$id, a$wy)[!a$flag]))
  out$d_noflag <- f$d
  if (!enough(f) || classify(f$d) != out$class) notes <- c(notes, "unstable (flagged years)")
  for (e in c("<=2011", ">=2012")) {
    x <- dmed(site_ratio(a, use_adj, paste(a$id, a$wy)[a$era == e]))
    out[[paste0("d_era", e)]] <- x$d
    out[[paste0("n_era", e)]] <- c(x$n_dry, x$n_con)
    if (enough(x)) {
      if (identical(out$class, "high") && x$d < 1.00) notes <- c(notes, "era-dependent")
      if (identical(out$class, "not high") && x$d > 1.10) notes <- c(notes, "era-dependent")
    }
  }
  dz <- psite[[paste0("dz_", product)]][match(pid_of(names(r), "gauge"), psite$pid)]
  z <- dmed(r, ids = names(r)[!is.na(dz) & abs(dz) <= 200])
  out$d_dz <- z$d
  out$n_dz <- c(z$n_dry, z$n_con)
  out$dz_check <- if (!enough(z)) "unavailable" else if (classify(z$d) == out$class) "holds" else "fails"
  if (out$dz_check == "fails") notes <- c(notes, "unstable (elevation)")
  u <- dmed(r, ids = names(r)[!gs$prism[match(names(r), gs$id)]])
  out$d_unflagged <- u$d
  out$n_unflagged <- c(u$n_dry, u$n_con)
  out$prism_check <- if (!enough(u)) "unavailable" else if (classify(u$d) == out$class) "holds" else "fails"
  if (out$prism_check == "fails") notes <- c(notes, "unstable (PRISM-input gauges)")
  if (identical(out$class, "not high") && out$prism_check == "unavailable") {
    notes <- c(notes, "unavailable (unflagged check)")
  }
  out$status <- if (length(notes)) paste(unique(notes), collapse = "; ") else out$class
  out
}
t1 <- judge_t1("climr", cls_c)
t1_pn <- judge_t1("pnwnamet", cls_p)
t1_tc <- judge_t1("terraclimate", cls_r)

# B3 precondition: climr / PNWNAmet at the gauge sites, product against product
b3 <- local({
  a <- gys$pnwnamet
  x <- gm[gm$wy <= 2012 & paste(gm$id, gm$wy) %in% paste(a$id, a$wy), ]
  pc <- prod[prod$product == "climr", ]
  pn <- prod[prod$product == "pnwnamet", ]
  x$p_c <- pc$p[match(paste(x$pid, x$ym), paste(pc$pid, pc$ym))]
  x$p_n <- pn$p[match(paste(x$pid, x$ym), paste(pn$pid, pn$ym))]
  n <- tapply(x$wy, x$id, function(w) length(unique(w)))
  r <- (tapply(x$p_c, x$id, sum) / tapply(x$p_n, x$id, sum))[names(n)[n >= 3]]
  d <- dmed(r)
  list(r = d$d, n_dry = d$n_dry, n_con = d$n_con,
       met = !is.na(d$d) && d$n_dry >= 4 && d$n_con >= 4 && d$d >= 1.10,
       zone = tapply(r, gs$zone[match(names(r), gs$id)], med), con_med = med(r[grp(names(r), gs) == "contrast"]))
})

# T2 veto: climr / catch-adjusted gauge P at dry gauges with a catch factor
t2 <- local({
  a <- gys$climr
  a <- a[!is.na(a$c) & grp(a$id, gs) %in% "dry", ]
  r <- site_ratio(a, adj = TRUE)
  list(n = length(r), share_below = if (length(r)) mean(r < 1) else NA,
       veto = length(r) >= 3 && mean(r < 1) >= 0.5)
})

# T3: product winter P (1 Sep to the survey date) against the survey's SWE, WY 1982-2010
sc$pid <- pid_of(sc$id, "course")
winter <- function(product) {
  pp <- prod[prod$product == product, ]
  by_pid <- lapply(split(pp, pp$pid), function(x) stats::setNames(x$p, x$ym))
  vapply(seq_len(nrow(sc)), function(i) {
    d <- sc$date[i]
    ms <- seq(as.Date(sprintf("%d-09-01", sc$wy[i] - 1)), as.Date(format(d, "%Y-%m-01")), by = "month")
    last <- ms[length(ms)]
    dim_last <- as.integer(format(seq(last, by = "month", length.out = 2)[2] - 1, "%d"))
    frac <- (as.integer(format(d, "%d")) - 1) / dim_last
    v <- by_pid[[as.character(sc$pid[i])]][ym_of(ms)]
    if (is.null(v) || anyNA(v)) return(NA_real_)
    sum(v[-length(v)]) + frac * v[length(v)]
  }, 1)
}
t3 <- lapply(stats::setNames(names(wy_max), names(wy_max)), function(product) {
  w <- winter(product)
  ok <- !is.na(w)
  r <- tapply(w[ok], sc$id[ok], sum) / tapply(sc$swe[ok], sc$id[ok], sum)
  g <- grp(names(r), csite)
  rd <- r[g == "dry"]
  share <- mean(rd < 1)
  out <- list(n_dry = length(rd), share_below = share, low = length(rd) > 0 && share >= 0.5,
              factor = med(rd) / med(r[g == "contrast"]), med_dry = med(rd),
              zone = tapply(rd, csite$zone[match(names(rd), csite$id)], function(x) mean(x < 1)),
              n_dz = NA, dz_check = "-")
  if (product == "pnwnamet") {
    dz <- psite$dz_pnwnamet[match(pid_of(names(rd), "course"), psite$pid)]
    k <- !is.na(dz) & dz >= -100
    out$n_dz <- sum(k)
    out$dz_check <- if (sum(k) < 4) "unavailable" else if (mean(rd[k] < 1) >= 0.5) "holds" else "fails"
    if (out$low && out$dz_check == "fails") out$low <- FALSE
  }
  out
})

# reported, not deciding: bootstrap interval, seasons, full and elevation-matched contrast, zone mix
r_main <- site_ratio(gys$climr, use_adj)
g_main <- grp(names(r_main), gs)
set.seed(50)
boot <- local({
  rd <- r_main[g_main == "dry"]
  rc <- r_main[g_main == "contrast"]
  if (length(rd) < 2 || length(rc) < 2) return(c(NA, NA))
  b <- replicate(2000, med(sample(rd, replace = TRUE)) / med(sample(rc, replace = TRUE)))
  stats::quantile(b, c(0.05, 0.95))
})
# on raw gauge P: the catch adjustment is a whole-year quantity
season_d <- vapply(list(`Oct-Apr` = c(10:12, 1:4), `May-Sep` = 5:9), function(ms) {
  dmed(site_ratio(gyear("climr", ms)))$d
}, 1)
d_full <- dmed(r_main, "full")
elev_main <- gs$elev[match(names(r_main), gs$id)]
dry_iqr <- stats::quantile(elev_main[g_main == "dry"], c(0.25, 0.75))
d_em <- dmed(r_main, ids = names(r_main)[g_main == "dry" | (g_main == "contrast" & elev_main >= dry_iqr[1] &
                                                              elev_main <= dry_iqr[2])])
zone_mix <- table(factor(gs$zone[match(names(r_main)[g_main == "dry"], gs$id)], levels = dry))

# ---- verdict -----------------------------------------------------------------------------------
climr_high <- b3$met && identical(t1$status, "high") && !t2$veto
climr_not_high <- b3$met && identical(t1$status, "not high")
verdict <- if (!b3$met && (b3$n_dry < 4 || b3$n_con < 4)) {
  "unresolved: too few gauges for the B3 precondition"
} else if (!b3$met) {
  "unresolved: the gauge sites do not show #45's gap"
} else if (climr_high && t3$climr$low) {
  "conflicted (T1 climr high, T3 climr below the lower bound)"
} else if (climr_high) {
  "climr high"
} else if (identical(t1$status, "high") && t2$veto) {
  "climr high vetoed by T2"
} else if (climr_not_high) {
  "climr not high"
} else {
  sprintf("not decided (T1: %s)", t1$status)
}
pn_stable <- !grepl("unstable|unavailable", t1_pn$status)
attribution <- if (!b3$met) "unresolved" else {
  ok_high <- climr_high && !t3$climr$low
  ours <- ok_high && pn_stable && t1_pn$d > 0.90
  theirs <- pn_stable && t1_pn$d <= 0.83 && !is.na(t1$d) && t1$d < 1.10
  both <- ok_high && pn_stable && t1_pn$d <= 0.83
  if (both) "both" else if (ours) "ours" else if (theirs) "theirs" else "unresolved"
}

# ---- report --------------------------------------------------------------------------------------
f2 <- function(x) ifelse(is.na(x), "-", sprintf("%.2f", x))
ng <- function(x) sprintf("dry %s, contrast %s", x[1], x[2])
gtab <- function(ids) {
  s <- gs[match(ids, gs$id), ]
  sprintf("%-6s %-4s %-8s %5.0f  %-26s %-5s", s$id, s$zone, s$group, s$elev, substr(s$name, 1, 26), s$prism)
}
rp <- site_ratio(gys$pnwnamet, use_adj)
rt <- site_ratio(gys$terraclimate, use_adj)
nyr <- tapply(gys$climr$wy, gys$climr$id, function(w) sprintf("%d-%d (%d)", min(w), max(w), length(w)))
site_lines <- function(ids) {
  ps <- psite[match(pid_of(ids, "gauge"), psite$pid), ]
  sprintf("%s %5s %5s %5s  %-15s %5.0f %5.0f %5.0f", gtab(ids), f2(r_main[ids]), f2(rp[ids]), f2(rt[ids]),
          nyr[ids], ps$dz_climr, ps$dz_pnwnamet, ps$dz_terraclimate)
}
hdr <- "id     zone group     elev  name                       prism climr  PNWN    TC  years            dz_cl dz_pn dz_tc"
lines <- c(
  "# Plateau precipitation (#50): climr, PNWNAmet and TerraClimate against plateau-elevation observations",
  "",
  "rule: pre-registered in the #50 findings before any product value was computed at a site, as replaced by Amendment 2",
  "deviation 1: gauge days floored at 0 in both eras, as the daily archive defines P (as registered, check (a) stopped the run at 1.156)",
  "correction 1: the catch factor counts only years covered from October to the peak",
  "deviation 1c: the daily era's Jun-Sep flag reads the archive's AccumP increments, as the hourly era's reads PC",
  sprintf("observations: BC River Forecast Centre ASWS (daily archive to WY 2011, hourly PC after) and snow courses; snapshot %s",
          paste(unique(raw_date), collapse = ", ")),
  vapply(names(raw), function(k) sprintf("  %-15s md5 %s", k, raw_md5[[k]]), ""),
  sprintf("products: climr %s (refmap_climr, mswx.blend), PNWNAmet as PCIC %s PREC, TerraClimate ppt (NCSS)",
          utils::packageVersion("climr"), pcic_run),
  sprintf("sites in band %d-%d m and PCIC's domain; dry zones %s; primary contrast zones %s",
          band[1], band[2], paste(dry, collapse = " "), paste(contrast_zones, collapse = " ")),
  sprintf("check (a): daily archive / hourly PC, %d gauge-years at %d sites: median %s",
          check_a$n, check_a$sites, f2(check_a$ratio)),
  sprintf("flag on those gauge-years: from the daily archive's AccumP %d, from hourly PC %d, both %d",
          check_a$flag[["daily"]], check_a$flag[["hourly"]], check_a$flag[["both"]]),
  sprintf("catch factor c, median by group: dry %s, contrast %s; primary D on %s gauge P",
          f2(cmed["dry"]), f2(cmed["contrast"]), if (use_adj) "catch-adjusted" else "raw"),
  sprintf("flagged site-years (Jun-Sep negative increments > %d mm): %d of %d", neg_flag, sum(gy$flag), nrow(gy)),
  sprintf("daily-archive station-years dropped for year-day-month dates: %s (%d rows)",
          paste(obs$bad, collapse = ", "), obs$n_bad_rows),
  "",
  sprintf("## Verdict: %s", verdict),
  sprintf("attribution of #45's climr-PNWNAmet gap: %s", attribution),
  "",
  "## B3 precondition: climr / PNWNAmet at the gauge sites (WY <= 2012), dry over contrast",
  sprintf("R = %s (%s gauges; contrast median climr/PNWNAmet %s); met: %s", f2(b3$r), ng(c(b3$n_dry, b3$n_con)),
          f2(b3$con_med), b3$met),
  sprintf("  zone %s: median climr/PNWNAmet %s", names(b3$zone), f2(b3$zone)),
  "",
  "## T1: D = median(product / gauge) over dry gauges, over the same for contrast gauges",
  sprintf("climr:        D %s (%s; dry zones %d) -> %s; status: %s", f2(t1$d), ng(c(t1$n_dry, t1$n_con)), t1$zones,
          t1$class, t1$status),
  sprintf("  leave-one-out %s-%s; flagged years removed %s; era <=2011 %s (%s), >=2012 %s (%s)",
          f2(t1$loo_range[1]), f2(t1$loo_range[2]), f2(t1$d_noflag), f2(t1[["d_era<=2011"]]),
          ng(t1[["n_era<=2011"]]), f2(t1[["d_era>=2012"]]), ng(t1[["n_era>=2012"]])),
  sprintf("  |dz| <= 200 m: %s (%s) %s; unflagged by PRISM input: %s (%s) %s", f2(t1$d_dz), ng(t1$n_dz),
          t1$dz_check, f2(t1$d_unflagged), ng(t1$n_unflagged), t1$prism_check),
  sprintf("PNWNAmet:     D %s (%s) -> %s; status: %s; leave-one-out %s-%s", f2(t1_pn$d),
          ng(c(t1_pn$n_dry, t1_pn$n_con)), t1_pn$class, t1_pn$status, f2(t1_pn$loo_range[1]),
          f2(t1_pn$loo_range[2])),
  sprintf("TerraClimate: D %s (%s); leave-one-out %s-%s", f2(t1_tc$d), ng(c(t1_tc$n_dry, t1_tc$n_con)),
          f2(t1_tc$loo_range[1]), f2(t1_tc$loo_range[2])),
  sprintf("reported: climr D bootstrap 90 %% interval %s-%s; Oct-Apr %s, May-Sep %s (raw gauge P)", f2(boot[1]), f2(boot[2]),
          f2(season_d[1]), f2(season_d[2])),
  sprintf("reported: full contrast %s (%s); elevation-matched contrast %s (%s)", f2(d_full$d),
          ng(c(d_full$n_dry, d_full$n_con)), f2(d_em$d), ng(c(d_em$n_dry, d_em$n_con))),
  sprintf("dry gauges by zone: %s%s", paste(sprintf("%s %d", names(zone_mix), zone_mix), collapse = ", "),
          if (zone_mix[["15"]] < 2) " (the gauge verdict does not cover zone 15)" else ""),
  "",
  "## T2 veto: climr / catch-adjusted gauge P at dry gauges with a catch factor",
  sprintf("gauges %d; share below 1.00: %s; veto: %s", t2$n, f2(t2$share_below), t2$veto),
  "",
  "## T3: product winter P (1 Sep to the survey) / snow-course SWE, WY 1982-2010",
  vapply(names(t3), function(p) {
    x <- t3[[p]]
    sprintf("%-12s dry courses %d; share below 1: %s -> %s; median dry %s; dry/contrast factor %s%s", p, x$n_dry,
            f2(x$share_below), if (x$low) "low there" else "not low", f2(x$med_dry), f2(x$factor),
            if (p == "pnwnamet") sprintf("; cell no more than 100 m below: %s courses, %s", x$n_dz, x$dz_check) else "")
  }, ""),
  vapply(names(t3), function(p) sprintf("  %-12s share below 1 by dry zone: %s", p,
                                        paste(sprintf("%s %s", names(t3[[p]]$zone), f2(t3[[p]]$zone)), collapse = ", ")), ""),
  sprintf("courses dropped for a zero SWE sum: %d", n_zero),
  "",
  "## Dry gauges: product / gauge (ratio of sums over complete years) and cell minus site elevation (m)",
  hdr,
  site_lines(sort(names(r_main)[g_main == "dry"])),
  "",
  "## Primary-contrast gauges",
  hdr,
  site_lines(sort(names(r_main)[g_main == "contrast"]))
)
f_report <- file.path("data", "checks", "wb_plateau_p.txt")
writeLines(lines, f_report)
saveRDS(list(sites = sites, psite = psite, gy = gy, gys = gys, course = sc, t1 = t1, t1_pn = t1_pn, t1_tc = t1_tc,
             b3 = b3, t2 = t2, t3 = t3, verdict = verdict, attribution = attribution, use_adj = use_adj),
        file.path(out_dir, "plateau_p.rds"))
stamp("done; report ", f_report)
