# Province output of the open water balance (#11, Phase 7).
#
#   WET_HYDAT=<Hydat.sqlite3 of the release> Rscript scripts/wb_output.R
#
# Applies the fits from scripts/wb_validate.R, for one fit (the shipped
# release unless WET_HYDAT_RELEASE says otherwise; scripts/wb_fit_lib.R), to
# the upstream means from scripts/wb_province.R and writes, per top-level
# basin (gitignored):
#   <fit>/output/<CODE>.parquet
#     watershed_feature_id, month (0 annual, 1-12), runoff_mm, discharge_m3s,
#     coverage, bc_fraction
# plus the tracked report wb_report("wb_output", release) and the annual
# runoff grid <fit>/runoff_annual.tif (for the map). WET_HYDAT must hold the
# fit's release: the major-river check reads it.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
key_dir <- wb_key_dir()
release <- wb_release()
hydat <- wb_hydat(release)
fit_dir <- wb_fit_dir(key_dir, release)
if (!file.exists(file.path(fit_dir, "fits.rds"))) stop("run scripts/wb_validate.R first: no fits in ", fit_dir)
fits <- readRDS(file.path(fit_dir, "fits.rds"))
aet <- fits$aet
# Ship only a fit made under the current scoring code, and only the AET chosen
# (scripts/wb_aet_compare.R, #15) or carried (#43) under that code; without a
# winner nothing ships. The old outputs go first, so a refused fit never
# leaves the parquet or the map (scripts/wb_map.R) of an earlier one.
unlink(c(file.path(fit_dir, "runoff_annual.tif"), file.path(fit_dir, "output")), recursive = TRUE)
source("scripts/wb_score_md5.R")  # score_code_md5
if (!identical(fits$code_md5, score_code_md5)) {
  stop("fits.rds was made under other scoring code: rerun scripts/wb_validate.R (and the comparison)")
}
f_winner <- file.path(fit_dir, "aet_winner.txt")
if (file.exists(f_winner)) {
  w <- readLines(f_winner)
  if (!identical(w[2], aet_code_md5)) stop(f_winner, " was chosen under other code: rerun the comparison or the carry")
  if (!identical(aet, w[1])) {
    stop("fits.rds ships ", aet, " but the comparison chose ", w[1], ": run scripts/wb_validate.R ", w[1])
  }
} else {
  stop("fits.rds ships ", aet, " but no comparison or carry chose it (no ", f_winner, ")")
}
dir.create(file.path(fit_dir, "output"), showWarnings = FALSE)
days <- c(365.25, wet_month_days())

# ---- per-watershed annual and monthly runoff -----------------------------------------------
tally <- list()
for (f in list.files(file.path(key_dir, "upstream"), "\\.rds$", full.names = TRUE)) {
  code <- sub("\\.rds$", "", basename(f))
  up <- readRDS(f)
  up$raw <- wet:::wet_wb_raw(up, aet)
  zc <- grep("^zp?[0-9]+$", names(up), value = TRUE)
  known <- c(paste0("z", fits$wb$coef$zone), paste0("zp", fits$wb$coef$zone))
  # a zone the fit never saw (no calibration station anywhere in it) gets no
  # adjustment: its columns are dropped rather than refused
  drop <- setdiff(zc, known)
  ann <- if (fits$keep_adjust) wet_wb_adjust(fits$wb, up[setdiff(names(up), drop)]) else pmax(up$raw, 0)
  sh <- wet_share_predict(fits$share, up)
  mm <- cbind(ann, sh * ann)
  out <- data.frame(
    watershed_feature_id = rep(up$watershed_feature_id, 13),
    month = rep(0:12, each = nrow(up)),
    runoff_mm = as.vector(mm),
    discharge_m3s = as.vector(wet_mm_to_m3s(mm, up$upstream_area_m2, days = rep(days, each = nrow(up)))),
    coverage = rep(up$coverage, 13),
    bc_fraction = rep(up$bc_fraction, 13)
  )
  tmp <- tempfile(fileext = ".parquet", tmpdir = file.path(fit_dir, "output"))
  arrow::write_parquet(out, tmp)
  file.rename(tmp, file.path(fit_dir, "output", paste0(code, ".parquet")))
  tally[[code]] <- data.frame(code = code, n = nrow(up), na_annual = sum(is.na(ann)),
                              low_cov = sum(up$coverage < 0.9, na.rm = TRUE),
                              out_bc = sum(up$bc_fraction < 0.95, na.rm = TRUE),
                              zones_unfitted = length(drop) / 2)
  stamp(code, ": ", nrow(up), " watersheds")
}
tally <- do.call(rbind, tally)

