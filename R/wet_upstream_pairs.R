#' Watershed-to-upstream-polygon pairs for one watershed group, from fwapg
#'
#' The slow oracle: the pairwise `FWA_Upstream()` join fwapg's own builds use,
#' with fwapg's stored `fwa_watersheds_upstream_area`. It materialises every
#' (watershed, upstream polygon) pair (722 k for SALR), so use it only to spot
#' check [wet_upstream_sums()] / [wet_upstream_mean()] on small headwater
#' groups. Upstream polygons are not restricted to the group.
#'
#' @param conn A DBI connection to an fwapg database.
#' @param wsg Watershed group code, e.g. `"SALR"`.
#' @return `data.frame(watershed_feature_id, id_up, area_up_m2,
#'   upstream_area_m2)`.
#' @export
wet_upstream_pairs <- function(conn, wsg) {
  stopifnot(is.character(wsg), length(wsg) == 1L, grepl("^[A-Z]{4}$", wsg))
  sql <- "
    SELECT a.watershed_feature_id,
           uw.watershed_feature_id AS id_up,
           ST_Area(uw.geom) AS area_up_m2,
           ua.upstream_area_ha * 10000 AS upstream_area_m2
    FROM whse_basemapping.fwa_watersheds_poly a
    INNER JOIN whse_basemapping.fwa_watersheds_upstream_area ua
      ON a.watershed_feature_id = ua.watershed_feature_id
    INNER JOIN whse_basemapping.fwa_watersheds_poly uw
      ON whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree,
                                       uw.wscode_ltree, uw.localcode_ltree)
    WHERE a.watershed_group_code = $1"
  DBI::dbGetQuery(conn, sql, params = list(wsg))
}
