# Regulation per non-HYDAT station (#196, #191): a status for every station wet_station_list()
# lists, natural, regulated or unknown, from what sits upstream of it, under the rule registered
# in scripts/station_regulation_rule.R before this script existed.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/station_regulation.R
#
# Stages, cached under data/station_regulation/ (gitignored):
#   1. both WFS layers (dams, water rights licences) taken once into raw/<YYYYMMDD>/, paged and
#      held to the server's count (WET_REG_SNAPSHOT names the snapshot date; left unset, the
#      newest one there, or a new one today when there is none);
#   2. every station snapped by the rule (rg_snap_pick());
#   3. dams and licence points placed in FWA watersheds and tested upstream of each snapped
#      station, as #53 places them; the border and man-made waterbody tests;
#   4. the mean annual flow at each snapped segment from wet's published segment_monthly parts,
#      verified against the manifest before and after the read;
#   5. the status, written to inst/extdata/station_sources/regulation_<bcenv snapshot>.csv
#      (tracked, read by wet_station_list()) and the report
#      data/checks/station_regulation_<bcenv snapshot>.txt (tracked). Neither carries a time,
#      so a rerun from the caches writes the same bytes.
# Connection from WET_PG* (connect_timeout 10 s). Needs the Tool's pinned files in wet's cache.

pkgload::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/station_sources_lib.R")  # stream_of(), regulation_of()
source("scripts/station_regulation_rule.R")
source("scripts/station_regulation_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S "), ...)

# ---- the rule as registered ---------------------------------------------------------------------
rule_commit <- "6c9cb1e5f0ff2e667777449c697a403cb11f64aa"
rule_files <- c("scripts/station_regulation_rule.R", "scripts/station_sources_lib.R")
rule_md5 <- vapply(rule_files, function(f) {
  tmp <- tempfile()
  st <- system2("git", c("show", paste0(rule_commit, ":", f)), stdout = tmp, stderr = FALSE)
  if (!identical(st, 0L)) stop("cannot read ", f, " at the rule's registering commit ", rule_commit, call. = FALSE)
  reg <- unname(tools::md5sum(tmp))
  now <- unname(tools::md5sum(f))
  if (!identical(reg, now)) {
    stop(f, " differs from the rule's registering commit ", substr(rule_commit, 1, 8),
         ": an amendment is dated in the rule file and this commit moved with it", call. = FALSE)
  }
  now
}, "")

release <- wb_release()
snapshot <- wet_bcenv_snapshot
tool_snapshot <- wet_bcwatertool_snapshot
root <- file.path("data", "station_regulation")
dir.create(root, recursive = TRUE, showWarnings = FALSE)
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}
key_of <- function(...) substr(wet:::wet_md5_text(paste(c(...), collapse = "|")), 1, 10)

# ---- population: both registries, folded as wet_station_list() folds them ---------------------------
reg_path <- c(bcenv = sprintf("bcenv_%s_hydat.csv", snapshot),
              bcwatertool = sprintf("bcwatertool_%s_hydat.csv", tool_snapshot))
reg_path <- vapply(reg_path, function(f) system.file("extdata", "station_sources", f, package = "wet"), "")
reg_md5 <- vapply(reg_path, function(f) unname(tools::md5sum(f)), "")
prov <- wet:::wet_bcenv_stations(snapshot)
tool_all <- wet:::wet_bcwatertool_against(wet:::wet_bcwatertool_stations(tool_snapshot), snapshot)
wet:::wet_registry_check(tool_all, prov, snapshot)
tool <- tool_all[is.na(tool_all$continues), ]
st <- rbind(
  data.frame(station_number = prov$station_number, source = "bcenv", name = prov$name, lon = prov$lon,
             lat = prov$lat, id = NA_character_, hydat_site = prov$hydat_site, registry = prov$regulation),
  data.frame(station_number = tool$station_number, source = "bcwatertool", name = tool$name, lon = tool$lon,
             lat = tool$lat, id = tool$id, hydat_site = tool$hydat_site, registry = tool$regulation)
)
st <- st[order(st$source, st$station_number, method = "radix"), ]
rownames(st) <- NULL
stopifnot(!anyDuplicated(st$station_number), !anyNA(st$lon), !anyNA(st$lat))
st$name_regulated <- regulation_of(st$name) != "unknown"
stamp(nrow(st), " stations: ", sum(st$source == "bcenv"), " provincial, ", sum(st$source == "bcwatertool"), " Tool")

