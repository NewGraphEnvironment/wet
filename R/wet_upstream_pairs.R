#' Watershed-to-upstream-polygon pairs for one watershed group, from fwapg
#'
#' Uses `FWA_Upstream()` on fundamental watershed codes and fwapg's
#' precomputed `fwa_watersheds_upstream_area`, as fwapg's own discharge build
#' does. Upstream polygons are not restricted to the group, so run it on a
#' group whose upstream area lies inside it or expect a large result.
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
