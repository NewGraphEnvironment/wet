# Gauge side in the dry interior (#53): flag the shipped fit's calibration
# gauges whose basins hold licensed surface-water diversions, and rescore the
# held-out predictions without them and against naturalized flows, under the
# rule pre-registered in the #53 findings ("Pre-registered rule" as changed by
# "Amendment 1"; archived with #53) before any licence was joined to a gauge.
#
#   WET_HYDAT=<Hydat.sqlite3 of 2026-07-17> WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_gauge_diversion.R
#
# HYDAT's regulation flag cannot do this: wet_station_select() keeps only
# REGULATED = 0, so every calibration gauge is already "natural" to HYDAT.
# Stages, cached under data/gauge_div/ (gitignored):
#   1. raw snapshots of BC water rights licences (points of diversion) and BC
#      dams, downloaded once and kept (their md5 is in the report). Licensee
#      names and addresses are not requested;
#   2. each point placed in an FWA fundamental watershed and tested upstream of
#      each calibration gauge: whse_basemapping.fwa_upstream() on codes, and
#      by stream position for points in the gauge's own reach;
#   3. per gauge: licensed consumptive depth L and storage share S over the
#      gauge's own complete years, and the flags;
#   4. the drop test, the naturalized test, the verdict and its checks.
# Report: data/checks/wb_gauge_diversion_<release>.txt (tracked, wb_report()). Connection from WET_PG*.

source("scripts/wb_cv_lib.R")  # cal, mae(), fit_dir, release, score_code_md5, stamp(); loads the source tree
dry <- c("15", "17", "23", "24")
years <- c(1981L, 2010L)  # the observation window licences are weighted over
out_dir <- file.path("data", "gauge_div")
raw_dir <- file.path(out_dir, "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# a cache is renamed into place only once complete, so a killed run leaves none
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}

# ---- 1. raw snapshots ----------------------------------------------------------------------
# The BC WFS caps an un-paged GetFeature at 10,000 features and still answers
# 200, so each layer is paged in a stable order and held to the server's own
# count, recorded when the snapshot was taken.
wfs <- "https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0&typeName=pub:WHSE_WATER_MANAGEMENT."
layers <- list(
  licences = list(name = "WLS_WATER_RIGHTS_LICENCES_SV", sort = "WLS_WRL_SYSID", geom = "SHAPE",
                  fields = c("WLS_WRL_SYSID", "POD_NUMBER", "POD_SUBTYPE", "POD_DIVERSION_TYPE", "POD_STATUS",
                             "LICENCE_NUMBER", "LICENCE_STATUS", "LICENCE_STATUS_DATE", "PRIORITY_DATE", "PURPOSE_USE_CODE",
                             "PURPOSE_USE", "SOURCE_NAME", "REDIVERSION_IND", "QUANTITY", "QUANTITY_UNITS",
                             "QUANTITY_FLAG", "QUANTITY_FLAG_DESCRIPTION", "HYDRAULIC_CONNECTIVITY")),
  dams = list(name = "WRIS_DAMS_PUBLIC_SVW", sort = "WRIS_DP_SYSID", geom = "GEOMETRY",
              fields = c("WRIS_DP_SYSID", "DAM_FILE_NUMBER", "DAM_NAME", "COMMISSIONED_YEAR", "DAM_FUNCTION",
                         "DAM_REGULATED_CODE", "DAM_OPERATION_CODE", "DAM_TYPE", "DAM_HEIGHT"))
)
page_size <- 10000
snapshot <- function(k) {
  l <- layers[[k]]
  f_hits <- file.path(raw_dir, paste0(k, "_hits.txt"))
  if (!file.exists(f_hits)) {
    tmp <- tempfile(fileext = ".xml")
    wet:::wet_download(paste0(wfs, l$name, "&request=GetFeature&resultType=hits"), tmp, 300)
    n <- as.integer(sub('.*numberMatched="([0-9]+)".*', "\\1", paste(readLines(tmp, warn = FALSE), collapse = "")))
    stopifnot(!is.na(n), n > 0)
    writeLines(as.character(n), paste0(f_hits, ".part"))
    file.rename(paste0(f_hits, ".part"), f_hits)
  }
  n <- as.integer(readLines(f_hits))
  pages <- seq(0, n - 1, by = page_size)
  f <- file.path(raw_dir, sprintf("%s_%02d.csv", k, seq_along(pages)))
  # Each page must start after the previous one ends (a malformed startIndex,
  # such as paste0()'s "1e+05", is answered with the first page); a page that
  # does not is fetched again.
  ids <- function(p) as.numeric(utils::read.csv(p, colClasses = "character")[[l$sort]])
  last <- -Inf
  for (i in seq_along(pages)) {
    for (try in 1:3) {
      if (!file.exists(f[i])) {
        stamp("downloading ", k, " page ", i, " of ", length(pages))
        wet:::wet_download(paste0(wfs, l$name, "&request=GetFeature&outputFormat=csv&srsName=EPSG:3005",
                                  "&sortBy=", l$sort, "&count=", page_size, "&startIndex=", sprintf("%d", as.integer(pages[i])),
                                  "&propertyName=", paste(c(l$fields, l$geom), collapse = ",")), f[i], 1800)
      }
      id <- ids(f[i])
      if (length(id) && !is.unsorted(id, strictly = TRUE) && id[1] > last) break
      stamp(k, " page ", i, " is out of sequence (first id ", id[1], " after ", last, "): fetching again")
      unlink(f[i])
    }
    if (!file.exists(f[i])) stop(k, " page ", i, " out of sequence 3 times", call. = FALSE)
    last <- id[length(id)]
  }
  f
}
raw <- lapply(stats::setNames(names(layers), names(layers)), snapshot)
read_layer <- function(k) {
  x <- do.call(rbind, lapply(raw[[k]], utils::read.csv, stringsAsFactors = FALSE, na.strings = "",
                             colClasses = "character"))
  n <- as.integer(readLines(file.path(raw_dir, paste0(k, "_hits.txt"))))
  id <- layers[[k]]$sort
  if (nrow(x) != n || anyDuplicated(x[[id]])) {
    stop(k, ": ", nrow(x), " rows (", sum(duplicated(x[[id]])), " duplicated ids) against the server's ", n,
         call. = FALSE)
  }
  x
}
lic <- read_layer("licences")
dams <- read_layer("dams")
raw_md5 <- vapply(unlist(raw), function(f) unname(tools::md5sum(f)), "")
stamp(nrow(lic), " licence points, ", nrow(dams), " dams")
raw_key <- substr(wet:::wet_md5_text(paste(raw_md5, collapse = "|")), 1, 10)

