# Regulation per non-HYDAT station (#196): the pieces scripts/station_regulation.R copies from
# elsewhere, each naming its source so a reader can diff them. Sourced after
# scripts/station_regulation_rule.R; the rule decides nothing here.
#
# Copied, not sourced: scripts/wb_gauge_diversion.R is #53's frozen rule and runs only where the
# full fit is (it sources scripts/wb_cv_lib.R), so its pieces are copied as they stand at
# 0e56d60 and that script is not touched.

# ---- WFS snapshots (scripts/wb_gauge_diversion.R:37-103) ------------------------------------
# The BC WFS caps an un-paged GetFeature at 10,000 features and still answers 200, so each
# layer is paged in a stable order and held to the server's own count, recorded when the
# snapshot was taken. Licensee names and addresses are not requested.
rg_wfs <- "https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0&typeName=pub:WHSE_WATER_MANAGEMENT."
rg_layers <- list(
  licences = list(name = "WLS_WATER_RIGHTS_LICENCES_SV", sort = "WLS_WRL_SYSID", geom = "SHAPE",
                  fields = c("WLS_WRL_SYSID", "POD_NUMBER", "POD_SUBTYPE", "POD_DIVERSION_TYPE", "POD_STATUS",
                             "LICENCE_NUMBER", "LICENCE_STATUS", "LICENCE_STATUS_DATE", "PRIORITY_DATE",
                             "PURPOSE_USE_CODE", "PURPOSE_USE", "SOURCE_NAME", "REDIVERSION_IND", "QUANTITY",
                             "QUANTITY_UNITS", "QUANTITY_FLAG", "QUANTITY_FLAG_DESCRIPTION",
                             "HYDRAULIC_CONNECTIVITY")),
  dams = list(name = "WRIS_DAMS_PUBLIC_SVW", sort = "WRIS_DP_SYSID", geom = "GEOMETRY",
              fields = c("WRIS_DP_SYSID", "DAM_FILE_NUMBER", "DAM_NAME", "COMMISSIONED_YEAR", "DAM_FUNCTION",
                         "DAM_REGULATED_CODE", "DAM_OPERATION_CODE", "DAM_TYPE", "DAM_HEIGHT"))
)
rg_page_size <- 10000

# The files of layer `k` under `raw_dir`, downloading what is missing. `download(url, dest)`
# fetches one URL (wet:::wet_download() in the script, a stand-in in a guard's proof).
rg_wfs_snapshot <- function(k, raw_dir, download, msg = message) {
  l <- rg_layers[[k]]
  f_hits <- file.path(raw_dir, paste0(k, "_hits.txt"))
  if (!file.exists(f_hits)) {
    tmp <- tempfile(fileext = ".xml")
    download(paste0(rg_wfs, l$name, "&request=GetFeature&resultType=hits"), tmp)
    n <- as.integer(sub('.*numberMatched="([0-9]+)".*', "\\1", paste(readLines(tmp, warn = FALSE), collapse = "")))
    stopifnot(!is.na(n), n > 0)
    writeLines(as.character(n), paste0(f_hits, ".part"))
    file.rename(paste0(f_hits, ".part"), f_hits)
  }
  n <- as.integer(readLines(f_hits))
  pages <- seq(0, n - 1, by = rg_page_size)
  f <- file.path(raw_dir, sprintf("%s_%02d.csv", k, seq_along(pages)))
  # Each page must start after the previous one ends (a malformed startIndex, such as
  # paste0()'s "1e+05", is answered with the first page); a page that does not is fetched again.
  ids <- function(p) as.numeric(utils::read.csv(p, colClasses = "character")[[l$sort]])
  last <- -Inf
  for (i in seq_along(pages)) {
    for (try in 1:3) {
      if (!file.exists(f[i])) {
        msg("downloading ", k, " page ", i, " of ", length(pages))
        download(paste0(rg_wfs, l$name, "&request=GetFeature&outputFormat=csv&srsName=EPSG:3005",
                        "&sortBy=", l$sort, "&count=", rg_page_size,
                        "&startIndex=", sprintf("%d", as.integer(pages[i])),
                        "&propertyName=", paste(c(l$fields, l$geom), collapse = ",")), f[i])
      }
      id <- ids(f[i])
      if (length(id) && !is.unsorted(id, strictly = TRUE) && id[1] > last) break
      msg(k, " page ", i, " is out of sequence (first id ", id[1], " after ", last, "): fetching again")
      unlink(f[i])
    }
    if (!file.exists(f[i])) stop(k, " page ", i, " out of sequence 3 times", call. = FALSE)
    last <- id[length(id)]
  }
  f
}

