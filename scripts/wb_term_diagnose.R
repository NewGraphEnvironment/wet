# Which term is off in the dry interior (#45): our P (climr) and AET (cfu)
# against PCIC VIC-GL's PREC and EVAP, at the calibration gauges of the
# shipped fit, under the attribution rule pre-registered in the #45 findings
# ("Pre-registered attribution rule" and "Amendment 1"; archived with #45)
# before any PCIC value was computed.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_term_diagnose.R
#
# PCIC is a reference here, never an input (CLAUDE.md, "Own estimates first").
# Stages, each cached under data/wb_term/ (gitignored):
#   1. PCIC PREC, EVAP, RUNOFF, BASEFLOW, PET_NATVEG, 1981-2010 mean annual per
#      cell, for each FWA basin PCIC models (300 Columbia, 100 Fraser, 200
#      Peace), fetched one year at a time (wet_pcic_annual(), cached in
#      data/pcic/; a failed year is retried, and a rerun resumes from the cache);
#   2. area-weighted per fundamental watershed and upstream means over each
#      basin, all layers on one cover (wet_ws_sample(), wet_upstream_means());
#   3. climr against ECCC 1981-2010 normals at every BC station (any normal
#      code), by hydrologic zone: corroboration (ii') of the rule.
# Report: data/checks/wb_term_diagnose_<release>.txt (tracked, wb_report()). Connection from WET_PG*.

source("scripts/wb_cv_lib.R")  # cal: the shipped fit's calibration gauges
years <- 1981:2010
basins <- c("300", "100", "200")  # dry zones first; the Peace is contrast only
dry <- c("15", "17", "23", "24")
min_cover <- 0.95
min_basins <- 4
omega_max <- 5
out_dir <- file.path("data", "wb_term")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
vars <- c(p_c = "PREC", e_c = "EVAP", ro_c = "RUNOFF", bf_c = "BASEFLOW", pet_c = "PET_NATVEG")
pcic_run <- "TPS_gridded_obs_init"
# Every cache is named for everything its content depends on (code-check
# round 3): the PCIC layers on the run, years and variables; the upstream means
# on those and the basin; the ECCC table on the years and the zones zip.
hz_zip <- file.path("data", "hydz", "bc_hydrologic_zones.zip")
# and each on the code that builds it: the package files for the PCIC stages,
# this script (which holds the ECCC stage) for the ECCC table
pcic_code <- unname(tools::md5sum(file.path("R", c(
  "wet_pcic_annual.R", "wet_pcic_fetch.R", "wet_pcic_index.R", "wet_pcic_url.R", "wet_runoff_annual.R",
  "wet_ws_fetch.R", "wet_ws_sample.R", "wet_upstream_means.R", "wet_upstream_sums.R"))))
stopifnot(!anyNA(pcic_code))
pcic_key <- substr(wet:::wet_md5_text(paste(c(pcic_run, years, vars, names(vars), pcic_code), collapse = "|")), 1, 10)
eccc_key <- substr(wet:::wet_md5_text(paste(c(years, unname(tools::md5sum(c(hz_zip, "scripts/wb_term_diagnose.R")))),
                                            collapse = "|")), 1, 10)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

# a cache is renamed into place only once complete, so a killed run leaves none
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  if (inherits(x, "SpatRaster")) terra::writeRaster(x, tmp, datatype = "FLT8S", filetype = "GTiff", overwrite = TRUE)
  else saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}