# ---- licence rows (rule "Licences counted", Amendment 1 items 1-7) ------------------------
lic$units <- trimws(lic$QUANTITY_UNITS)
to_m3yr <- c("m3/year" = 1, "m3/day" = 365.25, "m3/sec" = 365.25 * 86400)
lic$m3yr <- as.numeric(lic$QUANTITY) * unname(to_m3yr[lic$units])  # NA: no volume
lic$py <- as.integer(substr(lic$PRIORITY_DATE, 1, 4))
lic$sy <- as.integer(substr(lic$LICENCE_STATUS_DATE, 1, 4))
lic$current <- lic$LICENCE_STATUS %in% "Current"
lic$start <- lic$py
lic$end <- ifelse(lic$current, years[2], lic$sy)  # NA start or end: never in force (counted)
storage_codes <- c("08A", "12A", "11A")
instream_codes <- c("07A", "07B", "07C", "11B", "11C", "02E", "02I38", "02I26", "08B")
core_codes <- c("01A", "01A01", "WSA01", "03A", "03B", "00A", "00B", "00C", "02I35", "02I31", "WSA08")
lic$class <- ifelse(is.na(lic$PURPOSE_USE_CODE), "none",
                    ifelse(lic$PURPOSE_USE_CODE %in% storage_codes, "storage",
                           ifelse(lic$PURPOSE_USE_CODE %in% instream_codes, "instream", "consumptive")))
lic$located <- !is.na(lic$SHAPE)
lic$surface <- lic$POD_SUBTYPE %in% "POD"
lic$redivert <- lic$REDIVERSION_IND %in% "Y"
# replaced: a non-current row whose POD, purpose and priority date a Current row carries
key3 <- paste(lic$POD_NUMBER, lic$PURPOSE_USE_CODE, lic$PRIORITY_DATE, sep = "|")
key3[is.na(lic$POD_NUMBER) | is.na(lic$PURPOSE_USE_CODE) | is.na(lic$PRIORITY_DATE)] <- NA  # paste() writes NA as "NA"
lic$replaced <- !lic$current & !is.na(key3) & key3 %in% key3[lic$current & !is.na(key3)]
# The view repeats a row for each licensee: one row per licence-purpose, POD,
# quantity flag and units is kept (the first located one by id), at the largest quantity its
# repeats carry, so quantity, flag and units come from rows that agree on all
# three (Deviation 1, code-check rounds 1 and 2). Every count below is over the
# kept rows.
# located rows first, so a repeat without a location never displaces one with
lic <- lic[order(!lic$located, as.numeric(lic$WLS_WRL_SYSID)), ]
lic$grp <- paste(lic$LICENCE_NUMBER, lic$PURPOSE_USE_CODE, sep = "|")
pod_key <- ifelse(is.na(lic$POD_NUMBER), paste0("no POD|", lic$WLS_WRL_SYSID),
                  paste(lic$grp, lic$POD_NUMBER, lic$QUANTITY_FLAG, lic$units, sep = "|"))
lic$dup_pod <- duplicated(pod_key)
max_or_na <- function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE)
lic$m3yr_pod <- unname(tapply(lic$m3yr, pod_key, max_or_na)[pod_key])
# one quantity per licence-purpose (M, no flag, or a D/P group whose distinct
# PODs all carry one quantity), the maximum over those rows, split over their
# distinct located PODs; T, D, P: each POD's own
one <- !lic$dup_pod
dp <- lic$QUANTITY_FLAG %in% c("D", "P")
dp_rep <- tapply(lic$m3yr_pod[dp & one], lic$grp[dp & one], function(v) length(v) > 1 && length(unique(v)) == 1)
lic$shared <- lic$QUANTITY_FLAG %in% "M" | is.na(lic$QUANTITY_FLAG) | (dp & dp_rep[lic$grp] %in% TRUE)
# the shared quantity comes from the shared rows only: a T row in the same
# licence-purpose is its own POD's (Deviation 1)
g_max <- tapply(lic$m3yr_pod[lic$shared], lic$grp[lic$shared], max_or_na)
g_npod <- tapply(lic$located & one & lic$shared, lic$grp, sum)
lic$g_full <- unname(g_max[lic$grp])
lic$g_npod <- as.integer(g_npod[lic$grp])
lic$v <- ifelse(lic$shared, lic$g_full / lic$g_npod, lic$m3yr_pod)
lic$pid <- paste0("L", lic$WLS_WRL_SYSID)
# rows that can count anywhere (each variant narrows these)
lic$candidate <- lic$located & lic$class %in% c("consumptive", "storage") & !lic$dup_pod &
  !is.na(lic$v) & lic$v > 0 & !lic$redivert
