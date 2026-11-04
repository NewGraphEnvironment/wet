# What one watershed group's balance needs (#157): for every watershed group,
# the polygons FWA_Upstream reaches from the group's rows (wet_ws_reach()),
# which is what its rows' upstream sums need, and the upstream-closed set
# under its roots that wet_ws_closure() fetches to find them. A group that
# reaches only itself, or a few groups, can be rebuilt alone
# (scripts/segment_group.R).
#
#   Rscript scripts/segment_group_closure.R
#
# Writes the tracked data/checks/segment_group_closure.txt. Needs fwapg only
# (WET_PG*).

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts")
if (length(dirty)) stop("commit these first, so the recorded commit made the table:\n", paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
groups <- DBI::dbGetQuery(conn, "
  SELECT DISTINCT watershed_group_code AS wsg FROM whse_basemapping.fwa_watersheds_poly
  WHERE wscode_ltree IS NOT NULL ORDER BY 1")$wsg
n_coded <- DBI::dbGetQuery(conn, "
  SELECT count(*)::int AS n FROM whse_basemapping.fwa_watersheds_poly
  WHERE wscode_ltree IS NOT NULL AND localcode_ltree IS NOT NULL")$n
stamp(length(groups), " groups, ", n_coded, " coded polygons")

# wet_ws_closure()'s roots and filter, with codes only (a Fraser closure is
# 645,000 polygons, and its centroids are not needed here); irregular pairs
# by top-level drainage, fetched once each. Checked against wet_ws_closure()
# itself on two groups below.
irr_cache <- list()
irr_for <- function(code) {
  if (is.null(irr_cache[[code]])) irr_cache[[code]] <<- wet_upstream_irregular(conn, code)
  irr_cache[[code]]
}
closure_codes <- function(roots) {
  DBI::dbGetQuery(conn, "
    SELECT watershed_feature_id, watershed_group_code AS g, wscode_ltree::text AS wscode,
           localcode_ltree::text AS localcode
    FROM whse_basemapping.fwa_watersheds_poly
    WHERE wscode_ltree <@ ANY($1::ltree[]) AND localcode_ltree IS NOT NULL
    ORDER BY watershed_feature_id", params = list(paste0("{", paste(roots, collapse = ","), "}")))
}
t0 <- Sys.time()
res <- lapply(groups, function(g) {
  codes <- DBI::dbGetQuery(conn, "
    SELECT DISTINCT wscode_ltree::text AS wscode FROM whse_basemapping.fwa_watersheds_poly
    WHERE watershed_group_code = $1 AND wscode_ltree IS NOT NULL", params = list(g))$wscode
  roots <- wet_ws_roots(codes)
  top <- sort(unique(substr(roots, 1, 3)), method = "radix")
  ws <- closure_codes(roots)
  irr <- do.call(rbind, lapply(top, irr_for))
  irr <- irr[irr$id_up %in% ws$watershed_feature_id, ]
  r <- wet_ws_reach(ws, ws$g == g, irr)
  gr <- sort(unique(ws$g[r]), method = "radix")
  data.frame(wsg = g, roots = length(roots), first_root = roots[1], whole = any(nchar(roots) == 3L),
             own = sum(ws$g == g), closure = nrow(ws), closure_groups = length(unique(ws$g)),
             reach = sum(r), n_groups = length(gr), codes = paste(top, collapse = ","),
             groups = paste(setdiff(gr, g), collapse = ","))
})
tab <- do.call(rbind, res)
stamp("counted in ", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), " s")

# the closure counts are wet_ws_closure()'s, and the reach its trim
for (g in c("BULK", "SALR")) {
  ws <- wet_ws_closure(conn, g)
  r <- wet_ws_reach(ws, ws$watershed_group_code == g, attr(ws, "irregular"))
  x <- tab[tab$wsg == g, ]
  stopifnot(nrow(ws) == x$closure, length(attr(ws, "groups")) == x$closure_groups,
            length(attr(ws, "roots")) == x$roots, sum(ws$watershed_group_code == g) == x$own,
            sum(r) == x$reach, length(unique(ws$watershed_group_code[r])) == x$n_groups)
}
DBI::dbDisconnect(conn)
stopifnot(sum(tab$own) == n_coded, all(tab$reach >= tab$own), all(tab$reach <= tab$closure))

# ---- report ----------------------------------------------------------------------------------
bins <- function(x, br, lab) table(factor(cut(x, br, labels = lab), levels = lab))
fmt_bins <- function(a, b) sprintf("  %-16s %6d %8d", names(a), as.integer(a), as.integer(b))
br_g <- c(0, 1, 3, 10, Inf)
lab_g <- c("1 (itself)", "2-3", "4-10", "more than 10")
br_n <- c(0, 5e4, 2e5, Inf)
lab_n <- c("<= 50,000", "50,000-200,000", "> 200,000")
n_codes <- lengths(strsplit(tab$codes, ","))
short <- function(s, k = 8) {
  v <- strsplit(s, ",")[[1]]
  if (length(v) > k) paste0(paste(v[1:k], collapse = ","), ",+", length(v) - k) else s
}
con <- file("data/checks/segment_group_closure.txt", "w")
writeLines(c(
  "# What one watershed group's balance needs (#157)", "",
  sprintf("wet commit %s; %d watershed groups, %d coded fundamental watersheds", wet_commit, nrow(tab), n_coded),
  "reach: the polygons FWA_Upstream reaches from the group's rows (wet_ws_reach()), the least set that gives",
  "them their upstream sums. closure: every polygon under the group's roots (its distinct wscodes with no",
  "proper ancestor among them, wet_ws_roots(); wet_ws_closure()), the upstream-closed set the reach is cut from.",
  "",
  "## Watershed groups spanned, the group included (groups: reach, closure)",
  fmt_bins(bins(tab$n_groups, br_g, lab_g), bins(tab$closure_groups, br_g, lab_g)),
  "", "## Polygons (groups: reach, closure)",
  fmt_bins(bins(tab$reach, br_n, lab_n), bins(tab$closure, br_n, lab_n)),
  "", sprintf("groups whose reach is the whole closure: %d", sum(tab$reach == tab$closure)),
  sprintf("groups whose polygons lie under more than one top-level drainage code: %d", sum(n_codes > 1)),
  sprintf("groups whose closure includes a whole top-level drainage (a root of one label, e.g. 100): %d",
          sum(tab$whole)),
  "", "## By watershed group",
  "roots: how many (first_root: the first in ltree order); own: the group's polygons; reach and closure:",
  "polygons, and the groups they span; others: the other groups the reach spans (the first eight)",
  sprintf("%-5s %6s %7s %8s %3s %8s %3s %-16s %-40s %s", "group", "roots", "own", "reach", "g", "closure", "g",
          "codes", "others", "first_root"),
  sprintf("%-5s %6d %7d %8d %3d %8d %3d %-16s %-40s %s", tab$wsg, tab$roots, tab$own, tab$reach, tab$n_groups,
          tab$closure, tab$closure_groups, tab$codes, vapply(tab$groups, short, ""), tab$first_root)
), con)
close(con)
stamp("report written")