# ---- 1-2. PCIC upstream means per basin ---------------------------------------------------
pcic_annual <- function(v, bbox, tries = 3) {
  for (i in seq_len(tries)) {
    r <- tryCatch(wet_pcic_annual(v, bbox, years, run = pcic_run), error = function(e) e)
    if (!inherits(r, "error")) return(r)
    stamp(v, ": attempt ", i, " failed: ", conditionMessage(r))
  }
  stop(v, " failed ", tries, " times", call. = FALSE)
}
pcic_upstream <- function(code) {
  # the whole basin, cut to this fit's gauges only after reading, so the cache
  # does not depend on the fit
  f_up <- file.path(out_dir, sprintf("pcic_upstream_%s_%s.rds", code, pcic_key))
  if (file.exists(f_up)) {
    up <- readRDS(f_up)
    return(up[up$watershed_feature_id %in% cal$watershed_feature_id, ])
  }
  e <- DBI::dbGetQuery(conn, "
    SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
    FROM (SELECT ST_Extent(geom) e FROM whse_basemapping.fwa_watersheds_poly
          WHERE wscode_ltree <@ $1::ltree) x", params = list(code))
  ext <- terra::project(terra::ext(unlist(e)[c("xmin", "xmax", "ymin", "ymax")]),
                        "EPSG:3005", "EPSG:4326")
  bbox <- c(ext$xmin, ext$ymin, ext$xmax, ext$ymax) + c(-1, -1, 1, 1) * 0.0625  # as scripts/mad_basin.R
  stamp(code, ": bbox ", paste(round(bbox, 3), collapse = ", "))
  f_cell <- file.path(out_dir, sprintf("pcic_cell_%s_%s.tif", code, pcic_key))
  if (!file.exists(f_cell)) {
    r <- terra::rast(lapply(vars, function(v) {
      stamp(code, ": ", v)
      pcic_annual(v, bbox)
    }))
    names(r) <- names(vars)
    save_atomic(r, f_cell)
  }
  r <- terra::rast(f_cell)
  stopifnot(identical(names(r), names(vars)))
  ws <- wet_ws_fetch(conn, code)
  irr <- wet_upstream_irregular(conn, code)
  vals <- do.call(rbind, lapply(sort(unique(ws$watershed_group_code)), function(g) {
    wet_ws_sample(r, wet_ws_geom(conn, g), "area")
  }))
  vals <- vals[vals$watershed_feature_id %in% ws$watershed_feature_id, ]
  up <- wet_upstream_means(ws, vals, cols = names(vars), irregular_pairs = irr)
  up$basin <- code
  save_atomic(up, f_up)
  stamp(code, ": ", nrow(ws), " polygons")
  up[up$watershed_feature_id %in% cal$watershed_feature_id, ]
}
pc <- do.call(rbind, lapply(basins, pcic_upstream))
pc$pcic_cover <- pc$coverage
pc <- pc[c("watershed_feature_id", "basin", names(vars), "pcic_cover")]

# ---- gauges: ours, PCIC, observed, held out -----------------------------------------------
cv <- readRDS(file.path(fit_dir, "cv_aet-cfu.rds"))
stopifnot(identical(cv$aet, "cfu"), identical(cv$release, release),
          identical(cv$code_md5, score_code_md5))  # a fit made under this scoring code
cols_g <- c("station_number", "station_name", "watershed_feature_id", "linear_feature_id", "zone",
            "nesting", "n_years", "area_km2", "elev", "obs", "p_yr", "aet_cfu", "aet_fu", "pet_yr",
            "ppt_tc", "aet_mod16")
g <- merge(cal[cols_g], pc, by = "watershed_feature_id")
g$cv_ann <- cv$cv_ann[match(g$station_number, cv$station_number)]
# fwapg's stored MAD on the gauge's own segment (a plumbing check only)
fw <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id, mad_mm FROM whse_basemapping.fwa_stream_networks_discharge
  WHERE linear_feature_id IN (%s)", paste(unique(g$linear_feature_id), collapse = ", ")))
g$fwapg_mm <- fw$mad_mm[match(g$linear_feature_id, fw$linear_feature_id)]
n_in_basins <- nrow(g)
g <- g[g$pcic_cover >= min_cover, ]

# one row per distinct basin: gauges on the same watershed are averaged
num <- setdiff(names(g)[vapply(g, is.numeric, TRUE)], c("watershed_feature_id", "linear_feature_id"))
dup <- g$watershed_feature_id[duplicated(g$watershed_feature_id)]
b <- do.call(rbind, lapply(split(g, g$watershed_feature_id), function(d) {
  o <- d[1, ]
  o[num] <- lapply(d[num], mean)
  o$station_number <- paste(d$station_number, collapse = "+")
  o
}))
b <- b[order(b$zone, b$station_number), ]

b$r_o <- b$p_yr - b$aet_cfu           # ours, raw (no zone adjustment)
b$r_c <- b$ro_c + b$bf_c              # PCIC runoff
b$dp <- b$p_yr - b$p_c
b$da <- b$aet_cfu - b$e_c
b$gap <- b$dp - b$da                  # (P_o - A_o) - (P_c - E_c)
b$overshoot <- b$r_o - b$obs
b$closure <- (b$p_c - b$e_c - b$r_c) / b$r_c
b$a_imp <- b$p_yr - b$obs             # gauge-implied AET under our P
# runoff at or below 0 floored at 1 mm for the log error, and counted
n_floor_o <- sum(b$r_o < 1)
n_floor_c <- sum(b$r_c < 1)
lerr <- function(r) log(pmax(r, 1) / b$obs)
b$le_o <- lerr(b$r_o)
b$le_c <- lerr(b$r_c)
b$le_cv <- lerr(b$cv_ann)

# Fu's omega that reproduces an AET from P and PET; Inf where none can (the
# AET is at or above min(P, PET), the omega -> Inf limit), NA where AET <= 0
omega_implied <- function(p, pet, aet) {
  vapply(seq_along(p), function(i) {
    if (!is.finite(aet[i]) || aet[i] <= 0) return(NA_real_)
    if (aet[i] >= min(p[i], pet[i])) return(Inf)
    f <- function(w) wet_aet_budyko(p[i], pet[i], w) - aet[i]
    if (f(1.0001) >= 0) return(1)
    if (f(50) < 0) return(Inf)
    stats::uniroot(f, c(1.0001, 50), tol = 1e-6)$root
  }, 1)
}
b$w_harg <- omega_implied(b$p_yr, b$pet_yr, b$a_imp)
b$w_pcic <- omega_implied(b$p_yr, b$pet_c, b$a_imp)
# Fu counterfactual (reported, not deciding) on basins where cfu is Fu
b$fu_dom <- abs(b$aet_cfu - b$aet_fu) < 1e-9 * pmax(1, b$aet_cfu)
b$cf_p <- (b$p_yr - wet_aet_budyko(b$p_yr, b$pet_yr)) - (b$p_c - wet_aet_budyko(b$p_c, b$pet_yr))
b$cf_model <- wet_aet_budyko(b$p_c, b$pet_yr) - b$e_c

# ---- 3. climr against ECCC normals at every station ----------------------------------------
f_eccc <- file.path(out_dir, sprintf("eccc_climr_%s.rds", eccc_key))
if (!file.exists(f_eccc)) {
  eccc <- function(q) {
    f <- tempfile(fileext = ".json")
    wet:::wet_download(paste0("https://api.weather.gc.ca/collections/", q), f, 300)
    jsonlite::fromJSON(f)$features
  }
  p <- eccc("climate-normals/items?f=json&limit=10000&PROVINCE_CODE=BC&MONTH=13&NORMAL_ID=56")$properties
  p <- p[p$PERIOD_BEGIN == 1981 & p$PERIOD_END == 2010 & !is.na(p$VALUE), ]
  stopifnot(nrow(p) > 0, !anyDuplicated(p$CLIMATE_IDENTIFIER))
  stf <- eccc("climate-stations/items?f=json&limit=10000&PROV_STATE_TERR_CODE=BC")
  xy <- do.call(rbind, stf$geometry$coordinates)  # decimal; LATITUDE/LONGITUDE are packed DMS
  est <- data.frame(climate_id = stf$properties$CLIMATE_IDENTIFIER, lon = xy[, 1], lat = xy[, 2],
                    elev = as.numeric(stf$properties$ELEVATION))
  ec <- merge(data.frame(climate_id = p$CLIMATE_IDENTIFIER, station = p$STATION_NAME,
                         code = p$NORMAL_CODE, map = p$VALUE), est, by = "climate_id")
  ec <- ec[stats::complete.cases(ec), ]
  pts <- data.frame(id = seq_len(nrow(ec)), lon = ec$lon, lat = ec$lat, elev = ec$elev)
  cl <- suppressMessages(climr::downscale(
    pts, which_refmap = "refmap_climr", obs_ts_dataset = "mswx.blend", obs_years = years,
    vars = "MAP", return_refperiod = FALSE
  ))
  cl <- as.data.frame(cl)
  cl <- cl[!is.na(cl$PERIOD), ]
  ec$climr_map <- as.numeric(tapply(cl$MAP, factor(cl$id, levels = pts$id), mean))
  hz_src <- file.path("data", "hydz", paste0("src_", substr(unname(tools::md5sum(hz_zip)), 1, 8)))
  utils::unzip(hz_zip, exdir = hz_src, overwrite = TRUE)  # every run, as scripts/wb_inputs.R
  hz <- terra::vect(list.files(hz_src, "[.]shp$", full.names = TRUE, recursive = TRUE))
  zp <- terra::extract(hz, terra::project(terra::vect(ec, geom = c("lon", "lat"), crs = "EPSG:4326"),
                                          terra::crs(hz)))
  zp <- zp[!duplicated(zp$id.y), ]
  stopifnot(nrow(zp) == nrow(ec), all(zp$id.y == seq_len(nrow(ec))))  # id.y is double
  ec$zone <- ifelse(is.na(zp$HYDZN_NO), NA, sprintf("%02d", as.integer(zp$HYDZN_NO)))
  save_atomic(ec, f_eccc)
}
ec <- readRDS(f_eccc)
ec <- ec[!is.na(ec$climr_map) & ec$map > 0, ]
ec$ratio <- ec$climr_map / ec$map

# ---- the rule (findings: "Pre-registered attribution rule" as amended) ---------------------
med <- stats::median
verdict <- function(d, zones, check_n = TRUE) {
  e <- ec[ec$zone %in% zones & ec$elev >= med(d$elev) - 500, ]
  r <- list(n = nrow(d), le_o = med(d$le_o), le_c = med(d$le_c), ale_o = med(abs(d$le_o)),
            ale_c = med(abs(d$le_c)), closure = med(abs(d$closure)), sdp = sum(d$dp), sda = sum(d$da),
            g = sum(d$gap), tc_o = med(d$ppt_tc / d$p_yr), tc_c = med(d$ppt_tc / d$p_c),
            mod16 = med(d$aet_mod16 / d$aet_cfu),
            # "under both PETs" is per basin: a basin counts only when the test
            # holds under each PET. NA (implied AET <= 0) fails both tests, so
            # every basin is in both denominators.
            w_high = mean(!is.na(d$w_harg) & d$w_harg > omega_max &
                            !is.na(d$w_pcic) & d$w_pcic > omega_max),
            w_low = mean(is.finite(d$w_harg) & d$w_harg <= omega_max &
                           is.finite(d$w_pcic) & d$w_pcic <= omega_max),
            n_eccc = nrow(e), eccc = if (nrow(e) >= 3) med(e$ratio) else NA_real_)
  r$share_p <- if (r$g > 0) r$sdp / r$g else NA_real_
  r$share_a <- if (r$g > 0) -r$sda / r$g else NA_real_
  r$off <- if (r$ale_o > r$ale_c) "ours" else "theirs"
  shared <- NULL
  decompose <- function() {
    if (r$g <= 0) return("decomposition undefined (our P - AET is not above PCIC's)")
    in_band <- function(s) s >= 2 / 3 && s <= 1.5
    p_corr <- r$w_high >= 0.5 || (!is.na(r$eccc) && r$eccc >= 1.10) || r$tc_o <= 0.90
    a_corr <- r$w_low > 0.5 && r$mod16 >= 1.00
    if (in_band(r$share_p)) return(if (p_corr) "P side (ours)" else "unresolved: P by decomposition, not corroborated")
    if (in_band(r$share_a)) return(if (a_corr) "AET side (ours)" else "unresolved: AET by decomposition, not corroborated")
    if (r$share_p > 1.5 || r$share_a > 1.5) return("compensating (the other term offsets more than half)")
    "mixed"
  }
  r$decomp <- decompose()
  r$verdict <- if (check_n && r$n < min_basins) {
    "too few"
  } else if (r$le_o < 0.10) {
    "no material gap"
  } else if (r$ale_c > 0.25 || r$closure > 0.25) {
    "unresolved: PCIC not a usable reference"
  } else if (r$le_c >= 0.10 && r$le_c >= (2 / 3) * r$le_o) {
    if (r$tc_o <= 0.90 && r$tc_c <= 0.90) "P side, shared (ours and theirs)"
    else "gauge side (unresolved: withdrawals or groundwater)"
  } else {
    r$decomp
  }
  r
}
# a verdict, with leave-one-basin-out stability (the minimum count applies to
# the zone, not to each leave-one-out subset)
judge <- function(d, zones) {
  r <- verdict(d, zones)
  if (r$n >= min_basins) {
    loo <- vapply(seq_len(nrow(d)), function(i) verdict(d[-i, ], zones, check_n = FALSE)$verdict, "")
    if (any(loo != r$verdict)) r$verdict <- sprintf("unstable (%s)", r$verdict)
  }
  r
}
as_row <- function(r, label) as.data.frame(c(list(zone = label), r), stringsAsFactors = FALSE)
zs <- do.call(rbind, lapply(sort(unique(b$zone)), function(z) as_row(judge(b[b$zone == z, ], z), z)))
zs <- zs[order(!zs$zone %in% dry, zs$zone), ]
pooled_dry <- judge(b[b$zone %in% dry, ], dry)
big <- b[b$area_km2 >= 100, ]
zs_big <- do.call(rbind, lapply(dry, function(z) {
  d <- big[big$zone == z, ]
  if (nrow(d)) as_row(verdict(d, z), z) else NULL
}))

term_of <- function(v) {
  ifelse(v %in% c("P side (ours)", "P side, shared (ours and theirs)"), "P",
         ifelse(v == "AET side (ours)", "AET", NA_character_))
}
votes <- term_of(zs$verdict[match(dry, zs$zone)])
tab <- table(factor(votes, levels = c("P", "AET")))
lead <- names(tab)[which.max(tab)]
lever <- if (max(tab) >= 2 && tab[["P"]] != tab[["AET"]] &&
             !identical(term_of(pooled_dry$verdict), setdiff(c("P", "AET"), lead))) lead else "none"

# ---- report -------------------------------------------------------------------------------
f2 <- function(x) ifelse(is.na(x), "  -", sprintf("%.2f", x))
pct <- function(le) sprintf("%+.0f %%", 100 * (exp(le) - 1))
zone_line <- function(z, r) {
  sprintf("%-6s %3d  %6s  %6s  %5s  %5s  %6.0f %6.0f %6.0f  %5s %5s  %5s %5s %5s  %4.0f%% %4.0f%%  %2d %5s  %-6s %s",
          z, r$n, pct(r$le_o), pct(r$le_c), f2(r$ale_c), f2(r$closure), r$sdp, r$sda, r$g,
          f2(r$share_p), f2(r$share_a), f2(r$tc_o), f2(r$tc_c), f2(r$mod16), 100 * r$w_high,
          100 * r$w_low, r$n_eccc, f2(r$eccc), r$off, r$verdict)
}
hdr <- paste("zone     n  ours    PCIC   |PCIC| clos.   sumdP  sumdA    gap  shP   shA    tc/Po tc/Pc m16/A  w>5   w<=5  ec ratio  off    verdict")
dd <- b[b$zone %in% dry, ]
fw_ok <- !is.na(b$fwapg_mm)
lines <- c(
  "# Which term is off in the dry interior (#45): ours (climr P, cfu AET) against PCIC VIC-GL",
  "",
  sprintf("fit: %s, province run %s, scoring code %s; PCIC %s %d-%d (cache %s), upstream area-weighted means",
          release, basename(key_dir), score_code_md5, pcic_run, min(years), max(years), pcic_key),
  "rule: pre-registered in the #45 findings before any PCIC value was computed, as amended (Amendment 1)",
  sprintf("calibration gauges in basins 100/200/300: %d; with PCIC over >= %.0f %% of the basin: %d, in %d distinct basins (merged: %s)",
          n_in_basins, 100 * min_cover, nrow(g), nrow(b), if (length(dup)) paste(unique(b$station_number[grepl("[+]", b$station_number)]), collapse = ", ") else "none"),
  sprintf("runoff floored at 1 mm for the log error: ours %d, PCIC %d; dry-zone gauges with < 20 years: %d of %d",
          n_floor_o, n_floor_c, sum(g$n_years[g$zone %in% dry] < 20), sum(g$zone %in% dry)),
  "",
  "## Is PCIC sound as a reference?",
  sprintf("PCIC RUNOFF+BASEFLOW / fwapg stored MAD on the gauge's segment, %d basins: median %s, p10-p90 %s-%s",
          sum(fw_ok), f2(med(b$r_c[fw_ok] / b$fwapg_mm[fw_ok])),
          f2(stats::quantile(b$r_c[fw_ok] / b$fwapg_mm[fw_ok], 0.1)),
          f2(stats::quantile(b$r_c[fw_ok] / b$fwapg_mm[fw_ok], 0.9))),
  "  (plumbing: the same two variables; fwapg samples centroids over a stale upstream area)",
  sprintf("closure (P - EVAP - runoff) / runoff, all basins: median %s, p10-p90 %s-%s",
          f2(med(b$closure)), f2(stats::quantile(b$closure, 0.1)), f2(stats::quantile(b$closure, 0.9))),
  sprintf("ECCC 1981-2010 MAP normals (any code) with a climr value: %d; climr/ECCC median %s",
          nrow(ec), f2(med(ec$ratio))),
  "",
  "## Per zone: dry zones first, then contrast zones, then the pooled dry stratum",
  "Runoff errors are the median raw log error as %. Sums are over distinct basins (mm).",
  "w>5: share of basins whose implied omega is > 5 or has no solution under both PETs. w<=5: share whose omega is <= 5 under both.",
  "ec / ratio: ECCC stations no more than 500 m below the median basin elevation, and their median climr/ECCC (needs >= 3).",
  hdr,
  vapply(seq_len(nrow(zs)), function(i) zone_line(zs$zone[i], zs[i, ]), ""),
  zone_line("dry", pooled_dry),
  "",
  sprintf("## Lever (votes over zones %s; P %d, AET %d; pooled dry stratum: %s): %s",
          paste(dry, collapse = ", "), tab[["P"]], tab[["AET"]], pooled_dry$verdict, lever),
  "",
  "## Reported, not deciding",
  sprintf("zone %s: overshoot R_o - Q median %.0f mm; decomposition alone: %s; held-out error %s",
          zs$zone[zs$zone %in% dry],
          vapply(zs$zone[zs$zone %in% dry], function(z) med(b$overshoot[b$zone == z]), 1),
          zs$decomp[zs$zone %in% dry],
          vapply(zs$zone[zs$zone %in% dry], function(z) pct(med(b$le_cv[b$zone == z])), "")),
  vapply(dry, function(z) {
    d <- dd[dd$zone == z & dd$fu_dom, ]
    sprintf("zone %s Fu counterfactual (%d Fu-dominated basins): P term %.0f mm, model term (Fu(P_c) - EVAP) %.0f mm",
            z, nrow(d), sum(d$cf_p), sum(d$cf_model))
  }, ""),
  "basins >= 100 km2 only:",
  if (!is.null(zs_big)) vapply(seq_len(nrow(zs_big)), function(i) zone_line(zs_big$zone[i], zs_big[i, ]), "") else "  none",
  "",
  "## Dry-zone basins (mm/yr): P ours/PCIC/TerraClimate, AET ours/EVAP/MOD16, runoff ours/PCIC/obs, implied AET, PET Harg/PCIC, implied omega",
  "station          zone nesting      km2   P_o   P_c  P_tc   A_o   E_c  A_16   R_o   R_c   obs   A*  PET_h PET_c  w_h   w_c  name",
  sprintf("%-16s %-4s %-9s %7.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5s %5s  %s",
          dd$station_number, dd$zone, dd$nesting, dd$area_km2, dd$p_yr, dd$p_c, dd$ppt_tc, dd$aet_cfu,
          dd$e_c, dd$aet_mod16, dd$r_o, dd$r_c, dd$obs, dd$a_imp, dd$pet_yr, dd$pet_c,
          f2(dd$w_harg), f2(dd$w_pcic), substr(dd$station_name, 1, 28)),
  "",
  "## ECCC normals in the dry zones: climr against the station normal",
  "climate_id zone station                       code  elev  ECCC   climr ratio",
  {
    e <- ec[ec$zone %in% dry, ]
    e <- e[order(e$zone, e$elev), ]
    sprintf("%-10s %-4s %-28s %4s %5.0f %7.1f %7.1f %5.2f", e$climate_id, e$zone, substr(e$station, 1, 28),
            e$code, e$elev, e$map, e$climr_map, e$ratio)
  }
)
f_report <- wb_report("wb_term_diagnose", release)
writeLines(lines, f_report)
saveRDS(list(basins = b, zones = zs, pooled_dry = pooled_dry, eccc = ec, lever = lever, release = release),
        file.path(out_dir, sprintf("diagnose_%s.rds", release)))
DBI::dbDisconnect(conn)
stamp("done; report ", f_report)
