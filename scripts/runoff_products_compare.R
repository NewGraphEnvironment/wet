# TerraClimate runoff and the BC 1961-1990 runoff isolines against the held-out
# balance and HYDAT at the shipped fit's calibration gauges (#243, #225), under
# the rule registered in scripts/runoff_products_rule.R before this script or
# any product value existed. Both products are references, never inputs
# (CLAUDE.md, "Own estimates first").
#
#   WET_DATA_ROOT=<main checkout>/data Rscript scripts/runoff_products_compare.R [workers]
#
# Inputs, each fetched once into <WET_DATA_ROOT>/runoff_products/raw/ with every
# request logged to <WET_DATA_ROOT>/logs/243/runoff_products_fetch.tsv:
#   - TerraClimate_19812010_q.nc (the 1981-2010 runoff climatology, 12 monthly
#     layers in mm), from the Climatology Lab's THREDDS file server, the path
#     wet_terraclimate_aet() reads the AET and precipitation climatologies from
#     (its robots.txt, THREDDS's default, disallows it: the owner's decision of
#     2026-11-27, research/runoff_products.md);
#   - WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE from the BC WFS (OGL-BC), held
#     to the server's numberMatched.
# Stages 1-3 are cached under <WET_DATA_ROOT>/runoff_products/. Stage 1's .tif
# files are named for their inputs' md5s and parameters, not this script's code:
# after changing stage 1 here, remove them. Stage 2 is keyed on the md5 of the
# .tif it samples (so a rebuilt .tif is sampled again), wet_ws_sample.R,
# wet_ws_fetch.R and `sample_version`; stage 3 on stage 2's key and the upstream
# code in R/. After changing sample_group() or upstream() here, bump
# `sample_version`. fwapg and installed packages are in no key. Stages 4 and 5 are
# recomputed on every run:
#   1. TerraClimate cropped to BC at its own 1/24 degree lattice; the isolines
#      densified to 1 km and gridded by sf's GDAL to a TIN and an inverse-distance
#      surface on one fixed 1 km BC Albers grid, with a flat-triangle layer;
#   2. each watershed group sampled once per layer set (wet_ws_sample(), area);
#   3. upstream means per first-level watershed code holding a calibration gauge
#      (wet_ws_fetch(), wet_upstream_irregular(), wet_upstream_means()), as
#      scripts/wb_province.R accumulates;
#   4. the period ratio at long-record natural HYDAT gauges (wet_station_select(),
#      wet_station_monthly());
#   5. scores and verdicts under the rule.
# Report: data/checks/runoff_products_compare_<release>.txt, byte-identical on a
# rerun from the caches. Connection from WET_PG*. It refuses an uncommitted file
# under `code_paths` (R/, scripts/, data-raw/, inst/vignette-data/, DESCRIPTION) or
# data/checks/, and records the last commit to `code_paths`.

source("scripts/wb_cv_lib.R")  # load_all(), cal, release, fit_dir, wb_hydat(), stamp(), score_code_md5
source("scripts/runoff_products_rule.R")

# ---- the rule as registered ------------------------------------------------------------------
rule_file <- "scripts/runoff_products_rule.R"
rule_commit <- "a5e867cfa56718631ff26dc478c843b4687cea45"
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
rule_md5 <- local({
  tmp <- tempfile()
  st <- system2("git", c("show", paste0(rule_commit, ":", rule_file)), stdout = tmp, stderr = FALSE)
  if (!identical(st, 0L)) stop("cannot read ", rule_file, " at the rule's registering commit ", rule_commit, call. = FALSE)
  reg <- unname(tools::md5sum(tmp))
  now <- unname(tools::md5sum(rule_file))
  if (!identical(reg, now)) {
    stop(rule_file, " differs from the rule's registering commit ", substr(rule_commit, 1, 8),
         ": an amendment is dated in the rule file and this commit moved with it", call. = FALSE)
  }
  now
})
if (release != rp_release) stop("the rule names HYDAT ", rp_release, ", not ", release, call. = FALSE)

# one set of paths: the clean-tree guard, the recorded commit and the report's label
code_paths <- c("R", "scripts", "data-raw", "inst/vignette-data", "DESCRIPTION")
dirty <- git("status", "--porcelain", "--", code_paths, "data/checks")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the report:\n",
                        paste(dirty, collapse = "\n"), call. = FALSE)
code_commit <- substr(git("log", "-1", "--format=%H", "--", code_paths), 1, 8)  # fixed length, as rule_commit

workers <- as.integer(commandArgs(trailingOnly = TRUE)[1])
if (is.na(workers)) workers <- 4L
root <- Sys.getenv("WET_DATA_ROOT", "data")
rp_dir <- file.path(root, "runoff_products")
raw_dir <- file.path(rp_dir, "raw")
log_dir <- file.path(root, "logs", "243")
for (d in c(raw_dir, log_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
report <- file.path("data", "checks", sprintf("runoff_products_compare_%s.txt", release))
md5 <- function(f) unname(tools::md5sum(f))
key_of <- function(...) substr(wet:::wet_md5_text(paste(c(...), collapse = "|")), 1, 10)
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}
pg <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 host = Sys.getenv("WET_PGHOST", "localhost"),
                 port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                 dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                 user = Sys.getenv("WET_PGUSER", "postgres"),
                 password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                 connect_timeout = 10)
}

