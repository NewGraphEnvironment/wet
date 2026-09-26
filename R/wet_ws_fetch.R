#' Fundamental watersheds of one basin, with codes, area and centroid
#'
#' Everything [wet_upstream_sums()] and centroid sampling need, with no
#' geometry transfer: FWA codes as text, `ST_Area(geom)` in m2 (as fwapg's
#' upstream-area and discharge builds use), and the centroid taken in BC Albers
#' then reprojected to lon/lat (as fwapg's `discharge02_load.sql` does).
#'
#' A basin is every polygon whose `wscode` lies under `wscode`, e.g. `"100"`
#' (Fraser), `"200"` (Peace), `"300"` (Columbia). Upstream sets never leave
#' the basin, because `FWA_Upstream` requires the upstream `wscode` to lie
#' under the downstream one.
#'
#' @param conn A DBI connection to an fwapg database.
#' @param wscode Character. FWA watershed code of the basin root.
#' @return `data.frame(watershed_feature_id, watershed_group_code, wscode,
#'   localcode, area_m2, lon, lat)`.
#' @export
wet_ws_fetch <- function(conn, wscode) {
  wet_check_wscode(wscode)
  sql <- "
    SELECT watershed_feature_id, watershed_group_code,
           wscode_ltree::text AS wscode, localcode_ltree::text AS localcode,
           ST_Area(geom) AS area_m2,
           ST_X(c) AS lon, ST_Y(c) AS lat
    FROM (SELECT watershed_feature_id, watershed_group_code, wscode_ltree,
                 localcode_ltree, geom,
                 ST_Transform(ST_Centroid(geom), 4326) AS c
          FROM whse_basemapping.fwa_watersheds_poly
          WHERE wscode_ltree <@ $1::ltree) x"
  ws <- DBI::dbGetQuery(conn, sql, params = list(wscode))
  bad <- is.na(ws$wscode) | is.na(ws$localcode)
  if (any(bad)) {
    warning(sum(bad), " polygons without FWA codes dropped", call. = FALSE)
    ws <- ws[!bad, ]
  }
  ws
}

#' `FWA_Upstream` pairs for the irregularly coded polygons of one basin
#'
#' A polygon whose `localcode` neither equals nor lies under its `wscode` is
#' irregular: `FWA_Upstream`'s localcode guards treat it differently from the
#' range structure [wet_upstream_sums()] relies on. This returns, for each
#' such polygon `b`, every watershed `a` that `FWA_Upstream(a, b)` counts it
#' upstream of (including itself). The join is small: `a.wscode_ltree @>
#' b.wscode_ltree` restricts candidates to the few streams whose code is a
#' prefix of `b`'s, via the gist index.
#'
#' @inheritParams wet_ws_fetch
#' @return `data.frame(watershed_feature_id, id_up)`.
#' @export
wet_upstream_irregular <- function(conn, wscode) {
  wet_check_wscode(wscode)
  sql <- "
    SELECT a.watershed_feature_id, b.watershed_feature_id AS id_up
    FROM whse_basemapping.fwa_watersheds_poly b
    JOIN whse_basemapping.fwa_watersheds_poly a
      ON a.wscode_ltree @> b.wscode_ltree
     AND whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree,
                                       b.wscode_ltree, b.localcode_ltree)
    WHERE b.wscode_ltree <@ $1::ltree
      AND NOT b.localcode_ltree <@ b.wscode_ltree"
  DBI::dbGetQuery(conn, sql, params = list(wscode))
}

wet_check_wscode <- function(wscode) {
  if (!is.character(wscode) || length(wscode) != 1L || is.na(wscode) ||
      !grepl("^[0-9]{3}(\\.[0-9]{6})*$", wscode)) {
    stop("wscode must be one FWA watershed code, e.g. \"100\"", call. = FALSE)
  }
  invisible(wscode)
}

#' Fundamental watershed polygons of one watershed group
#'
#' Geometry for area-weighted sampling ([wet_ws_sample()] with
#' `method = "area"`), one watershed group at a time so a basin never has to
#' be held in memory at once.
#'
#' @inheritParams wet_ws_fetch
#' @param wsg Watershed group code, e.g. `"SALR"`.
#' @return `terra::SpatVector` (BC Albers) with `watershed_feature_id`.
#' @export
wet_ws_geom <- function(conn, wsg) {
  stopifnot(is.character(wsg), length(wsg) == 1L, !is.na(wsg), grepl("^[A-Z]{4}$", wsg))
  d <- DBI::dbGetQuery(conn, "
    SELECT watershed_feature_id, ST_AsText(geom) AS wkt
    FROM whse_basemapping.fwa_watersheds_poly
    WHERE watershed_group_code = $1", params = list(wsg))
  v <- terra::vect(d$wkt, crs = "EPSG:3005")
  v$watershed_feature_id <- d$watershed_feature_id
  v
}