# ---- drainage areas: the Tool's header, else HYDAT's gross area at the station's site ---------------
paths <- wet:::wet_bcwatertool(tool$id, tool_snapshot)
tool_area <- vapply(seq_along(paths), function(i) {
  if (is.na(paths[i])) return(NA_character_)
  m <- wet:::wet_bcwatertool_read(paths[i], tool$id[i])$meta
  a <- unname(m[names(m) == "Drainage Area"])
  if (!length(a) || is.na(a[1]) || a[1] %in% c("", "None")) NA_character_ else a[1]
}, "")
if (any(!is.na(tool_area) & !grepl("^[0-9]+(\\.[0-9]+)?$", tool_area))) {
  bad <- unique(tool_area[!is.na(tool_area) & !grepl("^[0-9]+(\\.[0-9]+)?$", tool_area)])
  stop("a Tool drainage area is not a number: ", paste(bad, collapse = ", "))
}
st$area_km2 <- NA_real_
st$area_from <- NA_character_
i_tool <- match(tool$station_number, st$station_number)
st$area_km2[i_tool] <- as.numeric(tool_area)
st$area_from[i_tool[!is.na(tool_area)]] <- "Tool header"
con_h <- wet:::wet_hydat_connect(wb_hydat(release))
sites <- sort(unique(stats::na.omit(st$hydat_site)), method = "radix")
hy <- DBI::dbGetQuery(con_h, sprintf("
  SELECT s.STATION_NUMBER station_number, s.DRAINAGE_AREA_GROSS gross, r.REGULATED regulated
  FROM STATIONS s LEFT JOIN STN_REGULATION r USING (STATION_NUMBER)
  WHERE s.STATION_NUMBER IN (%s) ORDER BY 1", paste0("'", sites, "'", collapse = ",")))
DBI::dbDisconnect(con_h)
stopifnot(!anyDuplicated(hy$station_number), setequal(hy$station_number, sites))
k <- match(st$hydat_site, hy$station_number)
use_hy <- is.na(st$area_km2) & !is.na(k) & !is.na(hy$gross[k]) & hy$gross[k] > 0
st$area_km2[use_hy] <- hy$gross[k[use_hy]]
st$area_from[use_hy] <- paste("HYDAT", st$hydat_site[use_hy])
st$hydat_regulated <- hy$regulated[k]

# ---- 1. the WFS snapshot ---------------------------------------------------------------------------
raw_root <- file.path(root, "raw")
wfs_date <- Sys.getenv("WET_REG_SNAPSHOT", "")
if (!nzchar(wfs_date)) {
  have <- list.dirs(raw_root, recursive = FALSE, full.names = FALSE)
  have <- sort(have[grepl("^[0-9]{8}$", have)], method = "radix")
  wfs_date <- if (length(have)) have[length(have)] else format(Sys.time(), "%Y%m%d", tz = "UTC")
}
if (!grepl("^[0-9]{8}$", wfs_date)) stop("WET_REG_SNAPSHOT must be YYYYMMDD, not ", wfs_date)
raw_dir <- file.path(raw_root, wfs_date)
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
raw <- lapply(stats::setNames(names(rg_layers), names(rg_layers)), rg_wfs_snapshot, raw_dir = raw_dir,
              download = function(u, d) wet:::wet_download(u, d, 1800), msg = stamp)
lic_all <- rg_wfs_read("licences", raw$licences, raw_dir)
dams <- rg_wfs_read("dams", raw$dams, raw_dir)
raw_md5 <- vapply(unlist(raw), function(f) unname(tools::md5sum(f)), "")
names(raw_md5) <- basename(unlist(raw))
hits <- vapply(names(rg_layers), function(k) as.integer(readLines(file.path(raw_dir, paste0(k, "_hits.txt")))), 0L)
raw_key <- key_of(raw_md5)
stamp(nrow(lic_all), " licence rows, ", nrow(dams), " dams (snapshot ", wfs_date, ", ", raw_key, ")")

dams$regulating <- rg_dam_regulating(dams$DAM_OPERATION_CODE, dams$DAM_REGULATED_CODE, dams$DAM_FUNCTION)
dams$pid <- paste0("D", dams$WRIS_DP_SYSID)
lic <- rg_licence_rows(lic_all)

# ---- 2. snap ------------------------------------------------------------------------------------------
conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres"),
  connect_timeout = 10
)
sql_snap <- sprintf(rg_sql_snap, rg_snap_tolerance_m, rg_snap_candidates)
pts_st <- st[c("station_number", "lon", "lat")]
f_snap <- file.path(root, sprintf("snap_%s.rds", key_of("snap", sql_snap, do.call(paste, pts_st))))
if (!file.exists(f_snap)) {
  stamp("snapping ", nrow(st), " stations")
  DBI::dbWriteTable(conn, "rg_st", pts_st, temporary = TRUE)
  save_atomic(DBI::dbGetQuery(conn, sql_snap), f_snap)
  DBI::dbRemoveTable(conn, "rg_st", temporary = TRUE)
}
cand <- readRDS(f_snap)
cand <- cand[order(cand$station_number, cand$linear_feature_id, method = "radix"), ]
pick <- do.call(rbind, lapply(seq_len(nrow(st)), function(i) {
  rg_snap_pick(cand[cand$station_number == st$station_number[i], , drop = FALSE], st$name[i], st$area_km2[i])
}))
st <- cbind(st, pick)
j <- match(paste(st$station_number, st$linear_feature_id), paste(cand$station_number, cand$linear_feature_id))
for (v in c("gnis_name", "blue_line_key", "measure", "seg_wscode", "seg_localcode", "watershed_feature_id",
            "wscode", "localcode", "watershed_group_code")) {
  st[[v]] <- cand[[v]][j]
  st[[v]][!st$accepted] <- NA
}
st$snap_stream <- ifelse(st$accepted, st$gnis_name, NA_character_)
sn <- st[st$accepted, ]
# a snapped station with no codes would be tested upstream of nothing and read natural
codes <- c("wscode", "localcode", "seg_wscode", "seg_localcode", "blue_line_key", "measure")
if (anyNA(sn[codes])) {
  stop("a snapped station has no FWA codes or measure: ",
       paste(sn$station_number[!stats::complete.cases(sn[codes])], collapse = ", "))
}
stamp(nrow(sn), " of ", nrow(st), " stations snapped")

# ---- 3. placement, border, man-made waterbodies -------------------------------------------------
lic_pts <- lic[lic$located & (lic$candidate | lic$power | lic$novol), ]
dam_pts <- dams[dams$regulating & !is.na(dams$GEOMETRY), ]
pts <- rbind(data.frame(pid = lic_pts$pid, wkt = lic_pts$SHAPE),
             data.frame(pid = dam_pts$pid, wkt = dam_pts$GEOMETRY))
pts <- pts[order(pts$pid, method = "radix"), ]
stopifnot(!anyDuplicated(pts$pid))
gauges <- sn[c("station_number", "wscode", "localcode", "linear_feature_id", "lon", "lat")]
sn_net <- sn[c("station_number", "linear_feature_id", "blue_line_key", "measure", "seg_wscode", "seg_localcode")]
sql_border <- sprintf(rg_sql_border, paste0("'", rg_borders, "'", collapse = ", "))
place_key <- key_of("placed", raw_key, do.call(paste, pts), rg_sql_place, rg_sql_up, rg_sql_own, sql_border,
                    rg_sql_manmade, do.call(paste, gauges), do.call(paste, sn_net))
f_place <- file.path(root, sprintf("placement_%s.rds", place_key))
if (!file.exists(f_place)) {
  stamp("placing ", nrow(pts), " points")
  DBI::dbWriteTable(conn, "gd_raw", pts, temporary = TRUE)
  DBI::dbWriteTable(conn, "gd_g", gauges, temporary = TRUE)
  for (q in rg_sql_place) DBI::dbExecute(conn, q)
  stamp("upstream of ", nrow(gauges), " stations")
  up <- DBI::dbGetQuery(conn, rg_sql_up)
  DBI::dbWriteTable(conn, "gd_own", unique(up[up$own, c("station_number", "pid")]), temporary = TRUE)
  own <- DBI::dbGetQuery(conn, rg_sql_own)
  placed <- DBI::dbGetQuery(conn, "SELECT pid FROM gd_ws")$pid
  n_gm <- DBI::dbGetQuery(conn, "SELECT count(*) n FROM gd_gm WHERE measure IS NOT NULL")$n
  DBI::dbWriteTable(conn, "rg_sn", sn_net, temporary = TRUE)
  stamp("border and man-made waterbodies")
  border <- DBI::dbGetQuery(conn, sql_border)$station_number
  manmade <- DBI::dbGetQuery(conn, rg_sql_manmade)
  save_atomic(list(up = up, own = own, placed = sort(placed, method = "radix"), n_gm = as.integer(n_gm),
                   border = sort(border, method = "radix"), manmade = manmade), f_place)
}
DBI::dbDisconnect(conn)
pl <- readRDS(f_place)
stopifnot(pl$n_gm == nrow(gauges))
up <- rg_upstream_pairs(pl$up, pl$own)

# ---- 4. mean annual flow from the published parts -------------------------------------------------
catalog <- wet_catalog()
digest <- wet:::wet_catalog_digest(catalog)
parts <- catalog[catalog$dataset == "discharge/fwa/v1/segment_monthly" & catalog$scenario == "historical", ]
parts <- parts[order(parts$source, parts$code, method = "radix"), ]
ids <- sort(unique(sn$linear_feature_id))
groups <- sort(unique(sn$watershed_group_code), method = "radix")
f_flow <- file.path(root, sprintf("flow_%s.rds", key_of("flow", digest, ids, groups)))
if (!file.exists(f_flow)) {
  verify <- function() {
    v <- wet:::wet_catalog_verify(parts)
    if (!all(v$ok)) stop("published parts do not match the manifest (a publish under way?): ",
                         paste(v$key[!v$ok], v$reason[!v$ok], collapse = "; "))
    sum(v$ok)
  }
  stamp("reading flow at ", length(ids), " segments from ", nrow(parts), " parts")
  n_before <- verify()
  q <- wet_segment_monthly(NULL, ids, groups = groups, catalog = parts)
  n_after <- verify()
  save_atomic(list(q = q, n_verified = c(n_before, n_after)), f_flow)
}
fl <- readRDS(f_flow)
q0 <- fl$q[fl$q$month == 0 & fl$q$pick %in% TRUE, ]
if (anyDuplicated(q0$linear_feature_id)) stop("a segment has two picked sources at month 0")
st$q_m3s <- q0$q_m3s[match(st$linear_feature_id, q0$linear_feature_id)]
st$q_source <- q0$source[match(st$linear_feature_id, q0$linear_feature_id)]
st$q_m3s[!st$accepted] <- NA

# ---- 5. per station -----------------------------------------------------------------------------
count_by <- function(x) as.integer(table(factor(x, st$station_number)))
sum_by <- function(v, x) {
  s <- tapply(v, factor(x, st$station_number), sum)
  s[is.na(s)] <- 0
  unname(s)
}
flow_yr <- ifelse(!is.na(st$q_m3s) & st$q_m3s > 0, st$q_m3s * rg_year_s, NA_real_)
off <- !st$accepted
# The evidence and status of every station from the upstream pairs `up`; `novol` FALSE scores the
# rule as it stood before Amendment 2. Each version since stations were placed is scored from the
# same caches, so the report can give the statuses under each (the rule's amendment protocol).
score <- function(up, novol = TRUE) {
  u_lic <- merge(up[c("station_number", "pid", "own")],
                 lic_pts[c("pid", "class", "candidate", "surface", "power", "novol", "v")], by = "pid")
  u_dam <- up[up$pid %in% dam_pts$pid, ]
  # surface PODs only, as the rule says and #53's base_mask does
  cons <- u_lic$candidate & u_lic$surface & u_lic$class == "consumptive"
  stor <- u_lic$candidate & u_lic$surface & u_lic$class == "storage"
  x <- data.frame(
    dams_up = count_by(u_dam$station_number),
    L_m3yr = sum_by(u_lic$v[cons], u_lic$station_number[cons]),
    S_m3yr = sum_by(u_lic$v[stor], u_lic$station_number[stor]),
    n_cons = count_by(u_lic$station_number[cons]),
    n_stor = count_by(u_lic$station_number[stor]),
    power_up = st$station_number %in% u_lic$station_number[u_lic$power],
    novol_up = novol & st$station_number %in% u_lic$station_number[u_lic$novol],
    outside_bc = st$station_number %in% pl$border
  )
  x$L_share <- x$L_m3yr / flow_yr
  x$S_share <- x$S_m3yr / flow_yr
  for (v in c("dams_up", "power_up", "novol_up", "outside_bc", "L_share", "S_share")) x[[v]][off] <- NA
  s <- rg_status(st$name_regulated, st$accepted, x$dams_up, x$L_share, x$S_share, x$outside_bc, x$power_up,
                 x$novol_up)
  cbind(x, s)
}
cur <- score(up)
for (v in names(cur)) st[[v]] <- cur[[v]]
st$manmade_up <- pl$manmade$manmade_up[match(st$station_number, pl$manmade$station_number)]
st$manmade_up[is.na(st$manmade_up)] <- 0L
st$manmade_up[off] <- NA
# the versions since stations were placed: Amendment 1 alone (#53's own-reach test, no no-volume
# arm), with Amendment 2, and with Amendment 3 (the shipped one)
up_53 <- local({
  # no point on the station's line is within the margin, so #53's 1 mm test alone decides
  own <- pl$own
  own$below_m[own$same_line %in% TRUE] <- Inf
  rg_upstream_pairs(pl$up, own)
})
versions <- list(`Amendment 1` = score(up_53, novol = FALSE)$regulation,
                 `Amendments 1-2` = score(up_53)$regulation,
                 `Amendments 1-3` = st$regulation)
if (anyNA(st$regulation) || !all(st$regulation %in% rg_vocab)) stop("a status outside the vocabulary")
if (any(st$name_regulated & st$regulation != "regulated")) {
  stop("a station regulated by name came out ",
       paste(unique(st$regulation[st$name_regulated & st$regulation != "regulated"]), collapse = ", "))
}
if (any(st$regulation == "natural" & !st$accepted)) stop("a natural station without an accepted snap")

# ---- the status file ----------------------------------------------------------------------------
credit <- paste(
    "Dams: contains information licensed under the Open Government Licence – British Columbia (BC Dams).",
    "Licensed use and storage: computed by wet from the Province of British Columbia's Water Rights Licences",
    "- Public (Access Only); no licence record is reproduced.")
out <- data.frame(
  station_number = st$station_number, source = st$source, regulation = st$regulation, why = st$why,
  dams_up = st$dams_up, L_share = round(st$L_share, 4), S_share = round(st$S_share, 4),
  power_up = st$power_up, novol_up = st$novol_up, outside_bc = st$outside_bc, manmade_up = st$manmade_up,
  linear_feature_id = st$linear_feature_id, snap_stream = st$snap_stream, snap_leg = st$leg,
  snap_m = round(st$distance_m, 1), wfs_snapshot = wfs_date, bcenv_snapshot = snapshot,
  bcwatertool_snapshot = tool_snapshot, bcenv_registry_md5 = reg_md5[["bcenv"]],
  bcwatertool_registry_md5 = reg_md5[["bcwatertool"]], credit = credit
)
out$linear_feature_id[!st$accepted] <- NA
out$snap_leg[!st$accepted] <- NA
out$snap_m[!st$accepted] <- NA
f_status <- file.path("inst", "extdata", "station_sources", sprintf("regulation_%s.csv", snapshot))
local({
  op <- options(scipen = 100)  # shares as decimals, never 4e-04
  on.exit(options(op))
  utils::write.csv(out, f_status, row.names = FALSE, na = "", fileEncoding = "UTF-8")
})

# ---- the report ---------------------------------------------------------------------------------
f_rep <- file.path("data", "checks", sprintf("station_regulation_%s.txt", snapshot))
pct <- function(x) ifelse(is.na(x), "", sprintf("%.1f", 100 * x))
tab <- function(x) paste(sprintf("%s %d", names(x), as.integer(x)), collapse = ", ")
fmt_tbl <- function(d) paste0("  ", utils::capture.output(print(d, row.names = FALSE, right = FALSE)))
fmt_mat <- function(m) paste0("  ", utils::capture.output(print(m)))
every <- data.frame(
  station = st$station_number, src = ifelse(st$source == "bcenv", "prov", "tool"), status = st$regulation,
  leg = ifelse(st$accepted, st$leg, "-"), snap_m = ifelse(st$accepted, sprintf("%.0f", st$distance_m), ""),
  area = ifelse(is.na(st$area_km2), "", sprintf("%.1f", st$area_km2)),
  ratio = ifelse(st$accepted & !is.na(st$area_ratio), sprintf("%.2f", st$area_ratio), ""),
  q_m3s = ifelse(is.na(st$q_m3s), "", sprintf("%.3g", st$q_m3s)), dams = ifelse(is.na(st$dams_up), "", st$dams_up),
  L = pct(st$L_share), S = pct(st$S_share), man = ifelse(is.na(st$manmade_up), "", st$manmade_up),
  why = st$why)
lines <- c(
  sprintf("Regulation per non-HYDAT station (#196): provincial snapshot %s, Water Tool snapshot %s, WFS snapshot %s",
          snapshot, tool_snapshot, wfs_date),
  "Produced by scripts/station_regulation.R under the rule in scripts/station_regulation_rule.R.",
  "",
  "== The rule as registered",
  "  registered at 2d93787fb631ccd3b231827c2484c0f58029cb3d, before any station was snapped or placed;",
  sprintf("  run under %s, with the amendments its header dates:", rule_commit),
  paste0("    ", sub("^# ---- (Amendment [0-9]+, [0-9-]+ \\(.*\\)) -*$", "\\1",
                     grep("^# ---- Amendment [0-9]+, ", readLines(rule_files[1]), value = TRUE))),
  "  the registered version stopped at a shared licence before placing any station, so no status exists under it",
  sprintf("  %s md5 %s", names(rule_md5), rule_md5),
  "",
  "== Inputs",
  sprintf("  registry %s md5 %s", basename(reg_path), reg_md5),
  sprintf("  HYDAT %s (drainage areas and regulation flags at the stations' HYDAT sites)", release),
  sprintf("  WFS layer %s: %d rows, the server's count when taken", vapply(rg_layers, `[[`, "", "name"), hits),
  sprintf("  WFS file %s md5 %s", names(raw_md5), raw_md5),
  "  terms: WRIS_DAMS_PUBLIC_SVW (catalogue record bc-dams) Open Government Licence - British Columbia;",
  paste("         WLS_WATER_RIGHTS_LICENCES_SV (record water-rights-licences-public) Access Only:",
        "only values wet computes ship"),
  sprintf(paste("  published build: catalog digest %s; %d segment_monthly historical parts verified before",
                "and %d after the read"), digest, fl$n_verified[1], fl$n_verified[2]),
  sprintf(paste("  dams: %d, %d regulating for the rule (active, Regulated or Regulated - Part 3 Exempt),",
                "%d of those located"), nrow(dams), sum(dams$regulating), nrow(dam_pts)),
  sprintf(paste("  licence rows: %d; Current %d; counted (located, surface, consumptive or storage, kept,",
                "quantity > 0, not rediverted) %d; power PODs %d; no volume (Amendment 2) %d"), nrow(lic_all),
          nrow(lic), sum(lic$candidate & lic$surface), sum(lic$power & !lic$dup_pod), sum(lic$novol)),
  local({
    # surface consumptive, storage or power rows with no location: tested upstream of no station
    off <- !lic$located & lic$surface & !lic$dup_pod & !lic$redivert
    k <- ifelse(lic$PURPOSE_USE_CODE[off] %in% rg_power_codes, "power",
                ifelse(!lic$class[off] %in% c("consumptive", "storage"), NA,
                       ifelse(!is.na(lic$v[off]) & lic$v[off] > 0, paste(lic$class[off], "with a volume"),
                              paste(lic$class[off], "with no volume"))))
    k <- k[!is.na(k)]
    if (length(k)) sprintf("  surface licence rows with no location, so tested upstream of no station: %s", tab(table(k)))
  }),
  sprintf("  points placed in an FWA watershed: %d of %d", length(pl$placed), nrow(pts)),
  local({
    gone <- setdiff(pts$pid, pl$placed)
    cls <- ifelse(gone %in% dam_pts$pid, "regulating dam",
                  ifelse(gone %in% lic_pts$pid[lic_pts$candidate & lic_pts$surface], "counted surface POD",
                         ifelse(gone %in% lic_pts$pid[lic_pts$power], "power POD",
                                ifelse(gone %in% lic_pts$pid[lic_pts$novol], "no-volume POD", "groundwater POD"))))
    dn <- dam_pts$DAM_NAME[match(gone[cls == "regulating dam"], dam_pts$pid)]
    c(if (length(gone)) sprintf("  not placed, so tested upstream of no station: %s", tab(table(cls))),
      if (length(dn)) sprintf("  regulating dams not placed: %s", paste(sort(dn, method = "radix"), collapse = ", ")))
  }),
  "",
  "== Statuses under each version since stations were placed (the rule's amendment protocol)",
  "  scored from the same snapshot, snap, placement and flows with this script (L and S on surface PODs only)",
  fmt_mat(do.call(rbind, lapply(versions, function(v) table(factor(v, rg_vocab))))),
  unlist(lapply(2:length(versions), function(k) {
    moved <- which(versions[[k]] != versions[[k - 1]])
    c(sprintf("  %s -> %s: %d stations", names(versions)[k - 1], names(versions)[k], length(moved)),
      if (length(moved)) sprintf("    %s %s -> %s", st$station_number[moved], versions[[k - 1]][moved],
                                 versions[[k]][moved]))
  })),
  local({
    # regulating dams on a natural station's own line, dropped as more than the margin below it
    o <- pl$own[pl$own$pid %in% dam_pts$pid & pl$own$same_line %in% TRUE & !(pl$own$upstream %in% TRUE), ]
    o <- o[o$station_number %in% st$station_number[st$regulation == "natural"], ]
    o <- o[order(o$station_number, o$below_m, method = "radix"), ]
    c(sprintf("  regulating dams below a natural station on its own line, beyond the %g m margin: %d", rg_own_margin_m,
              nrow(o)),
      if (nrow(o)) sprintf("    %s: %s, %.1f m below", o$station_number, dam_pts$DAM_NAME[match(o$pid, dam_pts$pid)],
                           o$below_m))
  }),
  "",
  "== Population",
  sprintf(paste("  %d stations: %d provincial, %d Water Tool listings of their own (%d continuing listings",
                "folded into their provincial station)"), nrow(st), sum(st$source == "bcenv"), sum(st$source == "bcwatertool"), sum(!is.na(tool_all$continues))),
  sprintf("  drainage area known: %d (%s)", sum(!is.na(st$area_km2)),
          tab(table(ifelse(grepl("^HYDAT", st$area_from), "HYDAT site", st$area_from)))),
  "",
  "== Snap acceptance by leg and source",
  fmt_mat(table(snap = ifelse(st$accepted, st$leg, "not snapped"), source = st$source)),
  "",
  "  not snapped, by reason:",
  fmt_tbl(stats::setNames(as.data.frame(table(sub(" [0-9.]+ ", " # ", st$reason[!st$accepted])),
                                        stringsAsFactors = FALSE), c("reason", "n"))),
  "",
  "== Status by source",
  fmt_mat(table(status = factor(st$regulation, rg_vocab), source = st$source)),
  "",
  "== Change from the registries' name-only column",
  fmt_mat(table(registry = st$registry, now = factor(st$regulation, rg_vocab))),
  "",
  "== Why, by status (each reason counted wherever it applies)",
  unlist(lapply(rg_vocab, function(r) {
    w <- st$why[st$regulation == r]
    # a natural station's one reason holds "; " itself, so it is named before the split
    w <- sub("^no regulating dam; licensed use .*$", "no regulating dam, use and storage under 10 %", w)
    w <- unlist(strsplit(w, "; ", fixed = TRUE))
    w <- sub("^[0-9]+ regulating dams? upstream$", "regulating dam(s) upstream", w)
    w <- sub("^(licensed use|licensed storage) .*$", "\\1 >= 10 %", w)
    t <- sort(table(w), decreasing = TRUE)
    c(sprintf("  %s (%d):", r, sum(st$regulation == r)), sprintf("    %s %d", names(t), as.integer(t)))
  })),
  "",
  "== The rule beside HYDAT's regulation flag, at the provincial stations at a HYDAT site (decides nothing)",
  local({
    h <- st[st$source == "bcenv" & !is.na(st$hydat_site), ]
    flag <- ifelse(is.na(h$hydat_regulated), "no flag",
                   ifelse(h$hydat_regulated == 1, "HYDAT regulated", "HYDAT natural"))
    c(sprintf("  %d stations", nrow(h)), fmt_mat(table(hydat = flag, rule = factor(h$regulation, rg_vocab))))
  }),
  "",
  "== Every station",
  paste("  L, S: licensed consumptive use and storage upstream, % of the mean annual flow (published pick,",
        "month 0); man: FWA man-made waterbodies upstream"),
  fmt_tbl(every)
)
writeLines(lines, f_rep, useBytes = TRUE)
stamp("wrote ", f_status, " and ", f_rep)