# One logged GET: the time it was sent (UTC), the URL, the HTTP status, and the
# bytes and md5 kept. A non-200 answer keeps nothing and stops.
fetch_log <- file.path(log_dir, "runoff_products_fetch.tsv")
if (!file.exists(fetch_log)) writeLines("utc\turl\tstatus\tbytes\tmd5", fetch_log)
fetch <- function(url, dest, timeout = 1800) {
  part <- paste0(dest, ".part")
  on.exit(unlink(part), add = TRUE)
  sent <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  h <- curl::new_handle(followlocation = TRUE, timeout = timeout, useragent = "wet")
  res <- tryCatch(curl::curl_fetch_disk(url, part, handle = h), error = function(e) e)
  status <- if (inherits(res, "error")) paste("error:", conditionMessage(res)) else as.character(res$status_code)
  ok <- identical(status, "200")
  cat(paste(sent, url, status, if (ok) file.size(part) else "", if (ok) md5(part) else "", sep = "\t"),
      "\n", sep = "", file = fetch_log, append = TRUE)
  if (!ok) stop("GET ", url, " answered ", status, call. = FALSE)
  if (!file.rename(part, dest)) stop("could not move download to ", dest, call. = FALSE)
  invisible(dest)
}

# ---- gauges: observed, the held-out balance, routed PCIC --------------------------------------
cv <- readRDS(file.path(fit_dir, "cv_aet-cfu.rds"))
stopifnot(identical(cv$aet, "cfu"), identical(cv$release, release), identical(cv$code_md5, score_code_md5),
          identical(cv$station_number, cal$station_number))
f_bundle <- file.path("inst", "vignette-data", "monthly_values.rds")
mv <- readRDS(f_bundle)$gauges
stopifnot(nrow(mv) == 315 * 13, !anyDuplicated(mv[c("station_number", "month")]))
g0 <- mv[mv$month == 0, ]
i <- match(cv$station_number, g0$station_number)
stopifnot(nrow(g0) == 315, !anyNA(i), isTRUE(all.equal(g0$obs_mm[i], cv$obs)),
          isTRUE(all.equal(g0$wb_mm[i], cv$cv_ann)), identical(g0$zone[i], cv$zone),
          identical(g0$zone[i], cal$zone), identical(g0$lake[i], cal$lake %in% TRUE))
month_mat <- function(col) {
  m <- matrix(NA_real_, length(cv$station_number), 12)
  for (k in 1:12) {
    x <- mv[mv$month == k, ]
    m[, k] <- x[[col]][match(cv$station_number, x$station_number)]
  }
  m
}
g <- data.frame(station_number = cv$station_number, station_name = g0$station_name[i], zone = cv$zone,
                lake = cal$lake %in% TRUE, area_km2 = g0$area_km2[i],
                watershed_feature_id = cal$watershed_feature_id, wscode = cal$wscode,
                obs = cv$obs, bal = cv$cv_ann, routed = g0$routed_mm[i],
                ppt_tc = cal$ppt_tc, aet_tc = cal$aet_tc, p_yr = cal$p_yr, aet_cfu = cal$aet_cfu)
obs_m <- month_mat("obs_mm")
bal_m <- month_mat("wb_mm")
routed_m <- month_mat("routed_mm")
stopifnot(!anyNA(obs_m), !anyNA(bal_m), !anyNA(g[c("obs", "bal", "ppt_tc", "aet_tc", "p_yr", "aet_cfu")]))
# routed is scored where the gauge's segment carries at least a fifth of observed
# annual flow, the shared set of scripts/gauge_monthly_compare.R
g$shared <- !is.na(g$routed) & g$routed >= 0.2 * g$obs
stopifnot(sum(g$shared) == 283)

# ---- 1a. TerraClimate ------------------------------------------------------------------------
tc_url <- paste0("http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/",
                 "climatology/TerraClimate_19812010_q.nc")
f_tc <- file.path(raw_dir, basename(tc_url))
if (!file.exists(f_tc)) {
  stamp("fetching ", basename(f_tc))
  fetch(tc_url, f_tc)
}
tc_md5 <- md5(f_tc)
tc_ext <- c(-140, -113, 47, 61)   # BC with a margin, lon/lat
tc_key <- key_of(tc_md5, tc_ext)
f_tc_bc <- file.path(rp_dir, sprintf("tc_q_bc_%s.tif", tc_key))
if (!file.exists(f_tc_bc)) {
  r <- terra::rast(f_tc)
  vn <- unique(terra::varnames(r))
  if (!identical(vn, "q")) stop(basename(f_tc), " holds ", paste(vn, collapse = ", "), ", not q", call. = FALSE)
  if (terra::nlyr(r) != 12) stop(basename(f_tc), " has ", terra::nlyr(r), " layers, not 12", call. = FALSE)
  terra::crs(r) <- "EPSG:4326"  # the netCDF declares none (as wet_terraclimate_grid())
  r <- terra::crop(r, terra::ext(tc_ext), snap = "out")
  names(r) <- sprintf("q_%02d", 1:12)
  tmp <- tempfile(fileext = ".tif", tmpdir = rp_dir)
  terra::writeRaster(r, tmp, datatype = "FLT8S")
  if (!file.rename(tmp, f_tc_bc)) stop("could not move ", tmp, call. = FALSE)
}
tc <- terra::rast(f_tc_bc)
stopifnot(identical(names(tc), sprintf("q_%02d", 1:12)))
tc_res <- terra::res(tc)

# ---- 1b. Isolines ----------------------------------------------------------------------------
wfs <- paste0("https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0",
              "&typeName=pub:WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE")
