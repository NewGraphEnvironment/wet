#' Minimal FWA watershed codes of a set
#'
#' The codes of a set that have no proper ancestor in it: every code in the
#' set lies under exactly one of them. FWA codes are a 3-digit root label then
#' 6-digit labels, so a code's ancestors are its prefixes ending at a label
#' boundary.
#'
#' @param wscode Character. FWA watershed codes as text (ltree form, e.g.
#'   `"100.190442"`). `NA` is ignored; duplicates are fine.
#' @return Character, the minimal codes, sorted in byte order (ltree order).
#' @examples
#' wet_ws_roots(c("100.190442.244975", "100.190442", "100.190442.999094",
#'                "300.625474.584724", "300.625474.584724.100997"))
#' @export
wet_ws_roots <- function(wscode) {
  if (!is.character(wscode)) stop("wscode must be character", call. = FALSE)
  w <- unique(wscode[!is.na(wscode)])
  bad <- !grepl("^[0-9]{3}(\\.[0-9]{6})*$", w)
  if (any(bad)) stop("not an FWA watershed code: ", w[bad][1], call. = FALSE)
  if (!length(w)) return(character())
  # fixed width: a code of n labels has proper ancestors of 3 + 7 * k
  # characters, k = 0 .. n - 2
  n <- (nchar(w) - 3L) %/% 7L + 1L
  idx <- rep(seq_along(w), n - 1L)
  k <- sequence(n - 1L) - 1L
  anc <- substr(w[idx], 1L, 3L + 7L * k)
  has <- tabulate(idx[anc %in% w], nbins = length(w)) > 0L
  sort(w[!has], method = "radix")
}

#' The upstream-closed set of fundamental watersheds a watershed group needs
#'
#' The polygons [wet_upstream_sums()] needs to give one watershed group's
#' rows the sums a whole basin gives them: every polygon whose `wscode` lies
#' under one of the group's roots, its distinct `wscode`s with no proper
#' ancestor among them ([wet_ws_roots()]). `FWA_Upstream(a, b)` requires
#' `b`'s `wscode` to lie under `a`'s, so nothing upstream of a polygon in the
#' set lies outside it, and the sums over the set, for the group's rows (or
#' any row of the set), equal the basin's up to the order the doubles are
#' added in.
#'
#' A group whose polygons include a mainstem one (`localcode == wscode` at a
#' basin root such as `100`) needs that whole basin: `FWA_Upstream` of such a
#' polygon is the whole subtree.
#'
#' @inheritParams wet_ws_fetch
#' @param wsg Watershed group code, e.g. `"BULK"`.
#' @return The polygons in [wet_ws_fetch()]'s shape, ordered by
#'   `watershed_feature_id`, with attributes `wsg`, `roots` (the group's
#'   roots), `groups` (the watershed groups the set spans), `codes` (the
#'   top-level drainage codes it spans) and `irregular` (the
#'   [wet_upstream_irregular()] pairs of its irregularly coded polygons, to
#'   pass as `irregular_pairs`). Attributes are lost on subsetting, so take
#'   them first.
#' @examples
#' \dontrun{
#' conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
#' ws <- wet_ws_closure(conn, "BULK")
#' attr(ws, "groups")   # BULK and MORR: the Morice drains into the Bulkley
#' s <- wet_upstream_sums(ws, "area_m2", irregular_pairs = attr(ws, "irregular"))
#' s[ws$watershed_group_code == "BULK", ]
#' }
#' @export
wet_ws_closure <- function(conn, wsg) {
  if (!is.character(wsg) || length(wsg) != 1L || is.na(wsg) || !grepl("^[A-Z]{4}$", wsg)) {
    stop("wsg must be one watershed group code, e.g. \"BULK\"", call. = FALSE)
  }
  codes <- DBI::dbGetQuery(conn, "
    SELECT DISTINCT wscode_ltree::text AS wscode
    FROM whse_basemapping.fwa_watersheds_poly
    WHERE watershed_group_code = $1 AND wscode_ltree IS NOT NULL", params = list(wsg))$wscode
  if (!length(codes)) stop("no coded polygons in watershed group ", wsg, call. = FALSE)
  roots <- wet_ws_roots(codes)
  arr <- paste0("{", paste(roots, collapse = ","), "}")
  # wet_ws_fetch()'s columns and order, over every root at once
  ws <- DBI::dbGetQuery(conn, "
    SELECT watershed_feature_id, watershed_group_code,
           wscode_ltree::text AS wscode, localcode_ltree::text AS localcode,
           ST_Area(geom) AS area_m2,
           ST_X(c) AS lon, ST_Y(c) AS lat
    FROM (SELECT watershed_feature_id, watershed_group_code, wscode_ltree,
                 localcode_ltree, geom,
                 ST_Transform(ST_Centroid(geom), 4326) AS c
          FROM whse_basemapping.fwa_watersheds_poly
          WHERE wscode_ltree <@ ANY($1::ltree[])) x
    ORDER BY watershed_feature_id", params = list(arr))
  bad <- is.na(ws$wscode) | is.na(ws$localcode)
  if (any(bad)) {
    warning(sum(bad), " polygons without FWA codes dropped", call. = FALSE)
    ws <- ws[!bad, ]
  }
  # wet_upstream_irregular()'s pairs, over every root at once: the roots'
  # subtrees are disjoint, so no pair is fetched twice
  irr <- DBI::dbGetQuery(conn, "
    SELECT a.watershed_feature_id, b.watershed_feature_id AS id_up
    FROM whse_basemapping.fwa_watersheds_poly b
    JOIN whse_basemapping.fwa_watersheds_poly a
      ON a.wscode_ltree @> b.wscode_ltree
     AND whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree,
                                       b.wscode_ltree, b.localcode_ltree)
    WHERE b.wscode_ltree <@ ANY($1::ltree[])
      AND NOT b.localcode_ltree <@ b.wscode_ltree
    ORDER BY a.watershed_feature_id, b.watershed_feature_id", params = list(arr))
  structure(ws, wsg = wsg, roots = roots,
            groups = sort(unique(ws$watershed_group_code), method = "radix"),
            codes = sort(unique(substr(roots, 1L, 3L)), method = "radix"),
            irregular = irr)
}