# g_npod counts a shared group's located PODs; the straddle test compares it with
# the group's candidate pairs upstream, so every located kept POD of a shared
# group must be a candidate (true of snapshot 9adbffe764; checked, not assumed)
sh <- lic$shared & lic$located & !lic$dup_pod & lic$grp %in% lic$grp[lic$candidate & lic$shared]
stopifnot(all(lic$candidate[sh]))
dams$pid <- paste0("D", dams$WRIS_DP_SYSID)

# ---- 2. placement --------------------------------------------------------------------------
conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)
# dams at the midpoint of the crest's longest part
sql_place <- c("
  CREATE TEMP TABLE gd_pt AS
  SELECT pid, CASE WHEN GeometryType(g) LIKE '%LINESTRING' THEN ST_LineInterpolatePoint(
                 (SELECT d.geom FROM ST_Dump(ST_LineMerge(g)) d ORDER BY ST_Length(d.geom) DESC, d.path LIMIT 1), 0.5)
               ELSE g END geom
  FROM (SELECT pid, ST_SetSRID(ST_GeomFromText(wkt), 3005) g FROM gd_raw) r", "
  CREATE TEMP TABLE gd_ws AS
  SELECT DISTINCT ON (p.pid) p.pid, w.watershed_feature_id, w.wscode_ltree wscode, w.localcode_ltree localcode, p.geom
  FROM gd_pt p JOIN whse_basemapping.fwa_watersheds_poly w ON ST_Intersects(p.geom, w.geom)
  ORDER BY p.pid, w.watershed_feature_id", "
  CREATE INDEX ON gd_ws USING gist (wscode)", "
  ANALYZE gd_ws", "
  CREATE TEMP TABLE gd_gm AS
  SELECT g.station_number, g.wscode, g.localcode, s.blue_line_key,
         s.downstream_route_measure + ST_LineLocatePoint(ST_LineMerge(ST_Force2D(s.geom)),
           ST_Transform(ST_SetSRID(ST_MakePoint(g.lon, g.lat), 4326), 3005)) * s.length_metre AS measure
  FROM gd_g g JOIN whse_basemapping.fwa_stream_networks_sp s ON s.linear_feature_id = g.linear_feature_id")
# upstream on codes; own reach (the gauge's exact codes) flagged for the stream-position test
sql_up <- "
  SELECT g.station_number, p.pid, (p.wscode = g.wscode::ltree AND p.localcode = g.localcode::ltree) AS own
  FROM gd_g g JOIN gd_ws p ON p.wscode <@ g.wscode::ltree
  WHERE whse_basemapping.fwa_upstream(g.wscode::ltree, g.localcode::ltree, p.wscode, p.localcode)"
sql_own <- "
  SELECT o.station_number, o.pid, i.blue_line_key IS NOT NULL AS indexed,
         whse_basemapping.fwa_upstream(m.blue_line_key, m.measure, m.wscode::ltree, m.localcode::ltree,
           i.blue_line_key, i.downstream_route_measure, i.wscode_ltree, i.localcode_ltree) AS upstream
  FROM gd_own o JOIN gd_ws p ON p.pid = o.pid JOIN gd_gm m ON m.station_number = o.station_number
  LEFT JOIN LATERAL whse_basemapping.fwa_indexpoint(p.geom, 100, 1) i ON true"
pts <- rbind(
  data.frame(pid = lic$pid[lic$located], wkt = lic$SHAPE[lic$located]),
  data.frame(pid = dams$pid, wkt = dams$GEOMETRY)
)
gauges <- cal[c("station_number", "watershed_feature_id", "wscode", "localcode", "linear_feature_id", "lon", "lat")]
gauges <- gauges[order(gauges$station_number), ]
place_key <- substr(wet:::wet_md5_text(paste(c("placed pids", raw_key, sql_place, sql_up, sql_own, do.call(paste, gauges)),
                                             collapse = "|")), 1, 10)
f_place <- file.path(out_dir, sprintf("placement_%s.rds", place_key))
if (!file.exists(f_place)) {
  stamp("placing ", nrow(pts), " points")
  DBI::dbWriteTable(conn, "gd_raw", pts, temporary = TRUE)
  DBI::dbWriteTable(conn, "gd_g", gauges, temporary = TRUE)
  for (q in sql_place) DBI::dbExecute(conn, q)
  stamp("upstream of ", nrow(gauges), " gauges")
  up <- DBI::dbGetQuery(conn, sql_up)
  DBI::dbWriteTable(conn, "gd_own", unique(up[up$own, c("station_number", "pid")]), temporary = TRUE)
  own <- DBI::dbGetQuery(conn, sql_own)
  placed <- DBI::dbGetQuery(conn, "SELECT pid FROM gd_ws")$pid
  n_gm <- DBI::dbGetQuery(conn, "SELECT count(*) n FROM gd_gm WHERE measure IS NOT NULL")$n
  save_atomic(list(up = up, own = own, placed = sort(placed), n_gm = as.integer(n_gm)), f_place)
}
DBI::dbDisconnect(conn)
pl <- readRDS(f_place)
stopifnot(pl$n_gm == nrow(gauges), !anyDuplicated(pl$up[c("station_number", "pid")]),
          !anyDuplicated(pl$own[c("station_number", "pid")]))
up <- pl$up
k_own <- match(paste(up$station_number, up$pid), paste(pl$own$station_number, pl$own$pid))
stopifnot(identical(!is.na(k_own), up$own))
up$indexed <- pl$own$indexed[k_own]
up$below <- up$own & up$indexed %in% TRUE & !(pl$own$upstream[k_own] %in% TRUE)
up <- up[!up$below, ]
up <- up[order(up$station_number, up$pid), ]

# ---- 3. per gauge ---------------------------------------------------------------------------
cv <- readRDS(file.path(fit_dir, "cv_aet-cfu.rds"))
stopifnot(identical(cv$aet, "cfu"), identical(cv$release, release),
          identical(cv$code_md5, score_code_md5))  # a fit made under this scoring code
g <- cal[c("station_number", "station_name", "zone", "nesting", "area_km2", "obs", "n_years")]
g <- g[order(g$station_number), ]
i_cv <- match(g$station_number, cv$station_number)
g$cv <- cv$cv_ann[i_cv]
g$raw <- cv$raw[i_cv]
stopifnot(!anyNA(g$cv), !anyNA(g$raw), isTRUE(all.equal(g$obs, cv$obs[i_cv])))
# each gauge's complete years, the ones obs averages (Amendment 1, item 4)
sel <- wet_station_select(wb_hydat(release), years = years[1]:years[2], min_years = 10)
gy <- attr(sel, "years")[g$station_number]
stopifnot(!any(vapply(gy, is.null, TRUE)), identical(unname(lengths(gy)), as.integer(g$n_years)))

# one row per (gauge, licence row) upstream, with both in-force weights
u <- merge(up[c("station_number", "pid", "own")],
           lic[lic$candidate, c("pid", "grp", "class", "PURPOSE_USE_CODE", "units", "surface", "current",
                                "replaced", "shared", "start", "end", "v", "g_full", "g_npod",
                                "HYDRAULIC_CONNECTIVITY")], by = "pid")
in_force <- function(start, end, yrs) if (is.na(start) || is.na(end)) 0 else mean(yrs >= start & yrs <= end)
u$w <- mapply(function(s, a, b) in_force(a, b, gy[[s]]), u$station_number, u$start, u$end)
u$w30 <- mapply(function(a, b) in_force(a, b, years[1]:years[2]), u$start, u$end)
u <- u[order(u$station_number, u$pid), ]
# a shared group straddles a gauge when only some of its PODs are upstream of it
n_up <- table(paste(u$station_number, u$grp)[u$shared])
u$straddle <- u$shared & as.integer(n_up[paste(u$station_number, u$grp)]) < u$g_npod
mm <- function(vol, km2) vol / (km2 * 1e6) * 1000
# L (mm/yr) for a mask over u; vol per row is w * v, or a straddling group at 0 or in full
depth <- function(mask, weight = u$w, straddle = c("split", "zero", "full"), cls = "consumptive") {
  straddle <- match.arg(straddle)
  vol <- weight * u$v
  m <- mask & u$class == cls
  if (straddle == "zero") vol[u$straddle] <- 0
  if (straddle == "full") {
    # each straddling group counted once, at its full quantity, on its first row the mask keeps
    j <- which(m & u$straddle)
    first <- !duplicated(paste(u$station_number[j], u$grp[j]))
    vol[j] <- ifelse(first, weight[j] * u$g_full[j], 0)
  }
  s <- tapply(vol[m], factor(u$station_number[m], g$station_number), sum)
  s[is.na(s)] <- 0
  mm(unname(s), g$area_km2)
}
base_mask <- u$surface & !u$replaced
g$L <- depth(base_mask)
g$S <- depth(base_mask, cls = "storage") / g$obs
g$n_cons <- as.integer(table(factor(u$station_number[base_mask & u$class == "consumptive"], g$station_number)))
g$n_stor <- as.integer(table(factor(u$station_number[base_mask & u$class == "storage"], g$station_number)))
g$n_dams <- as.integer(table(factor(up$station_number[up$pid %in% dams$pid], g$station_number)))
L_var <- list(
  current_only = depth(base_mask & u$current),
  no_replacement_removal = depth(u$surface),
  core = depth(base_mask & u$PURPOSE_USE_CODE %in% core_codes),
  no_m3sec = depth(base_mask & u$units != "m3/sec"),
  w30 = depth(base_mask, weight = u$w30),
  no_own_reach = depth(base_mask & !u$own),
  split_zero = depth(base_mask, straddle = "zero"),
  split_full = depth(base_mask, straddle = "full")
)
g$L_gw <- depth(!u$surface & !u$replaced)
g$L_gw_likely <- depth(!u$surface & !u$replaced & u$HYDRAULIC_CONNECTIVITY %in% "Likely")
d_at <- function(L, thr = 0.10) L >= thr * g$obs
g$D <- d_at(g$L)
g$Sf <- g$S >= 0.10
g$placement_sensitive <- g$D != d_at(L_var$no_own_reach)
g$split_sensitive <- d_at(L_var$split_zero) != d_at(L_var$split_full)
g$window_sensitive <- g$D != d_at(L_var$w30)

# ---- 4. tests and verdict -------------------------------------------------------------------
n_draws <- 10000
signed_log <- function(o, p) mean(log(p / o))
med_abs <- function(o, p) stats::median(abs(100 * (p - o) / o))
# step 1, the drop test, and step 2, the naturalized test, on gauges `x` (a subset
# of g) with D flags and L; thresholds relative to x's own baselines (Amendment 1)
decide <- function(x, D, L, pred = x$cv) {
  d <- x$zone %in% dry
  z24 <- x$zone == "24"
  b_dry <- mae(x$obs[d], pred[d])
  b24 <- mae(x$obs[z24], pred[z24])
  r <- list(b_dry = b_dry, b24 = b24, n24 = sum(z24), n_flag_dry = sum(d & D), n_flag24 = sum(z24 & D),
            n_kept24 = sum(z24 & !D))
  # step 1
  k <- d & !D
  r$d_dry <- b_dry - mae(x$obs[k], pred[k])
  r$d24 <- b24 - mae(x$obs[z24 & !D], pred[z24 & !D])
  med <- tapply(x$obs, x$zone, stats::median)
  stratum <- ifelse(d, paste(x$zone, x$obs > med[x$zone]), NA)
  strata <- sort(unique(stratum[d]))
  members <- lapply(strata, function(s) which(stratum %in% s))
  kk <- vapply(members, function(m) sum(D[m]), 0L)
  draw_d <- function(sets) {
    set.seed(53)
    t(vapply(seq_len(n_draws), function(i) {
      drop <- unlist(lapply(seq_along(sets$m), function(j) sets$m[[j]][sample.int(length(sets$m[[j]]), sets$k[j])]))
      keep <- setdiff(which(d), drop)
      c(b_dry - mae(x$obs[keep], pred[keep]), b24 - mae(x$obs[intersect(keep, which(z24))], pred[intersect(keep, which(z24))]))
    }, c(0, 0)))
  }
  nul <- draw_d(list(m = members, k = kk))
  r$p_dry <- mean(nul[, 1] >= r$d_dry - 1e-9)
  r$p24 <- mean(nul[, 2] >= r$d24 - 1e-9, na.rm = TRUE)
  is24 <- grepl("^24 ", strata)
  r$minp_dry <- 1 / prod(choose(lengths(members), kk))
  r$minp24 <- 1 / prod(choose(lengths(members)[is24], kk[is24]))
  r$step1 <- if (r$n_kept24 < 3) {
    "too few"
  } else if (r$d_dry >= 10 && r$d24 >= 0.5 * b24) {
    if (r$p_dry <= 0.05 && r$p24 <= 0.05) "select"
    else if (max(r$minp_dry, r$minp24) > 0.05) "uninformative" else "inconclusive"
  } else if (r$d_dry < 5 && r$d24 < 0.25 * b24) {
    "no"
  } else {
    "inconclusive"
  }
  # step 2
  natural <- function(Lx, f) c(dry = b_dry - mae(x$obs[d] + f * Lx[d], pred[d]),
                               z24 = b24 - mae(x$obs[z24] + f * Lx[z24], pred[z24]))
  n05 <- natural(L, 0.5)
  n1 <- natural(L, 1)
  r$dn_dry <- n05[["dry"]]
  r$dn24 <- n05[["z24"]]
  r$dn24_f1 <- n1[["z24"]]
  r$dn_dry_f1 <- n1[["dry"]]
  set.seed(53)
  zl <- split(which(d), x$zone[d])
  nn <- t(vapply(seq_len(n_draws), function(i) {
    Lp <- L
    for (m in zl) Lp[m] <- L[m][sample.int(length(m))]
    natural(Lp, 0.5)
  }, c(dry = 0, z24 = 0)))
  r$pn_dry <- mean(nn[, "dry"] >= r$dn_dry - 1e-9)
  r$pn24 <- mean(nn[, "z24"] >= r$dn24 - 1e-9)
  r$step2 <- if (r$dn24 >= 0.5 * b24 && r$dn_dry >= 10 && r$pn24 <= 0.05 && r$pn_dry <= 0.05) {
    "accounts"
  } else if (r$dn24_f1 < 0.25 * b24) {
    "cannot"
  } else {
    "neither"
  }
  r$verdict <- if (r$step2 == "cannot") {
    "not gauge side"
  } else if (r$step1 %in% c("select", "too few") && r$step2 == "accounts") {
    "gauge side"
  } else if (r$step1 == "select") {
    "flags select the bad gauges, but licensed water cannot account for the overshoot: unresolved"
  } else {
    "inconclusive"
  }
  r
}
base <- decide(g, g$D, g$L)
stopifnot(sum(g$zone %in% dry) == 40, base$n24 == 9, round(base$b_dry, 1) == 42.8, round(base$b24, 1) == 92.8,
          round(mae(g$obs, g$cv), 1) == 27.5)
# as registered: zone-only random removal
set.seed(53)
dz <- which(g$zone %in% dry)
kz <- table(factor(g$zone[dz][g$D[dz]], dry))
reg_null <- vapply(seq_len(n_draws), function(i) {
  drop <- unlist(lapply(dry, function(z) {
    m <- dz[g$zone[dz] == z]
    m[sample.int(length(m), kz[[z]])]
  }))
  keep <- setdiff(dz, drop)
  base$b_dry - mae(g$obs[keep], g$cv[keep])
}, 0)
# stability (Amendment 1, item 15)
stab <- c(
  vapply(which(g$zone %in% dry & g$D), function(i) {
    D2 <- g$D
    D2[i] <- FALSE
    paste0("unflag ", g$station_number[i], ": ", decide(g, D2, g$L)$verdict)
  }, ""),
  vapply(which(g$zone == "24"), function(i) {
    paste0("without ", g$station_number[i], ": ", decide(g[-i, ], g$D[-i], g$L[-i])$verdict)
  }, "")
)
stable <- all(sub("^[^:]+: ", "", stab) == base$verdict)
verdict <- if (stable) base$verdict else sprintf("unstable (%s)", base$verdict)
# reported verdicts
sens <- list(
  "D threshold 0.05" = decide(g, d_at(g$L, 0.05), g$L),
  "D threshold 0.20" = decide(g, d_at(g$L, 0.20), g$L),
  "D or S" = decide(g, g$D | g$Sf, g$L),
  "core consumptive" = decide(g, d_at(L_var$core), L_var$core),
  "without m3/sec" = decide(g, d_at(L_var$no_m3sec), L_var$no_m3sec),
  "Current licences only" = decide(g, d_at(L_var$current_only), L_var$current_only),
  "no replacement removal" = decide(g, d_at(L_var$no_replacement_removal), L_var$no_replacement_removal),
  "zone 15 on raw error" = decide(g, g$D, g$L, pred = ifelse(g$zone == "15", g$raw, g$cv))
)
labels <- character(0)
if (base$verdict == "gauge side" && sens[["D threshold 0.05"]]$verdict != "gauge side" &&
    sens[["D threshold 0.20"]]$verdict != "gauge side") labels <- c(labels, "threshold-dependent")
if (sens[["Current licences only"]]$verdict != base$verdict ||
    sens[["no replacement removal"]]$verdict != base$verdict) labels <- c(labels, "sensitive to licence history")
if (sens[["zone 15 on raw error"]]$verdict != base$verdict) labels <- c(labels, "depends on the zone-15 fit (not refit)")
# semi-blind replication in the non-dry zones
nd <- which(!g$zone %in% dry)
fl <- nd[g$D[nd]]
pool <- setdiff(nd, fl)
partner <- integer(0)
for (i in fl) {
  cand <- setdiff(pool, partner)
  same <- cand[g$zone[cand] == g$zone[i]]
  if (length(same)) cand <- same
  if (!length(cand)) break
  partner <- c(partner, cand[which.min(abs(log(g$obs[cand]) - log(g$obs[i])))])
}
rep_diff <- if (length(fl) && length(partner) == length(fl)) {
  stats::median(log(g$cv[fl] / g$obs[fl])) - stats::median(log(g$cv[partner] / g$obs[partner]))
} else NA_real_
if (length(fl) >= 10 && !is.na(rep_diff) && rep_diff <= 0) labels <- c(labels, "not replicated outside the dry zones")
if (length(labels)) verdict <- paste0(verdict, "; ", paste(labels, collapse = "; "))

save_atomic(list(gauges = g, upstream = u, L_var = L_var, base = base, sens = sens, verdict = verdict,
                 raw_md5 = raw_md5), file.path(out_dir, sprintf("gauges_%s.rds", release)))

# ---- report --------------------------------------------------------------------------------
f1 <- function(x) ifelse(is.na(x), "-", sprintf("%.1f", x))
pc <- function(x) ifelse(is.na(x), "-", sprintf("%.1f%%", x))
f3 <- function(x) ifelse(is.na(x), "-", sprintf("%.3f", x))
stat_cells <- function(i, pred) {
  k <- i & !g$D
  sprintf("%7s %7s %7s %7s %6s %6s", pc(mae(g$obs[i], pred[i])), pc(mae(g$obs[k], pred[k])),
          pc(med_abs(g$obs[i], pred[i])), pc(med_abs(g$obs[k], pred[k])),
          f3(signed_log(g$obs[i], pred[i])), f3(signed_log(g$obs[k], pred[k])))
}
zone_row <- function(lab, i) sprintf("%-5s %4d %4d %4d %4d | %s | %s", lab, sum(i), sum(i & g$D), sum(i & g$Sf),
                                     sum(i & !g$D), stat_cells(i, g$cv), stat_cells(i, g$raw))
res_lines <- function(r, lab) c(
  sprintf("%s: dry D-flagged %d, zone 24 D-flagged %d of %d, kept %d", lab, r$n_flag_dry, r$n_flag24, r$n24, r$n_kept24),
  sprintf("  step 1 drop: dry MAE %s, fall %s points (p %s, min attainable %s); zone 24 MAE %s, fall %s (p %s, min %s): %s",
          pc(r$b_dry), f1(r$d_dry), f3(r$p_dry), f3(r$minp_dry), pc(r$b24), f1(r$d24), f3(r$p24), f3(r$minp24), r$step1),
  sprintf("  step 2 naturalized (f 0.5): dry fall %s (p %s), zone 24 fall %s (p %s); at f 1: dry %s, zone 24 %s: %s",
          f1(r$dn_dry), f3(r$pn_dry), f1(r$dn24), f3(r$pn24), f1(r$dn_dry_f1), f1(r$dn24_f1), r$step2),
  sprintf("  verdict: %s", r$verdict))
d <- g[g$zone %in% dry, ]
d <- d[order(d$zone, d$station_number), ]
top_purpose <- function(s) {
  m <- base_mask & u$class == "consumptive" & u$station_number == s
  if (!any(m)) return("-")
  t <- sort(tapply(u$w[m] * u$v[m], u$PURPOSE_USE_CODE[m], sum), decreasing = TRUE)
  n <- seq_len(min(2, length(t)))
  if (sum(t) == 0) return(paste(names(t)[n], collapse = ", ") |> paste("(none in force)"))
  paste(sprintf("%s %.0f%%", names(t)[n], 100 * t[n] / sum(t)), collapse = ", ")
}
marks <- function(i) paste0(ifelse(d$placement_sensitive[i], "P", ""), ifelse(d$split_sensitive[i], "X", ""),
                            ifelse(d$window_sensitive[i], "W", ""))
gauge_line <- function(i) with(d[i, ], sprintf(
  "%-8s %-4s %-9s %7.0f %5.0f %5.0f %5.0f %6.1f %5.2f %5.2f %4d %4d %4d %6.1f %-4s %-4s %-22s %s",
  station_number, zone, nesting, area_km2, obs, cv, raw, L, L / obs, S, n_cons, n_stor, n_dams, L_gw,
  paste0(ifelse(D, "D", ""), ifelse(Sf, "S", ""), ifelse(!D & !Sf, "-", "")),
  ifelse(nzchar(marks(i)), marks(i), "-"), top_purpose(station_number), substr(station_name, 1, 28)))
cnt <- function(lab, i) sprintf("  %-46s %7d", lab, sum(i & one))
one <- !lic$dup_pod
sy_gap <- lic$sy[lic$current & one] - lic$py[lic$current & one]
kept_pid <- c(lic$pid[one & lic$located], dams$pid)
pl_up <- pl$up[pl$up$pid %in% kept_pid, ]
pl_own <- pl$own[pl$own$pid %in% kept_pid, ]
cap <- g[g$zone == "24" & g$D & g$cv > g$obs, ]
cap_lines <- if (nrow(cap)) vapply(seq_len(nrow(cap)), function(i) {
  ns <- L_var$no_m3sec[match(cap$station_number[i], g$station_number)]
  over <- cap$cv[i] - cap$obs[i]
  sprintf("  %-8s overshoot %5.0f mm; 0.5 L without m3/sec %6.1f mm: %s%s", cap$station_number[i], over, 0.5 * ns,
          if (0.5 * ns >= 0.5 * over) "reaches half" else "short of half",
          if (cap$L[i] < 0.5 * over) "; cannot account even at full entitlement" else "")
}, "") else "  (no flagged zone-24 gauge with cv > obs)"
s_only <- d$station_number[d$Sf & !d$D]
dam_lines <- vapply(d$station_number[d$n_dams > 0], function(st) {
  x <- dams[dams$pid %in% up$pid[up$station_number == st], ]
  t <- table(paste0(x$DAM_FUNCTION, " (", ifelse(is.na(x$DAM_REGULATED_CODE), "no class", x$DAM_REGULATED_CODE), ")"))
  sprintf("  %-8s %s", st, paste(sprintf("%s %d", names(t), as.integer(t)), collapse = "; "))
}, "")
if (!length(dam_lines)) dam_lines <- "  none"
rho_l <- suppressWarnings(stats::cor(d$L, d$cv - d$obs, method = "spearman"))
rho_reg <- suppressWarnings(stats::cor(d$L / d$obs, log(d$cv / d$obs), method = "spearman"))

out <- c(
  "# Gauge side in the dry interior (#53): the shipped fit's calibration gauges and licensed surface-water diversions",
  "",
  sprintf("fit: %s, province run %s, scoring code %s; held-out predictions cv_aet-cfu (no refit)", release,
          basename(key_dir), score_code_md5),
  "rule: pre-registered in the #53 findings before any licence or dam was joined to a gauge, as changed by Amendment 1",
  paste("deviation 1 (code-check rounds 1-2, after flags were seen): repeat rows of one licence-purpose, POD, flag and units",
        "kept once; a shared quantity taken from the shared rows only. The as-amended run on snapshot 9adbffe764: not gauge side",
        if (raw_key == "9adbffe764") "(this snapshot)" else "(THIS RUN'S SNAPSHOT DIFFERS)"),
  sprintf("snapshot (BC WFS, licensee fields not requested): %d licence points, %d dams; md5 over its %d pages %s",
          nrow(lic), nrow(dams), length(raw_md5), raw_key),
  sprintf("HYDAT regulated among the %d calibration gauges: 0 (wet_station_select() keeps REGULATED = 0 only)", nrow(g)),
  "",
  "## Licence rows",
  sprintf("  %-46s %7d", "rows in the snapshot", nrow(lic)),
  sprintf("  %-46s %7d", "repeat rows (left out; counts below exclude them)", sum(lic$dup_pod)),
  cnt("points of diversion, one per licence-purpose", rep(TRUE, nrow(lic))),
  cnt("surface (POD)", lic$surface),
  cnt("no location, surface, current (not placed)", !lic$located & lic$surface & lic$current),
  cnt("no location, surface, not current (not placed)", !lic$located & lic$surface & !lic$current),
  cnt("no volume: unit Total Flow, Hectares, Select or none", !lic$units %in% names(to_m3yr)),
  cnt("no volume: empty quantity", lic$units %in% names(to_m3yr) & is.na(lic$m3yr)),
  cnt("no priority date, or not current with no status date", is.na(lic$start) | is.na(lic$end)),
  cnt("replaced (a Current row carries POD, purpose, priority)", lic$replaced),
  cnt("rediversion (left out)", lic$redivert),
  sprintf("  %-46s %7d", "D/P groups repeating one quantity (as M)", sum(dp_rep, na.rm = TRUE)),
  cnt("surface consumptive candidates", lic$candidate & lic$surface & lic$class == "consumptive"),
  cnt("  of them m3/sec", lic$candidate & lic$surface & lic$class == "consumptive" & lic$units %in% "m3/sec"),
  cnt("surface storage candidates", lic$candidate & lic$surface & lic$class == "storage"),
  cnt("surface instream (not counted)", lic$surface & lic$class == "instream"),
  sprintf("Current rows, status year - priority year: < 0 %d, 0 %d, 1-10 %d, > 10 %d, missing %d",
          sum(sy_gap < 0, na.rm = TRUE), sum(sy_gap == 0, na.rm = TRUE), sum(sy_gap >= 1 & sy_gap <= 10, na.rm = TRUE),
          sum(sy_gap > 10, na.rm = TRUE), sum(is.na(sy_gap))),
  "purpose classes, fixed before placement:",
  sprintf("  storage %s; instream %s; core consumptive %s; consumptive: every other code",
          paste(storage_codes, collapse = " "), paste(instream_codes, collapse = " "), paste(core_codes, collapse = " ")),
  "",
  "## Placement",
  sprintf("placed in a fundamental watershed: %d of %d points (located kept licence rows and dams)",
          sum(kept_pid %in% pl$placed), length(kept_pid)),
  sprintf("point-gauge pairs upstream on codes: %d; in the gauge's own reach: %d, of which below the gauge by stream position %d, not indexed within 100 m (kept) %d",
          nrow(pl_up), sum(pl_up$own), sum(pl_own$indexed & !(pl_own$upstream %in% TRUE)), sum(!pl_own$indexed)),
  "",
  "## Flags by zone (D: licensed consumptive depth L >= 10 % of obs, deciding; S: licensed storage >= 10 % of annual runoff volume, reported)",
  "Held-out (cv), then raw P - AET: MAE all, kept; median |%| all, kept; mean log(pred/obs) all, kept.",
  "zone     n    D    S kept |  MAE all  kept  med all  kept  log all  kept |  raw: MAE all  kept  med all  kept  log all  kept",
  vapply(dry, function(z) zone_row(z, g$zone == z), ""),
  zone_row("dry", g$zone %in% dry),
  vapply(sort(setdiff(unique(g$zone), dry)), function(z) zone_row(z, g$zone == z), ""),
  zone_row("other", !g$zone %in% dry),
  zone_row("all", rep(TRUE, nrow(g))),
  "",
  "## Decision (dry zones 15/17/23/24)",
  res_lines(base, "registered"),
  sprintf("stability: %s", if (stable) "every leave-one-out run gives the same verdict" else "differs"),
  paste0("  ", stab),
  sprintf("VERDICT: %s", verdict),
  "",
  "## Reported, not deciding",
  sprintf("as-registered zone-only random removal: p95 of the dry fall %s; share of draws >= observed %s",
          f1(unname(stats::quantile(reg_null, 0.95))), f3(mean(reg_null >= base$d_dry - 1e-9))),
  unlist(lapply(names(sens), function(k) res_lines(sens[[k]], k))),
  "capacity (flagged zone-24 gauges with cv > obs):",
  cap_lines,
  sprintf("S only (regulated pattern; annual volume not depleted by the licence data): %s",
          if (length(s_only)) paste(s_only, collapse = ", ") else "none"),
  sprintf("Spearman over %d dry gauges: L (mm) against cv - obs (mm) %s; as registered, L/obs against log(cv/obs) %s (shares 1/obs on both sides, so not used)",
          nrow(d), f3(rho_l), f3(rho_reg)),
  sprintf("semi-blind replication, non-dry zones: %d D-flagged of %d; median log(cv/obs) flagged minus obs-matched unflagged %s",
          length(fl), length(nd), f3(rep_diff)),
  "dams upstream of dry gauges, by function and regulation class:",
  dam_lines,
  sprintf("dry gauges with groundwater consumptive licences upstream: %d (hydraulically connected, Likely: %d); in force over the gauge's years: %d (%d)",
          sum(d$station_number %in% u$station_number[!u$surface & u$class == "consumptive"]),
          sum(d$station_number %in% u$station_number[!u$surface & u$class == "consumptive" &
                                                       u$HYDRAULIC_CONNECTIVITY %in% "Likely"]),
          sum(d$L_gw > 0), sum(d$L_gw_likely > 0)),
  sprintf("dry gauges whose D flag differs on the 30-year weight (W): %d; placement-sensitive (P): %d; split-sensitive (X): %d",
          sum(d$window_sensitive), sum(d$placement_sensitive), sum(d$split_sensitive)),
  "limits: imports from another basin, off-stream storage, unlicensed use and reservoir evaporation are not seen; licensed quantities are entitlements, not use",
  "",
  "## Dry-zone gauges (mm/yr over the FWA upstream area; L consumptive, S storage / annual runoff volume, L_gw groundwater)",
  "marks: P placement-sensitive, X split-sensitive, W window-sensitive",
  "station  zone nesting       km2   obs    cv   raw      L L/obs     S cons stor dams   L_gw flag mark top consumptive purposes name",
  vapply(seq_len(nrow(d)), gauge_line, "")
)
f_report <- wb_report("wb_gauge_diversion", release)
writeLines(out, f_report)
stamp("wrote ", f_report, "; verdict: ", verdict)
