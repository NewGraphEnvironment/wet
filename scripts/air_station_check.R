# The station check of the air temperature lookup (#216): at every station of the water
# temperature archive that the pinned HYDAT release places on a segment, the series read
# through the built tree (wet_air_daily()) equals cd::cd_extract_daily() at the segment's
# stored point, every day of every year and variable; against the station's own coordinates it
# is equal wherever the two share a cell, and the stations where they do not are listed with
# both cells and the distance between the points, not failed. That proves the lookup and the
# copy, not the air series: both sides read one cube.
#
#   Rscript scripts/air_station_check.R
#
# Reads the tree scripts/air_publish.R built under <WET_DATA_ROOT>/publish/air_temperature/fwa/v1/
# (its local manifest; WET_AIR_MANIFEST names another, such as a mutated copy), the archive's
# station list (s3://water-temp-bc, Parameter=5), HYDAT (WET_HYDAT_RELEASE, default the shipped
# release) and fwapg from WET_PG*. Writes data/checks/air_station_check_<last year>.txt, or with
# WET_AIR_REPORT another path. The station list grows as the archive does, which is why this is
# its own report and not the BUILD's.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")       # wb_shipped_release, wb_hydat()
source("scripts/air_publish_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
manifest <- Sys.getenv("WET_AIR_MANIFEST", file.path(data_root, "publish", air_id, "manifest.json"))
last_year <- as.integer(substr(air_mask_day, 1, 4))
f_report <- Sys.getenv("WET_AIR_REPORT", file.path("data", "checks", sprintf("air_station_check_%d.txt", last_year)))
release <- Sys.getenv("WET_HYDAT_RELEASE", wb_shipped_release)
cat_air <- wet_catalog(manifest)
years <- sort(as.integer(cat_air$code[cat_air$dataset == paste(air_id, "cell_daily", sep = "/")]))
from <- sprintf("%d-01-01", min(years))
to <- sprintf("%d-12-31", max(years))

# ---- the archive's stations, and where HYDAT places them -------------------------------------
duck <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;")
DBI::dbExecute(duck, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
temp_root <- getOption("wet.temp_root", "s3://water-temp-bc/data/canonical/Parameter=5/")
archive <- sort(DBI::dbGetQuery(duck, sprintf("SELECT DISTINCT STATION_NUMBER AS s FROM read_parquet(%s)",
                                              DBI::dbQuoteString(duck, paste0(temp_root, "*.parquet"))))$s,
                method = "radix")
DBI::dbDisconnect(duck, shutdown = TRUE)
list_md5 <- {
  f <- tempfile()
  writeLines(archive, f)
  unname(tools::md5sum(f))
}
stamp(length(archive), " stations in the archive")

hc <- wet:::wet_hydat_connect(wb_hydat(release))
st <- DBI::dbGetQuery(hc, "SELECT STATION_NUMBER station_number, LONGITUDE lon, LATITUDE lat,
                                  DRAINAGE_AREA_GROSS drainage_area_gross_km2
                           FROM STATIONS ORDER BY STATION_NUMBER")
DBI::dbDisconnect(hc)
st <- st[st$station_number %in% archive, ]
why <- stats::setNames(rep(NA_character_, length(archive)), archive)
why[setdiff(archive, st$station_number)] <- paste("not in HYDAT", release)
no_area <- st$station_number[is.na(st$drainage_area_gross_km2) | is.na(st$lon) | is.na(st$lat)]
why[no_area] <- paste("no coordinates or gross drainage area in HYDAT", release)
st <- st[!st$station_number %in% no_area, ]

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"), port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"), user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres"), connect_timeout = 10
)
sn <- wet_station_snap(conn, st)
why[sn$station_number[!sn$accepted]] <- paste("not placed:", sn$reason[!sn$accepted])
sn <- sn[sn$accepted, ]
grp <- DBI::dbGetQuery(conn, sprintf(
  "SELECT linear_feature_id::double precision AS linear_feature_id, watershed_group_code
   FROM whse_basemapping.fwa_stream_networks_sp WHERE linear_feature_id IN (%s) ORDER BY linear_feature_id",
  paste(sn$linear_feature_id, collapse = ", ")))
DBI::dbDisconnect(conn)
d <- merge(sn[c("station_number", "linear_feature_id")], st[c("station_number", "lon", "lat")], by = "station_number")
d <- merge(d, grp, by = "linear_feature_id")
d <- d[order(d$station_number, method = "radix"), ]
stopifnot(nrow(d) == nrow(sn))
stamp(nrow(d), " stations placed on a segment")

# ---- the series through the tree, against cd at the segment's point and at the station --------
segs <- unique(d$linear_feature_id)
a <- wet_air_daily(segs, from, to, air_vars, groups = sort(unique(d$watershed_group_code)), catalog = cat_air)
look <- unique(a[c("id", "cell_id", "cell_x", "cell_y", "cell_status")])
stopifnot(!anyDuplicated(look$id))
# the stored point of each segment, from the lookup part itself
duck <- DBI::dbConnect(duckdb::duckdb())
pt <- DBI::dbGetQuery(duck, sprintf(
  "SELECT linear_feature_id, point_x, point_y FROM read_parquet([%s]) WHERE linear_feature_id IN (%s)",
  wet:::wet_sql_in(duck, cat_air$href[cat_air$dataset == paste(air_id, "segment_cell", sep = "/")]),
  paste(segs, collapse = ", ")))
DBI::dbDisconnect(duck, shutdown = TRUE)
pt <- pt[match(segs, pt$linear_feature_id), ]
quiet_cd <- function(p) {
  expected <- "^(Outside the daily cube's extent|No ERA5-Land data in or around the cell for)"
  withCallingHandlers(cd::cd_extract_daily(p, from, to, air_vars),
                      warning = function(w) if (grepl(expected, conditionMessage(w))) invokeRestart("muffleWarning"))
}
at_seg <- quiet_cd(data.frame(id = segs, lon = pt$point_x, lat = pt$point_y))
# integer ids on both sides: paste() writes a whole double such as 701000000 as 7.01e+08
key <- function(x) paste(as.integer(x$id), x$variable, as.integer(x$date))
m <- match(key(at_seg), key(a))
seg_diff <- sum(is.na(m)) + sum(!(is.na(at_seg$value) & is.na(a$value[m])) &
                                  (is.na(at_seg$value) | is.na(a$value[m]) | at_seg$value != a$value[m]), na.rm = TRUE)
seg_largest <- suppressWarnings(max(abs(at_seg$value - a$value[m]), na.rm = TRUE))

at_st <- quiet_cd(data.frame(id = d$station_number, lon = d$lon, lat = d$lat))
st_cell <- unique(at_st[c("id", "cell", "cell_x", "cell_y", "cell_moved")])
st_cell$cell_id <- ifelse(is.na(st_cell$cell_x), NA_integer_, wet:::wet_air_cell_id(st_cell$cell_x, st_cell$cell_y))
d$station_cell <- st_cell$cell_id[match(d$station_number, st_cell$id)]
d$segment_cell <- look$cell_id[match(d$linear_feature_id, look$id)]
d$same <- !is.na(d$station_cell) & !is.na(d$segment_cell) & d$station_cell == d$segment_cell
# the series through the lookup against cd at the station, where they share a cell
same_st <- d$station_number[d$same]
xs <- at_st[at_st$id %in% same_st, ]
xs$seg <- d$linear_feature_id[match(xs$id, d$station_number)]
ms <- match(paste(as.integer(xs$seg), xs$variable, as.integer(xs$date)), key(a))
st_diff <- sum(is.na(ms)) + sum(is.na(xs$value) != is.na(a$value[ms]) | xs$value != a$value[ms], na.rm = TRUE)
p_seg <- pt[match(d$linear_feature_id, pt$linear_feature_id), ]
d$distance_m <- round(as.vector(terra::distance(as.matrix(d[c("lon", "lat")]), as.matrix(p_seg[c("point_x", "point_y")]),
                                                lonlat = TRUE, pairwise = TRUE)))

# ---- the report ---------------------------------------------------------------------------------
other <- d[!d$same, ]
not_placed <- why[!is.na(why)]
rep <- c(
  sprintf("# Station check of the air temperature lookup (%s), by scripts/air_station_check.R", air_id),
  "",
  sprintf("tree: %s parts, parts md5 %s; HYDAT %s; days %s to %s, %s", nrow(cat_air), wet:::wet_catalog_digest(cat_air),
          release, from, to, paste(air_vars, collapse = ", ")),
  sprintf("archive stations (water-temp-bc Parameter=5): %d, list md5 %s", length(archive), list_md5),
  sprintf("placed on a segment by wet_station_snap(): %d; not placed: %d", nrow(d), length(not_placed)),
  "",
  "## Through the lookup against cd_extract_daily() at the segment's stored point (the condition)",
  air_check_line("station segments, every day, year and variable", nrow(at_seg), seg_diff,
                 if (is.finite(seg_largest)) seg_largest else NA),
  "",
  "## Against the station's own coordinates",
  sprintf("stations whose own cell is their segment's: %d of %d", sum(d$same), nrow(d)),
  air_check_line("those stations, every day, year and variable", nrow(xs), st_diff),
  sprintf("stations in another cell than their segment's: %d (listed, not failed)", nrow(other)),
  if (nrow(other)) sprintf("  %s segment %d: station cell %s, segment cell %s, %s m between station and midpoint",
                           other$station_number, as.integer(other$linear_feature_id),
                           ifelse(is.na(other$station_cell), "none", other$station_cell),
                           ifelse(is.na(other$segment_cell), "none", other$segment_cell), other$distance_m),
  "",
  "## Stations not placed",
  if (length(not_placed)) sprintf("  %s: %s", names(not_placed), not_placed) else "  none"
)
writeLines(rep, f_report)
stamp("wrote ", f_report)
if (any(grepl("FAIL", rep))) stop("the station check failed: see ", f_report)
