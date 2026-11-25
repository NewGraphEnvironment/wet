# The holdout frame of the whole-station temperature baseline (#213): the truth stations snapped
# to the FWA, their catchment traits, their folds and the stations the leak-free pool removes.
#
#   Rscript scripts/temp_baseline_traits.R
#
# Stations: those of the truth station-years of scripts/temp_fill_validate.R (`truth_years()`,
# taken from that script by parse(), on the same cached water and air). Each is snapped with
# wet_station_snap() from its coordinates and gross drainage area in the pinned HYDAT release
# (WET_HYDAT_RELEASE). A station the water balance already snapped must get the same segment.
# A truth year whose observed 1 March - 30 November daily means have a standard deviation under
# 0.1 degC is a sensor reading one value, not a stream, and is not a truth year.
#
# Traits, per station, over everything upstream of its fundamental watershed:
#   elev, e_km, n_km, snowmelt_doy_50, swe_max   the province run's upstream means
#                                                (data/wb/<key>/upstream/)
#   log_area                                     log10 of the accumulated upstream area, km2
#   glacier                                      FWA glacier area as a share of upstream area: the
#                                                query and cache of scripts/wb_small_basin.R, taken
#                                                from it by parse()
#   lake_cover                                   FWA lake and manmade-waterbody (reservoir) area
#                                                as a share of upstream area, by the same recipe
#
# Kept: snapped and accepted, at least 95 % of the basin inside BC and on the trait grids (as the
# water balance calibrates), every trait present, at least one truth year, and enough record for
# wet_temp_fill() to fit the station (365 observed days with air). Every other station is listed
# with its reason. The frame also carries each kept station's own fit (wet:::wet_fill_prepare():
# a1, a2, a3, the departure's rho and sigma) and HYDAT's regulation flag. Fitting a station is not
# a score: no candidate has predicted anything.
#
# Folds are wet_cv_folds()'s (WSC sub-sub-drainage); `related[i, j]` says station j is upstream or
# downstream of station i, as scripts/wb_cv_lib.R's share_related() builds it.
#
# Needs fwapg (WET_PG*), the province run's upstream means for the stations' watersheds (the
# machine with the full run, or a bundle cut to the watersheds this script lists when it stops),
# and data/temp_fill/ (scripts/temp_fill_validate.R's caches).
# Writes data/temp_baseline/frame_<key>.rds and the tracked report
# data/checks/temp_baseline_frame.txt, which names the frame and is byte-identical on a rerun.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/temp_baseline_lib.R")
options(width = 160)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
release <- wb_release()
key_dir <- wb_key_dir()
min_frac <- 0.95  # basin share inside BC and on the grids, as scripts/wb_cv_lib.R
out_dir <- file.path("data", "temp_baseline")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- truth station-years ----------------------------------------------------------------------
f_water <- file.path("data", "temp_fill", "water_2002_2025.rds")
f_air <- file.path("data", "temp_fill", "air_2002_2025.rds")
if (!all(file.exists(f_water, f_air))) {
  stop("data/temp_fill/ has no water and air caches: run scripts/temp_fill_validate.R", call. = FALSE)
}
water <- readRDS(f_water)
air <- readRDS(f_air)
water <- water[water$station_number %in% air$id, ]
v <- new.env()
tb_take("scripts/temp_fill_validate.R", "truth_years", v)
ty <- v$truth_years(water)
ty <- ty[order(ty$station_number, ty$year), ]
rownames(ty) <- NULL
stamp(nrow(ty), " truth station-years at ", length(unique(ty$station_number)), " stations")
stopifnot(nrow(ty) > 0, !anyDuplicated(ty))
n_truth <- c(station_years = nrow(ty), stations = length(unique(ty$station_number)))
# a sensor reading one value all season is not a truth year
stuck_sd <- 0.1
season_sd <- vapply(seq_len(nrow(ty)), function(i) {
  x <- water[water$station_number == ty$station_number[i], ]
  stats::sd(x$t_mean_c[x$date >= as.Date(paste0(ty$year[i], "-03-01")) &
                         x$date <= as.Date(paste0(ty$year[i], "-11-30"))])
}, numeric(1))
stopifnot(all(is.finite(season_sd)))
stuck <- ty[season_sd < stuck_sd, ]
ty <- ty[season_sd >= stuck_sd, ]
rownames(ty) <- NULL
all_stations <- sort(unique(c(ty$station_number, stuck$station_number)))

