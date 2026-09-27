# Province topology, sampling and upstream accumulation for the open water
# balance (#11, Phase 3).
#
#   caffeinate -i Rscript scripts/wb_province.R [WORKERS]   # default 4
#
# Reads the Phase 1 inputs (scripts/wb_inputs.R) and writes, keyed on those
# inputs (gitignored):
#   data/wb/<key>/sample/<WSG>.rds   per-polygon layer means and cover
#   data/wb/<key>/upstream/<CODE>.rds upstream means for every watershed
# The run log (stdout/stderr, e.g. data/wb/province_run.log) is gitignored;
# scripts/wb_validate.R's report is the tracked record.
# Connection from WET_PG* env vars.

devtools::load_all(quiet = TRUE)
workers <- as.integer(commandArgs(trailingOnly = TRUE)[1])
if (is.na(workers)) workers <- 4L
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
pg <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 host = Sys.getenv("WET_PGHOST", "localhost"),
                 port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                 dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                 user = Sys.getenv("WET_PGUSER", "postgres"),
                 password = Sys.getenv("WET_PGPASSWORD", "postgres"))
}
one <- function(d, pattern) {
  f <- list.files(d, pattern, full.names = TRUE)
  if (length(f) != 1) stop("expected one ", pattern, " in ", d, ", found ", length(f))
  f
}
f_in <- c(aet = one("data/cgiar", "^cgiar_aet_c.*\\.tif$"), clim = one("data/climr", "^climr_.*\\.tif$"),
          dem = one("data/dem", "^glo90v3_.*\\.tif$"), hz = one("data/hydz", "^hydz_.*\\.tif$"))
# Each input's name already encodes its content; the key adds this script's
# own md5 and that of every package file it calls, so a code change never
# reuses old samples.
code_md5 <- unname(tools::md5sum(c("scripts/wb_province.R", "R/wet_ws_sample.R", "R/wet_upstream_means.R",
                                   "R/wet_upstream_sums.R", "R/wet_ws_fetch.R", "R/wet_climr_normals.R")))
key <- substr(wet:::wet_md5_text(paste(c(basename(f_in), code_md5), collapse = "|")), 1, 10)
out_dir <- file.path("data", "wb", key)
dir.create(file.path(out_dir, "sample"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out_dir, "upstream"), recursive = TRUE, showWarnings = FALSE)
stamp("run key ", key)

# ---- derived layers, on the input grid ------------------------------------------------
lay_file <- file.path(out_dir, "layers.tif")
if (!file.exists(lay_file)) {
  aet <- terra::rast(f_in[["aet"]])
  cl <- terra::rast(f_in[["clim"]])
  dem <- terra::rast(f_in[["dem"]])
  hz <- terra::rast(f_in[["hz"]])
  stopifnot(terra::compareGeom(aet, cl, dem, hz))
  p_yr <- sum(cl[[sprintf("PPT_%02d", 1:12)]])
  t_yr <- terra::mean(cl[[sprintf("Tave_%02d", 1:12)]])
  xy <- terra::project(terra::vect(terra::crds(aet[[1]], na.rm = FALSE), crs = "EPSG:4326"), "EPSG:3005")
  en <- terra::crds(xy)
  e_km <- aet[[1]]
  terra::values(e_km) <- en[, 1] / 1000
  n_km <- aet[[1]]
  terra::values(n_km) <- en[, 2] / 1000
  lay <- c(p_yr, aet[["aet_yr"]], p_yr - aet[["aet_yr"]], t_yr, dem, e_km, n_km,
           cl[[sprintf("PPT_%02d", 1:12)]], cl[[sprintf("Tave_%02d", 1:12)]],
           aet[[sprintf("aet_%02d", 1:12)]], hz)
  names(lay) <- c("p_yr", "aet_yr", "ro_raw", "t_yr", "elev", "e_km", "n_km",
                  sprintf("ppt_%02d", 1:12), sprintf("tave_%02d", 1:12), sprintf("aet_%02d", 1:12), "zone")
  # one analysis mask: a cell counts only where every layer has a value
  lay <- terra::mask(lay, sum(is.na(lay)) > 0, maskvalues = TRUE)
  tmp <- tempfile(fileext = ".tif", tmpdir = out_dir)
  terra::writeRaster(lay, tmp, datatype = "FLT4S")
  file.rename(tmp, lay_file)
}
stamp("layers ", lay_file)

# in-BC indicator, over whole polygons (not masked)
bc_file <- file.path(out_dir, "in_bc.tif")
if (!file.exists(bc_file)) {
  conn <- pg()
  wkt <- DBI::dbGetQuery(conn, "SELECT ST_AsText(geom) wkt FROM whse_basemapping.fwa_bcboundary")$wkt
  DBI::dbDisconnect(conn)
  g <- terra::rast(lay_file)[[1]]
  # stored as ~28,000 subdivided pieces: dissolve first, so a cell split
  # between pieces gets its whole cover
  bc <- terra::project(terra::aggregate(terra::vect(wkt, crs = "EPSG:3005")), "EPSG:4326")
  inbc <- terra::rasterize(bc, g, cover = TRUE, background = 0)
  tmp <- tempfile(fileext = ".tif", tmpdir = out_dir)
  terra::writeRaster(inbc, tmp, datatype = "FLT4S")
  file.rename(tmp, bc_file)
}

# ---- sampling, one watershed group at a time, in parallel --------------------------------
conn <- pg()
groups <- DBI::dbGetQuery(conn, "
  SELECT watershed_group_code wsg,
         ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT watershed_group_code, ST_Extent(ST_Transform(geom, 4326)) e
        FROM whse_basemapping.fwa_watershed_groups_poly GROUP BY 1) x
  ORDER BY 1")
