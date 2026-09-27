#' Snap HYDAT stations to FWA fundamental watersheds, checked by drainage area
#'
#' Finds the `num_features` nearest stream segments to each station with
#' fwapg's `fwa_indexpoint()` (the function `fresh::frs_point_snap()` wraps),
#' in one query for all stations, and keeps the candidate whose upstream area
#' is closest to HYDAT's gross drainage area on a log scale. The nearest
#' segment at a confluence is often the wrong stream, and the area is what
#' tells them apart. A snap is accepted when that area is within `max_dev` of
#' the gross drainage area.
#'
#' Upstream area here is fwapg's stored `fwa_watersheds_upstream_area`, which
#' is good enough to choose between candidates. The area the water balance
#' compares against is accumulated later from the live polygons.
#'
#' @param conn A DBI connection to an fwapg database.
#' @param stations `data.frame(station_number, lon, lat,
#'   drainage_area_gross_km2)`, e.g. from [wet_station_select()].
#' @param tolerance Search distance, m.
#' @param num_features Candidates per station.
#' @param max_dev Accepted relative deviation of the snapped area from the
#'   gross drainage area.
#' @param lake_dist,lake_min_ha,lake_min_share A station is flagged as a lake
#'   outlet when a lake of at least `lake_min_ha` hectares lies within
#'   `lake_dist` metres of the gauge, has stream segments upstream of the
#'   snapped point on the FWA network (`fwa_upstream()`), **and** drains
#'   between `lake_min_share` and `1 + max_dev` of the gauge's upstream area.
#'   So an inlet, an off-network pond, or a lake on a tributary is not one; the
#'   upper bound also catches an inlet that an FWA coding fault places upstream.
#' @return `data.frame(station_number, linear_feature_id, watershed_feature_id,
#'   wscode, localcode, distance_m, upstream_area_km2, area_ratio, accepted,
#'   reason, lake)`, one row per station. Stations with no candidate keep a
#'   row with `accepted = FALSE`.
#' @export
wet_station_snap <- function(conn, stations, tolerance = 1000, num_features = 5,
                             max_dev = 0.1, lake_dist = 3000, lake_min_ha = 100,
                             lake_min_share = 0.5) {
  need <- c("station_number", "lon", "lat", "drainage_area_gross_km2")
  miss <- setdiff(need, names(stations))
  if (length(miss)) stop("stations is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  stopifnot(!anyDuplicated(stations$station_number))
  if (!nrow(stations)) return(wet_snap_empty())

  tmp <- paste0("wet_snap_", paste(sample(letters, 12, TRUE), collapse = ""))
  DBI::dbWriteTable(conn, tmp, as.data.frame(stations[, need]), temporary = TRUE)
  on.exit(DBI::dbRemoveTable(conn, tmp, temporary = TRUE), add = TRUE)
  cand <- DBI::dbGetQuery(conn, sprintf("
    SELECT s.station_number,
           -- bigint arrives as bit64::integer64, which reads back as garbage
           -- doubles wherever bit64 is not loaded; FWA ids fit a double
           c.linear_feature_id::double precision AS linear_feature_id,
           c.distance_to_stream AS distance_m, c.blue_line_key,
           c.downstream_route_measure AS measure,
           c.wscode_ltree::text AS seg_wscode, c.localcode_ltree::text AS seg_localcode,
           l.watershed_feature_id, w.wscode_ltree::text AS wscode,
           w.localcode_ltree::text AS localcode,
           u.upstream_area_ha / 100 AS upstream_area_km2
    FROM %s s
    CROSS JOIN LATERAL whse_basemapping.fwa_indexpoint(
      ST_Transform(ST_SetSRID(ST_MakePoint(s.lon, s.lat), 4326), 3005), %f, %d) c
    LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
    LEFT JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
    LEFT JOIN whse_basemapping.fwa_watersheds_upstream_area u USING (watershed_feature_id)",
    DBI::dbQuoteIdentifier(conn, tmp), tolerance, as.integer(num_features)))
  out <- wet_snap_pick(stations, cand, max_dev)
  out$lake <- wet_snap_lake(conn, stations, cand, out, lake_dist, lake_min_ha,
                            c(lake_min_share, 1 + max_dev))
  out
}

# Lake outlet: a lake of at least lake_min_ha within lake_dist of the gauge,
# with a stream segment upstream of the chosen snapped point, whose own
# upstream area is a share of the gauge's inside `share`.
wet_snap_lake <- function(conn, stations, cand, picked, lake_dist, lake_min_ha, share) {
  i <- match(paste(picked$station_number, picked$linear_feature_id),
             paste(cand$station_number, cand$linear_feature_id))
  p <- data.frame(station_number = picked$station_number,
                  lon = stations$lon[match(picked$station_number, stations$station_number)],
                  lat = stations$lat[match(picked$station_number, stations$station_number)],
                  blue_line_key = cand$blue_line_key[i], measure = cand$measure[i],
                  wscode = cand$seg_wscode[i], localcode = cand$seg_localcode[i])
  p <- p[!is.na(i), ]
  lake <- rep(NA, nrow(picked))
  if (!nrow(p)) return(lake)
  tmp <- paste0("wet_lake_", paste(sample(letters, 12, TRUE), collapse = ""))
  DBI::dbWriteTable(conn, tmp, p, temporary = TRUE)
  on.exit(DBI::dbRemoveTable(conn, tmp, temporary = TRUE), add = TRUE)
  # A lake qualifies when some segment of it is upstream of the point; its own
  # upstream area is taken at its outlet (the largest over ALL its segments),
  # so an inlet, whose lake drains more than the gauge, fails the upper bound
  # even where an FWA coding fault makes fwa_upstream() call it upstream.
  r <- DBI::dbGetQuery(conn, sprintf("
    WITH hit AS (
      SELECT DISTINCT p.station_number, lk.waterbody_key
      FROM %s p
      JOIN whse_basemapping.fwa_lakes_poly lk
        ON lk.area_ha >= %f
       AND ST_DWithin(lk.geom, ST_Transform(ST_SetSRID(ST_MakePoint(p.lon, p.lat), 4326), 3005), %f)
      JOIN whse_basemapping.fwa_stream_networks_sp s
        ON s.waterbody_key = lk.waterbody_key
       AND whse_basemapping.fwa_upstream(p.blue_line_key, p.measure, p.wscode::ltree,
             p.localcode::ltree, s.blue_line_key, s.downstream_route_measure,
             s.wscode_ltree, s.localcode_ltree))
    SELECT h.station_number, h.waterbody_key, MAX(u.upstream_area_ha) / 100 AS lake_up_km2
    FROM hit h
    JOIN whse_basemapping.fwa_stream_networks_sp s ON s.waterbody_key = h.waterbody_key
    JOIN whse_basemapping.fwa_streams_watersheds_lut l ON l.linear_feature_id = s.linear_feature_id
    JOIN whse_basemapping.fwa_watersheds_upstream_area u USING (watershed_feature_id)
    GROUP BY 1, 2", DBI::dbQuoteIdentifier(conn, tmp), lake_min_ha, lake_dist))
  up <- picked$upstream_area_km2[match(r$station_number, picked$station_number)]
  r$ok <- r$lake_up_km2 / up >= share[1] & r$lake_up_km2 / up <= share[2]
  lake[!is.na(i)] <- FALSE
  hit <- unique(r$station_number[r$ok %in% TRUE])
  lake[picked$station_number %in% hit] <- TRUE
  lake
}

# Choose one candidate per station: the smallest |log(area ratio)| among
# candidates with a watershed and an area; nearest when the station has no
# gross area.
wet_snap_pick <- function(stations, cand, max_dev) {
  cand$gross <- stations$drainage_area_gross_km2[match(cand$station_number, stations$station_number)]
  cand$area_ratio <- cand$upstream_area_km2 / cand$gross
  usable <- !is.na(cand$watershed_feature_id) & !is.na(cand$upstream_area_km2)
  cand$score <- ifelse(is.na(cand$gross), cand$distance_m, abs(log(cand$area_ratio)))
  cand <- cand[usable, ]
  cand <- cand[order(cand$station_number, cand$score, cand$distance_m), ]
  best <- cand[!duplicated(cand$station_number), ]
  i <- match(stations$station_number, best$station_number)
  out <- data.frame(
    station_number = stations$station_number,
    linear_feature_id = best$linear_feature_id[i],
    watershed_feature_id = best$watershed_feature_id[i],
    wscode = best$wscode[i], localcode = best$localcode[i],
    distance_m = best$distance_m[i], upstream_area_km2 = best$upstream_area_km2[i],
    area_ratio = best$area_ratio[i]
  )
  out$accepted <- !is.na(out$area_ratio) & abs(out$area_ratio - 1) <= max_dev
  out$reason <- ifelse(out$accepted, "",
                ifelse(is.na(out$watershed_feature_id), "no candidate within tolerance",
                ifelse(is.na(stations$drainage_area_gross_km2), "no gross drainage area",
                       sprintf("area ratio %.2f outside 1 +/- %.2f", out$area_ratio, max_dev))))
  out
}

wet_snap_empty <- function() {
  data.frame(station_number = character(), linear_feature_id = numeric(),
             watershed_feature_id = integer(), wscode = character(), localcode = character(),
             distance_m = numeric(), upstream_area_km2 = numeric(), area_ratio = numeric(),
             accepted = logical(), reason = character(), lake = logical())
}