# Layer `k`'s rows from its files, held to the server's count with no id twice.
rg_wfs_read <- function(k, files, raw_dir) {
  x <- do.call(rbind, lapply(files, utils::read.csv, stringsAsFactors = FALSE, na.strings = "",
                             colClasses = "character"))
  n <- as.integer(readLines(file.path(raw_dir, paste0(k, "_hits.txt"))))
  id <- rg_layers[[k]]$sort
  if (nrow(x) != n || anyDuplicated(x[[id]])) {
    stop(k, ": ", nrow(x), " rows (", sum(duplicated(x[[id]])), " duplicated ids) against the server's ", n,
         call. = FALSE)
  }
  x
}

# ---- licence rows (scripts/wb_gauge_diversion.R:108-165) -------------------------------------
# The row rules #53 applies, with the rule's Amendment 1 (rg_split_pods()), on the rows the
# rule counts: LICENCE_STATUS "Current" only, so its in-force weighting (every row in force on
# the snapshot date, weight 1) and its removal of replaced rows (which are never Current) fall
# away. Classes from rg_licence_class(). Returns the Current rows with pid, class, v (each
# row's m3/year), candidate, power and novol. L and S count candidates on surface PODs only
# (#53's base_mask), which the script applies.
rg_licence_rows <- function(lic) {
  rg_codes_check(lic$LICENCE_STATUS, rg_licence_status_codes, "LICENCE_STATUS")
  lic <- lic[lic$LICENCE_STATUS == "Current", ]
  # a subtype the snapshot of 2026-11-24 did not hold would read as groundwater and drop out of
  # every count, and a located surface row with no purpose would be classed "none": both stop
  rg_codes_check(lic$POD_SUBTYPE, c("PG", "POD", "PWD"), "POD_SUBTYPE")
  if (any(!is.na(lic$SHAPE) & lic$POD_SUBTYPE == "POD" & is.na(lic$PURPOSE_USE_CODE))) {
    stop("a located surface licence row has no PURPOSE_USE_CODE: a question for the owner", call. = FALSE)
  }
  lic$units <- trimws(lic$QUANTITY_UNITS)
  to_m3yr <- c("m3/year" = 1, "m3/day" = 365.25, "m3/sec" = 365.25 * 86400)
  lic$m3yr <- as.numeric(lic$QUANTITY) * unname(to_m3yr[lic$units])  # NA: no volume
  lic$class <- rg_licence_class(lic$PURPOSE_USE_CODE)
  lic$located <- !is.na(lic$SHAPE)
  lic$surface <- lic$POD_SUBTYPE %in% "POD"
  lic$redivert <- lic$REDIVERSION_IND %in% "Y"
  # The view repeats a row for each licensee: one row per licence-purpose, POD, quantity flag
  # and units is kept (the first located one by id), at the largest quantity its repeats carry
  # (#53's Deviation 1). Located rows first, so a repeat without a location never displaces one.
  lic <- lic[order(!lic$located, as.numeric(lic$WLS_WRL_SYSID)), ]
  lic$grp <- paste(lic$LICENCE_NUMBER, lic$PURPOSE_USE_CODE, sep = "|")
  pod_key <- ifelse(is.na(lic$POD_NUMBER), paste0("no POD|", lic$WLS_WRL_SYSID),
                    paste(lic$grp, lic$POD_NUMBER, lic$QUANTITY_FLAG, lic$units, sep = "|"))
  lic$dup_pod <- duplicated(pod_key)
  max_or_na <- function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE)
  lic$m3yr_pod <- unname(tapply(lic$m3yr, pod_key, max_or_na)[pod_key])
  # one quantity per licence-purpose (M, no flag, or a D/P group whose distinct PODs all carry
  # one quantity), the maximum over those rows, split over their distinct located PODs;
  # T, D, P: each POD's own
  one <- !lic$dup_pod
  dp <- lic$QUANTITY_FLAG %in% c("D", "P")
  dp_rep <- tapply(lic$m3yr_pod[dp & one], lic$grp[dp & one], function(v) length(v) > 1 && length(unique(v)) == 1)
  lic$shared <- lic$QUANTITY_FLAG %in% "M" | is.na(lic$QUANTITY_FLAG) | (dp & dp_rep[lic$grp] %in% TRUE)
  g_max <- tapply(lic$m3yr_pod[lic$shared], lic$grp[lic$shared], max_or_na)
  # Amendment 1: split over the group's PODs that are not rediversions (#53: rediversions included)
  split <- rg_split_pods(lic$located, one, lic$shared, lic$redivert)
  g_npod <- tapply(split, lic$grp, sum)
  lic$g_full <- unname(g_max[lic$grp])
  lic$g_npod <- as.integer(g_npod[lic$grp])
  lic$v <- ifelse(lic$shared, lic$g_full / lic$g_npod, lic$m3yr_pod)
  lic$pid <- paste0("L", lic$WLS_WRL_SYSID)
  lic$candidate <- lic$located & lic$class %in% c("consumptive", "storage") & !lic$dup_pod &
    !is.na(lic$v) & lic$v > 0 & !lic$redivert
  # the split counts a shared group's PODs (rg_split_pods()), so every such POD of a group that
  # counts must be a candidate: checked, not assumed (a failure is a question for the owner)
  sh <- split & lic$grp %in% lic$grp[lic$candidate & lic$shared]
  if (!all(lic$candidate[sh])) {
    stop(sum(!lic$candidate[sh]), " located PODs of shared licence-purposes are not counted: ",
         "the split over a group's PODs would undercount", call. = FALSE)
  }
  lic$power <- lic$located & lic$surface & lic$PURPOSE_USE_CODE %in% rg_power_codes
  # Amendment 2: a surface consumptive or storage row that would count but states no volume
  lic$novol <- lic$located & lic$surface & lic$class %in% c("consumptive", "storage") & !lic$dup_pod &
    !lic$redivert & (is.na(lic$v) | lic$v <= 0)
  lic
}

