# Bundled data for wet_snow_annual()'s example and test (#121): Maxan Creek
# above Bulkley Lake (08EE018), the #120 pilot site, and cd's annual
# ERA5-Land snow layers cropped to it. The example reads them through
# system.file() and touches neither cd nor fwapg.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/snow_pilot_data.R
#
# Writes inst/extdata/snow_pilot/:
#   - maxan_outline.rds: list(station_number, watershed_feature_id, crs, wkt),
#     xz-compressed. The outline is the union of the 788 fundamental
#     watersheds upstream of 08EE018's snap (FWA_Upstream, the gauge's own
#     polygon included), in EPSG:3005, unsimplified, WKT at 15 significant
#     digits.
#   - <var>_annual.tif for swe_max, snowmelt_doy_50 and snowmelt_rate_peak:
#     cd's file cropped to the outline plus two cells (the window
#     wet_snow_annual() reads), every band (named by year), FLT8S as cd
#     writes it, cd's CD_* tags kept.
#   - catalog.csv: variable, period, href, the href relative to the
#     directory (the example joins it onto system.file()).
#   - provenance.txt: the build's date, wet commit, HYDAT release, snap, and
#     each cd file's href and CD_* tags.
#
# Refuses unless: HYDAT is 20260717; the three pilot gauges snap, accepted,
# onto their fundamental watersheds with the polygon counts measured at the
# plan (scripts/departure_snow_lib.R); each crop read back equals the remote
# file at every cell; wet_snow_annual() over the bundle equals it over cd's
# whole files, and over the outline equals it over the fundamental
# watersheds (to 1e-9); every year 1950-2025 has cover 1; the bundle is at
# most 500 KB. HYDAT from wet's per-user cache (wb_hydat()); fwapg from the
# WET_PG* variables (vd_connect()).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect()
source("scripts/departure_snow_lib.R")  # ds_gauges, ds_stations(), ds_snap(), ds_watershed()

release <- wb_release()
if (release != "20260717") stop("the pilot names HYDAT 20260717, not ", release, call. = FALSE)
hydat <- wb_hydat(release)
out <- file.path("inst", "extdata", "snow_pilot")
vars <- c("swe_max", "snowmelt_doy_50", "snowmelt_rate_peak")
max_kb <- 500
maxan <- ds_gauges[ds_gauges$name == "maxan", ]

st <- ds_stations(hydat)
conn <- vd_connect()
sn <- ds_snap(conn, st)
ws <- lapply(stats::setNames(ds_gauges$watershed_feature_id, ds_gauges$name), function(id) ds_watershed(conn, id))
DBI::dbDisconnect(conn)
fund <- ws[["maxan"]]

u <- terra::aggregate(fund[, 0])
wkt <- sf::st_as_text(sf::st_geometry(sf::st_as_sf(u)), digits = 15)
outline <- list(station_number = maxan$station_number, watershed_feature_id = maxan$watershed_feature_id,
                crs = "EPSG:3005", wkt = wkt)

unlink(out, recursive = TRUE)
dir.create(out, recursive = TRUE)
saveRDS(outline, file.path(out, "maxan_outline.rds"), compress = "xz")
back <- readRDS(file.path(out, "maxan_outline.rds"))
ws_back <- terra::vect(back$wkt, crs = back$crs)

cat_remote <- cd::cd_catalog()
cat_remote <- as.data.frame(cat_remote[cat_remote$variable %in% vars & cat_remote$period %in% "annual",
                                       c("variable", "period", "href")])