f_hits <- file.path(raw_dir, "isolines_hits.xml")
f_lines <- file.path(raw_dir, "isolines.geojson")
if (!file.exists(f_hits)) fetch(paste0(wfs, "&request=GetFeature&resultType=hits"), f_hits, 300)
n_hits <- as.integer(sub('.*numberMatched="([0-9]+)".*', "\\1", paste(readLines(f_hits, warn = FALSE), collapse = "")))
stopifnot(!is.na(n_hits), n_hits > 0, n_hits < 10000)
if (!file.exists(f_lines)) {
  fetch(paste0(wfs, "&request=GetFeature&outputFormat=application/json&srsName=EPSG:3005&sortBy=OBJECTID",
               "&count=10000&propertyName=OBJECTID,ANNUAL_RUNOFF_IN_MM,GEOMETRY"), f_lines, 300)
}
lines_md5 <- md5(f_lines)
lines <- withCallingHandlers(sf::st_read(f_lines, quiet = TRUE),
                             warning = function(w) stop("reading ", f_lines, ": ", conditionMessage(w), call. = FALSE))
if (nrow(lines) != n_hits) stop(f_lines, " holds ", nrow(lines), " lines; the server reports ", n_hits, call. = FALSE)
lines <- sf::st_zm(lines)
if (is.na(sf::st_crs(lines)$epsg) || sf::st_crs(lines)$epsg != 3005) stop(f_lines, " is not in BC Albers", call. = FALSE)
lines <- lines[order(lines$OBJECTID), ]
lv <- as.numeric(lines$ANNUAL_RUNOFF_IN_MM)
stopifnot(!anyNA(lv), all(lv > 0), all(sf::st_is_valid(lines)))
levels_iso <- sort(unique(lv))
# lines of different levels that touch or cross give one point two values: refused
hit <- sf::st_intersects(lines)
clash <- do.call(rbind, lapply(seq_along(hit), function(a) {
  b <- hit[[a]][hit[[a]] > a]
  b <- b[lv[b] != lv[a]]
  if (length(b)) data.frame(a = lines$OBJECTID[a], b = lines$OBJECTID[b]) else NULL
}))
if (!is.null(clash)) {
  stop("isolines of different levels meet: ", paste(clash$a, clash$b, sep = "/", collapse = ", "), call. = FALSE)
}
densify_m <- 1000
grid_txe <- c(270000, 1880000)   # BC Albers, the FWA watershed groups' extent rounded out to 10 km
grid_tye <- c(1740000, 360000)   # north first, so the grid is north-up
grid_tr <- 1000
alg_tin <- "linear:radius=0:nodata=-9999"
alg_idw <- "invdistnn:power=2:radius=50000:max_points=12:nodata=-9999"
flat_tol <- 1e-3   # mm: a TIN cell this close to a level lies on a flat triangle
gdal_sf <- sf::sf_extSoftVersion()[["GDAL"]]
iso_key <- key_of(lines_md5, densify_m, grid_txe, grid_tye, grid_tr, alg_tin, alg_idw, flat_tol, gdal_sf)
f_iso <- file.path(rp_dir, sprintf("isolines_%s.tif", iso_key))
f_pts <- file.path(rp_dir, sprintf("isoline_points_%s.gpkg", iso_key))
seg <- sf::st_segmentize(lines["ANNUAL_RUNOFF_IN_MM"], densify_m)
sf::st_agr(seg) <- "constant"
pts <- sf::st_cast(sf::st_cast(seg, "MULTIPOINT"), "POINT")
xy <- sf::st_coordinates(pts)
pts <- data.frame(x = xy[, 1], y = xy[, 2], z = as.numeric(pts$ANNUAL_RUNOFF_IN_MM))
pts <- pts[!duplicated(pts), ]
if (anyDuplicated(pts[c("x", "y")])) stop("one isoline vertex carries two levels", call. = FALSE)
n_pts <- nrow(pts)
if (!file.exists(f_iso)) {
  stamp("gridding the isolines from ", n_pts, " points")
  pv <- sf::st_as_sf(pts, coords = c("x", "y"), crs = 3005)
  tmp_pts <- tempfile(fileext = ".gpkg", tmpdir = rp_dir)
  sf::st_write(pv, tmp_pts, layer = "pts", quiet = TRUE)
  file.rename(tmp_pts, f_pts)
  grid_one <- function(alg) {
    out <- tempfile(fileext = ".tif", tmpdir = rp_dir)
    sf::gdal_utils("grid", f_pts, out, options = c(
      "-l", "pts", "-zfield", "z", "-a", alg, "-txe", grid_txe, "-tye", grid_tye, "-tr", grid_tr, grid_tr,
      "-ot", "Float64", "-of", "GTiff", "-a_srs", "EPSG:3005"))
    if (!file.exists(out)) stop("gdal_grid wrote nothing for ", alg, call. = FALSE)
    r <- terra::rast(out)
    r <- terra::classify(r, cbind(-9999, NA))
    terra::values(r) <- terra::values(r)   # into memory before the temporary file goes
    unlink(out)
    r
  }
  tin <- grid_one(alg_tin)
  idw <- grid_one(alg_idw)
  stopifnot(terra::res(tin)[1] == grid_tr, terra::compareGeom(tin, idw),
            terra::ymax(tin) == grid_tye[1], terra::xmin(tin) == grid_txe[1])
  near <- Reduce(function(a, b) min(a, b), lapply(levels_iso, function(L) abs(tin - L)))
  flat <- terra::ifel(near < flat_tol, 1, 0)
  iso <- c(tin, idw, flat)
  names(iso) <- c("iso_tin", "iso_idw", "iso_flat")
  tmp <- tempfile(fileext = ".tif", tmpdir = rp_dir)
  terra::writeRaster(iso, tmp, datatype = "FLT8S")
  if (!file.rename(tmp, f_iso)) stop("could not move ", tmp, call. = FALSE)
}
iso <- terra::rast(f_iso)
stopifnot(identical(names(iso), c("iso_tin", "iso_idw", "iso_flat")))
iso_cells <- unlist(terra::global(!is.na(iso), "sum"))

