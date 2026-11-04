# What one watershed group's balance needs (#157): for every watershed group,
# the upstream-closed set of fundamental watersheds wet_ws_closure() returns
# (every polygon under the group's roots), and how many groups and polygons
# that is. A group whose closure is itself, or a few groups, can be rebuilt
# alone (scripts/segment_group.R); a group holding a mainstem polygon needs
# its whole basin.
#
#   Rscript scripts/segment_group_closure.R
#
# Writes the tracked data/checks/segment_group_closure.txt. Needs fwapg only
# (WET_PG*); about five minutes.

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

# the same roots and the same filter as wet_ws_closure(), counted rather than
# fetched (a Fraser closure is 645,000 polygons); checked against
# wet_ws_closure() itself on two groups below
closure_counts <- function(wsg) {
  codes <- DBI::dbGetQuery(conn, "
    SELECT DISTINCT wscode_ltree::text AS wscode FROM whse_basemapping.fwa_watersheds_poly
    WHERE watershed_group_code = $1 AND wscode_ltree IS NOT NULL", params = list(wsg))$wscode
  roots <- wet_ws_roots(codes)
  n <- DBI::dbGetQuery(conn, "
    SELECT watershed_group_code AS g, count(*)::int AS n FROM whse_basemapping.fwa_watersheds_poly
    WHERE wscode_ltree <@ ANY($1::ltree[]) AND localcode_ltree IS NOT NULL
    GROUP BY 1 ORDER BY 1", params = list(paste0("{", paste(roots, collapse = ","), "}")))
  list(roots = roots, n = n)
}
t0 <- Sys.time()
res <- lapply(groups, function(g) {
  x <- closure_counts(g)
  data.frame(wsg = g, roots = length(x$roots), first_root = x$roots[1],
             whole = any(nchar(x$roots) == 3L), own = x$n$n[x$n$g == g], closure = sum(x$n$n), n_groups = nrow(x$n),
             codes = paste(sort(unique(substr(x$roots, 1, 3)), method = "radix"), collapse = ","),
             groups = paste(setdiff(x$n$g, g), collapse = ","))
})
tab <- do.call(rbind, res)
stamp("counted in ", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), " s")

# the counts are wet_ws_closure()'s
for (g in c("BULK", "SALR")) {
  ws <- wet_ws_closure(conn, g)
  r <- tab[tab$wsg == g, ]
  stopifnot(nrow(ws) == r$closure, length(attr(ws, "groups")) == r$n_groups,
            length(attr(ws, "roots")) == r$roots, sum(ws$watershed_group_code == g) == r$own)
}
DBI::dbDisconnect(conn)
stopifnot(sum(tab$own) == n_coded)

# ---- report ----------------------------------------------------------------------------------
bins <- function(x, br, lab) table(factor(cut(x, br, labels = lab), levels = lab))
fmt_bins <- function(t) sprintf("  %-14s %4d", names(t), as.integer(t))
n_codes <- lengths(strsplit(tab$codes, ","))
short <- function(s, k = 8) {
  v <- strsplit(s, ",")[[1]]
  if (length(v) > k) paste0(paste(v[1:k], collapse = ","), ",+", length(v) - k) else s
}
con <- file("data/checks/segment_group_closure.txt", "w")
writeLines(c(
  "# What one watershed group's balance needs (#157)", "",
  sprintf("wet commit %s; %d watershed groups, %d coded fundamental watersheds", wet_commit, nrow(tab), n_coded),
  "A group's closure is every polygon under its roots (its distinct wscodes with no proper ancestor among them,",
  "wet_ws_roots()): the polygons wet_upstream_sums() needs to give the group's rows the sums its basin gives them.",
  "",
  "## Watershed groups a group's closure spans, itself included",
  fmt_bins(bins(tab$n_groups, c(0, 1, 3, 10, Inf), c("1 (itself)", "2-3", "4-10", "more than 10"))),
  "", "## Polygons in a group's closure",
  fmt_bins(bins(tab$closure, c(0, 5e4, 2e5, Inf), c("<= 50,000", "50,000-200,000", "> 200,000"))),
  "", sprintf("groups whose polygons lie under more than one top-level drainage code: %d", sum(n_codes > 1)),
  sprintf("groups whose closure is a whole basin (a root of one label, e.g. 100): %d",
          sum(tab$whole)),
  "", "## By watershed group",
  "roots: how many (first_root: the first in ltree order); own: the group's polygons; closure: polygons needed;",
  "groups: how many the closure spans (others: the rest, the first eight)",
  sprintf("%-5s %6s %-26s %7s %8s %6s %-16s %s", "group", "roots", "first_root", "own", "closure", "groups",
          "codes", "others"),
  sprintf("%-5s %6d %-26s %7d %8d %6d %-16s %s", tab$wsg, tab$roots, tab$first_root, tab$own, tab$closure,
          tab$n_groups, tab$codes, vapply(tab$groups, short, ""))
), con)
close(con)
stamp("report written")