# ---- mouths of major rivers against HYDAT ------------------------------------------------------
mouths <- c("08MF005", "08LF051", "08EF001", "08DB001", "08CE001", "07FD002", "08NE049")
con <- wet:::wet_hydat_connect(hydat)
g <- DBI::dbGetQuery(con, sprintf("
  SELECT STATION_NUMBER station_number, STATION_NAME station_name, LONGITUDE lon, LATITUDE lat,
         DRAINAGE_AREA_GROSS drainage_area_gross_km2
  FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste(sprintf("'%s'", mouths), collapse = ",")))
q <- DBI::dbGetQuery(con, sprintf("
  SELECT STATION_NUMBER station_number, AVG(MONTHLY_MEAN) q
  FROM DLY_FLOWS WHERE YEAR BETWEEN 1981 AND 2010 AND FULL_MONTH = 1
    AND STATION_NUMBER IN (%s) GROUP BY 1", paste(sprintf("'%s'", mouths), collapse = ",")))
DBI::dbDisconnect(con)
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
sn <- wet_station_snap(conn, g)
DBI::dbDisconnect(conn)
g <- merge(g, sn, by = "station_number")
g$obs_m3s <- q$q[match(g$station_number, q$station_number)]
read_annual <- function(f) {
  x <- as.data.frame(arrow::read_parquet(f))
  x[x$month == 0 & x$watershed_feature_id %in% g$watershed_feature_id, ]
}
mod <- do.call(rbind, lapply(list.files(file.path(fit_dir, "output"), "\\.parquet$", full.names = TRUE),
                             read_annual))
g$mod_m3s <- mod$discharge_m3s[match(g$watershed_feature_id, mod$watershed_feature_id)]
g$bc_fraction <- mod$bc_fraction[match(g$watershed_feature_id, mod$watershed_feature_id)]

# PCIC VIC-GL through wet at Hope, from the tracked basin report (#2)
hope <- grep("area/covered", readLines("data/basin/100_report.txt"), value = TRUE)
pcic_hope <- if (length(hope)) sub(".*area/covered ([0-9.]+) m3/s.*", "\\1", hope[1]) else "n/a"

# ---- annual runoff grid, for the map -------------------------------------------------------------
lay <- terra::rast(file.path(key_dir, "layers.tif"))
ro <- wet:::wet_wb_raw(lay, aet)
if (fits$keep_adjust) {
  for (i in seq_len(nrow(fits$wb$coef))) {
    k <- as.integer(fits$wb$coef$zone[i])
    iz <- lay[["zone"]] == k
    ro <- ro + iz * (fits$wb$coef$a[i] + fits$wb$coef$b[i] * lay[["p_yr"]])
  }
}
ro <- terra::clamp(ro, lower = 0, values = TRUE)
names(ro) <- "runoff_mm"
terra::writeRaster(ro, file.path(fit_dir, "runoff_annual.tif"), overwrite = TRUE)

# ---- report -----------------------------------------------------------------------------------------
con <- file(wb_report("wb_output", release), "w")
writeLines(c(
  "# Open water balance: province output (#11)", "",
  sprintf("province run: %s; annual AET: %s; adjustment %s", basename(key_dir), aet,
          if (fits$keep_adjust) "applied" else "not applied (gate failed)"),
  sprintf("watersheds: %d in %d top-level basins; rows: %d (annual + 12 months)",
          sum(tally$n), nrow(tally), 13 * sum(tally$n)),
  sprintf("annual NA: %d; coverage < 0.9: %d; bc_fraction < 0.95: %d",
          sum(tally$na_annual), sum(tally$low_cov), sum(tally$out_bc)),
  "", "## By basin (code, watersheds, annual NA, coverage < 0.9, bc_fraction < 0.95, zones with no fit)",
  sprintf("%-4s %8d %6d %8d %8d %3d", tally$code, tally$n, tally$na_annual, tally$low_cov, tally$out_bc,
          as.integer(tally$zones_unfitted)),
  "", "## Major rivers: modelled mean annual discharge against HYDAT 1981-2010 (full months)",
  "Regulated gauges keep their mean annual flow except where water is diverted out of the basin:",
  "the Nechako (Kemano) diversion takes Fraser water to the coast above 08MF005.",
  sprintf("%-8s %-36s %9s %9s %9s %6s %6s", "station", "name", "area_km2", "obs_m3s", "mod_m3s", "ratio", "in_bc"),
  sprintf("%-8s %-36s %9.0f %9.1f %9.1f %6.2f %6.2f", g$station_number, substr(g$station_name, 1, 36),
          g$upstream_area_km2, g$obs_m3s, g$mod_m3s, g$mod_m3s / g$obs_m3s, g$bc_fraction),
  "", sprintf("PCIC VIC-GL through wet at 08MF005, area-weighted (data/basin/100_report.txt): %s m3/s", pcic_hope)
), con)
close(con)
stamp("report written")