# ---- 2. one sample per watershed group and layer set -----------------------------------------
sample_version <- "2"  # bump whenever sample_group() or upstream() changes what it stores
sample_code <- md5(file.path("R", c("wet_ws_sample.R", "wet_ws_fetch.R")))
# keyed on what each .tif holds, not on the key that named it
sets <- list(tc = list(file = f_tc_bc, key = key_of(md5(f_tc_bc), sample_code, sample_version), crs = "EPSG:4326"),
             iso = list(file = f_iso, key = key_of(md5(f_iso), sample_code, sample_version), crs = "EPSG:3005"))
for (s in names(sets)) {
  sets[[s]]$dir <- file.path(rp_dir, paste0("sample_", s), sets[[s]]$key)
  dir.create(sets[[s]]$dir, recursive = TRUE, showWarnings = FALSE)
}
conn <- pg()
codes <- sort(unique(sub("[.].*$", "", g$wscode)), method = "radix")
ws_by_code <- lapply(stats::setNames(codes, codes), function(code) wet_ws_fetch(conn, code))
need <- sort(unique(unlist(lapply(ws_by_code, function(w) unique(w$watershed_group_code)))), method = "radix")
ext_g <- DBI::dbGetQuery(conn, "
  SELECT watershed_group_code wsg,
         ST_XMin(a) axmin, ST_YMin(a) aymin, ST_XMax(a) axmax, ST_YMax(a) aymax,
         ST_XMin(l) lxmin, ST_YMin(l) lymin, ST_XMax(l) lxmax, ST_YMax(l) lymax
  FROM (SELECT watershed_group_code, ST_Extent(geom) a, ST_Extent(ST_Transform(geom, 4326)) l
        FROM whse_basemapping.fwa_watershed_groups_poly GROUP BY 1) x
  ORDER BY 1")
DBI::dbDisconnect(conn)
stopifnot(all(need %in% ext_g$wsg))
ext_g <- ext_g[ext_g$wsg %in% need, ]
stamp(length(codes), " first-level codes, ", nrow(ext_g), " watershed groups")

sample_group <- function(e, sets, pg) {
  terra::setGDALconfig("GDAL_CACHEMAX", "256")
  conn <- pg()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  ws <- NULL
  for (s in names(sets)) {
    f <- file.path(sets[[s]]$dir, paste0(e$wsg, ".rds"))
    if (file.exists(f)) next
    if (is.null(ws)) ws <- wet_ws_geom(conn, e$wsg)
    bb <- if (sets[[s]]$crs == "EPSG:4326") {
      terra::ext(e$lxmin - 0.1, e$lxmax + 0.1, e$lymin - 0.1, e$lymax + 0.1)
    } else {
      terra::ext(e$axmin - 2000, e$axmax + 2000, e$aymin - 2000, e$aymax + 2000)
    }
    r <- terra::crop(terra::rast(sets[[s]]$file), bb, snap = "out")
    w <- ws
    if (sets[[s]]$crs == "EPSG:3005") {
      # On a projected CRS terra 1.9.50's exact extract takes each cell's
      # ellipsoidal area, about 100 times slower than on lon/lat. BC Albers is
      # equal-area, so planar fractions are its area fractions: both are labelled
      # "local" (same coordinates) for the sample, a fresh copy of the polygons
      # so the other set's keep their CRS. Measured on SALR: fractions within
      # 1.1e-7 of the ellipsoidal ones (research/runoff_products.md).
      stopifnot(terra::same.crs(r, ws), terra::crs(r, describe = TRUE)$code == "3005")
      w <- wet_ws_geom(conn, e$wsg)
      terra::crs(r) <- "local"
      terra::crs(w) <- "local"
    }
    v <- wet_ws_sample(r, w, "area")
    tmp <- tempfile(fileext = ".rds", tmpdir = dirname(f))
    saveRDS(v, tmp)
    file.rename(tmp, f)
  }
  e$wsg
}
todo <- ext_g[!Reduce(`&`, lapply(sets, function(s) file.exists(file.path(s$dir, paste0(ext_g$wsg, ".rds"))))), ]
if (nrow(todo)) {
  stamp(nrow(todo), " groups to sample with ", workers, " workers")
  cl <- parallel::makePSOCKcluster(workers)
  here <- normalizePath(".")
  parallel::clusterCall(cl, function(p) {
    setwd(p)
    suppressMessages(devtools::load_all(quiet = TRUE))
    NULL
  }, here)
  todo <- todo[order(-(todo$axmax - todo$axmin) * (todo$aymax - todo$aymin)), ]
  done <- parallel::clusterApplyLB(cl, split(todo, seq_len(nrow(todo))), sample_group, sets = sets, pg = pg)
  parallel::stopCluster(cl)
  stopifnot(setequal(unlist(done), todo$wsg))
}
stamp("sampling done")

# ---- 3. upstream means per first-level code ---------------------------------------------------
up_code <- md5(file.path("R", c("wet_upstream_means.R", "wet_upstream_sums.R", "wet_ws_fetch.R")))
conn <- pg()
upstream <- function(s) {
  d <- file.path(rp_dir, paste0("upstream_", s), key_of(sets[[s]]$key, up_code))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  do.call(rbind, lapply(codes, function(code) {
    f <- file.path(d, paste0(code, ".rds"))
    if (!file.exists(f)) {
      ws <- ws_by_code[[code]]
      irr <- wet_upstream_irregular(conn, code)
      grp <- sort(unique(ws$watershed_group_code), method = "radix")
      vals <- do.call(rbind, lapply(grp, function(w) readRDS(file.path(sets[[s]]$dir, paste0(w, ".rds")))))
      vals <- vals[vals$watershed_feature_id %in% ws$watershed_feature_id, ]
      up <- wet_upstream_means(ws, vals, irregular_pairs = irr)
      save_atomic(up, f)
      stamp(s, " ", code, ": ", nrow(ws), " watersheds")
    }
    up <- readRDS(f)
    up[up$watershed_feature_id %in% g$watershed_feature_id, ]
  }))
}
up_tc <- upstream("tc")
up_iso <- upstream("iso")
DBI::dbDisconnect(conn)
it <- match(g$watershed_feature_id, up_tc$watershed_feature_id)
ii <- match(g$watershed_feature_id, up_iso$watershed_feature_id)
stopifnot(!anyNA(it), !anyNA(ii))
tc_m <- as.matrix(up_tc[it, sprintf("q_%02d", 1:12)])
dimnames(tc_m) <- NULL
g$tc_cov <- up_tc$coverage[it]
g$q_ann <- rowSums(tc_m)
g$iso_cov <- up_iso$coverage[ii]
g$tin <- up_iso$iso_tin[ii]
g$idw <- up_iso$iso_idw[ii]
g$flat <- up_iso$iso_flat[ii]
g$area_fwa_km2 <- up_tc$upstream_area_m2[it] / 1e6
stopifnot(isTRUE(all.equal(g$area_fwa_km2, g$area_km2)))

# ---- 4. the period ratio ---------------------------------------------------------------------
hy <- wb_hydat(release)
period_sel <- function(years) wet_station_select(hy, years = years, min_years = rp_period_years)
s61 <- period_sel(1961:1990)
s81 <- period_sel(1981:2010)
both <- sort(intersect(s61$station_number, s81$station_number), method = "radix")
annual_q <- function(s) {
  k <- s[s$station_number %in% both, ]
  attr(k, "years") <- attr(s, "years")[k$station_number]
  m <- wet_station_monthly(k, hy)
  m <- m[m$month == 0, ]
  m$q_m3s[match(both, m$station_number)]
}
pg_st <- s81[match(both, s81$station_number), c("station_number", "station_name", "lon", "lat")]
pg_st$n61 <- s61$n_years[match(both, s61$station_number)]
pg_st$n81 <- s81$n_years[match(both, s81$station_number)]
pg_st$ratio <- annual_q(s81) / annual_q(s61)
stopifnot(!anyNA(pg_st$ratio), all(pg_st$ratio > 0))
hz_zip <- file.path("data", "hydz", "bc_hydrologic_zones.zip")
if (!file.exists(hz_zip)) stop(hz_zip, " is missing: run scripts/wb_inputs.R, which caches it", call. = FALSE)
hz_src <- tempfile("hydz")
utils::unzip(hz_zip, exdir = hz_src)
hz <- terra::vect(list.files(hz_src, "[.]shp$", full.names = TRUE, recursive = TRUE))
zp <- terra::extract(hz, terra::project(terra::vect(pg_st, geom = c("lon", "lat"), crs = "EPSG:4326"), terra::crs(hz)))
zp <- zp[!duplicated(zp$id.y), ]
stopifnot(nrow(zp) == nrow(pg_st), all(zp$id.y == seq_len(nrow(pg_st))))
pg_st$zone <- ifelse(is.na(zp$HYDZN_NO), NA_character_, sprintf("%02d", as.integer(zp$HYDZN_NO)))
zone_ratio <- function(z) rp_period_ratio(pg_st$ratio[pg_st$zone %in% z])
prov_ratio <- rp_period_ratio(pg_st$ratio)

# ---- 5. scores -------------------------------------------------------------------------------
g$err_b <- rp_error(g$bal, g$obs)
g$err_r <- ifelse(g$shared, 100 * (g$routed / g$obs - 1), NA_real_)
g$tc_ok <- g$tc_cov >= rp_coverage
g$iso_ok <- g$iso_cov >= rp_coverage
g$err_tc <- ifelse(g$tc_ok, 100 * (g$q_ann / g$obs - 1), NA_real_)
g$err_tin <- ifelse(g$iso_ok, 100 * (g$tin / g$obs - 1), NA_real_)
g$err_idw <- ifelse(g$iso_ok, 100 * (g$idw / g$obs - 1), NA_real_)
g <- g[order(g$zone, g$station_number, method = "radix"), ]
tc_m <- tc_m[match(g$station_number, cv$station_number), ]
obs_m <- obs_m[match(g$station_number, cv$station_number), ]
bal_m <- bal_m[match(g$station_number, cv$station_number), ]
routed_m <- routed_m[match(g$station_number, cv$station_number), ]

# the plumbing check: TerraClimate's runoff against the province run's
# ppt_tc - aet_tc (bilinear on the 30" grid, filled where TerraClimate is empty)
g$wb_tc <- g$ppt_tc - g$aet_tc
full <- g$tc_cov >= 1 - 1e-9
if (any(g$wb_tc[full] <= 0)) stop("ppt_tc - aet_tc is not above 0 at a fully covered gauge", call. = FALSE)
plumb <- 100 * abs(g$q_ann - g$wb_tc) / g$wb_tc
plumb_full <- stats::median(plumb[full])
plumb_rest <- stats::median(plumb[!full & g$wb_tc > 0])
if (plumb_full > rp_plumbing) {
  stop(sprintf("TerraClimate runoff differs from ppt_tc - aet_tc by a median %.1f %% at %d fully covered gauges: a sampling fault",
               plumb_full, sum(full)), call. = FALSE)
}

# TerraClimate's gap to the balance in four terms that sum to it
g$t_p <- g$ppt_tc - g$p_yr
g$t_a <- -(g$aet_tc - g$aet_cfu)
g$t_s <- g$q_ann - g$wb_tc
g$t_z <- -(g$bal - (g$p_yr - g$aet_cfu))
g$gap <- g$q_ann - g$bal
stopifnot(all(abs(g$t_p + g$t_a + g$t_s + g$t_z - g$gap) <= 1e-8 * pmax(1, abs(g$gap))))

# verdicts
strip <- function(v) sub("^unstable [(](.*)[)]$", "\\1", v)
judge_set <- function(d, z) {
  pr <- if (is.null(z)) prov_ratio else zone_ratio(z)
  per <- function(mod, obs) if (is.na(pr)) NA else rp_error(mod * pr, obs)
  chk <- !is.null(z)
  dt <- d[d$tc_ok, ]
  di <- d[d$iso_ok, ]
  v_tc <- rp_judge(dt$err_tc, dt$err_b, check_n = chk)
  v_tin <- rp_judge(di$err_tin, di$err_b, if (nrow(di)) per(di$tin, di$obs) else NULL, check_n = chk)
  v_idw <- rp_judge(di$err_idw, di$err_b, if (nrow(di)) per(di$idw, di$obs) else NULL, check_n = chk)
  if (v_tin != v_idw) v_tin <- paste0(v_tin, ", surface-dependent")
  data.frame(zone = if (is.null(z)) "BC" else z, ratio = pr,
             n_tc = nrow(dt), tc = med(dt$err_tc), b_tc = med(dt$err_b), v_tc = v_tc,
             n_iso = nrow(di), tin = med(di$err_tin), idw = med(di$err_idw), b_iso = med(di$err_b),
             tin_period = if (nrow(di) && !is.na(pr)) med(per(di$tin, di$obs)) else NA_real_,
             v_tin = v_tin, v_idw = v_idw)
}
med <- function(x) if (length(x)) stats::median(x) else NA_real_
zones <- sort(unique(g$zone), method = "radix")
vd <- rbind(judge_set(g, NULL), do.call(rbind, lapply(zones, function(z) judge_set(g[g$zone == z, ], z))))

# ---- report ----------------------------------------------------------------------------------
out <- character()
say <- function(...) out <<- c(out, ...)
f1 <- function(x) ifelse(is.na(x), "     -", sprintf("%+6.1f", x))
fq <- function(x) if (length(x)) sprintf("%+6.1f [%+6.1f, %+6.1f]", stats::median(x),
                                         stats::quantile(x, 0.25, names = FALSE), stats::quantile(x, 0.75, names = FALSE)) else "                       -"
fw <- function(x) if (length(x)) sprintf("%3.0f %%", 100 * mean(rp_inside(x))) else "    -"
nse_med <- function(obs, mod, rows) {
  if (!any(rows)) return(NA_real_)
  stats::median(vapply(which(rows), function(k) wet:::wet_nse(obs[k, ], mod[k, ]), 0))
}
shares <- function(m) m / rowSums(m)

say(sprintf("# TerraClimate runoff and the 1961-1990 runoff isolines at the calibration gauges (#243, #225), HYDAT %s", release),
    "",
    "The rule: scripts/runoff_products_rule.R, registered before this script or any product value existed.",
    sprintf("Rule commit %s, md5 %s. Code commit %s (the last commit to %s).",
            substr(rule_commit, 1, 8), rule_md5, code_commit, paste(code_paths, collapse = ", ")),
    sprintf("Fit: cv_aet-cfu.rds under scoring md5 %s; gauges and routed PCIC from %s (md5 %s), held equal to the fit.",
            substr(score_code_md5, 1, 8), f_bundle, md5(f_bundle)),
    "Both products are references here, never inputs. Error is modelled over observed, in %; within is |error| <= 20 %.",
    "",
    "## 1. Inputs",
    "",
    sprintf("TerraClimate: %s, md5 %s; variable q, 12 layers, read at its own %.6f x %.6f degree lattice, cropped to lon %g to %g, lat %g to %g.",
            tc_url, tc_md5, tc_res[1], tc_res[2], tc_ext[1], tc_ext[2], tc_ext[3], tc_ext[4]),
    sprintf("Isolines: WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE (OGL-BC), %d lines (the server's numberMatched %d), md5 %s.",
            nrow(lines), n_hits, lines_md5),
    sprintf("  levels (mm): %s", paste(sprintf("%g x%d", as.numeric(names(table(lv))), as.integer(table(lv))), collapse = ", ")),
    "  no two lines of different levels touch or cross.",
    sprintf("  densified to %d m: %d points. Gridded by sf's GDAL %s on BC Albers, %d m cells, x %d to %d, y %d to %d:",
            as.integer(densify_m), n_pts, gdal_sf, as.integer(grid_tr), as.integer(grid_txe[1]), as.integer(grid_txe[2]),
            as.integer(grid_tye[2]), as.integer(grid_tye[1])),
    sprintf("  TIN -a %s; inverse distance -a %s.", alg_tin, alg_idw),
    sprintf("  cells with a value: TIN %d, inverse distance %d; flat-triangle cells (TIN within %g mm of a level) %d.",
            iso_cells[[1]], iso_cells[[2]], flat_tol, sum(terra::values(iso[["iso_flat"]]) == 1, na.rm = TRUE)),
    sprintf("Samples: TerraClimate %s, isolines %s, over %d watershed groups; upstream means over %d first-level codes: %s.",
            sets$tc$key, sets$iso$key, nrow(ext_g), length(codes), paste(codes, collapse = " ")),
    "",
    "## 2. Gauges each product scores",
    "",
    sprintf("315 calibration gauges (%d lake outlets); routed PCIC's shared set 283. A product is scored where it covers at least %.0f %% of the basin.",
            sum(g$lake), 100 * rp_coverage),
    sprintf("TerraClimate scores %d; isolines (both surfaces) %d.", sum(g$tc_ok), sum(g$iso_ok)),
    "",
    "Not scored, with each product's coverage and the reason, which is the only way a cell has no value: for TerraClimate, a cell the file leaves empty;",
    "for the isolines, a cell beyond the TIN's triangulation or more than 50 km from an isoline vertex. The lake-outlet flag is shown beside, not tested.",
    "")
nd <- g[!g$tc_ok | !g$iso_ok, ]
nd$reason <- ifelse(!nd$tc_ok & !nd$iso_ok, "both: empty TerraClimate cells; beyond the isolines' surfaces",
                    ifelse(!nd$tc_ok, "TerraClimate: empty cells", "isolines: beyond the surfaces"))
say(sprintf("%-8s %-4s %-5s %8s %8s  %-36s %s", "station", "zone", "lake", "tc_cov", "iso_cov", "name", "reason"),
    sprintf("%-8s %-4s %-5s %8.3f %8.3f  %-36s %s", nd$station_number, nd$zone, ifelse(nd$lake, "yes", "no"),
            nd$tc_cov, nd$iso_cov, nd$station_name, nd$reason), "")
say("By zone: gauges, TerraClimate not scored, isolines not scored",
    sprintf("  zone %s: %3d gauges, TerraClimate %2d, isolines %2d", zones,
            vapply(zones, function(z) sum(g$zone == z), 1L),
            vapply(zones, function(z) sum(g$zone == z & !g$tc_ok), 1L),
            vapply(zones, function(z) sum(g$zone == z & !g$iso_ok), 1L)), "")

say("## 3. Plumbing check: TerraClimate's runoff against the province run's ppt_tc - aet_tc",
    "",
    sprintf("Median |q - (ppt_tc - aet_tc)| / (ppt_tc - aet_tc): %.2f %% at the %d gauges TerraClimate covers fully (bound %g %%: passed); %.2f %% at the other %d.",
            plumb_full, sum(full), rp_plumbing, plumb_rest, sum(!full)),
    "ppt_tc and aet_tc are bilinear on the 30\" grid and filled from climr and CGIAR where TerraClimate is empty, so only full cover tests the sampling.",
    "")

score_rows <- function(d, label, star_tc = FALSE, star_iso = FALSE) {
  dt <- d[d$tc_ok, ]
  di <- d[d$iso_ok, ]
  lt <- paste0(label, if (star_tc) "*" else "")
  li <- paste0(label, if (star_iso) "*" else "")
  c(sprintf("%-4s TerraClimate n %3d  %s %s | balance %s %s | routed n %3d %s %s", lt, nrow(dt), fq(dt$err_tc), fw(dt$err_tc),
            fq(dt$err_b), fw(dt$err_b), sum(dt$shared), fq(dt$err_r[dt$shared]), fw(dt$err_r[dt$shared])),
    sprintf("%-4s isolines TIN  n %3d  %s %s | balance %s %s | routed n %3d %s %s", li, nrow(di), fq(di$err_tin), fw(di$err_tin),
            fq(di$err_b), fw(di$err_b), sum(di$shared), fq(di$err_r[di$shared]), fw(di$err_r[di$shared])),
    sprintf("%-4s isolines IDW  n %3d  %s %s", li, nrow(di), fq(di$err_idw), fw(di$err_idw)))
}
say("## 4. Annual error, % (median [middle half], share within +-20 %), each beside the balance and routed PCIC at the same gauges",
    "",
    "Routed PCIC over those gauges that are also among its 283 shared gauges. A row whose product scores fewer than 5 gauges in its zone is marked * and not read.",
    "",
    score_rows(g, "BC"), "")
for (z in zones) {
  d <- g[g$zone == z, ]
  say(score_rows(d, z, star_tc = sum(d$tc_ok) < rp_min_gauges, star_iso = sum(d$iso_ok) < rp_min_gauges))
}
say("")

say("## 5. TerraClimate's months: median per-gauge NSE (monthly runoff) and share NSE (twelve monthly shares)",
    "",
    sprintf("At the %d gauges TerraClimate scores: TerraClimate monthly %.2f, share %.2f; balance monthly %.2f, share %.2f.",
            sum(g$tc_ok), nse_med(obs_m, tc_m, g$tc_ok), nse_med(shares(obs_m), shares(tc_m), g$tc_ok),
            nse_med(obs_m, bal_m, g$tc_ok), nse_med(shares(obs_m), shares(bal_m), g$tc_ok)),
    sprintf("At the %d of them in routed PCIC's shared set: TerraClimate monthly %.2f, share %.2f; balance %.2f, %.2f; routed PCIC %.2f, %.2f.",
            sum(g$tc_ok & g$shared), nse_med(obs_m, tc_m, g$tc_ok & g$shared),
            nse_med(shares(obs_m), shares(tc_m), g$tc_ok & g$shared),
            nse_med(obs_m, bal_m, g$tc_ok & g$shared), nse_med(shares(obs_m), shares(bal_m), g$tc_ok & g$shared),
            nse_med(obs_m, routed_m, g$tc_ok & g$shared), nse_med(shares(obs_m), shares(routed_m), g$tc_ok & g$shared)),
    "")

di <- g[g$iso_ok, ]
spread <- 100 * (di$idw - di$tin) / di$tin
say("## 6. The isolines: TIN against inverse distance, and the flat-triangle share",
    "",
    sprintf("Inverse distance over TIN, %% at the %d scored gauges: median %+.1f, middle half %+.1f to %+.1f, largest |difference| %.1f.",
            nrow(di), stats::median(spread), stats::quantile(spread, 0.25, names = FALSE),
            stats::quantile(spread, 0.75, names = FALSE), max(abs(spread))),
    sprintf("Share of basin area on flat triangles: median %.2f; %d gauges above 0.5. Both surfaces share that bias; their spread cannot show it.",
            stats::median(di$flat), sum(di$flat > 0.5)),
    "The isolines were drawn from Water Survey of Canada gauges, so they are not independent of the gauges they are scored at.",
    "",
    sprintf("%-4s %3s %12s %12s", "zone", "n", "IDW-TIN %", "flat share"),
    vapply(zones, function(z) {
      k <- di$zone == z
      if (!any(k)) return(sprintf("%-4s %3d %12s %12s", z, 0L, "-", "-"))
      sprintf("%-4s %3d %+12.1f %12.2f", z, sum(k), stats::median(spread[k]), stats::median(di$flat[k]))
    }, ""), "")

say("## 7. The period: 1981-2010 over 1961-1990 mean annual flow at long-record natural HYDAT gauges",
    "",
    sprintf("%d natural BC gauges with at least %d complete years in each period; province-wide ratio %.3f. A zone needs %d for a ratio.",
            nrow(pg_st), rp_period_years, prov_ratio, rp_period_min),
    sprintf("  zone %s: %2d gauges, ratio %s", sort(unique(c(zones, stats::na.omit(pg_st$zone))), method = "radix"),
            vapply(sort(unique(c(zones, stats::na.omit(pg_st$zone))), method = "radix"), function(z) sum(pg_st$zone %in% z), 1L),
            vapply(sort(unique(c(zones, stats::na.omit(pg_st$zone))), method = "radix"), function(z) {
              r <- zone_ratio(z)
              if (is.na(r)) "     -" else sprintf("%6.3f", r)
            }, "")),
    sprintf("  outside every zone polygon: %d gauges.", sum(is.na(pg_st$zone))),
    "")

say("## 8. Verdicts (median annual error, %, product and balance over the product's scored gauges)",
    "",
    sprintf("%-4s %3s %7s %7s  %-28s | %3s %7s %7s %7s %7s  %-44s %s", "zone", "n", "TC", "bal", "TerraClimate",
            "n", "TIN", "IDW", "bal", "period", "isolines (TIN)", "isolines (IDW)"),
    sprintf("%-4s %3d %s %s  %-28s | %3d %s %s %s %s  %-44s %s", vd$zone, vd$n_tc, f1(vd$tc), f1(vd$b_tc), vd$v_tc,
            vd$n_iso, f1(vd$tin), f1(vd$idw), f1(vd$b_iso), f1(vd$tin_period), vd$v_tin, vd$v_idw),
    "",
    "period: the TIN's median error with its values multiplied by the zone's period ratio (section 7).",
    "")

material <- function(v) !strip(sub(", surface-dependent$", "", v)) %in% c("not material", "too few")
say("## 9. Evidence for each material disagreement",
    "")
mt <- vd[material(vd$v_tc), ]
if (nrow(mt)) {
  say("TerraClimate: its gap to the balance (q - cv_ann), median mm over the zone's scored gauges, in four terms that sum to it at every gauge:",
      "precipitation ppt_tc - p_yr; AET -(aet_tc - aet_cfu); TerraClimate's storage and fill q - (ppt_tc - aet_tc); the zone adjustment -(cv_ann - (p_yr - aet_cfu)).",
      "Each column is that term's median, so the four sum to the gap at every gauge but their medians need not sum to the gap's median.",
      "TerraClimate uses no gauge.",
      sprintf("%-4s %-28s %7s %7s %7s %7s %7s", "zone", "verdict", "gap", "P", "AET", "storage", "zone adj"))
  for (k in seq_len(nrow(mt))) {
    d <- if (mt$zone[k] == "BC") g[g$tc_ok, ] else g[g$tc_ok & g$zone == mt$zone[k], ]
    say(sprintf("%-4s %-28s %+7.0f %+7.0f %+7.0f %+7.0f %+7.0f", mt$zone[k], mt$v_tc[k], stats::median(d$gap),
                stats::median(d$t_p), stats::median(d$t_a), stats::median(d$t_s), stats::median(d$t_z)))
  }
  say("")
} else {
  say("TerraClimate: no material disagreement.", "")
}
mi <- vd[material(vd$v_tin), ]
if (nrow(mi)) {
  say("Isolines: drawn from Water Survey of Canada gauges, for 1961-1990; the period ratio and the period-scaled median are in sections 7 and 8.",
      sprintf("%-4s %-44s %7s %7s %7s %7s", "zone", "verdict", "TIN", "bal", "ratio", "period"),
      sprintf("%-4s %-44s %s %s %s %s", mi$zone, mi$v_tin, f1(mi$tin), f1(mi$b_iso),
              ifelse(is.na(mi$ratio), "      -", sprintf("%7.3f", mi$ratio)), f1(mi$tin_period)), "")
} else {
  say("Isolines: no material disagreement.", "")
}

say("## 10. Per gauge (annual mm; errors in %)",
    "",
    sprintf("%-8s %-4s %7s %6s %6s %7s %6s %6s %6s %6s %5s %6s %6s", "station", "zone", "obs", "bal", "routed",
            "tc_mm", "tc", "tin", "idw", "flat", "lake", "tc_cv", "iso_cv"),
    sprintf("%-8s %-4s %7.0f %s %s %7.0f %s %s %s %6.2f %5s %6.3f %6.3f", g$station_number, g$zone, g$obs, f1(g$err_b),
            f1(g$err_r), g$q_ann, f1(g$err_tc), f1(g$err_tin), f1(g$err_idw), g$flat, ifelse(g$lake, "yes", "no"),
            g$tc_cov, g$iso_cov))

writeLines(out, report)
stamp("wrote ", report)