cat_remote <- cat_remote[match(vars, cat_remote$variable), ]
stopifnot(identical(cat_remote$variable, vars), !anyNA(cat_remote$href))
tags <- list()
for (i in seq_along(vars)) {
  r <- terra::rast(paste0("/vsicurl/", cat_remote$href[i]))
  e <- terra::extend(terra::ext(terra::project(ws_back, terra::crs(r))), 2 * terra::res(r))
  x <- terra::crop(r, e, snap = "out")
  tg <- terra::metags(r)
  tg <- tg[grepl("^CD_", tg$name), c("name", "value")]
  if (nrow(tg) == 0) stop(vars[i], " carries no CD_* tags", call. = FALSE)
  tags[[vars[i]]] <- tg
  terra::metags(x) <- stats::setNames(tg$value, tg$name)
  f <- file.path(out, sprintf("%s_annual.tif", vars[i]))
  terra::writeRaster(x, f, datatype = "FLT8S", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))
  # the crop read back against the remote file at every cell, band names and tags
  y <- terra::rast(f)
  z <- terra::crop(terra::rast(paste0("/vsicurl/", cat_remote$href[i])), e, snap = "out")
  stopifnot(identical(names(y), names(z)), terra::compareGeom(y, z),
            identical(terra::values(y), terra::values(z)))
  ty <- terra::metags(y)
  stopifnot(identical(ty$value[match(tg$name, ty$name)], tg$value))
}
sidecars <- setdiff(list.files(out), c("maxan_outline.rds", sprintf("%s_annual.tif", vars)))
if (length(sidecars)) stop("unexpected files beside the layers: ", paste(sidecars, collapse = ", "), call. = FALSE)
utils::write.csv(data.frame(variable = vars, period = "annual", href = sprintf("%s_annual.tif", vars)),
                 file.path(out, "catalog.csv"), row.names = FALSE)

# the bundle answers as cd's whole files do, and the outline as its fundamental watersheds
cat_bundle <- utils::read.csv(file.path(out, "catalog.csv"))
cat_bundle$href <- file.path(out, cat_bundle$href)
a <- wet_snow_annual(ws_back, vars, catalog = cat_bundle)
b <- wet_snow_annual(ws_back, vars, catalog = cat_remote)
f <- wet_snow_annual(fund, vars, catalog = cat_bundle)
stopifnot(identical(a, b), isTRUE(all.equal(a, f, tolerance = 1e-9)), identical(a$year, 1950:2025),
          all(a$cover == 1), !anyNA(a[vars]))

n_vert <- nrow(terra::geom(ws_back))
git <- function(...) system2("git", c(...), stdout = TRUE)
dirty <- length(git("status", "--porcelain", "--", "R", "scripts", "data-raw")) > 0
writeLines(c(
  "Built by data-raw/snow_pilot_data.R (wet #121).",
  sprintf("Date: %s (UTC).", format(Sys.time(), "%Y-%m-%d", tz = "UTC")),
  sprintf("wet commit: %s%s.", git("rev-parse", "HEAD"), if (dirty) " (R/, scripts/ or data-raw/ uncommitted)" else ""),
  sprintf("HYDAT release: %s (STATIONS lon, lat and gross drainage area for the snaps).", release),
  sprintf("Snaps (wet_station_snap(), fwapg, all accepted): %s.",
          paste(sprintf("%s -> %d (%d upstream fundamental watersheds)", sn$station_number,
                        sn$watershed_feature_id, ds_gauges$n_poly), collapse = "; ")),
  sprintf(paste("maxan_outline.rds: the union of %s's %d upstream fundamental watersheds, EPSG:3005,",
                "unsimplified, %d vertices, WKT at 15 significant digits."),
          maxan$station_number, maxan$n_poly, n_vert),
  paste("Layers: cd's annual ERA5-Land files cropped to the outline plus two 0.1-degree cells, every band,",
        "FLT8S; equal to the remote file at every cell."),
  unlist(lapply(vars, function(v) {
    tg <- tags[[v]]
    c(sprintf("  %s: %s", v, cat_remote$href[cat_remote$variable == v]),
      sprintf("    %s %s", tg$name, tg$value))
  }))
), file.path(out, "provenance.txt"))

kb <- sum(file.size(list.files(out, full.names = TRUE))) / 1024
print(data.frame(file = list.files(out), kb = round(file.size(list.files(out, full.names = TRUE)) / 1024, 1)))
message(sprintf("snow_pilot bundle: %.1f KB", kb))
if (kb > max_kb) stop(sprintf("the bundle is %.1f KB, over %d KB", kb, max_kb), call. = FALSE)