# ---- snap (R/wet_station_snap.R:50-67, with gnis_name and the watershed group) --------------
rg_sql_snap <- "
    SELECT s.station_number,
           c.linear_feature_id::double precision AS linear_feature_id,
           c.gnis_name, c.distance_to_stream AS distance_m, c.blue_line_key,
           c.downstream_route_measure AS measure,
           c.wscode_ltree::text AS seg_wscode, c.localcode_ltree::text AS seg_localcode,
           l.watershed_feature_id, w.wscode_ltree::text AS wscode,
           w.localcode_ltree::text AS localcode, w.watershed_group_code,
           u.upstream_area_ha / 100 AS upstream_area_km2
    FROM rg_st s
    CROSS JOIN LATERAL whse_basemapping.fwa_indexpoint(
      ST_Transform(ST_SetSRID(ST_MakePoint(s.lon, s.lat), 4326), 3005), %f, %d) c
    LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
    LEFT JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
    LEFT JOIN whse_basemapping.fwa_watersheds_upstream_area u USING (watershed_feature_id)
    ORDER BY s.station_number, c.linear_feature_id"

# ---- placement (scripts/wb_gauge_diversion.R:177-205) ---------------------------------------
# Points (gd_raw: pid, wkt in BC Albers) placed in FWA fundamental watersheds, dams at the
# midpoint of the crest's longest part; the stations (gd_g: station_number, wscode, localcode,
# linear_feature_id, lon, lat; the snapped watershed's codes) located on their segment.
rg_sql_place <- c("
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
# upstream on codes; own reach (the station's exact codes) flagged for the stream-position test
rg_sql_up <- "
  SELECT g.station_number, p.pid, (p.wscode = g.wscode::ltree AND p.localcode = g.localcode::ltree) AS own
  FROM gd_g g JOIN gd_ws p ON p.wscode <@ g.wscode::ltree
  WHERE whse_basemapping.fwa_upstream(g.wscode::ltree, g.localcode::ltree, p.wscode, p.localcode)"
rg_sql_own <- "
  SELECT o.station_number, o.pid, i.blue_line_key IS NOT NULL AS indexed,
         i.blue_line_key = m.blue_line_key AS same_line, m.measure - i.downstream_route_measure AS below_m,
         whse_basemapping.fwa_upstream(m.blue_line_key, m.measure, m.wscode::ltree, m.localcode::ltree,
           i.blue_line_key, i.downstream_route_measure, i.wscode_ltree, i.localcode_ltree) AS upstream
  FROM gd_own o JOIN gd_ws p ON p.pid = o.pid JOIN gd_gm m ON m.station_number = o.station_number
  LEFT JOIN LATERAL whse_basemapping.fwa_indexpoint(p.geom, 100, 1) i ON true"

# The pairs (station, point) upstream once own-reach points below the station are removed, as
# scripts/wb_gauge_diversion.R:229-238 removes them, with the rule's Amendment 3 margin
# (rg_own_below(): a point within rg_own_margin_m below the station on its line is upstream).
# The own-reach query (rg_sql_own) adds same_line and below_m for it.
rg_upstream_pairs <- function(up, own) {
  stopifnot(!anyDuplicated(up[c("station_number", "pid")]), !anyDuplicated(own[c("station_number", "pid")]))
  k_own <- match(paste(up$station_number, up$pid), paste(own$station_number, own$pid))
  stopifnot(identical(!is.na(k_own), up$own))
  up$indexed <- own$indexed[k_own]
  up$below <- up$own & rg_own_below(own$indexed[k_own], own$upstream[k_own], own$same_line[k_own],
                                     own$below_m[k_own])
  up <- up[!up$below, ]
  up[order(up$station_number, up$pid, method = "radix"), ]
}

# ---- border and man-made waterbodies (new) ----------------------------------------------------
# A station's upstream area reaches outside BC when an FWA stream upstream of its point (or its
# own segment) crosses one of the rule's border lines. Stations: rg_sn (station_number,
# linear_feature_id, blue_line_key, measure, seg_wscode, seg_localcode).
rg_sql_border <- "
  WITH b AS (
    SELECT DISTINCT s.linear_feature_id, s.blue_line_key, s.downstream_route_measure, s.wscode_ltree, s.localcode_ltree
    FROM whse_basemapping.fwa_stream_networks_sp s
    JOIN whse_basemapping.fwa_approx_borders a ON ST_Intersects(s.geom, a.geom)
    WHERE a.border IN (%s))
  SELECT DISTINCT n.station_number
  FROM rg_sn n JOIN b ON b.wscode_ltree <@ n.seg_wscode::ltree
  WHERE b.linear_feature_id = n.linear_feature_id
     OR whse_basemapping.fwa_upstream(n.blue_line_key, n.measure, n.seg_wscode::ltree, n.seg_localcode::ltree,
          b.blue_line_key, b.downstream_route_measure, b.wscode_ltree, b.localcode_ltree)
  ORDER BY 1"
# FWA man-made waterbodies with a stream segment upstream of the station's point: reported only.
rg_sql_manmade <- "
  WITH m AS (
    SELECT DISTINCT s.waterbody_key, s.blue_line_key, s.downstream_route_measure, s.wscode_ltree, s.localcode_ltree
    FROM whse_basemapping.fwa_stream_networks_sp s
    JOIN whse_basemapping.fwa_manmade_waterbodies_poly p ON p.waterbody_key = s.waterbody_key)
  SELECT n.station_number, count(DISTINCT m.waterbody_key)::integer AS manmade_up
  FROM rg_sn n JOIN m ON m.wscode_ltree <@ n.seg_wscode::ltree
  WHERE whse_basemapping.fwa_upstream(n.blue_line_key, n.measure, n.seg_wscode::ltree, n.seg_localcode::ltree,
          m.blue_line_key, m.downstream_route_measure, m.wscode_ltree, m.localcode_ltree)
  GROUP BY 1 ORDER BY 1"