# enough record to fit, exactly as wet_temp_fill() decides it
pool <- stats::setNames(substr(unique(water$station_number), 1, 3), unique(water$station_number))
prep <- wet:::wet_fill_prepare(water, air, pool, NULL, NULL, 365, 0.1^2)
stamp(length(prep$fit_st), " stations with a fit")

# ---- snap ---------------------------------------------------------------------------------------
con <- wet:::wet_hydat_connect(wb_hydat(release))
st <- DBI::dbGetQuery(con, "
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.LONGITUDE lon, s.LATITUDE lat,
         s.DRAINAGE_AREA_GROSS drainage_area_gross_km2, r.REGULATED regulated
  FROM STATIONS s LEFT JOIN STN_REGULATION r USING (STATION_NUMBER)
  ORDER BY s.STATION_NUMBER")
DBI::dbDisconnect(con)
stopifnot(!anyDuplicated(st$station_number))
st <- st[st$station_number %in% all_stations, ]
# a station newer than the pinned release has no gross drainage area to snap against
absent <- setdiff(all_stations, st$station_number)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres"),
  connect_timeout = 10
)
sn <- wet_station_snap(conn, st[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
d <- merge(st, sn[setdiff(names(sn), "upstream_area_km2")], by = "station_number")
d <- d[order(d$station_number), ]
stamp(sum(d$accepted), " of ", nrow(d), " stations snapped and accepted")

# a station the water balance snapped (to calibrate on, or as a test station) keeps its segment
wb <- readRDS(wb_stations_path(release))
cols_wb <- c("station_number", "accepted", "linear_feature_id", "watershed_feature_id")
wb <- rbind(wb$stations[cols_wb], wb$test[cols_wb])
stopifnot(!anyDuplicated(wb$station_number))
both <- intersect(d$station_number, wb$station_number)
i <- match(both, d$station_number)
j <- match(both, wb$station_number)
same <- d$accepted[i] == wb$accepted[j] &
  (!d$accepted[i] | (d$linear_feature_id[i] == wb$linear_feature_id[j] &
                       d$watershed_feature_id[i] == wb$watershed_feature_id[j]))
n_both <- c(accepted = sum(d$accepted[i]), rejected = sum(!d$accepted[i]))
if (!all(same)) {
  stop("snapped differently from ", wb_stations_path(release), ": ", paste(both[!same], collapse = ", "),
       call. = FALSE)
}

# ---- glacier and lake area per fundamental watershed -------------------------------------------
# The glacier query, its table check and its cache key are scripts/wb_small_basin.R's.
g <- new.env()
g$conn <- conn
tb_take("scripts/wb_small_basin.R", c("q_glacier", "gl_table", "gl_dir", "gl_key", "f_gl"), g)
if (!file.exists(g$f_gl)) {
  stamp("glacier area per fundamental watershed")
  dir.create(g$gl_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(DBI::dbGetQuery(conn, g$q_glacier), paste0(g$f_gl, ".part"))
  if (!file.rename(paste0(g$f_gl, ".part"), g$f_gl)) stop("could not move the glacier cache into place")
}
# Lakes and reservoirs, by the same recipe. Area before any simplification; ordered on the key.
q_lake <- "
  SELECT w.watershed_feature_id, w.wscode_ltree::text AS wscode, w.localcode_ltree::text AS localcode,
         sum(ST_Area(ST_Intersection(w.geom, g.geom))) AS lake_m2
  FROM (SELECT geom FROM whse_basemapping.fwa_lakes_poly
        UNION ALL
        SELECT geom FROM whse_basemapping.fwa_manmade_waterbodies_poly) g
  JOIN whse_basemapping.fwa_watersheds_poly w ON ST_Intersects(w.geom, g.geom)
  GROUP BY w.watershed_feature_id, w.wscode_ltree, w.localcode_ltree
  ORDER BY w.watershed_feature_id"
lk_table <- DBI::dbGetQuery(conn, "
  SELECT 'fwa_lakes_poly' AS tbl, count(*)::int AS n, sum(ST_Area(geom)) AS m2
  FROM whse_basemapping.fwa_lakes_poly
  UNION ALL
  SELECT 'fwa_manmade_waterbodies_poly', count(*)::int, sum(ST_Area(geom))
  FROM whse_basemapping.fwa_manmade_waterbodies_poly
  ORDER BY 1")
lk_key <- substr(wet:::wet_md5_text(paste(c(q_lake, lk_table$tbl, lk_table$n, sprintf("%.0f", lk_table$m2)),
                                          collapse = "|")), 1, 10)
f_lk <- file.path(out_dir, sprintf("lake_ws_%s.rds", lk_key))
if (!file.exists(f_lk)) {
  stamp("lake and reservoir area per fundamental watershed")
  saveRDS(DBI::dbGetQuery(conn, q_lake), paste0(f_lk, ".part"))
  if (!file.rename(paste0(f_lk, ".part"), f_lk)) stop("could not move the lake cache into place")
}
DBI::dbDisconnect(conn)

# ---- upstream means -------------------------------------------------------------------------------
cols_up <- c("watershed_feature_id", "elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max",
             "bc_fraction", "coverage", "upstream_area_m2")
ids <- d$watershed_feature_id[d$accepted]
up <- do.call(rbind, lapply(sort(list.files(file.path(key_dir, "upstream"), "\\.rds$", full.names = TRUE)),
                            function(f) {
                              x <- readRDS(f)
                              x[x$watershed_feature_id %in% ids, cols_up]
                            }))
lost <- setdiff(ids, up$watershed_feature_id)
if (length(lost)) {
  f_need <- file.path(out_dir, "watersheds_needed.txt")
  writeLines(format(sort(ids), scientific = FALSE, trim = TRUE), f_need)
  stop(length(lost), " of the stations' ", length(ids), " watersheds are not in ", file.path(key_dir, "upstream"),
       ": run where the full province run is, or cut a bundle to the watersheds in ", f_need, call. = FALSE)
}
stopifnot(!anyDuplicated(up$watershed_feature_id))
d <- merge(d, up, by = "watershed_feature_id", all.x = TRUE)
d <- d[order(d$station_number), ]
rownames(d) <- NULL
d$area_km2 <- d$upstream_area_m2 / 1e6
d$log_area <- log10(d$area_km2)

cover <- function(w, col) {
  w <- w[w[[col]] > 0 & !is.na(w$wscode) & !is.na(w$localcode), ]
  vapply(seq_len(nrow(d)), function(i) {
    if (!d$accepted[i]) return(NA_real_)
    sum(w[[col]][wet:::wet_fwa_upstream(d$wscode[i], d$localcode[i], w$wscode, w$localcode)])
  }, numeric(1)) / d$upstream_area_m2
}
stamp("glacier and lake cover upstream of each station")
d$glacier <- cover(readRDS(g$f_gl), "glacier_m2")
d$lake_cover <- cover(readRDS(f_lk), "lake_m2")
ok <- d$accepted
stopifnot(all(d$glacier[ok] >= 0), all(d$glacier[ok] <= 1.01), all(d$lake_cover[ok] >= 0),
          all(d$lake_cover[ok] <= 1.01))

# ---- who is kept ------------------------------------------------------------------------------------
n_of <- function(x, s) {
  n <- table(x$station_number)[s]
  ifelse(is.na(n), 0L, as.integer(n))
}
d$n_years <- n_of(ty, d$station_number)
d$n_stuck <- n_of(stuck, d$station_number)
d$reason <- ifelse(d$n_years == 0, "no truth year left: the sensor reads one value all season",
            ifelse(!d$accepted, paste("not snapped:", d$reason),
            ifelse(d$bc_fraction < min_frac, sprintf("%.0f %% of the basin inside BC", 100 * d$bc_fraction),
            ifelse(d$coverage < min_frac, sprintf("%.0f %% of the basin on the grids", 100 * d$coverage),
            ifelse(!stats::complete.cases(d[tb_traits]), "a trait is missing",
            ifelse(!d$station_number %in% prep$fit_st, "too little record to fit", ""))))))
stopifnot(!anyNA(d$reason))
d$kept <- d$reason == ""
k <- d[d$kept, ]
stopifnot(nrow(k) > 0, all(is.finite(as.matrix(k[tb_traits]))))

# ---- folds and the leak-free pool --------------------------------------------------------------------
folds <- wet_cv_folds(data.frame(station_number = k$station_number, wscode = k$wscode,
                                 localcode = k$localcode, upstream_area_km2 = k$area_km2))
stopifnot(identical(folds$station_number, k$station_number))
k <- cbind(k, folds[c("fold", "nesting", "leak_up", "leak_down")])
v2 <- new.env()
tb_take("scripts/wb_cv_lib.R", "share_related", v2)
related <- v2$share_related(k)
dimnames(related) <- list(k$station_number, k$station_number)
stopifnot(isSymmetric(related), !any(diag(related)))
same_fold <- outer(k$fold, k$fold, "==")

# HYDAT's flag: 1 regulated, 0 natural, NA where it says neither
k$regulated <- ifelse(is.na(k$regulated), "unflagged", ifelse(k$regulated == 1, "regulated", "natural"))
cols_frame <- c("station_number", "station_name", "lon", "lat", "drainage_area_gross_km2", "linear_feature_id",
                "watershed_feature_id", "wscode", "localcode", "distance_m", "area_ratio", "lake", "regulated",
                "area_km2", "bc_fraction", "coverage", tb_traits, "n_years", "fold", "nesting", "leak_up",
                "leak_down")
stations <- k[cols_frame]
rownames(stations) <- NULL
truth <- ty[ty$station_number %in% stations$station_number, ]
rownames(truth) <- NULL
dropped <- d[!d$kept, c("station_number", "station_name", "n_years", "reason")]
if (length(absent)) {
  dropped <- rbind(dropped, data.frame(station_number = absent, station_name = NA_character_,
                                       n_years = n_of(ty, absent), reason = paste("not in HYDAT", release)))
}
dropped <- dropped[order(dropped$station_number), ]
rownames(dropped) <- NULL
# each kept station's own fit, as wet_temp_fill() makes it
fit <- do.call(rbind, lapply(stations$station_number, function(s) {
  data.frame(station_number = s, t(prep$open[[s]]$par), rmse_open = prep$open[[s]]$rmse,
             rho = prep$first[[s]]$par[["rho"]], sigma = prep$first[[s]]$par[["sigma"]],
             n_obs = prep$n_obs[[s]])
}))
rownames(fit) <- NULL
stopifnot(identical(fit$station_number, stations$station_number), all(fit$a3 > 0 & fit$a3 < 1))
# The key is of what a score depends on: the stations, their traits to 6 significant digits,
# their folds, the truth years and the related pairs.
canon <- c(do.call(paste, c(lapply(stations[c("station_number", "fold", tb_traits)], function(x) {
  if (is.numeric(x)) formatC(x, digits = 6, format = "g") else x
}), sep = "|")), paste(truth$station_number, truth$year), which(related))
key <- substr(wet:::wet_md5_text(canon), 1, 10)
frame <- list(key = key, stations = stations, truth = truth, related = related, dropped = dropped, fit = fit,
              provenance = list(release = release, run = basename(key_dir), glacier = basename(g$f_gl),
                                lake = basename(f_lk)))
f_frame <- file.path(out_dir, sprintf("frame_%s.rds", key))
saveRDS(frame, f_frame)
stamp("wrote ", f_frame)

# ---- report --------------------------------------------------------------------------------------------
fmt <- function(x) utils::capture.output(print(x, row.names = FALSE, digits = 4))
rng <- do.call(rbind, lapply(tb_traits, function(t) {
  x <- stations[[t]]
  data.frame(trait = t, min = min(x), q25 = unname(stats::quantile(x, 0.25)), median = stats::median(x),
             q75 = unname(stats::quantile(x, 0.75)), max = max(x), n_zero = sum(x == 0))
}))
by_sub <- as.data.frame(table(sub_drainage = substr(stations$station_number, 1, 3)), responseName = "stations")
by_sub$station_years <- as.integer(tapply(stations$n_years, substr(stations$station_number, 1, 3), sum)[
  as.character(by_sub$sub_drainage)])
fold_n <- table(stations$fold)
lines <- c(
  "Holdout frame of the whole-station temperature baseline (#213)",
  sprintf("frame: %s", key),
  sprintf("HYDAT %s; province run %s; glacier cache %s; lake cache %s", release, basename(key_dir),
          basename(g$f_gl), basename(f_lk)),
  sprintf("lake cover reads %d FWA lakes (%.0f km2) and %d manmade waterbodies (%.0f km2)",
          lk_table$n[lk_table$tbl == "fwa_lakes_poly"], lk_table$m2[lk_table$tbl == "fwa_lakes_poly"] / 1e6,
          lk_table$n[lk_table$tbl == "fwa_manmade_waterbodies_poly"],
          lk_table$m2[lk_table$tbl == "fwa_manmade_waterbodies_poly"] / 1e6),
  "",
  sprintf("truth: %d station-years at %d stations; kept: %d station-years at %d stations",
          n_truth[["station_years"]], n_truth[["stations"]], nrow(truth), nrow(stations)),
  sprintf("truth years dropped as a sensor reading one value (season sd under %.1f degC): %d%s",
          stuck_sd, nrow(stuck),
          if (nrow(stuck)) paste0(" (", paste(stuck$station_number, stuck$year, collapse = ", "), ")") else ""),
  sprintf(paste("already snapped by the water balance (%s): %d; accepted by both, every one on the same",
                "segment: %d; rejected by both: %d"),
          basename(wb_stations_path(release)), length(both), n_both[["accepted"]], n_both[["rejected"]]),
  sprintf("HYDAT regulation flag at the kept stations: %s",
          paste(names(table(stations$regulated)), table(stations$regulated), collapse = ", ")),
  sprintf("folds (WSC sub-sub-drainage): %d; stations per fold: median %g, largest %d; folds of one station: %d",
          length(fold_n), stats::median(fold_n), max(fold_n), sum(fold_n == 1)),
  sprintf("headwater %d, nested %d; lake outlets %d; with any glacier upstream %d; with any lake upstream %d",
          sum(stations$nesting == "headwater"), sum(stations$nesting == "nested"), sum(stations$lake %in% TRUE),
          sum(stations$glacier > 0), sum(stations$lake_cover > 0)),
  sprintf(paste("related pairs (one upstream of the other): %d; in different folds, so removed only by the",
                "leak-free pool: %d; stations with at least one such neighbour: %d"),
          sum(related) / 2, sum(related & !same_fold) / 2, sum(rowSums(related & !same_fold) > 0)),
  "",
  "## Traits at the kept stations", fmt(rng), "",
  "## Kept stations by WSC sub-drainage", fmt(by_sub), "",
  sprintf("## Dropped stations (%d, %d truth station-years)", nrow(dropped), sum(dropped$n_years)),
  if (nrow(dropped)) fmt(dropped) else "none")
dir.create(dirname(tb_frame_report), recursive = TRUE, showWarnings = FALSE)
writeLines(lines, tb_frame_report)
cat(lines, sep = "\n")