DBI::dbDisconnect(conn)
# WET_WB_GROUPS="BULK,SALR" samples only those groups and stops before the
# accumulation: a smoke test that finds a bug in minutes, not an hour in.
only <- strsplit(Sys.getenv("WET_WB_GROUPS"), ",")[[1]]
if (length(only)) groups <- groups[groups$wsg %in% only, ]
todo <- groups[!file.exists(file.path(out_dir, "sample", paste0(groups$wsg, ".rds"))), ]
stamp(nrow(groups), " groups, ", nrow(todo), " to sample with ", workers, " workers")

sample_group <- function(g, lay_file, bc_file, out_dir, pg) {
  terra::setGDALconfig("GDAL_CACHEMAX", "256")
  conn <- pg()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  t0 <- Sys.time()
  ws <- wet_ws_geom(conn, g$wsg)
  e <- terra::ext(g$xmin - 0.05, g$xmax + 0.05, g$ymin - 0.05, g$ymax + 0.05)
  lay <- terra::crop(terra::rast(lay_file), e, snap = "out")
  zones <- sort(unique(stats::na.omit(terra::values(lay[["zone"]], mat = FALSE))))
  base <- lay[[setdiff(names(lay), "zone")]]
  zl <- lapply(zones, function(z) {
    i <- terra::ifel(lay[["zone"]] == z, 1, 0)
    x <- c(i, i * lay[["p_yr"]])
    names(x) <- c(sprintf("z%02d", z), sprintf("zp%02d", z))
    x
  })
  st <- if (length(zl)) c(base, terra::rast(zl)) else base
  v <- wet_ws_sample(st, ws, "area")
  inbc <- wet_ws_sample(terra::crop(terra::rast(bc_file), e, snap = "out"), ws, "area")
  v$in_bc <- inbc$value
  v$watershed_group_code <- g$wsg
  f <- file.path(out_dir, "sample", paste0(g$wsg, ".rds"))
  tmp <- tempfile(fileext = ".rds", tmpdir = dirname(f))
  saveRDS(v, tmp)
  file.rename(tmp, f)
  sprintf("%s %d polygons %.0f s", g$wsg, nrow(ws), as.numeric(Sys.time() - t0, units = "secs"))
}

if (nrow(todo)) {
  cl <- parallel::makePSOCKcluster(workers)
  here <- normalizePath(".")
  parallel::clusterCall(cl, function(p) {
    setwd(p)
    suppressMessages(devtools::load_all(quiet = TRUE))
    NULL
  }, here)
  # largest groups first, so the tail is short
  todo <- todo[order(-(todo$xmax - todo$xmin) * (todo$ymax - todo$ymin)), ]
  msgs <- parallel::clusterApplyLB(cl, split(todo, seq_len(nrow(todo))), sample_group,
                                   lay_file = lay_file, bc_file = bc_file, out_dir = out_dir, pg = pg)
  parallel::stopCluster(cl)
  writeLines(unlist(msgs), file.path(out_dir, "sample_times.txt"))
}
stamp("sampling done")
if (length(only)) {
  stamp("WET_WB_GROUPS set: stopping before accumulation")
  quit(save = "no")
}

# ---- accumulation, one top-level basin at a time ---------------------------------------------
conn <- pg()
codes <- DBI::dbGetQuery(conn, "
  SELECT DISTINCT subltree(wscode_ltree, 0, 1)::text AS code
  FROM whse_basemapping.fwa_watersheds_poly WHERE nlevel(wscode_ltree) > 0 ORDER BY 1")$code
smp <- NULL
for (code in codes) {
  f <- file.path(out_dir, "upstream", paste0(code, ".rds"))
  if (file.exists(f)) next
  t0 <- Sys.time()
  ws <- wet_ws_fetch(conn, code)
  irr <- wet_upstream_irregular(conn, code)
  need <- unique(ws$watershed_group_code)
  vals <- lapply(need, function(g) readRDS(file.path(out_dir, "sample", paste0(g, ".rds"))))
  cols <- unique(unlist(lapply(vals, names)))
  vals <- do.call(rbind, lapply(vals, function(v) {
    for (k in setdiff(cols, names(v))) v[[k]] <- 0  # a zone absent from a group has share 0
    v[, cols]
  }))
  vals <- vals[vals$watershed_feature_id %in% ws$watershed_feature_id, ]
  ws$in_bc <- vals$in_bc[match(ws$watershed_feature_id, vals$watershed_feature_id)]
  ws$in_bc[is.na(ws$in_bc)] <- 0
  keep <- setdiff(cols, c("in_bc", "watershed_group_code"))
  up <- wet_upstream_means(ws, vals[, keep], irregular_pairs = irr, extra = "in_bc")
  names(up)[names(up) == "in_bc"] <- "bc_fraction"
  up$wscode <- ws$wscode
  up$localcode <- ws$localcode
  up$area_m2 <- ws$area_m2
  tmp <- tempfile(fileext = ".rds", tmpdir = dirname(f))
  saveRDS(up, tmp)
  file.rename(tmp, f)
  stamp(code, ": ", nrow(ws), " watersheds in ", round(as.numeric(Sys.time() - t0, units = "secs")), " s")
}
DBI::dbDisconnect(conn)
# the marker later scripts require: every basin accumulated
if (all(file.exists(file.path(out_dir, "upstream", paste0(codes, ".rds"))))) {
  writeLines(codes, file.path(out_dir, "upstream", "_complete"))
}
stamp("accumulation done")
