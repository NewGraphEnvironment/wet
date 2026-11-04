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

#' An upstream-closed set of fundamental watersheds holding a watershed group
#'
#' Every polygon whose `wscode` lies under one of the group's roots, its
#' distinct `wscode`s with no proper ancestor among them ([wet_ws_roots()]).
#' `FWA_Upstream(a, b)` requires `b`'s `wscode` to lie under `a`'s, so
#' nothing upstream of a polygon in the set lies outside it, and
#' [wet_upstream_sums()] over the set gives the group's rows (or any row of
#' the set) the sums a whole basin gives them, up to the order the doubles are
#' added in.
#'
#' The set is enough, not the least: it holds each root's whole subtree,
#' including the part of a root's stream below the group and its tributaries
#' there. A group holding a polygon whose `wscode` is a basin root such as
#' `100` gets that whole basin. [wet_ws_reach()] trims it to the polygons the
#' group's rows reach.
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
#' ws <- ws[wet_ws_reach(ws, ws$watershed_group_code == "BULK", attr(ws, "irregular")), ]
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

#' The fundamental watersheds that FWA_Upstream reaches from some of them
#'
#' Which rows of `ws` lie in the `FWA_Upstream` set of at least one of the
#' rows `from` (each counting itself), by the same ranges
#' [wet_upstream_sums()] sums over, with irregularly coded polygons from
#' `irregular_pairs`. Over an upstream-closed `ws` such as
#' [wet_ws_closure()]'s, those rows are the least set that gives the `from`
#' rows their sums: [wet_upstream_sums()] over them gives the `from` rows
#' the same sums as over all of `ws`, up to the order the doubles are added
#' in.
#'
#' @param ws `data.frame` with `watershed_feature_id`, `wscode` and
#'   `localcode` (FWA ltree codes as text).
#' @param from Logical, one per row of `ws`: the rows whose upstream sets to
#'   join.
#' @param irregular_pairs Optional `data.frame(watershed_feature_id, id_up)`,
#'   as [wet_upstream_sums()] takes it. Without it, irregularly coded rows
#'   are left out with a warning, as [wet_upstream_sums()] leaves them out.
#' @return Logical, one per row of `ws`.
#' @examples
#' ws <- data.frame(watershed_feature_id = 1:5,
#'                  wscode = c("100", "100", "100.000300", "100.000300", "100.000700"),
#'                  localcode = c("100", "100.000500", "100.000300", "100.000300.000010",
#'                                "100.000700"))
#' # row 2 sits on the main stem above position 000500: it reaches itself
#' # and the tributary at 000700, not row 1 or the tributary at 000300
#' wet_ws_reach(ws, ws$watershed_feature_id == 2)
#' @export
wet_ws_reach <- function(ws, from, irregular_pairs = NULL) {
  need <- c("watershed_feature_id", "wscode", "localcode")
  miss <- setdiff(need, names(ws))
  if (length(miss)) stop("ws is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (!is.logical(from) || length(from) != nrow(ws) || anyNA(from)) {
    stop("from must be TRUE or FALSE for each row of ws", call. = FALSE)
  }
  wc <- as.character(ws$wscode)
  lc <- as.character(ws$localcode)
  if (anyNA(wc) || anyNA(lc)) stop("wscode and localcode must not be NA", call. = FALSE)
  valid <- lc == wc | startsWith(lc, paste0(wc, "."))
  kb <- paste(wc[valid], lc[valid])
  uk <- sort(unique(kb), method = "radix")
  lt <- function(q) wet_count_lt(uk, q)
  # the ranges wet_upstream_sums() sums for each distinct (wscode, localcode) among `from`
  ka <- unique(paste(wc[from], lc[from]))
  wq <- sub(" .*", "", ka)
  lq <- sub(".* ", "", ka)
  eq <- wq == lq
  sub_lo <- lt(wq)
  sub_hi <- lt(paste0(wq, "/"))
  lo <- c(ifelse(eq, sub_lo, lt(paste(wq, lq))), pmax(lt(paste0(lq, "/")), sub_lo)[!eq])
  hi <- c(ifelse(eq, sub_hi, lt(paste0(wq, "!"))), sub_hi[!eq])
  keep <- hi > lo
  # covered key positions: +1 at each range's start, -1 past its end
  d <- tabulate(lo[keep] + 1L, nbins = length(uk) + 1L) - tabulate(hi[keep] + 1L, nbins = length(uk) + 1L)
  covered <- cumsum(d)[seq_along(uk)] > 0L
  out <- logical(nrow(ws))
  out[valid] <- covered[match(kb, uk)]
  irr <- !valid
  if (any(irr)) {
    if (is.null(irregular_pairs)) {
      warning(sum(irr), " irregularly coded polygons are left out; pass irregular_pairs to match ",
              "FWA_Upstream", call. = FALSE)
    } else {
      stopifnot(all(c("watershed_feature_id", "id_up") %in% names(irregular_pairs)))
      hit <- irregular_pairs$id_up[irregular_pairs$watershed_feature_id %in% ws$watershed_feature_id[from]]
      out[irr] <- ws$watershed_feature_id[irr] %in% hit
    }
  }
  out
}
